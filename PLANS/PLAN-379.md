# PLAN: Phase 5 — Single install path + npx update command

**Branch**: feat/379
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/379
**Base**: main (ca5beaf — includes all four prior phases)

## Acceptance Criteria

From ticket #379, re-validated @ `ca5beaf`; amended after plan review (ARCH-1..8, REQ-1..6 folded in):

- [ ] New `tests/update.bats`: fresh-install → mutate source → `update` re-copies; orphan reported not deleted; `--prune` removes; legacy manifest without `entries` upgrades cleanly; no-mutation idempotence (`unchanged`); `--dry-run` writes nothing
- [ ] Delegated-deploy bats (new, fake HOME): `init.mjs add --all --yes` populates the manifest with registry-complete entries (counts compared dynamically against `registry.json`) — promoted to the primary AC-2 check (no end-to-end setup.sh harness exists — review-verified)
- [ ] No setup.sh full-deploy path still copies agents/skills directly (grep gates keyed to avoid the `lift-only` false positive)
- [ ] README "Testing & Development" section + documented redeploy backup/clobber contract
- [ ] bats full suite green; registry drift clean; public `npx … add <name>` unchanged; Dockerfile resolver call unchanged

**Re-validation notes:** agents are written today by `resolve-models.mjs` (copy + model inject, via `run_resolver` `--agents-src/--agents-dest`), skills by the rsync loop in `setup_config` (:2548-2562; prompt default-`n` means `--yes` historically never clobbered). `run_resolver` is a SHARED helper serving three modes — deploy (:3333), `--models-only` (:4079), `--migrate-only` (:4094). `resolve-models.mjs` **hard-requires** `--agents-src` in non-lift mode (:120-128, exit 2 — review-proven). Migration+lift live INSIDE `deploy_agents` (:3329), before `run_resolver` (:3333); `setup_config` (:4239) runs BEFORE migration and has early-returns. `init.mjs` has model injection (`tierToModel`) but lacks the resolver's user precedence; manifest write :615-626; `cmdRemove` :763; dispatch :809-813; no `--all`, no `update`.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` manifest `entries` (per-target hash map) | Phase 1 precedes update | `update`, `remove`, `--prune`, delegated deploy AC | high |
| `installer/init.mjs` `update` command | Phase 1 | npx users, `tests/update.bats`, `--models-only` flow | high |
| `installer/init.mjs` `--all` + resolver-faithful `tierToModel` precedence | precedes Phase 4 | setup.sh delegation, `add` users (behavior note: users with `agent-overrides.json` now see pins honored in `add` too — alignment, note in PR) | high |
| `installer/resolve-models.mjs` agents-args-optional | precedes Phase 4 call-site change | setup.sh 3 modes, Dockerfile (unchanged, keeps args), ps1 mirror | high |
| `deploy/setup.sh` `deploy_agents` (deploy_content insert) + `setup_config` (loop removal) + `run_resolver` scoped arg-drop | Phases 1-3 + resolver change | full-deploy users, `--models-only`/`--migrate-only` users, bats, dry-run flows | high |
| `deploy/setup.ps1` mirrors | track setup.sh | Windows users (grep-verified only) | med |
| `tests/update.bats` + `tests/deploy_delegate.bats` (both new; no existing suite asserts the old copy paths — ARCH-7) | per-phase | CI | med |
| `README.md` | behavior lands first | humans | low |

## Implementation Phases

### Phase 1: Manifest `entries` with per-target hashes (5b)

- [x] **1.1** `installer/init.mjs`: `sha256Hex`; `hashSkillDir(dir)` (deterministic tree hash: sorted relative paths + file contents; no mtimes); extend the user-scope manifest write (:615-626) with `entries: { <name>: { type: "agent"|"skill", targets: { opencode?: "sha256:…", claude?: "sha256:…" } } }` — hash the WRITTEN bytes per target (agent file post-injection → opencode only; skill dir for opencode; skill dir post-`stripModelLine` for claude); legacy `agents`/`skills` arrays unchanged; merge preserves untouched entries. **`cmdRemove` (:788-795) and `doPrune`'s manifest rewrite also drop `entries[name]`** (ARCH-6)
    — **Why:** update needs per-entry hashes and per-target records; claude copies legitimately differ from opencode copies (model-strip) so a single hash would mis-report drift forever (ARCH-5); remove/prune without entries-drop creates ghost "missing" reports.
    — **Done when:** fake-HOME `add tdd-subagent --yes` + `--target both` of a model:-carrying skill shows distinct per-target hashes; `remove X` then re-read manifest → entry gone; prior entries preserved.
    — **Consumers affected:** remove, prune, update, delegated deploy.

### Phase 2: `update` command (5c)

- [x] **2.1** `installer/init.mjs`: `update [--prune] [--dry-run] [--yes]` — load manifest; legacy-only manifests (no `entries`) upgrade by hashing current installs into entries then proceed; for each entry still in the registry: recompute would-write hash per target (agent: readAgent + tierToModel + injectModelLine; skill: source dir [+ strip for claude]) vs stored → re-copy changed to that target, update hashes; installed-files-absent → `missing`; registry-absent names → `registryRemoved` (reported only; with `--prune` → files + manifest rows removed); report `updated N · unchanged M · missing K` (+ `registryRemoved R` / `pruned P`); `--dry-run` prints JSON plan, writes nothing; after real runs run the strict-allowlist visibility check (warn-only — name-stable updates cannot grow the union; **conscious deviation from 5c's "refresh permissions union" letter: missing allow rules are NOT repaired — PR body notes it**). Help entry.
    — **Why:** The ticket's core UX; written-hash recomputation is what makes provider/model swaps propagate (`--models-only` relies on it in Phase 4).
    — **Done when:** fake-HOME: install → mutate → update re-copies; no mutation → unchanged; registry-removed orphan reported; `--prune` removes; legacy manifest upgrades.
    — **Consumers affected:** npx users; `--models-only` flow (Phase 4).

- [x] **2.2** New `tests/update.bats` (fake HOME): (a) fresh-install → mutate source → update re-copies; (b) orphan reported not deleted; (c) `--prune` removes; (d) legacy manifest without `entries` upgrades cleanly; (e) `--dry-run` prints plan, writes nothing; (f) no-mutation run reports unchanged and rewrites nothing
    — **Why:** Ticket AC + idempotence proof (REQ-3).
    — **Done when:** `bats tests/update.bats` green.
    — **Consumers affected:** CI.

**Phase gate:** `node --check`; `bats tests/update.bats tests/init.bats`; registry `--check`.

### Phase 3: `--all` selection + resolver-faithful model precedence (5a prep)

- [x] **3.1** `installer/init.mjs`: `add --all` → full registry selection (every agent + skill) non-interactive; `tierToModel` extended with the resolver's EXACT precedence (project map > provider preset > user `models.json` > default map; per-agent `agent-overrides.json` pin above tier resolution — crib from `resolve-models.mjs` :189-191 ordering); `deploy_content` (Phase 4) passes `--provider` only when the user set one (no forced default — ARCH-8)
    — **Why:** Full-deploy delegation needs the whole catalog in one call; injection must match the resolver's semantics exactly or agents and config drift to different models for custom-tier users.
    — **Done when:** fake-HOME `add --all --yes` installs counts == registry counts (assert dynamically vs `registry.json`); an `agent-overrides.json` pin changes that agent's injected model; a user `models.json` tier override beats the default map.
    — **Consumers affected:** `add` users, setup.sh Phase 4.

### Phase 4: Resolver flexibility + setup delegation (5a)

- [x] **4.1** `installer/resolve-models.mjs`: make `--agents-src`/`--agents-dest` OPTIONAL in non-lift mode — agent block (:222-458) gated on their presence; JSON summary's agent rows empty-safe when absent; Dockerfile call (passes args) behavior unchanged (ARCH-1)
    — **Why:** Review-proven: the script hard-exits without `--agents-src`, so any config-only invocation from setup.sh fails; optionality is the minimal change preserving the Docker path byte-for-byte.
    — **Done when:** config-only invocation (no agents args) exits 0 and patches config; full-args invocation output identical to today (dry-run diff empty); `node --check`.
    — **Consumers affected:** setup.sh 3 call modes, Dockerfile (unchanged).

- [x] **4.2** `deploy/setup.sh`: (a) new `deploy_content()` — snapshot existing `SKILLS_DIR` + `AGENTS_DEST_DIR` into `BACKUP_DIR/content-backup` when non-empty (re-anchors the pre-overwrite net the deleted prompt provided — ARCH-4), then `node "${INSTALLER_DIR}/init.mjs" add --all --yes ${PROVIDER:+--provider $PROVIDER}` (+ `--dry-run` passthrough); (b) insert `deploy_content` INSIDE `deploy_agents` between `run_migration` (:3329) and `run_resolver` (:3333) — NOT in `setup_config` (runs pre-migration, has early-returns — ARCH-3); (c) remove the skills rsync/cp loop + overwrite prompt from `setup_config`; (d) `run_resolver` scoped change: the `deploy_agents` call drops `--agents-src/--agents-dest` (config-only); `--models-only` (:4079) becomes resolver config-only + `node init.mjs update` (written-hash propagates model changes through the manifest path); `--migrate-only` (:4094) unchanged (full resolver — legacy pre-manifest path) (ARCH-2); (e) counts/banners still read source dirs; backup/rollback untouched
    — **Why:** One manifest-tracked install path with correct ordering (lift sees pre-overwrite agents; migration backup captures the old files), a pre-clobber snapshot (new `--yes` force-copies where it previously skipped), and mode-scoped resolver use that doesn't break provider swaps or migration.
    — **Done when:** `bash -n`; `--dry-run` exit 0; grep gates: no `--agents-src` in the deploy_agents resolver call (lift-only :3166-3167 and migrate-only exempt — REQ-1), no skills rsync/cp in `setup_config`; delegated bats (4.4) green.
    — **Consumers affected:** all deploy modes; dry-run flows.

- [x] **4.3** `deploy/setup.ps1`: mirror 4.2 — `Deploy-Content` (backup snapshot + CLI call), insert per the ps1 call flow (`Deploy-Agents` :2308-2330), remove `Deploy-Skills` copy loop (:1793+), scoped `Invoke-Resolver` arg handling (base array :1867-1868 gains a config-only variant; models-only :2857 / migrate-only :2876 per 4.2(d) semantics)
    — **Why:** Windows parity (grep-verified only — no pwsh on runner).
    — **Done when:** separator-agnostic greps mirror 4.2's gates.
    — **Consumers affected:** Windows users.

- [x] **4.4** New `tests/deploy_delegate.bats` (fake HOME): invoke `node installer/init.mjs add --all --yes` exactly as `deploy_content` does → assert manifest `entries` count == registry agents+skills counts (dynamic); spot-assert one agent hash and one skill hash present; second run idempotent (no error, counts stable). Plus: grep-assert `deploy/setup.sh` contains the delegated call between migration and resolver markers (structure pin)
    — **Why:** ARCH-7: no existing suite covers the replaced path — this is the regression net for the epic's riskiest change and the promoted AC-2 check.
    — **Done when:** `bats tests/deploy_delegate.bats` green.
    — **Consumers affected:** CI.

**Phase gate:** full bats suite; `bash deploy/setup.sh --dry-run`; registry `--check`; grep gates both scripts.

### Phase 5: Docs + final sweep (5d)

- [ ] **5.1** `README.md`: "Testing & Development" section — clone + `node installer/init.mjs add X --dry-run`; `npm link` for the bin; branch testing `npx github:darellchua2/opencode-config-template#<branch> add X --dry-run`; sandboxed `HOME=<tmp>`; CI note (`--yes`/`--dry-run`); `update` example; PLUS the redeploy contract: setup snapshots existing skills/agents to `content-backup` before overwriting (force-copy on `--yes`)
    — **Why:** Ticket 5d + the data-loss posture change must be documented (ARCH-4 follow-through).
    — **Done when:** section exists with all recipes + contract line.
    — **Consumers affected:** contributors, redeploying users.

- [ ] **5.2** Final sweep: reword `cmdRemove`'s "files installed by setup.sh are not tracked" (:773 — false post-5a; point at `update`/`remove`); help lists `update`; full bats; registry `--check`; `npm pack --dry-run` includes installer/
    — **Why:** The old gap message becomes a false claim the moment 5a lands.
    — **Done when:** `grep -rn 'not tracked' installer/ README.md` clean; help shows update.
    — **Consumers affected:** users reading remove/update output.

**Phase gate:** all ACs re-checked; full suite green.

## Technical Notes

- `npx github:` pulls HEAD only; npm publish remains the optional follow-up (ticket).
- Written-content hashing is what lets `update` (and `--models-only` via update) propagate tier/override model changes; source hashes could never detect them.
- Per-target hash map (`targets: {opencode, claude}`) deviates from the ticket's `targets: [...]` array + single-hash letter — required because claude copies are model-stripped (ARCH-5); documented in PR body.
- Resolver keeps full capability; only invocation shapes change (deploy=config-only, models-only=config+update, migrate=full). Dockerfile untouched.
- setup.sh `--dry-run`: CLI gets `--dry-run` (no writes); resolver keeps `--preview-dir` staging for config consumers (packs/profile) — parity verified at the no-write level by review.
- Reviewer learnings to persist post-merge: shared-deploy-helper arg-drop anti-pattern; written-content-hash decision; setup --yes clobber-posture change.

## Dependencies

- Branch cut from `ca5beaf` (all four prior phases merged).
- Closes epic #376 (final phase).

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Resolver optionality regresses the Docker/full path | 4.1 done-when: full-args invocation byte-identical (dry-run diff empty) |
| Wrong insertion point lifts/backs up post-overwrite files | Pinned anchor (inside deploy_agents, migration→deploy_content→resolver) + 4.4 structure-pin grep |
| Force-clobber loses user edits on redeploy | Pre-overwrite `content-backup` snapshot (4.2a) + documented contract (5.1) |
| `--models-only` breaks | Rerouted through update (written-hash) + bats; migrate-only untouched |
| Hash false-positives across re-runs | Deterministic tree hash (no mtime); (f) idempotence case proves it |
| Manifest schema lock-in with wrong shape | Per-target map landed pre-ship (ARCH-5), legacy arrays retained |
| ps1 unverifiable | Separator-agnostic greps (established pattern) |
| PR-body-must-carry deviations | Tracked: permissions-union warn-only; per-target targets shape; `add` now honors user overrides |
