# An idempotency assertion over N invocations is vacuous with one invocation

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-23
- **Ticket**: #537 (code review)

## Symptom

A test asserted `find "$d/plugins/ponytail" -mindepth 1 -type d | wc -l` = 0
to pin the rm-first re-run safety of a directory copy — but the test invoked
the deploy function exactly once. Nesting (`ponytail/ponytail`) only occurs on
the SECOND copy into an existing dir, so deleting the `rm -rf` line kept the
suite green: the guarded line had no teeth.

## Root cause

The assertion's precondition (a previous invocation left state behind) was
never established by the test itself; it was only ever satisfied by a manual
run outside the suite.

## Rule

An idempotency/re-run pin must perform the N invocations it asserts about —
call the function twice inside the test, then assert the post-re-run
invariant. Kin of `guard-error-branches-need-negative-fixtures`: the
"already there" branch needs its fixture too.
