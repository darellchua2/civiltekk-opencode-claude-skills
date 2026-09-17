---
name: jira-status-updater-skill
description: Automate JIRA ticket status transitions after pull requests are merged, ensuring proper workflow closure
license: Apache-2.0
compatibility: opencode
category: JIRA
---

## What I do

After a PR merges, transition its JIRA ticket to Done/Closed **exactly once** and add a merge comment. Idempotency is the contract: check current status first, transition only if not already done-category.

## When to use me

Post-merge closure (typically driven by `worktree-pipeline-skill` or the PR workflow; never by the PR-creation agent itself).

## MCP Availability Guard

Transitions/comments use `atlassian_*` MCP tools, and the `atlassian` MCP server is **disabled by default** (opt-in). Ticket-key detection (Step 1, git/`gh` based) always works; before the first `atlassian_*` call:

- If `atlassian_*` tools are absent from your tool list, do NOT attempt or hallucinate them.
- Interactive: offer per-project enable via `opencode-repo-setup-skill` (effective next session).
- Fallback: REST transition — `curl -u email:token -X POST https://<site>.atlassian.net/rest/api/3/issue/<KEY>/transitions` (cloudId: `curl https://<site>.atlassian.net/_edge/tenant_info`).
- No credentials/headless: report the transition as skipped and log the detected ticket key — never fail the PR-merge workflow.

## Workflow

1. **Detect ticket ref** from the merged PR: title/body (`[A-Z]+-\d+`), branch name (`feat/IBIS-123-*`), or commit footers (`Closes IBIS-123`). Via `gh pr view <num> --json title,body,headRefName`. No key found → report and stop (never guess).
2. **Available transitions**: `atlassian_getTransitions --cloudId <id> --issueKey <KEY>`.
3. **Pick target** by priority: `to.name == "Done"` → `"Closed"` → any `to.statusCategory.key == "done"` (jq: `.transitions[] | select(.to.name=="Done") | .id`).
4. **Check current status** (`atlassian_getJiraIssue` or `gh`-cached state): already done-category → skip transition, still add/verify the merge comment. This is the transition-once guard.
5. **Execute**: `atlassian_transitionJiraIssue --transitionId <id>` (REST fallback: POST transitions with `{"transition": {"id": <id>}}`).
6. **Merge comment** (house template):

```markdown
## Pull Request Merged
### Status Update
- **Previous**: <from> → **New**: <to>
### Merge Details
- **PR**: #<num> — <title> (<merge SHA>)
### Files Changed
- <summary or count>
```

Failure of any step: log + continue where possible; a comment failure must not trigger a second transition attempt.
