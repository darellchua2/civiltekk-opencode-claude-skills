# Embedded diff hunks + a path claim are untrusted — reviewer probes .git/HEAD first

**Category**: anti-pattern
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-20

## Anti-pattern

A review prompt that embeds diff hunks AND names a repo/worktree path can
name the WRONG tree (main checkout instead of the feat worktree). The
reviewer that trusts the path reviews pre-change files, mismatches every
hunk, and either fabricates findings or wastes the round.

## Fix

The reviewer's FIRST act is a no-shell branch probe, before reading any
file:

1. `.git/HEAD` (or `.git` file → worktree gitdir) — confirm the expected
   branch.
2. Spot-check one cited hunk location (e.g. the renamed line) — confirm the
   claimed state exists.
3. On mismatch: fail fast with the probe evidence; do not review the
   prompt's copy of the diff.

Parent-side corollary: paste the path from `git worktree list` output, not
from memory — the main checkout path is one autocomplete away.

## Evidence

#482 pipeline Step 9: the review prompt embedded correct hunks but named the
main checkout; the reviewer probed `.git/HEAD` → `refs/heads/main`,
verified all 46 changed files absent, and blocked instead of fabricating
(feat/482 actually lived in `/home/silentx/VSCODE/worktrees/482`, pushed
5c53c39..9f62e00).

Related: `anti-patterns/unexpanded-cat-embedding-wrong-branch-cwd.md`
(#383 — same failure, `$(cat …)` flavor).

