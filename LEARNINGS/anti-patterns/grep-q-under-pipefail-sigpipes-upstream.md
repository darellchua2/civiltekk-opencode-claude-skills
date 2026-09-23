# grep -q under pipefail SIGPIPEs its upstream echo — the pipeline exits 141

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-23
- **Ticket**: #537 (exit-gate harness)

## Symptom

A verification script wrapped repo guards in `set -o pipefail` and ran CI's
tarball guard verbatim: `echo "$tarball" | grep -q " skills/" && …`. The
guard failed with exit 141 even though every grep matched when run
standalone — the `&&` chain fell through to `|| exit 1` and aborted the gate.

## Root cause

`grep -q` exits at the first match, closing the pipe early; under pipefail
the upstream `echo`'s SIGPIPE death (141 = 128+13) becomes the pipeline's
status, so the `&&` chain sees failure. CI runs the same guard under plain
`bash -e` (no pipefail) where pipeline status is grep's 0 — an identical
command is green in CI and red under a pipefail harness.

## Rule

When replaying CI guard lines in a stricter local harness, either drop
`pipefail` for the replay or avoid `grep -q` in pipelines — grep on the
captured variable (`[[ "$var" == *pat* ]]` or `grep -q <<< "$var"` still
SIGPIPEs under pipefail; prefer `printf '%s' "$var" | grep -q` only without
pipefail, or match with bash globbing). Any "works in CI, 141 locally"
mismatch on a guard line is this pattern first, a real regression second.
