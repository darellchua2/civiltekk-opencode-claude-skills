---
name: git-issue-updater-skill
description: Update GitHub issues and JIRA tickets with commit progress including user, date, time, and consistent documentation formatting for traceability
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

## What I do

Post progress comments to the ticket referenced by new commits (GitHub Issues via `gh`; JIRA via MCP/REST), in the house comment format.

## When to use me

After pushing commits that reference a ticket; before PR creation to keep the tracker current.

## MCP Availability Guard (JIRA branch only)

GitHub comments go through `gh` — always available. JIRA comments use `atlassian_addCommentToJiraIssue`, and the `atlassian` MCP server is **disabled by default** (opt-in):
- If `atlassian_*` tools are absent from your tool list, do NOT attempt or hallucinate them.
- Interactive: offer per-project enable via `opencode-repo-setup-skill` (effective next session).
- Fallback: REST comment — `curl -u email:token -X POST https://<site>.atlassian.net/rest/api/3/issue/<KEY>/comment -d '{"body":"..."}'` (cloudId: `curl https://<site>.atlassian.net/_edge/tenant_info`).
- Otherwise: report the JIRA update as skipped — commit detection and GitHub updates are unaffected.

## Workflow

1. **Latest commit**: `git log -1 --format='%H %an %aI %s'` (hash, author, ISO date, subject); files changed via `git diff-tree --no-commit-id --name-only -r HEAD`.
2. **Determine issue ref** — GitHub first: `#(\d+)` in the commit message; then JIRA: `[A-Z]+-\d+`; then branch name (`123` → `#123`, `GITHUB-123`/`PROJ-123` → JIRA); else ask the user. Never guess a ticket.
3. **Post the comment** — GitHub: `gh issue comment <num> --body-file`; JIRA per the Guard above.
4. **Idempotency**: one progress comment per commit push — skip if the comment (matched by commit hash) already exists.

## Comment format (house template)

```markdown
## Progress Update - <YYYY-MM-DD at HH:mm (UTC offset)>

### Changes Made
- <subject-line bullets from commits>

### Statistics
- **Commits**: <n> · **Files changed**: <n> (+<adds>/−<dels>)

### Commit Link
- [<short-hash>]($REPO_URL/commit/<sha>) — <subject>

### Files Changed
- <paths>
```

Rules: real user + timestamp (from `git log`, never invented); bullets from actual commit subjects; no editorializing; the same template every update so progress is diffable across updates.
