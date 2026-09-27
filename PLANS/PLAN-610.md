# PLAN: --select convergence — prune-only mode for registry-removed entries

**Branch**: feat/610
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/610
**Base**: main

**Design decision (user-confirmed via question tool 2026-09-27): Option B** — teach `init.mjs` a surgical `prune` verb scoped to registry-removed entries (NOT `update --prune`'s whole-new-set semantics), called from the `--select` flow. Signal and behavior land in this one ticket (per the ticket's own rule).

## Acceptance Criteria
- [ ] A `--select` redeploy prunes manifest-tracked entries whose names left `installer/registry.json` (per Option B), with tests pinning the semantics: **no whole-manifest re-copy** and **registry-live-but-unselected entries survive**
- [ ] `--select` users see the registry-removed signal (pruned names reported in deploy output)
- [ ] Dry-run safety preserved (no mutation under `--dry-run`; comparison-only output per `tests/test_dry_run_leaks.bats` conventions)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` `cmdPrune` + dispatch | — (reuses cmdUpdate's detection/removal bodies) | setup.sh select flow; direct `opencode-init prune` users | med |
| `deploy/setup.sh` select `PLAN_STEPS` + new `deploy_selected_prune()` | Phase 1 verb | --select users' deploy output | med |
| `tests/init.bats` prune cases | Phases 1–2 | CI suite | low |
| `README.md` update recipe | Phase 1–2 shipped | users following the interim workaround | low |

## Implementation Phases

### Phase 1: `prune` verb in init.mjs
- [ ] **1.1** Add `cmdPrune(args, opts)`: read user manifest (die with update's no-manifest message shape if absent), `loadRegistry()`, iterate manifest entries with the SAME registry-removed detection as `cmdUpdate` (agent stems / skill name sets), and for each removed entry run the same per-target removal body as cmdUpdate's prune arm (rm targets, filter `prev.agents`/`prev.skills`, collect names). `--dry-run`: report `registry-removed (present locally): …` and mutate nothing. Applied run: `pruned: <names>` (or `(nothing to prune)`), then rewrite the manifest minus pruned entries. No re-copy arm — other entries' files are never read or written.
    — **Why:** Option B — the surgical predicate (registry-removed only) is what distinguishes convergence from Option A's whole-manifest refresh; extracting from cmdUpdate's existing bodies keeps one source of truth for detection and removal
    — **Done when:** on a synthetic manifest containing one registry-removed name + one live name, `node installer/init.mjs prune` removes only the removed entry, prints `pruned: <name>`, and leaves the live entry's files byte-identical
    — **Consumers affected:** setup.sh select flow (Phase 2); direct `opencode-init prune` users
- [ ] **1.2** Dispatch `prune` in `main()` + usage/help lines (top usage block + OPTIONS section, mirroring update's entry style)
    — **Why:** a verb without dispatch/help is undiscoverable and untestable via CLI
    — **Done when:** `node installer/init.mjs --help` (or usage block) lists prune; `prune` routes to cmdPrune
    — **Consumers affected:** CLI users; bats tests calling the CLI

### Phase 2: setup.sh select-flow wiring
- [ ] **2.1** Append a third step to the select `PLAN_STEPS` after `deploy-selected-agents`: `PLAN_STEPS+=("true|prune-registry-removed|Prune registry-removed entries|deploy_selected_prune")` and add `deploy_selected_prune()` mirroring the group functions' boolean-safe dry-run form (`dry_args="--dry-run"` under `$DRY_RUN`), calling `node "${INSTALLER_DIR}/init.mjs" prune $dry_args`
    — **Why:** the convergence must run once per --select deploy after both groups land, and appear as a visible, ordered deploy step so the signal surfaces in deploy output
    — **Done when:** a `--select --dry-run` deploy lists the `prune-registry-removed` step and emits the comparison signal without mutating `$HOME`
    — **Consumers affected:** --select users; PLAN_STEPS executor

### Phase 3: bats tests pinning Option-B semantics
- [ ] **3.1** New init.bats cases: (a) `prune` removes a synthetic registry-removed manifest entry (manifest JSON hand-crafted in TMP_HOME) and leaves a live installed skill byte-identical (surgical predicate); (b) `prune --dry-run` reports `registry-removed` and mutates nothing (manifest + dirs unchanged); (c) prune performs no re-copy: a deliberately corrupted installed file survives prune unchanged
    — **Why:** the ticket demands tests pinning the chosen semantics; (c) is the Option-A rejection made mechanical
    — **Done when:** the three cases pass in isolation and in the full suite
    — **Consumers affected:** CI suite
- [ ] **3.2** Full suite `bats tests/` green (catches collisions with existing prune/update expectations)
    — **Why:** exit-gate discipline
    — **Done when:** exit=0, zero failures
    — **Consumers affected:** CI

### Phase 4: docs + exit
- [ ] **4.1** Reword the README interim-workaround note (the `update --prune` recipe added for this gap) to document shipped behavior: `--select` deploys now converge (prune-registry-removed step); keep the manual `init.mjs prune`/`update --prune` instructions for non-select users
    — **Why:** the ticket calls the README recipe an interim workaround — leaving it stale after shipping recreates the drift class
    — **Done when:** README no longer calls it interim and documents the prune verb
    — **Consumers affected:** README readers
- [ ] **4.2** Exit gate: full `bats tests/` + `node installer/build-registry.mjs` no-op check (registry untouched — no agents/skills change) + `GATE <sha> tier=full` memo
    — **Why:** pipeline exit-gate citation for the PR
    — **Done when:** suite exit=0; `git status --porcelain installer/registry.json` empty; memo appended
    — **Consumers affected:** PR reviewer, merge watcher

## Technical Notes
- Detection reuse: `regAgentStems`/`regSkillNames` sets vs manifest entry names — agent matching is by stem (registry `stem` field), skills by `name` (cmdUpdate precedent).
- `prune` is a BOOL flag in `BOOL_FLAGS`; the new verb is the positional `prune` — no flag collision with `add --prune`'s ban (init.mjs:818-819).
- Manifest rewrite after prune must preserve unrelated manifest keys (`generatedAt` bump acceptable; `plugins` key preserved) — same shape as cmdUpdate's write.
- tests/init.bats TMP_HOME pattern (`mktemp -d` + `HOME=` override) is the isolation precedent.

## Dependencies
None — independent of #592/#261. #617 (other session) touches worktree-pipeline SKILL.md; no file overlap with this PLAN.

## Risks & Mitigation
- **Prune predicate too aggressive** → scoped to registry-removed ONLY; the live-skill-survives assertion in 3.1(a) pins it.
- **Dry-run mutation** → mirrored from cmdUpdate's `prune && !dry` guard; test (b) asserts byte-identical manifest/dirs.
- **Setup.sh nounset/empty-array traps** → new function mirrors `deploy_selected_group`'s boolean-safe `dry_args` pattern (documented at its head).
