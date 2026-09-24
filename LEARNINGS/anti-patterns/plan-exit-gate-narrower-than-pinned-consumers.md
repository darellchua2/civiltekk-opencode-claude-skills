# A PLAN exit gate narrower than the file's pinned consumers lets pinned-content deletion ship green

**Category**: anti-pattern
**Confidence**: 0.85
**Scope**: project
**Date**: 2026-09-24

## Anti-pattern

A PLAN that rewrites a file pinned by test suites must (a) list those suites
as consumers in its Dependency & Consumer Map AND (b) include them in its
exit-gate invocation. The ticket's named suites are a lower bound, not the
gate. PLAN-546 (#546) named only the ticket's four suites in its Phase 5 gate
while Phase 1 rewrote `skills/frontend-design-skill/SKILL.md` — a file pinned
by `tests/test_default_behavior.bats:835-847` (gating preamble exactly-once)
and `tests/test_autoresearch_protocol.bats:521-532` (Iteration Protocol
section, `metadata.protocol`, iteration-safety citation). Every named gate
could pass with a pinned line already deleted by prose compression; the break
would surface only as a red CI run at merge.

## Rule

When authoring a PLAN, grep the test suite for pins on every file the PLAN
edits (`grep -rl "<filename>" tests/`), add each pinning suite to the map and
to the exit-gate command, and carry the pinned strings as explicit constraints
in the editing steps' Done-when.

Extends `conventions/structure-pinning-tests-are-map-consumers` (map
membership) to gate scope.

Related: `done-when-gate-escapes-its-phase`, `dangling-cross-reference-in-ac`.
