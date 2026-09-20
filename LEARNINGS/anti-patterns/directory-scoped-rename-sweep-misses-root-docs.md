# Directory-scoped rename sweeps miss repo-root docs that teach the spelling

**Category**: anti-pattern
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-20

## Anti-pattern

Scoping a frontmatter-vocabulary rename sweep to code dirs
(`agents/ skills/ installer/ deploy/ tests/`) leaves repo-root docs and
`opencode_app/` outside both the inventory and the rename steps — yet those
files teach readers to write present-tense config with the renamed-away
spelling, re-propagating the exact bug the rename fixes.

## Context

#482: `README.md:263` and `opencode_app/README.md:183` both teach
`action:"task"`; the drafted 1.2 sweep scope excluded them, and the drafted
2.4 completeness grep (`action: task`) was vacuous over the quoted no-space
form `action:"task"` — the proof would have passed while the sites sat
stale. `frontmatter-shape-change-blast-radius.md` consumer class 5 (docs)
names these exact files.

## Fix

- Sweep scope for frontmatter vocabulary changes: repo-root `*.md` +
  `opencode_app/` explicitly, always.
- Completeness greps must be form-insensitive:
  `action:?\s*["']?\s*(bash|task)` — a literal `action: task` pattern never
  matches `action:"task"`.
- Name the exclusions, don't discover them by accident: bash-binary
  detection (`deploy/setup.sh:271-284`, `setup.ps1:1341`) and
  migration-narrative mentions
  (`agents/opencode-v2-migration-subagent.md:117-118` documents the v1→v2
  translation itself — keep verbatim).

## Evidence

PLAN-482 rev 1 caught by architecture review; Mode R ruling 1 (#482,
2026-09-20).

Related: `patterns/frontmatter-shape-change-blast-radius.md`,
`anti-patterns/literal-only-path-sweep-misses-variable-indirection.md`
(the string-key sibling of this failure).
