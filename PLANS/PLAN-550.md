# PLAN: End per-phase PLAN tick commits in run-plan + pipeline

**Branch**: feat/550
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/550
**Base**: main

## Acceptance Criteria
- [ ] "Optional hash-trace: two commits" sentence removed from plan-execution-skill
- [ ] `--gate` 4f explicitly forbids standalone `docs(plan)` commits mid-run
- [ ] `--soft` Step 3 defers PLAN commits to a single end-of-run tick commit
- [ ] `--update` commits only on standalone invocation (sync-only as subroutine)
- [ ] worktree-pipeline Step 9 folds re-ticks into existing commits
- [ ] Guarantees section documents the no-tick-commit rule
- [ ] `grep -rn "hash-trace" skills/ tests/` returns empty; no frontmatter changes (no registry regen)

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/plan-execution-skill/SKILL.md` | — | executing agents (`/run-plan`, `/goal`), worktree-pipeline-skill Step 8, README `/run-plan` blurb, `opencode_app/opencode.json` run-plan description, `tests/test_plan_executor.bats` | low (prose contract) |
| `skills/worktree-pipeline-skill/SKILL.md` | Phase 1 wording it cites | orchestrator sessions (`/run-worktree-pipeline`), `agents/pr-workflow-subagent.md` pipeline-mode note | low (prose contract) |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: plan-execution-skill — fold ticks into work commits; defer --soft ticks to ticket end
- [ ] **1.1** Remove the "Optional hash-trace: two commits" sentence from §Traceability
    — **Why:** it is the only documented source of standalone per-phase tick commits in `--gate` mode
    — **Done when:** `grep -c "hash-trace" skills/plan-execution-skill/SKILL.md` returns 0
    — **Consumers affected:** `--gate` executors that used the two-commit trace variant
- [ ] **1.2** Amend §Commit + push (4f) so PLAN ticks ride inside the phase's atomic commit and a standalone `docs(plan)` commit mid-run is named a violation
    — **Why:** makes the no-tick-commit rule explicit at the only place `--gate` commits
    — **Done when:** the section states PLAN updates commit together with phase files and contains an explicit "never" prohibition on a standalone `docs(plan)` commit mid-run
    — **Consumers affected:** `--gate` executors; worktree-pipeline-skill Step 8
- [ ] **1.3** Rewrite `--soft` Step 3 to tick checkboxes and write Done lines in the working tree with no commit, deferring all PLAN updates to one trailing `docs(plan): tick` commit at end of run
    — **Why:** `--soft` has no auto-commit cadence; invoking `--update` per phase manufactured a `docs(plan)` commit per phase
    — **Done when:** Step 3 text says no commit per phase and names the single end-of-run tick commit
    — **Consumers affected:** `--soft` interactive runs
- [ ] **1.4** Add the subroutine rule to `--update`: invoked from `--soft`/`--gate` it syncs checkboxes only and skips its step-6 commit; standalone use keeps the commit
    — **Why:** `--update` is reusable by both modes; without a caller-aware rule the per-phase commit returns via the side door
    — **Done when:** the `--update` workflow shows a commit-suppression condition tied to invocation context
    — **Consumers affected:** worktree-pipeline-skill Step 8; `--soft` Step 3 callers

### Phase 2: worktree-pipeline-skill — orchestrator-side fold + guarantee
- [ ] **2.1** Amend Step 9 so post-exit-gate PLAN re-ticks fold into the review-fix commit or the `chore(learnings)` commit, never their own commit
    — **Why:** review fixes are the only post-run-plan mutation that could re-tick the PLAN
    — **Done when:** Step 9 text names folding re-ticks into the existing fix/learnings commit
    — **Consumers affected:** pipeline review-fix loops; PR reviewers
- [ ] **2.2** Add a Guarantees bullet: no standalone tick/progress commits at any step; squash merge keeps PLAN noise out of release notes
    — **Why:** Guarantees is the skill's enforced-behavior summary audited by reviewers and users
    — **Done when:** the Guarantees section contains the no-tick-commit bullet
    — **Consumers affected:** pipeline users auditing release notes

### Phase 3: verification sweep
- [ ] **3.1** Grep sweep: `hash-trace` absent repo-wide, new rule sentences present in both skills, `tests/test_plan_executor.bats` + `tests/test_portability.bats` green
    — **Why:** the ticket's final AC couples text removal with test greenness
    — **Done when:** `grep -rn "hash-trace" skills/ tests/` returns nothing and both bats files pass
    — **Consumers affected:** CI; skill consumers

## Technical Notes
- Markdown-only edits; no SKILL.md frontmatter keys change → `node installer/build-registry.mjs` regen not required (registry.json derives from frontmatter).
- README `/run-plan` blurb, `opencode_app/opencode.json` run-plan description, and `agents/pr-workflow-subagent.md` ("PLAN is ticked and committed") remain accurate with folded ticks — no restatement edits.
- The single trailing tick commit is the only `docs(plan)` commit a `--soft` run produces; worktree-pipeline 6e's PLAN pre-push is unchanged.

## Dependencies
None — standalone prose-contract change.

## Risks & Mitigation
- Agent drift back toward per-phase `--update` commits → mitigated by the explicit prohibition in 4f and the `--update` subroutine rule (1.2, 1.4).
- Existing in-flight runs may still emit one legacy tick commit → acceptable; subsequent runs are clean.

## Gate memos
_(gate memos appended here by /run-plan --gate)_
