# AC cross-references must resolve to a real artifact

- **Category**: anti-pattern
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #470 (arch review round 2)

## Symptom

PLAN-470's AC delegated full/quick/single-step step lists to "the table in
Technical Notes" — no such table existed (Technical Notes held only a
criticality list). Per-step atomicity checks (Why/Done-when/Consumers all
present) passed while the AC pointed at a nonexistent artifact, leaving pin
authoring (1.6) with unspecified expected values.

## Rule

Verify that AC cross-references RESOLVE inside the document, not just that
each step carries its rationale triple. A reference to a missing artifact is
a hidden spec hole the atomicity self-check cannot see — add a
reference-target check to the authoring self-check.
