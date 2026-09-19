# A hand-rolled YAML-subset parser cannot read a shape richer than the shapes it was built for

- **Category**: solution
- **Confidence**: 0.95
- **Scope**: project
- **Added**: 2026-09-17 (#380 plan review)

## Problem

`installer/build-registry.mjs` parseFrontmatter (:72-121) handles scalars and nested maps only.
Any plan that rewrites frontmatter into YAML **sequences** (`- action:` rule lists) while touching
only the downstream reader lines (:144-146) is unimplementable: the parser collapses a rules array
into `{"- action": "...", resource: "...", effect: "..."}` (last rule survives, keys overwrite) and
`fm.permissions.filter` throws `TypeError`.

## Fix / detection rule

- The parser extension IS part of the change surface — sequence support must land in the same
  commit as the files and the reader lines (a "pair" is actually a triple).
- Prove it before writing the plan: slice the parser into a /tmp harness (export via file copy —
  the function is module-private), feed it ONE hand-written target-shaped frontmatter, observe.
  Tier-4, ~20 lines, settles the question in one run.

## Evidence

- Executed proof (#380 review): legacy map parse preserves insertion order exactly
  (`["read","edit",...,"task","skill"]`, read `["*","mcp:*"]`, 17 skills / 4 delegates);
  target array parse returns an object and `.filter` → `TypeError: fm2.permissions.filter is not a function`.
- Census: 34/34 agents map-form, 0 odd shapes (no integer-like keys → JS object order safe).
