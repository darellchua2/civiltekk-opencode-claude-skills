# `${VAR:+word}` gates on non-emptiness, not truth — banned on boolean strings

- **Category**: anti-pattern
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #467 (review round 1, BLOCK)

## Symptom

`node … update ${DRY_RUN:+--dry-run}` looked like a clean dry-run gate, but
`DRY_RUN` is the *string* `"false"` when unset-flagged (setup.sh:326) —
non-empty, so `:+` expanded on every run. Real `--models-only` deploys
silently became permanent previews: the resolver applied, the manifest update
printed its dry JSON and changed nothing, and the script still said
"Model resolution complete!".

## Root cause

`:+` substitutes on unset-or-null only. For a flag holding `"true"`/`"false"`
strings, non-empty is always — the gate is a tautology.

## Rule

Boolean-string flags gate with a comparison plus a pre-initialized variable:
`local dry_arg=""; [ "$DRY_RUN" = true ] && dry_arg="--dry-run"` (the
`local …=""` matters under `set -o nounset`, setup.sh:60). `${VAR:+word}` is
reserved for genuinely optional-string variables. A semantics pin
(`DRY_RUN=false; echo ${DRY_RUN:+expanded}` → "expanded") documents why.
