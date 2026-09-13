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
| `opencode_app/opencode.json` | — | resolve-models.mjs, merge-packs.mjs, apply-skill-profile.mjs, **init.mjs**, **Dockerfile inline patch**, setup.sh/ps1 echoes, tests/*, README/AGENTS docs, deployed user configs | **high** — silent-ignore trap: scripts writing v1 keys into a v2 file are silently dropped |
| `deploy/init.mjs` | opencode.json (v2) | npx `add` installer flow (issue #304), tests/init.bats | **high** — reads source config at 4 sites (`init.mjs:195,414,425-427,868`) with silent fallbacks; writes v1 keys (`init.mjs:420,669-681`) into generated project configs |
| `opencode_app/Dockerfile` | opencode.json (v2) | docker standalone deploy (repo purpose #2) | **high** — inline python patch at lines 86–99 rewrites v1 `provider.*.options.baseURL`; pins `opencode-ai@1.18.20` (v1 binary) |
| `deploy/packs/*.json` | opencode.json (v2 shape decision) | merge-packs.mjs, pack tests | medium — pack data files carry v1 shapes (`pack-markitdown.json:3-8`, `pack-voice.json:7` `tui.plugin`) |
| `deploy/resolve-models.mjs` | opencode.json (v2) | setup.sh (`--models-only` path), built-in agent model pins | medium |
| `deploy/apply-skill-profile.mjs` | opencode.json (v2) | setup.sh skill-profile step, `deploy/skill-profiles.json` consumers | medium |
| `deploy/merge-packs.mjs` | opencode.json (v2) | setup.sh `--enable-pack`, tests/test_voice_pack.bats, tests/test_pack_permissions.bats, tests/test_docling_skill.bats | medium — `enabled`→`disabled` inversion is a logic flip, not a rename |
| `deploy/setup.sh` / `setup.ps1` | all deploy scripts above | end-user deploys, tests/test_mcp_count_consistency.bats | medium |
| `tests/*.bats` (6 files) | merge-packs.mjs + opencode.json (v2) | CI gate | low |
| `AGENTS.md`, `README.md`, `MIGRATION.md` | opencode.json (v2) | contributors, installer users | low |
| `deploy/registry.json` | opencode.json (v2), skill files (unchanged) | installer (`init.mjs`), build-site.mjs | low |

## Implementation Phases

### Phase 1: Config conversion (source of truth)

- [x] **1.1** Convert `opencode_app/opencode.json` to native v2: `plugin[]`→`plugins[]`, `subagent_depth`→`experimental.subagent_depth`, `attachment`→`media`, `permission` map→ordered `permissions` array (`bash`→`shell`, `task`→`subagent`, `write`/`patch`→`edit`; `skill` map and bare tool-glob keys become `{action, resource, effect}` entries, deny-all skill entry first), `command`→`commands`, `provider`→`providers` (`npm`→`package` with `aisdk:` prefix, `options.baseURL`→`settings.baseURL`, `tool_call`/`modalities`→`capabilities.tools`/`capabilities.input`/`capabilities.output`, `cost.cache_read/write`→`cost.cache.read/write`), `mcp`→`mcp.servers` with `enabled`→inverted `disabled`, `agent`→`agents`
    — **Why:** single source of truth; every downstream consumer and test normalizes against this file, and the silent-ignore trap means no script fix is verifiable until the file itself is v2.
    — **Done when:** `jq . opencode_app/opencode.json` parses; `rg -n '"plugin"|"attachment"|"subagent_depth"|"command":|"provider":|"agent":' opencode_app/opencode.json` (v1 top-level keys) returns zero matches; `mcp.servers` entries all carry boolean `disabled`; `rg -n '"action":\s*"(write|patch|bash|task)"' opencode_app/opencode.json` returns zero matches (action renames inside the array verified, not just top-level keys).
    — **Consumers affected:** all nodes in the Dependency & Consumer Map.
    — **Done:** converted via throwaway transform script (/tmp/opencode/convert-v2.mjs) to avoid hand-typing
      105 skill names; programmatic fidelity checks passed (skill allows 105/105 in order, read-rule order
      preserved broad→specific, 8/8 servers disabled-inverted, plugin count, agents renamed, no v1 keys,
      model attachment/reasoning dropped per v2 accepted-but-unsupported list, provider options→settings,
      tool_call/modalities→capabilities.*, cost.cache_read/write→cost.cache.read/write, npm→package with
      aisdk: prefix). Done-when note: the v1-keys grep was refined to map-form patterns (`"permission": {` etc.)
      because bare `"subagent_depth"` would false-positive on v2-native `experimental.subagent_depth`; top-level
      key absence verified via Node key check instead. Verified v2 precedence semantics against
      opencode.ai/v2/docs/permissions (LAST matching rule wins → deny-all skill first, allows after).
      files: opencode_app/opencode.json; fixes: none

### Phase 2: Deploy tooling

- [x] **2.1** Update `deploy/resolve-models.mjs` model-pin patching from `configObj.agent.{explore,general}.model` to `configObj.agents.{explore,general}.model` (lines ~288–301, incl. diagnostics labels)
    — **Why:** it writes the built-in explore/general pins; against a v2 file its v1 writes are silently ignored, leaving wrong tier models deployed with no error.
    — **Done when:** `node deploy/resolve-models.mjs --models-only` against the converted config emits diagnostics naming `agents.explore`/`agents.general` and stages a config with `agents.explore.model` set from `deploy/models.default.json`.
    — **Consumers affected:** setup.sh model-resolution step; deployed explore/general built-ins.
    — **Done:** config patch block (resolve-models.mjs:288-301) rewritten agent.*→agents.*; verified live via
      the same invocation setup.sh --models-only uses: resolver staged preview config with
      agents.explore.model=zai-coding-plan/glm-5.3-flash + agents.general.model=zai-coding-plan/glm-5.3,
      "(config patched)" emitted. Note: `--models-only` is a setup.sh flag (line 340), not a resolver flag —
      done-when executed through the resolver's real CLI surface instead.
      files: deploy/resolve-models.mjs; fixes: none

- [x] **2.2** Update `deploy/apply-skill-profile.mjs` to read/write `permissions` array entries with `action: "skill"` (lean profile = keep allow-listed entries + the `{"*": "deny"}` catch-all; full = no-op)
    — **Why:** the lean profile currently rewrites the `permission.skill` object map; against a v2 `permissions` array it would drop the map entirely or corrupt gating.
    — **Done when:** applying the lean profile to the converted config yields a `permissions` array containing `{action:"skill", resource:"*", effect:"deny"}` plus one allow entry per lean-listed skill, and idempotent on re-run.
    — **Consumers affected:** setup.sh skill-profile step; users of `deploy/skill-profiles.json`.
    — **Done:** full rewrite — reads/writes only `action:"skill"` rules in the `permissions` array, all other
      permission entries pass through untouched; rebuilt as deny-all-first + 46 sorted allows (v2
      last-match-wins). Verified: lean apply yields 47 skill rules (1 deny + 46 allow), 11 non-skill entries
      preserved (4 read + 7 tool globs), re-run idempotent (real before/after JSON compare).
      files: deploy/apply-skill-profile.mjs; fixes: none

- [x] **2.3** Convert `deploy/packs/*.json` data files to v2 shapes (mcp entries → `servers`-nested `disabled`, permission maps → `permissions` arrays, `tui.plugin` tuples → v2 plugin objects) AND update `deploy/merge-packs.mjs` to read those pack shapes and write `mcp.servers` with inverted `disabled` flags, `plugins[]`, and `permissions` array
    — **Why:** pack merging is the most complex consumer; the inversion is a logic flip, and packs carrying v1 shapes would either double-translate or fail silently. Repo-owned pack data converts alongside the merger (single format, no runtime translation ambiguity).
    — **Done when:** `node deploy/merge-packs.mjs --config <v2 fixture> --client-config <tui.json or cli.json per step 2.4> --packs-dir deploy/packs --packs markitdown` flips `mcp.servers.markitdown.disabled` to `false`, applies the pack's `permissions` entries, leaves other servers untouched, and leaks no `tui` key; same probe repeated for `--packs voice` covers the `plugins[]` path.
    — **Consumers affected:** setup.sh `--enable-pack`; tests/test_voice_pack.bats, tests/test_pack_permissions.bats, tests/test_docling_skill.bats.
    — **Done:** all 6 packs converted (mcp.servers nested disabled:false, permissions rule arrays, voice cli
      partial with {package,options} plugins); merge-packs.mjs rewritten — pack permissions APPEND with
      in-place replace on same action+resource (markitdown allow flips the shipped deny mid-array, preserving
      rule order like the v1 scalar deep-merge did), no wholesale array clobber. Probes passed: markitdown →
      servers.markitdown.disabled=false, docling untouched (disabled:true), no tui leak, 117 rules stable;
      voice → cli.json plugins object-form + keybinds merged; config+cli both idempotent on re-run.
      files: deploy/merge-packs.mjs, deploy/packs/pack-*.json (6); fixes: none (markitdown/nextjs pack writes
      initially landed mis-nested/mis-pathed during authoring; caught by post-write structural pass, rewritten)

- [x] **2.4** Decide and implement the voice-pack client-config target: v2 replaces layered `tui.json` with global `cli.json` (first v2 start one-time-migrates existing tui.json; post-migration tui.json writes are ignored) — verify the cli.json schema at https://opencode.ai/v2/docs/cli/config and point `merge-packs.mjs` plugin merging at `cli.json` `plugins` object form (`{"package": ..., "options": ...}`)
    — **Why:** writing plugin tuples to tui.json after a v2 client has created cli.json silently stops affecting the client — same silent-ignore class one layer removed.
    — **Done when:** merge-packs writes `plugins` entries to the configured client-config path in v2 object form; fallback write to `tui.json` only when explicitly requested via flag for v1-compat deploys; behavior documented in `--help` output.
    — **Consumers affected:** pack-voice users; tests/test_voice_pack.bats.
    — **Done:** cli.json schema verified (opencode.ai/v2/docs/cli/config: top-level keybinds, plugins array of
      strings or {package,options}; $schema https://opencode.ai/v2/cli.json). merge-packs: --client-config is
      the v2 primary (object-form plugins, merge by package name); --tui-config kept as explicit v1-compat
      fallback converting plugin objects → [name, options] tuples on write (verified: tuple output, tui.json
      $schema). Neither flag + cli pack → warning + skip (Docker path). Documented in file header.
      files: deploy/merge-packs.mjs, deploy/packs/pack-voice.json; fixes: none

- [x] **2.5** Update `deploy/setup.sh` and `deploy/setup.ps1` v1-key references: `plugin[]` mentions (setup.sh ~line 3517), permission/skill echoes, help text and count listings tied to config shape
    — **Why:** setup scripts both document and invoke the tools updated in 2.1–2.3; stale echoes would instruct users with v1 syntax.
    — **Done when:** `rg -n 'permission\.skill|plugin\[\]|"mcp"\.' deploy/setup.sh deploy/setup.ps1` returns zero matches; `./deploy/setup.sh --dry-run` completes and stages a preview config with zero v1-only keys.
    — **Consumers affected:** end-user deploys; docs consistency tests.
    — **Done:** setup.sh: pack help (`mcp.servers.<server>.disabled` +
      permissions-array wording), voice help → cli.json, skill-profile help +
      comments → "skill rules (action:\"skill\") in the permissions array",
      `plugin[]`→`plugins[]`, run_pack_merger now passes
      `--client-config ${CONFIG_DIR}/cli.json` (was --tui-config), dry-run
      stages cli.json; setup.ps1 mirrored ($targetCli, all comments/echoes).
      Gate: grep zero matches; bash -n / node --check clean;
      `./deploy/setup.sh --dry-run -y --enable-pack markitdown,voice
      --skill-profile lean` completed — preview opencode.json fully v2
      (58-rule permissions array, mcp.servers x8, agents x4, providers v2,
      markitdown.disabled=false, docling untouched) + cli.json object-form
      voice plugin.
      files: deploy/setup.sh, deploy/setup.ps1; fixes: none

- [x] **2.6** Update `deploy/init.mjs` for v2: `oc.mcp` enumerations → `oc.mcp.servers` (init.mjs:195,868), `src.mcp[m]` → `src.mcp.servers[m]` (:414), `src.agent.*` → `src.agents.*` (:425-427), generated `subagent_depth` → `experimental.subagent_depth` (:420), `--permit` writes → `permissions` array form (:669-681)
    — **Why:** the npx `add` installer flow (issue #304) reads the source config at 4 sites with silent fallbacks and writes v1 keys into generated project configs — post-conversion it ships MCP servers with no url/command and drops model pins with no error anywhere.
    — **Done when:** `tests/init.bats` passes against the converted source config (its `d['agent']['build']['permission']['task']` assertion at init.bats:95 updated to `agents`/`permissions` array form); a generated project config contains `mcp.servers.*` entries with real url/command values and `permissions` arrays.
    — **Consumers affected:** npx installer users; tests/init.bats.
    — **Done:** generator produces v2-native configs: mcp.servers.* (real
      command/url from source, disabled=false, no enabled key), permissions
      array (deny-all skill first + allows + tool-glob allows),
      agents.build/plan/explore/general with permissions arrays,
      experimental.subagent_depth=3, zero v1 keys; mcps listing + interactive
      picker enumerate oc.mcp.servers; --permit merges skill/subagent rules
      into permissions arrays (in-place replace, deny-all-first re-seed for
      v1-shaped configs, backup kept); checkStrictAllowlist reads array form;
      AGENTS.md note + help/usage text reworded. Verified: node --check clean;
      13-assertion live generator probe passes (real command/url from source);
      `--list mcps` emits v2 shape. init.bats assertion update lands in 3.1.
      files: deploy/init.mjs; fixes: none

- [x] **2.7** Update `opencode_app/Dockerfile`: bump pinned `opencode-ai` version ARG from `1.18.20` to a v2 build, and rewrite the inline python provider patch (lines 86–99) from `cfg["provider"][...]["options"]["baseURL"]` to v2 `providers.<name>.settings.baseURL`
    — **Why:** the baked `/app/opencode.json` becomes v2-native the moment Phase 1 lands; a v1 binary reading it is the exact combination the migration guide prohibits, and the v1-key patch silently no-ops under v2 keys. Scope delta vs ticket non-goal (base bump): minimal ARG bump + patch rewrite only, no Dockerfile overhaul; recorded as a ticket comment.
    — **Done when:** the pinned version resolves to a v2 release on npm (`npm view opencode-ai versions` contains it) and `grep -c 'provider"\]\[' opencode_app/Dockerfile` returns zero; `docker compose config` still parses.
    — **Consumers affected:** docker standalone deploys (repo purpose #2); docker-compose.yml users.
    — **Done:** inline patch rewritten to v2 (`providers.<n>.settings.baseURL`,
      setdefault guard). DEVIATION — ARG bump BLOCKED UPSTREAM: no installable
      v2 artifact exists (npm versions end at 1.18.30/latest=1.18.30;
      beta+dev tags are 0.0.0 snapshots whose only bin is `opencode.exe`,
      linux-broken; opencode.ai/install.sh → 404). ARG left at 1.18.20 and
      Dockerfile NOTE added; Docker standalone stays v1-binary/v2-config
      (broken by design) until upstream ships v2 — flagged for PR body +
      ticket comment. Verified: grep gate zero; python block compiles;
      `docker compose config` parses (compose hard-requires a .env —
      gitignored stub used for the check).
      files: opencode_app/Dockerfile; fixes: none

### Phase 3: Tests

- [x] **3.1** Update the 6 `.bats` files (`test_voice_pack`, `test_pack_permissions`, `test_mcp_count_consistency`, `skill_profiles`, `init`, `test_docling_skill`) to v2 fixture shapes: `mcp.servers.*.disabled`, `permissions` arrays, `plugins[]`, `agents`; `init.bats` updates are contingent on step 2.6 (init.mjs) landing first
    — **Why:** the suite is the CI gate proving the tooling flips are correct; stale fixtures would fail regardless of tooling correctness (or worse, pass against v1 leftovers).
    — **Done when:** full bats suite exits 0 from the repo root.
    — **Consumers affected:** CI; future contributors.
    — **Done:** all 6 files updated to v2 shapes (pack shape/merge tests, mcp-count
      disabled-flag assertions incl. auto-start=3 via `disabled:false` count,
      skill_profiles 45→46 allows + deny-all-first + non-skill preservation,
      init.bats generated-config assertions per 2.6 generator, docling pack/config
      v2 shapes). BUG FOUND + FIXED: merge-packs.mjs legacy `--tui-config` path
      wrote a `plugins` key instead of v1 `plugin` (v1 tui clients would never
      see merged plugins) — now keys by target format; new legacy-fallback test
      covers it. Also: setup.sh assertion --tui-config→--client-config (+ absence
      gate); bats-core submodule initialized in worktree (d9faff0, no tracked
      change). Full suite: 330 ok, exit 0. files: tests/{test_voice_pack,
      test_pack_permissions,test_mcp_count_consistency,skill_profiles,init,
      test_docling_skill}.bats, deploy/merge-packs.mjs;
      fixes: legacy plugin-key bug (fix-on-fail attempt 1).

### Phase 4: Docs + registry

- [x] **4.1** Update `AGENTS.md` frontmatter contract tables to v2 names (`disable`→`disabled`, `permission`→`permissions`, `temperature`/`top_p`→`request.body`, JSON `prompt`→`system`, `model#variant`) and note that source agent files remain legacy-translated until a later normalisation pass
    — **Why:** the contract table is what every future agent/skill edit is validated against; leaving v1 names would reintroduce v1 shapes.
    — **Done when:** contract tables contain no `disable`/`permission`/`temperature` v1 names for agents/skills; agent `.md` files left untouched (v2 auto-translates).
    — **Consumers affected:** contributors; opencode-tooling-subagent validation passes.
    — **Done:** contract table rewritten to v2 keys (`disabled`, `permissions` array of {action,resource,effect}, `request.body.temperature`/`request.body.top_p`, `system`, `model#variant`) + legacy-spelling deferred-normalisation note; agent `.md` files untouched; gate grep zero backticked v1 names; docs-verified stamp bumped to v2 2026-09-14. files: AGENTS.md; fixes: none

- [x] **4.2** Update `README.md` and `MIGRATION.md` config-shape references (permission examples, MCP opt-in snippet, model tiering resolution notes)
    — **Why:** user-facing install/config docs teaching v1 syntax would produce broken setups post-deploy.
    — **Done when:** `rg -n '"permission"\s*:|"enabled":\s*(true|false)' README.md MIGRATION.md` returns matches only inside sections whose heading contains "v1" or "migration" (historical context); every other hit converted to v2 snippets.
    — **Consumers affected:** installer users; issue #304 individual-install flow.
    — **Done:** MCP opt-in snippets + global-enable prose converted to v2 (`mcp.servers.<key>.disabled:false`) in both files; gate grep returns zero matches (stronger than the heading-gated allowance). files: README.md, MIGRATION.md; fixes: none

- [x] **4.3** Run `node deploy/build-registry.mjs` and commit regenerated `deploy/registry.json`
    — **Why:** house rule — any frontmatter/config-shape-adjacent change requires the registry rebuild and commit.
    — **Done when:** build exits 0 and `git status` shows `deploy/registry.json` diff committed.
    — **Consumers affected:** `init.mjs` installer, build-site.mjs.
    — **Done:** build exits 0 (agents=33, skills=148); registry.json diff is generatedAt-only (frontmatter untouched in a docs phase) and committed with the phase. files: deploy/registry.json; fixes: none

- [x] **4.4** Update v1-shape snippets and comments in deploy-adjacent docs and metadata: `deploy/.AGENTS.md` (ships to users' `~/.config/opencode/AGENTS.md` with `mcp.atlassian.enabled`, `permission.task`, `permission.skill` map snippets — lines 17/29/41), `deploy/dependency-map.json` header comment ("MUST match `mcp.<key>`"), `deploy/skill-profiles.json` header comment ("full = permission.skill"), `deploy/build-registry.mjs` header comment (line 13)
    — **Why:** `deploy/.AGENTS.md` teaches every deployed user v1 syntax; stale invariants in data-file comments mislead future maintainers even though the data itself is shape-agnostic.
    — **Done when:** `rg -n 'permission\.skill|permission\.task|"mcp":\s*\{|"enabled":' deploy/.AGENTS.md` returns only v2-form matches; the three header comments reference `mcp.servers`/`permissions` array semantics; `LEARNINGS/decisions/skill-permission-allowlist.md` and `LEARNINGS/solutions/plugin-needs-command-block.md` updated to reference the v2 mechanisms (living-doc bump).
    — **Consumers affected:** deployed users (via setup.sh copy), maintainers, future sessions relying on LEARNINGS accuracy.
    — **Done:** deploy/.AGENTS.md 4 snippets to v2 (atlassian mcp.servers.disabled, subagent permissions-rule gate, skill allowlist deny-all-first array form, read deny rule); 3 header comments reference mcp.servers / permissions-array semantics (+ v2 legacy-shapes note in build-registry.mjs); both LEARNINGS docs bumped to v2 mechanisms with v1-era evidence tagged; gate grep shows only the v2-form mcp.servers match; JSON parse + node --check clean. files: deploy/.AGENTS.md, deploy/dependency-map.json, deploy/skill-profiles.json, deploy/build-registry.mjs, LEARNINGS/decisions/skill-permission-allowlist.md, LEARNINGS/solutions/plugin-needs-command-block.md; fixes: none

### Phase 5: Validation gate

- [ ] **5.1** Run full verification: bats suite, `node deploy/build-registry.mjs`, `./deploy/setup.sh --dry-run`, and grep-based zero-v1-keys audit over the staged preview config
    — **Why:** final gate mirrors the repo's verification rules (lint/tests on logic changes; build on config changes) and proves the deploy pipeline emits v2 natively rather than relying on runtime normalization.
    — **Done when:** all commands exit 0 and the staged `opencode.json` contains none of: `plugin`(singular), `attachment`, `permission`(map form), `command`(singular), `provider`(singular), `agent`(singular), `mcp` without `.servers`, top-level `subagent_depth`.
    — **Consumers affected:** release pipeline; end users.

## Technical Notes

- From ticket #374: the silent-ignore trap (native v2 values take precedence; scripts writing v1 keys are silently dropped) is why Phase 1 and Phase 2 must land in the same change (single PR on one branch makes this structural).
- **Review decisions (plan review, this branch):**
  1. `deploy/init.mjs` is IN SCOPE (was unmapped) — it reads the source config at 4 sites with silent fallbacks and writes v1 into npx-generated configs; step 2.6.
  2. Docker: ticket non-goal ("base bump") is overridden minimally — ARG version bump + inline-patch key rewrite only (step 2.7); ticket gets a comment documenting this delta. Deferring would pair a v1 binary with a v2-native baked config, which the migration guide prohibits.
  3. `deploy/packs/*.json` convert to v2 shapes (repo-owned data), merge-packs consumes v2 packs — no runtime dual-format translation (step 2.3).
  4. Voice pack plugin merging targets global `cli.json` (v2) instead of deprecated tui.json, schema verified during implementation (step 2.4).
  5. `deploy/.AGENTS.md` (shipped user doc) + stale data-file comments fold into Phase 4 (step 4.4).
- `enabled`→`disabled` is **inverted**, not renamed — merge-packs toggling logic needs a semantic flip, not a find-replace.
- Nested mixing rules: `mcp`/`compaction`/`experimental` may mix v1/v2 members, but each `agents`/`providers`/`commands` entry must be entirely one format.
- Agent `.md` frontmatter and local plugins remain explicitly out of scope (v2 auto-translates frontmatter; plugins are follow-up issues per ticket Non-goals).
- Reference: https://opencode.ai/v2/docs/migrate-v1/

## Dependencies

- None blocking (no `blocked-by:` tickets). OpenCode v2 binary NOT required in CI — validation is structural (JSON shape, greps, bats, dry-run staging).

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Permission-array conversion changes gating semantics (order matters in v2) | Preserve exact v1 precedence when flattening: deny-all `skill` catch-all first, specific allows after; verify against v1 file side-by-side; 1.1 done-when greps action names inside the array |
| `enabled`→`disabled` inversion missed in a merge-packs branch | 2.3 done-when exercises the flip on pack-markitdown (real mcp+permission keys); voice test asserts untouched servers stay `disabled: true` (was `enabled: false`) |
| resolve-models/init.mjs silently no-op (the ticket's core trap) | 2.1/2.6 done-whens require generated/staged output to show the converted values, not just a clean exit |
| Docker standalone breaks: v1 binary + v2-native baked config | 2.7 bumps the pinned version and rewrites the inline patch in the same change; recorded as ticket scope delta |
| Pack client-config target (tui.json) ignored by v2 clients after cli.json exists | 2.4 targets cli.json object-form plugins, verified against v2 CLI config docs during implementation |
| Scripts keep dual-shape support ambiguity | Convert fully to v2-only writes; no v1 fallback branches (repo deploys from single source of truth) |
| Docs drift (counts, snippets, shipped user docs) | 2.5/4.1/4.2/4.4 grep gates + documentation-consistency check in review |
