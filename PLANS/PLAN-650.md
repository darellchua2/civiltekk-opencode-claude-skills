# PLAN: architecture-review-skill — decision-tree review skill + v2 inline routing

**Branch**: feat/650
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/650
**Base**: main

## Acceptance Criteria
- [ ] `skills/architecture-review-skill/SKILL.md` exists, self-contained, passes `tests/test_skill_isolation.bats`
- [ ] No v2 path references "load agents/architecture-review-subagent.md" anymore (grep-verifiable)
- [ ] `/review-arch` + v1 pipeline Step 7 still resolve (thin subagent loads the skill)
- [ ] `installer/registry.json` regenerated and committed
- [ ] README / setup.sh / setup.ps1 skill counts updated

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/architecture-review-skill/SKILL.md` (new) | 1.1 precedes all; content lifted from `agents/architecture-review-subagent.md` body | subagent body (1.2), `deploy/opencode.json` templates (2.1), `installer/dependency-map.json` (3.1), `installer/presets/pack-inline-workers.json` (3.1), `installer/registry.json` (3.2) | low |
| `agents/architecture-review-subagent.md` | skill (1.1) | `deploy/opencode.json` `/review-arch` (unchanged), v1 pipeline Step 7 (`worktree-pipeline-skill` soft-dep, unchanged), `installer/agent-tiers.json` (unchanged), `installer/registry.json` (3.2 — permissions frontmatter changes) | medium |
| `deploy/opencode.json` (v2 template + `/review-inline`) | skill (1.1), subagent rework (1.2) | `deploy/setup.sh` / `setup.ps1` copy to user config; every shipped command | medium |
| `skills/worktree-pipeline-skill/SKILL.md` | skill (1.1) | `/run-worktree-pipeline`, `/run-worktree-pipeline-v2`, `/worktree-pipeline-preview` commands load it | low |
| `installer/dependency-map.json` | skill dir exists (1.1) | `installer/init.mjs` (`requiresSkills` resolution for `npx add`) | low |
| `installer/presets/pack-inline-workers.json` | skill dir exists (1.1) | `installer/init.mjs` (`--preset inline-workers`) | low |
| `installer/registry.json` (generated) | ALL frontmatter final (1.1, 1.2) | `installer/init.mjs` registry reads | low |
| `README.md` | counts stable (phases 1–3) | humans | low |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Canonical step format
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: Skill + thin orchestrator
- [ ] **1.1** Create `skills/architecture-review-skill/SKILL.md` with the decision-tree review methodology (evidence gate rule, target-routing decision tree, review axes, Blast-Radius Gate, finding schema + severity rubric, Plan Atomicity Check, Return Contract), frontmatter per the house contract (`name` = dir, ≤50-word description with triggers, Apache-2.0, `compatibility: opencode`, `metadata.mirrors: architecture-review-subagent`, `category: Code Quality`), content lifted from the subagent body — no new review semantics
    — **Why:** every later step consumes this file; it is the single source of truth the subagent and the inline arm share
    — **Done when:** file exists with valid frontmatter; zero sibling-skill path refs inside fenced code blocks (guard-safe); prose cites reviewer-baseline/blast-radius/clean-architecture skills
    — **Consumers affected:** 1.2, 2.1, 3.1, 3.2
- [ ] **1.2** Rework `agents/architecture-review-subagent.md` into a thin orchestrator: body states the skill is the review-knowledge source of truth and retains only orchestration mechanics (baseline-first load order, CodeGraph integration, explore delegation, LEARNINGS-candidate rule, Return Contract pointer); add `action: skill, resource: architecture-review-skill, effect: allow` to permissions
    — **Why:** the subagent must load the skill instead of embedding it, or the two copies drift (#437 isolation contract by analogy: single checklist source)
    — **Done when:** the moved sections (Mandatory Blast-Radius Gate, Plan Atomicity Check, review axes) live in the skill only — `grep -c "Mandatory Blast-Radius & Consumer Traversal Gate" agents/architecture-review-subagent.md` = 0; permissions include `architecture-review-skill: allow`; `/review-arch` command's agent ref still resolves
    — **Consumers affected:** 2.1 (templates keep pointing at the same agent for v1), 3.2 (registry rebuild reads new frontmatter)

### Phase 2: Rewire inline consumers
- [ ] **2.1** Rewrite the `run-worktree-pipeline-v2` template Step 7 sentence and the `/review-inline` command in `deploy/opencode.json` to load skill `architecture-review-skill` (with `reviewer-baseline-skill` first) in place of the deployed agent-file checklist; keep the skip-with-note fallback rule for unresolvable skills; update both `description` fields to say "skill-driven"
    — **Why:** this is the ticket's core deliverable — the v2 arm stops depending on a deployed agent file for architecture review
    — **Done when:** the v2 template's Step 7 sentence no longer routes reviewers through the `agents/<reviewer>-subagent.md` placeholder checklist (`grep -c "load the deployed file agents/<reviewer>-subagent.md" deploy/opencode.json` = 0) and `grep -c "architecture-review-skill" deploy/opencode.json` ≥ 2 (v2 template + `/review-inline`); `/review-arch` template untouched
    — **Consumers affected:** deployed-command users; `worktree-pipeline-skill` docs (2.2)
- [ ] **2.2** Update `skills/worktree-pipeline-skill/SKILL.md` Step 1 soft-dep line and Step 7: inline arm routes architecture review to skill `architecture-review-skill` in-session; v1 arm text unchanged
    — **Why:** the skill doc is the pipeline's behavioral contract — the command template and the skill must not disagree
    — **Done when:** Step 7 names the inline-arm skill route; v1 Task-call text for `architecture-review-subagent` remains verbatim
    — **Consumers affected:** pipeline runs in both arms

### Phase 3: Installer closure + registry
- [ ] **3.1** Add `"architecture-review-skill": ["reviewer-baseline-skill"]` to `installer/dependency-map.json` `requiresSkills` and add `architecture-review-skill` to `installer/presets/pack-inline-workers.json` skills array; update the preset `$comment` and description to cover the arch-review wrapper
    — **Why:** `npx add architecture-review-skill` must pull its runtime baseline, and the `inline-workers` preset is the documented opt-in pack for the v2 arm
    — **Done when:** both JSON files parse (`node -e` JSON.parse) and contain the entries
    — **Consumers affected:** `installer/init.mjs`, fresh per-skill installs
- [ ] **3.2** Run `node installer/build-registry.mjs` and stage the regenerated `installer/registry.json` (single rebuild — all frontmatter is final after 1.1/1.2)
    — **Why:** frontmatter contract: registry must match skill+agent frontmatter; regenerated artifacts must not be left unstaged
    — **Done when:** `installer/registry.json` diff contains the new skill entry and the updated agent permissions; file staged
    — **Consumers affected:** `installer/init.mjs` install-time warnings

### Phase 4: Docs sync + verification
- [ ] **4.1** Update `README.md`: Code Quality row 15→16 with `architecture-review-skill` listed, total skill count wherever stated, inline-workers pack line (95) naming the arch wrapper, and the line-24 "loading the deployed agent definitions as checklists" wording to reflect the skill-driven arch review
    — **Why:** README is the usage-docs home; stale counts are the #1 doc-drift class in this repo
    — **Done when:** README states the new count and the line-24 sentence describes skill-driven arch review; `grep -c "architecture-review-skill" README.md` ≥ 3
    — **Consumers affected:** none (docs)
- [ ] **4.2** Verify `deploy/setup.sh` + `deploy/setup.ps1` carry no hardcoded skill counts (`count_skills` is dynamic) — record the finding instead of editing when dynamic
    — **Why:** ticket AC names setup counts; if they are computed, "updated" means verified-not-stale, and an edit would be make-work
    — **Done when:** grep for hardcoded skill totals in both scripts returns none, noted in the phase commit message
    — **Consumers affected:** none (verification)
- [ ] **4.3** Run the full verification set: `tests/test_skill_isolation.bats`, `node installer/build-registry.mjs` idempotence (no diff), AC greps (no agent-file load in v2 paths; `/review-arch` + v1 Step 7 intact)
    — **Why:** exit-gate evidence for the ticket ACs
    — **Done when:** bats suite exits 0; registry rebuild is a no-op; all AC greps return the expected result
    — **Consumers affected:** Step 9 code review, Step 10 PR citation

## Technical Notes
- Guard semantics (verified in `tests/test_skill_isolation.bats`): sibling-skill violations trigger only on path refs inside fenced code blocks of SKILL.md — prose mentions are documentation. The new skill needs NO new HANDOFF entry.
- `deploy/setup.sh:4636` computes the skill count via `count_skills` — dynamic, nothing to bump (step 4.2 verifies).
- Subagent frontmatter: keep `mode: subagent`, `steps: 40`, all existing permissions except the one added skill allow.
- The v1 arm (`/run-worktree-pipeline`) and `/review-arch` keep spawning the (thin) subagent — isolated-context review stays available; deletion of the subagent is explicitly out of scope (thin-orchestrator decision, #650 discussion).
- Skill content source of truth: current `agents/architecture-review-subagent.md` body (baseline-first, blast-radius gate, plan atomicity, return contract) restructured to the `uiux-review-skill` section pattern (what/when → methodology → decision tree → axes → gates → schema → severity → references).

## Dependencies
None — single ticket, no `blocked-by`.

## Risks & Mitigation
- **Drift between skill and subagent bodies** → 1.2 makes the subagent a pointer, not a copy; code review (Step 9) diffs for restated rubric text.
- **Command template regressions breaking deployed commands** → 2.1 touches only the v2 template + `/review-inline` sentences; `/review-arch` and `/run-worktree-pipeline` (v1) are grep-verified untouched in 4.3.
- **Registry drift** → single rebuild at 3.2 after frontmatter is final + idempotence check at 4.3.
