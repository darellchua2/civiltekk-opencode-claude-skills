# Transient cross-file contract drift between per-phase commits is safe iff pinned

- **Category**: pattern
- **Confidence**: 0.7
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #488

## Pattern

Editing a canonical contract and its deferring consumers in separate
per-phase commits creates a window where the consumer restates the stale
format (e.g. tierless memo after Phase 1, before Phase 2). The window is
safe iff (a) the stale surface already points at the canonical by name and
(b) no test pins the stale example — pre-verify both before relying on it;
do not "fix" by reordering phases.

## Evidence

#488: Phase 1→2 memo-format drift verified CI-invisible against
tests/*.bats before proceeding (architecture review, issue 4).
