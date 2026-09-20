# Uncoordinated `execute.before` writers on `event.input` — vibeguard restore vs. plugin payload rewrites

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Added**: 2026-09-20 (#448 plan review)

## Problem

Every local plugin that hooks `ctx.tool.hook('execute.before')` becomes a **concurrent writer**
on the same `event.input` field, with ordering decided by plugin glob order (an implementation
detail, currently alphabetical). `plugins/vibeguard.ts:490-496` registers an unguarded (all-tools)
hook that mutates `event.input` **in place** (`restoreDeep`) to unmask `__VG_…__` placeholders
before execution. Any new hook that *rewrites* `event.input` (repair/normalize/swap) interacts with
that restore:

- Full-string fills (copy field → field) are placeholder-safe: restore runs later over the new object.
- **Truncating fills are not**: deriving a short field (e.g. header ← first 30 chars) can split a
  `__VG_…__` placeholder, and broken placeholders fail to restore — the user then sees mangled mask
  text in the rendered tool UI.

## Rule

New `execute.before` writers must state their vibeguard interaction in the plan: either run after
restore is irrelevant (pure adds), or make every derived string placeholder-safe — when a fill
source contains the vibeguard prefix, copy verbatim (no truncation) or skip the fill. Add one
fixture with a placeholder-laden payload to the plugin's test file.
