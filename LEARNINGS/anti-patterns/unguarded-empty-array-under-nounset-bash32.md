# First unguarded empty-array `${arr[@]}` crashes stock macOS bash 3.2 under nounset

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #473 (review round 2)

## Symptom

`local dry_args=(); … "${dry_args[@]}"` under `set -o nounset`: bash < 4.4 (macOS stock /bin/bash 3.2.57) treats the expansion of an EMPTY declared array as unbound — real (non-dry) `--select` runs crash on macOS while dry-run (non-empty) and Linux CI (bash 5) stay green.

## Rule

setup.sh declares no minimum bash and uses no bash-4 features, so it must keep running on 3.2: every possibly-empty array gets a length-guard (`[ ${#arr[@]} -gt 0 ]`) or a scalar form (`local arg=""; [ cond ] && arg="--flag"`) before expansion. Precedent: the rc_files length-guard.
