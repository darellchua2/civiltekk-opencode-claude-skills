# Section pins must target resolvable heading anchors

**Category**: conventions
**Confidence**: 0.7
**Scope**: project
**Date**: 2026-09-27

## Convention

`§Name` reference pins in skills/agents prose should target real heading anchors, not bolded list labels. The repo's § convention is heading-anchored: `§MCP Availability Guard` → `ticketing-skill` §MCP Availability Guard (was `jira-git-integration-skill:17`, moved #599 with the heading preserved verbatim), `§Attribution` → `ticketing-skill` §Attribution (was `ticket-creation-skill:181`, moved #599), `§Branch Flow` → `version-bump-standard:31`. #595 introduced two `§Branch Naming` pins (plan-execution-skill:35, pr-creation-workflow-skill:27) that resolved only to a bolded workflow item in the pre-#599 `jira-git-integration` file — since #599 the branch-naming rule lives under ticketing-skill §Git Plumbing (a real heading), so those pins now resolve heading-anchored.

## Rule

When authoring or reviewing a `§` pin: verify the target is a heading (`#`-prefixed). If the content lives in a list item, either promote it to a heading in the owner or drop the `§Name` suffix and pin at skill level. Reviewers of pin-style docs check anchor resolvability, not just skill-name existence. Origin: #595 code review (NOTE).
