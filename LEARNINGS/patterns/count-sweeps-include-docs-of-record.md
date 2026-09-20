# Count-literal sweeps must include docs-of-record

**Category**: pattern
**Confidence**: 0.75
**Scope**: project
**Date**: 2026-09-20

## Pattern

Count-drift sweeps scoped to `tests/ deploy/ README.md opencode_app/` miss
`LEARNINGS/` — the repo's docs-of-record. Their line-number citations rot
silently (new-skill-count-literal-gates.md cited README:397 and
setup.sh:3240 — all drifted within weeks).

## Fix

- Extend the sweep regex scope to include `LEARNINGS/` (and any
  docs-of-record directory) when the swept value is a count.
- In docs-of-record, cite search anchors (`run_skill_profile` header
  comments) instead of `file:line` — lines drift, anchors survive.
- Decision records: refresh every count or freeze the body dated (see
  `partial-record-refresh-contradicts-itself.md`).

## Evidence

#481 review NOTE: pre-existing stale refs in
`patterns/new-skill-count-literal-gates.md:8,10` — README cite drifted
:397→:408 and value 105→106; setup cites drifted by ~1000 lines.
