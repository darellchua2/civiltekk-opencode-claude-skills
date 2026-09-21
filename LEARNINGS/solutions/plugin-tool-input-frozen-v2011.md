## Pattern: opencode 2.0.11 freezes `question` tool input — plugins must write-back conditionally

**Context**: After the 2026-09-20 opencode 2.0.11 upgrade, EVERY `question` call
failed with `Attempted to assign to readonly property` before any part was
created — the whole prompt layer was dead (`/goal`, pipelines, intake). DB
forensics showed zero question parts since the upgrade date.

**Pattern**: 2.0.11 passes the question tool's (possibly all UI-interactive)
`execute.before` input as a **frozen object**; other tools' inputs stay
mutable, which is why only question broke. `walkDeep`'s unconditional
`node[key] = leaf(v)` wrote even when the leaf was identity → Bun readonly
throw. Fix: assign only when `next !== v && !Object.isFrozen(node)`
(opencode-vibeguard-v2.ts `walkDeep`; regression tests
`tests/test_vibeguard_walkdeep.test.ts`). Rule for all local plugins: **never
write to tool input unconditionally** — check change-first, and treat
provider-supplied objects as immutable. Bisect protocol that found it: stash
`~/.config/opencode/plugins/`, run `opencode run --standalone` with one plugin
at a time (question renders headless = pass).
