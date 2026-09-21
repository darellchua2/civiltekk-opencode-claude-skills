# Guard error branches need negative fixtures in the same change

- **Category**: anti-pattern
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #468 (review round 2)

## Symptom

A review fix added two fail-loudly branches to the #468 pin checker
(non-object preset entry, missing `.primary`). Their correctness was proven
by a manual one-off run; the committed fixture still exercised only the
membership branch — so both new branches were silently deletable while the
suite stayed green.

## Root cause

Same genus as a multi-clause fix whose committed pins cover the old behavior
set: the fix changed
the guard's behavior set, but the committed pins covered the old behavior
set. Manual verification doesn't survive the next refactor.

## Rule

Every new error branch in a guard ships with a committed negative fixture in
the same change — construct the malformed input, run the guard, assert the
named error. One fixture per branch, not one per guard.
