# PLAN: inline-aware dependency preflight + #613-comment follow-ups

**Branch**: feat/617
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/617
**Base**: main

## Acceptance Criteria

- [ ] A preset-`inline-workers`-only install can run `/run-worktree-pipeline-v2` through preflight without abort (preflight resolves the Step 8 executor per arm)
- [ ] v1 `/run-worktree-pipeline` preflight behavior unchanged (subagent arm still hard-requires `plan-execution-skill` + both reviewer agents)
- [ ] The preset description no longer carries the "pack-only installs lack the pipeline skill's hard dependency preflight" caveat (removed when fixed)
- [ ] `bats tests/` green, including a new guard pinning the v2 zero-subagent contract string + preset membership
- [ ] Docker dead-letter agent-path references pruned repo-wide (v2 entry + `/review-inline`)
- [ ] `playwright-responsive-audit-skill` present in the lean profile (closes the inline responsive-audit deferral gap)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/worktree-pipeline-skill/SKILL.md` preflight | — | every pipeline run (v1 + v2); the running session resolves the set per invocation | medium |
| `deploy/opencode.json` v2 entry + `review-inline` entry | — | opencode runtime; setup.sh copy; new bats guard | medium |
| `deploy/skill-profiles.json` lean array + `deploy/opencode.json` shipped allows + `tests/skill_profiles.bats` count pin + `README.md` profile prose | all four move together (Step 7 WARN-1) | setup.sh skill-profile filtering; count-pin tests; docs readers | medium |
| `installer/presets/pack-inline-workers.json` description | 1.1 (caveat removal only valid once preflight is arm-aware) | installer/init.mjs preset flow | low |
| `tests/test_v2_pipeline_contract.bats` | 1.1 + 2.2 (guards the post-change text) | CI / local bats runs | low |

## Implementation Phases

### Phase 1: inline-aware preflight

- [x] **1.1** Reword the SKILL.md preflight (lines ~65-71) to per-arm dependency sets: subagent arm (v1) hard-requires `plan-execution-skill` --gate + agents `code-review-subagent`/`pr-workflow-subagent`; inline arm (invoked by the `/run-worktree-pipeline-v2` template) hard-requires `plan-execution-inline-skill` + the same agent definition FILES as checklists (code-review-subagent.md, pr-workflow-subagent.md — resolve as files at the deploy-mode paths); the running session resolves which set applies from its invocation (the v2 template's "spawn NO subagents" directive marks the inline arm); soft deps and install hints unchanged
    — **Why:** this is #617's core — a preset-inline-workers-only install aborts at preflight on `plan-execution-skill`, which the v2 arm never invokes
    — **Done when:** the preflight text names both sets with the arm-resolution rule; v1's set is textually unchanged in its requirements
    — **Consumers affected:** all pipeline runs (v1 behavior preserved by the explicit arm split)
    — **Done:** preflight rewritten to two named arm sets with the directive-based resolution rule; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **1.2** Verify v1 preflight invariance: diff the subagent-arm clause against the pre-change text — requirements identical (same hard deps, same abort + install hint wording)
    — **Why:** AC2 — v1 users must see zero preflight behavior change
    — **Done when:** the v1 clause's hard-dep list and abort semantics match origin/main's byte-for-byte modulo the arm-scoping framing
    — **Consumers affected:** v1 pipeline users (unchanged)
    — **Done:** diff shows all three v1 hard deps retained; "Any missing dep for the resolved arm → abort" + install hint intact; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none

## Gate Trace

GATE 311c868 tier=full lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a (bats 615/615 — phase 1, cross-module anchor; SKILL.md-only change, no linter target)

### Phase 2: #613-comment follow-ups

- [x] **2.1** Prune the Docker dead-letter path `/app/.opencode/agents/` from both command templates in `deploy/opencode.json` (v2 entry, `review-inline`) — keep the CLI path + unresolvable handling as the sole resolution branch
    — **Why:** #506 removed the Docker staging surface; the leg is dead-letter (Mode R adjudication recommended pruning in a follow-up — this is it); pruned BEFORE the guard lands so the guard's no-Docker assertion is green at its own Done-when
    — **Done when:** `rg -c "app/.opencode/agents" deploy/opencode.json` returns 0 matches
    — **Consumers affected:** runtime command templates (CLI resolution unchanged)
    — **Done:** both templates pruned to CLI-only resolution ("if it does not resolve" phrasing); zero `app/.opencode/agents` matches in deploy/opencode.json; files: deploy/opencode.json; fixes: none
- [x] **2.2** Add `tests/test_v2_pipeline_contract.bats`: assert the v2 command entry contains "spawn NO subagents" and `"subagent": false`, asserts NO Docker `/app/.opencode/agents` path remains in any command template, and asserts every `installer/presets/pack-inline-workers.json` skill exists as `skills/<name>/SKILL.md`
    — **Why:** the v2 entry has been reshaped 3 times (#585→#591→#613) with no drift guard; the preset gained 7 members with no membership guard (review NOTE-5)
    — **Done when:** `bats tests/test_v2_pipeline_contract.bats` exits 0 on the changed tree
    — **Consumers affected:** CI / local bats runs
    — **Done:** 7-test guard added (subagent:false pin, zero-subagent directive, checklist mechanics, no-Docker, no-caveat, preset membership on disk, arm-aware preflight) — 7/7 green; files: tests/test_v2_pipeline_contract.bats; fixes: none
- [x] **2.3** Make `playwright-responsive-audit-skill` loadable on lean deploys — FOUR coordinated surfaces (Step 7 review WARN-1): (a) add to the shipped skill allows in `deploy/opencode.json` (currently absent — lean must stay a subset of shipped allows), (b) add to the `lean` array in `deploy/skill-profiles.json`, (c) update the count pin in `tests/skill_profiles.bats` ("exactly 67 keys" → 68), (d) update the README skill-profile prose count (line ~217 "67 primary-visible")
    — **Why:** `responsive-audit-inline-skill` (lean ✓) defers to it in-session; on lean deploys that load hits a denied skill (review NOTE-4); the two-file + two-count coupling was missed in the original step (review WARN-1)
    — **Done when:** all four surfaces updated; `bats tests/skill_profiles.bats` green; `rg -c "67 primary-visible" README.md` returns 0
    — **Consumers affected:** lean-profile deploys; count-pin tests; README accuracy
    — **Done:** shipped allow added adjacent to responsive-audit-inline-skill; lean array +1; count pin 67→68 (test + comment header); README prose 67→68; skill_profiles.bats green; files: deploy/opencode.json, deploy/skill-profiles.json, tests/skill_profiles.bats, README.md; fixes: none
- [x] **2.4** Remove the caveat clause " — pack-only installs lack the pipeline skill's hard dependency preflight" from `installer/presets/pack-inline-workers.json` description (keep the "on full deploys" scoping only if still accurate post-1.1 — if preflight is now arm-aware, drop the whole caveat)
    — **Why:** #617 AC3 — the caveat is false once the preflight resolves per arm
    — **Done when:** the description carries no preflight caveat; 2.1 membership guard still green
    — **Consumers affected:** preset installs (description only)
    — **Done:** preflight caveat dropped; "on full deploys" scoping kept (pack still ships no agent definition files, so the inline arm's Step 9 checklist still needs a full deploy for those); files: installer/presets/pack-inline-workers.json; fixes: none

### Phase 3: user-space refresh + exit gate

- [ ] **3.1** Surgical user-space refresh: copy the updated `skills/worktree-pipeline-skill/SKILL.md` to `~/.config/opencode/skills/worktree-pipeline-skill/SKILL.md`; surgically update the live `commands.run-worktree-pipeline-v2` + `commands.review-inline` entries to the pruned template text (single-key updates, `permissions` untouched); verify live == template for both entries
    — **Why:** the v2 arm reads the deployed SKILL.md + deployed commands — repo edits are inert until deployed; full setup.sh re-copy is avoided to protect the live `permissions` customization (the #613 deploy lesson)
    — **Done when:** deployed SKILL.md matches the repo file; both live command entries byte-equal the template; `permissions` key intact
    — **Consumers affected:** live v2 arm behavior (the point of the ticket)
- [ ] **3.2** Full-gate run and final AC sweep: `bats tests/` (whole suite, includes the new guard) + json lints on changed JSON files; tick ACs against evidence
    — **Why:** ticket exit gate runs full unconditionally; AC ticks need evidence
    — **Done when:** gate memo `tier=full` green for the final tree; all 6 ACs ticked with evidence
    — **Consumers affected:** PR creation (cites this memo)

## Technical Notes

- The preflight is prose executed by the running session, not a script — the "arm resolution" is the session reading its own invocation (the v2 template directive marks inline).
- `installer/dependency-map.json` has no `requiresSkills` entry for `worktree-pipeline-skill` (verified) — no installer-side sync needed for 1.1.
- Docker path history: inherited from `/review-inline` (#582) when the Docker staging surface still existed; #506 removed it; Mode R adjudication (#613) sanctioned pruning in a follow-up.
- The v2 inline arm itself is exercised by this very run — treat any template-following friction found mid-run as findings for the PLAN's Risks section.

## Dependencies

None — single ticket.

## Risks & Mitigation

- **Arm mis-resolution**: a v1 run misreading itself as inline (or vice versa) checks the wrong preflight set → mitigation: the resolution rule keys on the invocation's explicit directive ("spawn NO subagents" only ever appears in the v2 template).
- **Skill-profile count drift**: adding to the lean array may trip count-pinning guards → mitigation: 2.3 checks for guards reading skill-profiles.json before/after; run the full suite.
- **Deploy drift recurrence** (#613 lesson): a parallel refresh could revert the surgical user-space updates → mitigation: 3.1 verifies parity immediately, and the Step 9/PR-time checks re-verify.
