# PLAN: End per-phase PLAN tick commits in run-plan + pipeline

**Branch**: feat/550
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/550
**Base**: main

## Acceptance Criteria
- [x] "Optional hash-trace: two commits" sentence removed from plan-execution-skill
- [x] `--gate` 4f explicitly forbids standalone `docs(plan)` commits mid-run
- [x] `--soft` Step 3 defers PLAN commits to a single end-of-run tick commit
- [x] `--update` commits only on standalone invocation (sync-only as subroutine)
- [x] worktree-pipeline Step 9 folds re-ticks into existing commits
- [x] Guarantees section documents the no-tick-commit rule
- [x] `grep -rn "hash-trace" skills/ tests/` returns empty; no frontmatter changes (no registry regen)

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/plan-execution-skill/SKILL.md` | — | executing agents (`/run-plan`, `/goal`), worktree-pipeline-skill Step 8, README `/run-plan` blurb, `opencode_app/opencode.json` run-plan description, `tests/test_plan_executor.bats` | low (prose contract) |
| `skills/worktree-pipeline-skill/SKILL.md` | Phase 1 wording it cites | orchestrator sessions (`/run-worktree-pipeline`), `agents/pr-workflow-subagent.md` pipeline-mode note | low (prose contract) |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: plan-execution-skill — fold ticks into work commits; defer --soft ticks to ticket end
- [x] **1.1** Remove the "Optional hash-trace: two commits" sentence from §Traceability
    — **Why:** it is the only documented source of standalone per-phase tick commits in `--gate` mode
    — **Done when:** `grep -c "hash-trace" skills/plan-execution-skill/SKILL.md` returns 0
    — **Consumers affected:** `--gate` executors that used the two-commit trace variant
    — **Done:** sentence removed; files: skills/plan-execution-skill/SKILL.md; fixes: none
- [x] **1.2** Amend §Commit + push (4f) so PLAN ticks ride inside the phase's atomic commit and a standalone `docs(plan)` commit mid-run is named a violation
    — **Why:** makes the no-tick-commit rule explicit at the only place `--gate` commits
    — **Done when:** the section states PLAN updates commit together with phase files and contains an explicit "never" prohibition on a standalone `docs(plan)` commit mid-run
    — **Consumers affected:** `--gate` executors; worktree-pipeline-skill Step 8
    — **Done:** 4f states ticks/Done lines/memos ride the atomic commit and standalone docs(plan) mid-run is "never allowed"; files: skills/plan-execution-skill/SKILL.md; fixes: none
- [x] **1.3** Rewrite `--soft` Step 3 to tick checkboxes and write Done lines in the working tree with no commit, deferring all PLAN updates to one trailing `docs(plan): tick` commit at end of run
    — **Why:** `--soft` has no auto-commit cadence; invoking `--update` per phase manufactured a `docs(plan)` commit per phase
    — **Done when:** Step 3 text says no commit per phase and names the single end-of-run tick commit
    — **Consumers affected:** `--soft` interactive runs
    — **Done:** Step 3 retitled "Tick per phase, commit once at the end" with the exact trailing-commit command; files: skills/plan-execution-skill/SKILL.md; fixes: none
- [x] **1.4** Add the subroutine rule to `--update`: invoked from `--soft`/`--gate` it syncs checkboxes only and skips its step-6 commit; standalone use keeps the commit
    — **Why:** `--update` is reusable by both modes; without a caller-aware rule the per-phase commit returns via the side door
    — **Done when:** the `--update` workflow shows a commit-suppression condition tied to invocation context
    — **Consumers affected:** worktree-pipeline-skill Step 8; `--soft` Step 3 callers
    — **Done:** step 6 retitled "Commit — standalone only" with the subroutine suppression and caller-ownership note; files: skills/plan-execution-skill/SKILL.md; fixes: none

### Phase 2: worktree-pipeline-skill — orchestrator-side fold + guarantee
- [x] **2.1** Amend Step 9 so post-exit-gate PLAN re-ticks fold into the review-fix commit or the `chore(learnings)` commit, never their own commit
    — **Why:** review fixes are the only post-run-plan mutation that could re-tick the PLAN
    — **Done when:** Step 9 text names folding re-ticks into the existing fix/learnings commit
    — **Consumers affected:** pipeline review-fix loops; PR reviewers
    — **Done:** LEARNINGS block extended — re-ticks (gate-memo append, Done-line updates) fold into the review-fix/learnings commit; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **2.2** Add a Guarantees bullet: no standalone tick/progress commits at any step; squash merge keeps PLAN noise out of release notes
    — **Why:** Guarantees is the skill's enforced-behavior summary audited by reviewers and users
    — **Done when:** the Guarantees section contains the no-tick-commit bullet
    — **Consumers affected:** pipeline users auditing release notes
    — **Done:** Guarantees bullet added citing Step 8 phase-commit folding, Step 9 review-fix folding, and the squash-merge shield; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none

### Phase 3: verification sweep
- [x] **3.1** Grep sweep: `hash-trace` absent repo-wide, new rule sentences present in both skills, `tests/test_plan_executor.bats` + `tests/test_portability.bats` green
    — **Why:** the ticket's final AC couples text removal with test greenness
    — **Done when:** `grep -rn "hash-trace" skills/ tests/` returns nothing and both bats files pass
    — **Consumers affected:** CI; skill consumers
    — **Done:** hash-trace sweep empty repo-wide; 4 new rule sentences confirmed (2 per skill); frontmatter diff empty (no registry regen); full bats suite 564 ok / 0 failed; files: PLANS/PLAN-550.md (verification only); fixes: none

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

GATE ccac64d tier=light lint=t typecheck=n.a build=n.a unit=t e2e=n.a
GATE 4277e02 tier=light lint=t typecheck=n.a build=n.a unit=t e2e=n.a
GATE f543640 tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a
GATE 25e940a tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a

## Review round 1 (code-review-subagent)

0 Critical / 2 Major / 4 Minor. Fixed (in review-fix commit): Major 1 — Modes-table `--soft` row "no auto-commit" contradicted the new trailing tick commit under the line-23 supremacy clause → row now names the single end-of-run commit; Major 2 — `--update` step 6's caller enumeration was dead in the same diff (per Mode R relay ruling B: context-keyed definition, agent end-of-workflow syncs stay standalone) → replaced with a run-context signal, never a caller list; Minor 1 — `--update` Modes-table row now reads "commit (standalone use only)". Skipped by judgment: Minor 2 (AC placement — substance met in §Commit + push), Minor 3 (documentation-consistency pointer — out of diff), Minor 4 (file-level bash note — file-wide convention, portability guard green). Requirements Gaps relayed to requirements-specialist Mode R and resolved: agent wording (pr-workflow/tdd/testing) ruled OUT of scope, accurate as written. LEARNINGS: 1 new anti-pattern (`enumerated-subroutine-callers-go-stale.md`); 2 reviewer dedup bumps void on this branch (target files absent at base).
