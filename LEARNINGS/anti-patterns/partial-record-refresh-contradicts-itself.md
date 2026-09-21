# Partial record refresh contradicts itself

**Category**: anti-pattern
**Confidence**: 0.8
**Scope**: project
**Date**: 2026-09-20

## Anti-pattern

Refreshing a decision record's header or update-block while leaving body
counts stale creates in-file contradictions — contributors re-deriving
from the body re-introduce the exact drift the update fixed.

## Context

#481 review: `decisions/skill-permission-allowlist.md` got a refreshed
header (146/70) + update blockquote, but the body still said ~148/107/48
in the same file. The repo's own delta-derived-from-single-surface entry
documents counts propagating from reference docs into code.

## Fix

Either refresh EVERY count in the record in the same edit, or freeze the
stale body behind a dated "historical — see update above" label. Pair with
the sweep rule below: count-literal sweeps include LEARNINGS/.

Related: `anti-patterns/delta-derived-from-single-surface.md`,
`patterns/new-skill-count-literal-gates.md` (its line refs now use search
anchors for the same reason).

**Recurrence 2026-09-22 (#522):** the pattern bit its own tail — a LEARNINGS recurrence bump (#506 sweep-set file) updated the body prose to say "confidence bumped to high" while the structured header field and its `_index.md` mirror still read the old numeric value; caught by code review before merge. Generalizes to any structured-header + prose-body record: bump the field, the index mirror, and the prose in the same commit, or the next dedup search mis-sorts bump-vs-duplicate.
