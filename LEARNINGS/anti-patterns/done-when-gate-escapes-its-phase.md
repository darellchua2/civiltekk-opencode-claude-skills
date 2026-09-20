# Anti-pattern: done-when gate escapes its phase

A done-when gate whose pass condition depends on edits scheduled in a *later*
phase is unsatisfiable at its own step and forces either early cross-phase
edits or gate rot.

PLAN-487 step 2.2's worktree-wide zero-reference grep ran in Phase 2 while
the tests (Phase 3) and docs (Phase 4) still carried the old name — the gate
could not pass as written, pushing the executor to edit docs early (breaking
phase atomicity) or ignore the gate. Fix applied: scope 2.2 to functional
surfaces, move the exhaustive sweep to a Phase 5 gate (5.6).

**Rule:** scope each step's verification gate to the state that exists when
the step runs; put exhaustive end-state sweeps in the final gate phase.

- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
