# Structure-pinning tests are first-class consumers for any refactor PLAN

- **Category**: convention
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #470 (architecture review)

## Symptom

PLAN-470's Dependency & Consumer Map listed runtime consumers only — and
missed three bats files that awk/grep the SOURCE SHAPE of functions:
test_skills_only_parity.bats (function-body extraction),
test_dry_run_leaks.bats (literal gate-string pins), deploy_delegate.bats
(first-occurrence line-order pin). Executing the refactor as planned would
have red-gated CI midway and tempted a "fix" that deletes the parity
guarantee the test exists to enforce.

## Rule

Any test that pins structure (function-body text, literal gate spellings,
definition order) is a consumer in the blast-radius map. For each: either
carry the pinned shape verbatim through the refactor, or schedule a
deliberate in-step re-pin — never leave it for the red gate to discover.
