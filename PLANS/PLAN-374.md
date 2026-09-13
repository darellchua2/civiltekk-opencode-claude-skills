# PLAN: Migrate configurator setup to OpenCode v2 (config + deploy tooling)

**Branch**: feat/374
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/374
**Base**: main

## Acceptance Criteria

- [ ] `opencode_app/opencode.json` uses native v2 shape only (`plugins`, `media`, `permissions` array, `commands`, `providers` with `package`/`settings`/`capabilities.*`, `mcp.servers` with inverted `disabled`, `agents`, `experimental.subagent_depth`)
- [ ] `deploy/resolve-models.mjs` reads/writes `agents.explore.model` / `agents.general.model`
- [ ] `deploy/apply-skill-profile.mjs` emits `permissions` array entries for skill gating
- [ ] `deploy/merge-packs.mjs` targets `mcp.servers.*.disabled` (inverted), `plugins`, `permissions`
- [ ] `deploy/setup.sh` + `deploy/setup.ps1` carry no v1-only key references
- [ ] `AGENTS.md` frontmatter contract tables use v2 key names
- [ ] All 6 affected `.bats` test files updated to v2 fixture shapes; full suite green
- [ ] `node deploy/build-registry.mjs` runs clean; regenerated `deploy/registry.json` committed
- [ ] Deploy dry-run stages a config containing zero v1-only keys
- [ ] `MIGRATION.md` / `README.md` config-shape references updated

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` | — | resolve-models.mjs, merge-packs.mjs, apply-skill-profile.mjs, setup.sh/ps1 echoes, tests/*, README/AGENTS docs, deployed user configs | **high** — silent-ignore trap: scripts writing v1 keys into a v2 file are silently dropped |
| `deploy/resolve-models.mjs` | opencode.json (v2) | setup.sh (`--models-only` path), built-in agent model pins | medium |
| `deploy/apply-skill-profile.mjs` | opencode.json (v2) | setup.sh skill-profile step, `deploy/skill-profiles.json` consumers | medium |
| `deploy/merge-packs.mjs` | opencode.json (v2) | setup.sh `--enable-pack`, tests/test_voice_pack.bats, tests/test_pack_permissions.bats, tests/test_docling_skill.bats | medium — `enabled`→`disabled` inversion is a logic flip, not a rename |
| `deploy/setup.sh` / `setup.ps1` | all deploy scripts above | end-user deploys, tests/test_mcp_count_consistency.bats | medium |
| `tests/*.bats` (6 files) | merge-packs.mjs + opencode.json (v2) | CI gate | low |
| `AGENTS.md`, `README.md`, `MIGRATION.md` | opencode.json (v2) | contributors, installer users | low |
| `deploy/registry.json` | opencode.json (v2), skill files (unchanged) | installer (`init.mjs`), build-site.mjs | low |

## Implementation Phases

### Phase 1: Config conversion (source of truth)

- [ ] **1.1** Convert `opencode_app/opencode.json` to native v2: `plugin[]`→`plugins[]`, `subagent_depth`→`experimental.subagent_depth`, `attachment`→`media`, `permission` map→ordered `permissions` array (`bash`→`shell`, `task`→`subagent`; `skill` map and bare tool-glob keys become `{action, resource, effect}` entries, deny-all skill entry first), `command`→`commands`, `provider`→`providers` (`npm`→`package` with `aisdk:` prefix, `options.baseURL`→`settings.baseURL`, `tool_call`/`modalities`→`capabilities.tools`/`capabilities.input`/`capabilities.output`, `cost.cache_read/write`→`cost.cache.read/write`), `mcp`→`mcp.servers` with `enabled`→inverted `disabled`, `agent`→`agents`
    — **Why:** single source of truth; every downstream consumer and test normalizes against this file, and the silent-ignore trap means no script fix is verifiable until the file itself is v2.
    — **Done when:** `jq . opencode_app/opencode.json` parses; `rg -n '"plugin"|"attachment"|"subagent_depth"|"command":|"provider":|"agent":' opencode_app/opencode.json` (v1 top-level keys) returns zero matches; `mcp.servers` entries all carry boolean `disabled`.
    — **Consumers affected:** all nodes in the Dependency & Consumer Map.

### Phase 2: Deploy tooling

- [ ] **2.1** Update `deploy/resolve-models.mjs` model-pin patching from `configObj.agent.{explore,general}.model` to `configObj.agents.{explore,general}.model` (lines ~288–301, incl. diagnostics labels)
    — **Why:** it writes the built-in explore/general pins; against a v2 file its v1 writes are silently ignored, leaving wrong tier models deployed with no error.
    — **Done when:** `node deploy/resolve-models.mjs --models-only` against the converted config emits diagnostics naming `agents.explore`/`agents.general` and stages a config with `agents.explore.model` set from `deploy/models.default.json`.
    — **Consumers affected:** setup.sh model-resolution step; deployed explore/general built-ins.

- [ ] **2.2** Update `deploy/apply-skill-profile.mjs` to read/write `permissions` array entries with `action: "skill"` (lean profile = keep allow-listed entries + the `{"*": "deny"}` catch-all; full = no-op)
    — **Why:** the lean profile currently rewrites the `permission.skill` object map; against a v2 `permissions` array it would drop the map entirely or corrupt gating.
    — **Done when:** applying the lean profile to the converted config yields a `permissions` array containing `{action:"skill", resource:"*", effect:"deny"}` plus one allow entry per lean-listed skill, and idempotent on re-run.
    — **Consumers affected:** setup.sh skill-profile step; users of `deploy/skill-profiles.json`.

- [ ] **2.3** Update `deploy/merge-packs.mjs` to merge into `mcp.servers` with inverted `disabled` flags, `plugins[]`, and `permissions` array; flip `enabled: true`→`disabled: false` semantics everywhere it currently toggles
    — **Why:** pack merging is the most complex consumer; the inversion is a logic flip, and missing it would enable servers that packs intend to enable only opt-in.
    — **Done when:** `node deploy/merge-packs.mjs --config <v2 fixture> --tui-config <tui.json> --packs-dir deploy/packs --packs voice` flips `mcp.servers.<target>.disabled` to `false`, leaves other servers untouched, and leaks no `tui` key.
    — **Consumers affected:** setup.sh `--enable-pack`; tests/test_voice_pack.bats, tests/test_pack_permissions.bats, tests/test_docling_skill.bats.

- [ ] **2.4** Update `deploy/setup.sh` and `deploy/setup.ps1` v1-key references: `plugin[]` mentions (setup.sh ~line 3517), permission/skill echoes, help text and count listings tied to config shape
    — **Why:** setup scripts both document and invoke the tools updated in 2.1–2.3; stale echoes would instruct users with v1 syntax.
    — **Done when:** `rg -n 'permission\.skill|plugin\[\]|"mcp"\.' deploy/setup.sh deploy/setup.ps1` returns no v1-shape operational references; `./deploy/setup.sh --dry-run` completes and stages a preview config with zero v1-only keys.
    — **Consumers affected:** end-user deploys; docs consistency tests.

### Phase 3: Tests

- [ ] **3.1** Update the 6 `.bats` files (`test_voice_pack`, `test_pack_permissions`, `test_mcp_count_consistency`, `skill_profiles`, `init`, `test_docling_skill`) to v2 fixture shapes: `mcp.servers.*.disabled`, `permissions` arrays, `plugins[]`, `agents`
    — **Why:** the suite is the CI gate proving the tooling flips are correct; stale fixtures would fail regardless of tooling correctness (or worse, pass against v1 leftovers).
    — **Done when:** full bats suite exits 0 from the repo root.
    — **Consumers affected:** CI; future contributors.

### Phase 4: Docs + registry

- [ ] **4.1** Update `AGENTS.md` frontmatter contract tables to v2 names (`disable`→`disabled`, `permission`→`permissions`, `temperature`/`top_p`→`request.body`, JSON `prompt`→`system`, `model#variant`) and note that source agent files remain legacy-translated until a later normalisation pass
    — **Why:** the contract table is what every future agent/skill edit is validated against; leaving v1 names would reintroduce v1 shapes.
    — **Done when:** contract tables contain no `disable`/`permission`/`temperature` v1 names for agents/skills; agent `.md` files left untouched (v2 auto-translates).
    — **Consumers affected:** contributors; opencode-tooling-subagent validation passes.

- [ ] **4.2** Update `README.md` and `MIGRATION.md` config-shape references (permission examples, MCP opt-in snippet, model tiering resolution notes)
    — **Why:** user-facing install/config docs teaching v1 syntax would produce broken setups post-deploy.
    — **Done when:** `rg -n '"permission"\s*:|"enabled":\s*(true|false)' README.md MIGRATION.md` returns no v1 config snippets (or matches only historical/migration-context text clearly labeled as v1).
    — **Consumers affected:** installer users; issue #304 individual-install flow.

- [ ] **4.3** Run `node deploy/build-registry.mjs` and commit regenerated `deploy/registry.json`
    — **Why:** house rule — any frontmatter/config-shape-adjacent change requires the registry rebuild and commit.
    — **Done when:** build exits 0 and `git status` shows `deploy/registry.json` diff committed.
    — **Consumers affected:** `init.mjs` installer, build-site.mjs.

### Phase 5: Validation gate

- [ ] **5.1** Run full verification: bats suite, `node deploy/build-registry.mjs`, `./deploy/setup.sh --dry-run`, and grep-based zero-v1-keys audit over the staged preview config
    — **Why:** final gate mirrors the repo's verification rules (lint/tests on logic changes; build on config changes) and proves the deploy pipeline emits v2 natively rather than relying on runtime normalization.
    — **Done when:** all commands exit 0 and the staged `opencode.json` contains none of: `plugin`(singular), `attachment`, `permission`(map form), `command`(singular), `provider`(singular), `agent`(singular), `mcp` without `.servers`, top-level `subagent_depth`.
    — **Consumers affected:** release pipeline; end users.

## Technical Notes

- From ticket #374: the silent-ignore trap (native v2 values take precedence; scripts writing v1 keys are silently dropped) is why Phase 1 and Phase 2 must land in the same change.
- `enabled`→`disabled` is **inverted**, not renamed — merge-packs toggling logic needs a semantic flip, not a find-replace.
- Nested mixing rules: `mcp`/`compaction`/`experimental` may mix v1/v2 members, but each `agents`/`providers`/`commands` entry must be entirely one format.
- Agent `.md` frontmatter and local plugins are explicitly out of scope (v2 auto-translates frontmatter; plugins are follow-up issues per ticket Non-goals).
- Reference: https://opencode.ai/v2/docs/migrate-v1/

## Dependencies

- None blocking (no `blocked-by:` tickets). OpenCode v2 binary NOT required in CI — validation is structural (JSON shape, greps, bats, dry-run staging).

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Permission-array conversion changes gating semantics (order matters in v2) | Preserve exact v1 precedence when flattening: deny-all `skill` catch-all first, specific allows after; verify against v1 file side-by-side |
| `enabled`→`disabled` inversion missed in a merge-packs branch | 2.3 done-when exercises the flip; voice-pack test asserts untouched servers stay `disabled: true` (was `enabled: false`) |
| resolve-models silently no-ops (the ticket's core trap) | 2.1 done-when requires staged config to show the pin, not just a clean exit |
| Scripts keep dual-shape support ambiguity | Convert fully to v2-only writes; no v1 fallback branches (repo deploys from single source of truth) |
| Docs drift (counts, snippets) | 2.4/4.1/4.2 grep gates + documentation-consistency check in review |
