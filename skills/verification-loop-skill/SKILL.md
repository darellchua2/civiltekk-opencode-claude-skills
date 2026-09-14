---
name: verification-loop-skill
description: Continuously verify implementations against requirements, acceptance criteria, and quality standards throughout the development cycle
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: Agent Optimization
---

## What I do

I provide continuous verification of implementations against defined requirements throughout the development cycle:

1. **Checkpoint Creation**: Define verification checkpoints at key stages of implementation
2. **Requirement Tracking**: Map each requirement to verifiable conditions
3. **Automated Verification**: Check implementations against acceptance criteria automatically
4. **Regression Detection**: Verify that new changes don't break existing functionality
5. **Progress Reporting**: Track verification status across all requirements over time

## When to use me

Use this skill when:
- You want to verify implementation against acceptance criteria before committing
- You're working on a feature with clear requirements and want continuous validation
- You need to ensure no requirements are missed during implementation
- You want to catch regressions as soon as they happen
- You're doing TDD/BDD and want structured verification beyond unit tests

**Trigger phrases**:
- "verify implementation"
- "check against requirements"
- "run verification"
- "validate against criteria"
- "checkpoint"

## Core Workflow

### Step 1: Define Verification Scope

Establish what needs to be verified:

```markdown
## Verification Scope

### Source of Truth
- Issue/PLAN file: [reference]
- Acceptance criteria: [list]
- Requirements: [list]

### Files in Scope
| File | Purpose | Criteria Covered |
|------|---------|-----------------|
| src/auth/login.ts | Login handler | AC-1, AC-2 |
| src/auth/session.ts | Session management | AC-3, AC-4 |
| tests/auth.test.ts | Test coverage | AC-5 |

### Verification Levels
1. **Syntax** — Code compiles/types correctly
2. **Functional** — Code does what it should
3. **Integration** — Code works with other components
4. **Acceptance** — Code meets all acceptance criteria
5. **Non-regression** — Existing features still work
```

### Step 2: Create Verification Checkpoints

Define checkpoints aligned with implementation phases:

```markdown
## Checkpoints

### Checkpoint 1: Structure
- [ ] All required files exist
- [ ] File structure follows conventions
- [ ] Types/interfaces defined correctly
- [ ] No syntax errors

### Checkpoint 2: Core Logic
- [ ] Main functionality implemented
- [ ] Edge cases handled
- [ ] Error paths covered
- [ ] Input validation present

### Checkpoint 3: Tests
- [ ] Unit tests written
- [ ] Integration tests written (if applicable)
- [ ] Edge case tests present
- [ ] All tests passing

### Checkpoint 4: Acceptance
- [ ] AC-1: [description] — verified
- [ ] AC-2: [description] — verified
- [ ] AC-3: [description] — verified

### Checkpoint 5: Non-Regression
- [ ] Existing tests still pass
- [ ] No new lint errors
- [ ] No type errors
- [ ] Build succeeds
```

### Step 3: Execute Verification

Run verification at each checkpoint:

1. **Parse requirements**: Extract acceptance criteria from issue/PLAN
2. **Map to code**: Find which code files implement each criterion
3. **Verify each criterion**: Check if the code satisfies the requirement
4. **Run automated checks**: lint, type-check, tests, build
5. **Record results**: Track pass/fail status with evidence

### Step 4: Report Verification Status

Generate a verification status report:

```markdown
## Verification Report

**Checkpoint**: 3 (Tests)
**Time**: 2024-01-25 14:30
**Status**: IN PROGRESS

### Requirements Status
| ID | Requirement | Status | Evidence |
|----|-------------|--------|----------|
| AC-1 | User can login with email/password | PASS | tests/auth.test.ts:L12 |
| AC-2 | Failed login shows error message | PASS | tests/auth.test.ts:L34 |
| AC-3 | Session persists across page reloads | FAIL | No test found |
| AC-4 | Session expires after 24 hours | SKIP | Not yet implemented |
| AC-5 | Logout clears session | PASS | tests/auth.test.ts:L56 |

### Automated Checks
| Check | Status | Details |
|-------|--------|---------|
| TypeScript | PASS | No type errors |
| ESLint | PASS | No lint errors |
| Unit tests | 4/5 pass | Session persistence test missing |
| Build | PASS | Successful compilation |

### Blocking Issues
- AC-3: No test for session persistence — needs implementation
```

### Step 5: Iterate Until Complete

Loop through verification until all criteria pass:

```
while (failing_criteria exist):
    1. Fix the failing implementation
    2. Re-run verification for affected criteria
    3. Run regression check
    4. Update status
```

## Verification Strategies

### By Task Type

| Task Type | Primary Verification | Secondary Verification |
|-----------|---------------------|----------------------|
| Feature | Acceptance criteria | Integration tests |
| Bug fix | Reproduce -> fix -> verify gone | Regression tests |
| Refactoring | Behavior unchanged | All existing tests pass |
| Documentation | Content accuracy | No broken links |
| Config change | System still functional | Integration tests |

### By Confidence Level

| Level | Verification Depth | When to Use |
|-------|-------------------|-------------|
| **Quick** | Syntax + basic functional | During rapid prototyping |
| **Standard** | Syntax + functional + tests | Regular feature work |
| **Thorough** | All 5 levels | Critical features, PRs |
| **Exhaustive** | Thorough + edge cases + perf | Production releases |

## Checkpoint Management

### Saving Checkpoints

```markdown
## Checkpoint: pre-refactor
**Date**: 2024-01-25 14:00
**Status**: All tests passing (12/12)
**Files**: src/auth/*.ts
**Command**: `npm test -- --coverage`
**Result**: 12 passed, 0 failed, 87% coverage
```

### Restoring Checkpoints

When verification fails, restore to last good checkpoint:

1. Identify the last passing checkpoint
2. Determine what changed since then
3. Either revert changes or fix forward
4. Re-verify from the checkpoint

### Checkpoint Naming Convention

- `pre-<task>`: Before starting a task
- `post-<task>`: After completing a task
- `mid-<task>-<step>`: Mid-task at significant step
- `pre-pr`: Before creating a PR

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `eval-harness` | Verification provides data for evaluation scoring |
| `continuous-learning` | Verification failures become learning opportunities |
| `strategic-compact` | Checkpoints are preserved during compaction |
| `tdd-workflow` | Verification extends TDD with acceptance-level checks |
| `plan-updater` | Update PLAN.md with verification progress |
| `error-resolver-workflow` | Verification failures trigger error resolution |

## Best Practices

### Writing Good Verification Criteria
- **Specific**: "Returns HTTP 401 for invalid credentials" not "Handles errors"
- **Measurable**: "Response time < 200ms" not "Fast"
- **Binary**: Each criterion should be clearly pass or fail
- **Evidence-based**: Include how to verify (test, manual check, command)

### Verification Cadence
- **Per file**: Quick syntax check after editing a file
- **Per task**: Standard check after completing a task
- **Per phase**: Thorough check after completing a phase
- **Pre-commit**: Standard check before committing
- **Pre-PR**: Thorough check before creating a PR

### Handling Failures
1. Record the failure with context (what, when, expected vs actual)
2. Classify severity (blocking vs non-blocking)
3. Fix or document as known issue
4. Re-verify affected criteria
5. Run regression check

## Example Usage

### Verify against acceptance criteria

```
"Verify our auth implementation against issue #42 acceptance criteria"
```

The skill will:
1. Parse acceptance criteria from the issue
2. Map each criterion to relevant code
3. Run checks for each criterion
4. Report pass/fail with evidence
5. List any unmet criteria with suggestions

### Pre-PR verification

```
"Run full verification before I create the PR"
```

The skill will:
1. Run all 5 verification levels
2. Check all acceptance criteria
3. Run automated checks (lint, type, test, build)
4. Check for regressions
5. Report full status — only proceed if all pass

### Checkpoint and resume

```
"Save checkpoint before refactoring the auth module"
```

The skill will:
1. Run current test suite
2. Record passing state
3. Save file list and test results
4. After refactoring, verify against checkpoint

## References

- `eval-harness` - Score-based evaluation framework
- `continuous-learning` - Learn from verification failures
- `strategic-compact` - Preserve verification state during compaction
- `plan-updater` - Update PLAN.md with verification progress

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
