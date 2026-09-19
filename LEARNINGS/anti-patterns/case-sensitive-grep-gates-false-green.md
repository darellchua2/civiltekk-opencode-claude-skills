# Case-sensitive / line-anchored grep gates false-green on file-tree prose

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Ticket**: #423

## Symptom

PLAN-423's 3.5 reference gate reported "reference greps empty", yet
`README.md:32` still documented the deleted symlink bridge:
`├── .opencode/  # Symlink bridge → root content (local serve only)`.

## Root cause

Two gate blind spots stacked:

1. The prose pattern `grep -rn "symlink bridge"` is case-sensitive — the tree
   entry says "Symlink bridge" (capital S), so it sailed through.
2. The path pattern `opencode_app[/\\]\.opencode` is line-anchored — ASCII
   file trees put the parent directory and the child entry on separate lines,
   so no single line ever matches the joined path.

Same failure class as `literal-only-path-sweep-misses-variable-indirection`:
the gate proves the *pattern* is absent, not that the *reference* is absent.

## Rule

Verification greps over prose must be case-insensitive (`grep -ri`). For
file-tree / ASCII-art doc blocks, additionally grep the bare child name
(`\.opencode/`) and the comment text ("bridge") separately — a joined
parent/child path never matches a split tree line.
