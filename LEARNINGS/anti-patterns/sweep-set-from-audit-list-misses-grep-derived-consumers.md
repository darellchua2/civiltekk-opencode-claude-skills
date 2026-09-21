# A repoint sweep derived from an audited-file list misses grep-derived sibling consumers

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #506 (code review WARN-3 + Mode R round 2)

## Symptom

#506 repointed the 9 files its audit flagged, but `tier-model-swap-blast-radius.md` — never audited, cross-referenced from the just-fixed `task-delegate-permission-sync.md` — still ran `node deploy/build-registry.mjs --check` and cited six other `deploy/` paths that moved to `installer/` in #378. Both of its verification commands failed with ENOENT the moment an auditor followed them. The sweep set came from the audit list, not from grepping the old path strings.

## Rule

When a path move (or rename) makes old strings dead, derive the repoint sweep from `grep -rn "<old-path-string>"` across all file types — every hit is either repointed or explicitly exempted with a dated note. An audit list is a lower bound, not the universe: sibling consumers cite the same dead paths and are found only by the string, not by the list. Gate the sweep on the same grep returning zero (modulo documented exemptions).

**Evidence**: `grep -rn "deploy/build-registry" LEARNINGS/` post-fix returns only this file's own mention; tier-model-swap's two verification commands re-run verbatim green on feat/506.

**Recurrence 2026-09-22 (#522 plan review):** the PLAN's consumer map was built from #520's audit list and missed 3 grep-derivable mechanical consumers of `installer/provider-models.json` (`installer/init.mjs:50` advisory note, `deploy/setup.sh:3229` check-catalog pass-through, `opencode_app/Dockerfile:96` flag pass-through) — all verified safe, map-completeness impact only. Same lesson, different artifact type: derive consumer maps by grep census of the changed file's name/path, not by inheriting the previous review's list. Confidence bumped to high.
