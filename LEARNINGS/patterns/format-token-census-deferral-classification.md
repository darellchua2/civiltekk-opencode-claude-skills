# Format-token census classifies deferral-by-name as verified-compatible

- **Category**: pattern
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #488

## Pattern

A canonical-format change's blast radius = literal-token census
(`GATE <sha>`, `lint=t`): grep every restating site for the tokens, then
classify each hit update/no-change. Surfaces that defer by name only
zero-hit *by design* and take the "verified compatible" classification —
never invent changes for them. Name deliberate exclusions (immutable
history dirs) in the census record itself.

## Evidence

#488 Phase 4 census: 4 hit-groups, one true external consumer
(pr-creation-workflow-skill:25) updated; pr-workflow-subagent and
linting-subagent deferred by name and stayed untouched.
