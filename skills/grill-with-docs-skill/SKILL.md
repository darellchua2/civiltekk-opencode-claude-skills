---
name: grill-with-docs-skill
description: >-
  Relentless plan-sharpening interview that also produces CONTEXT.md glossary
  and ADRs — pairs grilling-skill with domain-modeling-skill.
license: Apache-2.0
compatibility: opencode
category: Planning & Alignment
---

## What I do

I orchestrate a focused session that combines two engines:

1. **`grilling-skill`** — relentlessly interviews the user about the plan, one question at a time with a recommended answer, until the decision tree is resolved
2. **`domain-modeling-skill`** — captures the crystallised terminology into `CONTEXT.md` and records hard-to-reverse decisions as ADRs, inline as they emerge

The result is alignment AND a durable artifact: the next session (or the next agent) inherits a sharpened glossary and recorded decisions, so the work doesn't have to be re-litigated.

## When to use me

Use this skill when:
- You want to stress-test a plan or design before building
- You want the alignment session to ALSO produce domain docs (glossary + ADRs)
- You're starting a non-trivial feature and want to lock down terminology first

**Trigger phrases**:
- "grill with docs"
- "grill me and write it up"
- "stress-test this plan and capture it"
- "interview me and document"

If you want the interview WITHOUT doc capture, use `grill-me-skill` instead.

## Core Workflow

### Step 1: Load both engines

This skill delegates all behavior to two model-invoked engines. Do not reimplement them:

- `grilling-skill` — owns the interview loop
- `domain-modeling-skill` — owns doc capture

### Step 2: Run the grilling session

Invoke `grilling-skill` to conduct the interview. Apply its rules throughout:
- One question at a time, each with a recommended answer
- Explore the codebase instead of asking when possible
- Walk the decision tree branch-by-branch

### Step 3: Capture docs inline during the session

As `grilling-skill` resolves each branch, hand off to `domain-modeling-skill` to:
- **Challenge and sharpen terminology** against the existing `CONTEXT.md`
- **Update `CONTEXT.md` inline** the moment a term is resolved
- **Offer an ADR** only when a decision is hard-to-reverse + surprising + a real trade-off

The two engines run interleaved, not sequentially. Doc capture happens *during* the interview, not after.

### Step 4: Conclude

When `grilling-skill` signals convergence (every branch resolved, or the user wants to build), summarise:
- Terms added/changed in `CONTEXT.md`
- ADRs created (if any)
- Remaining open questions (if any)

## Why This Combination Matters

> With a ubiquitous language, conversations among developers and expressions of the code are all derived from the same domain model.
> — Eric Evans, *Domain-Driven Design*

Agents dropped into a project usually decode jargon as they go, using 20 words where 1 will do. A shared `CONTEXT.md` fixes this concisely:

- **Before**: "There's a problem when a lesson inside a section of a course is made 'real' (i.e. given a spot in the file system)"
- **After**: "There's a problem with the materialization cascade"

This concision pays off session after session: variables/functions/files are named consistently, the codebase is easier to navigate, and the agent spends fewer tokens on thinking because it has a more concise language.

## Rules

- **Do not reimplement the engines.** Delegate to `grilling-skill` and `domain-modeling-skill`. This skill is an orchestrator, nothing more.
- **Capture inline, not in a batch.** Docs are written as terms/decisions crystallise, not collected and dumped at the end.
- **Respect the user's appetite.** If they want a shorter session, stop grilling earlier. Don't grill past their signal.
- **Don't force ADRs.** The three-criteria gate (hard-to-reverse + surprising + real trade-off) is enforced by `domain-modeling-skill`. Most sessions create zero ADRs, and that's correct.

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `grilling-skill` | The interview engine I orchestrate |
| `domain-modeling-skill` | The doc-capture engine I orchestrate |
| `ticket-creation-skill` / `worktree-pipeline-skill` | A grilled, documented outcome feeds cleanly into ticket creation, then the branch+PLAN pipeline |
| `plan-execution-skill` | The resolved plan + glossary give execution a precise vocabulary |
| `continuous-learning-skill` | ADRs and glossary entries become durable learnings |

## Example Usage

```
"Grill with docs — we're adding a notifications module"
```

The skill will:
1. Load `grilling-skill` and `domain-modeling-skill`.
2. Begin the interview: "First — push, pull, or hybrid notifications? I recommend hybrid. Agree?"
3. As terms resolve (e.g. "notification" vs "alert" vs "digest"), update `CONTEXT.md` inline.
4. If a hard-to-reverse decision emerges (e.g. "we'll use a message bus, not polling"), offer an ADR.
5. Conclude with a summary of docs written and any open questions.

## References

- `grilling-skill` - Interview engine
- `domain-modeling-skill` - Doc-capture engine
