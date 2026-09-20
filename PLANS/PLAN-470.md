# PLAN: deploy plan model + single executor, uniform epilogue

**Branch**: feat/470
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/470
**Base**: main

## Acceptance Criteria
- [ ] A plan model (ordered step list: `critical|id|label|function`) is built by `build_plan()` from the existing mode flags; every mode maps to its step list — full (env + config + llm/vllm/provider + agents + plugins + symlink + learnings + shell_vars), quick (same content steps, no env), skills-only (opencode-check + config + agents + plugins + symlink + learnings), models-only (provider + resolver-config-only + manifest update), migrate-only, update, rollback, peonping, check-update (single-step plans)
- [ ] A single executor `run_plan()` runs the steps: non-critical failure → warn + continue; critical failure → stop stepping, record; the epilogue then ALWAYS runs (zip backup + cleanup + summary for content modes; mode completion for single-step modes) and the exit code is truthful — non-zero iff a critical step failed (today every caller wraps steps in `|| true` and early exits skip backup/cleanup/summary entirely)
- [ ] Old flags keep working as aliases (they are the plan generators); README examples unchanged; the interactive menu only sets flags (options 4/5 stop duplicating step calls inline)
- [ ] Flag conflicts die at plan validation (`validate_mode_conflicts` invoked by `build_plan`)
- [ ] D2 decided + implemented + pinned: declining the config overwrite now means "my existing opencode.json wins" — `run_resolver` omits `--config-src` when `SKIP_CONFIG_COPY=true`, so resolve-models.mjs bases its in-place model patch on the EXISTING config (its own fallback, resolve-models.mjs:283-284) instead of silently overwriting user content with the stock template; decline with no existing config ⇒ no config write at all, agents still resolve
- [ ] Mode-matrix bats: every mode's plan (ids, order, criticality) + a dry-run execution trace per mode + truthful exit codes + the D2 pin (functional: declined config's custom keys survive a real resolver run)
- [ ] Full gate green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` main() | build_plan, run_plan (new) | every user of every mode | **high** — flow restructure |
| `run_resolver` | SKIP_CONFIG_COPY (existing global, now honored) | deploy_agents path, models-only path | medium — contract change (omit --config-src) |
| `installer/resolve-models.mjs` | — (unchanged; its configSrc→configDest fallback :283-284 is the mechanism) | setup.sh, setup.ps1, npx installer | none — not modified |
| `deploy/setup.ps1` | — (untouched; its own epilogue alignment is #474) | Windows users | none |
| `tests/test_plan_executor.bats` (new) | all setup.sh plan changes | CI bats job | low |
| Existing step functions (setup_config, deploy_agents, …) | — (called, not modified — except none require signature changes) | plan executor | low |

## Implementation Phases

### Phase 1: plan machinery + D2
- [ ] **1.1** Add plan constants + `build_plan()`: sets PLAN_MODE, fills PLAN_STEPS per the AC table, calls validate_mode_conflicts, and includes the opencode-install precondition as a critical first step for skills-only (extracted from deploy_skills_only's inline validation into `validate_opencode_install()`)
    — **Why:** One authoritative mode→steps mapping replaces five divergent branches; validation belongs to plan construction (fail before any work).
    — **Done when:** `build_plan` under each mode's flags yields the expected PLAN_STEPS (pinned in 2.1); unknown flag combinations already die via validate_mode_conflicts.
    — **Consumers affected:** run_plan (1.2), main (Phase 2).
- [ ] **1.2** Add `run_plan()`: iterate PLAN_STEPS, call each function bare, branch on criticality (non-critical fail → `log_warn` + continue; critical fail → record + stop), then return failures
    — **Why:** The executor is the single place that owns `|| true` semantics — the "failed deploy exits 0" defect dies here.
    — **Done when:** a stub-mode run with a failing non-critical step continues and exits 0; a failing critical step stops stepping and the final exit code is 1 (pinned in 2.1 with stub functions).
    — **Consumers affected:** main (Phase 2).
- [ ] **1.3** D2: in run_resolver, omit `--config-src` when `SKIP_CONFIG_COPY=true` (resolver then bases on existing config-dest per :283-284); document the decided semantics in a comment at both sites (setup_config decline branch + run_resolver)
    — **Why:** Today a declined overwrite is silently overwritten anyway — the resolver bases on the stock template (:281-282) and writes config-dest. Decline must mean the existing file wins; the resolver's own fallback makes this a one-line contract change with zero installer edits.
    — **Done when:** source shows the conditional omission; functional pin (2.1): seeded config with a custom key survives a real resolver run after SKIP_CONFIG_COPY=true, and is overwritten without it.
    — **Consumers affected:** interactive decliners and headless `-y` runs over existing configs (previously silently replaced).
- [ ] **1.4** Extract inline step code into functions the plan can call: `validate_opencode_install()` (from deploy_skills_only), `resolve_models_config_only()` + `update_manifest()` (from the models-only block), `run_migration_only()` (from the migrate-only block); deploy_skills_only becomes a thin wrapper kept for any external callers (none in-repo) OR is absorbed — implementer's call, documented
    — **Why:** The executor needs per-step functions; inline blocks inside main are not callable.
    — **Done when:** all steps in build_plan reference callable functions; `bash -n` green.
    — **Consumers affected:** none — behavior-preserving extraction.
- [ ] **1.5** Class sweep extension (#467/#469 family): the extracted inline blocks contain writes that bypassed run_cmd (`mv "$LEGACY_CONFIG_FILE"`, `mkdir -p ${AGENTS_DEST_DIR}`) — route through run_cmd/gate per the established pattern
    — **Why:** Extraction without gating would re-enter the same leak class through the new executor's broader reachability.
    — **Done when:** no new bare writes in the extracted functions (grep sweep documented).
    — **Consumers affected:** dry-run users.

### Phase 2: main() restructure
- [ ] **2.1** Rewrite main(): parse_arguments → validate_enable_pack → [network check + auto-update + interactive menu — menu options now only SET flags] → build_plan → run_plan → uniform epilogue (zip + cleanup + summary + next-steps for content modes; mode completion for single-step modes) → exit with run_plan's truthful code. Remove the five early-exit branches and the duplicated step calls; keep the headless no-TTY notice (#466) setting SKILLS_ONLY instead of calling deploy_skills_only
    — **Why:** This is the ticket's core: every path = build plan → execute → epilogue → honest exit.
    — **Done when:** mode-matrix pins (2.1) pass for all nine modes; `bash -n` green; no `|| true` step calls remain in main.
    — **Consumers affected:** every deploy path.
- [ ] **2.2** Verify ps1 untouched and README examples unchanged; note in the PR that ps1's own epilogue alignment lands with #474's thin launcher
    — **Why:** Scope boundary: this ticket restructures bash only.
    — **Done when:** diff shows no setup.ps1/README changes.
    — **Consumers affected:** none.

### Phase 3: mode-matrix pins + full gate
- [ ] **3.1** New tests/test_plan_executor.bats: (a) plan-shape pins — build_plan under each mode's flags yields expected ids/order/criticality; (b) executor pins — stub-mode runs prove non-critical continue + critical stop + truthful exit codes; (c) conflict die at build_plan; (d) dry-run execution traces — `main --dry-run` per mode in a sandboxed HOME prints each step's execution in plan order and exits truthfully; (e) D2 functional pin — seeded opencode.json with a custom key + SKIP_CONFIG_COPY=true + real run_resolver ⇒ custom key survives; without skip ⇒ overwritten
    — **Why:** The ticket's core AC — the matrix IS the contract.
    — **Done when:** all pins green.
    — **Consumers affected:** CI bats job.
- [ ] **3.2** Full gate: `bash -n`, `bats tests/`, `node --test tests/*.test.ts`; diff scope = setup.sh + new test file
    — **Why:** Gate contract.
    — **Done when:** all green.
    — **Consumers affected:** none.

## Technical Notes
- Step criticality (decided, overridable in review): critical = opencode install check, config write, agents deploy (incl. resolver), plugins, migration, resolver-config-only, manifest update, the single-step modes' whole function; non-critical = env setup (gh/zai/nvm/nodejs/opencode install), local_llm, vllm, provider selection, symlink, learnings, shell_vars. Rationale: critical = "broken afterwards or wrong content deployed"; non-critical = "feature absent but installation usable".
- Epilogue detail: zip backup only for content modes (full/quick/skills-only) and only over what exists (create_zip_backup is already defensive); single-step modes print their existing completion lines — "uniform" means every path ends in a summary + honest exit code, not identical output text.
- resolve-models.mjs:283-284 fallback is the entire D2 mechanism — verified in source this session.
- The menu keeps its current position (after network check, TTY-gated); options 4/5 become flag-sets so their steps flow through the plan (and gain truthful exit codes).
- #466/#467/#469 fixes are preserved as-is: validate_mode_conflicts moves inside build_plan; the TTY notice remains; the #467 gates are inside step functions and keep working.

## Dependencies
Epic #464; lands after #465–#469 (all merged). #471–#474 build on this plan model.

## Risks & Mitigation
- **Highest-risk ticket of the epic** (main flow restructure): mitigated by behavior-preserving extraction (1.4), the mode-matrix pins written BEFORE the restructure lands (3.1 authored against PLAN, run after each phase), and the architecture review gate on this PLAN before execution.
- **Dry-run semantics under the executor**: step functions are dry-safe individually (post-#467/#469); the executor adds no writes of its own.
- **Headless -y over existing config now preserves user content** (D2): a behavior CHANGE — previously silently replaced. Documented in PR body as the decided fix, pinned both directions.
