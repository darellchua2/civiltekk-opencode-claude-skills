# PLAN: v2 pipeline Step 10 PR via civiltekk-pr-workflow-skill

**Branch**: feat/652
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/652
**Base**: main

## Acceptance Criteria
- [ ] v2 command template Step 10 invokes `civiltekk-pr-workflow-skill` (create route); no pr-workflow-subagent reference remains in the v2 entry
- [ ] worktree-pipeline-skill: inline-arm preflight hard dep = the skill; Step 10a carries the inline-arm routing sentence; "What I do" is arm-aware
- [ ] tests/test_v2_pipeline_contract.bats pins the skill name
- [ ] pack-inline-workers preset includes civiltekk-pr-workflow-skill, ticketing-skill, semantic-release-convention-skill, gh-cli-setup-skill
- [ ] README two-flavor paragraph accurate
- [ ] bats tests/test_v2_pipeline_contract.bats green

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Use `codegraph_callers` (code) or `tofu graph` + grep (IaC). CodeGraph CLI absent — rg/grep fallback._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/opencode.json` → `commands.run-worktree-pipeline-v2` (description + template) | — (same-phase coupling: 1.1 must cite the wording decided by 1.2–1.4; no run consumes either until Phase 1 completes) | opencode runtime (every v2 run), `tests/test_v2_pipeline_contract.bats` (pins: `subagent:false`, "spawn NO subagents" directive, skill-name phrases), README:24 two-flavor paragraph | high |
| `skills/worktree-pipeline-skill/SKILL.md` (What-I-do, preflight, Step 10a) | — | v1+v2 pipeline runs, `tests/test_v2_pipeline_contract.bats` preflight greps ("plan-execution-inline-skill" ≥1, "resolved per arm" ≥1), Step 6 PLAN authoring (copies actor names into authored PLAN labels) | high |
| `tests/test_v2_pipeline_contract.bats` | final template wording (pins must match post-edit text) | CI gate | low |
| `installer/presets/pack-inline-workers.json` | `skills/<name>/SKILL.md` existence (verified for all four) | `installer/init.mjs --preset inline-workers`, `tests/test_v2_pipeline_contract.bats` (membership + "no preflight caveat" description check) | med |
| `README.md` (two-flavor paragraph) | final template + skill wording | docs readers; no test pins | low |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Canonical step format
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: v2 entry + pipeline skill rewire
- [ ] **1.1** Rewrite the Step 10 sentence of `commands.run-worktree-pipeline-v2` in `deploy/opencode.json` (template + description) to invoke the skill `civiltekk-pr-workflow-skill` (create route) with the declared-hard-dep stop rule, keeping every pipeline pin (target `<base>`, `tier=full` memo citation, `Closes <TICKET_ID>`, background-shell merge watch, "never a subagent") and the pinned phrases ("spawn NO subagents anywhere in the run", "code-review-inline-skill", "reviewer-baseline-skill")
    — **Why:** the v2 entry is the last place binding Step 10 to the `agents/pr-workflow-subagent.md` file; every v2 run resolves it and the preflight aborts without it
    — **Done when:** the v2 entry contains "civiltekk-pr-workflow-skill (create route)" and zero `pr-workflow-subagent` substrings; `node -e` JSON parse of `deploy/opencode.json` exits 0
    — **Consumers affected:** v2 runs, contract-test pins (synced in 2.1), README:24 (3.1)
- [ ] **1.2** Make the "What I do" actor line of `skills/worktree-pipeline-skill/SKILL.md` arm-aware (inline arm = the skill, v1 = `pr-workflow-subagent`)
    — **Why:** Step 6 PLAN authoring copies this line's actor name into authored PLAN step labels (observed: canvastekk PLAN-DA-3151.md:39 "PR (pr-workflow-subagent)")
    — **Done when:** the line names `civiltekk-pr-workflow-skill` for the inline arm and names `pr-workflow-subagent` only as the v1-arm worker
    — **Consumers affected:** future authored PLANs in all repos
- [ ] **1.3** Update the Step 1 dependency preflight of `skills/worktree-pipeline-skill/SKILL.md`: inline arm's Step 10 hard dep = skill `civiltekk-pr-workflow-skill` (create route), replacing the `agents/pr-workflow-subagent.md` definition-FILE dep
    — **Why:** preflight is the run gate — it must demand the new authority, not the retired checklist file
    — **Done when:** the inline-arm sentence names the skill; pinned preflight phrases "resolved per arm" and "plan-execution-inline-skill" remain intact (contract-test greps)
    — **Consumers affected:** v2 preflight; v1 preflight sentence untouched
- [ ] **1.4** Prepend the inline-arm routing sentence to Step 10a of `skills/worktree-pipeline-skill/SKILL.md` (Step 9's pattern: "inline arm: invoke the skill … the remainder of this section describes the subagent arm")
    — **Why:** Step 10a prose is Task-prompt mechanics for the subagent arm; the inline arm needs its routing sentence ahead of the pins so v2 runs execute the skill route
    — **Done when:** an "inline arm" sentence precedes the Task-prompt prose; the `tier=full` citation, skip-steps, and `Closes <TICKET_ID>` pins read unchanged
    — **Consumers affected:** v2 Step 10 execution
### Phase 2: contract pin + preset closure
- [ ] **2.1** Update the Step 10 pin in `tests/test_v2_pipeline_contract.bats` from "agents/pr-workflow-subagent.md as your in-session checklist" to the new skill-invocation phrase
    — **Why:** the test pins the old checklist phrase verbatim; after 1.1 the assertion fails and CI goes red
    — **Done when:** the assertion matches the post-1.1 template text and `bats tests/test_v2_pipeline_contract.bats` passes
    — **Consumers affected:** CI gate
- [ ] **2.2** Add `civiltekk-pr-workflow-skill`, `ticketing-skill`, `semantic-release-convention-skill`, `gh-cli-setup-skill` to `installer/presets/pack-inline-workers.json` and update its `$comment` + `description`
    — **Why:** per-skill installs of the inline family need the Step 10 route and its runtime deps — `dependency-map.json` has no `requiresSkills` coverage for the PR skill, so preset membership is the only closure
    — **Done when:** the preset lists the four skills, every member resolves on disk, and the description carries no preflight caveat (both contract-test checks)
    — **Consumers affected:** `installer/init.mjs --preset inline-workers`
### Phase 3: README accuracy
- [ ] **3.1** Reword the README two-flavor paragraph so the v2 claim matches reality (PR route skill-driven; the remaining agent-file checklist loads are the Step 7 uiux reviewer and the requirements relay)
    — **Why:** the paragraph currently claims all phases load "skills and the remaining deployed agent definitions as checklists" — false for Step 10 after 1.1; wording drift here misleads adopters (per command-description restatement drift learning, restatements must change with the source)
    — **Done when:** the paragraph names `civiltekk-pr-workflow-skill` as the Step 10 route and the uiux/requirements agent-file checklists as the only remaining agent-file loads
    — **Consumers affected:** docs readers

## Technical Notes
- Phrase pins in `tests/test_v2_pipeline_contract.bats` to preserve while editing the template: "spawn NO subagents anywhere in the run" (zero-subagent directive test), "code-review-inline-skill", "reviewer-baseline-skill", `subagent === false`; preflight greps on SKILL.md: "plan-execution-inline-skill" ≥1, "resolved per arm" ≥1. Only the line-30 pin changes (2.1).
- No frontmatter changes → no `installer/build-registry.mjs` rebuild; no skill/agent added/removed → no setup.sh/README count sync. The preset is hand-maintained — edit in place.
- Per-phase gate: `bats tests/test_v2_pipeline_contract.bats` + `node -e "require('./deploy/opencode.json')"`; ticket exit gate = full tier at Phase 3.
- Related learnings: `anti-patterns/command-description-parallel-restatement-drift.md` (description + template change together in 1.1), `anti-patterns/case-sensitive-grep-gates-false-green.md` (2.1 pin must match exact case of the new phrase).

## Dependencies
None external; single-ticket run.

## Risks & Mitigation
- Test-pin drift (template edited, pin not) → 2.1 lands in the same run; full bats file is the per-phase gate.
- Authored-PLAN copy-through (other repos' Step 6 copies the old actor name from stale deployed skills) → mitigated post-merge by redeploy; existing canvastekk PLAN labels already reconciled in a separate docs PR (#522).
