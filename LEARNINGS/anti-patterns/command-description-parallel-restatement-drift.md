# Command-description parallel restatements drift when only the source is fixed

- **Category**: anti-pattern
- **Confidence**: 0.75
- **Scope**: project
- **Added**: 2026-09-22 (#524 plan review)

## Anti-pattern

Fixing a `commands.*.description` in `opencode_app/opencode.json` without
grepping its distinctive phrase repo-wide. The description is restated in
parallel prose the PLAN's consumer map misses.

## Instances

Two surfaced in one #524 review: `/run-plan`'s description is mirrored in
`README.md:624` (Git/Workflow category cell, "lint+build+test+e2e gate →
per-step traceability → commit → push") and anchored by
`docker-compose.yml:29-31` (healthcheck comment citing the description's
`/goal` mention). Fixing only the JSON would leave the repo's front door
promising a heavier gate than the tool runs.

## Rule

When a PLAN edits a `commands.*.description`, grep the description's
distinctive phrase repo-wide (README, compose comments, docs) and map every
hit before authoring steps.

Related: `anti-patterns/rule-added-example-stale.md` (same genus — parallel
teaching surfaces), `patterns/skill-add-count-sync-blast-radius.md`.
