---
name: grill-me-skill
description: >-
  Relentless plan-sharpening interview WITHOUT doc capture — runs grilling-skill
  only. Grilling without CONTEXT.md/ADR artifacts.
license: Apache-2.0
compatibility: opencode
category: Planning & Alignment
---

## What I do

I orchestrate a plain grilling session — a relentless interview that sharpens a plan or design, with no doc artifacts produced. I delegate entirely to `grilling-skill` (the model-invoked interview engine).

Use `grill-with-docs-skill` instead if you also want the session to capture `CONTEXT.md` (glossary) and ADRs inline.

## When to use me

Use this skill when:
- You want to stress-test a plan or design via interview, but don't need durable doc artifacts
- A quick alignment check before building is enough

**Trigger phrases**:
- "grill me"
- "interview me about this plan"
- "stress-test this idea"

## Core Workflow

### Step 1: Load the engine

Delegate all behavior to `grilling-skill`. Do not reimplement the interview loop.

### Step 2: Run the grilling session

Apply `grilling-skill`'s rules:
- One question at a time, each with a recommended answer
- Explore the codebase instead of asking when possible
- Walk the decision tree branch-by-branch until resolved or the user wants to build

### Step 3: Conclude

Summarise the resolved decisions and any open questions. No files are written.

## Rules

- **Do not reimplement the engine.** Delegate to `grilling-skill`.
- **No doc capture.** If the user wants CONTEXT.md/ADR capture, redirect to `grill-with-docs-skill`.

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `grilling-skill` | The interview engine I orchestrate |
| `grill-with-docs-skill` | The variant that ALSO captures CONTEXT.md + ADRs |
| `domain-modeling-skill` | Not used by me (that's grill-with-docs-skill's job) |

## Example Usage

```
"Grill me about how we should structure the notifications module"
```

The skill will delegate to `grilling-skill`, which interviews one question at a time with recommendations until the decision tree is resolved. No docs are written.

## References

- `grilling-skill` - Interview engine
- `grill-with-docs-skill` - Variant with doc capture
