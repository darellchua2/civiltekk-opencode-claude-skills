# PLAN: per-item interactive deploy picker (OpenTUI dashboard + linear + headless drivers)

**Branch**: feat/473
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/473
**Base**: main

## Acceptance Criteria
- [ ] Node ≥ 26.4 runtime floor installed by the environment layer: setup.sh + setup.ps1 nvm install 24 → 26 (and Node-26 references updated); opencode-ai tolerates Node 26 (it ships its own bundled runtime concerns — the floor is for the TUI dep)
- [ ] `@opentui/core` pinned exact `0.5.11` in package.json with regenerated lockfile (committed); prebuilt native binaries via its optionalDependencies — no build step, core TS API, no JSX
- [ ] New pure module `installer/deploy-plan-items.mjs`: builds the selectable item inventory (skills by category from registry.json, agents by tier, MCP packs from deploy/packs, plugins = opencode-* dir listing, extras) + the dependency DAG (dependency-map.json requiresSkills; pack ⇒ its matching skill) + `buildSelectionPlan(choices)` → plan JSON with auto-included dependencies and per-inclusion `lockedBy`/`reason` records
- [ ] Three drivers over that module with IDENTICAL plan output for identical selections: (a) OpenTUI dashboard `tui.mjs select-items` — DAG-ordered groups (environment, identity, content: skills/agents/packs/plugins, extras), locked items visibly disabled with the reason, arrow/space/enter keys; (b) linear readline fallback (Node < 26.4 or opentui import failure) — same order, sequential prompts; (c) headless `--print-plan --skills a,b --agents x --packs p --plugins q --extras llm,vllm --defaults` — zero TTY reads
- [ ] setup.sh integration: `--select` flag + menu-context picker writes the selection plan to `$CONFIG_DIR/deploy-plan.json`; the full-path plan gains conditional steps deploying FROM the selection (skills/agents via `init.mjs add <names>` — requiresSkills auto-install, packs merged, plugins deployed, extras configured); headless full path unchanged (blanket deploy)
- [ ] bats (tests/test_select_items.bats): DAG auto-include + lock reasons (pure-module pins), print-plan determinism, linear≡print-plan equivalence (piped answers), headless zero-TTY, nvm 26 pins (both scripts), opentui exact-pin + lockfile presence, setup wiring
- [ ] Full gate green (npm install regenerates package-lock.json — committed per repo convention)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `package.json` + package-lock.json | — | npm ci (CI has no node_modules need for opentui — bats is bash) | medium — new runtime dep, native optionalDeps |
| `installer/deploy-plan-items.mjs` (new, pure) | registry.json, dependency-map.json, deploy/packs, plugins dir | both TUI drivers, --print-plan, setup.sh deploy-from-selection | low |
| `deploy/tui.mjs` select-items flow | deploy-plan-items; @opentui/core (dashboard only) | setup.sh --select / menu | medium |
| `deploy/setup.sh` + `deploy/setup.ps1` nvm 26 | — | fresh installs | low |
| `deploy/setup.sh` select/plan-consumption steps | #470 executor; init.mjs add <names> | interactive full path | medium |
| `tests/test_select_items.bats` (new) | all of the above | CI | low |

## Implementation Phases

### Phase 1: dependency + runtime floor
- [ ] **1.1** package.json: `"@opentui/core": "0.5.11"` (exact); `npm install` to regenerate package-lock.json; commit both
    — **Why:** Ticket AC — the dashboard dep, exact-pinned per the grilled decision; lockfile committed per repo convention.
    — **Done when:** `npm ls @opentui/core` shows 0.5.11; package-lock diff committed; existing suites unaffected (node --test + init tests don't import opentui).
    — **Consumers affected:** CI npm ci (installs the dep — verify CI time acceptable via this PR's run).
- [ ] **1.2** setup.sh + setup.ps1: nvm install/use 24 → 26; version references updated; README Node mention updated if present
    — **Why:** @opentui/core engines require node ≥ 26.4; the environment layer must provision it.
    — **Done when:** grep shows no stale `nvm install 24` / `nvm use 24`; both scripts pinned by tests (2.1).
    — **Consumers affected:** fresh installs get Node 26.

### Phase 2: pure plan-item module + three drivers
- [ ] **2.1** installer/deploy-plan-items.mjs: `buildInventory()` (skills grouped by registry category, agents by tier, packs from deploy/packs/pack-*.json names, plugins from deploy/plugins/opencode-* dirs, extras fixed list) + `dependencyLocks()` (requiresSkills edges; pack ⇒ matching skill; recorded as {item, requires, reason}) + `buildSelectionPlan(choices)` (validates, auto-includes required deps, annotates each inclusion with why: direct|locked-by:<id>) — pure, no I/O beyond caller-passed data
    — **Why:** All three drivers render/produce over the same pure core — the identical-output AC becomes testable without a TTY.
    — **Done when:** pins in 2.1 exercise inventory + locks + auto-include directly (node -e over the module with fixture data).
    — **Consumers affected:** tui.mjs flows, setup.sh consumption.
- [ ] **2.2** tui.mjs `select-items` flow: dashboard (opentui core API: terminal init, group/list rendering in DAG order, space toggles, lock display with reason, enter = emit plan JSON to --out or stdout), `--print-plan` headless mode (flags → choices → plan; zero TTY reads), linear fallback (auto-selected when node < 26.4 or opentui import throws; sequential prompts in the same DAG order; `--driver linear` forces it)
    — **Why:** The ticket's three drivers; identical plan output is the AC.
    — **Done when:** equivalence pin (2.1): linear piped answers vs print-plan flags → identical plan JSON; dashboard import failure falls back (pin: FORCE_LINEAR=1 or mocked import failure).
    — **Consumers affected:** setup.sh --select; tests.
- [ ] **2.3** setup.sh: `--select` flag → interactive full path runs `tui.mjs select-items --out "$CONFIG_DIR/deploy-plan.json"` (non-critical plan step before content), then conditional steps `deploy_selected_content` (init.mjs add <skills/agents>, packs, plugins, extras from the plan) — skipped cleanly when no plan file exists (headless/full-blanket unchanged); menu unchanged (option 3 gains the picker after provider selection)
    — **Why:** The picker must deploy what it selects — otherwise dead UI.
    — **Done when:** wiring pins; an end-to-end dry-run with a pre-seeded plan file deploys exactly the selected skill (2.1).
    — **Consumers affected:** interactive full-path users; headless unchanged.

### Phase 3: pins + full gate
- [ ] **3.1** tests/test_select_items.bats: pure-module pins (inventory shape from fixture registry/packs, lock reasons, auto-include), print-plan determinism (same flags → same bytes), linear equivalence, headless zero-TTY (main-select path under </dev/null completes), nvm 26 pins both scripts, opentui exact pin + lockfile presence, setup wiring (--select flag, plan-step membership, conditional consumption)
    — **Why:** The AC matrix as executable contract.
    — **Done when:** green offline (no opentui import needed for the pure/headless pins; dashboard flow pinned by import-failure fallback).
    — **Consumers affected:** CI.
- [ ] **3.2** Full gate: `bash -n`, `bats tests/`, `node --test tests/*.test.ts`, `npm ls @opentui/core`; diff scope = package.json/lock + tui/primitives + new module + setup scripts + new test
    — **Why:** Gate contract.
    — **Done when:** all green.
    — **Consumers affected:** none.

## Technical Notes
- OpenTUI usage stays minimal (terminal init, text/list draw, key events) via the core TS API — the pinned version ships TS directly; no build step, no JSX (grilled decision).
- The dashboard degrade path is load-bearing: CI and headless environments never import opentui (print-plan/linear only), so a broken native binary cannot break deploys — pinned by the fallback test.
- Skills list is 146 items — the dashboard renders categories collapsed-by-default with per-category bulk toggle; linear fallback prompts per category (all/skip/list) then per-item only for "list" — sequential-prompt AC satisfied without 146 mandatory prompts.
- #470's executor consumes the picker output as conditional steps; the blanket deploy remains the default everywhere else.

## Dependencies
Epic #464; #470 (executor) + #471 (credential blocks in the identity group). Blocks nothing; #474 may fold its UX into subcommands later.

## Risks & Mitigation
- **Native dep weight / platform coverage**: opentui ships prebuilt optionalDeps for 8 platforms; CI (linux) installs one. The dashboard is only entered interactively; all non-interactive paths never import it (pinned).
- **Node 26 floor for fresh installs**: nvm installs the pinned major; existing installs unaffected (the picker falls back to linear under node < 26.4).
- **Big-diff risk**: mitigated by the pure-module split (Phase 2.1 lands and pins before any TUI code), behavior-preserving default paths (headless/full unchanged), and the arch review gate on this PLAN.
