# Recount claimed structural counts in PLANs — an unnamed element is an unrecorded scope decision

- **Category**: convention
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #470 (arch review round 2)

## Symptom

PLAN-470 said "remove the six early-exit blocks"; main() has seven. The
uncounted seventh (`--check-update`, setup.sh:4301-4304) carries the exact
defect the ticket exists to kill — `check_for_updates_only` returns 1 on
real failures (:3830/:3840) while the caller exits 0 unconditionally — and
would have survived outside the truthful-exit contract.

## Rule

When a PLAN enumerates structural removals BY COUNT, recount against source
and name every element. A count is a claim about scope; an element outside
the count is an unrecorded scope decision. Prefer naming all elements over
counting them.
