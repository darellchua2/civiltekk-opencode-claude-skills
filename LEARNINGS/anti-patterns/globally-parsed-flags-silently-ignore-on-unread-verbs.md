# Globally-parsed flags silently ignore on unread verbs

**Category**: anti-patterns
**Confidence**: 0.7
**Scope**: project
**Date**: 2026-09-26

## Pattern

`parseArgs` accepts every `BOOL_FLAGS` entry for every verb (`init.mjs:111`), so any verb handler that never reads a flag silently ignores it — `cmdAdd` ignored `opts.prune` until #567. Silent ignore is drift bait: users believe a side effect happened. The trap sharpens when honoring the flag would be destructive: prune is set-replace semantics, and single-name `add` + set-replace would delete every other manifest-owned entry (data loss) — so the fix is rejection, not implementation.

Review rule: for each verb handler, grep which parsed flags it reads; a parsed-but-unread flag on a mutating path is a latent silent-ignore bug. Fix pattern: first-statement explicit-rejection guard in the verb (single choke point before any branching — covers `--all`, named, and loop-dispatched paths since opts spread through), plus per-path fixtures pinning the exact exit code (`-eq 2`, not `-ne 0`). Origin: #567 code review.

**Update 2026-09-27 (#607 code review):** the class extends beyond verb
parsers to *selection surfaces*. Deleting an executor arm without sweeping
every surface that OFFERS the selection leaves the same silent no-op: #607
removed `apply_selected_packs_extras`' extras dispatch but initially left
`EXTRA_ITEMS` + the picker's "Extras" group (`installer/deploy-plan-items.mjs`,
`deploy/tui.mjs`), so `--select` users could still pick `local-llm`/`vllm` and
the deploy silently ignored them. Review rule, generalized: when deleting an
executor arm, sweep the picker inventory, the plan schema, and saved presets —
not just the flag parser.
