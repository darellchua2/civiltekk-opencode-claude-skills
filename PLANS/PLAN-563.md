# PLAN: npx-skills parity: -g alias and remove _archived skills

**Branch**: feat/563
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/563
**Base**: main

## Acceptance Criteria

- [x] `add <skill> -g` and `add <skill> --global` install user scope identically to the default; `-g --project` exits non-zero naming the conflict
- [x] `--help` documents `-g, --global`
- [x] `skills/_archived/` removed from the working tree
- [x] Census: zero remaining references to the 6 removed skill names (README, AGENTS.md, dependency-map.json, deploy-plan-items.mjs, registry.json, tests)
- [x] Isolation guard: the `_archived` legacy exception retired from `tests/test_skill_isolation.bats` — the `_`-prefix ban becomes unconditional
- [ ] `node installer/build-registry.mjs` regenerates cleanly (commit `registry.json` if it changes); portability guard stays green
- [ ] Full `bats tests/` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` parseArgs/BOOL_FLAGS + main conflict guard | — | CLI users, setup.sh (`--yes` long form — unaffected), bats tests | low |
| `skills/_archived/**` (deleted) | — | nothing shipped: registry/build-registry already exclude it (census: zero names in registry.json); npx-skills walker is the only consumer — that leak is the bug | low |
| `skills/docstring-generator-skill/SKILL.md` L22 house-reference | `_archived` deletion | consumers of that skill | low |
| `tests/test_skill_isolation.bats` (:144 walker filter, :193–197 allowlist) | `_archived` deletion | CI | low |
| root `AGENTS.md` §Skill Isolation Contract exception sentence | `_archived` deletion | contributors, guard rationale | low |
| `README.md` npx-skills note | — | consumers | low |

## Implementation Phases

### Phase 1: `-g/--global` alias (installer)

- [x] **1.1** In `installer/init.mjs`: add `global` to `BOOL_FLAGS`; add an explicit `-g` case in `parseArgs` mapping to `opts.global = true` (single-dash tokens otherwise fall into positionals and die as an unknown name); add one guard in `main()` right after `build_plan`: `opts.global && opts.project` → `die("cannot combine --global with --project (user scope is the default; drop -g)", 2)` — one site covering the add and preset/init flows.
    — **Why:** `-g` is the npx-skills global-scope muscle memory; today it falls into positionals and dies as `'-g' not found`. The guard prevents a contradictory scope request from silently meaning "project".
    — **Done when:** `node --check installer/init.mjs` passes; `node installer/init.mjs add tdd-workflow-skill -g --project /tmp/x --yes` exits 2 printing "cannot combine --global"; `add --global` alone parses (no name error).
    — **Consumers affected:** every `add`/preset invocation path (guard), none otherwise.
    — **Done:** BOOL_FLAGS + `-g` case + main() conflict guard ("cannot combine --global with --project", exit 2); files: installer/init.mjs; fixes: none
- [x] **1.2** Help text: FLAGS section gains `-g, --global` ("user scope (default) — explicit npx-skills-compatible alias; cannot combine with --project"); SCOPE section unchanged (user scope already documented as default).
    — **Why:** undocumented accepted flags are drift bait (learned-pattern: help restatements drift when only the source is fixed).
    — **Done when:** `node installer/init.mjs --help` prints the `-g, --global` line.
    — **Consumers affected:** CLI users.
    — **Done:** FLAGS entry `-g, --global` printed by --help; files: installer/init.mjs; fixes: none
- [x] **1.3** Tests in `tests/init.bats`: (a) `add tdd-workflow-skill -g --yes` (sandboxed HOME) → user-scope dir exists; (b) `add solid-principles-skill --global --yes` → same; (c) `add tdd-workflow-skill -g --project "$TMP_PROJ" --yes` → non-zero + "cannot combine --global" in output.
    — **Why:** pins the alias behavior and the guard; the sandboxed-HOME pattern already established in this suite.
    — **Done when:** the three new tests pass.
    — **Consumers affected:** CI gate for later phases.
    — **Done:** two tests added (alias install with both spellings; conflict non-zero + message); files: tests/init.bats; fixes: none
- [x] **1.4** Gate: `bats tests/init.bats` green (light tier: affected suite).
    — **Why:** behavioral proof before docs/deletion phases stack on top.
    — **Done when:** exit 0.
    — **Consumers affected:** Phases 2–3 gates.
    — **Done:** bats tests/init.bats → 34 ok / 0 not ok, exit 0; files: none; fixes: none

### Phase 2: `_archived` deletion + census cleanup

- [x] **2.1** `git rm -r skills/_archived`; then run `node installer/build-registry.mjs` and confirm `git diff --stat installer/registry.json` is empty (census proved the registry already excludes `_archived`; if it is NOT empty, commit the regenerated registry and note the count delta).
    — **Why:** the deletion is the ticket's core fix — the npx-skills walker offered 6 retired skills as a "catalog level".
    — **Done when:** `skills/_archived` absent from the tree; registry.json unchanged (or regenerated + committed with explanation).
    — **Consumers affected:** ecosystem consumers (`npx skills add`); nothing internal (all tooling already excluded `_archived`).
    — **Done:** skills/_archived removed (git rm); build-registry zero-diff verified (only generatedAt churn — reverted); files: skills/_archived/**; fixes: none
- [x] **2.2** Trim the dead house-reference in `skills/docstring-generator-skill/SKILL.md` L22: remove `python-docstring-generator` from the "House references" list (the other three names are live skills).
    — **Why:** census AC — a shipped skill must not point at a deleted one.
    — **Done when:** `grep -rn 'python-docstring-generator' skills/` returns nothing.
    — **Consumers affected:** docstring-generator-skill readers.
    — **Done:** python-docstring-generator dropped from the House references list; files: skills/docstring-generator-skill/SKILL.md; fixes: none
- [x] **2.3** Retire the isolation-guard exception: delete the `parts[1].startswith("_")` walker filter (+ its comment) at `tests/test_skill_isolation.bats:144`, and rewrite the `skill_isolation_no_new_underscore_prefixed_shared_dirs` test (:193–197) to assert `ls skills/ | grep '^_'` finds nothing (drop `grep -v -x '_archived'` and the legacy-allowlist comment).
    — **Why:** with `_archived` gone the exception is dead weight; the ban becomes unconditional per the ticket.
    — **Done when:** the rewritten test passes; `grep -n "_archived" tests/test_skill_isolation.bats` returns nothing.
    — **Consumers affected:** CI.
    — **Done:** walker `_`-filter removed; allowlist test rewritten to unconditional ban; files: tests/test_skill_isolation.bats; fixes: none
- [x] **2.4** Root `AGENTS.md` §Skill Isolation Contract: replace "`_archived` is the only legacy exception" with the unconditional ban (and drop the parenthetical naming it).
    — **Why:** the prose grants an exception that no longer exists — documentation-consistency drift.
    — **Done when:** `grep -n "_archived" AGENTS.md` returns nothing.
    — **Consumers affected:** contributors.
    — **Done:** isolation-contract sentence updated to unconditional ban; files: AGENTS.md; fixes: none
- [x] **2.5** Census sweep: `grep -rn` for all 6 removed names across `*.md`, `*.json`, `*.bats`, `*.mjs` (excluding LEARNINGS history) → zero hits.
    — **Why:** the ticket's census AC — deleted skills must leave no dangling references.
    — **Done when:** the grep is empty; README/AGENTS/dependency-map/deploy-plan-items/registry/tests all clean.
    — **Consumers affected:** none (verification step).
    — **Done:** grep across md/json/bats/mjs/sh/ps1 → zero hits outside LEARNINGS history and this PLAN; files: none; fixes: none
- [x] **2.6** Gate: `bats tests/test_skill_isolation.bats tests/init.bats` green.
    — **Why:** the guard rewrite and the flag work are the phase's behavioral surface.
    — **Done when:** exit 0.
    — **Consumers affected:** Phase 3 gate.
    — **Done:** bats test_skill_isolation + init → 39 ok / 0 not ok, exit 0; files: none; fixes: none

### Phase 3: README note + full exit gate

- [ ] **3.1** `README.md`: one line in the individual-install section — the catalog is consumable via the ecosystem CLI (`npx skills add darellchua2/civiltekk-opencode-claude-skills`, project default) alongside this repo's own installer.
    — **Why:** consumers deserve to know both paths exist; the ticket's proposed solution includes it.
    — **Done when:** README mentions `npx skills add` for this repo.
    — **Consumers affected:** README readers.
- [ ] **3.2** Full exit gate: `bats tests/` (portability + isolation + profiles guards sweep the deleted tree and the flag change).
    — **Why:** ticket exit gate runs full tier; the deletion could shift any count-pinned test (skill_profiles union guard) — fix forward in-phase if so.
    — **Done when:** exit 0; gate memo `GATE <short-sha> tier=full` recorded in the trace.
    — **Consumers affected:** Step 9 review citation and Step 10 PR gate citation.

## Technical Notes

- `deploy/setup.sh` `count_skills`/`count_agents`/`print_skill_categories` keep their `*/_archived/*` find filters — harmless no-ops after deletion (defensive against stray `_archived` dirs); simplifying them is out of scope.
- `installer/registry.json` already excludes `_archived` (census at Step 5: none of the 6 names present) — expected zero-diff from build-registry; Step 2.1 verifies rather than assumes.
- `-g` on `update`/`remove` is accepted-and-ignored (they are already user-scope-only); the conflict guard only fires for `-g` + `--project`.
- `metadata.internal` approach was rejected by the ticket author in favor of deletion.

## Dependencies

None (no `blocked-by:`).

## Risks & Mitigation

- **Count-pinned tests** (skill_profiles union guard, init.bats preset counts): the deleted tree only removed already-excluded dirs — full gate catches any surprise; fix forward in the same phase.
- **build-registry drift**: Step 2.1 verifies the zero-diff assumption instead of trusting the census.
