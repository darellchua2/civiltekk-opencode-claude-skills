---
name: pr-merge-workflow-skill
description: >-
  Post-merge workflow — merges PR, monitors CI, auto-fixes failures, updates
  JIRA, deletes source branch. Triggers: 'pr merge to [branch]', 'merge the PR',
  'complete the PR'. Not 'create pr'.
metadata:
  protocol: autoresearch-opt-in
category: Framework
license: Apache-2.0
compatibility: opencode
---

# PR Merge + Monitor + Fix Workflow

Use when the user says phrases like "pr merge to main", "merge the PR to develop", "merge to [branch]", "complete the PR", or "merge it". This skill handles everything after the PR is approved and ready to merge.

## Prerequisites

Before executing, confirm:
- Current branch has an open PR targeting the specified branch
- PR is in a mergeable state (no conflicts, reviews passed)
- If not, tell the user what's blocking and stop

## Phase 1: Merge the PR

1. Get PR info: `gh pr view --json number,url,headRefName,baseRefName,title,state,mergeable`
2. Verify state is `OPEN` and mergeable is `MERGEABLE`
3. Merge using squash (default): `gh pr merge <number> --squash --delete-branch=false`
   - If user prefers merge commit: `gh pr merge <number> --merge --delete-branch=false`
   - Do NOT auto-delete branch yet — wait for CI
4. Record: PR number, source branch name, target branch name, JIRA ticket key (if any)

## Phase 2: Monitor GitHub Actions CI

1. Find the post-merge CI run: `gh run list --branch <target-branch> --limit 1`
2. If no CI workflow exists, skip to Phase 4 (no CI to monitor)
3. Monitor the run:
   - Use `gh run view <run-id>` to check status
   - Poll every 30 seconds if still `in_progress`
   - Maximum wait: 10 minutes (configurable by user)
4. Possible outcomes:
   - `completed` + `conclusion: success` → Phase 4
   - `completed` + `conclusion: failure` → Phase 3
   - Timeout → Report to user, ask how to proceed

## Phase 3: Fix CI Failures (Auto-Heal Loop)

This phase loops until CI passes or max retries hit (default: 3 attempts).

### Step 3a: Diagnose

1. Get failure logs: `gh run view <run-id> --log-failed`
2. Identify failing job and step
3. Determine if the failure is fixable by code changes (lint errors, test failures, type errors) or requires human intervention (infrastructure issues, secret rotation)

### Step 3b: Fix

For auto-fixable failures:
1. Checkout the target branch: `git checkout <target-branch> && git pull`
2. Create a fix branch: `git checkout -b fix/ci-<run-id>`
3. Read the failing files and apply fixes
4. Commit with message: `fix(ci): resolve <error-type> from run <run-id>`
5. Push and create PR: `gh pr create --base <target-branch> --title "fix(ci): ..." --body "..."`
6. Merge immediately if trivial: `gh pr merge <number> --squash --delete-branch`

### Step 3c: Re-Monitor

1. Find the new CI run on the target branch
2. Monitor until pass or fail
3. If pass → Phase 4
4. If fail → increment retry counter, go back to Step 3a
5. If max retries exceeded → report to user with full diagnostic, stop

### Common Auto-Fixes

| Failure Type | Auto-Fix Action |
|-------------|----------------|
| Lint errors | Run linter with --fix, review changes, commit |
| Type errors | Fix type annotations or casts |
| Test failures | Read test output, fix code or update test if test is wrong |
| Build errors | Fix missing imports, syntax errors |
| Format errors | Run formatter, commit |

### Not Auto-Fixable (Report and Stop)

- Infrastructure/service failures
- Missing secrets or credentials
- Flaky tests (intermittent)
- Dependency resolution conflicts requiring version decisions
- Any failure the agent is not confident about

## Phase 4: Post-Merge Cleanup

### JIRA Integration

If a JIRA ticket key was found in the PR title or branch name (pattern: `[A-Z]+-\d+`):
1. Load `jira-status-updater` skill for transition logic
2. Transition ticket to post-merge status (e.g., "Done")
3. Add comment with merge commit URL and CI result
4. If no JIRA key found, skip silently

### Branch Cleanup

1. Delete remote source branch: `git push origin --delete <source-branch>`
2. Delete local source branch: `git branch -d <source-branch>`
3. If `--delete-branch=false` was used earlier (step 1.3), clean up now
4. Switch to target branch: `git checkout <target-branch>`

### PLAN.md Cleanup

1. Check if a PLAN.md exists for this branch (e.g., `plans/PLAN-GIT-*.md`)
2. If found and all phases complete, mark as fully complete
3. Commit the final PLAN state

## Summary Report

After all phases complete, report to user:

```
✓ PR #<number> merged into <target-branch>
✓ CI passed (run <run-id>)
✓ JIRA <ticket> → Done
✓ Branch <source-branch> deleted
```

Or if failures occurred:

```
✓ PR #<number> merged into <target-branch>
✗ CI failed (run <run-id>): <error summary>
✓ Auto-fixed and merged fix PR #<fix-number>
✓ CI passed on retry (run <run-id-2>)
✓ JIRA <ticket> → Done
✓ Branch <source-branch> deleted
```

## Agent Requirements

This skill expects the loading agent to have:
- `bash: allow` — for gh CLI, git operations
- `edit: allow` — for CI failure fixes
- `read: allow` / `glob: allow` / `grep: allow` — for code analysis
- Access to atlassian MCP tools — for JIRA integration
- `jira-status-updater` skill — for ticket transitions

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

### Auto-detection
If invoked on an iterative task, prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". Cache answer for session.

### Skill-specific patterns

**CI auto-fix crash recovery.** CI failure mode → response: (a) lint failure → auto-fix and re-push; (b) test failure → debug, fix, re-push (max 3 attempts); (c) build failure → revert + log; (d) environment/infra failure → wait + retry. All responses logged to `pr-merge-results.tsv`. See `crash-recovery.md`.

### Citations
- `autoresearch-core-skill/references/crash-recovery.md`

### Imperative gating
When `AUTORESEARCH_PROTOCOL` is unset, this section is descriptive only. Default behavior is documented in all sections above.
