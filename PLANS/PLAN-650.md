# PLAN: architecture-review-skill — decision-tree review skill + v2 inline routing

**Branch**: feat/650
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/650
**Base**: main

## Acceptance Criteria
- [x] `skills/architecture-review-skill/SKILL.md` exists, self-contained, passes `tests/test_skill_isolation.bats`
- [x] No v2 path references "load agents/architecture-review-subagent.md" anymore (grep-verifiable)
- [x] `/review-arch` + v1 pipeline Step 7 still resolve (thin subagent loads the skill)
- [x] `installer/registry.json` regenerated and committed
- [x] README / setup.sh / setup.ps1 skill counts updated

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/architecture-review-skill/SKILL.md` (new) | 1.1 precedes all; content lifted from `agents/architecture-review-subagent.md` body | subagent body (1.2), `deploy/opencode.json` templates (2.1), `installer/dependency-map.json` (1.3), `installer/presets/pack-inline-workers.json` (1.3), `installer/registry.json` (1.4) | low |
| `agents/architecture-review-subagent.md` | skill (1.1) | `deploy/opencode.json` `/review-arch` (unchanged), v1 pipeline Step 7 (`worktree-pipeline-skill` soft-dep, unchanged), `installer/agent-tiers.json` (unchanged), `installer/registry.json` (1.4 — permissions frontmatter changes) | medium |
| `installer/dependency-map.json` | skill dir exists (1.1) | `installer/init.mjs` (`requiresSkills` resolution for `npx add`) | low |
| `installer/presets/pack-inline-workers.json` | skill dir exists (1.1) | `installer/init.mjs` (`--preset inline-workers`) | low |
| `installer/registry.json` (generated) | ALL frontmatter final (1.1, 1.2) | `installer/init.mjs` registry reads; `tests/` count guard (test 59) | low |
| `README.md` (counts + wording) | registry/skill final (1.4) | humans; `tests/` doc-count guard (test 425) | low |
| `deploy/opencode.json` (v2 template + `/review-inline`) | skill (1.1), subagent rework (1.2) | `deploy/setup.sh` / `setup.ps1` copy to user config; every shipped command | medium |
| `skills/worktree-pipeline-skill/SKILL.md` | skill (1.1) | `/run-worktree-pipeline`, `/run-worktree-pipeline-v2`, `/worktree-pipeline-preview` commands load it | low |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Canonical step format
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: Skill + thin orchestrator + repo-consistency closure
- [x] **1.1** Create `skills/architecture-review-skill/SKILL.md` with the decision-tree review methodology (evidence gate rule, target-routing decision tree, review axes, Blast-Radius Gate, finding schema + severity rubric, Plan Atomicity Check, Return Contract), frontmatter per the house contract (`name` = dir, ≤50-word description with triggers, Apache-2.0, `compatibility: opencode`, `metadata.mirrors: architecture-review-subagent`, `category: Code Quality`), content lifted from the subagent body — no new review semantics
    — **Why:** every later step consumes this file; it is the single source of truth the subagent and the inline arm share
    — **Done when:** file exists with valid frontmatter; zero sibling-skill path refs inside fenced code blocks (guard-safe); prose cites reviewer-baseline/blast-radius/clean-architecture skills
    — **Consumers affected:** 1.2, 2.1, 1.3, 1.4
    — **Done:** skill created (289 lines: decision tree, 7 axes, gates, schema, contract); files: skills/architecture-review-skill/SKILL.md; fixes: none
- [x] **1.2** Rework `agents/architecture-review-subagent.md` into a thin orchestrator: body states the skill is the review-knowledge source of truth and retains only orchestration mechanics (baseline-first load order, bash sandbox enforcement, CodeGraph integration, explore delegation, LEARNINGS-candidate rule, Return Contract pointer); add `action: skill, resource: architecture-review-skill, effect: allow` to permissions
    — **Why:** the subagent must load the skill instead of embedding it, or the two copies drift (#437 isolation contract by analogy: single checklist source)
    — **Done when:** the moved sections live in the skill only — `grep -c "Mandatory Blast-Radius & Consumer Traversal Gate" agents/architecture-review-subagent.md` = 0; permissions include `architecture-review-skill: allow`; `/review-arch` command's agent ref still resolves
    — **Consumers affected:** 2.1 (templates keep pointing at the same agent for v1), 1.4 (registry rebuild reads new frontmatter)
    — **Done:** agent body shrunk to orchestrator (baseline, sandbox, CodeGraph, explore, boundaries); permissions +1 skill; files: agents/architecture-review-subagent.md; fixes: none
- [x] **1.3** Add `"architecture-review-skill": ["reviewer-baseline-skill"]` to `installer/dependency-map.json` `requiresSkills` and add `architecture-review-skill` to `installer/presets/pack-inline-workers.json` skills array; update the preset `$comment` and description to cover the arch-review wrapper
    — **Why:** `npx add architecture-review-skill` must pull its runtime baseline, and the `inline-workers` preset is the documented opt-in pack for the v2 arm; landing it inside Phase 1 keeps the count guards' closure in one gate window
    — **Done when:** both JSON files parse (`node -e` JSON.parse) and contain the entries
    — **Consumers affected:** `installer/init.mjs`, fresh per-skill installs
    — **Done:** requiresSkills entry + preset membership + comment/description; files: installer/dependency-map.json, installer/presets/pack-inline-workers.json; fixes: reverted json.dumps reformat for surgical text edits
- [x] **1.4** Run `node installer/build-registry.mjs` and stage the regenerated `installer/registry.json` (single rebuild — all frontmatter is final after 1.1/1.2)
    — **Why:** frontmatter contract: registry must match skill+agent frontmatter; the test-59 count guard stays red until this lands, and regenerated artifacts must not be left unstaged
    — **Done when:** `installer/registry.json` diff contains the new skill entry and the updated agent permissions; file staged
    — **Consumers affected:** `installer/init.mjs` install-time warnings; Phase 1 gate (test 59)
    — **Done:** registry rebuilt (skills=120→121, agent closure 11→12); files: installer/registry.json; fixes: none
- [x] **1.5** Update `README.md` skill counts: Code Quality row 15→16 with `architecture-review-skill` listed, and the total skill count wherever stated
    — **Why:** the test-425 doc-count guard stays red until the README counts match the skills/ tree
    — **Done when:** README Code Quality row shows 16 and lists the new skill; `bats` count guard green
    — **Consumers affected:** Phase 1 gate (test 425); 3.1 wording updates ride the same file
    — **Done:** README counts 120→121 (5 sites) + Code Quality row 15→16 with new skill; files: README.md; fixes: none

### Phase 2: Rewire inline consumers
- [x] **2.1** Rewrite the `run-worktree-pipeline-v2` template Step 7 sentence and the `/review-inline` command in `deploy/opencode.json` to load skill `architecture-review-skill` (with `reviewer-baseline-skill` first) in place of the deployed agent-file checklist; keep the skip-with-note fallback rule for unresolvable skills; update both `description` fields to say "skill-driven"
    — **Why:** this is the ticket's core deliverable — the v2 arm stops depending on a deployed agent file for architecture review
    — **Done when:** the v2 template's Step 7 sentence no longer routes reviewers through the `agents/<reviewer>-subagent.md` placeholder checklist (`grep -c "load the deployed file agents/<reviewer>-subagent.md" deploy/opencode.json` = 0) and `grep -c "architecture-review-skill" deploy/opencode.json` ≥ 2 (v2 template + `/review-inline`); `/review-arch` template untouched
    — **Consumers affected:** deployed-command users; `worktree-pipeline-skill` docs (2.2)
    — **Done:** v2 Step 7 sentence + both description fields rewritten to skill routing; files: deploy/opencode.json; fixes: none
- [x] **2.2** Update `skills/worktree-pipeline-skill/SKILL.md` Step 1 soft-dep line and Step 7: inline arm routes architecture review to skill `architecture-review-skill` in-session; v1 arm text unchanged
    — **Why:** the skill doc is the pipeline's behavioral contract — the command template and the skill must not disagree
    — **Done when:** Step 7 names the inline-arm skill route; v1 Task-call text for `architecture-review-subagent` remains verbatim
    — **Consumers affected:** pipeline runs in both arms
    — **Done:** Step 1 soft-dep inline-arm note + Step 7 inline-arm skill route; v1 Task-call text verbatim; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none

### Phase 3: Docs remainder + verification
- [x] **3.1** Update `README.md` remaining wording: the line-24 "loading the deployed agent definitions as checklists" sentence to reflect the skill-driven arch review, and the inline-workers pack line (95) naming the arch wrapper
    — **Why:** README is the usage-docs home; the v2 flavor description must match the new routing
    — **Done when:** line-24 sentence describes skill-driven arch review; pack line names `architecture-review-skill`; `grep -c "architecture-review-skill" README.md` ≥ 3
    — **Consumers affected:** none (docs)
    — **Done:** line-24 v2 flavor sentence + inline-workers pack row updated; files: README.md; fixes: none
- [x] **3.2** Verify `deploy/setup.sh` + `deploy/setup.ps1` carry no hardcoded skill counts (`count_skills` is dynamic) — record the finding instead of editing when dynamic
    — **Why:** ticket AC names setup counts; if they are computed, "updated" means verified-not-stale, and an edit would be make-work
    — **Done when:** grep for hardcoded skill totals in both scripts returns none, noted in the phase commit message
    — **Consumers affected:** none (verification)
    — **Done:** no hardcoded counts — count_skills dynamic (setup.sh:4636), ps1 thin launcher guard-enforced; recorded, no edit; fixes: none
- [x] **3.3** Run the full verification set: `tests/test_skill_isolation.bats`, `node installer/build-registry.mjs` idempotence (no diff), AC greps (no agent-file load in v2 paths; `/review-arch` + v1 Step 7 intact)
    — **Why:** exit-gate evidence for the ticket ACs
    — **Done when:** bats suite exits 0; registry rebuild is a no-op; all AC greps return the expected result
    — **Consumers affected:** Step 9 code review, Step 10 PR citation
    — **Done:** bats 642/642 exit 0; registry idempotent (timestamp-only diff reverted); AC greps: v2 agent-file refs 0/0, /review-arch + v1 Step 7 intact 1/1, README skill refs 3; fixes: none

GATE 224605d tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a (bats 642/642; lint=JSON.parse substitutes on dep-map+preset; full tier: cross-module Consumer Map node + manifest anchors; 3 gate fix rounds: plan resequencing pulled 1.3–1.5 into phase, HANDOFF5 contract added to guard+mirror, argv index fix)

GATE 39506ab tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a (bats 642/642; lint=deploy/opencode.json JSON.parse; full tier: deploy-config anchor)

GATE 73f92fc tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a (ticket exit gate, run on the phase-3 tree before its commit; bats 642/642 exit 0; registry idempotent modulo generatedAt; AC1–AC5 PASS)

## Technical Notes
- Guard semantics (verified in `tests/test_skill_isolation.bats`): sibling-skill violations trigger only on path refs inside fenced code blocks of SKILL.md — prose mentions are documentation. The new skill needs NO new HANDOFF entry.
- **Phase-1 gate sequencing** (execution finding, fix attempt 1): tests 59 (`registry.json … counts`) and 425 (`skill_count_consistent_across_docs`) are end-state guards — red until registry (1.4) + README counts (1.5) land. Steps 3.1/3.2/4.1-counts of the original draft were pulled into Phase 1 so every phase gate can go green in order.
- `deploy/setup.sh:4636` computes the skill count via `count_skills` — dynamic, nothing to bump (step 3.2 verifies).
- Subagent frontmatter: keep `mode: subagent`, `steps: 40`, all existing permissions except the one added skill allow.
- The v1 arm (`/run-worktree-pipeline`) and `/review-arch` keep spawning the (thin) subagent — isolated-context review stays available; deletion of the subagent is explicitly out of scope (thin-orchestrator decision, #650 discussion).
- Skill content source of truth: current `agents/architecture-review-subagent.md` body (baseline-first, blast-radius gate, plan atomicity, return contract) restructured to the `uiux-review-skill` section pattern (what/when → methodology → decision tree → axes → gates → schema → severity → references).

## Dependencies
None — single ticket, no `blocked-by`.

## Risks & Mitigation
- **Drift between skill and subagent bodies** → 1.2 makes the subagent a pointer, not a copy; code review (Step 9) diffs for restated rubric text.
- **Command template regressions breaking deployed commands** → 2.1 touches only the v2 template + `/review-inline` sentences; `/review-arch` and `/run-worktree-pipeline` (v1) are grep-verified untouched in 3.3.
- **Registry drift** → single rebuild at 1.4 after frontmatter is final + idempotence check at 3.3.
