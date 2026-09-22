# PLAN per-file census claims must be derived from the tree

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #514

## Symptom

PLAN-514 step 1.1 asserted a per-file frontmatter split without a tree grep —
first as "8 lack / 4 have", re-corrected (still without a grep) to "6/6" with
`opencode-skill-creation-skill` mislisted as having frontmatter `metadata:`.
Base-tree truth: 5 of the twelve Tier A files had a `metadata:` block, 7 did
not. Either wrong enumeration invites literal execution that creates duplicate
`metadata:` YAML keys — and every current gate stays green on that mistake:
`rg -l` counts files not blocks, build-registry's hand-rolled parser silently
merges duplicate map markers (build-registry.mjs:143), `--check` compares
derived fields only. Two independent review passes also mis-stated the census.

## Fix / Rule

Any PLAN claim enumerating files-by-shape ("N have X, M lack X") must carry —
or be preceded by — a captured tree grep, and plan reviewers must re-run it
rather than trust the PLAN text. Executors: re-run the census before the first
edit. A census corrected from memory is still an unverified census.
