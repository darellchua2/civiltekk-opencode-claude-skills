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


## Evidence add (2026-09-23, #541)

Stale-BASE variant: a worktree's local `main` ref can lag `origin/main` (here by merged #540), making a true -2/+2 PR diff read as -2/+4 scope creep against `git diff main...HEAD`. Scope branch diffs against `origin/main`/merge-base, never the local main ref.

## Evidence add (2026-09-28, #515 instance)

False-positive variant: the reviewer probed its session cwd — a stale
main checkout missing the just-merged #514 metadata — and raised a BLOCK
("test 3 cannot pass; zero os: lines tree-wide") that was false on the actual
feat/515 branch (playwright carries `os: "linux"`; guard ran 5/5 green).
Static traces against a stale tree produce confident, wrong BLOCKs: re-verify
against the real branch HEAD (or state the cwd assumption and ask for a
tree-state probe) before reporting blocking findings.
