# Section pins must target resolvable heading anchors

**Category**: conventions
**Confidence**: 0.7
**Scope**: project
**Date**: 2026-09-27

## Convention

`§Name` reference pins in skills/agents prose should target real heading anchors, not bolded list labels. The repo's § convention is heading-anchored: `§MCP Availability Guard` → `jira-git-integration-skill:17`, `§Attribution` → `ticket-creation-skill:181`, `§Branch Flow` → `version-bump-standard:31`. #595 introduced two `§Branch Naming` pins (plan-execution-skill:35, pr-creation-workflow-skill:27) that resolve only to a bolded workflow item (`5. **Branch naming**:` at jira-git-integration:34) — resolvable today because the file is 36 lines, but a reader (or agent) jumping to "the Branch Naming section" finds no such heading.

## Rule

When authoring or reviewing a `§` pin: verify the target is a heading (`#`-prefixed). If the content lives in a list item, either promote it to a heading in the owner or drop the `§Name` suffix and pin at skill level. Reviewers of pin-style docs check anchor resolvability, not just skill-name existence. Origin: #595 code review (NOTE).
