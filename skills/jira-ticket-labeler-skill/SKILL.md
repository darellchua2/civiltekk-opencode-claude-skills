---
name: jira-ticket-labeler-skill
description: Assess and classify JIRA tickets with appropriate issue types (Bug, Story, Task, Epic), priorities, and components using Atlassian MCP tools
license: Apache-2.0
compatibility: opencode
category: JIRA
---

## What I do

I provide intelligent JIRA ticket classification by:

- Analyzing ticket content to determine appropriate issue type (Bug, Story, Task, Epic)
- Assigning priority levels using JIRA's priority field (Highest, High, Medium, Low, Lowest)
- Adding JIRA components for area classification
- Using Atlassian MCP tools for all JIRA operations
- Supporting cross-platform workflows (GitHub issue → JIRA ticket mapping)

## When to use me

Use this when:
- You need to classify JIRA tickets with correct issue types
- You want to set appropriate priorities on JIRA tickets
- You're creating JIRA tickets from GitHub issue context
- You need consistent ticket classification across your JIRA project
- You want to map GitHub labels to JIRA issue types

## Prerequisites

- `atlassian` MCP server enabled in this session — it is **disabled by default** (opt-in). If `atlassian_*` tools are absent from your tool list, do NOT attempt or hallucinate them:
  - Interactive: offer per-project enable via `opencode-repo-setup-skill` (effective next session).
  - Fallback: classification/label-mapping is analytical and can proceed without MCP; only ticket creation/reads (`atlassian_createJiraIssue`, `atlassian_getJiraIssue`) need the server or the REST fallback (`curl -u email:token`).
  - Otherwise: return the classification and report creation as skipped.
- JIRA project access with create/edit permissions
- Valid JIRA project key (e.g., "IBIS", "PROJ")

## Why a Separate Skill from git-issue-labeler

JIRA and GitHub use fundamentally different taxonomy systems:

| Aspect | GitHub | JIRA |
|--------|--------|------|
| Classification | Labels (flat, multiple) | Issue Type (single, structured) |
| Priority | Labels (`priority: high`) | Dedicated Priority field (dropdown) |
| Area | Labels | Components (separate entity) |
| Subtasks | Not supported natively | First-class citizen |
| Epics | Label-based | Dedicated Epic issue type |

GitHub `git-issue-labeler-skill` handles GitHub labels. This skill handles JIRA taxonomy.

## JIRA Issue Types

### Standard Hierarchy

```
Epic
 └── Story / Task
      └── Sub-task (Bug, Sub-task)
```

### Issue Type Reference

| Type | Description | When to Use |
|------|-------------|-------------|
| **Bug** | Something isn't working | Errors, crashes, incorrect behavior, regressions |
| **Story** | New feature or enhancement | User-facing features, new APIs, new functionality |
| **Task** | General work item | Technical debt, refactoring, configuration, documentation |
| **Epic** | Large body of work | Multi-sprint initiative, cross-cutting concern |
| **Sub-task** | Child of another issue | Break down Story/Task into smaller pieces |

### Type Detection

> **Sync Contract**: The priority keyword tables below are mirrored in `git-issue-labeler-skill`. When updating one, update both.

> These keywords are intent signals, not literal substring matches. Apply semantic judgment — "add" in "address" does not indicate a Story.

**Bug** — Keywords: fix, error, broken, crash, fail, doesn't work, incorrect, wrong, problem, bug, defect, regression
Examples:
- "Login fails when user enters invalid credentials"
- "App crashes when uploading large files"
- "Regression: export button stopped working after v2.1"

**Story** — Keywords: add, implement, create, new, feature, support, introduce, build, develop, as a user I want
Examples:
- "Add dark mode support to the dashboard"
- "Implement export to PDF functionality"
- "As a user I want to filter search results by date"

**Task** — Keywords: update, refactor, configure, migrate, document, upgrade, cleanup, improve, optimize
Examples:
- "Refactor authentication module for better testability"
- "Upgrade React to v18"
- "Update API documentation for v2 endpoints"

**Epic** — Keywords: initiative, project, overhaul, migration, platform, infrastructure
Examples:
- "User Authentication Overhaul"
- "Cloud Migration Initiative"
- "Design System Implementation"

## JIRA Priority Reference

| Priority | Description | When to Use |
|----------|-------------|-------------|
| **Highest** | System down, data loss, security | Production outage, data corruption, active exploit |
| **High** | Major feature broken | Core functionality impaired, significant user impact |
| **Medium** | Functional issue with workaround | Standard feature request, normal bug with workaround |
| **Low** | Minor inconvenience | Cosmetic issue, minor UX annoyance, nice-to-have |
| **Lowest** | Trivial | Typo in docs, minor visual glitch |

### Priority Detection

**Highest** — Keywords: critical, urgent, system down, data loss, security, vulnerability, outage, production down
Examples:
- "Production outage — all users affected"
- "Data loss reported during backup"

**High** — Keywords: high priority, important, blocking, unusable, regression, broken
Examples:
- "Core feature unusable after v3.0"
- "Regression blocking the release"

**Medium** (default) — Keywords: medium, moderate, workaround, intermittent
Examples:
- "Intermittent error with a known workaround"
- "Moderate: feature works but slowly"

**Low** — Keywords: low priority, minor, cosmetic, nice to have, nit, typo
Examples:
- "Minor cosmetic glitch in dark mode"
- "Typo in an error message"

**Lowest** — Keywords: trivial, whenever, backlog, far future
Examples:
- "Trivial: rename an internal flag"
- "Backlog — no timeline"

## GitHub → JIRA Mapping

When creating JIRA tickets from GitHub issue context:

| GitHub Label | JIRA Issue Type |
|-------------|----------------|
| `bug` | Bug |
| `enhancement` | Story |
| `documentation` | Task |
| `good first issue` | Task |
| No type label | Task (default) |

| GitHub Priority Label | JIRA Priority |
|----------------------|--------------|
| `priority: critical` | Highest |
| `priority: high` | High |
| `priority: medium` | Medium |
| `priority: low` | Low |
| (none) | Medium (default) |

## Steps

### Step 1: Analyze Ticket Content

Determine the appropriate issue type and priority from the title and description:

```bash
# Content to analyze
ticket_title="..."
ticket_description="..."
content="${ticket_title} ${ticket_description}"
```

### Step 2: Determine Issue Type

Resolve the issue type by matching ticket content against the **Type Detection** keyword lists above (§ Type Detection), applying semantic judgment:

- Bug / Story / Task / Epic keyword match → that issue type
- No keyword matches → default to `Task`

```bash
# issue_type is resolved from the Type Detection table above (not a literal regex match)
issue_type="<Bug|Story|Task|Epic>"
```

### Step 3: Determine Priority

Resolve the priority by matching ticket content against the **Priority Detection** keyword lists above (§ Priority Detection), applying semantic judgment:

- Highest / High / Low / Lowest keyword match → that priority
- No keyword matches → default to `Medium`

```bash
# priority is resolved from the Priority Detection table above (not a literal regex match)
priority="<Highest|High|Medium|Low|Lowest>"
```

### Step 4: Create or Update JIRA Ticket

Use Atlassian MCP tools to create the ticket:

```
# Create JIRA issue via MCP tool
atlassian_createJiraIssue(
  cloudId: "<cloud-id>",
  projectKey: "<PROJECT-KEY>",
  issueTypeName: "<issue_type>",
  summary: "<ticket_title>",
  description: "<ticket_description>",
  additional_fields: {
    "priority": { "name": "<priority>" }
  }
)
```

### Step 5: Map GitHub Labels to JIRA (Cross-Platform)

When creating a JIRA ticket from a GitHub issue:

```
1. Read GitHub issue labels
2. Map labels to JIRA issue type using the mapping table above
3. Map priority label to JIRA priority
4. Create JIRA ticket with mapped values
5. Add comment to GitHub issue with JIRA ticket link
```

### Step 6: Generate Assessment Report

```markdown
# JIRA Ticket Assessment

**Ticket**: <KEY>-<number> - <title>
**Issue Type**: <type>
**Priority**: <priority>

**Detection Keywords**:
- <keyword1> → <type>
- <keyword2> → <priority>

**Confidence**: High/Medium/Low

**GitHub Mapping** (if applicable):
- GitHub labels: <labels>
- Mapped to JIRA type: <type>
- Mapped to JIRA priority: <priority>
```

## JIRA Components

Components are JIRA's way of categorizing work by area. Common patterns:

| Component Pattern | Examples |
|-------------------|---------|
| By layer | `frontend`, `backend`, `api`, `database` |
| By feature | `auth`, `billing`, `notifications`, `search` |
| By module | `user-management`, `reporting`, `integrations` |
| By platform | `web`, `mobile`, `desktop`, `infrastructure` |

Component assignment is optional and depends on project configuration.

## Best Practices

### Issue Type Selection

- **Bug vs Task**: If it was working before and broke, it's a Bug. If it's an improvement, it's a Task.
- **Story vs Task**: If it delivers user-facing value, it's a Story. If it's technical, it's a Task.
- **Epic**: Only for multi-sprint initiatives. Don't overuse.
- **Sub-task**: Always nest under a parent. Never standalone.

### Priority Assignment

- Default to **Medium** unless keywords clearly indicate otherwise
- **Highest** should be rare — only for production-impacting issues
- Avoid priority inflation — not everything is High

### Cross-Platform Sync

- When syncing GitHub → JIRA, always set the JIRA issue type (not just labels)
- Add the JIRA ticket link as a comment on the GitHub issue
- Add the GitHub issue URL in the JIRA ticket description
- Keep priorities consistent across platforms

## Common Issues

### Unknown Issue Type

**Solution**: Default to `Task`. Add a comment suggesting the reporter clarify.

### Priority Field Not Available

**Solution**: Some JIRA projects customize priority values. Use `atlassian_getJiraIssueTypeMetaWithFields` to check available priorities for the project.

### Epic Link Required

**Solution**: Some projects require all issues to be linked to an Epic. Check the project's field configuration and link appropriately.

### Component Does Not Exist

**Solution**: Components are project-specific. Use `atlassian_search` to find existing components or skip component assignment if not available.

## Verification

After creating or classifying a JIRA ticket:

```
# Verify ticket details
atlassian_getJiraIssue(
  cloudId: "<cloud-id>",
  issueIdOrKey: "<KEY>-<number>",
  fields: ["summary", "issuetype", "priority", "status", "labels"]
)
```
