# set -E would arm the ERR trap inside plan steps — never add it while dispatch-by-call

- **Category**: solution
- **Confidence**: 0.75
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #470 (code review round 1)

## Context

setup.sh arms a global ERR trap (:487) but never sets `set -E`/errtrace, so
the trap never fires inside functions. This is LOAD-BEARING for the #470
plan executor: `run_plan` dispatches steps as `if ! "$func"` and step
functions deliberately `return 1` for warn-and-continue semantics.

## Rule

Do not add `set -E` "for better error traces" in setup.sh while the plan
executor dispatches by call: errtrace would fire the ERR trap (whose handler
exits 1) inside every returning step, bypassing the executor and the uniform
epilogue. If errtrace is ever wanted, the executor must switch to subshell-
isolated steps or the trap must be disabled around step dispatch.
