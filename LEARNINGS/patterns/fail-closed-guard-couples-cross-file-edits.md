# A fail-closed guard couples cross-file edits into one atomic unit

**Category**: pattern
**Confidence**: 0.85
**Scope**: project
**Date**: 2026-09-20

## Pattern

When tooling fails closed on cross-file consistency (e.g.
`deploy/apply-skill-profile.mjs:74-81` exits 1 if a lean key lacks a
shipped full allow), any append to the consumer file and its prerequisite
in the source file are ONE atomic unit — they must ride the same commit,
together with their test-pinned mirrors, or the next deploy/CI run exits 1.

## Context

#481 plan review: Phase 2 appended 26 lean entries while the bats pins
lived in Phase 3 — every per-push CI run between the commits would be red
by construction. Restructured: config edits + count mirrors in one commit.

## Method

1. Before splitting phases, grep for fail-closed guards over the files
   you touch (`process.exit(1)`, `die(...)`, hard `assert` on cross-file
   state).
2. Each guard names its atomic unit — phase boundaries must not cut
   through it.
3. Test literals that pin the changed numbers ride in the same unit.

Related: `anti-patterns/delta-derived-from-single-surface.md`,
`patterns/new-skill-count-literal-gates.md`.
