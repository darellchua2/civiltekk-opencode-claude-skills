# node -e argv has no script-name slot — slice(2) shifts args silently

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #468

## Symptom

A bats test passed `node -e "$SCRIPT" "$A" "$B"` with a checker that read
`process.argv.slice(2)`. Under `node -e`, argv is `[execPath, ...args]` —
there is no script-name slot like `node file.js` has. slice(2) dropped the
first real argument and shifted the rest; one test threw
(ERR_INVALID_ARG_TYPE) while a sibling test PASSED on meaningless shifted
inputs — a false green, not a crash.

## Rule

Inside `node -e` code, arguments start at `process.argv.slice(1)`. When a
multi-arg checker is reused across tests, add a comment stating the argv
shape, and make at least one test assert a named value from the LAST
argument so an off-by-one cannot pass vacuously.
