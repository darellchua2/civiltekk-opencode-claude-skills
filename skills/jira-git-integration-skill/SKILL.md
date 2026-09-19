---
name: jira-git-integration-skill
description: "JIRA-Git plumbing shared by other JIRA skills — branch naming from ticket keys, ticket-key extraction from branches and commits. Triggers: jira branch, ticket key from branch. Not for creating, labeling, or status-updating tickets (use ticket-creation-skill, jira-ticket-labeler-skill, jira-status-updater-skill)."
license: Apache-2.0
compatibility: opencode
category: JIRA
---

## What I do

JIRA + Git utilities: discover accessible Atlassian resources / user / projects, create tickets from templates, derive branch names from ticket keys, and keep commits referencing tickets.

## When to use me

Creating a JIRA ticket before starting work; wiring ticket keys into branch/commit naming; any JIRA operation from a git workflow.

## MCP Availability Guard

Every step below uses `atlassian_*` MCP tools, and the `atlassian` MCP server is **disabled by default** (opt-in). Before Step 1:

- If `atlassian_*` tools are absent from your tool list, do NOT attempt or hallucinate them.
- Interactive: offer per-project enable via `opencode-repo-setup-skill` (effective next session).
- Fallback: REST with an API token — `curl -u email:token` against `https://<site>.atlassian.net` (cloudId: `curl https://<site>.atlassian.net/_edge/tenant_info`); scoped tokens use `api.atlassian.com/ex/jira/{cloudId}`.
- No credentials/headless: report the JIRA operation as skipped — never block the calling workflow.

## Workflow

1. **Accessible resources**: `atlassian_getAccessibleAtlassianResources` → cloudId + site name (feeds every later call).
2. **User info**: `atlassian_getUserInformation` → account id (assignee).
3. **Visible projects**: `atlassian_getVisibleJiraProjects(cloudId)` → pick project key.
4. **Create ticket**: `atlassian_createJiraIssue --cloudId --projectKey --issueTypeName --summary --description [--assignee_account_id]`. Description template: `## Description` / `## Type` / `## Context` / `## Acceptance Criteria` (checkboxes) / `## Files to Modify` / `## Notes`.
5. **Branch naming**: ticket key first — `feature/IBIS-123-short-slug` (key parses back out of the branch trivially); commits carry `Refs: IBIS-123` or `Closes IBIS-123` in footers (feeds `git-issue-updater-skill` / `jira-status-updater-skill` detection).

**Related:** `git-issue-updater-skill` (progress comments) · `jira-status-updater-skill` (post-merge transitions) · `ticket-creation-skill` (platform selection).
