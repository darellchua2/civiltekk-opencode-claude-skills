# Destination flips need a legacy-dir sweep in manifest-keyed lifecycle flows

**Category**: patterns
**Confidence**: 0.7
**Scope**: project
**Date**: 2026-09-25

## Pattern

A single-site destination flip in a table like `TARGETS` must add a legacy-column sweep (`legacyProjectSkillsDirs`) to every manifest-keyed lifecycle flow in the same change. Project manifests that store entry NAMES (not paths) recompute locations from the current table row, so after the flip `update` (re-`add`) writes only the new dir and `prune` removes only the new dir — pre-flip copies in the old dir silently survive, and both dirs stay live wherever the runtime unions discovery locations (OpenCode unions `.opencode/skills/` + `.agents/skills/`; pi scans `.agents/skills/`). Sweep scope = prev-manifest-owned names ∩ (re)installed or pruned names — claim-only-what-we-writes keeps user-authored dirs safe. Origin: #561 code review (Major) — `installer/init.mjs` `writeInstall`/`doPrune`.

## Anti-pattern signaled by

Fresh-install tests green after a destination flip while no test simulates a pre-flip leftover (`mkdir -p <old-dir>/<owned-name>` before re-add/prune). The orphan is invisible to clean-slate suites.
