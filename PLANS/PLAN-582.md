# PLAN: A/B harness — /review-arch pilot + inline skill family

**Branch**: feat/582
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/582
**Base**: main

## Acceptance Criteria
- [ ] `/review-arch` and `/review-inline` exist in the global commands block and run the same review target
- [ ] Four `*-inline-skill` dirs exist: self-contained, frontmatter contract conformant (`name` = dir, `license`, `compatibility`, `metadata`), `requiresSkills` declared
- [ ] `/run-plan-v2` completes a small PLAN end-to-end with zero Task/subagent calls
- [ ] `pack-experiment` preset installs the family opt-in; default `setup.sh` deploy unchanged
- [ ] `build-registry.mjs` + `registry.json` rebuilt; skill counts synced (`setup.sh`, `setup.ps1`, README)
- [ ] A/B numbers recorded in this issue (session tokens, wall time, context growth, findings per variant) with a keep/park decision per variant

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/{testing,linting,documentation,responsive-audit}-inline-skill/SKILL.md` (4 new) | — | `/run-plan-v2` template (substitution map), `pack-experiment` preset, lean profile, registry rebuild | medium |
| `installer/dependency-map.json` (skill→skill `requiresSkills` edges) | skill dirs exist (1.1) | installer dep resolution (`add <inline-skill>` pulls knowledge skills) | medium |
| `opencode_app/opencode.json` `commands` block (+`/review-arch`, `/review-inline`, `/run-plan-v2`) | inline family (for `/run-plan-v2`'s substitution map) | opencode runtime command surface (user-facing slash commands) | high |
| `installer/presets/pack-experiment.json` (new) | skill dirs (1.1) | `--preset experiment` installer flow | low |
| `deploy/skill-profiles.json` (lean +4) | skill dirs (1.1) | `apply-skill-profile.mjs`, `tests/skill_profiles.bats` (lean keys must match disk) | low |
| `installer/registry.json` (rebuild) | skill dirs (1.1) | installer picker/listing; README counts | low |
| `setup.sh`/`setup.ps1`/`README.md` counts | registry rebuild (3.2) | deploy banner; docs readers | low |
| Issue #582 A/B comment | Phase 4 runs | ticket AC 6; keep/park decision | low |

## Implementation Phases

### Phase 1: inline skill family (4 self-contained skills)
- [ ] **1.1** Create `skills/testing-inline-skill/SKILL.md`: thin decision tree for running the testing delegate's workflow in-session — role skip rules (pure-data/trivial exemptions, test-inviable stacks), scope bounds (only files in the current diff), output contract mirroring testing-subagent's report shape, an **Enforcement deltas** section (translating the subagent's harness-enforced `edit: allow` isolation, fresh context, tier routing into explicit advisory discipline: announce scope before writing tests, no source edits beyond test files, self-report token budget), and frontmatter per contract (`name` = dir, `description` ≤1024 with triggers, `license: Apache-2.0`, `compatibility: opencode`, `metadata`)
    — **Why:** First family member establishes the inline-skill template the other three clone — its shape decision (decision-tree + enforcement-deltas + output contract) is the design the A/B measures
    — **Done when:** Dir + SKILL.md exist, frontmatter contract-conformant, decision tree covers skip/scope/output, Enforcement deltas section present
    — **Consumers affected:** `/run-plan-v2` (2.1), preset (3.1), lean profile (3.3), registry (3.2)
- [ ] **1.2** Create `skills/linting-inline-skill/SKILL.md`: in-session linting delegate — language linter discovery, scoped-lint rule (only touched files), gate semantics deferring to `verification-loop-skill`, Enforcement deltas (subagent's read-only-then-fix isolation → in-session: fixes applied directly but reported per-file), output contract
    — **Why:** Highest-frequency /run-plan delegate — its inline form carries the most A/B weight
    — **Done when:** Dir + SKILL.md contract-conformant with the four sections
    — **Consumers affected:** same as 1.1
- [ ] **1.3** Create `skills/documentation-inline-skill/SKILL.md`: in-session docstring/docs delegate — PEP 257/JSDoc/XML per language pointers via `documentation-*` knowledge, skip rules (pure-data, trivial), scope bounds (new/changed symbols only), output contract
    — **Why:** Third standard /run-plan delegate
    — **Done when:** Dir + SKILL.md contract-conformant
    — **Consumers affected:** same as 1.1
- [ ] **1.4** Create `skills/responsive-audit-inline-skill/SKILL.md`: in-session responsive audit delegate — wraps the `playwright-responsive-audit-skill` inline loop (detect→fix→re-verify tiers) with skip rules (no Playwright config → note + skip, never install unprompted) and output contract
    — **Why:** Completes the delegation-substitution map; the subagent's background/timeout model needs an explicit inline translation
    — **Done when:** Dir + SKILL.md contract-conformant
    — **Consumers affected:** same as 1.1
- [ ] **1.5** Declare `requiresSkills` edges in `installer/dependency-map.json` for the four inline skills → their knowledge-skill deps (testing-inline → none beyond self; linting-inline → `language-linting-skill`, `verification-loop-skill`; documentation-inline → `technical-writing-skill`; responsive-audit-inline → `playwright-responsive-audit-skill`), following the existing skill-entry shape in the map
    — **Why:** `add <inline-skill>` must pull the knowledge skills the decision trees defer to — without the edges the skills are hollow
    — **Done when:** Installer `--expand` on an inline skill resolves its knowledge deps; JSON parses
    — **Consumers affected:** installer dep resolution; preset installs

### Phase 2: command surfaces
- [ ] **2.1** Add `/review-arch` and `/review-inline` to the `opencode_app/opencode.json` `commands` block: identical review-prompt template (target arg → severity-gated review per `reviewer-baseline-skill`), differing only in executor — `/review-arch` sets `agent: architecture-review-subagent` (subagent session per its `mode: subagent`), `/review-inline` runs in-session on `build` with the architecture checklist inlined via `architecture-review-skill` pointer
    — **Why:** AC 1 — the A/B needs both variants reachable as first-class commands running the same review target
    — **Done when:** Both entries in the commands block; JSON parses; descriptions state the executor difference
    — **Consumers affected:** opencode runtime command surface; A/B (4.1)
- [ ] **2.2** Add `/run-plan-v2` to the commands block: wraps unmodified `plan-execution-skill` with an explicit delegation-substitution map in the template (testing → `testing-inline-skill`, linting → `linting-inline-skill`, documentation → `documentation-inline-skill`, responsive-audit → `responsive-audit-inline-skill` inline loop) and a hard "zero Task/subagent calls" instruction
    — **Why:** AC 3 — the inline execution path must be a single command, not a remembered convention
    — **Done when:** Entry present; template carries the full substitution map and the zero-Task instruction
    — **Consumers affected:** A/B trial (4.2); plan-execution skill (unmodified — verified)

### Phase 3: packaging
- [ ] **3.1** Create `installer/presets/pack-experiment.json` (`name: experiment`, the 4 inline skills, no agents) in the exact `pack-*.json` shape; hand-authored with a `$comment` noting the registry generator (`/tmp/gen-presets.mjs`) is not in-repo, so this preset is hand-maintained
    — **Why:** AC 4 — opt-in install path; opt-in means default deploy is untouched
    — **Done when:** `--expand experiment` resolves the 4 skills; file matches the pack-*.json schema
    — **Consumers affected:** installer preset flow; AC 4
- [ ] **3.2** Run `node installer/build-registry.mjs`; commit `registry.json` with the 4 new skill entries (149→153); sync counts in `setup.sh` + `setup.ps1` (banner/count sites) + `README.md` skill count; add the 4 inline skills to `deploy/skill-profiles.json` `lean` array (primary must load them for /run-plan-v2)
    — **Why:** AC 5 + the lean profile is what lets the primary actually invoke the family
    — **Done when:** Registry shows 153 skills; counts grep consistent across the three surfaces; `skill_profiles.bats` green (every lean key matches a dir)
    — **Consumers affected:** installer listing; deploy banner; docs

### Phase 4: A/B execution + evidence
- [ ] **4.1** Run the review A/B on a fixed target (the repo's last merged feature diff — #583's `git diff 6752e15..86cbd45` scope) once per variant: `/review-arch` (subagent session) vs `/review-inline` (in-session); record per variant in a working note: session tokens, wall time, context growth (session length delta), findings count by severity
    — **Why:** AC 6 — the harness exists to measure; qualitative arguments are what this ticket replaces
    — **Done when:** Both variants ran to their output contracts on the same target; four metrics captured per variant
    — **Consumers affected:** 4.3 keep/park decision; issue comment
- [ ] **4.2** Run the `/run-plan-v2` end-to-end trial: author a small scratch PLAN (3-5 atomic steps, e.g. a docs fix in the worktree), execute it via `/run-plan-v2`, verify zero Task/subagent calls in the session trace
    — **Why:** AC 3 — the substitution map must be proven end-to-end, not just written
    — **Done when:** Scratch PLAN fully executed via /run-plan-v2; trace shows no Task tool calls
    — **Consumers affected:** AC 3; 4.3 evidence
- [ ] **4.3** Post the A/B numbers + `/run-plan-v2` trial result + keep/park decision per variant as an issue comment on #582
    — **Why:** AC 6 — numbers live in the issue, decision recorded where the experiment was proposed
    — **Done when:** Comment posted with all four metrics per variant and an explicit keep/park per variant
    — **Consumers affected:** ticket AC 6; future routing-skill work

### Phase 5: verification gate
- [ ] **5.1** Full `bats tests/` + `node installer/build-registry.mjs --check` + `skill_profiles.bats` explicitly green (ticket exit gate, tier=full)
    — **Why:** AC 5 — packaging must survive the whole suite (skill counts, lean keys, preset flow all have pinned tests)
    — **Done when:** --check no drift beyond the 4 intended entries; bats fully green
    — **Consumers affected:** CI; ticket AC 5

## Technical Notes
- Commands vehicle: the shipped `opencode_app/opencode.json` `commands` block (already carries `/run-plan`, `/create-ticket`, `/run-worktree-pipeline`) — deployed globally by `setup.sh`, so the pilot commands appear for all users of the default deploy. Opt-in-ness comes from the preset (skills) + the commands being additive/no-op unless invoked.
- `pack-experiment.json` is hand-maintained: the other presets carry `$comment: derived by /tmp/gen-presets.mjs` — that generator is not in-repo, so regeneration would drop the hand preset; noted in its `$comment`.
- The inline family must NOT vendor subagent content (isolation contract #437): decision trees defer to the same knowledge skills (`requiresSkills`), Enforcement deltas translate harness enforcement into advisory discipline.
- A/B fairness: same review target, same model (session default), sequential runs, fresh session per variant where the harness allows; context growth measured as session message-length delta.
- Existing subagents, `plan-execution-skill`, and all knowledge skills stay byte-identical (ticket constraint).

## Dependencies
- None external; single ticket.

## Risks & Mitigation
- **A/B measurement noise** (single run per variant): the ticket asks for recorded numbers + a decision, not statistical significance — record raw numbers and state the caveat in the comment.
- **Skill-count drift across surfaces**: 3.2 greps all three surfaces in one step; documentation-sync rules.
- **Command-block JSON size**: three new entries in a large config — full bats + JSON parse in 5.1 catches syntax; descriptions kept ≤ the run-plan entry's length.
- **opt-in leak**: default deploy unchanged verified by 5.1's full suite (skill_profiles + pack tests) — the preset only installs when requested.
