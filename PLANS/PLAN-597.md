# PLAN: plan-execution-inline-skill — durable inline plan executor (#597)

**Branch**: feat/597
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/597
**Base**: main

## Acceptance Criteria

- [ ] New `skills/plan-execution-inline-skill/SKILL.md`: self-contained inline `--gate` loop (PLAN resolution + parse incl. rationale triple, dependency-map read, gate discovery deferred to `verification-loop-skill`, per-phase implement → test-new-code → verify (light default, full on critical anchors + ticket exit gate) → fix-on-fail max 3 → tick + `— Done:` traceability → one atomic commit + push → report; guardrails 12/20/protected-branch; completion markers; stop conditions) with an all-inline delegate matrix (tests → `testing-inline-skill`, lint → `linting-inline-skill`, docstrings/docs → `documentation-inline-skill`, E2E visual scope → `responsive-audit-inline-skill`; refactor/build/deploy/simple → direct); execution-only (no review/PR steps)
- [ ] Frontmatter contract: `name` equals directory name, description ≤50 words with neutral triggers, `license: Apache-2.0`, `compatibility: opencode`, `category: Git/Workflow`, zero experiment/A-B references
- [ ] `installer/dependency-map.json`: `requiresSkills` edge `plan-execution-inline-skill` → the four inline skills
- [ ] `tests/test_skill_isolation.bats`: handoff allowlist extended in one uniform owner→targets shape covering both declared handoffs
- [ ] `tests/test_requires_skills.bats`: map-equality assertion derives the expected map from ALL declared guard handoffs (not just the pptx pair)
- [ ] `AGENTS.md` §Skill Isolation Contract and `installer/dependency-map.json` `$comment` updated to the two-handoff shape
- [ ] `tests/skill_profiles.bats` lean-count literal moves with the lean array (77→78)
- [ ] `opencode_app/opencode.json`: `/run-plan-v2` loads the new skill; `/run-worktree-pipeline-v2` runs `worktree-pipeline-skill` with Step 8 via the new skill (explicit PLAN path), Steps 9/10 unchanged; `/review-arch` + `/review-inline` de-branded (pilot framing dropped, mechanism distinction kept); all descriptions neutral; skill-allow permission rule added for the new skill
- [ ] `README.md` + `opencode_app/README.md`: experiment note becomes a neutral two-flavors line; catalog table redistributes the four inline skills to real categories, removes the Experiment row, adds the new skill to Git/Workflow, total 154→155; every count restatement swept (154→155, 77→78 primary-visible)
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
| `tests/test_skill_isolation.bats` | dependency-map edge shape (2.1) | `test_requires_skills.bats` (parses HANDOFF lines) | medium |
| `tests/test_requires_skills.bats` | guard handoff vars (2.2) | — (leaf) | low |
| `tests/skill_profiles.bats` | lean array membership (2.4) | — (leaf; count literal 77→78 moves with the array) | low |
| `AGENTS.md` §Skill Isolation Contract + `installer/dependency-map.json` `$comment` | guard shape redesign (2.2/2.3) | contributors (prose pins the invariant) | low |
| `opencode_app/opencode.json` (commands + permissions) | new SKILL.md (1.1) | Docker deploy, user-space mirror (out of repo), `test_jsonc_sibling.bats` | low |
| `installer/presets/pack-inline-workers.json` (renamed) | new SKILL.md (1.1) | `init.mjs --preset`, `tests/init.bats` preset count (10) | low |
| `deploy/skill-profiles.json` | new SKILL.md (1.1) | `tests/skill_profiles.bats` (lean keys must exist on disk) | low |
| `installer/registry.json` (regenerated) | ALL frontmatter changes (1.1, 1.2) | `init.mjs --list/--describe/resolve`, README category table provenance | medium |
| `README.md` + `opencode_app/README.md` | registry rebuild (4.1, counts) | — (docs) | low |

Phase ordering follows the map: skill before wiring; wiring before guard-test coupling; commands/docs after the skill exists; registry last (consumes all frontmatter).

## Implementation Phases

### Phase 1: Inline executor skill + worker de-branding

- [x] **1.1** Create `skills/plan-execution-inline-skill/SKILL.md` — self-contained inline `--gate` loop with the all-inline delegate matrix, per the frontmatter contract (bare-name sibling references only; bash snippets carry the bash-requirement note; no `background: true` literals, no unix-only idioms, no experiment/A-B wording; `metadata: harness: "opencode"` declared and harness mechanisms presented via the capability-binding block with Other/none fallback)
    — **Why:** everything downstream (installer edge, guard allowlist, commands, preset, README) references this skill, so it must exist first
    — **Done when:** file exists; `name` equals dir; description ≤50 words; `rg -i "A/B|#582|#585|experiment" skills/plan-execution-inline-skill/SKILL.md` is empty; structural greps all non-empty: the four inline delegate targets (`testing-inline-skill`, `linting-inline-skill`, `documentation-inline-skill`, `responsive-audit-inline-skill`), guardrail literals `12` and `20`, `[goal:evidence]` + `[goal:complete]` + `[goal:blocked]`, tier wording `light`, `critical anchor`, `exit gate`, `full`; sibling-ref scan stays green (bare names only)
    — **Consumers affected:** dependency-map (2.1), guard (2.2), opencode.json commands (3.1), preset (3.3), README (3.2), registry (4.1)
    — **Done:** skill created with full inline gate loop + all-inline matrix + capability-binding block; files: skills/plan-execution-inline-skill/SKILL.md; fixes: self-caught branding-grep hit ("experiment" in prose) reworded to "trial variant"
- [x] **1.2** De-brand the four inline worker SKILL.md frontmatters — `category: experiment` → `Code Quality` (testing, linting), `Documentation` (documentation), `Responsive & Visual Testing` (responsive-audit); drop `experiment: inline-family` metadata keeping `mirrors:`; replace `/run-plan-v2 … step` trigger phrases with neutral inline-execution phrasing
    — **Why:** the family graduates from A/B harness to production skills; real categories feed the README table and registry
    — **Done when:** `grep -rl "category: experiment" skills/` is empty; each of the four keeps a `mirrors:` metadata line; no `run-plan-v2` trigger strings remain in the four files
    — **Consumers affected:** README catalog rows (3.2), registry (4.1)
    — **Done:** categories reassigned (Code Quality ×2, Documentation, Responsive & Visual Testing), experiment metadata dropped, triggers neutralized; files: skills/{testing,linting,documentation,responsive-audit}-inline-skill/SKILL.md; fixes: none

### Phase 2: Installer edge + guard coupling

- [ ] **2.1** Add the `requiresSkills` edge to `installer/dependency-map.json`: `"plan-execution-inline-skill": ["testing-inline-skill", "linting-inline-skill", "documentation-inline-skill", "responsive-audit-inline-skill"]`
    — **Why:** `npx … add plan-execution-inline-skill` must auto-install its four inline workers or the installed skill is broken standalone (#439 mechanics)
    — **Done when:** `python3 -c "import json; assert json.load(open('installer/dependency-map.json'))['requiresSkills']['plan-execution-inline-skill'] == ['testing-inline-skill','linting-inline-skill','documentation-inline-skill','responsive-audit-inline-skill']"` exits 0
    — **Consumers affected:** `test_requires_skills.bats` map equality (2.3), isolation guard handoff record (2.2)
- [ ] **2.2** Extend `tests/test_skill_isolation.bats`: declare both handoffs in one uniform shape — `HANDOFF1_OWNER`/`HANDOFF1_TARGETS` (pptx pair) and `HANDOFF2_OWNER="plan-execution-inline-skill"`/`HANDOFF2_TARGETS` (space-separated four inline skills); teach test 3's allowlist to accept each declared owner→targets set
    — **Why:** AGENTS.md §Skill Isolation Contract: the guard's HANDOFF vars are the source of truth for allowed cross-skill references; the new handoff must be declared there before any path-shaped reference could exist; one token shape keeps the derived pin in 2.3 single-form
    — **Done when:** `bats tests/test_skill_isolation.bats` exits 0; the new vars are greppable in the file; no scalar `HANDOFF_TARGET` (singular) remains
    — **Consumers affected:** `test_requires_skills.bats` (2.3 parses HANDOFF lines from this file), AGENTS.md + dependency-map $comment (2.5)
- [ ] **2.3** Update `requires_skills_map_entry_matches_isolation_guard_handoff_pair` in `tests/test_requires_skills.bats` to build the expected map from ALL declared handoffs (parsed uniformly from the guard's OWNER/TARGETS pairs) and assert `requiresSkills == expected` (full-map equality preserved)
    — **Why:** the assertion is the anti-drift coupling between map and guard; adding an edge without updating it fails CI by design
    — **Done when:** `bats tests/test_requires_skills.bats` exits 0 (all four tests)
    — **Consumers affected:** none (leaf test)
- [ ] **2.4** Register the new skill for visibility: add a `skill` permission allow rule for `plan-execution-inline-skill` in `opencode_app/opencode.json` (beside the four inline allows) and `"plan-execution-inline-skill"` to the `lean` array in `deploy/skill-profiles.json`; bump the lean-count literal in `tests/skill_profiles.bats` 77→78 (test name, count assertion, header comment)
    — **Why:** new skills default hidden; primary visibility requires the opencode.json allow + lean-profile entry (AGENTS.md §Skill Allowlist); the profile test pins the exact lean count, so the same commit must move it or the phase gate self-contradicts
    — **Done when:** both config files contain the new name; `grep -c '"' <(sed -n '/^  "lean"/,/^\]/p' deploy/skill-profiles.json)`-style count equals 78; `bats tests/skill_profiles.bats` exits 0
    — **Consumers affected:** Docker deploy (3.1 touches the same file), lean deploy
- [ ] **2.5** Update the guard's docs of record to the two-handoff shape: `AGENTS.md` §Skill Isolation Contract ("the single declared exception" → the two declared handoffs, HANDOFF vars named) and `installer/dependency-map.json` `$comment` ("The requiresSkills pair" → plural handoffs, owner→multi-target form)
    — **Why:** the 2.2/2.3 redesign invalidates prose that pins the old singular shape; a contributor following stale AGENTS.md would duplicate code instead of declaring a handoff
    — **Done when:** `rg -n "single declared exception|requiresSkills pair" AGENTS.md installer/dependency-map.json` is empty; both files name the two handoffs
    — **Consumers affected:** future contributors; `test_requires_skills.bats` $comment-derived docs

### Phase 3: Command + docs + preset de-branding

- [ ] **3.1** Rewrite the four #582-pilot command entries in `opencode_app/opencode.json`: `/run-plan-v2` template loads `plan-execution-inline-skill` for the given PLAN file; `/run-worktree-pipeline-v2` template loads `worktree-pipeline-skill` with Step 8 executed via `plan-execution-inline-skill` (explicit PLAN path), Steps 9/10 unchanged; `/review-arch` and `/review-inline` descriptions drop only the pilot framing ("Architecture review pilot (A/B arm A/B, #582) — "), keeping the mechanism distinction (isolated child session vs in-session); all descriptions neutral — no "A/B trial (#582)"/"A/B trial (#585)"/"A/B arm"/"#582"/"#585" wording
    — **Why:** the commands are the manual flavor choice; their templates must name the first-class skill instead of hard-coding a substitution map; the ticket's exit gate inspects this whole changed file, so sibling #582 branding in the review commands must go in the same step (requirements relay, gap 1: accepted)
    — **Done when:** file parses (JSON valid); `rg "A/B trial|A/B arm|#582|#585" opencode_app/opencode.json` is empty; both -v2 templates contain `plan-execution-inline-skill`; `bats tests/test_jsonc_sibling.bats` exits 0
    — **Consumers affected:** user-space `~/.config/opencode/opencode.json` (out-of-repo mirror, noted at PR time), README (3.2)
- [ ] **3.2** Update `README.md` and `opencode_app/README.md`: replace the line-24 experiment note with a neutral two-flavors line (subagent execution via `/run-plan` + `/run-worktree-pipeline`, inline execution via `/run-plan-v2` + `/run-worktree-pipeline-v2`, manual choice); catalog table — delete the Experiment row, move the four inline skills into Code Quality (14→16), Documentation (5→6), Responsive & Visual Testing (2→3), add `plan-execution-inline-skill` to Git/Workflow (14→15); sweep every count restatement: README.md:5 ("154 ready-to-load"), :76, :110, :251 ("77 primary-visible" + "all 154"), :288 (summary), :290 ("Current count") → 155 / 78 primary-visible; opencode_app/README.md:26 → 155
    — **Why:** the catalog and command notes are the user-facing contract; experiment framing must go, and every prose count must match disk reality or the docs contradict the test suite
    — **Done when:** `rg "#582|#585|A/B|Experiment" README.md` empty; `rg "\b154\b|77 primary" README.md opencode_app/README.md` empty (historical 123/146 in the count-history line untouched); category counts sum to 155
    — **Consumers affected:** documentation consumers; GitHub Pages catalog; Docker README
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
- Plan review (Step 7) ran via architecture-review-subagent: 1 blocker + 4 major + 2 minor applied — lean 77→78 literal bump (2.4), full count-restatement sweep incl. opencode_app/README.md (3.2), /review-arch + /review-inline de-branding (3.1), AGENTS.md + dependency-map $comment doc-of-record updates (2.5), structural content greps + tier wording in 1.1, uniform HANDOFF list shape (2.2). Requirements Gaps relayed to requirements-specialist Mode R — both answered accept-recommended (gap 1: de-brand the two review commands, forced by the exit-gate AC on the changed file; gap 2: restore tier wording as transcription fidelity). Findings were additive consumer fixes, not structural — no re-review required.
- Gate discovery: package.json has no scripts; no Makefile — lint/typecheck/build are n.a.; unit = bats suite; e2e n/a (no frontend). `build-registry.mjs` is the artifact build.
- Out of scope: `plan-execution-skill`, `worktree-pipeline-skill`, worker subagents, user-space `~/.config/opencode/opencode.json` (report at PR time), CHANGELOG/PLANS historical docs.

## Dependencies

- None external; single-ticket run. Originates from #582/#585 (both closed/merged).

## Risks & Mitigation

- Guard coupling missed → CI red on `test_requires_skills`; mitigated by updating both tests in the same phase (2.2/2.3) and running them scoped at the phase gate.
- README count drift → `test_count_drift.bats` guards setup.sh/disk (dynamic), README is prose; mitigated by recomputing category sums in 3.2's Done-when.
- Registry staleness → rebuild last (4.1) after every frontmatter change; diff audited before commit.
- Preset rename breaks `--preset experiment` muscle memory → 1:1 rename, README updated in the same PR; count literal untouched (10).
