# ERR-trap interpolations need nounset defaults — a crashing handler masks the real rc

- **Category**: solution
- **Confidence**: 0.9
- **Scope**: project
- **Evidence**: deploy/setup.sh:492 — global ERR trap read `error_handler "${BASH_LINENO[0]}" "$?"` unguarded; in sourced-script + bare-failing-call contexts (the bats `bash -c` stub idiom, tests/test_subcommands.bats:50) that array element is unset, so under `set -o nounset` the handler itself crashed (`BASH_LINENO[0]: unbound variable`) and bash surfaced the crash as exit 127 — hiding the function's real rc 1 and tripping bats BW01 on every suite run (#501; pre-existing on main, flagged in the #499 pipeline). Fixed with `"${BASH_LINENO[0]:-0}"`; pinned by tests/test_err_trap_nounset.bats (rc==1 AND no `unbound variable`).

**Audit rule for new traps**: every variable interpolated in a trap *action* string gets a nounset default (`:-`), because a trap can fire in contexts with a different variable universe than the authoring site — and a handler that crashes converts any non-zero into 127, masking the real return code. Prefer degrading the diagnostic (`line 0`) over rc masking. Related but distinct: `unguarded-empty-array-under-nounset-bash32` (empty-array expansion) and `errtrace-would-arm-the-err-trap-inside-steps` (`set -E` arming) — this is the third failure mode: unguarded *scalar/array-element interpolation inside the trap action itself*.
