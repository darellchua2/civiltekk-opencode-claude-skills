# Legacy manifest upgrades must probe every on-disk target, not just the default

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Evidence**: installer/init.mjs:881-891 (legacy synthesis hashes only USER_AGENTS/USER_SKILLS; USER_CLAUDE_SKILLS never probed).

A legacy manifest that recorded names but not per-target state loses the target set on upgrade. Synthesizing `entries` from only the default target silently stops maintaining the other targets: `update` never re-copies or prunes them (stale forever), while `remove`/`--prune` still delete them — inconsistent lifecycle. Upgrade loops must existsSync-probe every known target dir and record what they find. Found in #379 review; update.bats misses it because tests install the default opencode target only.
