# PLAN: project-scope installs honor agent-overrides.json (#401)

**Branch**: feat/401
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/401
**Base**: main (c06bcde)

## Acceptance Criteria

From ticket #401:

- [x] project-scope install honors a global `~/.config/opencode/agent-overrides.json` pin (injected `model:` matches the pin)
- [x] a project-level `.opencode/agent-overrides.json` pin outranks the global one (resolver parity: project > global)
- [x] bats coverage for both precedence levels (fake HOME + temp project); no-pin behavior unchanged (existing tier default still injected)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` `agentModel` (:278) | — | user-scope `add` (:654), `cmdUpdate` (:934), project-scope `writeInstall` (new) | low |
| `installer/init.mjs` `writeInstall` agent loop (:381-388) | `agentModel` change | `models.json` artifact generation (uses `tierModels` cache — must keep populating) | low |

## Implementation Phases

### Phase 1: Precedence parity + bats

- [x] **1.1** `agentModel(stem, tier, provider, projectOverrides = null)`: new optional 4th param — if `projectOverrides?.[stem]?.model` exists, return it (project pin, highest); else global pin (existing behavior); else `tierToModel`. `writeInstall`: read `.opencode/agent-overrides.json` under the target project ONCE before the agent loop; pass it per agent; KEEP populating the `tierModels` cache per tier (the project `models.json` artifact at :399 still consumes it — pins are per-agent and may differ from the tier map, matching the artifact's `$comment`)
    — **Why:** CR-9: `--project` installs call `tierToModel` directly, so agent-overrides pins are silently ignored at project scope while user scope honors them — scope-dependent inconsistency. Resolver precedence (:210-215) is project > global > tier chain; init.mjs must mirror it.
    — **Done when:** `node --check`; fake-HOME bats: global pin → injected `model:` equals the pin; project pin + global pin → project pin wins; no pins → tier default unchanged.
    — **Consumers affected:** `writeInstall` output agents; `models.json` artifact unchanged; user-scope paths untouched (default param `null`).

- [x] **1.2** `tests/init.bats`: three new cases — fixture `add <fast-tier-agent> --project "$TMP_PROJ" --yes` with `HOME` exported to a temp dir; (a) global pin: seed `$HOME/.config/opencode/agent-overrides.json` with `{stem: {model: "test/global-pin"}}`, assert `.opencode/agents/<stem>.md` contains `model: test/global-pin`; (b) project pin wins: additionally seed `$TMP_PROJ/.opencode/agent-overrides.json` with `{stem: {model: "test/project-pin"}}`, assert `model: test/project-pin` (and not the global pin); (c) no-pin tier default BY VALUE (REQ-2): empty fake HOME + no project overrides → assert the injected `model:` equals the fast-tier value from `installer/models.default.json` (existing tests only grep `^model:` existence under the real HOME — indistinguishable from a pin on pinned machines)
    — **Why:** The ticket's acceptance demands executable proof at both precedence levels (fake HOME isolates the global read from the CI runner's real home); (c) pins the no-pin regression contract.
    — **Done when:** `bats tests/init.bats` green.
    — **Consumers affected:** CI.

**Phase gate:** full bats suite green; registry `--check`; public `add --dry-run` unchanged; user-scope `add`/`update` byte-identical (default param).

## Technical Notes

- Resolver's full tier chain inside `tierToModel` (provider > user models.json > default) is NOT extended with project tiers: init.mjs's project `models.json` is a generated artifact, not a precedence input — project tiers only exist via the resolver (`resolve-models.mjs`), which setup/Docker run separately. Out of scope: merging project `models.json` tiers into the install-time chain (would create a feedback loop with the generated artifact).
- A missing project overrides file reads as `null` → behavior identical to today.

## Dependencies

- None. Closes #401.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| `models.json` artifact regresses to all-`null` tiers if the cache is dropped in the refactor | Keep the `tierModels[tier]` population line; existing bats assert artifact contents |
| Per-agent `await agentModel()` re-reads the global overrides file N times | Pre-existing pattern (user scope does the same); file is tiny — acceptable |
