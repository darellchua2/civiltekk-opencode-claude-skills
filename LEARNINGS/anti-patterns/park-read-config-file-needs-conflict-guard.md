# Parking/renaming a runtime-READ config file needs a conflict guard

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Evidence**: #432 architecture review — deploy/setup.sh config phase parks a coexisting `opencode.jsonc` guarded on BOTH `[ -f "$CONFIG_FILE" ]` and the jsonc operand (feat/432 commit 9130a36); contrast the `config.json` park (safe unguarded — v2 never reads it) and the conflict-gate precedent in installer/init.mjs (#412).

Parking/renaming a config file the runtime actively READS (`opencode.jsonc`) has different safety semantics than parking one it ignores (`config.json`): an unconditional rename can silently disable a user's sole live config. Require a both-exist guard (or prompt), and park again on the copy-accept path so exactly one live config remains on every exit path. Found in #432 review.
