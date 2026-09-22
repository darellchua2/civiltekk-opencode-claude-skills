# PLAN: Deploy picker — truthful catalog and safe plugin picks

**Branch**: feat/537
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/537
**Base**: main

## Acceptance Criteria
- [ ] `./deploy/setup.sh --list-items` prints the real packs (autodesk, markitdown, nextjs, docling, chrome-devtools) and the 5 `opencode-*.ts` plugins
- [ ] The plugins group and `--print-plan --defaults` list the same 5 `.ts` plugins; the README is offered in neither
- [ ] Selecting `opencode-ponytail-scoped.ts` deploys the `.ts` + `ponytail/` (SKILL.md, instructions.cjs) + `ATTRIBUTION.md`
- [ ] Selecting `opencode-vibeguard-v2.ts` still copies `vibeguard.config.json`
- [ ] Menu option 6 routes to the picker path; `--select` behavior unchanged
- [ ] `bats tests/test_select_items.bats tests/test_ships_plugins.bats tests/test_deploy_delegate.bats` pass; full suite green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/deploy-plan-items.mjs` (new scanner exports) | `./init.mjs` (existing import, import-safe) | `deploy/tui.mjs` (loadPickerData, planFromFlags), `deploy/setup.sh` (dump_catalog via node) | med — two consumers must switch in the same change |
| `deploy/tui.mjs` (loadPickerData, planFromFlags) | scanners from deploy-plan-items.mjs (Phase 1) | `setup.sh --select` picker (dashboard + linear + defaults) | low |
| `deploy/setup.sh` `dump_catalog` | scanners from deploy-plan-items.mjs (Phase 1) | `--list-items` CLI output | low |
| `deploy/setup.sh` `apply_selected_packs_extras` | `plugins/` source tree (companion artifacts) | `--select` plugin deploy | med — plugin correctness at runtime |
| `deploy/setup.sh` main() Setup Mode menu | build_plan (SELECT_ITEMS flag) | interactive menu users | low |

Cross-module node: the scanners have consumers in two modules (`deploy/tui.mjs` and `deploy/setup.sh`) — architecture review is selected for plan review.

## Implementation Phases

### Phase 1: Shared scanners (foundation)
- [ ] **1.1** Add exported `scanPackNames(packsDir)` and `scanPluginNames(pluginsDir)` to `installer/deploy-plan-items.mjs` (packs = `pack-*.json` stems; plugins = `opencode-*.ts` files only), with a doc note that caller-passed-dir readdir is the module's one I/O exception.
    — **Why:** the pack/plugin filter rule currently lives in two drifted copies inside `deploy/tui.mjs` (`loadPickerData` scans `opencode-*` unfiltered, `planFromFlags` filters `.ts` only); the catalog dump in `setup.sh` has a third, empty copy. One source is the fix for all three.
    — **Done when:** a `node --input-type=module -e` import of the module returns 5 pack stems and 5 plugin `.ts` names for this repo's `deploy/packs/` and `plugins/` dirs.
    — **Consumers affected:** `deploy/tui.mjs` and `deploy/setup.sh` `dump_catalog` (both switch in Phases 1–2).
- [ ] **1.2** Switch `deploy/tui.mjs` `loadPickerData` and `planFromFlags` (`--defaults` path) to call the shared scanners.
    — **Why:** removes the README from the selectable inventory and ends the 6-vs-5 defaults/inventory inconsistency.
    — **Done when:** `node deploy/tui.mjs select-items --print-plan --defaults` emits `plugins` with exactly the 5 `opencode-*.ts` names and no README entry.
    — **Consumers affected:** `setup.sh --select` picker UX (inventory and defaults now agree).

### Phase 2: Truthful catalog, safe plugin picks, menu entry
- [ ] **2.1** Rewrite `dump_catalog` in `deploy/setup.sh` to import the shared scanners (dynamic import in the existing `node` one-liner; no new file, no step-order change).
    — **Why:** `--list-items` currently hardcodes `packs: []` / `plugins: []`, telling users plugins are not installable — the ticket's headline gap.
    — **Done when:** `./deploy/setup.sh --list-items` output lists all 5 pack names and all 5 `opencode-*.ts` plugins.
    — **Consumers affected:** `--list-items` CLI output only.
- [ ] **2.2** In `apply_selected_packs_extras`, replace the vibeguard-only special case with a companion `case` statement: `opencode-vibeguard-v2.ts` → also copy `vibeguard.config.json`; `opencode-ponytail-scoped.ts` → also copy `ponytail/` and `ATTRIBUTION.md`.
    — **Why:** picking the ponytail wrapper today ships a broken plugin (its instructions source `ponytail/instructions.cjs` never lands); the vibeguard config is what arms masking.
    — **Done when:** a sandboxed deploy of a pre-seeded plan containing only `opencode-ponytail-scoped.ts` produces `opencode-ponytail-scoped.ts`, `ponytail/SKILL.md`, `ponytail/instructions.cjs`, and `ATTRIBUTION.md` in the plugin dir (artifact set per `tests/test_ships_plugins.bats`).
    — **Consumers affected:** `--select` plugin deploy correctness; no change for skills/agents/packs/extras paths.
- [ ] **2.3** Add Setup Mode menu option `6) Select items to deploy (skills / agents / packs / plugins)` that sets `SELECT_ITEMS=true` in `main()`.
    — **Why:** `--select` is flag-only; the default interactive menu gives no path to plugins/subagents — the discoverability gap.
    — **Done when:** a pseudo-TTY (`script -qec`) run of the menu choosing option 6 logs the picker plan steps (`select-items`, `deploy-selected-skills`, …) and no blanket agents/plugins step.
    — **Consumers affected:** interactive menu only; flags `--select`, `--quick`, etc. unchanged.

### Phase 3: Test coverage
- [ ] **3.1** Extend `tests/test_select_items.bats`: pin the plugin filter (inventory and `--print-plan --defaults` both list exactly the 5 `.ts` plugins, README absent from both).
    — **Why:** the README-in-inventory bug and the defaults drift are exactly the regression class this AC forbids.
    — **Done when:** new assertions pass and existing pins (determinism, driver equivalence, MCP_TO_PACK) stay green.
    — **Consumers affected:** none (test-only).
- [ ] **3.2** Add a bats test that `--list-items` prints non-empty `packs` and `plugins` arrays with the expected counts.
    — **Why:** the catalog dump was the lying surface; pin it so it cannot silently regress to empty arrays.
    — **Done when:** the test fails on the pre-change behavior (empty arrays) and passes post-change.
    — **Consumers affected:** none (test-only).
- [ ] **3.3** Add a bats test for plugin selection deploy: pre-seed a plan with only `opencode-ponytail-scoped.ts` (and a second case with only `opencode-vibeguard-v2.ts`), run the deploy in a sandbox `HOME`, assert the companion artifact sets land.
    — **Why:** companion-copy correctness is the AC with real data-loss shape (a broken plugin in the user's config).
    — **Done when:** both sandbox runs produce exactly the artifact sets from AC 3/4.
    — **Consumers affected:** none (test-only).
- [ ] **3.4** Add a bats test for menu option 6 wiring using `script -qec` (pseudo-TTY), asserting the picker plan steps are logged.
    — **Why:** the menu change is the only user-facing routing change; without a pin it can silently revert.
    — **Done when:** the test passes on this branch; on main it would fail (option absent).
    — **Consumers affected:** none (test-only).

### Phase 4: Verification gate
- [ ] **4.1** Run the affected suites (`bats tests/test_select_items.bats tests/test_ships_plugins.bats tests/test_deploy_delegate.bats tests/test_plan_executor.bats`), then the full `bats tests/` suite; fix anything red before proceeding.
    — **Why:** `test_deploy_delegate.bats` pins first-occurrence line order in `setup.sh` — the strongest regression risk of Phases 2; the full suite catches cross-file drift (count pins, portability guard).
    — **Done when:** full suite exits 0; the ticket exit gate memo line `GATE <sha> tier=full` is recorded for the final SHA.
    — **Consumers affected:** Step 9 review and Step 10 PR citation (both consume the gate memo).

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
| node one-liner in dump_catalog fails on Node versions without ESM `-e` support | Node >= 20 supports `--input-type=module -e`; repo already requires Node 20+ (installer CLI), and the ps1 bootstrap requires >= 26.4 |
| Pseudo-TTY test flaky in CI | `script -qec` is util-linux standard on ubuntu runners; if unstable, keep the wiring covered by a direct function-invocation test instead (fallback decided in review, not silently) |
| Companion map drifts as new plugins ship | The scanners + companion `case` live next to the plugins they describe; `test_ships_plugins.bats` already pins the ponytail artifact set |
