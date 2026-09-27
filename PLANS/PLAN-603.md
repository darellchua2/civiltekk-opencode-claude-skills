# PLAN: Wave 1 — consolidate 24 skills into 11 civiltekk- hosts

**Branch**: feat/603
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/603
**Base**: main (0549005 — includes #609 Docker removal + #612 HANDOFF3 guard lines; `opencode_app/` gone, sweeps target `README.md` only; `tests/test_skill_isolation.bats` now has HANDOFF3 lines above HANDOFF2 — Phase 11 edits HANDOFF2 only)

## Acceptance Criteria

- [ ] 11 atomic commits `refactor(skills): consolidate X into Y`; counts green per commit
- [ ] HANDOFF2_TARGETS + dependency-map requiresSkills for plan-execution-inline cite civiltekk-documentation-inline-skill
- [ ] deploy/.AGENTS.md granularity + api-design exception lines cite civiltekk- names; repo AGENTS.md doc-sync row updated
- [ ] docstring fold repoints done: documentation-subagent, nextjs-specialist-subagent, pack-docs.json, pack-frontend.json
- [ ] registry.json rebuilt per merge; `bats tests/` green; LEARNINGS count-literal sweep clean
- [ ] All member triggers preserved in host descriptions; skill count = 135 after this wave (150 − 15: 26 members → 11 hosts; AC amended from 136 per Mode R — 136 was the transient Phase-10 ladder value)

## Pattern template (every host follows — ticketing-skill shape)

Host SKILL.md = METHOD only (~≤140 lines): first body line `Consolidates <members> (#603)`; §What I do (numbered route); §Side files table (read/when/use); §Detection: explicit > inferred > ask-once (one ask per run); §Routes (situation → variant); §Boundaries (what belongs elsewhere); §Agent behavior rules; harness-binding block (question tool / AskUserQuestion / plain-reply). `references/<variant>.md` = VALUES only (commands, vocabularies, tables, templates; scripts/assets move intact). Frontmatter: `name` = dir name (`civiltekk-*`, ≤64 chars), `description` = union of ALL member trigger phrases (≤1024 chars), `license: Apache-2.0`, `compatibility: opencode`, `category` inherited from members. Every member's triggers must survive verbatim in the union.

## Standard phase skeleton (each phase = one merge = one commit)

- **N.1** Author host SKILL.md + `references/` (method+values; trigger-union description)
- **N.2** `git rm` absorbed dirs + repoint ALL consumers listed for that merge — ALWAYS including the member's `permissions` skill-allow rules in `deploy/opencode.json` (~25 member edges across phases 1–11; the deny-all-first allowlist silently drops new `civiltekk-*` hosts otherwise — BLOCK-1)
- **N.3** `node installer/build-registry.mjs` + scoped gate (affected bats files + count sweep + `ls -d skills/*/ | wc -l`)
- **N.4** Atomic commit + push (PLAN ticks ride it — no standalone docs commits)

Count sweep per phase (adapted post-#609): `grep -rn 'skill director\|lean has exactly\|deny-ok\|primary-visible\|allows)' tests/ deploy/ README.md` — every literal the decrement touches gets fixed in the SAME commit; PLUS the README per-category parenthetical counts (README.md:260-276, mutated by every phase — WARN-3); PLUS `bats tests/skill_profiles.bats tests/test_select_items.bats tests/test_ships_plugins.bats` (whichever the phase touches) and the phase's other affected test files.

Residue rule (orchestrator constant — issued verbatim to every N.2 delegate): sweep BOTH the full `-skill` name AND its suffix-stripped stem (catches `git-semantic-commits` in README:87, `documentation-sync-workflow` in AGENTS.md:69 — WARN-2). Residue exemptions (never rewrite): `CHANGELOG.md`, `docs/` research snapshots, historical `PLANS/`, `LEARNINGS/`, `installer/registry.json` pre-rebuild. Live-path residue (MUST repoint, not exempt): `plugins/ATTRIBUTION.md` ponytail paths (Phase 8).

## Dependency & Consumer Map

| Node | Depends on | Consumers | Risk |
|------|-----------|-----------|------|
| 11 new `skills/civiltekk-*` dirs | — | agents, presets, installer, registry | med |
| `installer/registry.json` | each merge | installer/init.mjs, presets | low (generated) |
| `tests/test_skill_isolation.bats` (HANDOFF2_TARGETS) | Phase 11 | guard + pin test (derived) | high |
| `installer/dependency-map.json` (requiresSkills entry, shipsPlugins ponytail edge) | Phases 2, 11 | init.mjs, pin test | high |
| `agents/*.md` allowlists+bodies | each merge | subagent routing | med |
| `installer/presets/pack-*.json` | each merge | installer packs | med |
| `deploy/skill-profiles.json`, `deploy/opencode.json`, `opencode.json` | every phase (profiles; ~25 member allow rules in deploy/opencode.json:70-565) | primary visibility + routing | med |
| `deploy/.AGENTS.md` | Phases 2 (granularity line :53), 9 (api-design exception :9) | user-level deployed config | med |
| `AGENTS.md` (repo) | Phase 4 (doc-sync row) | agents | low |
| `README.md`, `deploy/setup.sh`, `deploy/setup.ps1` | every phase | counts/banners | low |

## Implementation Phases

### Phase 1: civiltekk-opencode-creation-skill (smallest risk — warm-up)
Absorbs: `opencode-agent-creation-skill` (11.4K) + `opencode-skill-creation-skill`. references/: `agent.md`, `skill.md`.
Consumers: agents/opencode-tooling-subagent.md (allowlist + body), deploy/skill-profiles.json, deploy/opencode.json (both members' allow rules), README.md. (pack-core holds no creation-skill — its member hit is git-semantic, Phase 2's.)
- [x] **1.1** Author host + references per template (shared frontmatter-contract knowledge is the shared method; per-artifact values split by variant)
    — **Why:** biggest body (agent-creation 11.4K) is mostly per-artifact values — the split is the token win
    — **Done when:** host ≤140 lines; both members' triggers present in description; `bats tests/test_skill_isolation.bats` green (new dir self-contained)
    — **Consumers affected:** opencode-tooling-subagent routing
    — **Done:** host 79 lines, union description 310 chars, metadata.harness preserved, category OpenCode Meta; files: skills/civiltekk-opencode-creation-skill/{SKILL.md, references/agent.md, references/skill.md}; fixes: none
- [x] **1.2** Delete absorbed dirs + repoint: tooling-subagent allowlist/body, skill-profiles, pack-core/pack-devops entries, README table
    — **Why:** stale names break agent routing + installer packs
    — **Done when:** `grep -rn 'opencode-agent-creation-skill\|opencode-skill-creation-skill' --exclude-dir=.git .` returns only registry.json (pre-rebuild), historical PLANS/LEARNINGS
    — **Consumers affected:** opencode-tooling-subagent, installer packs
    — **Done:** 2 dirs git-rm'd; repointed: opencode-tooling-subagent (2 allows→1), skill-profiles (lean 78→77), deploy/opencode.json (2 rules→1), README (150→149 ×6 sites + category row), setup.sh, skills-maintainer + agent-introspection fellow-refs (WARN-5 net worked); residue = template-mandated Consolidates line + registry + historical only; fixes: none
- [x] **1.3** Registry rebuild + scoped gate + count check (149)
    — **Why:** registry is installer input; counts must stay green per commit
    — **Done when:** `node installer/build-registry.mjs` clean diff (only expected entries); affected bats green; sweep clean; count 149
    — **Consumers affected:** installer/init.mjs
    — **Done:** registry rebuilt (agents=34, skills=149); scoped gate 123/123 green; fixes: skill_profiles lean literals 78→77 at all six pin sites (fix #1); count 149 verified
- [x] **1.4** Commit `refactor(skills): consolidate opencode creation skills into civiltekk-opencode-creation-skill` + push
    — **Why:** atomic, reversible merge unit; PLAN ticks ride it
    — **Done when:** pushed; `git log -1` shows phase files + PLAN in one commit
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a. (this step)

### Phase 2: civiltekk-git-commits-skill
Absorbs: `git-semantic-commits-skill` + `git-compact-commits-skill`. references/: `semantic.md`, `compact.md`. Routes: conventional-format | brevity-budget (descriptions already cross-reference as alternatives).
Consumers: deploy/skill-profiles.json, deploy/.AGENTS.md (§Commits "Granularity: git-semantic-commits-skill" line → new name), installer/presets/pack-core.json + pack-devops.json + pack-inline-workers.json, tests/test_select_items.bats.
- [x] **2.1** Author host + references per template
    — **Why:** two commit-style skills are one method (write a commit) with two style variants
    — **Done when:** host routes both; triggers union intact; isolation bats green
    — **Consumers affected:** AGENTS.md §Commits readers
    — **Done:** host 78 lines, routes conventional-format|brevity-budget, mutual boundary refs absorbed; files: skills/civiltekk-git-commits-skill/{SKILL.md,references/semantic.md,references/compact.md}; fixes: none
- [x] **2.2** Delete + repoint (skill-profiles, deploy/.AGENTS.md granularity line, 3 presets, test_select_items literals)
    — **Why:** deploy/.AGENTS.md ships to user-level config — stale name misdirects the primary session
    — **Done when:** grep residue clean (same rule as 1.2); test_select_items green
    — **Consumers affected:** primary-session commit behavior, packs
    — **Done:** 2 dirs git-rm; repointed: skill-profiles (77→76), deploy/opencode.json, deploy/.AGENTS.md granularity line, 3 presets, test_select_items, README (149→148 ×6 + category row), setup.sh lean comment, 6 fellow-skills (changelog-cliff, plan-execution x2, semantic-release, verification-loop, version-bump); residue exempt-only; fixes: none
- [x] **2.3** Registry + scoped gate + count (148)
    — **Why:** per-commit green discipline
    — **Done when:** same shape as 1.3 with count 148
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=148); scoped gate 123/123 green first run; count 148; fixes: none
- [x] **2.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed single commit
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 3: civiltekk-context-optimization-skill
Absorbs: `context-budget-skill` (10.1K) + `strategic-compact-skill`. references/: `budget.md`, `compact.md`. Routes: audit-overhead | compaction-strategy.
Consumers: agents/autoresearch-{code,ml,research}-subagent.md (strategic-compact), agents/loop-operator-subagent.md, deploy/skill-profiles.json, presets pack-frontend/pack-business/pack-review (context-budget) + pack-research (strategic-compact).
- [x] **3.1** Author host + references per template
    — **Why:** both are token-economy method skills; one audit route, one strategy route
    — **Done when:** template satisfied; triggers intact; isolation green
    — **Consumers affected:** autoresearch agents, loop-operator
    — **Done:** host mirrors pattern shape, routes audit-overhead|compaction-strategy, 455-char union description (12 trigger phrases), category Agent Optimization; files: skills/civiltekk-context-optimization-skill/{SKILL.md,references/budget.md,references/compact.md}; fixes: none
- [x] **3.2** Delete + repoint (4 agent files, skill-profiles, 4 presets)
    — **Why:** autoresearch agents allowlist strategic-compact by name
    — **Done when:** grep residue clean
    — **Consumers affected:** autoresearch loops, packs
    — **Done:** 2 dirs git-rm; repointed: skill-profiles (76→75 + six bats literals), deploy/opencode.json, setup.sh lean comment, 4 presets, 4 agents (autoresearch x3 + loop-operator), README counts+rows, 6 fellow-skills; residue exempt-only; fixes: none
- [x] **3.3** Registry + scoped gate + count (147)
    — **Why:** per-commit green
    — **Done when:** same shape; count 147
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=147); scoped gate green; count 147; fixes: none
- [x] **3.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 4: civiltekk-documentation-sync-skill
Absorbs: `documentation-sync-workflow-skill` + `documentation-consistency-skill`. references/: `sync-on-add.md`, `drift-audit.md`. Routes: on-add sync | drift audit/fix.
Consumers: agents/repo-ops-specialist-subagent.md, agents/opencode-tooling-subagent.md, agents/opencode-v2-migration-subagent.md, deploy/skill-profiles.json, deploy/opencode.json (both members' allow rules), presets pack-devops (both), tests/test_default_behavior.bats + test_autoresearch_protocol.bats (consistency literals), README.md (incl. category-table rows — host lands in **OpenCode Meta**, per Mode R; remove the Documentation-row member entry), repo `AGENTS.md` (sync-rules row names documentation-sync-workflow).
- [ ] **4.1** Author host + references per template
    — **Why:** same object (docs counts/drift), two situations (adding vs auditing)
    — **Done when:** template satisfied; triggers intact; isolation green
    — **Consumers affected:** repo-ops, tooling agents
- [ ] **4.2** Delete + repoint (3 agents, skill-profiles, presets, 2 bats literal sets, README, AGENTS.md row)
    — **Why:** bats pin member names — literals must move with the merge
    — **Done when:** residue clean; test_default_behavior + test_autoresearch_protocol green
    — **Consumers affected:** CI, agents
- [x] **4.3** Registry + scoped gate + count (146)
    — **Why:** per-commit green
    — **Done when:** count 146; affected bats green
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=146); scoped gate green incl. default_behavior+autoresearch_protocol pinned literals; count 146; fixes: none
- [x] **4.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 5: civiltekk-startup-docs-skill
Absorbs: `startup-business-docs-skill` + `startup-pitch-deck-skill`. references/: `business-docs.md`, `pitch-deck.md`. Routes: business docs | pitch decks.
Consumers: agents/startup-founder-subagent.md (both), agents/startup-ceo-subagent.md (pitch-deck), presets pack-docs (pitch-deck) + pack-business (both), README.md.
- [x] **5.1** Author host + references per template
    — **Why:** one startup-docs family, two deliverable variants; same subagent pair consumes
    — **Done when:** template satisfied; triggers intact; isolation green
    — **Consumers affected:** startup agents
    — **Done:** routes business-docs|pitch-decks, 530-char union description, category Startup/Business (both members matched); files: skills/civiltekk-startup-docs-skill/{SKILL.md,references/business-docs.md,references/pitch-deck.md}; fixes: none
- [x] **5.2** Delete + repoint (2 agents, presets, README)
    — **Why:** agents allowlist members by name
    — **Done when:** residue clean
    — **Consumers affected:** startup agents, packs
    — **Done:** 2 dirs git-rm; repointed: opencode.json, 2 agents, 2 presets, README (145 counts, category row 3->2); lean untouched (neither member was lean — 74 stays); zero fellow-skill hits; residue exempt-only; fixes: none
- [x] **5.3** Registry + scoped gate + count (145)
    — **Why:** per-commit green
    — **Done when:** count 145
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=145); preset diff verified = member->host swaps only; scoped gate green; count 145; fixes: none
- [x] **5.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 6: civiltekk-python-backend-skill
Absorbs: `python-backend-skill` (host renames) + `python-packaging-skill` + `fastapi-pydantic-orm-patterns-skill`. references/: `scaffold.md`, `packaging.md`, `fastapi-orm.md`. Routes: scaffold | package | patterns.
Consumers: agents/language-reviewer-subagent.md (packaging + fastapi), deploy/skill-profiles.json, presets pack-review + pack-backend, README.md.
- [x] **6.1** Rename dir + author host + references per template (host body is the scaffold method)
    — **Why:** scaffold method already exists — it absorbs the other two as routes
    — **Done when:** template satisfied; all three trigger sets intact; isolation green
    — **Consumers affected:** language-reviewer
    — **Done:** git mv preserved history; routes scaffold|packaging|patterns; 408-char 3-way union description, category Language-Specific; files: skills/civiltekk-python-backend-skill/{SKILL.md,references/scaffold.md,references/packaging.md,references/fastapi-orm.md}; fixes: none
- [x] **6.2** Delete absorbed + repoint (language-reviewer allowlist/body, skill-profiles, presets, README)
    — **Why:** stale names break reviewer routing
    — **Done when:** residue clean (python-backend-skill old name included)
    — **Consumers affected:** language-reviewer, packs
    — **Done:** 2 dirs git-rm (net -2 dirs); repointed: skill-profiles (3 lean entries -> 1, 74->72 — deviation from PLAN estimate 73, all three were lean), six bats literals, setup.sh, opencode.json (3 rules -> 1), language-reviewer + architecture-review agents, 2 presets, README (143 counts, Language-Specific 6->4), 4 fellow-skills; residue exempt-only; fixes: none
- [x] **6.3** Registry + scoped gate + count (143)
    — **Why:** per-commit green (3 dirs removed: 145→143... running total corrected at gate)
    — **Done when:** count 143; affected bats green
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=143); scoped gate green; count 143 (PLAN said 143 — matches); fixes: none
- [x] **6.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 7: civiltekk-diagram-skill
Absorbs: `ascii-diagram-creator-skill` + `mermaid-diagram-creator-skill`. references/: `ascii.md`, `mermaid.md`; move any scripts/ or assets/ the members ship (inspect dirs at execution; keep trees intact).
Consumers: agents/documentation-subagent.md (ascii), agents/startup-founder-subagent.md (mermaid), presets pack-docs + pack-devops (both), tests/test_default_behavior.bats + test_autoresearch_protocol.bats (mermaid literals), README.md.
- [x] **7.1** Author host + references (+ moved scripts/assets) per template
    — **Why:** one "make a diagram" intent, two rendering variants
    — **Done when:** template satisfied; triggers intact; scripts functional; isolation green
    — **Consumers affected:** documentation-subagent, startup-founder
    — **Done:** routes ascii|mermaid, trigger-union description, category Git/Workflow (both members), protocol metadata preserved, bats-pinned literals carried once; members had no scripts/assets; files: skills/civiltekk-diagram-skill/{SKILL.md,references/ascii.md,references/mermaid.md}; fixes: none
- [x] **7.2** Delete + repoint (2 agents, presets, bats literals, README)
    — **Why:** bats pin mermaid name
    — **Done when:** residue clean; affected bats green
    — **Consumers affected:** CI, agents, packs
    — **Done:** 2 dirs git-rm; 10 files repointed: skill-profiles (mermaid lean slot -> host, lean stays 72), opencode.json, 2 agents, 2 presets, 2 bats literal sets (7 each), horseshoe fellow-ref, README (142 counts, Git/Workflow 13->12); residue exempt-only; fixes: none
- [x] **7.3** Registry + scoped gate + count (142)
    — **Why:** per-commit green
    — **Done when:** count 142
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=142); scoped gate green; count 142; fixes: none
- [x] **7.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 8: civiltekk-ponytail-audit-skill
Absorbs: `ponytail-audit-skill` (host renames) + `ponytail-review-skill` + `ponytail-debt-skill`. references/: `audit.md`, `review.md`, `debt.md`. Routes: whole-repo audit | diff review | debt ledger. `shipsPlugins` edges in dependency-map.json: three entries collapse to one under the new name (same plugin artifacts); `pluginCompanions` unchanged (plugin-keyed).
Consumers: agents/code-review-subagent.md (review), agents/architecture-review-subagent.md (ponytail-audit allow), agents/repo-ops-specialist-subagent.md (debt), deploy/skill-profiles.json, deploy/opencode.json (trio's allow rules), tests/test_ships_plugins.bats (~15 invocation lines across ~10 tests pin the three names), plugins/ATTRIBUTION.md:36-40 (LIVE relative paths `../skills/ponytail-*-skill/SKILL.md` — repoint, not exempt), README.md.
- [x] **8.1** Rename + author host + references per template
    — **Why:** one ponytail family, three scopes; mode skill (vendored `ponytail`) is untouched — different directory
    — **Done when:** template satisfied; three trigger sets intact; isolation green
    — **Consumers affected:** code-review, repo-ops agents
    — **Done:** git mv preserved history; routes whole-repo-audit|diff-review|debt-ledger; 9-phrase union description; vendored v4.10.0 attribution retained; files: skills/civiltekk-ponytail-audit-skill/{SKILL.md,references/audit.md,references/review.md,references/debt.md}; fixes: none
- [x] **8.2** Delete + repoint + collapse shipsPlugins map entries (2 agents, skill-profiles, test_ships_plugins, README)
    — **Why:** dependency-map shipsPlugins pins travel with the rename or `npx add` loses the plugin edge
    — **Done when:** map has one entry; test_ships_plugins green; residue clean
    — **Consumers affected:** installer shipsPlugins path, agents
    — **Done:** 2 dirs git-rm (net -2); shipsPlugins 3->1 in dependency-map; ATTRIBUTION live paths repointed to host; test_ships_plugins ~15 literals -> host (intent kept); 3 agents + architecture-review allow; skill-profiles lean 72->70 + six bats literals; opencode.json 3->1; README 142->140 (Code Quality 16->14); setup.sh; fixes: none
- [x] **8.3** Registry + scoped gate + count (140)
    — **Why:** per-commit green
    — **Done when:** count 140 (3 dirs removed)
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=140); scoped gate green incl. ships_plugins + ponytail_plugin + requires_skills + isolation; count 140; fixes: none
- [x] **8.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 9: civiltekk-api-spec-skill
Absorbs: `api-design-skill` + `openapi-contract-adherence-skill`. references/: `design.md`, `adherence.md`. Routes: author spec | diff/review contract. §Authoring Quality Gate stays in host method (it is the method).
Consumers: agents/technical-design-specialist-subagent.md, deploy/skill-profiles.json, deploy/opencode.json (pair's allow rules), deploy/.AGENTS.md (skill-not-subagent exception names api-design-skill → cite new name; semantics unchanged), presets pack-business + pack-backend, tests/test_default_behavior.bats + test_autoresearch_protocol.bats, **lockstep pair (BLOCK-3): `installer/init.mjs:1826` usage example string ↔ `tests/test_help_parity.bats:36` grep -F pin — rename rides BOTH in this commit**, installer/templates/api-quality/README.md:4 (shipped template cites the api-design gate), README.md.
- [x] **9.1** Author host + references per template
    — **Why:** same artifact (OpenAPI spec), two lifecycle ops (author vs adherence-diff)
    — **Done when:** template satisfied; triggers intact; isolation green
    — **Consumers affected:** technical-design-specialist
    — **Done:** routes author|adherence; Authoring Quality Gate method in host; 2 fellow-skills repointed (authn-authz, technical-design-creation); files: skills/civiltekk-api-spec-skill/{SKILL.md,references/design.md,references/adherence.md}; fixes: none
- [x] **9.2** Delete + repoint (specialist agent, skill-profiles, deploy/.AGENTS.md exception line, presets, 3 bats literal sets, README)
    — **Why:** user-level config ships the exception name; bats pin both names
    — **Done when:** residue clean; affected bats green
    — **Consumers affected:** primary sessions (user AGENTS.md), CI, specialist
    — **Done:** 2 dirs git-rm; 16 files repointed: init.mjs:1826 + help-parity pin (lockstep pair, both edited), api-quality template, deploy/.AGENTS.md:9 exception line, specialist agent allowlist, skill-profiles lean 70->69 + six literals, opencode.json, 2 presets, 2 bats literal sets, README 140->139 (+fixed stale 142 header drift from phase 7), setup.sh; residue exempt-only; fixes: none
- [x] **9.3** Registry + scoped gate + count (139)
    — **Why:** per-commit green
    — **Done when:** count 139
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=139); scoped gate green incl. help-parity lockstep; count 139; fixes: none
- [x] **9.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 10: civiltekk-react-quality-skill
Absorbs: `react-best-practices-skill` (already has references/ — move tree in) + `react-hooks-antipatterns-skill` + `react-render-antipatterns-skill` + `typescript-dry-principle-skill`. references/: existing best-practices tree + `hooks.md`, `render.md`, `dry.md`. Routes: perf | hooks-antipatterns | render-antipatterns | TS-DRY.
Consumers: agents/language-reviewer-subagent.md + agents/error-resolver-subagent.md + agents/code-review-subagent.md + agents/nextjs-specialist-subagent.md (all four members across these), deploy/skill-profiles.json, presets pack-frontend + pack-review, tests/test_default_behavior.bats + test_autoresearch_protocol.bats (typescript-dry literals), README.md.
- [x] **10.1** Author host + references per template (4 variants)
    — **Why:** one React/TS quality family, four detection/fix recipes; biggest agent fan-in
    — **Done when:** template satisfied; four trigger sets intact; isolation green
    — **Consumers affected:** 4 reviewer/specialist agents
    — **Done:** routes perf|hooks-antipatterns|render-antipatterns|ts-dry; best-practices references tree moved byte-identical (1 catalog self-ref line); 4-way trigger union; files: skills/civiltekk-react-quality-skill/{SKILL.md,references/perf/,references/hooks.md,references/render.md,references/dry.md}; fixes: none
- [x] **10.2** Delete + repoint (4 agents' allowlists+bodies, skill-profiles, presets, bats literals, README)
    — **Why:** reviewers allowlist each member by name — all four names must collapse
    — **Done when:** residue clean; affected bats green
    — **Consumers affected:** review lattice, packs, CI
    — **Done:** 4 dirs git-rm; 17 files repointed: 4 agents (allowlists+bodies with per-route annotations), skill-profiles lean 69->67 + six literals (deduped double-add caught in-verification), opencode.json 4->1, 2 presets, 2 bats literal sets, README 139->136 (Framework-Specific 11->8), setup.sh; residue exempt-only; fixes: none
- [x] **10.3** Registry + scoped gate + count (136)
    — **Why:** per-commit green; 4 dirs removed (139→136 hits the ticket's 136 target early only if Phase-6 arithmetic offset — reconcile running count at gate and record actual)
    — **Done when:** count verified; `bats tests/` for touched files green
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=136); scoped gate green incl. isolation; count 136 (ladder matches); fixes: none
- [x] **10.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 11: civiltekk-documentation-inline-skill (isolation-contract touchpoint — last)
Absorbs: `documentation-inline-skill` (host renames) + `docstring-generator-skill`. references/: `docstring-formats.md` (PEP 257/Javadoc/JSDoc/XML tables); host keeps the inline decision-tree method. Routes: inline-docs delegate | docstring-format lookup.
Contract lockstep (same fail-closed unit, one commit): `tests/test_skill_isolation.bats` HANDOFF2_TARGETS renames `documentation-inline-skill` → `civiltekk-documentation-inline-skill`; `installer/dependency-map.json` plan-execution-inline requiresSkills entry renames same (pin test derives from guard — no third copy); `skills/plan-execution-inline-skill/SKILL.md` body references the four inline skills — rename the documentation one; HANDOFF3 (post-#612) untouched.
Consumers: agents/documentation-subagent.md + agents/nextjs-specialist-subagent.md (docstring-generator), plan-execution-inline-skill body, presets pack-docs + pack-frontend (docstring) **+ pack-inline-workers.json (documentation-inline entry — BLOCK-2)**, deploy/skill-profiles.json + deploy/opencode.json + opencode.json (documentation-inline allow rules), README.md. **Lockstep prose mirror (Mode R Q3): repo `AGENTS.md` §Skill Isolation Contract brace-shorthand `{testing,linting,documentation,responsive-audit}-inline-skill` at AGENTS.md:22 rewords in this same commit — grep-invisible, checklist-enforced.**
- [x] **11.1** Rename + author host + fold docstring values into references/
    — **Why:** documentation-inline already owns "docstrings for new/changed symbols"; the generator's format tables are values it lacked
    — **Done when:** template satisfied; both trigger sets intact; isolation green
    — **Consumers affected:** inline delegate family, plan-execution-inline
    — **Done:** git mv preserved history; inline METHOD kept (decision tree, scope bounds, enforcement deltas, output contract) + new docstring-formats route; dead house-reference line dropped (cited nonexistent skills); files: skills/civiltekk-documentation-inline-skill/{SKILL.md,references/docstring-formats.md}; fixes: none
- [x] **11.2** Delete + repoint + contract lockstep (HANDOFF2_TARGETS, dependency-map entry, plan-execution-inline body, 2 agents, presets, profiles/opencode.json, README)
    — **Why:** the guard + pin are one fail-closed unit with the map — partial rename turns CI red (same lockstep lesson as #602)
    — **Done when:** `bats tests/test_skill_isolation.bats tests/test_requires_skills.bats` green; residue clean
    — **Consumers affected:** isolation guard, installer, plan-execution-inline routing
    — **Done:** all four lockstep surfaces together: guard HANDOFF2_TARGETS, dependency-map plan-execution-inline entry, plan-execution-inline SKILL.md x3, AGENTS.md:22 brace-shorthand reword; + 3 agents, 3 presets, skill-profiles (lean stays 67), deploy/opencode.json, README 136->135, 1 fellow-skill; docstring dir git-rm; residue exempt-only; fixes: none
- [x] **11.3** Registry + scoped gate + count (135 — then reconcile: 150−15 dirs if Phase 6/10 arithmetic differed; record the true number, target 136±1 with explanation)
    — **Why:** the ticket AC pins 136; any deviation must be explained in the Done line, never silently absorbed
    — **Done when:** count recorded + reconciled; affected bats green
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=135); scoped gate green incl. isolation + requires_skills lockstep; count 135 = amended AC target (was 136 pre-Mode-R); fixes: none
- [x] **11.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

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

- **Count arithmetic (definitive, arch-review + Mode R verified): 26 members → 11 hosts = −15 → 135.** The ticket's original "136 (150−14)" was the transient Phase-10 ladder value; ticket AC amended to 135 and #604's to 118 (135−17) pre-execution. Ladder: 149·148·147·146·145·143·142·140·139·136·135.
- ~20 fellow-skill cross-references (agent-introspection, skills-maintainer, search-first, eval-harness, grilling, plan-execution, semantic-release, version-bump, database-migration, nextjs-standard-setup, technical-design-creation, authn-authz, monorepo, horseshoe, language-review-checklists, uiux-review, frontend-design, amplify, complexity) name Wave-1 members — all suffixed, all residue-grep-catchable; no per-phase enumeration, the sweep is the net (WARN-5).
- Delegation: each phase's N.1–N.2 may run in a general-subagent given this PLAN phase block + the pattern template + the residue-rule constant (skeleton §Residue rule — issue verbatim, subagents never improvise carve-outs); N.3–N.4 (gate+commit) stay with the orchestrator for memo discipline.
- `deploy/opencode.json` `permissions` allow rules are a per-phase repoint surface (deny-all-first: missing allow = invisible skill) — folded into N.2 and every phase's consumer list.
- Rebase hazard: concurrent main churn (observed #606, #609, #612) — rebase at boundaries; Phase 11 shares files with recently-landed HANDOFF3 context (union-resolution precedent from #602's rebase).

## Dependencies

None active. (The pre-#612 overlap hold is resolved — feat/602 merged as 0549005 and feat/603 was rebased onto it before PLAN commit.) Phases are ordered risk-ascending; Phase 11 (isolation-contract lockstep) intentionally last.

## Risks & Mitigation

- **Concurrent-merge churn (observed twice: #606, #609)** — rebase discipline at boundaries; 6f hold releases only on merge notification.
- **Count literals trip six-site bats pins** — per-phase sweep + skill_profiles run inside every merge commit (LEARNINGS: skill-dir-consolidation-count-literals).
- **Trigger-phrase loss shrinks discovery** — description union verified per phase against member descriptions before dir deletion (checklist in N.1 Done-when).
- **Phase 11 contract lockstep** — same-commit rule; #602 precedent.

## Trace

WORK LOG — Phase 1: lean literal fix (78→77, six sites in tests/skill_profiles.bats) caught by the scoped gate on first run — the count-literal LEARNINGS recurring as predicted; WARN-5 sweep-net caught two unlisted fellow-skill consumers (skills-maintainer, agent-introspection). Template-mandated `Consolidates … (#603)` line is standing accepted residue for every host (ticketing-skill #599 precedent).
GATE eeb509f tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 13837af tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE cde8214 tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 135a641 tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 9d8174a tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 4f1ca75 tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE e1174fd tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 15dbf7e tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE eeeccb4 tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 18c988c tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 41ef666 tier=light lint=- typecheck=- build=- unit=t e2e=n.a
