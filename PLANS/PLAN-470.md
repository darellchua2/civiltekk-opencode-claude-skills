# PLAN: deploy plan model + single executor, uniform epilogue

**Branch**: feat/470
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/470
**Base**: main
**Arch review**: round 1 executed (3 BLOCK + 3 WARN amendments applied below; D2 mechanism execution-proven both directions; 2 Mode R gaps confirmed)

## Acceptance Criteria
- [ ] A plan model (ordered step list: `critical|id|label|function`) is built by `build_plan()` from the existing mode flags; every mode maps to its step list — **including per-mode preconditions as steps**: skills-only = validate_opencode_install(C) + check_dependencies(C) + config(C) + agents(C) + plugins(C) + symlink + learnings; models-only = node_check(C) + provider + resolver-config-only(C) + manifest-update(**non-critical**, #379 warn-and-continue); migrate-only = node_check(C) + run_migration_only(C, folds the AGENTS_DEST_DIR pre-mkdir) + resolver(C); full/quick/single-step modes per the table in Technical Notes
- [ ] A single executor `run_plan()` runs the steps: non-critical failure → warn + continue; critical failure → stop stepping, record; the epilogue then ALWAYS runs (zip backup + cleanup + summary + next-steps for content modes; mode completion for single-step modes) and the exit code is truthful — non-zero iff a critical step failed
- [ ] Old flags keep working as aliases (they are the plan generators); README examples unchanged; the interactive menu only sets flags (options 4/5 stop duplicating step calls inline); the #466 TTY notice sets SKILLS_ONLY instead of calling deploy_skills_only
- [ ] Flag conflicts die at plan validation — BEFORE the network check and menu render: `build_plan` runs once immediately after validate_enable_pack (fail-fast: conflicts + PLAN_MODE), and again after the menu mutates flags; network check / auto-update / menu stay gated on the flag conditions exactly as today (single-step modes never see them, preserving `--skills-only` as the offline/headless escape path)
- [ ] D2 decided + implemented + pinned: declining the config overwrite means "my existing opencode.json wins" — `run_resolver` omits `--config-src` when `SKIP_CONFIG_COPY=true` (resolve-models.mjs bases its in-place patch on the existing config via its :283-284 fallback); decline with no existing config ⇒ no config write at all, agents still resolve; when declining left NO config and packs were requested, `run_pack_merger`/`run_skill_profile` skip with an explicit "packs require a config you declined" warning instead of a cryptic merge error
- [ ] Mode-matrix bats enumerated FROM build_plan (not prose): plan shapes (ids, order, criticality) + executor continue/stop/exit pins + conflict die + per-mode dry-run traces + headless `--skills-only` with failing network stub → exit 0 + D2 functional pins both directions (custom keys survive decline; stale explicit `model` key deletion WITHOUT provider is EXPECTED and pinned as such — resolver behavior, not a decline bug)
- [ ] Structural-test consumers preserved deliberately (see map): test_skills_only_parity re-pinned against the plan step list (keeping real-run/dry-run pair), test_dry_run_leaks' `dry_arg` literals carried verbatim, deploy_delegate.bats line-order pin honored or deliberately re-pinned
- [ ] Full gate green; setup.ps1 untouched; README unchanged

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` main() | build_plan, run_plan (new) | every user of every mode | **high** — flow restructure |
| `run_resolver` | SKIP_CONFIG_COPY (existing global, now honored); note: models-only/migrate-only keep stock-base this ticket (Mode R: fresh-machine bootstrap depends on it) | deploy_agents path, models-only path | medium — contract change |
| `installer/resolve-models.mjs` | — (unchanged; :280-285 fallback + :463-468 write gate + :293-295 stale-key deletion are the mechanisms) | setup.sh, setup.ps1, npx installer, Docker | none — not modified |
| `deploy/setup.ps1` | — (untouched; epilogue AND D2 decline parity deferred to #474) | Windows users | none |
| **`tests/test_skills_only_parity.bats`** | 1.4: awk-pins deploy_skills_only's body — re-pin against build_plan's step list, keeping the real-run/dry-run artifact pair | CI | medium |
| **`tests/test_dry_run_leaks.bats`** | 1.4: greps literal `[ "$DRY_RUN" = true ] && dry_arg="--dry-run"` + `${dry_arg}` — extracted code must carry these verbatim | CI | low |
| **`tests/deploy_delegate.bats`** | 1.4: pins first-occurrence line order (run_migration < deploy_content < RESOLVER_CONFIG_ONLY run_resolver) — place extracted functions below deploy_agents OR re-pin deliberately | CI | medium |
| `tests/test_plan_executor.bats` (new) | all setup.sh plan changes | CI bats job | low |
| Existing step functions | called, not modified (behavior-preserving extraction only) | plan executor | low |

## Implementation Phases

### Phase 1: plan machinery + D2
- [ ] **1.1** Add plan constants + `build_plan()`: pure planner — sets PLAN_MODE, fills PLAN_STEPS per the mode table (preconditions as explicit steps: skills-only deps-check, models/migrate node-check; manifest-update NON-critical per #379's warn-and-continue, init.mjs:1160 die(2) + setup.sh warn+exit-0 contract), calls validate_mode_conflicts
    — **Why:** One authoritative mode→steps mapping; validation belongs to plan construction.
    — **Done when:** build_plan under each mode's flags yields the expected PLAN_STEPS (pinned in 1.6).
    — **Consumers affected:** run_plan (1.2), main (Phase 2).
- [ ] **1.2** Add `run_plan()`: iterate PLAN_STEPS, call each function bare, branch on criticality (non-critical fail → `log_warn` + continue; critical fail → record + stop), return failures
    — **Why:** The single owner of `|| true` semantics — the "failed deploy exits 0" defect dies here.
    — **Done when:** stub-mode runs prove non-critical continue + critical stop + truthful exit (pinned in 1.6).
    — **Consumers affected:** main (Phase 2).
- [ ] **1.3** D2: run_resolver omits `--config-src` when `SKIP_CONFIG_COPY=true`; decline-with-no-config + `--enable-pack` ⇒ run_pack_merger/run_skill_profile skip with "packs require a config you declined" warning; semantics documented at both sites; models-only/migrate-only KEEP stock-base this ticket (Mode R: fresh-machine bootstrap), follow-up ticket to align via presence-gated dest-fallback (gate on `$CONFIG_FILE` existence, not the decline flag) with both-branch bats + jsonc-sibling coverage
    — **Why:** Decline is silently clobbered today (resolver bases on stock :281-282, writes dest :463-466); the :283-284 dest-fallback makes honoring it a one-line contract change. Pack merge at a nonexistent declined config would otherwise hard-fail cryptically (setup.sh:3141 vs dry-only guard :3144-3148).
    — **Done when:** conditional omission + pack skip-guards in source; functional pins (1.6e/3.1): custom keys survive decline; stale explicit `model` key deletion without provider is pinned as EXPECTED; packs decline-warning fires; without skip, stock overwrite still occurs.
    — **Consumers affected:** interactive decliners, headless `-y` over existing configs; pack users who decline.
- [ ] **1.4** Extract inline step code into callable functions, placed BELOW deploy_agents (preserving deploy_delegate.bats' line-order pin): `validate_opencode_install()` (from deploy_skills_only), `check_dependencies` already a function (referenced as a step), `resolve_models_config_only()` + `update_manifest()` (models-only block; update_manifest keeps the #379 warn-and-continue inside), `run_migration_only()` (migrate-only block, folding the AGENTS_DEST_DIR pre-mkdir). deploy_skills_only becomes a thin wrapper kept for its bats consumers, or re-pinned — per the map
    — **Why:** The executor needs per-step functions; structural test consumers must survive.
    — **Done when:** all steps reference callable functions; dry_arg literals carried verbatim; `bash -n` green; the three structural suites re-pinned and green.
    — **Consumers affected:** none — behavior-preserving.
- [ ] **1.5** Class sweep (#467/#469 family) over the EXTRACTED code: gate the legacy-config `mv`s (setup.sh:2532/:2535) and run_migration's branch-guarded writes (:3283/:3285/:3299) per the run_cmd pattern; sweep shapes must include variable indirection, not just literal mv/mkdir strings
    — **Why:** Extraction re-enters the leak class through the executor's broader reachability; the arch review corrected the stale example list.
    — **Done when:** no ungated new bare writes (sweep output documented).
    — **Consumers affected:** dry-run users.
- [ ] **1.6** Author the Phase-1-satisfiable pins NOW (before 2.1): plan-shape pins per mode, executor continue/stop/exit pins (stub functions), conflict die pin, D2 functional pins — into tests/test_plan_executor.bats; run them green against Phase 1 alone
    — **Why:** Arch review F6: authoring pins before the restructure is the safety net; only the end-to-end trace pins (3.1d) genuinely need main() rewritten.
    — **Done when:** tests/test_plan_executor.bats passes its Phase-1 subset on HEAD.
    — **Consumers affected:** CI.

### Phase 2: main() restructure
- [ ] **2.1** Rewrite main(): parse_arguments → validate_enable_pack → **build_plan (fail-fast validation pass)** → header (keyed off PLAN_MODE) → [network check / auto-update / TTY-gated menu — gated on the SAME flag conditions as today; menu options only SET flags] → **build_plan (rebuild after menu)** → run_plan → uniform epilogue → truthful exit. Remove the six early-exit blocks + duplicated step calls; headless no-TTY notice sets SKILLS_ONLY; keep the AUTO_ACCEPT-gated "Press Enter to exit..."
    — **Why:** The core: every path = plan → execute → epilogue → honest exit, with single-step modes never gaining gates they were designed to skip.
    — **Done when:** per-mode dry-run traces pass (3.1d); no `|| true` step calls remain in main; skills-only gains cleanup_old_backups + print_next_steps (documented, benign); `bash -n` green.
    — **Consumers affected:** every deploy path.
- [ ] **2.2** Verify setup.ps1 untouched, README unchanged; PR body discloses: (a) behavior changes — models-only resolver failure now stops before manifest update; update/peonping/migrate failures flip exit 0 → truthful 1; headless -y over existing config now PRESERVES user content (D2) — **bash only**; (b) D2 Windows divergence (setup.ps1:1856) + models-only/migrate stock-base deferred, both tracked
    — **Why:** Arch F5/F9 + Mode R conditions — the deferral must be honest, not silent.
    — **Done when:** diff scope clean; PR body contains both disclosures.
    — **Consumers affected:** none.

### Phase 3: end-to-end pins + full gate
- [ ] **3.1** Complete tests/test_plan_executor.bats with the post-restructure pins: per-mode dry-run execution traces (steps in plan order, truthful exit, headless `--skills-only` failing-network → exit 0); D2 already pinned in 1.6 — verify still green against rewritten main
    — **Why:** The end-to-end matrix is the contract's final proof.
    — **Done when:** full file green.
    — **Consumers affected:** CI.
- [ ] **3.2** Full gate: `bash -n`, `bats tests/`, `node --test tests/*.test.ts`; diff scope = setup.sh + test files only
    — **Why:** Gate contract.
    — **Done when:** all green.
    — **Consumers affected:** none.

## Technical Notes
- Criticality: critical = opencode install check, deps check (skills-only), node check (models/migrate), config write, agents deploy (incl. resolver), plugins, migration, resolver-config-only, single-step modes' functions. NON-critical = env setup (gh/zai/nvm/nodejs/opencode install), local_llm, vllm, provider selection, symlink, learnings, shell_vars, **manifest update** (#379 contract: pre-#379 installs warn + exit 0 — reclassified per arch F1).
- Epilogue: zip backup only for content modes (full/quick/skills-only); single-step modes print their completion lines. "Uniform" = every path ends in summary + honest exit, not identical text.
- build_plan runs twice (F3): validation pass pre-network/menu; rebuild post-menu. Pure function of the flags.
- D2 mechanism: resolve-models.mjs :280-285 fallback + :463-468 configPatched write gate — execution-proven during arch review. Stale-key deletion (:293-295) pinned as expected.
- Follow-up tickets at PR time: (1) models-only/migrate D2 alignment via presence-gated dest-fallback (Mode R Gap 1 conditions); (2) #474 scope comment adding Invoke-Resolver decline-gate parity (Mode R Gap 2 condition).

## Dependencies
Epic #464; lands after #465–#469 (merged). #471–#474 build on this plan model.

## Risks & Mitigation
- **Highest-risk ticket of the epic**: mitigated by behavior-preserving extraction (1.4), pins authored against Phase 1 BEFORE the restructure (1.6, arch F6), structural-test consumers in the map with scheduled re-pins (F2), and the two-pass build_plan preserving per-mode gate exclusions (F3).
- **Dry-run semantics**: step functions are dry-safe individually; executor adds no writes; extracted-code sweep (1.5) closes the reintroduction path.
- **D2 behavior change** (decline now honored, bash only): documented per Mode R conditions — PR copy scopes decline-preservation to bash, never platform-wide.
