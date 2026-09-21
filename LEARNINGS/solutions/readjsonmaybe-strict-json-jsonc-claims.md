# readJsonMaybe tolerates only "$comment" lines — doc claims of JSONC stripping are false

- **Category**: solution
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #491 (review)

## Symptom

Two ticket PLANs (#470-era, #491) claimed `readJsonMaybe` strips JSONC
comments so commented configs patch cleanly. Reality: `stripJsonComments`
(resolve-models.mjs:80-83) removes only `"$comment":` lines; a `//`-commented
opencode.json throws at :75 BEFORE any write (writes happen at :400+) — loud
failure, no partial state, but not the tolerance the docs promised.

## Rule

Any doc claiming comment tolerance in the resolver must cite resolve-models.mjs:80-83
and describe the `"$comment"`-only scope. Commented configs fail loud by design.
