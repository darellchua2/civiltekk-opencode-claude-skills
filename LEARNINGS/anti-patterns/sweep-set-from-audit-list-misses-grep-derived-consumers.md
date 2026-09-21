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
