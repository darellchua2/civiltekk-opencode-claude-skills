# Flag-conflict guards vs value-flag parsers and late opts mutation

**Category**: anti-patterns
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-25

## Pattern

A conflict guard on two flags is only as complete as the parser's token handling and the opts-mutation timeline. #563's `-g`+`--project` guard missed two reachable states:

1. The hand-rolled long-flag parser (`if (next === undefined || next.startsWith("--")) opts[key] = true`) eats any non-`--`-prefixed next token as a VALUE — so `--project -g` consumed the short flag as the directory value, skipped the guard entirely, and installed into a junk `./-g` dir (execution-probed). Fix: value-branch must also refuse known short flags (`|| next === "-g"`).
2. `Object.assign(opts, interactive.opts)` (TUI path) sets `project` AFTER the main() guard fired — the guarded combination became reachable interactively. Fix: re-check after the assign.

Rule: when adding the FIRST short flag to a long-flag-only parser, probe BOTH flag orders in tests, and place conflict guards after the last opts-mutation site (or re-check there). Origin: #563 code review (Major ×2).

## Anti-pattern signaled by

A conflict test that only pins the canonical flag order (`-g --project`), and a guard placed at main() entry while a later code path mutates the same opts object.
