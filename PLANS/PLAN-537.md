# PLAN: Deploy picker — truthful catalog and safe plugin picks

**Branch**: feat/537
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/537
**Base**: main

## Acceptance Criteria
- [x] `./deploy/setup.sh --list-items` prints the real packs (autodesk, markitdown, nextjs, docling, chrome-devtools) and the 5 `opencode-*.ts` plugins
- [x] The plugins group and `--print-plan --defaults` list the same 5 `.ts` plugins; the README is offered in neither
- [x] Selecting `opencode-ponytail-scoped.ts` deploys the `.ts` + `ponytail/` (SKILL.md, instructions.cjs) + `ATTRIBUTION.md`
- [x] Selecting `opencode-vibeguard-v2.ts` still copies `vibeguard.config.json`
- [x] Menu option 6 routes to the picker path; `--select` behavior unchanged
- [x] `bats tests/test_select_items.bats tests/test_ships_plugins.bats tests/test_deploy_delegate.bats` pass; full suite green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/deploy-plan-items.mjs` (new scanner exports) | `./init.mjs` (existing import, import-safe) | `deploy/tui.mjs` (loadPickerData, planFromFlags), `deploy/setup.sh` (dump_catalog via node) | med — two consumers must switch in the same change |
| `deploy/tui.mjs` (loadPickerData, planFromFlags) | scanners from deploy-plan-items.mjs (Phase 1) | `setup.sh --select` picker (dashboard + linear + defaults) | low |
| `deploy/setup.sh` `dump_catalog` | scanners from deploy-plan-items.mjs (Phase 1) | `--list-items` CLI output | low |
| `deploy/setup.sh` `apply_selected_packs_extras` | `plugins/` source tree (companion artifacts) | `--select` plugin deploy | med — plugin correctness at runtime |
| `installer/dependency-map.json` (`pluginCompanions` key) | — | `deploy/setup.sh` `apply_selected_packs_extras`, `tests/test_select_items.bats` cross-surface pin | low |
| `deploy/setup.sh` main() Setup Mode menu | build_plan (SELECT_ITEMS flag) | interactive menu users | low |

Cross-module node: the scanners have consumers in two modules (`deploy/tui.mjs` and `deploy/setup.sh`) — architecture review is selected for plan review.

## Implementation Phases

<!-- Gate trace
GATE e8e2845 tier=light lint=- typecheck=- build=- unit=t e2e=-
GATE 232504a tier=light lint=- typecheck=- build=- unit=t e2e=-
GATE cd8c780 tier=light lint=- typecheck=- build=- unit=t e2e=-
GATE cd8c780 tier=full lint=- typecheck=- build=t unit=t e2e=-
GATE 8b054a5 tier=full lint=- typecheck=- build=t unit=t e2e=- (re-gate after review fixes)
-->

### Phase 1: Shared scanners (foundation)
- [x] **1.1** Add exported `scanPackNames(packsDir)` and `scanPluginNames(pluginsDir)` to `installer/deploy-plan-items.mjs` (packs = `pack-*.json` stems; plugins = `opencode-*.ts` files only), with a doc note that caller-passed-dir readdir is the module's one I/O exception — added at BOTH contract-comment sites: the module header (`deploy-plan-items.mjs` "No I/O beyond caller-passed data") and the `tests/test_select_items.bats` header ("one pure module").
    — **Why:** the pack/plugin filter rule currently lives in two drifted copies inside `deploy/tui.mjs` (`loadPickerData` scans `opencode-*` unfiltered, `planFromFlags` filters `.ts` only); the catalog dump in `setup.sh` has a third, empty copy. One source is the fix for all three.
    — **Done when:** a `node -e` import of the module returns 5 pack stems and 5 plugin `.ts` names for this repo's `deploy/packs/` and `plugins/` dirs.
    — **Consumers affected:** `deploy/tui.mjs` and `deploy/setup.sh` `dump_catalog` (both switch in Phases 1–2).
    — **Done:** scanners exported from deploy-plan-items.mjs with readdir exception documented at both header sites; import probe returns 5 packs + 5 plugins. files: installer/deploy-plan-items.mjs, tests/test_select_items.bats; fixes: none
- [x] **1.2** Switch `deploy/tui.mjs` `loadPickerData` and `planFromFlags` (`--defaults` path) to call the shared scanners.
    — **Why:** removes the README from the selectable inventory and ends the 6-vs-5 defaults/inventory inconsistency.
    — **Done when:** `node deploy/tui.mjs select-items --print-plan --defaults` emits `plugins` with exactly the 5 `opencode-*.ts` names and no README entry.
    — **Consumers affected:** `setup.sh --select` picker UX (inventory and defaults now agree).
    — **Done:** both paths consume the shared scanners; `readDirSyncCompat` helper and unused `readdirSync` import removed; defaults probe shows exactly the 5 `.ts` plugins. files: deploy/tui.mjs; fixes: none

### Phase 2: Truthful catalog, safe plugin picks, menu entry
- [x] **2.1** Rewrite `dump_catalog` in `deploy/setup.sh` to import the shared scanners via dynamic `import()` inside the existing `node` one-liner, with the module path built from an argv-passed absolute `${REPO_DIR}` through `pathToFileURL` (never a relative specifier — `node -e` `import()` resolves against the process cwd, and `setup.sh` runs from any cwd via the `opencode-setup` PATH shim).
    — **Why:** `--list-items` currently hardcodes `packs: []` / `plugins: []`, telling users plugins are not installable — the ticket's headline gap.
    — **Done when:** `./deploy/setup.sh --list-items` output lists all 5 pack names and all 5 `opencode-*.ts` plugins, verified from the repo root AND from a different cwd (e.g. `cd /tmp` first).
    — **Consumers affected:** `--list-items` CLI output only.
    — **Done:** dump_catalog imports the scanners via pathToFileURL(argv); 5 packs + 5 plugins listed from repo root and from /tmp. files: deploy/setup.sh; fixes: none
- [x] **2.2** Add a `pluginCompanions` map to `installer/dependency-map.json` (plugin file name → companion artifacts; seed with `opencode-vibeguard-v2.ts` → `vibeguard.config.json` and `opencode-ponytail-scoped.ts` → `ponytail/` + `ATTRIBUTION.md`, matching the existing `shipsPlugins` facts) and have `apply_selected_packs_extras` consume it through the function's existing `node` idiom instead of a hardcoded bash `case`.
    — **Why:** a bash `case` would fork companion knowledge `dependency-map.json` already declares (`shipsPlugins`) — the next companion-bearing plugin would then work on one install path and arrive broken on the other (arch review Major); the declarative map keeps the picker cp path and the manifest `shipPluginArtifacts` path single-sourced.
    — **Done when:** a sandboxed deploy of a pre-seeded plan containing only `opencode-ponytail-scoped.ts` produces `opencode-ponytail-scoped.ts`, `ponytail/SKILL.md`, `ponytail/instructions.cjs`, and `ATTRIBUTION.md` in the plugin dir; no plugin file name is hardcoded in `apply_selected_packs_extras` (grep-verifiable).
    — **Consumers affected:** `--select` plugin deploy correctness; no change for skills/agents/packs/extras paths.
    — **Done:** pluginCompanions added to dependency-map.json ($comment documented); consumption via node lookup; sandbox run produced exactly the 4 artifacts and rm-first kept the second apply non-nested; zero hardcoded plugin names in the function. files: installer/dependency-map.json, deploy/setup.sh; fixes: none
- [x] **2.3** Add Setup Mode menu option `6) Select items to deploy (skills / agents / packs / plugins)` that sets `SELECT_ITEMS=true` in `main()`.
    — **Why:** `--select` is flag-only; the default interactive menu gives no path to plugins/subagents — the discoverability gap.
    — **Done when:** a pseudo-TTY (`script -qec`) run of the menu choosing option 6 logs the picker plan steps (`select-items`, `deploy-selected-skills`, …) and no blanket agents/plugins step.
    — **Consumers affected:** interactive menu only; flags `--select`, `--quick`, etc. unchanged.
    — **Done:** menu echo + case arm added; routing verified via direct-invocation harness (source → SELECT_ITEMS=true → build_plan emits the 4 picker steps, blanket agents/plugins steps absent). Deviation (sanctioned): the pty variant of the Done-when hung 3× on the full path's interactive prompts — the arch review's pre-authorized fallback (direct function-invocation wiring test) replaces it; option 6's only logic is the flag assignment, which the harness proves deterministically. files: deploy/setup.sh; fixes: none

### Phase 3: Test coverage
- [x] **3.1** Extend `tests/test_select_items.bats`: pin the plugin filter (inventory and `--print-plan --defaults` both list exactly the 5 `.ts` plugins, README absent from both).
    — **Why:** the README-in-inventory bug and the defaults drift are exactly the regression class this AC forbids.
    — **Done when:** new assertions pass and existing pins (determinism, driver equivalence, MCP_TO_PACK) stay green.
    — **Consumers affected:** none (test-only).
    — **Done:** scanner pin (5 `.ts`, no README) + defaults-agreement pin added; all 19 tests green. files: tests/test_select_items.bats; fixes: none
- [x] **3.2** Add a bats test that `--list-items` prints non-empty `packs` and `plugins` arrays with the expected counts.
    — **Why:** the catalog dump was the lying surface; pin it so it cannot silently regress to empty arrays.
    — **Done when:** the test fails on the pre-change behavior (empty arrays) and passes post-change.
    — **Consumers affected:** none (test-only).
    — **Done:** count pin 5/5 + autodesk presence + cwd-independence run from /tmp. files: tests/test_select_items.bats; fixes: JSON extraction sed range `/^{/,$p` → `/^{/,/^}/` (trailing mode-completion log line broke JSON.parse — gate fix 1)
- [x] **3.3** Add a bats test for plugin selection deploy: pre-seed a plan with only `opencode-ponytail-scoped.ts` (and a second case with only `opencode-vibeguard-v2.ts`), run the deploy in a sandbox `HOME`, assert the companion artifact sets land; include a cross-surface pin asserting `pluginCompanions["opencode-ponytail-scoped.ts"]` covers the artifacts `dependency-map.json` `shipsPlugins` already declares.
    — **Why:** companion-copy correctness is the AC with real data-loss shape (a broken plugin in the user's config); the cross-surface pin keeps the declarative map from drifting against the manifest path's expectations.
    — **Done when:** both sandbox runs produce exactly the artifact sets from AC 3/4, and the cross-surface assertion passes against the live `dependency-map.json`.
    — **Consumers affected:** none (test-only).
    — **Done:** ponytail sandbox run asserts the 4 artifacts + non-nested re-run; vibeguard run asserts config companion; cross-surface and no-hardcode pins added. files: tests/test_select_items.bats; fixes: none
- [x] **3.4** Add a bats test for menu option 6 wiring using `script -qec` (pseudo-TTY), asserting the picker plan steps are logged.
    — **Why:** the menu change is the only user-facing routing change; without a pin it can silently revert.
    — **Done when:** the test passes on this branch; on main it would fail (option absent).
    — **Consumers affected:** none (test-only).
    — **Done:** wiring pin uses the direct-invocation harness (source → SELECT_ITEMS=true → build_plan) with static menu-line + case-arm greps — pty variant replaced per the arch-review-sanctioned fallback (3 hangs observed); positives (4 picker steps) AND negatives (blanket agents/plugins absent) asserted. files: tests/test_select_items.bats; fixes: none

### Phase 4: Verification gate
- [x] **4.1** Run the affected suites (`bats tests/test_select_items.bats tests/test_ships_plugins.bats tests/test_deploy_delegate.bats tests/test_plan_executor.bats`), then the full `bats tests/` suite; fix anything red before proceeding.
    — **Why:** `test_deploy_delegate.bats` pins first-occurrence line order in `setup.sh` — the strongest regression risk of Phases 2; the full suite catches cross-file drift (count pins, portability guard).
    — **Done when:** full suite exits 0; the ticket exit gate memo line `GATE <sha> tier=full` is recorded for the final SHA.
    — **Consumers affected:** Step 9 review and Step 10 PR citation (both consume the gate memo).
    — **Done:** full tier green — registry drift OK (34/146), mjs syntax (incl. changed deploy-plan-items.mjs + tui.mjs), package.json, tarball guard, and every tests/*.bats file (SUITE RC:0). files: none (verification); fixes: gate-harness only — my `set -o pipefail` SIGPIPE'd `grep -q` in the tarball guard (141); CI runs the guard without pipefail, gate re-run CI-identical

## Technical Notes
- Keep all `setup.sh` edits inside existing function bodies (`dump_catalog`, `apply_selected_packs_extras`, `main` menu block) — do not reorder or insert new top-level functions, to preserve `deploy_delegate.bats` line-order pins.
- Bash 3.2 compat (stock macOS): no associative arrays, no `${arr[@]}` on possibly-empty arrays without guards — use a `case` statement for companions.
- `deploy/setup.ps1` needs no change: thin launcher, `-Select` already forwards.
- Out of scope (deliberate): manifest-tracked plugin installs via `init.mjs add --plugins` — the cp-with-companions path is the accepted #473 contract.
- Interactive TUI (`@opentui/core`) rendering is untouched; only the inventory feeding it changes.

## Dependencies
None — single ticket, no `blocked-by:` refs.

## Risks & Mitigation
| Risk | Mitigation |
|------|------------|
| `deploy_delegate.bats` line-order pin breaks from setup.sh edits | Edits confined to existing function bodies; suite run per Phase 2 completion (step 4.1) |
| `node -e` dynamic-import resolves against process cwd | Module path built from argv-passed absolute `${REPO_DIR}` via `pathToFileURL` (step 2.1); Done-when runs from a second cwd |
| Pseudo-TTY test flaky in CI | `script -qec` is util-linux standard on ubuntu runners; if unstable, keep the wiring covered by a direct function-invocation test instead (fallback decided in review, not silently) |
| Companion knowledge drifts between picker path and manifest path | Single declarative home: `dependency-map.json` `pluginCompanions` (step 2.2); cross-surface pin in test 3.3 |

GATE 4ee48c3 tier=full lint=- typecheck=- build=t unit=t e2e=- (re-gate after origin/main merge)
