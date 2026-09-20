# Conditionally-armed detectors need an always-armed complement

- **Category**: pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #467 (review round 2)

## Context

The #467 sandbox-escape detector (md5 of the worktree `.env` before/after a
test run) only arms when that file exists — never in CI, where the worktree
`.env` is absent. Paired with it, the positive control (real run MUST change
sandbox bytes) is always armed and catches the same regression class in CI.

## Rule

Any guard whose armament depends on machine state (a file existing, a tool
being installed, a var being set) must have a state-independent twin covering
the same regression class. Check both arms when judging "the suite caught
this": which tests fail in EACH environment, not just the one you ran.
