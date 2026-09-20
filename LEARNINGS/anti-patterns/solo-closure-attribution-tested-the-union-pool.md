# Attribution loops must test membership in the per-source closure, not the union pool

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #473 (review round 1)

## Symptom

The #473 picker's provenance loop checked `pool.includes(name)` where `pool`
was the full combined closure — tautologically true for every item being
mapped, so every locked dependency was credited to the first solo entry in
insertion order, `locked-by:transitive` was unreachable, and the persisted
plan misrecorded who required what whenever more than one thing was selected.

## Rule

Per-source attribution iterates per-source closures and tests membership in
EACH (`res[poolKey].includes(name)`), falling through to a transitive
fallback only when no source claims the item. A union-pool predicate inside
an attribution loop is always-true.
