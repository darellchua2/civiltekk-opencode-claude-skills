# Replacement edits need removal assertions, not just presence greps

**Category**: anti-pattern
**Confidence**: 0.8
**Scope**: project
**Date**: 2026-09-24

## Anti-pattern

A Done-when gate for a replacement-type edit that only asserts the new
marker's presence passes while older contradictory prescriptions remain in
place. PLAN-546 (#546) step 1.2 replaces "staggered beats + scattered
micro-interactions" with a stricter one-orchestrated-moment rule and greps for
"orchestrated" — but "IntersectionObserver for scroll reveals" and Step 5's
"scroll reveals" prescriptions survive elsewhere in the same file and the gate
stays green, shipping a self-contradictory skill. Worse, the grep term was
already green pre-work (`orchestrated` at SKILL.md:54 — the very line being
replaced), a premise-already-true sentinel.

## Rule

A step that replaces text X with text Y needs BOTH: a positive grep for a
unique Y marker (one that fails on the pre-edit file) and a negative
assertion (grep must NOT find X at its known locations). When picking
sentinels, grep the pre-edit file first; a sentinel that already matches is
not a sentinel.

Generalizes the recurrence note in `done-when-gate-escapes-its-phase`
("count matched, enumeration didn't").
