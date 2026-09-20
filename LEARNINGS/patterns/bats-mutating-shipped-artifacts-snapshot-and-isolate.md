# Bats tests mutating shipped artifacts: snapshot/restore + private fixture copies

- **Category**: pattern
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #472

## Rule

Bats tests that mutate a shipped file snapshot/restore it in setup()/teardown
(cp to a mktemp path — a fixed /tmp name serializes future --jobs runs), and
fixture mutations go through a PRIVATE mktemp copy. #472's drop-fatal test
deleted a provider from the SHARED fixture and poisoned the three tests after
it — every one of them failed for a reason unrelated to its own assertion.
