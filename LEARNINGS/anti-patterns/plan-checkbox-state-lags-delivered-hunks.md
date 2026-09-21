# PLAN checkboxes lag delivered hunks in the same diff

- **Category**: anti-pattern
- **Confidence**: 0.7
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #512

## Symptom

PLAN-512's Phase 3/4 checkboxes stayed unticked while their hunks shipped in the
same branch diff — the PLAN record contradicted the delivered tree, and the
run's "AC verified" claim inherited the stale state. Any later
`--gate`/`--update` pass re-executes or misreports those phases.

## Fix / Rule

Tick + Done-line each step in the SAME commit as its hunks (per-phase commit =
PLAN update + phase files together, per plan-execution-skill 4f). A phase is not
complete until its PLAN record is complete — "code pushed, plan unticked" is an
unfinished phase, not a documentation cleanup.
