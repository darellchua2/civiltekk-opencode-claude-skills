# PLAN: A/B harness — /review-arch pilot + inline skill family

**Branch**: feat/582
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/582
**Base**: main
**Rev**: 3 — folds re-review amendments (N1 shipped commands model-free + project-overlay A/B model parity; N2 setup.sh --yes; N3 listing check deferred to 4.1; N4 full literal enumeration; commands-model LEARNINGS candidate)

## Acceptance Criteria
- [ ] `/review-arch` and `/review-inline` exist in the global commands block and run the same review target
- [ ] Four `*-inline-skill` dirs exist: self-contained, frontmatter contract conformant (`name` = dir, `license`, `compatibility`, `metadata`, `category`), dependency closure carried by the preset (no new `requiresSkills` handoffs)
- [ ] `/run-plan-v2` completes a small PLAN end-to-end with zero Task/subagent calls
- [ ] `pack-experiment` preset installs the family opt-in; default `setup.sh` deploy unchanged except the additive command entries + skill-allow rules
- [ ] `build-registry.mjs` + `registry.json` rebuilt; count/literal surfaces synced (`skill_profiles.bats`, `init.bats`, `README.md`, `opencode_app/README.md`)
- [ ] A/B numbers recorded in this issue (tokens incl. child sessions, wall time, context growth, findings per variant, resolved model per arm) with a keep/park decision per variant (park = remove that variant's command entry in a follow-up commit)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/{testing,linting,documentation,responsive-audit}-inline-skill/SKILL.md` (4 new, `category: experiment`) | — | `/run-plan-v2` substitution map (2.2), `pack-experiment` preset (3.1), lean profile + shipped allows (3.2), registry rebuild (3.3) | medium |
| `installer/presets/pack-experiment.json` (8-skill closure: 4 inline + 4 knowledge deps) | skill dirs (1.x) | `--preset experiment` flow; `tests/init.bats:56-59` preset-count literal (9→10) | low |
| `opencode_app/opencode.json` `commands` block (+3 entries) + `permissions` array (+4 skill allows) | skill dirs (1.x) for the allows' dead-allow guard | opencode runtime command surface; `skill_profiles.bats:54-61` (lean ⊆ shipped allows); A/B arms (4.2) | high |
| `deploy/skill-profiles.json` (lean +4) | skill dirs (1.x) | `apply-skill-profile.mjs`; `tests/skill_profiles.bats:44,105` (72→76 count literals) | low |
| `installer/registry.json` (rebuild 149→153) | skill dirs (1.x) | installer listing; `README.md:247` + `opencode_app/README.md:26` counts; README category table | low |
| Issue #582 A/B comment | Phase 4 runs | ticket AC 6; keep/park decision | low |

## Implementation Phases

### Phase 1: inline skill family (4 self-contained skills)
- [ ] **1.1** Create `skills/testing-inline-skill/SKILL.md`: thin decision tree for running the testing delegate's workflow in-session — role skip rules (pure-data/trivial exemptions, test-inviable stacks), scope bounds (only files in the current diff), output contract mirroring testing-subagent's report shape, and an **Enforcement deltas** section translating the subagent's REAL isolation (fresh context window, permission sandbox, deploy-tier model — all four family members carry `edit: '*' allow`, so edit isolation is NOT the delta) into explicit advisory discipline (announce scope before writing tests, confine writes to test files, self-report budget); frontmatter per contract (`name` = dir, `description` ≤1024 with triggers, `license: Apache-2.0`, `compatibility: opencode`, `metadata`, `category: experiment`)
    — **Why:** First family member establishes the inline-skill template the other three clone
    — **Done when:** Dir + SKILL.md exist, frontmatter contract-conformant incl. `category`, decision tree covers skip/scope/output, Enforcement deltas name fresh-context/sandbox/tier
    — **Consumers affected:** `/run-plan-v2` (2.2), preset (3.1), allows+lean (3.2), registry (3.3)
- [ ] **1.2** Create `skills/linting-inline-skill/SKILL.md`: in-session linting delegate — language linter discovery, scoped-lint rule (only touched files), gate semantics deferring to `verification-loop-skill`, Enforcement deltas (fresh context + sandbox → in-session: fixes applied directly but reported per-file), output contract
    — **Why:** Highest-frequency /run-plan delegate — its inline form carries the most A/B weight
    — **Done when:** Dir + SKILL.md contract-conformant
    — **Consumers affected:** same as 1.1
- [ ] **1.3** Create `skills/documentation-inline-skill/SKILL.md`: in-session docstring/docs delegate — PEP 257/JSDoc/XML per-language pointers via `technical-writing-skill`, skip rules (pure-data, trivial), scope bounds (new/changed symbols only), output contract
    — **Why:** Third standard /run-plan delegate
    — **Done when:** Dir + SKILL.md contract-conformant
    — **Consumers affected:** same as 1.1
- [ ] **1.4** Create `skills/responsive-audit-inline-skill/SKILL.md`: in-session responsive audit delegate — wraps the `playwright-responsive-audit-skill` inline loop (detect→fix→re-verify tiers) with skip rules (no Playwright config → note + skip, never install unprompted) and output contract
    — **Why:** Completes the delegation-substitution map; the subagent's background/timeout model needs an explicit inline translation
    — **Done when:** Dir + SKILL.md contract-conformant
    — **Consumers affected:** same as 1.1
- [ ] **1.5** Isolation-contract verification (C1): NO `requiresSkills` edges are added to `installer/dependency-map.json` — the inline family's dependency closure rides the preset member list (3.1) because `test_requires_skills.bats:74-76` asserts the map's requiresSkills shape EXACTLY (single declared handoff per #437); verify the guard file is untouched and prose deferral (naming knowledge skills in skill bodies) is isolation-legal
    — **Why:** Review Critical 1 — four new edges would fail the exact-map guard and force a #437 enforcement redesign; preset membership carries no such invariant (review-recommended resolution, adopted)
    — **Done when:** `dependency-map.json` diff-free; `test_requires_skills.bats` + `test_skill_isolation.bats` green in 5.1
    — **Consumers affected:** #437 packaging contract; 3.1's closure

### Phase 2: command surfaces
- [ ] **2.1** Add `/review-arch` and `/review-inline` to the `opencode_app/opencode.json` `commands` block: identical review-prompt template (target arg → severity-gated review per `reviewer-baseline-skill`), both **model-free** (a provider-qualified `model:` in the shipped block is provider-locked across `--provider` swaps — the deploy-time resolver's blast radius is agent .md files + built-in agent blocks only, review N1); `/review-arch` sets `agent: architecture-review-subagent` + `subagent: true` (child session per its `mode: subagent`); `/review-inline` sets `subagent: false` (in-session) and its template instructs reading the deployed `~/.config/opencode/agents/architecture-review-subagent.md` as the in-session checklist (single knowledge source — the referenced `architecture-review-skill` does not exist and must not be created, review M2/RG3)
    — **Why:** AC 1 + review M2/RG3/N1 — both arms run the same target with the same knowledge source, differing only in execution isolation; shipped config stays provider-agnostic
    — **Done when:** Both entries in the commands block, model-free, with explicit `subagent:` values; JSON parses
    — **Consumers affected:** opencode runtime command surface (incl. provider-swap users — commands must survive `--provider` changes); A/B (4.2)
- [ ] **2.2** Add `/run-plan-v2` to the commands block: wraps unmodified `plan-execution-skill` with an explicit delegation-substitution map in the template (testing → `testing-inline-skill`, linting → `linting-inline-skill`, documentation → `documentation-inline-skill`, responsive-audit → `responsive-audit-inline-skill` inline loop) and a hard "zero Task/subagent calls" instruction
    — **Why:** AC 3 — the inline execution path must be a single command, not a remembered convention
    — **Done when:** Entry present; template carries the full substitution map and the zero-Task instruction
    — **Consumers affected:** A/B trial (4.3); plan-execution skill (unmodified — verified)

### Phase 3: packaging
- [ ] **3.1** Create `installer/presets/pack-experiment.json` in the exact `pack-*.json` shape with the **8-skill dependency closure** (4 inline + `language-linting-skill`, `verification-loop-skill`, `technical-writing-skill`, `playwright-responsive-audit-skill`), no agents; hand-authored with a `$comment` noting the registry generator (`/tmp/gen-presets.mjs`) is not in-repo so this preset is hand-maintained; update `tests/init.bats:56-59` preset-count literal 9→10
    — **Why:** AC 4 opt-in + C1 resolution — the closure rides preset membership, not requiresSkills edges
    — **Done when:** `--expand experiment` resolves all 8 skills; init.bats preset-count test green
    — **Consumers affected:** installer preset flow; AC 4
- [ ] **3.2** Make the family loadable and profile-consistent: add 4 `{"action":"skill","resource":"<inline-skill>","effect":"allow"}` rules to the `opencode_app/opencode.json` `permissions` array (C2 — deny-all-first makes the primary blind to them otherwise); add the 4 inline skills to `deploy/skill-profiles.json` `lean` array; update the `skill_profiles.bats` count literals 72→76 (:44, :105)
    — **Why:** Review Critical 2 — without shipped allows the inline arm of the A/B cannot run at all; the lean ⊆ shipped-allows guard requires both surfaces
    — **Done when:** `skill_profiles.bats` green; live-listing verification deferred to 4.1 (the running session reads the deployed config, which redeploys in 4.1)
    — **Consumers affected:** opencode runtime; deploy profiles; AC 3/4
- [ ] **3.3** Run `node installer/build-registry.mjs`; commit `registry.json` with the 4 new entries (149→153); sync the count/literal surfaces: `README.md:247` (149→153, lean 72→76), `opencode_app/README.md:26` (149→153), README category table (new `experiment` rows)
    — **Why:** AC 5 + review M1 — the real pinned surfaces, enumerated from the actual literals (setup.sh/ps1 counts are dynamic; only verify no stale comment)
    — **Done when:** Registry 153; all listed literals updated PLUS the full enumeration — README.md:5, :72, :106, :247, :286 (every "149"/lean-72 site), `opencode_app/README.md:26`, and the `deploy/setup.sh:3579` "72 primary-visible" comment — verified via census `grep -rn "149\|\b72\b" README.md opencode_app/README.md deploy/setup.sh tests/skill_profiles.bats` returning only intended values
    — **Consumers affected:** installer listing; deploy banner; docs

### Phase 4: live deployment + A/B execution + evidence
- [ ] **4.1** Redeploy the global config (`./deploy/setup.sh --yes` — non-interactive; bare setup.sh stalls an agent-driven run) so the new commands + skill allows are live in the running session's harness; verify `/review-arch`, `/review-inline`, `/run-plan-v2` appear and one inline skill loads. Then create the A/B model-parity overlay: a project `.opencode/opencode.json` in the worktree redefining `/review-arch` + `/review-inline` with an identical pinned `model:` (v2 Loading: project replaces global same-name commands; keeps the shipped entries provider-agnostic — review N1's prescribed fix)
    — **Why:** Review M5 — the repo files are inert until deployed; the overlay delivers M3's model parity without provider-locking the shipped config
    — **Done when:** All three commands invocable, an inline skill loads, and the overlay pins both review commands to one model
    — **Consumers affected:** Phase 4 runs (4.2-4.4)
- [ ] **4.2** Run the review A/B on a fixed target (the repo's last merged feature diff — #583's `git diff 6752e15..86cbd45` scope) once per variant, sequential, fresh session per variant where the harness allows: `/review-arch` (child session — sum PARENT+CHILD usage from session-storage JSONL fields) vs `/review-inline` (in-session — parent usage); record per arm: tokens (with capture source named), wall time (timestamps), context growth (session length delta), findings count by severity, resolved model
    — **Why:** AC 6 + review M4 — metrics name their capture source; the arch arm's dominant cost hides in the child session
    — **Done when:** Both variants ran to their output contracts on the same target; all four metrics captured per arm with sources
    — **Consumers affected:** 4.4 keep/park decision; issue comment
- [ ] **4.3** Run the `/run-plan-v2` end-to-end trial: author a small scratch PLAN (3-5 atomic steps, a docs fix in the worktree), execute it via `/run-plan-v2`, verify zero Task/subagent calls in the session trace
    — **Why:** AC 3 — the substitution map must be proven end-to-end, not just written
    — **Done when:** Scratch PLAN fully executed via /run-plan-v2; trace shows no Task tool calls
    — **Consumers affected:** AC 3; 4.4 evidence
- [ ] **4.4** Post the A/B numbers (with per-arm resolved models + capture sources), the `/run-plan-v2` trial result, and the keep/park decision per variant (park semantics: remove that variant's command entry in a follow-up commit; full-family park = reverse the skills/preset/lean/counts sweep) as an issue comment on #582
    — **Why:** AC 6 — numbers live in the issue with the decision
    — **Done when:** Comment posted with all metrics, sources, and explicit keep/park per variant
    — **Consumers affected:** ticket AC 6; future routing-skill work

### Phase 5: verification gate
- [ ] **5.1** Full `bats tests/` (incl. `skill_profiles.bats` 76-count, `init.bats` 10-preset, `test_requires_skills.bats` untouched-map) + `node installer/build-registry.mjs --check` green (ticket exit gate, tier=full)
    — **Why:** AC 5 — packaging must survive the whole suite
    — **Done when:** --check no drift beyond the 4 intended entries; bats fully green
    — **Consumers affected:** CI; ticket AC 5

## Technical Notes
- Commands vehicle: the shipped `opencode_app/opencode.json` `commands` block (v2 key is plural `commands`; `agent` selects the executor; `subagent: true|false` forces child/current session — omitted means child iff the agent's `mode: subagent`; model precedence is command-model > agent model > session model — hence the pinned `model:`). Deployed globally by `setup.sh` (opencode_app/opencode.json:130 is the single global deploy source).
- `pack-experiment.json` is hand-maintained: sibling presets carry `$comment: derived by /tmp/gen-presets.mjs` — that generator is not in-repo; regeneration would drop the hand preset; noted in its `$comment`.
- The inline family must NOT vendor subagent content (isolation contract #437): decision trees defer to the same knowledge skills via preset closure; Enforcement deltas translate fresh-context/sandbox/tier-model into advisory discipline.
- A/B fairness: same review target (#583 diff), pinned identical `model:` on both commands, sequential runs, fresh session per variant; per-arm resolved model recorded anyway.
- Existing subagents, `plan-execution-skill`, and all knowledge skills stay byte-identical (ticket constraint).

## Dependencies
- None external; single ticket.

## Risks & Mitigation
- **A/B measurement noise** (single run per variant): the ticket asks for recorded numbers + a decision, not statistical significance — record raw numbers and state the caveat.
- **Skill-count/literal drift**: 3.1-3.3 enumerate the pinned literals from the actual test files (review M1 inventory); 5.1 runs the guards.
- **Command-block JSON size**: three new entries — JSON parse + full bats in 5.1.
- **opt-in leak**: default deploy changes are limited to additive command entries + 4 allow rules (both inert unless invoked); the preset only installs when requested — verified by 5.1's full suite.
- **Lean arithmetic**: 72→76 literal updates ride the same commit as the lean entries (review M1's violated pattern, pre-empted).
