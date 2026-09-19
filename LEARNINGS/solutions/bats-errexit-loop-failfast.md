# bats test bodies run under errexit — for-loop assertions are fail-fast

- **Category**: solution
- **Confidence**: 0.9
- **Scope**: project
- **Added**: 2026-09-19 (#417 review)

## Problem

Review knee-jerk: a bats `for` loop whose body is a bare `grep -q` / `cmp -s`
"only fails on the last iteration" — flag it as false-pass. False. bats-core
executes each test body under `set -e`; any failing command inside the loop
aborts the test immediately. The `run` helper exists precisely to capture
failures without tripping errexit, and `!`-prefixed commands are exempt.

## Rule

Do not flag multi-iteration assertion loops as silently-passing unless a
subshell, `run`, `|| true`, or a pipe actually swallows the status (e.g.
`cmd | grep -q` masks `cmd`'s exit, not grep's). Verified against
`tests/test_issue_template_byte_identity.bats` (loops at :15/:25/:32) —
fail-fast by construction; the repo-wide idiom
(`test_autoresearch_protocol.bats:35` etc., mid-test `[ ]` assertions in
`test_count_drift.bats`) relies on the same semantics.

## Evidence

#417 pre-commit review — initial false-positive BLOCK/WARN candidate retracted
after checking bats errexit semantics against the existing suite's mid-test
assertions.
