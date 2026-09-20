# A dry-run leak test asserting only exit 0 has no teeth

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #473 (review round 2)

## Symptom

`select_dry_run_with_preseeded_plan_writes_nothing` asserted only `[ "$status" -eq 0 ]`. Walking it against the unfixed code: the child CLI (init.mjs add) has no TTY guard on the add path, so without the --dry-run forwarding it really installs and STILL exits 0 — the test passed on the exact regression it existed to catch.

## Rule

Leak nets assert the untouched SURFACE (no written artifacts, file count/content unchanged), never just the happy-path status. If a regression exits 0 while leaking, an exit-only assertion is a green lie.
