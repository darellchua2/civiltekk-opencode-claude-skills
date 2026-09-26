# Anti-pattern: hold/resume rules must match parked state

A hold/resume rule must name only artifacts the held item can have at its
hold point. Copy-pasting a resume clause (rebase + "continue at Step 7")
across holds located at different pipeline boundaries yields instructions
for nonexistent state: a ticket held at parse/body-fetch time has no
branch, worktree, or PLAN, so "rebase feat/<KEY> and continue at Step 7"
sends the executor to review a PLAN that was never authored on a branch
that was never cut.

Evidence: worktree-pipeline SKILL.md blocked-by hold vs 6f/10a overlap holds
(#560 review) — the same resume clause was correct only for the
post-PLAN-authoring holds. Fix: pin the hold's evaluation point, park with
whatever state exists, and make resume re-enter at the first unexecuted
step, rebasing only when a branch exists.

- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-25
