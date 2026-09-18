# Pattern: Per-phase commits must satisfy per-push CI gates — registry drift and test-pinned invariants need in-phase owners

**Context**: PLAN-409 review. Plans executed by plan-automation-loop commit + push per phase, and CI (release.yml) runs the full bats suite plus `node installer/build-registry.mjs --check` on every push.
**Pattern**: Any plan step that (a) changes an agent/skill frontmatter `description:` or adds/removes a skill, or (b) rewrites a SKILL.md body, must have its registry rebuild and its test-pinned invariants (Iteration Protocol heading, `metadata.protocol`, autoresearch reference citations, gating preamble, `results.tsv` scoping) owned WITHIN the same phase — not deferred to a later phase's sweep step.
**Rationale**: A description edit in Phase 1 with registry rebuild deferred to Phase 2 makes the Phase-1 commit fail `--check` by construction; the executor halts on its own gate. Count/README assertions live in test_markitdown_skill.bats, not test_count_drift.bats (which reads no README).
**Alternatives Considered**: Fix forward at the final full-suite step — rejected, red mid-pipeline pushes violate "never push red code".
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-19
