# PLAN: installer target layer + shared ~/.agents/ target

**Branch**: feat/453
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/453
**Base**: main

## Acceptance Criteria

- [ ] `--target agents` installs skills verbatim to `~/.agents/skills/` and agents verbatim to `~/.agents/agents/`
- [ ] Target table drives dest dirs + transforms; existing `opencode` and `claude` target output is unchanged (no regression)
- [ ] Manifest entries record per-target content hashes; `update` copies only changed targets; `remove` cleans every probed target dir
- [ ] `--dry-run` previews new-target writes and writes nothing
- [ ] `node --test` + `bats` gates pass; README / `--help` / installer counts synced per repo documentation-sync rules

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` (`--target` validation, `writeUserScopeInstall`, `cmdUpdate`, `cmdRemove`, help text) | `installer/registry.json`, `installer/source.mjs`, `installer/tui-primitives.mjs` | `package.json` bin (`opencode-skill`, npx GitHub installs), `tests/init.bats`, `tests/update.bats`, `tests/parse_arguments.bats`, README install docs, root `AGENTS.md` §Repository Purpose | med |
| User manifest `~/.config/opencode/.skill-manifest.json` (schema: `entries.<name>.targets` + new `agents` key) | `init.mjs` write path | `cmdUpdate` (per-target re-copy), `cmdRemove` (probing), legacy-manifest upgrade path | med |
| `~/.agents/` install surface (new; `agents/` + `skills/`) | installer write path | Kimi Code CLI (reads `~/.agents/agents/` + `~/.agents/skills/`), pi (reads `~/.agents/skills/`) | low |

Cross-module consumers exist (tests, docs, bin) → architecture review selected. No frontend signal → no uiux review.

## Implementation Phases

### Phase 1: Target table + validation + preview

- [ ] **1.1** Extract the test contract from `tests/init.bats` + `tests/update.bats`: (a) how user-scope tests isolate `$HOME`, (b) every asserted dry-run JSON key for `add` and `update`.
    — **Why:** backward-compat constraints (AC: no regression) and test-isolation mechanics gate every later step; discovering them mid-phase would force rework.
    — **Done when:** assertion inventory + HOME-isolation mechanism recorded in Technical Notes below.
    — **Consumers affected:** all later phases.
- [ ] **1.2** Add `USER_AGENTS_SHARED`/`USER_SKILLS_SHARED` constants and a `TARGETS` table (target → dest dirs + transform mode); extend `--target` validation (`init.mjs:651`) to accept `agents`; update the `--help` `--target` line.
    — **Why:** single source of per-target dest+transform unblocks the write path and lifecycle; validation is the public contract.
    — **Done when:** `node installer/init.mjs add code-review-subagent --target agents --dry-run` exits 0 and names `~/.agents` paths; `--target bogus` still dies with usage; `bats tests/parse_arguments.bats` green.
    — **Consumers affected:** write path (Phase 2), update/remove (Phase 3), docs (Phase 4).
- [ ] **1.3** Generalize the user-scope dry-run preview (`init.mjs:660-673`): per-target destinations; preserve every existing JSON key byte-for-byte for `opencode`/`claude`/`both`.
    — **Why:** the preview JSON is an asserted contract (1.1 inventory); breaking keys fails gates and downstream scripts.
    — **Done when:** dry-run JSON for legacy targets has the identical key set as the 1.1 baseline; `agents` target preview lists `~/.agents` destinations; `bats tests/init.bats` green.
    — **Consumers affected:** bats suites, docs examples.

### Phase 2: agents-target install path

- [ ] **2.1** Implement shared-target skill install: verbatim `cp` of the skill dir to `~/.agents/skills/<name>/`; manifest entry gains `targets.agents = hashSkillDir(dst)`.
    — **Why:** core value — pi and Kimi read `~/.agents/skills/`; verbatim copy is safe because both loaders ignore unknown frontmatter.
    — **Done when:** `add --target agents --skills <name> --yes` creates the dir tree; manifest entry records `targets.agents`.
    — **Consumers affected:** `cmdUpdate`/`cmdRemove` (Phase 3), Kimi/pi users.
- [ ] **2.2** Implement shared-target agent install: write raw `agent.content` (NO `injectModelLine`) to `~/.agents/agents/<stem>.md`; record `manifest.agents` for shared-target installs (extend the `doOc`-only condition at `init.mjs:716`); entry `targets.agents = sha256Hex(content)`.
    — **Why:** foreign targets ship agents unpinned (ticket #453 decision); the raw content hash differs from the opencode-injected hash by design — per-target hashes (#379) already accommodate this.
    — **Done when:** installed file contains no `model:` line unless the source has one; manifest lists the stem; manifest `entries` carry both `opencode` and `agents` hashes after a `both`+`agents` install.
    — **Consumers affected:** `cmdUpdate` (Phase 3), Kimi users.
- [ ] **2.3** Regression sweep: in a temp `$HOME`, run full `add` for `opencode`, `claude`, and `both` and diff the manifests + written trees against the 1.1 baseline.
    — **Why:** AC demands zero regression on existing targets; a diff is the only objective proof.
    — **Done when:** manifest key-sets and written-tree shapes identical to baseline (modulo `generatedAt`).
    — **Consumers affected:** existing user installs.

### Phase 3: lifecycle (update / remove)

- [ ] **3.1** Rework `cmdUpdate` per-target loop: replace the "agents only ever install to the opencode target" assumption (`init.mjs:960`) — `installedPath` and `wouldHash` become target-dependent (opencode = model-injected content; agents = raw content); extend the `--prune` path (`init.mjs:944-946`) to remove shared files when `targets.agents` is present.
    — **Why:** `update` must re-copy drifted shared copies or the AC "update copies only changed targets" fails; prune must not leave orphans.
    — **Done when:** `update` re-copies a drifted `~/.agents` copy and leaves the `opencode` copy untouched; `--dry-run` reports per-target drift; `bats tests/update.bats` green.
    — **Consumers affected:** all manifest-tracked users.
- [ ] **3.2** Extend `cmdRemove` (`init.mjs:885-895`) to probe `~/.agents/agents/<stem>.md` and `~/.agents/skills/<name>/` alongside the existing opencode + claude paths.
    — **Why:** remove must clean every probed target dir (LEARNINGS: `legacy-upgrade-target-probe` — probe every historical target, not just the default).
    — **Done when:** remove wipes all three destinations for a multi-target install and cleans the manifest; single-target installs only remove what exists.
    — **Consumers affected:** users uninstalling.

### Phase 4: tests + docs + gates

- [ ] **4.1** Add bats coverage for the `agents` target: happy path (skills + agents), dry-run preview, update drift on a shared copy, remove probing — mirroring the 1.1 HOME-isolation mechanism.
    — **Why:** the AC requires lifecycle coverage; untested lifecycle code is where the probing regressions live.
    — **Done when:** new bats file green locally; no writes outside the isolated `$HOME`.
    — **Consumers affected:** CI.
- [ ] **4.2** Docs sync: README install section (new `agents` target + which tools read `~/.agents/`), `--help` text, root `AGENTS.md` §Repository Purpose target list.
    — **Why:** repo documentation-sync rules; undocumented installer surface breaks the repo's own contract (PLAN-418 precedent).
    — **Done when:** `rg -- '--target' README.md AGENTS.md installer/init.mjs` mentions all four values consistently.
    — **Consumers affected:** users, docs readers.
- [ ] **4.3** Full local gate: `bats tests/init.bats tests/update.bats tests/parse_arguments.bats` + new suite + `node --test tests/*.test.ts` + `bats tests/test_pack_permissions.bats tests/test_count_drift.bats`; record the `GATE <short-sha>` memo line for the pushed SHA.
    — **Why:** pipeline gate contract — the PR step cites this memo as its verification evidence.
    — **Done when:** every suite green; memo line emitted.
    — **Consumers affected:** code review (Step 9), PR creation (Step 10).

## Technical Notes

- **Manifest schema is already multi-target** (`entries.<name>.targets.{opencode,claude}` with written-content hashes, #379/#400): this PLAN adds an `agents` key — no schema migration needed. Legacy manifests upgrade via the existing `cmdUpdate` synthesis path.
- **Shared-dir collision risk:** `~/.agents/` may contain files owned by other tools (Kimi/pi). Current user-scope `add` overwrites installer-owned names without conflict checks; same behavior extends to `~/.agents/`. Mitigation for v1: document it; ownership tracking beyond the existing manifest is deferred.
- **1.1 contract inventory:** _to be filled by step 1.1 during execution (asserted dry-run JSON keys + HOME-isolation mechanism)._
- **Deliberately out of scope:** model pinning on foreign targets; `kimi`/`kilo` native targets (#454/#455 build on this table); MCP cross-platform config.
- Per-target agents hashing: opencode = `sha256Hex(injected)`, agents = `sha256Hex(raw)` — both stored under their own key; `update` recomputes the same way (mirrors the claude skill-strip asymmetry at `init.mjs:973-974`).

## Dependencies

- None blocked-by. Builds the foundation consumed by #454/#455/#457.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Dry-run JSON key drift breaks bats or downstream parsers | 1.1 inventories asserted keys first; 1.3 preserves them byte-for-byte; new keys only added |
| Tests pollute the real `$HOME` (`~/.agents`) | Mirror the existing bats HOME-isolation mechanism (1.1); 4.1 asserts isolation |
| `~/.agents/` name collisions with other tools' files | Documented v1 behavior (same as installer-owned dirs); manifest tracks what we wrote |
| Update loop regression on opencode-only agents | 2.3 regression sweep + 3.1 done-when asserts opencode copy untouched |
