# Conditional-mode blocks must supersede all restatements, not just the numbered list

- **Category**: pattern
- **Confidence**: 0.9
- **Scope**: project
- **Added**: 2026-09-18 (#399 architecture review)

A conditional-mode block in an agent/skill body (e.g. "in pipeline mode,
skip steps X/Y/Z") must explicitly supersede EVERY other restatement of the
skipped steps in the file — non-numbered sections, delegation bullets,
framework quality-checks sections, closing imperatives — and mark the list
non-exhaustive ("e.g."). Otherwise the un-superseded clauses stay in force
and the redundancy the mode was built to remove survives the fix.

Evidence: #399 feat/399 — pr-workflow-subagent PLAN.md Sync section,
docstring-sweep bullet, and closing "Always ensure all quality gates pass"
line all restated skipped steps; supersede sentence + "e.g." added per
architecture-review Major + Mode R round 1.
