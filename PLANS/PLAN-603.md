# PLAN: Wave 1 — consolidate 24 skills into 11 civiltekk- hosts

**Branch**: feat/603
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/603
**Base**: main (8478774 — includes #609 Docker-mode removal; `opencode_app/` no longer exists, sweeps target `README.md` only)

## Acceptance Criteria

- [ ] 11 atomic commits `refactor(skills): consolidate X into Y`; counts green per commit
- [ ] HANDOFF2_TARGETS + dependency-map requiresSkills for plan-execution-inline cite civiltekk-documentation-inline-skill
- [ ] deploy/.AGENTS.md granularity + api-design exception lines cite civiltekk- names; repo AGENTS.md doc-sync row updated
- [ ] docstring fold repoints done: documentation-subagent, nextjs-specialist-subagent, pack-docs.json, pack-frontend.json
- [ ] registry.json rebuilt per merge; `bats tests/` green; LEARNINGS count-literal sweep clean
- [ ] All member triggers preserved in host descriptions; skill count = 136 after this wave (150 - 14)

## Pattern template (every host follows — ticketing-skill shape)

Host SKILL.md = METHOD only (~≤140 lines): first body line `Consolidates <members> (#603)`; §What I do (numbered route); §Side files table (read/when/use); §Detection: explicit > inferred > ask-once (one ask per run); §Routes (situation → variant); §Boundaries (what belongs elsewhere); §Agent behavior rules; harness-binding block (question tool / AskUserQuestion / plain-reply). `references/<variant>.md` = VALUES only (commands, vocabularies, tables, templates; scripts/assets move intact). Frontmatter: `name` = dir name (`civiltekk-*`, ≤64 chars), `description` = union of ALL member trigger phrases (≤1024 chars), `license: Apache-2.0`, `compatibility: opencode`, `category` inherited from members. Every member's triggers must survive verbatim in the union.

## Standard phase skeleton (each phase = one merge = one commit)

- **N.1** Author host SKILL.md + `references/` (method+values; trigger-union description)
- **N.2** `git rm` absorbed dirs + repoint ALL consumers listed for that merge
- **N.3** `node installer/build-registry.mjs` + scoped gate (affected bats files + count sweep + `ls -d skills/*/ | wc -l`)
- **N.4** Atomic commit + push (PLAN ticks ride it — no standalone docs commits)

Count sweep per phase (adapted post-#609): `grep -rn 'skill director\|lean has exactly\|deny-ok\|primary-visible\|allows)' tests/ deploy/ README.md` — every literal the decrement touches gets fixed in the SAME commit; plus `bats tests/skill_profiles.bats tests/test_select_items.bats tests/test_ships_plugins.bats` (whichever the phase touches) and the phase's other affected test files.

## Dependency & Consumer Map

| Node | Depends on | Consumers | Risk |
|------|-----------|-----------|------|
| 11 new `skills/civiltekk-*` dirs | — | agents, presets, installer, registry | med |
| `installer/registry.json` | each merge | installer/init.mjs, presets | low (generated) |
| `tests/test_skill_isolation.bats` (HANDOFF2_TARGETS) | Phase 11 | guard + pin test (derived) | high |
| `installer/dependency-map.json` (requiresSkills entry, shipsPlugins ponytail edge) | Phases 2, 11 | init.mjs, pin test | high |
| `agents/*.md` allowlists+bodies | each merge | subagent routing | med |
| `installer/presets/pack-*.json` | each merge | installer packs | med |
| `deploy/skill-profiles.json`, `opencode.json` | phases touching primary-visible skills | primary visibility | med |
| `deploy/.AGENTS.md` | Phases 1, 7 | user-level deployed config | med |
| `AGENTS.md` (repo) | Phase 4 (doc-sync row) | agents | low |
| `README.md`, `deploy/setup.sh`, `deploy/setup.ps1` | every phase | counts/banners | low |
| `deploy/opencode.json` | — (post-#609 impliesMcp reference target) | none here | — |

## Implementation Phases

### Phase 1: civiltekk-opencode-creation-skill (smallest risk — warm-up)
Absorbs: `opencode-agent-creation-skill` (11.4K) + `opencode-skill-creation-skill`. references/: `agent.md`, `skill.md`.
Consumers: agents/opencode-tooling-subagent.md (allowlist + body), deploy/skill-profiles.json, installer/presets/pack-core.json (agent-creation only — verify), README.md.
- [ ] **1.1** Author host + references per template (shared frontmatter-contract knowledge is the shared method; per-artifact values split by variant)
    — **Why:** biggest body (agent-creation 11.4K) is mostly per-artifact values — the split is the token win
    — **Done when:** host ≤140 lines; both members' triggers present in description; `bats tests/test_skill_isolation.bats` green (new dir self-contained)
    — **Consumers affected:** opencode-tooling-subagent routing
- [ ] **1.2** Delete absorbed dirs + repoint: tooling-subagent allowlist/body, skill-profiles, pack-core/pack-devops entries, README table
    — **Why:** stale names break agent routing + installer packs
    — **Done when:** `grep -rn 'opencode-agent-creation-skill\|opencode-skill-creation-skill' --exclude-dir=.git .` returns only registry.json (pre-rebuild), historical PLANS/LEARNINGS
    — **Consumers affected:** opencode-tooling-subagent, installer packs
- [ ] **1.3** Registry rebuild + scoped gate + count check (149)
    — **Why:** registry is installer input; counts must stay green per commit
    — **Done when:** `node installer/build-registry.mjs` clean diff (only expected entries); affected bats green; sweep clean; count 149
    — **Consumers affected:** installer/init.mjs
- [ ] **1.4** Commit `refactor(skills): consolidate opencode creation skills into civiltekk-opencode-creation-skill` + push
    — **Why:** atomic, reversible merge unit; PLAN ticks ride it
    — **Done when:** pushed; `git log -1` shows phase files + PLAN in one commit
    — **Consumers affected:** none beyond phase

### Phase 2: civiltekk-git-commits-skill
Absorbs: `git-semantic-commits-skill` + `git-compact-commits-skill`. references/: `semantic.md`, `compact.md`. Routes: conventional-format | brevity-budget (descriptions already cross-reference as alternatives).
Consumers: deploy/skill-profiles.json, deploy/.AGENTS.md (§Commits "Granularity: git-semantic-commits-skill" line → new name), installer/presets/pack-core.json + pack-devops.json + pack-inline-workers.json, tests/test_select_items.bats.
- [ ] **2.1** Author host + references per template
    — **Why:** two commit-style skills are one method (write a commit) with two style variants
    — **Done when:** host routes both; triggers union intact; isolation bats green
    — **Consumers affected:** AGENTS.md §Commits readers
- [ ] **2.2** Delete + repoint (skill-profiles, deploy/.AGENTS.md granularity line, 3 presets, test_select_items literals)
    — **Why:** deploy/.AGENTS.md ships to user-level config — stale name misdirects the primary session
    — **Done when:** grep residue clean (same rule as 1.2); test_select_items green
    — **Consumers affected:** primary-session commit behavior, packs
- [ ] **2.3** Registry + scoped gate + count (148)
    — **Why:** per-commit green discipline
    — **Done when:** same shape as 1.3 with count 148
    — **Consumers affected:** installer
- [ ] **2.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed single commit
    — **Consumers affected:** none beyond phase

### Phase 3: civiltekk-context-optimization-skill
Absorbs: `context-budget-skill` (10.1K) + `strategic-compact-skill`. references/: `budget.md`, `compact.md`. Routes: audit-overhead | compaction-strategy.
Consumers: agents/autoresearch-{code,ml,research}-subagent.md (strategic-compact), agents/loop-operator-subagent.md, deploy/skill-profiles.json, presets pack-frontend/pack-business/pack-review (context-budget) + pack-research (strategic-compact).
- [ ] **3.1** Author host + references per template
    — **Why:** both are token-economy method skills; one audit route, one strategy route
    — **Done when:** template satisfied; triggers intact; isolation green
    — **Consumers affected:** autoresearch agents, loop-operator
- [ ] **3.2** Delete + repoint (4 agent files, skill-profiles, 4 presets)
    — **Why:** autoresearch agents allowlist strategic-compact by name
    — **Done when:** grep residue clean
    — **Consumers affected:** autoresearch loops, packs
- [ ] **3.3** Registry + scoped gate + count (147)
    — **Why:** per-commit green
    — **Done when:** same shape; count 147
    — **Consumers affected:** installer
- [ ] **3.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 4: civiltekk-documentation-sync-skill
Absorbs: `documentation-sync-workflow-skill` + `documentation-consistency-skill`. references/: `sync-on-add.md`, `drift-audit.md`. Routes: on-add sync | drift audit/fix.
Consumers: agents/repo-ops-specialist-subagent.md, agents/opencode-tooling-subagent.md, agents/opencode-v2-migration-subagent.md, deploy/skill-profiles.json, presets pack-devops (both), tests/test_default_behavior.bats + test_autoresearch_protocol.bats (consistency literals), README.md, repo `AGENTS.md` (sync-rules row names documentation-sync-workflow).
- [ ] **4.1** Author host + references per template
    — **Why:** same object (docs counts/drift), two situations (adding vs auditing)
    — **Done when:** template satisfied; triggers intact; isolation green
    — **Consumers affected:** repo-ops, tooling agents
- [ ] **4.2** Delete + repoint (3 agents, skill-profiles, presets, 2 bats literal sets, README, AGENTS.md row)
    — **Why:** bats pin member names — literals must move with the merge
    — **Done when:** residue clean; test_default_behavior + test_autoresearch_protocol green
    — **Consumers affected:** CI, agents
- [ ] **4.3** Registry + scoped gate + count (146)
    — **Why:** per-commit green
    — **Done when:** count 146; affected bats green
    — **Consumers affected:** installer
- [ ] **4.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 5: civiltekk-startup-docs-skill
Absorbs: `startup-business-docs-skill` + `startup-pitch-deck-skill`. references/: `business-docs.md`, `pitch-deck.md`. Routes: business docs | pitch decks.
Consumers: agents/startup-founder-subagent.md (both), agents/startup-ceo-subagent.md (pitch-deck), presets pack-docs (pitch-deck) + pack-business (both), README.md.
- [ ] **5.1** Author host + references per template
    — **Why:** one startup-docs family, two deliverable variants; same subagent pair consumes
    — **Done when:** template satisfied; triggers intact; isolation green
    — **Consumers affected:** startup agents
- [ ] **5.2** Delete + repoint (2 agents, presets, README)
    — **Why:** agents allowlist members by name
    — **Done when:** residue clean
    — **Consumers affected:** startup agents, packs
- [ ] **5.3** Registry + scoped gate + count (145)
    — **Why:** per-commit green
    — **Done when:** count 145
    — **Consumers affected:** installer
- [ ] **5.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 6: civiltekk-python-backend-skill
Absorbs: `python-backend-skill` (host renames) + `python-packaging-skill` + `fastapi-pydantic-orm-patterns-skill`. references/: `scaffold.md`, `packaging.md`, `fastapi-orm.md`. Routes: scaffold | package | patterns.
Consumers: agents/language-reviewer-subagent.md (packaging + fastapi), deploy/skill-profiles.json, presets pack-review + pack-backend, README.md.
- [ ] **6.1** Rename dir + author host + references per template (host body is the scaffold method)
    — **Why:** scaffold method already exists — it absorbs the other two as routes
    — **Done when:** template satisfied; all three trigger sets intact; isolation green
    — **Consumers affected:** language-reviewer
- [ ] **6.2** Delete absorbed + repoint (language-reviewer allowlist/body, skill-profiles, presets, README)
    — **Why:** stale names break reviewer routing
    — **Done when:** residue clean (python-backend-skill old name included)
    — **Consumers affected:** language-reviewer, packs
- [ ] **6.3** Registry + scoped gate + count (143)
    — **Why:** per-commit green (3 dirs removed: 145→143... running total corrected at gate)
    — **Done when:** count 143; affected bats green
    — **Consumers affected:** installer
- [ ] **6.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 7: civiltekk-diagram-skill
Absorbs: `ascii-diagram-creator-skill` + `mermaid-diagram-creator-skill`. references/: `ascii.md`, `mermaid.md`; move any scripts/ or assets/ the members ship (inspect dirs at execution; keep trees intact).
Consumers: agents/documentation-subagent.md (ascii), agents/startup-founder-subagent.md (mermaid), presets pack-docs + pack-devops (both), tests/test_default_behavior.bats + test_autoresearch_protocol.bats (mermaid literals), README.md.
- [ ] **7.1** Author host + references (+ moved scripts/assets) per template
    — **Why:** one "make a diagram" intent, two rendering variants
    — **Done when:** template satisfied; triggers intact; scripts functional; isolation green
    — **Consumers affected:** documentation-subagent, startup-founder
- [ ] **7.2** Delete + repoint (2 agents, presets, bats literals, README)
    — **Why:** bats pin mermaid name
    — **Done when:** residue clean; affected bats green
    — **Consumers affected:** CI, agents, packs
- [ ] **7.3** Registry + scoped gate + count (142)
    — **Why:** per-commit green
    — **Done when:** count 142
    — **Consumers affected:** installer
- [ ] **7.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 8: civiltekk-ponytail-audit-skill
Absorbs: `ponytail-audit-skill` (host renames) + `ponytail-review-skill` + `ponytail-debt-skill`. references/: `audit.md`, `review.md`, `debt.md`. Routes: whole-repo audit | diff review | debt ledger. `shipsPlugins` edges in dependency-map.json: three entries collapse to one under the new name (same plugin artifacts); `pluginCompanions` unchanged (plugin-keyed).
Consumers: agents/code-review-subagent.md (review), agents/repo-ops-specialist-subagent.md (debt), deploy/skill-profiles.json, tests/test_ships_plugins.bats (pins per-skill shipsPlugins — three assertions become one), README.md.
- [ ] **8.1** Rename + author host + references per template
    — **Why:** one ponytail family, three scopes; mode skill (vendored `ponytail`) is untouched — different directory
    — **Done when:** template satisfied; three trigger sets intact; isolation green
    — **Consumers affected:** code-review, repo-ops agents
- [ ] **8.2** Delete + repoint + collapse shipsPlugins map entries (2 agents, skill-profiles, test_ships_plugins, README)
    — **Why:** dependency-map shipsPlugins pins travel with the rename or `npx add` loses the plugin edge
    — **Done when:** map has one entry; test_ships_plugins green; residue clean
    — **Consumers affected:** installer shipsPlugins path, agents
- [ ] **8.3** Registry + scoped gate + count (140)
    — **Why:** per-commit green
    — **Done when:** count 140 (3 dirs removed)
    — **Consumers affected:** installer
- [ ] **8.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 9: civiltekk-api-spec-skill
Absorbs: `api-design-skill` + `openapi-contract-adherence-skill`. references/: `design.md`, `adherence.md`. Routes: author spec | diff/review contract. §Authoring Quality Gate stays in host method (it is the method).
Consumers: agents/technical-design-specialist-subagent.md, deploy/skill-profiles.json, deploy/.AGENTS.md (skill-not-subagent exception names api-design-skill → cite new name; semantics unchanged), presets pack-business + pack-backend, tests/test_default_behavior.bats + test_help_parity.bats + test_autoresearch_protocol.bats, README.md.
- [ ] **9.1** Author host + references per template
    — **Why:** same artifact (OpenAPI spec), two lifecycle ops (author vs adherence-diff)
    — **Done when:** template satisfied; triggers intact; isolation green
    — **Consumers affected:** technical-design-specialist
- [ ] **9.2** Delete + repoint (specialist agent, skill-profiles, deploy/.AGENTS.md exception line, presets, 3 bats literal sets, README)
    — **Why:** user-level config ships the exception name; bats pin both names
    — **Done when:** residue clean; affected bats green
    — **Consumers affected:** primary sessions (user AGENTS.md), CI, specialist
- [ ] **9.3** Registry + scoped gate + count (139)
    — **Why:** per-commit green
    — **Done when:** count 139
    — **Consumers affected:** installer
- [ ] **9.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 10: civiltekk-react-quality-skill
Absorbs: `react-best-practices-skill` (already has references/ — move tree in) + `react-hooks-antipatterns-skill` + `react-render-antipatterns-skill` + `typescript-dry-principle-skill`. references/: existing best-practices tree + `hooks.md`, `render.md`, `dry.md`. Routes: perf | hooks-antipatterns | render-antipatterns | TS-DRY.
Consumers: agents/language-reviewer-subagent.md + agents/error-resolver-subagent.md + agents/code-review-subagent.md + agents/nextjs-specialist-subagent.md (all four members across these), deploy/skill-profiles.json, presets pack-frontend + pack-review, tests/test_default_behavior.bats + test_autoresearch_protocol.bats (typescript-dry literals), README.md.
- [ ] **10.1** Author host + references per template (4 variants)
    — **Why:** one React/TS quality family, four detection/fix recipes; biggest agent fan-in
    — **Done when:** template satisfied; four trigger sets intact; isolation green
    — **Consumers affected:** 4 reviewer/specialist agents
- [ ] **10.2** Delete + repoint (4 agents' allowlists+bodies, skill-profiles, presets, bats literals, README)
    — **Why:** reviewers allowlist each member by name — all four names must collapse
    — **Done when:** residue clean; affected bats green
    — **Consumers affected:** review lattice, packs, CI
- [ ] **10.3** Registry + scoped gate + count (136)
    — **Why:** per-commit green; 4 dirs removed (139→136 hits the ticket's 136 target early only if Phase-6 arithmetic offset — reconcile running count at gate and record actual)
    — **Done when:** count verified; `bats tests/` for touched files green
    — **Consumers affected:** installer
- [ ] **10.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 11: civiltekk-documentation-inline-skill (isolation-contract touchpoint — last)
Absorbs: `documentation-inline-skill` (host renames) + `docstring-generator-skill`. references/: `docstring-formats.md` (PEP 257/Javadoc/JSDoc/XML tables); host keeps the inline decision-tree method. Routes: inline-docs delegate | docstring-format lookup.
Contract lockstep (same fail-closed unit, one commit): `tests/test_skill_isolation.bats` HANDOFF2_TARGETS renames `documentation-inline-skill` → `civiltekk-documentation-inline-skill`; `installer/dependency-map.json` plan-execution-inline requiresSkills entry renames same (pin test derives from guard — no third copy); `skills/plan-execution-inline-skill/SKILL.md` body references the four inline skills — rename the documentation one; HANDOFF3 (post-#612) untouched.
Consumers: agents/documentation-subagent.md + agents/nextjs-specialist-subagent.md (docstring-generator), plan-execution-inline-skill body, presets pack-docs + pack-frontend (docstring), deploy/skill-profiles.json + opencode.json (documentation-inline primary-visible — check lean array), README.md.
- [ ] **11.1** Rename + author host + fold docstring values into references/
    — **Why:** documentation-inline already owns "docstrings for new/changed symbols"; the generator's format tables are values it lacked
    — **Done when:** template satisfied; both trigger sets intact; isolation green
    — **Consumers affected:** inline delegate family, plan-execution-inline
- [ ] **11.2** Delete + repoint + contract lockstep (HANDOFF2_TARGETS, dependency-map entry, plan-execution-inline body, 2 agents, presets, profiles/opencode.json, README)
    — **Why:** the guard + pin are one fail-closed unit with the map — partial rename turns CI red (same lockstep lesson as #602)
    — **Done when:** `bats tests/test_skill_isolation.bats tests/test_requires_skills.bats` green; residue clean
    — **Consumers affected:** isolation guard, installer, plan-execution-inline routing
- [ ] **11.3** Registry + scoped gate + count (135 — then reconcile: 150−15 dirs if Phase 6/10 arithmetic differed; record the true number, target 136±1 with explanation)
    — **Why:** the ticket AC pins 136; any deviation must be explained in the Done line, never silently absorbed
    — **Done when:** count recorded + reconciled; affected bats green
    — **Consumers affected:** installer
- [ ] **11.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 12: Exit — full suite, final counts, sweep
- [ ] **12.1** Full gate: `bats tests/` (exit 0, zero `not ok`); registry diff committed clean; LEARNINGS count-literal sweep across tests/ deploy/ README.md
    — **Why:** ticket exit gate is tier=full unconditionally
    — **Done when:** suite exit=0; sweep grep clean; `GATE <sha> tier=full` memo appended to Trace
    — **Consumers affected:** PR citation, reviewer
- [ ] **12.2** Verify ticket ACs end-to-end (11 commits on branch, HANDOFF2 cites new name, deploy/.AGENTS.md lines, docstring repoints, triggers preserved, final count)
    — **Why:** AC reconciliation before review
    — **Done when:** every AC checkbox tickable with evidence; tick them
    — **Consumers affected:** reviewer, PR
- [ ] **12.3** Commit PLAN ticks + memo; push
    — **Why:** traceability; final SHA carries tier=full memo
    — **Done when:** pushed; `[goal:evidence]` emitted
    — **Consumers affected:** pipeline Step 9/10

## Technical Notes

- Skill count bookkeeping: 150 at base; M1 −1 (149), M2 −1 (148), M3 −1 (147), M4 −1 (146), M5 −1 (145), M6 −2 (143), M7 −1 (142), M8 −2 (140), M9 −1 (139), M10 −3 (136), M11 −1 (135). Reconcile at each gate — the ticket says 136 (150−14); if actual is 135 the Done line explains (24 members → 11 hosts = −13... verify: members M1..M11 = 2+2+2+2+2+3+2+3+4+2+... count: M1:2, M2:3, M3:2, M4:2, M5:2, M6:3, M7:2, M8:3, M9:2, M10:4, M11:2 = 27? No: Wave 1 = 24 members → 11 hosts = −13; 150−13 = 137, not 136. The ticket's "136 (150-14)" counts the docstring fold as a member (25th) — reconcile honestly at execution and record the true arithmetic in 11.3/12.2 Done lines.)
- `deploy/opencode.json` is the post-#609 impliesMcp target; not touched by Wave 1 (no impliesMcp edges among members).
- Primary-visibility renames (documentation-inline in lean array, zai/others NOT in this wave) — check `deploy/skill-profiles.json` + `opencode.json` per phase and fix literals.
- Delegation: each phase's N.1–N.2 may run in a general-subagent given this PLAN phase block + the pattern template; N.3–N.4 (gate+commit) stay with the orchestrator for memo discipline.
- Rebase hazard: #612 (feat/602) may merge mid-run touching HANDOFF3-adjacent context in the guard/map/pin files — Phase 11 edits those same files; if #612 merges before Phase 11, rebase feat/603 first (union resolution precedent: #602 rebase).

## Dependencies

Held-vs-#612 at 6f: feat/602's open-PR diff intersects this PLAN's touch-set (test_skill_isolation.bats, dependency-map.json, test_requires_skills.bats, AGENTS.md). Auto-resume on #612 merge notification: rebase feat/603 onto updated main, continue at Step 7 (Phase 1 execution).

## Risks & Mitigation

- **Concurrent-merge churn (observed twice: #606, #609)** — rebase discipline at boundaries; 6f hold releases only on merge notification.
- **Count literals trip six-site bats pins** — per-phase sweep + skill_profiles run inside every merge commit (LEARNINGS: skill-dir-consolidation-count-literals).
- **Trigger-phrase loss shrinks discovery** — description union verified per phase against member descriptions before dir deletion (checklist in N.1 Done-when).
- **Phase 11 contract lockstep** — same-commit rule; #602 precedent.
