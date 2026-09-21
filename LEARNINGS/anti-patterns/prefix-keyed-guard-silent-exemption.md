# Prefix-keyed guards silently exempt every unknown shape

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #468

## Symptom

Two generations of the same bug: (1) the #281 deploy guard validated only
`zai*` prefixes, so the broken anthropic `claude-haiku-4-6` pin shipped
unnoticed; (2) the pin test written to fix it skipped preset entries without
`.primary`, so a future shape change (renamed key, wrong nesting) would
escape both coverage and pin checks with a fully green suite.

## Root cause

A guard keyed by a known-prefix set exempts-by-omission: anything the author
didn't enumerate is silently outside the guard's jurisdiction, and the suite
stays green while proving nothing.

## Rule

Unknown shapes must FAIL, not skip, and exemptions must be explicit
allowlists with a "extend deliberately" message. The #468 fix: non-object
entries and primary-less preset objects are pushed into the broken list; the
openrouter/local presets are a named `LOCAL_PRESETS` allowlist referenced
from the data file's `$comment` so the two cannot drift silently.

Recurrence #3 (2026-09-21, #471 review): the credential schema pin hardcoded
the five remote preset names — a future provider without a credential block
would skip capture with a green suite; inverted to a LOCAL allowlist with
fail-on-bad-shape.
