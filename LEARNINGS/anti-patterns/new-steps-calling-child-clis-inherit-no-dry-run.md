# Steps that shell out to child CLIs inherit no dry-run behavior

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #473 (review round 1, BLOCK)

## Symptom

The #473 select-consumption step ran `node init.mjs add <name>` with no
DRY_RUN handling — run_plan executes steps verbatim in dry-run, so a
`--select --dry-run` preview installed skills/agents into the user's live
config. run_cmd (the usual dry-safe wrapper) does not apply to child CLI
invocations.

## Rule

Any step that shells out to a child CLI forwards the child's own dry flag
with the boolean-safe form: `local dry=(); [ "$DRY_RUN" = true ] && dry+=(--dry-run)`
(never `${DRY_RUN:+}` — it fires on the string "false", see
colon-plus-on-boolean-string-flags). The PLAN-promised dry-run-leak test is
the net: pre-seed the input, dry-run, assert the live config is untouched.
