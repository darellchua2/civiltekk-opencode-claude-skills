---
name: ticket-creation-skill
description: >-
  Create structured GitHub issues or JIRA tickets — platform detection,
  structured description, labels/type, sub-issues. Ticket creation only:
  no branch, no PLAN, no execution. Triggers: create ticket, create issue,
  new issue, jira ticket, bug report, feature request.
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

Renamed from `ticket-plan-workflow-skill` — planning/execution steps moved
to `worktree-pipeline-skill` (invoked via `/run-worktree-pipeline`).

## What I do

I create well-structured tickets on GitHub Issues or JIRA — nothing else:

1. **Detect Platform**: GitHub Issues or JIRA based on user input and project setup
2. **Gather Ticket Requirements**: structured description following industry best practices
3. **Determine Ticket Scope**: single ticket vs parent with sub-issues/subtasks
4. **Create Ticket**: GitHub CLI (`gh`) or Atlassian MCP with appropriate labels/type

Branch creation, PLAN generation, and execution belong to
`worktree-pipeline-skill` (`/run-worktree-pipeline`). To go end-to-end,
create the ticket here, then run the pipeline against its ref.

## Framework Skills Used

| Skill | Purpose | Used In |
|-------|---------|---------|
| `git-issue-labeler` | GitHub label assessment and assignment | Step 4 (GitHub) |
| `jira-ticket-labeler` | JIRA issue type and priority classification | Step 4 (JIRA) |

## When to use me

- Starting a new development task tracked in GitHub Issues or JIRA
- You want a standardized, well-structured ticket as the artifact
- `gh` available (GitHub) or `atlassian` MCP enabled (JIRA — see guard below)

## Prerequisites

### GitHub Issues
- GitHub CLI (`gh`) installed and authenticated (`gh auth status` valid). If `command -v gh` fails, load `gh-cli-setup-skill` (install + auth), then continue instead of erroring.
- Git repository with GitHub remote; write access to repository

### JIRA
- Active Atlassian/JIRA account with project access
- `atlassian` MCP server enabled in this session (opt-in — see MCP Availability Guard)

## MCP Availability Guard (JIRA steps)

The `atlassian` MCP server is **disabled by default**. Before any JIRA step, check whether `atlassian_*` tools exist in your tool list:

- **Present** → proceed normally.
- **Absent** → do NOT attempt or hallucinate `atlassian_*` calls. Options, in order:
  1. Interactive: offer per-project enable via `opencode-repo-setup-skill` (writes `{"mcp":{"servers":{"atlassian":{"disabled":false}}}}` into the project `opencode.json`; effective next session — this session must degrade).
  2. REST fallback: API token + `curl -u email:token` against `https://<site>.atlassian.net` (discover cloudId: `curl https://<site>.atlassian.net/_edge/tenant_info`).
  3. Degrade gracefully: run the GitHub-only flow, report JIRA steps as skipped.
- Headless/CI: skip option 1; use option 2 if credentials exist, else option 3.

## Steps

### Step 1: Detect Platform

```bash
# If user mentions JIRA ticket format (e.g., "PROJ-123") → JIRA
# If user mentions GitHub issue (#123) or "create issue" → GitHub
# If user says "create ticket" → Ask which platform

# Auto-detect: ONLY if atlassian_* tools exist in your tool list (see MCP
# Availability Guard); otherwise treat JIRA as unavailable and default to GitHub
atlassian_getVisibleJiraProjects --cloudId "$CLOUD_ID" 2>/dev/null

# Prompt user if ambiguous
"Which platform for this ticket?
- GitHub Issues (default)
- JIRA"
```

Set `PLATFORM` = `github` or `jira`.

### Step 2: Gather Ticket Description

Prompt the user for a structured ticket description:

1. **Title/Summary** (required): concise, max 72 characters
2. **Overview** (required): what this ticket accomplishes
3. **Acceptance Criteria** (required): definition of done (bullet points)
4. **Scope** (required): files or areas affected
5. **Technical Notes** (optional): implementation considerations

```
Please provide the following for your ticket:

1. **Title** (required): Brief title for the ticket
   Example: "Implement user authentication API"

2. **Overview** (required): What does this ticket accomplish?
   Example: "Add JWT-based authentication endpoints for user login/registration"

3. **Acceptance Criteria** (required): How do we know it's done?
   Example:
   - Users can register with email/password
   - Users can login and receive JWT token
   - Protected routes validate JWT

4. **Scope** (required): What files/areas will be affected?
   Example: src/api/auth/, src/middleware/, tests/auth/

5. **Technical Notes** (optional): Any implementation details?
   Example: Use bcrypt for password hashing, 24h token expiry
```

### Step 3: Determine Ticket Scope

Ask: "Should this be broken into smaller sub-issues/subtasks?"

- **Parent with Sub-items**: creates a parent ticket, then prompts for sub-items (repeat until done), creates each linked to the parent
- **Single Ticket**: one ticket for contained work

### Step 4: Create Ticket

#### Attribution (author/assignee)

- **GitHub**: the issue author is the `gh auth` user by construction (token owner — GitHub does not allow spoofing); `--assignee @me` self-assigns the same identity. `git config user.name`/`user.email` are NOT valid assignee sources (display name, not a login; email may be a private noreply address).
- **JIRA reporter**: defaults to the account behind the MCP token / REST credentials — automatic, no field needed.
- **JIRA assignee**: must be set explicitly by `accountId` (JIRA never assigns by display name or email):
  1. Fetch own accountId: REST `curl -u email:token https://<site>.atlassian.net/rest/api/3/myself` → `.accountId` (on Atlassian MCP v2, `getJiraCurrentUser`/`lookupJiraAccountId` are the MCP-native equivalents).
  2. Set assignee: REST `PUT /rest/api/3/issue/{key}/assignee` with `{"accountId": "<id>"}` — the only guaranteed path; works from the §MCP Availability Guard REST fallback.
  3. `atlassian_createJiraIssue` (v1, pinned) assignee parameter: **unverified — server absent** (2026-09-19 static inspection: Atlassian's supported-tools page documents v2 only — there the create tool is `createJiraIssue` with no published per-parameter schema and `editJiraIssue` is the documented field-edit path; the pinned v1 schema is not statically published). Re-inspect live when a project enables the atlassian MCP; until then use the REST PUT above, or MCP v2 `editJiraIssue` where v2 is enabled.

#### GitHub Issues

**Label Detection** — delegate to `git-issue-labeler` skill (analyzes issue content and assigns GitHub default labels): `bug`, `enhancement`, `documentation`, `good first issue`, `help wanted`, `question`, `invalid`, `wontfix`, `duplicate`, `priority: critical|high|medium|low`, and semver labels (`major`/`minor`/`patch`, PRs only).

**Single issue**:
```bash
ISSUE_URL=$(gh issue create \
  --title "$TITLE" \
  --body "$FORMATTED_BODY" \
  --label "$LABELS" \
  --assignee @me)

ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
```

**Parent with sub-issues**:
```bash
PARENT_URL=$(gh issue create --title "$TITLE" --body "$FORMATTED_BODY" \
  --label "$LABELS" --assignee @me)
PARENT_NUMBER=$(echo "$PARENT_URL" | grep -oE '[0-9]+$')

for subissue in "${SUBISSUES[@]}"; do
  gh issue create \
    --title "$subissue.title" \
    --body "$subissue.body

Parent: #$PARENT_NUMBER" \
    --label "$subissue.labels" \
    --assignee @me
done
```

#### JIRA Tickets

**Issue Type Detection** — delegate to `jira-ticket-labeler` skill (maps ticket content to JIRA types Bug/Story/Task/Epic and priority Highest→Lowest).

**Select JIRA Project** (if not specified):
```bash
atlassian_getVisibleJiraProjects --cloudId "$CLOUD_ID"
# Prompt user to select project by key (e.g., IBIS, PROJ, DA)
```

**Single Task**:
```bash
TICKET_KEY=$(atlassian_createJiraIssue \
  --cloudId "$CLOUD_ID" \
  --projectKey "$PROJECT_KEY" \
  --issueTypeName "Task" \
  --summary "$SUMMARY" \
  --description "$FORMATTED_DESCRIPTION")
```

**Story with Subtasks**:
```bash
STORY_KEY=$(atlassian_createJiraIssue \
  --cloudId "$CLOUD_ID" \
  --projectKey "$PROJECT_KEY" \
  --issueTypeName "Story" \
  --summary "$SUMMARY" \
  --description "$FORMATTED_DESCRIPTION")

for subtask in "${SUBTASKS[@]}"; do
  atlassian_createJiraIssue \
    --cloudId "$CLOUD_ID" \
    --projectKey "$PROJECT_KEY" \
    --issueTypeName "Sub-task" \
    --summary "$subtask.summary" \
    --description "$subtask.description" \
    --parent "$STORY_KEY"
done
```

## Best Practices

- **Be specific**: "Add JWT authentication" vs "Add auth"
- **Include context**: why is this needed?
- **Define done**: clear acceptance criteria
- **Limit scope**: one feature/fix per ticket
- **Labels**: use appropriate labels for discoverability; `bug` vs `enhancement` distinction matters

## Common Issues

### GitHub CLI Missing or Not Authenticated
- Missing (`command -v gh` fails): load `gh-cli-setup-skill`, then continue.
- Not authenticated:
```bash
gh auth login && gh auth status
```

### Cannot Create JIRA Ticket
- Verify project key is correct and user has create permissions
- Use `atlassian_getVisibleJiraProjects` to list accessible projects

### Subtask/Sub-issue Creation Fails
- GitHub: reference parent manually in body ("Parent: #123"); use task lists for hierarchy
- JIRA: ensure parent Story exists first; verify subtask issue type is enabled in project

## Troubleshooting Checklist

**Before starting**:
- [ ] Platform selected (GitHub or JIRA)
- [ ] CLI authenticated (`gh auth status` or Atlassian MCP guard checked)
- [ ] Git repository with remote configured

**After ticket creation**:
- [ ] Ticket ID/number captured and accessible via URL
- [ ] Labels/type assigned correctly
- [ ] Sub-items created and linked (if parent)

## Platform Comparison

| Aspect | GitHub Issues | JIRA |
|--------|---------------|------|
| Issue Type | Labels only | Task, Story, Bug, Subtask |
| Hierarchy | Manual linking (body refs/task lists) | Native parent/subtask |
| Projects | GitHub Projects | JIRA Boards |
| Ticket ref format | `#123` | `PROJ-123` |

## Example Usage

```
User: /create-ticket Add user authentication API

Agent: Please provide:
1. **Title**: Implement user authentication API ✓
2. **Overview**: Add JWT-based authentication endpoints
3. **Acceptance Criteria**: register/login/logout work; protected routes validate JWT
4. **Scope**: src/api/auth/, src/middleware/, tests/auth/
5. **Technical Notes**: bcrypt, 24h token expiry

User: (provides 2-5)
Agent: Single ticket or parent with sub-issues?
User: Single

Agent: Labels detected: enhancement
Created GitHub issue: #456 → https://github.com/org/repo/issues/456

Next step (optional): /run-worktree-pipeline #456
```
