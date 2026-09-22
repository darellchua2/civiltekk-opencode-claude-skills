# CI runners lack ripgrep — bats guards must use grep

- **Category**: anti-pattern
- **Confidence**: 1.0
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #515

## Symptom

`tests/test_portability.bats` swept with `rg` — green locally (rg installed),
RED in CI on the first run: `rg: command not found` (exit 127) on
ubuntu-latest. Every sweep returned 127; tests 2–5 would have "skipped"
vacuously and test 1 failed — caught by the guard's own non-vacuous canary
before a dead guard could merge as green. Repo precedent: every pre-existing
bats test uses grep/POSIX tools only.

## Fix / Rule

Bats guards (and anything CI executes) must run on POSIX baseline tooling:
`grep -rlE --include=… --exclude-dir=…`, `find`, `awk`. If ripgrep is genuinely
needed, the CI job must install it explicitly. Capture the fix rule: options
array before positional args, `[[:space:]]` classes instead of `\s`, and a
non-vacuous canary so a 127-hosed sweep can never read as green.
