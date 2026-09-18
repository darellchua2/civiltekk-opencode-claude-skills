# PLAN: Pipeline-mode PR handoff; fix read-only refactor delegation

**Branch**: feat/399
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/399
**Base**: main

## Acceptance Criteria

- [ ] Step 10 Task prompt instruction in `worktree-pipeline-skill` switched to pipeline mode: skip pr-workflow steps 2 / 2.5 / 4 — gates verified by run-plan, docstrings filled per-phase, PLAN ticked+committed; `gh pr checks --watch` is the merge gate; agent's job reduces to PR create (`Closes <TICKET_ID>`) + JIRA link
- [ ] `pr-workflow-subagent.md` gains a pipeline-mode conditional (parent states gates green → skip 2 / 2.5 / 4, proceed to PR creation) so the skip is agent-side, not prompt-only; standalone behavior unchanged
- [ ] Refactor/DRY delegation in `plan-automation-loop-skill` delegate matrix AND `plan-execution-skill` Step 4 + Subagents line → "Handle directly"; `code-review-subagent` remains review-only
- [ ] `node installer/build-registry.mjs --check` exits 0, no drift, `installer/registry.json` unmodified
- [ ] `CHANGELOG.md` untouched (release-automation owns it)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `agents/pr-workflow-subagent.md` (body) | paired wording with worktree-pipeline Step 10 (same commit) | OpenCode runtime sessions; worktree-pipeline Step 10 Task prompts; standalone "create pr" callers (must stay unchanged); `installer/registry.json` derivation (description unchanged → zero diff expected) | med |
| `skills/worktree-pipeline-skill/SKILL.md` (Step 10) | paired pipeline-mode line in pr-workflow-subagent (same commit) | primary orchestrator sessions running `/run-worktree-pipeline` | med |
| `skills/plan-automation-loop-skill/SKILL.md` (delegate matrix) | sibling consistency with plan-execution Step 4 | `/run-plan` executors; worktree-pipeline Step 8 | low |
| `skills/plan-execution-skill/SKILL.md` (Step 4 + Subagents line) | sibling consistency with plan-automation-loop matrix | interactive phase-by-phase executors | low |
| `installer/registry.json` | derived artifact — must NOT change | installer init/add; CI drift gate | low |

Cross-module contract: the two Step-10 surfaces form one behavioral pair; the two plan skills form a second pair. Registry is derived.

## Implementation Phases

### Canonical step format
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: Pipeline-mode PR handoff contract
- [x] **1.1** Add the pipeline-mode conditional to `agents/pr-workflow-subagent.md` — a short block after the Workflow list: parent states gates are green (pipeline mode, e.g. worktree-pipeline Step 10 after `/run-plan`) → skip steps 2, 2.5, and 4 (gate ran per-phase upstream, docstrings filled before the gate, PLAN ticked+committed; `gh pr checks` is the merge gate) and proceed via step 1 (framework detect) → step 5 (PR create) → step 6 (JIRA link); explicitly note standalone callers keep the full workflow; the block ends with the supersede sentence: "In pipeline mode this skip supersedes every other restatement of steps 2/2.5/4 in this file (the PLAN.md Sync section, the docstring-sweep delegation bullet, the closing gates line) — those apply on the standalone path only."
    — **Why:** makes the skip agent-side so it holds even when a Task prompt omits it; without the supersede sentence, three non-numbered clauses (PLAN.md Sync, docstring-sweep bullet, closing gates line) keep restating the skipped steps and the redundancy survives the fix
    — **Done when:** the block appears verbatim-intent after the workflow list, names steps 2/2.5/4, names the merge gate, contains the standalone-unchanged clause, and the supersede sentence names all three restating clauses; no text outside the added block changes
    — **Consumers affected:** worktree-pipeline Step 10 Task prompts; standalone "create pr" callers (unchanged by default)
    — **Done:** pipeline-mode block added after the workflow list (steps 2/2.5/4 skip, merge gate, standalone clause, supersede sentence naming all three restating clauses); no text outside the block changed; files: agents/pr-workflow-subagent.md; fixes: none
- [x] **1.2** Replace the Step 10 mandate parenthetical in `skills/worktree-pipeline-skill/SKILL.md` — "(its step 2.5 docstring sweep and PLAN.md sync run as part of it)" → pipeline-mode instruction: the Task prompt MUST state gates are green and instruct pr-workflow to skip its steps 2 / 2.5 / 4 (verified by run-plan per phase; CI watch below is the merge gate)
    — **Why:** the current text mandates the exact redundancy the ticket removes; 1.1 and 1.2 are one contract and land together
    — **Done when:** the old parenthetical phrase no longer appears anywhere in the file; the new text instructs the skip and defers the merge decision to the CI gate sentence that follows it
    — **Consumers affected:** primary sessions executing `/run-worktree-pipeline`
    — **Done:** old parenthetical removed; Step 10 now carries the pipeline-mode instruction (gates-green assertion + skip 2/2.5/4 + CI gate as merge decision); files: skills/worktree-pipeline-skill/SKILL.md; fixes: none

### Phase 2: Fix read-only refactor delegation
- [ ] **2.1** Change the Refactor / DRY row of the delegate matrix in `skills/plan-automation-loop-skill/SKILL.md` from `code-review-subagent` to "Handle directly" with the reason in-row (code-review-subagent is read-only: `edit`/`bash` deny; it reviews at pipeline Step 9)
    — **Why:** the row assigns implementation work to an agent that cannot edit files or run commands, and double-spawns it against its Step 9 review role
    — **Done when:** the matrix row reads Handle directly with the read-only reason; no other row changes
    — **Consumers affected:** `/run-plan` executors; code-review-subagent invocations (now review-only)
- [ ] **2.2** Apply the same fix to `skills/plan-execution-skill/SKILL.md`: Step 4 delegation list drops `code-review-subagent` for refactor/clean (→ handle directly, review-only note), and the Subagents line lists `testing-subagent` (tests) · `documentation-subagent` (docs) only, parent handles refactor/clean + build/deploy/git
    — **Why:** the soft sibling carries the identical broken row; leaving it would resurrect the defect on the interactive path
    — **Done when:** Step 4 and the Subagents line contain no refactor/clean → code-review-subagent delegation; both siblings agree
    — **Consumers affected:** interactive phase-by-phase executors

### Phase 3: Verification gate + no-drift proof
- [ ] **3.1** Run `node installer/build-registry.mjs --check` in the worktree and prove zero drift
    — **Why:** agent-body edits must not perturb the derived registry; this is the ticket's explicit acceptance criterion
    — **Done when:** command exits 0 reporting no drift and `git status --porcelain` shows no `installer/registry.json` modification
    — **Consumers affected:** none (read-only proof)
- [ ] **3.2** Prove the diff scope: `git diff --name-only origin/main...feat/399` lists exactly the 4 edited files plus `PLANS/PLAN-399.md` (no `CHANGELOG.md`, no `installer/registry.json`), and three pinned retired strings grep to zero outside PLANS/: `git grep -F -e 'docstring sweep and PLAN.md sync' -- ':!PLANS'`; `git grep -F -e '| Refactor / DRY | `code-review-subagent` |' -- ':!PLANS'`; `git grep -F -e 'refactor/clean → `code-review-subagent`' -- ':!PLANS'` (phrase 1 uses the wrap-tolerant anchor — the live text wraps across lines; never grep the bare `code-review-subagent` token — legitimate review-role mentions remain)
    — **Why:** the ticket's CHANGELOG-untouched criterion and the contract-pair wording need mechanical proof that cannot self-match the PLAN file (which quotes the retired phrases) nor pass vacuously on wrapped text
    — **Done when:** the 5-file list matches exactly and all three scoped greps return empty
    — **Consumers affected:** none (read-only proof)
- [ ] **3.3** Attempt the bats suite (`bats tests/`); runner is absent on this machine — record INCONCLUSIVE with that reason, do not install unprompted
    — **Why:** run-plan's gate rule forbids silently skipping a discoverable check; the diff touches no shell so INCONCLUSIVE is the honest verdict
    — **Done when:** the verdict INCONCLUSIVE + reason is written into the phase report
    — **Consumers affected:** none

## Technical Notes

- Gate mapping for this repo (no npm scripts, no Makefile): LINT/TYPECHECK/BUILD → no configured commands — INCONCLUSIVE, substituted by registry `--check` as the structural gate; UNIT → bats (absent locally → INCONCLUSIVE per 3.3); CI on PRs runs no test workflow, so Step 10 takes the zero-configured-checks merge path with note.
- LEARNING `task-delegate-permission-sync` Rule 2: delegation step wording must respect the delegate's permission ceiling — pipeline mode REMOVES delegation rather than re-wording it, so no ceiling violation is possible.
- LEARNING `doc-claims-match-plugin-defaults`: new wording states actual runtime behavior (skip is conditional on parent assertion; default standalone path unchanged).

## Dependencies

None. Follow-up to #351, #366, #350, #397 (all closed).

## Risks & Mitigation

- Wording drift between the Step-10 surfaces (1.1 vs 1.2) → paired in one phase, one commit, reviewed together.
- Registry drift if edits leak into frontmatter → body-only edits + 3.1 gate.
- Pipeline mode misread as a global behavior change → explicit standalone-unchanged clause in 1.1.
