# Anti-pattern: Manifest claims a file the gate skipped

**Context**: Conflict-gated writes whose manifest records path-claims unconditionally (built before the gate decides).
**Pattern**: If the manifest object is constructed with `configPath`/`modelsPath` (or any owned-path claim) and the write is conflict-skipped, an unconditional claim converts a *warned skip* into a *silent clobber on the next run* — the next install sees `prevManifest.<path> === file` and overwrites without warning. Claim only files actually written this run: in the skip branch, reset the claim (`manifest.<path> = prevManifest.<path> ?? null`) so protection repeats until `--force`.
**Rationale**: The gate's warning is the user's only signal; a claim the tool didn't earn makes it fire exactly once and never again.
**Verification commands**:
- `bats tests/init.bats` — cases #412d/#412e: seed a hand-authored file, install twice without `--force`, assert the warning repeats and content survives; assert the manifest records `null` for skipped paths
**Trade-offs**: Skipped files are never pruned/cleaned by later runs (correct — we don't own them); stale claims from foreign paths are dropped as `null`.
**Confidence**: 0.95
**Scope**: project
**Date**: 2026-09-19

**Evidence**:
- Found in #412 review (CR-1): `installer/init.mjs` manifest built at :366 with `modelsPath: modelsFile` while the gate at :410-418 skipped the write → run 2 silently overwrote the hand-authored file the ticket existed to protect.
- `configPath`/ocFile twin was pre-existing on main (same claim-after-skip shape): hand-authored `opencode.json` silently overwritten on the second `add --project`; fixed in the same commit (root cause shared).
