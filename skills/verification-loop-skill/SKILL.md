---
name: verification-loop-skill
description: "Canonical verification-gate contract — command discovery, gate order (lint, typecheck, build, unit, e2e), scoped-lint rule, INCONCLUSIVE handling, gate memo. Triggers: verification gate, gate memo, verify implementation. Pipeline skills defer here instead of restating gates. Scoring rubrics: eval-harness-skill."
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: Agent Optimization
---

## What I do

I am the **canonical verification-gate contract** for this estate. Pipeline surfaces defer here instead of restating gate tables — compose, don't duplicate.

## The gate contract

### Gate sequence (in order)

LINT → TYPECHECK → BUILD → UNIT → E2E. E2E runs only per the E2E rule: Playwright configured (`playwright.config.*` + `@playwright/test`) AND the change touched frontend code. Backend-only change → skip e2e and say so.

### Command discovery (once per run)

Discover commands from project manifests in this order: `package.json` scripts → `Makefile` → `pyproject.toml` → README. Never invent commands. A gate whose command cannot be found is `INCONCLUSIVE` — never silently skipped; install/repair, substitute the closest executable check, or stop and report.

### Pass semantics

- **Lint = zero NEW errors on changed files** (scoped rule; repo-wide zero-error sweeps are CI's job, not the local gate's).
- Record one verdict per run: `VERIFIED` (all applicable gates ran green, output captured) / `NOT VERIFIED` (a gate failed) / `INCONCLUSIVE` (a gate could not run).
- **INCONCLUSIVE is NOT a pass** — advance only on `VERIFIED`.

### Gate memo

After every green gate, write one line into the PLAN trace block (or task record when no PLAN exists):

```
GATE <short-sha> lint=t typecheck=t build=t unit=t e2e=<t|-|n.a>
```

- Same tree SHA already green since the last gate → later pipeline stages skip the re-run and state it.
- No memo for the current SHA → run the gates. Skipping on absent evidence is forbidden.
- CI (`gh pr checks`) remains the only unconditional re-run (post-push).

### Who defers here

| Surface | Role under this contract |
|---------|--------------------------|
| `plan-execution-skill` (--gate) | Runs the gate per PLAN phase; writes the memo |
| `pr-creation-workflow-skill` | PR-boundary memo check; fills the PR Quality Checks slot from memo/assertion |
| `worktree-pipeline-skill` | Sequences phases; its green assertion cites the final GATE line for the pushed SHA |
| `pr-workflow-subagent` | Executes PR checks via this contract; owns no command table |
| `linting-subagent` | Lint execution; `language-linting-skill` is its rules reference |
| `eval-harness-skill` | Scoring rubrics only — not gate execution |

## Requirements verification (secondary role)

Beyond the gate, verify implementations against acceptance criteria: parse criteria from the issue/PLAN, map each to code, check each with evidence, report PASS/FAIL/SKIP per criterion, iterate until green. Write criteria that are specific, measurable, binary, and evidence-based ("Returns HTTP 401 for invalid credentials", not "Handles errors").

**Triggers**: verify implementation, check against requirements, run verification, validate against criteria, checkpoint, verification gate, gate memo.

## Integration

- `eval-harness-skill` — score-based evaluation rubrics
- `error-resolver-workflow-skill` — failure diagnosis when a gate goes red
- `git-semantic-commits-skill` — commit discipline the gate protects
- `plan-execution-skill` (--update) — PLAN progress ticks

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

1. **Gate check**: confirm env var is set; if unset, follow default behavior above.
2. **Auto-detection**: if this skill is invoked on a task that looks iterative (multiple cycles expected), prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". On "y", continue; on "n", default behavior. Cache the answer for the session.
3. **5-stage loop**: cycle Understand → Hypothesize → Experiment → Evaluate → Log & Iterate. See `autoresearch-core-skill/SKILL.md`.
4. **Evaluator contract**: emit `{"pass":bool,"score":N}` JSON from a mechanical evaluator. Pass determines keep/revert; score logged to `verification-loop-results.tsv`. See `autoresearch-core-skill/references/evaluator-contract.md`.
5. **Stuck detection**: 3 consecutive non-improving iterations → strategy pivot; 5 consecutive → paradigm shift. See `autoresearch-core-skill/references/stuck-detection.md`.
6. **Audit trail**: append every iteration to `verification-loop-results.tsv` (8-column: iteration, commit, metric, delta, status, description, timestamp, evaluator_output). See `autoresearch-core-skill/references/audit-trail.md`.
7. **Crash recovery**: syntax errors → fix immediately (don't count); runtime → max 3 fix attempts then skip; timeout → revert + log; OOM → smaller variant. See `autoresearch-core-skill/references/crash-recovery.md`.
8. **Git-as-memory**: commit before each verify; auto-revert (`git reset --hard HEAD~1`) on `pass:false`.
9. **Iteration safety**: bounded-by-default (`Iterations: 25`); safety blocks `.env`, `node_modules/`, `rm -rf`, `git push --force`. See `autoresearch-core-skill/references/iteration-safety.md`.

### Skill-specific override

**Evaluator contract replaces LLM self-judgment.** The agent MUST produce `{"pass":bool,"score":N}` from the verification target (test runner output, typecheck result, lint exit code) instead of subjective self-assessment. Subjective phrasing like 'looks good' or 'passes review' is FORBIDDEN when protocol is enabled.

### Max iterations
- Default: 25 iterations
- Hard cap: 100 (explicit `Iterations: unlimited` overrides)
