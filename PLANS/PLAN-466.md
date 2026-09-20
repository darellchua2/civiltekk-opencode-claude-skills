# PLAN: setup.sh headless — no TTY gate, no --peonping flag, silent flag conflicts

**Branch**: feat/466
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/466
**Base**: main

## Acceptance Criteria
- [x] The interactive menu is TTY-gated: a run with no TTY on stdin takes the menu-default path (skills-only deploy) deterministically, printing a notice that names the default and the explicit flags — no `read` ever hits EOF on that path
- [x] The skills-only deploy body exists once (`deploy_skills_only()`), shared by the `--skills-only` flag path, menu option 2, and the headless default — no behavior delta between the three
- [x] `-P|--peonping` runs the PeonPing installer headless (menu option 5's flag spelling), with its own early-exit block, `PEONPING_ONLY` default, and both help surfaces updated
- [x] `validate_mode_conflicts` dies (exit 1, named flags) on: any two of `--quick|--skills-only|--update|--models-only|--migrate|--rollback|--check-update|--peonping` combined; and `--enable-pack` with a mode that never reaches the pack merger (`--update`, `--models-only`, `--migrate`, `--rollback`, `--check-update`, `--peonping`) — while `--enable-pack` stays valid with `--quick`, `--skills-only`, and the default full path (deploy_agents runs it)
- [x] bats: parser pins for the new flag + conflict matrix (die cases via subshell), help text pin, and one headless execution test (`main --dry-run` with stdin from /dev/null, `check_network`/`command_exists` stubbed) asserting exit 0, the no-TTY notice, and the skills-only completion
- [x] Full gate green; README examples unchanged; setup.ps1 untouched (its conflict surface is #470's plan validation)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` parse_arguments | — | main flow; tests/parse_arguments.bats (sources the script) | low |
| `deploy_skills_only()` (new) | functions it calls exist already (setup_config, deploy_agents, setup_learnings_dir, print_summary) | flag path, menu case 2, headless default | low — pure extraction |
| `validate_mode_conflicts()` (new) | mode flags initialized (defaults block ~:330) | main, right after validate_enable_pack | low |
| `tests/test_headless_default.bats` (new) | the TTY gate + extraction | CI bats job | low |

No cross-module consumers: single script, additive validation; existing flag behavior unchanged for every non-conflicting invocation.

## Implementation Phases

### Phase 1: bash changes
- [x] **1.1** Extract the skills-only deploy body (opencode validation + deps check + setup_config + deploy_agents + setup_learnings_dir + print_summary + completion echo) into `deploy_skills_only()`; replace the `--skills-only` flag path body (:4171-4187) and menu case 2 body (:4252-4266) with calls
    — **Why:** Three sites (flag path, menu option 2, upcoming headless default) must behave identically; duplicating the body a third time would guarantee drift (the #469 bug class).
    — **Done when:** `grep -c 'deploy_skills_only' deploy/setup.sh` = 4 (definition + 3 call sites); the two old inline bodies are gone; `bash -n` passes.
    — **Consumers affected:** `--skills-only` users and menu option 2 (byte-identical behavior by construction).
    — **Done:** extracted to deploy_skills_only(); flag path + menu case 2 now call it (3 refs at this step; 4th arrives with 1.2's headless default — final count 4); bash -n ok; files: deploy/setup.sh; fixes: none
- [x] **1.2** TTY-gate the menu: wrap the existing menu block in `if [ -t 0 ]; then ... else <notice + deploy_skills_only + exit 0> fi`
    — **Why:** Headless runs currently fall into the menu, `read` hits EOF, and the default "2" silently wins (LEARNINGS: setup-sh-dry-run-menu-skips-plugin-deploy). The default choice itself is kept (it is today's de-facto behavior) but becomes defined, visible, and announced.
    — **Done when:** the notice text ("No TTY detected") appears in setup.sh inside the menu branch's else; a `main --dry-run </dev/null` run (stubbed deps) exits 0 through the skills-only path (pinned in 2.1).
    — **Consumers affected:** CI/cron users running bare `./setup.sh` — previously silent skills-only, now announced skills-only.
    — **Done:** `[ ! -t 0 ]` guard at the top of the menu block; notice names the default + explicit flags; headless default routes through deploy_skills_only (4 refs total); files: deploy/setup.sh; fixes: none
- [x] **1.3** Add `PEONPING_ONLY=false` to the defaults block (~:330), `-P|--peonping` to parse_arguments (next to `-C|--check-update`), an early-exit block in main (after --migrate, before skills-only: deps check → `setup_peonping || true` → exit 0), and a `--peonping` row in both help surfaces (SETUP MODES table ~:527, OPTIONS/SETUP OPTIONS ~:550)
    — **Why:** Menu option 5 is the only PeonPing entry point; headless/CI cannot reach it. A flag spelling per menu entry is the ticket's stated contract.
    — **Done when:** `parse_arguments --peonping` sets PEONPING_ONLY=true; `./setup.sh --help | grep -c peonping` ≥ 2; `bash -n` passes.
    — **Consumers affected:** PeonPing users (headless install now possible); help readers.
    -- Done: PEONPING_ONLY default :331, -P|--peonping arm :842, early-exit block :4221 (before --migrate), both help surfaces :535/:556 (help grep = 2); files: deploy/setup.sh; fixes: one degenerate edit joined the migrate `if` line — caught and repaired in the same step
- [x] **1.4** Add `validate_mode_conflicts()` (after `validate_enable_pack`, ~:930) and call it in main immediately after the `validate_enable_pack` call (:4096-4098)
    — **Why:** The ticket's named defects: `--update --enable-pack x` silently ignores the pack; `--quick --skills-only` silently runs skills-only. Mutual-exclusion of early-exit modes is the same failure genus (later flag silently wins/loses by case-order accident).
    — **Done when:** conflict matrix from the ACs all die with exit 1 naming the flags; single modes and `--quick --enable-pack x` pass (pinned in 2.1).
    — **Consumers affected:** users passing contradictory flags — clear error instead of a surprise deploy.
    -- Done: validate_mode_conflicts() :946 (mode exclusivity + pack-less-mode rule), called at :4167 after validate_enable_pack; matrix verified by hand + 2.1 pins; files: deploy/setup.sh; fixes: none
- [x] **1.5** Note the deferral in a code comment at the validate_mode_conflicts call site: per-flag semantic validation (e.g. `--provider` with `--update`) lands with #470's plan model
    — **Why:** Keeps this PR scoped to mode-vs-mode + pack conflicts without implying full flag validation.
    — **Done when:** comment present referencing #470.
    — **Consumers affected:** none (documentation only).
    -- Done: deferral note lives in validate_mode_conflicts' header comment (kept with the function rather than the call site — better discoverability, same contract); references #470; deviation noted; files: deploy/setup.sh; fixes: none

### Phase 2: bats pins + full gate
- [x] **2.1** Extend tests/parse_arguments.bats (sources setup.sh — safe via its BASH_SOURCE guard) with: `--peonping` parse; conflict-matrix dies (subshell `run bash -c 'source …; FLAGS=…; validate_mode_conflicts'`, assert exit ≠ 0 + output names a flag) for quick+skills-only, update+enable-pack, models-only+enable-pack, migrate+enable-pack, rollback+enable-pack, check-update+enable-pack, peonping+enable-pack, update+models-only; passes for each single mode, quick+enable-pack, skills-only+enable-pack; help-text pin (`bash deploy/setup.sh --help` mentions peonping ≥ 2)
- [x] **2.2** New tests/test_headless_default.bats: execution test — `run bash -c "source '$SETUP_SH'; check_network(){ return 0; }; command_exists(){ return 0; }; main --dry-run" </dev/null`; assert exit 0, output contains "No TTY detected" and "Skills deployment complete!"
    — **Why:** The gate's end-to-end contract (defined path, zero EOF reads, announced default) can only be proven by running main; stubs keep it deterministic in CI sandboxes.
    — **Done when:** the execution test passes locally and in the full bats run.
    — **Consumers affected:** CI bats job.
    -- Done: test_headless_default.bats 2/2 — headless dry-run exits 0 with notice + skills-only completion (check_network/check_dependencies/command_exists stubbed, stdin </dev/null); -y variant asserts NO notice (documented full path preserved); files: tests/test_headless_default.bats; fixes: none
    -- Done: 7 new pins in parse_arguments.bats (peonping parse + alias, help >=2, single-mode acceptance x8 loop, quick+skills-only die naming both flags, enable-pack die x6 loop, enable-pack valid x2 loop); all pass; files: tests/parse_arguments.bats; fixes: none
- [x] **2.3** Full gate: `bash -n deploy/setup.sh`, `bats tests/` (all), `node --test tests/*.test.ts`; diff scope = setup.sh + the two test files only
    — **Why:** Gate contract; ticket is bash-only.
    — **Done when:** all green; `git diff --stat` limited to the three files (+ PLAN/LEARNINGS).
    — **Consumers affected:** none.
    -- Done: bash -n ok; bats 423 ok / 0 fail (414 + 9 new); node --test 30/0; diff scope = deploy/setup.sh + 2 test files (VERSION delta = release-bot churn on main, not this branch); files: -; fixes: none

## Technical Notes
- Menu default stays "2" (skills-only) on purpose: it is today's de-facto headless outcome; the fix makes it defined and announced rather than changing the outcome. Changing the default is a product decision, not a bug fix.
- `-y` (AUTO_ACCEPT) headless already skips the menu and runs the full path with defaults — unchanged, documented behavior.
- enable-pack validity map verified: run_pack_merger is invoked from deploy_agents (:3401), and deploy_agents runs on the flag path (:4180), menu case 2, quick, and full paths — packs are meaningless only where deploy_agents never runs (the six early-exit modes).
- ps1 keeps its own menu/flag surface; its conflicts validation arrives with the #470 plan executor.

## Dependencies
None — standalone. Part of epic #464.

## Risks & Mitigation
- **Execution test brittleness** (main runs real functions in dry-run): mitigated by stubbing check_network + command_exists, fresh-TEST_HOME (no stale-AGENTS.md prompt), and `|| true` guards already present on every deploy step; if CI sandboxes make it flaky, the test fails visibly and can be narrowed to the sourced-function pin without losing the parser/conflict coverage.
- **Behavior surprise** (headless users now see a warning + same outcome): intended — the outcome is unchanged, only its visibility.

## Gate Trace

GATE (fix-round head pending) lint=- typecheck=- build=- unit=t e2e=n.a.  (bash -n ok; bats 423 ok / 0 fail incl. 9 new pins; node --test 30 pass / 0 fail; scope = deploy/setup.sh + tests/parse_arguments.bats + tests/test_headless_default.bats)
