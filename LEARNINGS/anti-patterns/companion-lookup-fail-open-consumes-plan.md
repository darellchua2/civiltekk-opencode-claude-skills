# Fail-open derived-artifact lookups beside a consume-once plan deletion

- **Category**: anti-pattern
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-23
- **Ticket**: #537 (code review)

## Symptom

`apply_selected_packs_extras` fetched the plugin's companion list with an
unary-command substitution: `for comp in $(node -e '…' …); do`. If the node
lookup failed (corrupt/missing `dependency-map.json`), the loop iterated zero
times, `failed` stayed 0, and the function then deleted the deploy plan —
the plugin deployed broken with no warning and no re-run path. The error path
recreated the exact bug class the ticket existed to fix.

## Root cause

Command substitution failure in a `for x in $(…)` header is invisible: empty
output and failure are indistinguishable to the loop, and nothing downstream
checked status before the consume-once `rm -f` spent the plan.

## Rule

Every derived-artifact lookup inside a consume-once deploy function must fail
closed: capture on its own line (`local comps` would mask the status — declare
first, assign separately) with `|| { log_warn …; failed=1; continue; }`.
Empty-but-successful output stays a legitimate "no companions". Same family
as `guard-error-branches-need-negative-fixtures`: the failure branch is part
of the feature.
