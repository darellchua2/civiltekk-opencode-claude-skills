# PLAN: Phase 5 — Single install path + npx update command

**Branch**: feat/379
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/379
**Base**: main (ca5beaf — includes all four prior phases)

## Acceptance Criteria

From ticket #379, re-validated against `origin/main` @ `ca5beaf`:

- [ ] New `tests/update.bats`: fresh-install → mutate source → `update` re-copies; orphan reported; `--prune` removes; legacy manifest (no `entries`) upgrades cleanly
- [ ] `setup.sh` full run leaves `~/.config/opencode/.skill-manifest.json` populated (verified via the delegated CLI call; full-script fake-HOME run if the existing test harness supports it)
- [ ] No `setup.sh` path still copies agents/skills directly (grep gate: rsync/cp copy loops gone from the deploy path; `restore_from_dir` backup-restore exempt)
- [ ] README "Testing & Development" section added (clone dry-run, `npm link`, branch-ref npx, sandboxed HOME, CI)
- [ ] bats full suite green; registry drift clean; public `npx … add <name>` unchanged

**Re-validation notes:** agents are written today by `resolve-models.mjs` (copy + model inject via `run_resolver` args `--agents-src/--agents-dest`), skills by the rsync loop in `setup_config` (:2548-2562, overwrite prompt + `_archived` exclusion). `init.mjs` `writeUserScopeInstall` already writes agents WITH model injection (`tierToModel` + `injectModelLine`) and skills, and writes the manifest (:615-625) — but `tierToModel` reads only `models.default.json` + provider presets, NOT the user `models.json`/`agent-overrides.json` precedence the resolver honors. `cmdRemove` :770 carries the "not tracked" message this ticket kills. There is no `--all` selection and no `update` command (`main()` dispatch :809-813).

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` manifest schema (`entries` + sha256) | Phase 1 precedes update | `update` cmd, `remove`, `--prune`, setup.sh AC | high |
| `installer/init.mjs` `update` command | Phase 1 (hash util + entries) | npx users, `tests/update.bats` | high |
| `installer/init.mjs` `--all` selection + `tierToModel` user-precedence | precedes Phase 4 | setup.sh delegation, `add` users | high |
| `deploy/setup.sh` `deploy_agents`/`setup_config`/`run_resolver` args | Phase 3 precedes | full-deploy users, bats (count/dry-run/default-behavior), Docker (unchanged — Dockerfile resolver call keeps agents args) | high |
| `deploy/setup.ps1` mirror blocks | track setup.sh exactly | Windows users (grep-verified only) | med |
| `installer/resolve-models.mjs` | arg-drop only in the setup.sh call site (script keeps full capability for Docker) | Dockerfile :63-74 (unchanged), setup.sh | med |
| `tests/*.bats` (update.bats new; existing suites touching setup paths) | per-phase | CI | med |
| `README.md` Testing & Development | behavior lands first | humans | low |

## Implementation Phases

### Phase 1: Manifest `entries` + content hashes (5b)

- [ ] **1.1** `installer/init.mjs`: add `sha256Hex` helper + `hashSkillDir(dir)` (deterministic tree hash: sorted relative paths + file contents, `_archived`-safe) + `hashAgentContent(str)`; extend the user-scope manifest write (:615-625) with `entries: { <name>: { type: "agent"|"skill", targets: [...], hash: "sha256:<hex>" } }` — targets from the current install (`["opencode"]`, `["claude"]`, or both), agent hash over the WRITTEN file content (post model-injection), skill hash over the written dir; legacy `agents`/`skills` arrays unchanged; merge preserves existing entries for untouched names
    — **Why:** `update` needs per-entry hashes to detect drift and per-target records to know where to re-copy; hashing written (not source) content avoids false positives from model injection.
    — **Done when:** fake-HOME `add tdd-subagent --yes` manifest shows `entries.tdd-subagent` + `entries.plan-updater-skill` with sha256 hashes and `targets:["opencode"]`; re-run leaves previous entries intact.
    — **Consumers affected:** `remove`, future `update`, setup.sh AC.

### Phase 2: `update` command (5c)

- [ ] **2.1** `installer/init.mjs`: `update [--prune] [--dry-run] [--yes]` (user scope) — load manifest; for each `entries[]` name still in the registry, recompute would-write content hash (agent: readAgent+tierToModel+injectModelLine; skill: source dir tree hash); compare vs stored hash → re-copy changed to recorded targets (agents to opencode target only; skills to each recorded target with `stripModelLine` for claude), rewrite manifest entries; entries missing installed files → `missing`; manifest names absent from the registry → `registryRemoved` (reported, never deleted without `--prune`); `--prune` removes registry-removed entries (files + manifest rows); legacy manifest without `entries` → synthesize entries from `agents[]`/`skills[]` arrays by hashing current installs, then proceed (backward-compatible upgrade); report line `updated N · unchanged M · missing K` + `registryRemoved R` (+ `pruned P`); `--dry-run` prints the JSON plan and writes nothing; after real runs, run the strict-allowlist visibility check (name-stable updates make the permissions union a no-op; warn-only). Help text entry.
    — **Why:** The ticket's core UX: upgrade installed skills without a full-script rerun, manifest-tracked end to end.
    — **Done when:** fake-HOME sequence: `add X --yes` → mutate source skill file → `update` re-copies (hash + file changed); orphan (registry-removed) reported; `--prune` deletes it; hand-written legacy manifest upgrades cleanly.
    — **Consumers affected:** npx users; `tests/update.bats`.

- [ ] **2.2** New `tests/update.bats` (fake HOME): (a) fresh-install → mutate source → update re-copies; (b) orphan reported not deleted; (c) `--prune` removes; (d) legacy manifest without `entries` upgrades cleanly; (e) `--dry-run` prints plan, writes nothing
    — **Why:** Ticket AC demands executable proof of all update behaviors.
    — **Done when:** `bats tests/update.bats` green.
    — **Consumers affected:** CI suite.

**Phase gate:** `node --check`; `bats tests/update.bats tests/init.bats`; registry `--check`.

### Phase 3: `--all` selection + user-precedence for `tierToModel` (5a prep)

- [ ] **3.1** `installer/init.mjs`: `add --all` builds the full selection (every registry agent + skill) non-interactively; `tierToModel` gains the resolver's user precedence — per-agent `~/.config/opencode/agent-overrides.json` > tier from `~/.config/opencode/models.json` > current path (presets-with-provider / `models.default.json`) — cribbing the resolution order from `resolve-models.mjs`
    — **Why:** setup.sh's delegation needs a full-catalog install in one call, and the installer's model injection must honor the same user overrides the resolver did or full deploys silently lose per-agent pinning.
    — **Done when:** fake-HOME: `add --all --yes` installs 34 agents + 149 skills with manifest entries; a user `agent-overrides.json` pin changes the injected model for that agent (assert in bats or gate manually).
    — **Consumers affected:** `add` users (new flag), setup.sh Phase 4.

### Phase 4: setup.sh/ps1 delegate content to the CLI (5a)

- [ ] **4.1** `deploy/setup.sh`: new `deploy_content()` invoked from `main()` where skills/agents deploy happens today — calls `node "${INSTALLER_DIR}/init.mjs" add --all --yes --provider "${PROVIDER:-zai}"` (+ `--dry-run` passthrough when `DRY_RUN=true`); remove the skills rsync/cp loop + overwrite prompt from `setup_config` (:2546-2563) and drop `--agents-src/--agents-dest` from the `run_resolver` call (:3023-3024) so the resolver resolves CONFIG only (script capability unchanged — Dockerfile still passes agents args); keep migration/lift BEFORE `deploy_content`, packs/profile AFTER; keep counts/banners reading source dirs; backup/rollback (incl. `restore_from_dir`) untouched
    — **Why:** One install path: every install manifest-tracked; kills the :770 "not tracked" gap; setup keeps config/plugins/MCP/packs/profiles/backup per ticket scope.
    — **Done when:** fake-HOME `setup.sh --yes` (or the reduced path bats can drive) populates `~/.config/opencode/.skill-manifest.json`; `grep -nE 'rsync .*skills|cp -r .*SKILLS_DIR|agents-dest' deploy/setup.sh` shows no deploy-path hits (restore/backup exempt); `bash -n` + `--dry-run` pass.
    — **Consumers affected:** every full-deploy user; bats suites on setup paths.

- [ ] **4.2** `deploy/setup.ps1`: mirror `deploy_content` (`node $InitDir\init.mjs add --all --yes`), remove the skills copy loop, drop agents args from the resolver call — separator-agnostic grep gates
    — **Why:** Windows mirror parity.
    — **Done when:** separator-agnostic greps return 0 deploy-path hits; structure mirrors 4.1.
    — **Consumers affected:** Windows users (grep-verified only — no pwsh on runner).

- [ ] **4.3** Rewrite bats tests that assert the old copy paths (survey `test_default_behavior`, `parse_arguments`, `test_count_drift`, `test_backup_rollback` for skills-copy/deploy assertions; retarget to the CLI call + manifest) — keep backup/rollback tests untouched
    — **Why:** CI must gate the new path, not the removed one.
    — **Done when:** full `bats tests/` green; no test references the removed rsync loop.
    — **Consumers affected:** CI.

**Phase gate:** full bats suite; `bash deploy/setup.sh --dry-run` exit 0; manifest-populated proof (4.1 done-when); grep gates both scripts.

### Phase 5: Testing & Development docs (5d) + final sweep

- [ ] **5.1** `README.md`: add "Testing & Development" section — clone + `node installer/init.mjs add X --dry-run`; `npm link` for the bin; branch testing via `npx github:darellchua2/opencode-config-template#<branch> add X --dry-run`; sandboxed runs with `HOME=<tmp>`; CI note (`--yes`/`--dry-run` enforced); one `update` example
    — **Why:** Ticket 5d — contributors need the recipes; they double as the maintainer verification kit.
    — **Done when:** section exists with all five recipes; commands copy-pasteable.
    — **Consumers affected:** contributors.

- [ ] **5.2** Final sweep: `grep` for stale "not tracked by opencode-skill" messaging (`installer/init.mjs` :770 note becomes false post-5a — reword to reference `update`/`remove`); help text lists `update`; CHANGELOG-facing notes in PR body
    — **Why:** The old gap message is now false; docs must not teach the dead limitation.
    — **Done when:** `grep -rn 'not tracked' installer/ README.md` clean; help shows update.
    — **Consumers affected:** users reading remove/update output.

**Phase gate:** full bats suite; registry `--check`; `npm pack --dry-run` shows installer/; all ACs re-checked.

## Technical Notes

- `npx github:` always pulls HEAD — no version pinning (ticket note); npm publish stays the optional follow-up.
- Hashes cover WRITTEN content (post-injection for agents, post-strip for claude skill copies) so `update` never false-positives on deterministic rewrites; update recomputes would-write hashes rather than diffing source vs installed bytes.
- Resolver keeps full capability (Docker build path unchanged — Dockerfile :63-74 still passes `--agents-src/--agents-dest`); only the setup.sh CALL drops the agents args.
- Order in main(): migration/lift → deploy_content (CLI) → run_resolver (config-only) → pack merger → skill profile. lift_customizations reads deployed agents, so it must precede the CLI overwrite.
- setup.sh `--dry-run`: CLI receives `--dry-run` (prints JSON plan, writes nothing) — parity with the old staged-preview behavior at the "no writes" level (the resolver's `--preview-dir` staging remains for config).
- Legacy manifest upgrade (2.1d) makes pre-#379 installs (name arrays only) immediately update-able.

## Dependencies

- Branch cut from `ca5beaf` (all four prior phases merged: installer/ split, `--target`, v2 frontmatter normalization).
- Closes the epic #376 (last phase).

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Full-deploy behavior regression (overwrite prompt semantics lost, counts drift) | 4.1 keeps source-dir counts/banners; backup still runs before overwrite via existing backup flow; bats rewrite asserts manifest + counts |
| `tierToModel` precedence divergence from resolver | Phase 3 crib + targeted assertion; resolver stays source of truth for config |
| update hash false-positives (injection noise) | Hash written content; update recomputes would-write; update.bats (a) proves re-copy on real mutation and idempotence on no-mutation |
| setup.sh full-run untestable on runner (heavy optional installs) | Gate the delegated call in isolation (fake HOME, reduced flags); existing bats suites cover script syntax/dry-run; PR note |
| ps1 unverifiable (no pwsh) | Separator-agnostic greps (established pattern) |
| Manifest schema break for existing users | Legacy arrays stay; `entries` additive; legacy-only manifests upgraded on first update |
