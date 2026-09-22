# Single-sample parity probes miss type-conflict edges

- **Category**: anti-pattern
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #513

## Symptom

The node deep-merge snippet (#513, repo-setup) was declared "functionally
verified equal to jq `*`" on one well-formed sample — both sides plain nested
objects. The recurse condition type-checked only the base side, so three
type-conflict shapes diverged from jq: base-object vs delta-array merged index
keys into the object; base-object vs delta-number silently KEPT the base and
dropped the delta (worst case: the enabled server the user asked for vanishes
from opencode.json).

## Fix / Rule

Parity probes for merge/reimplement logic must include **type-mismatch fixtures
on both sides** (obj-vs-array, obj-vs-scalar, scalar-vs-obj, array-vs-obj) plus
the deep-merge happy path, compared against the reference implementation's
actual output — not a spot-check that "a plausible case works".
