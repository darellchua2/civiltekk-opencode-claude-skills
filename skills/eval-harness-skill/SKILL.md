---
name: eval-harness-skill
description: Evaluate code quality, skill effectiveness, and implementation correctness against defined criteria with scoring and improvement suggestions
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: Agent Optimization
---

## What I do

I provide a structured evaluation framework to assess code, skills, and implementations:

1. **Define Evaluation Criteria**: Establish measurable quality benchmarks for code or skill output
2. **Execute Evaluations**: Run automated checks against defined criteria with scoring
3. **Score Results**: Generate quantitative scores with qualitative feedback
4. **Identify Gaps**: Highlight areas below threshold with specific improvement suggestions
5. **Track Progress**: Compare scores across iterations to measure improvement

## When to use me

Use this skill when:
- You want to evaluate the quality of generated code against best practices
- You need to assess if a skill or agent is producing correct, high-quality output
- You want to benchmark code quality before and after refactoring
- You need to verify that implementation meets acceptance criteria
- You want to establish quality gates for PRs or deployments

**Trigger phrases**:
- "evaluate this code"
- "run eval"
- "score this implementation"
- "quality check"
- "benchmark against criteria"

## Core Workflow

### Step 1: Define Evaluation Criteria

Establish what "good" looks like for the evaluation target:

```markdown
## Evaluation Criteria

### Correctness (0-10)
- Does the code do what it's supposed to do?
- Are edge cases handled?
- Are error paths covered?

### Code Quality (0-10)
- Follows language/framework conventions?
- Clean, readable, maintainable?
- Proper abstractions without over-engineering?

### Test Coverage (0-10)
- Are tests present and comprehensive?
- Do tests cover edge cases?
- Are tests maintainable?

### Performance (0-10)
- Efficient algorithms and data structures?
- No unnecessary computations?
- Proper caching where applicable?

### Security (0-10)
- Input validation?
- No injection vulnerabilities?
- Proper auth/authz?
```

### Step 2: Configure Evaluation Scope

Define what to evaluate:

| Scope | Description | Example |
|-------|-------------|---------|
| **Single File** | Evaluate one file | `eval src/auth/login.ts` |
| **Module** | Evaluate a directory/module | `eval src/auth/` |
| **Skill Output** | Evaluate what a skill produces | `eval skill:tdd-workflow` |
| **PR Diff** | Evaluate changes in a PR | `eval pr:42` |
| **Acceptance Criteria** | Check against issue requirements | `eval issue:150` |

### Step 3: Execute Evaluation

Run the evaluation checks:

1. **Static Analysis**: Lint, type-check, complexity metrics
2. **Pattern Analysis**: Check against known patterns and anti-patterns
3. **Test Execution**: Run tests and analyze coverage
4. **Criteria Matching**: Score each criterion against the defined rubric
5. **Gap Analysis**: Identify specific areas below threshold

### Step 4: Generate Report

Produce a structured evaluation report:

```markdown
## Evaluation Report

**Target**: src/auth/login.ts
**Date**: 2024-01-25
**Evaluator**: eval-harness

### Summary
| Criterion | Score | Threshold | Status |
|-----------|-------|-----------|--------|
| Correctness | 8/10 | 7/10 | PASS |
| Code Quality | 7/10 | 7/10 | PASS |
| Test Coverage | 5/10 | 7/10 | FAIL |
| Performance | 9/10 | 6/10 | PASS |
| Security | 6/10 | 7/10 | FAIL |

### Overall: 35/50 (70%) — NEEDS IMPROVEMENT

### Detailed Findings

#### Test Coverage (5/10) — FAIL
- Missing: Error path tests for network failures
- Missing: Edge case test for expired tokens
- Suggestion: Add tests for `handleAuthError()` failure cases

#### Security (6/10) — FAIL
- Issue: Password not hashed before comparison (line 42)
- Issue: Session token stored in localStorage (vulnerable to XSS)
- Suggestion: Use httpOnly cookies for session management
```

### Step 5: Suggest Improvements

For each failing criterion, provide actionable improvements:

- **Priority**: Critical / High / Medium / Low
- **Effort**: Estimated effort to fix
- **Impact**: Expected score improvement
- **Guidance**: Specific steps to fix

## Evaluation Templates

### Code Quality Evaluation

```markdown
## Criteria
- Naming conventions (snake_case, camelCase per language)
- Function length (max 20 lines recommended)
- Class size (max 200 lines recommended)
- Complexity (cyclomatic < 10)
- Duplication (DRY principle)
- Error handling (no silent catches)
```

### Skill Effectiveness Evaluation

```markdown
## Criteria
- Task completion (does it achieve the goal?)
- Output quality (is the result production-ready?)
- Consistency (same input → same quality output?)
- Edge case handling (does it fail gracefully?)
- Integration (works with other skills/agents?)
```

### Acceptance Criteria Evaluation

```markdown
## Criteria (from issue/plan)
- Each acceptance criterion checked off
- Evidence provided for each check
- No partial completions
- No regressions introduced
```

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `verification-loop` | Eval provides criteria, verification enforces them continuously |
| `continuous-learning` | Eval results feed into learning (what patterns score well) |
| `strategic-compact` | Compact preserves evaluation results for context |
| `linting-workflow` | Eval incorporates lint results as a sub-criterion |
| `code-smells` | Eval uses code smell detection as quality signals |
| `solid-principles` | Eval checks SOLID compliance as code quality criterion |

## Scoring Guidelines

### Score Ranges

| Range | Label | Description |
|-------|-------|-------------|
| 9-10 | Excellent | Production-ready, exemplary implementation |
| 7-8 | Good | Solid work, minor improvements possible |
| 5-6 | Adequate | Functional but needs improvement |
| 3-4 | Below Standard | Significant issues, needs rework |
| 1-2 | Poor | Major problems, needs complete rewrite |
| 0 | Failed | Does not meet minimum requirements |

### Threshold Defaults

| Criterion | Default Threshold |
|-----------|-------------------|
| Correctness | 7/10 |
| Code Quality | 7/10 |
| Test Coverage | 7/10 |
| Performance | 6/10 |
| Security | 7/10 |

Thresholds can be customized per project or per evaluation run.

## Best Practices

### Defining Good Criteria
- Make criteria **measurable**: use numbers, not subjective terms
- Make criteria **specific**: "Functions under 20 lines" not "Clean code"
- Make criteria **relevant**: only evaluate what matters for the context
- Make criteria **consistent**: same criteria across similar evaluations

### Running Evaluations
- Run evaluations **iteratively**: evaluate, fix, re-evaluate
- Compare scores **across runs**: track improvement over time
- Use evaluations **as gates**: don't merge PRs that fail evaluation
- Document **exceptions**: if a criterion doesn't apply, note why

### Interpreting Results
- Focus on **trends**, not absolute scores
- Prioritize **failing criteria** over improving passing ones
- Consider **context**: a prototype doesn't need production quality
- Balance **speed and quality**: don't over-optimize scores

## Example Usage

### Evaluate a module before PR

```
"Run eval on src/auth/ before I create the PR"
```

The skill will:
1. Define criteria based on module purpose
2. Run static analysis, pattern checks, test coverage
3. Score each criterion
4. Generate report with pass/fail and suggestions
5. Block PR creation if any critical criterion fails

### Evaluate skill output quality

```
"Evaluate the output of tdd-workflow skill"
```

The skill will:
1. Define skill effectiveness criteria
2. Analyze recent skill output
3. Score consistency, completeness, quality
4. Suggest skill improvements

## References

- `verification-loop` - Continuous verification during implementation
- `continuous-learning` - Learn from evaluation results
- `strategic-compact` - Preserve eval context during compaction

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

1. **Gate check**: confirm env var is set; if unset, follow default behavior above.
2. **Auto-detection**: if this skill is invoked on a task that looks iterative (multiple cycles expected), prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". On "y", continue; on "n", default behavior. Cache the answer for the session.
3. **5-stage loop**: cycle Understand → Hypothesize → Experiment → Evaluate → Log & Iterate. See `autoresearch-core-skill/SKILL.md`.
4. **Evaluator contract**: emit `{"pass":bool,"score":N}` JSON from a mechanical evaluator. Pass determines keep/revert; score logged to `eval-harness-results.tsv`. See `autoresearch-core-skill/references/evaluator-contract.md`.
5. **Stuck detection**: 3 consecutive non-improving iterations → strategy pivot; 5 consecutive → paradigm shift. See `autoresearch-core-skill/references/stuck-detection.md`.
6. **Audit trail**: append every iteration to `eval-harness-results.tsv` (8-column: iteration, commit, metric, delta, status, description, timestamp, evaluator_output). See `autoresearch-core-skill/references/audit-trail.md`.
7. **Crash recovery**: syntax errors → fix immediately (don't count); runtime → max 3 fix attempts then skip; timeout → revert + log; OOM → smaller variant. See `autoresearch-core-skill/references/crash-recovery.md`.
8. **Git-as-memory**: commit before each verify; auto-revert (`git reset --hard HEAD~1`) on `pass:false`.
9. **Iteration safety**: bounded-by-default (`Iterations: 25`); safety blocks `.env`, `node_modules/`, `rm -rf`, `git push --force`. See `autoresearch-core-skill/references/iteration-safety.md`.

### Skill-specific override

**TSV audit trail.** Append every eval run to `eval-harness-results.tsv`. Overnight persistence via `autoresearch-core-skill/scripts/autoresearch-loop.sh` (detects available CLI tool). Score is the eval metric; pass = meets target threshold.

### Max iterations
- Default: 25 iterations
- Hard cap: 100 (explicit `Iterations: unlimited` overrides)
