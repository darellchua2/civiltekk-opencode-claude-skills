# Parking/renaming a runtime-READ config file needs a conflict guard

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Evidence**: #432 architecture review + Mode R round 2 — deploy/setup.sh `park_jsonc_sibling()` (both-exist guard `[ -f "$CONFIG_FILE" ] && [ -f ...jsonc ]`, `run_cmd mv`) is called from THREE sites: config phase, copy-accept branch, and end of `run_resolver` gated on apply-mode success (feat/432 commits 9130a36, Phase 4); contrast the `config.json` park (safe unguarded — v2 never reads it) and the conflict-gate precedent in installer/init.mjs (#412).

Parking/renaming a config file the runtime actively READS (`opencode.jsonc`) has different safety semantics than parking one it ignores (`config.json`): an unconditional rename can silently disable a user's sole live config. Require a both-exist guard (or prompt), and scope the invariant to the script's END STATE — the resolver also writes `opencode.json` in apply mode (decline-copy path, `--models-only`/`--migrate-only`), so the park must run after the resolver too, not just in the config phase. Found in #432 review.
