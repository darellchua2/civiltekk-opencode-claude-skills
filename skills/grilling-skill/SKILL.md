---
name: grilling-skill
description: >-
  Interview the user relentlessly to stress-test a plan or design — one question
  at a time with a recommended answer. Any 'grill' trigger phrase.
license: Apache-2.0
compatibility: opencode
category: Planning & Alignment
---

## What I do

I am the reusable interview engine behind `grill-me-skill` and `grill-with-docs-skill`. I relentlessly interview the user about a plan or design until we reach a shared understanding:

1. **Decision-tree walk**: Walk down each branch of the design tree, resolving dependencies between decisions one-by-one
2. **One question at a time**: Never ask multiple questions at once — that is bewildering
3. **Recommended answer**: For each question, provide my recommended answer so the user can accept or correct
4. **Codebase-first**: If a question can be answered by exploring the codebase, explore it instead of asking
5. **Shared understanding**: Continue until every branch of the decision tree is resolved

I am the **engine** (model-invoked). User-facing skills (`grill-me-skill`, `grill-with-docs-skill`) orchestrate me; they do not duplicate my behavior.

## When to use me

Use this skill when:
- A plan, spec, or design needs stress-testing before implementation begins
- The user uses any "grill" trigger phrase
- Another skill (e.g. `grill-with-docs-skill`) delegates an interview session
- Ambiguity in requirements is causing misalignment between user and agent

**Trigger phrases**:
- "grill me"
- "interview me about"
- "stress-test this plan"
- "walk through the decision tree"
- "what haven't we covered"

## Core Workflow

### Step 1: Frame the session

State what we're grilling about in one sentence, then begin immediately. Do not ask the user "what do you want to be grilled on?" if it's already clear from context.

### Step 2: Walk the decision tree

For each unresolved branch of the design:

1. **Identify the next dependency** — the decision that unblocks the most other decisions. Start with the highest-leverage unknowns.
2. **Formulate a single question** — one question, phrased so a concrete answer resolves the branch.
3. **Provide your recommended answer** — give your best recommendation with one-line rationale, so the user can say "yes" or correct you.
4. **Wait for feedback** — do NOT proceed until the user answers. Asking multiple questions at once is the primary failure mode of this skill.

### Step 3: Resolve via codebase, not questioning

Before asking any question, check: **can I answer this myself by reading the code or project docs?**

| Situation | Action |
|-----------|--------|
| Code clearly answers it | Read it and state the answer, don't ask |
| Code contradicts the user's claim | Surface the contradiction: "Your code does X, but you said Y — which is right?" |
| Genuinely a user-only decision | Ask the question |
| Documented in `CONTEXT.md`, README, or ADRs | Read it, don't ask |

### Step 4: Continue until convergence

Keep walking the tree until either:
- Every branch is resolved (success)
- The user signals they want to start building (respect this — don't grill past their appetite)
- Remaining unknowns are genuinely unresolvable until implementation begins (note them explicitly and move on)

## Rules

- **One question at a time.** This is the non-negotiable rule. A wall of questions overwhelms the user and breaks the feedback loop.
- **Always recommend.** A bare question forces the user to do all the thinking. Lead with your recommendation.
- **Never invent answers for user-only decisions.** If it's a product, scope, or preference call, ask — don't assume.
- **Respect the stop signal.** When the user says "that's enough" or "let's build," stop grilling immediately.
- **Don't repeat resolved questions.** Track what's been answered; re-asking signals you weren't listening.

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `grill-with-docs-skill` | Orchestrates me AND `domain-modeling-skill` to capture docs during the interview |
| `grill-me-skill` | Orchestrates me alone (no docs capture) |
| `domain-modeling-skill` | Paired with me by `grill-with-docs-skill` to write CONTEXT.md + ADRs inline |
| `ticket-creation-skill` / `worktree-pipeline-skill` | A grilled, resolved outcome feeds into ticket creation, then the branch+PLAN+execute pipeline |

## Example Usage

### Plain grilling session

```
"Grill me about how we should structure the notifications module"
```

The skill will:
1. Frame the session: "We're designing the notifications module structure."
2. Ask one question with a recommendation: "First — should notifications be push, pull, or hybrid? I recommend hybrid (push for real-time, a polling fallback for missed events) — agree?"
3. Wait for the answer, then proceed to the next branch.
4. Continue until the decision tree is resolved.

## References

- `grill-with-docs-skill` - User-facing command that pairs me with doc capture
- `domain-modeling-skill` - Doc capture engine used alongside me
- `strategic-compact-skill` - A resolved grilling session can be compacted into a decision summary
