# Dry-run preview logs must not interpolate secret values

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #469 (review round 1)

## Symptom

A new DRY_RUN gate logged `Would set ${key}=${value} via setx` — for the
API-key variable that puts the full key into terminal scrollback and CI
transcripts on every preview run. The script's house convention redacts:
first8/last4 (:1958) or name-only with "(value suppressed)".

## Root cause

New run_cmd-style gates copy the "Would set K=V" shape from the .env writer,
where values were config (ports, paths) — not secrets. The shape is fine
until someone applies it to a key variable.

## Rule

Preview logs interpolate NAMES, never values, for anything reachable by a
secret-bearing variable; values only in redacted form and only when
diagnosis demands it. Same principle as the secret-hygiene rule "report key
NAMES, not values".
