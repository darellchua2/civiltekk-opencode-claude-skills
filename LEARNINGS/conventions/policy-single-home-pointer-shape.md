# Convention: Single-homed policy prose — copies are pointer + skill-specific only

**Context**: #434 single-homed the MCP Availability Guard into `jira-git-integration-skill` (canonical); 6 other locations became pointers.
**Pattern**: When single-homing policy prose, each dedup-target copy keeps exactly (a) a pointer naming the canonical file + § heading, and (b) skill-specific facts/endpoints the canonical lacks (e.g. its own REST path, its own skip clause). A compressed policy summary inside a copy is residual drift — same genus as `conditional-mode-blocks-supersede-all-restatements`. Short glosses belong to consumers (agents, pipeline skills citing inline), not to files that own a §-section of the policy.
**Rationale**: Pre-dedup copies had already diverged (ticket-creation taught a bare `{"disabled":false}` stub while v2 requires the FULL server entry); any restated ladder re-opens that vector at smaller scale.
**Confidence**: 0.85
**Scope**: project
**Date**: 2026-09-19
