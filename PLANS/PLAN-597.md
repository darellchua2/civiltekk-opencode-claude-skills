# PLAN: plan-execution-inline-skill — durable inline plan executor (#597)

**Branch**: feat/597
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/597
**Base**: main

## Acceptance Criteria

- [ ] New `skills/plan-execution-inline-skill/SKILL.md`: self-contained inline `--gate` loop (PLAN resolution + parse incl. rationale triple, dependency-map read, gate discovery deferred to `verification-loop-skill`, per-phase implement → test-new-code → verify → fix-on-fail max 3 → tick + `— Done:` traceability → one atomic commit + push → report; guardrails 12/20/protected-branch; completion markers; stop conditions) with an all-inline delegate matrix (tests → `testing-inline-skill`, lint → `linting-inline-skill`, docstrings/docs → `documentation-inline-skill`, E2E visual scope → `responsive-audit-inline-skill`; refactor/build/deploy/simple → direct); execution-only (no review/PR steps)
- [ ] Frontmatter contract: `name` equals directory name, description ≤50 words with neutral triggers, `license: Apache-2.0`, `compatibility: opencode`, `category: Git/Workflow`, zero experiment/A-B references
- [ ] `installer/dependency-map.json`: `requiresSkills` edge `plan-execution-inline-skill` → the four inline skills
- [ ] `tests/test_skill_isolation.bats`: handoff allowlist extended to cover the new handoff (owner + multi-target form)
- [ ] `tests/test_requires_skills.bats`: map-equality assertion derives the expected map from ALL declared guard handoffs (not just the pptx pair)
- [ ] `opencode_app/opencode.json`: `/run-plan-v2` loads the new skill; `/run-worktree-pipeline-v2` runs `worktree-pipeline-skill` with Step 8 via the new skill (explicit PLAN path), Steps 9/10 unchanged; both descriptions neutral; skill-allow permission rule added for the new skill
- [ ] `README.md`: experiment note becomes a neutral two-flavors line; catalog table redistributes the four inline skills to real categories, removes the Experiment row, adds the new skill to Git/Workflow, total 154→155
- [ ] Four inline worker skills de-branded: `category: experiment` → real categories, `experiment: inline-family` metadata dropped (`mirrors:` kept), `/run-plan-v2` trigger phrases neutralized
- [ ] `installer/presets/pack-experiment.json` renamed to `pack-inline-workers.json` (name/description de-branded, family closure gains the new skill); `tests/init.bats` preset count stays 10
- [ ] `deploy/skill-profiles.json` lean array gains the new skill
- [ ] `node installer/build-registry.mjs` run; regenerated `registry.json` committed
- [ ] Bats isolation/portability/requires-skills/init/count guards pass (full suite at exit gate)
- [ ] `rg "A/B trial|#582|#585"` over changed paths matches only historical docs (CHANGELOG, PLANS, LEARNINGS)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/plan-execution-inline-skill/SKILL.md` (new) | — | dependency-map edge (2.1), guard allowlist (2.2), opencode.json commands (3.1), README catalog, preset closure (3.3), registry rebuild | medium |
| `skills/{testing,linting,documentation,responsive-audit}-inline-skill/SKILL.md` (frontmatter) | — | README catalog rows, preset closure, registry rebuild | low |
| `installer/dependency-map.json` | new SKILL.md (1.1) | installer/init.mjs resolver, `test_requires_skills.bats` map equality | medium |
| `tests/test_skill_isolation.bats` | dependency-map edge shape (2.1) | `test_requires_skills.bats` (greps HANDOFF lines) | medium |
| `tests/test_requires_skills.bats` | guard handoff vars (2.2) | — (leaf) | low |
| `opencode_app/opencode.json` (commands + permissions) | new SKILL.md (1.1) | Docker deploy, user-space mirror (out of repo), `test_jsonc_sibling.bats` | low |
| `installer/presets/pack-inline-workers.json` (renamed) | new SKILL.md (1.1) | `init.mjs --preset`, `tests/init.bats` preset count (10) | low |
| `deploy/skill-profiles.json` | new SKILL.md (1.1) | `tests/skill_profiles.bats` (lean keys must exist on disk) | low |
| `installer/registry.json` (regenerated) | ALL frontmatter changes (1.1, 1.2) | `init.mjs --list/--describe/resolve`, README category table provenance | medium |
| `README.md` | registry rebuild (4.1, counts) | — (docs) | low |

Phase ordering follows the map: skill before wiring; wiring before guard-test coupling; commands/docs after the skill exists; registry last (consumes all frontmatter).

## Implementation Phases

### Phase 1: Inline executor skill + worker de-branding

- [ ] **1.1** Create `skills/plan-execution-inline-skill/SKILL.md` — self-contained inline `--gate` loop with the all-inline delegate matrix, per the frontmatter contract (bare-name sibling references only; bash snippets carry the bash-requirement note; no `background: true` literals, no unix-only idioms, no experiment/A-B wording)
    — **Why:** everything downstream (installer edge, guard allowlist, commands, preset, README) references this skill, so it must exist first
    — **Done when:** file exists; `name` equals dir; description ≤50 words; `rg -i "A/B|#582|#585|experiment" skills/plan-execution-inline-skill/SKILL.md` is empty; `bash tests/test_skill_isolation.bats`-style sibling-ref scan stays green (bare names only)
    — **Consumers affected:** dependency-map (2.1), guard (2.2), opencode.json commands (3.1), preset (3.3), README (3.2), registry (4.1)
- [ ] **1.2** De-brand the four inline worker SKILL.md frontmatters — `category: experiment` → `Code Quality` (testing, linting), `Documentation` (documentation), `Responsive & Visual Testing` (responsive-audit); drop `experiment: inline-family` metadata keeping `mirrors:`; replace `/run-plan-v2 … step` trigger phrases with neutral inline-execution phrasing
    — **Why:** the family graduates from A/B harness to production skills; real categories feed the README table and registry
    — **Done when:** `grep -rl "category: experiment" skills/` is empty; each of the four keeps a `mirrors:` metadata line; no `run-plan-v2` trigger strings remain in the four files
    — **Consumers affected:** README catalog rows (3.2), registry (4.1)

### Phase 2: Installer edge + guard coupling

- [ ] **2.1** Add the `requiresSkills` edge to `installer/dependency-map.json`: `"plan-execution-inline-skill": ["testing-inline-skill", "linting-inline-skill", "documentation-inline-skill", "responsive-audit-inline-skill"]`
    — **Why:** `npx … add plan-execution-inline-skill` must auto-install its four inline workers or the installed skill is broken standalone (#439 mechanics)
    — **Done when:** `python3 -c "import json; assert json.load(open('installer/dependency-map.json'))['requiresSkills']['plan-execution-inline-skill'] == ['testing-inline-skill','linting-inline-skill','documentation-inline-skill','responsive-audit-inline-skill']"` exits 0
    — **Consumers affected:** `test_requires_skills.bats` map equality (2.3), isolation guard handoff record (2.2)
- [ ] **2.2** Extend `tests/test_skill_isolation.bats`: add `HANDOFF2_OWNER="plan-execution-inline-skill"` + `HANDOFF2_TARGETS` (space-separated four inline skills) beside the existing scalars; teach test 3's allowlist (`own == owner and sib == target`) to also accept the second pair's owner→targets set
    — **Why:** AGENTS.md §Skill Isolation Contract: the guard's HANDOFF vars are the source of truth for allowed cross-skill references; the new handoff must be declared there before any path-shaped reference could exist
    — **Done when:** `bats tests/test_skill_isolation.bats` exits 0; the new vars are greppable in the file
    — **Consumers affected:** `test_requires_skills.bats` (2.3 greps HANDOFF lines from this file)
- [ ] **2.3** Update `requires_skills_map_entry_matches_isolation_guard_handoff_pair` in `tests/test_requires_skills.bats` to build the expected map from ALL declared handoffs (pptx pair + HANDOFF2 owner→targets) and assert `requiresSkills == expected` (full-map equality preserved)
    — **Why:** the assertion is the anti-drift coupling between map and guard; adding an edge without updating it fails CI by design
    — **Done when:** `bats tests/test_requires_skills.bats` exits 0 (all four tests)
    — **Consumers affected:** none (leaf test)
- [ ] **2.4** Register the new skill for visibility: add a `skill` permission allow rule for `plan-execution-inline-skill` in `opencode_app/opencode.json` (beside the four inline allows) and `"plan-execution-inline-skill"` to the `lean` array in `deploy/skill-profiles.json`
    — **Why:** new skills default hidden; primary visibility requires the opencode.json allow + lean-profile entry (AGENTS.md §Skill Allowlist)
    — **Done when:** both files contain the new name; `bats tests/skill_profiles.bats` exits 0
    — **Consumers affected:** Docker deploy (3.1 touches the same file), lean deploy

### Phase 3: Command + docs + preset de-branding

- [ ] **3.1** Rewrite the `/run-plan-v2` and `/run-worktree-pipeline-v2` command entries in `opencode_app/opencode.json`: `/run-plan-v2` template loads `plan-execution-inline-skill` for the given PLAN file; `/run-worktree-pipeline-v2` template loads `worktree-pipeline-skill` with Step 8 executed via `plan-execution-inline-skill` (explicit PLAN path), Steps 9/10 unchanged; both descriptions state the inline/subagent flavor split with no "A/B trial (#582)/(#585)" wording
    — **Why:** the commands are the manual flavor choice; their templates must name the first-class skill instead of hard-coding a substitution map
    — **Done when:** both entries parse (JSON valid); `rg "A/B trial" opencode_app/opencode.json` is empty; both templates contain `plan-execution-inline-skill`; `bats tests/test_jsonc_sibling.bats` exits 0
    — **Consumers affected:** user-space `~/.config/opencode/opencode.json` (out-of-repo mirror, noted at PR time), README (3.2)
- [ ] **3.2** Update `README.md`: replace the line-24 experiment note with a neutral two-flavors line (subagent execution via `/run-plan` + `/run-worktree-pipeline`, inline execution via `/run-plan-v2` + `/run-worktree-pipeline-v2`, manual choice); catalog table — delete the Experiment row, move the four inline skills into Code Quality (14→16), Documentation (5→6), Responsive & Visual Testing (2→3), add `plan-execution-inline-skill` to Git/Workflow (14→15), total count 154→155
    — **Why:** the catalog and command notes are the user-facing contract; experiment framing must go, counts must match disk reality
    — **Done when:** `rg "#582|#585|A/B|Experiment" README.md` matches nothing; table arithmetic consistent (category counts sum to 155)
    — **Consumers affected:** documentation consumers; GitHub Pages catalog
- [ ] **3.3** `git mv installer/presets/pack-experiment.json installer/presets/pack-inline-workers.json`; set `"name": "inline-workers"`, neutral description (no #582/A-B), `$comment` updated (hand-maintained, family now includes `plan-execution-inline-skill`), and append `plan-execution-inline-skill` + `git-semantic-commits-skill` to the skills closure
    — **Why:** the preset name/description is A/B branding; the new skill and its commit-convention dependency must ride the family closure
    — **Done when:** old file gone, new file parses, `--list presets` still yields 10 (`bats tests/init.bats` preset-count test green); `rg -i "experiment|A/B" installer/presets/` empty
    — **Consumers affected:** `--preset inline-workers` users; `tests/init.bats` count literal (unchanged at 10)

### Phase 4: Registry rebuild + exit gate

- [ ] **4.1** Run `node installer/build-registry.mjs`; verify the `registry.json` diff contains exactly: the new skill entry, four category/metadata updates, preset rename side effects — nothing else
    — **Why:** registry is the generated single source for installer/TUI/README provenance; all frontmatter changes must land before the rebuild (generated-artifact-unstaged-regression guard)
    — **Done when:** build exits 0; `git diff --stat installer/registry.json` shows only expected entries; rebuilt artifact staged with this phase's commit
    — **Consumers affected:** installer/init.mjs, GitHub Pages catalog
- [ ] **4.2** Run the full gate on the final tree: complete bats suite (`bats tests/`), plus the branding rg-gate `rg "A/B trial|#582|#585" --glob '!CHANGELOG.md' --glob '!PLANS/**' --glob '!LEARNINGS/**'` returning no matches in changed surfaces
    — **Why:** ticket exit gate — full tier unconditionally on the last gate of the run
    — **Done when:** bats suite exits 0; rg-gate empty; gate memo line appended to this PLAN's trace block
    — **Consumers affected:** PR creation (Step 10 cites this memo)

## Technical Notes

- Sibling-skill references in the new SKILL.md use bare backticked names (house pattern — the isolation guard only flags path-shaped refs in fenced runtime blocks).
- `LEARNINGS/decisions/preset-closure-over-new-requireskills-handoffs.md` (#582) chose preset-membership closure to avoid a guard redesign; #597 explicitly authorizes that redesign for the graduated family. Capture the delta in LEARNINGS at Step 9.
- Gate discovery: package.json has no scripts; no Makefile — lint/typecheck/build are n.a.; unit = bats suite; e2e n/a (no frontend). `build-registry.mjs` is the artifact build.
- Out of scope: `plan-execution-skill`, `worktree-pipeline-skill`, worker subagents, user-space `~/.config/opencode/opencode.json` (report at PR time), CHANGELOG/PLANS historical docs.

## Dependencies

- None external; single-ticket run. Originates from #582/#585 (both closed/merged).

## Risks & Mitigation

- Guard coupling missed → CI red on `test_requires_skills`; mitigated by updating both tests in the same phase (2.2/2.3) and running them scoped at the phase gate.
- README count drift → `test_count_drift.bats` guards setup.sh/disk (dynamic), README is prose; mitigated by recomputing category sums in 3.2's Done-when.
- Registry staleness → rebuild last (4.1) after every frontmatter change; diff audited before commit.
- Preset rename breaks `--preset experiment` muscle memory → 1:1 rename, README updated in the same PR; count literal untouched (10).
