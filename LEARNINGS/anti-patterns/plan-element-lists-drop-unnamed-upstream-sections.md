# A merge PLAN's named-element list silently drops every upstream section it fails to name

**Category**: anti-pattern
**Confidence**: 0.85
**Scope**: project
**Date**: 2026-09-24

## Anti-pattern

A merge/upgrade PLAN that enumerates upstream guidance as a named element list
silently drops every upstream section the list fails to name — and the ticket
AC built from the same list cannot catch the drop, because AC and steps share
the blind spot. PLAN-546 (#546) named upstream tells + craft rules but omitted
Anthropic frontend-design's hero-treatment paragraph and the quality-floor
sentence (including visible keyboard focus); no step and no AC referenced
either, so the merge would ship without them and every gate would stay green.

## Rule

When a PLAN merges an upstream document, require a per-section delta table
(upstream section → step number, or explicit "dropped: why") before steps are
authored. The delta table, not the element list, is the completeness proof.

Related: `dangling-cross-reference-in-ac` (unresolved references inside ACs),
`case-sensitive-grep-gates-false-green` (gate-green ≠ content-complete).
