# Negated assertions are errexit-exempt — they can never fail a bats test

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #467 (review round 1)

## Symptom

A bats test line `! grep -q '^PATTERN' file` (asserting absence) passed even
though the file DID contain the pattern — the gate was a no-op and the false
green hid a vacuous sandbox.

## Root cause

bash's `set -e` does not trigger on a pipeline preceded by `!`: the negation
makes the failure "expected". A standalone `! cmd` line therefore never fails
the test, whatever `cmd` returns.

## Rule

Assert absence with `run grep -q …` followed by `[ "$status" -eq 1 ]`, or an
explicit `if grep -q …; then return 1; fi`. Same family as
`bats-and-chain-assertions-mask-nonfinal-links`: anything that blunts
errexit (chaining, negation) turns an assertion line into a comment.

## Evidence

- #537 (review round 1): the new `menu_option_six_routes_to_picker_path` pin
  shipped with `! echo "$output" | grep -q '|Deploy agents|'` negatives — the
  ticket's core "picker replaces blanket deploy" guarantee was unenforced.
  Fixed to `run grep -q … ; [ "$status" -eq 1 ]` against a steps file.
