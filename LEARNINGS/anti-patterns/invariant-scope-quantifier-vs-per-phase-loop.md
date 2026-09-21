# Invariant scope: quantifier must match the loop it lives in

- **Category**: anti-pattern
- **Confidence**: 0.75
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #488

## Symptom

plan-execution 4c stated "The pushed SHA must carry a green `tier=full`
memo" inside a per-phase loop whose 4f/4g push every iteration — light-gate
phases legitimately produce only `tier=light` memos (code review #488).

## Rule

When editing prompt-level contracts, check each invariant's quantifier
against the loop it lives in: boundary invariants need an explicit scope
word ("**final** pushed SHA") so per-phase pushes cannot be read as
requiring full every time. Correct spelling: worktree-pipeline Step 9
"the **final** pushed SHA".
