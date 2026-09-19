# Decision: Adaptive review drops proactive requirements review; gaps flow via Mode R relay

**Date:** 2026-09-18
**Scope:** project
**Confidence:** 0.9

## Context

`worktree-pipeline-skill` Step 7 selected `requirements-specialist-subagent` iff a PLAN was freshly generated. That agent has no PLAN-review mode — Mode R's declared input is a *reviewer-surfaced* Requirements Gaps array, which cannot exist before any reviewer has run. Same stage-mismatch class as the coverage-subagent removal in #366. Architecture-review already owns requirements verification (workflow step 8 + required `Requirements Gaps` contract field), and code-review (unconditional at Step 9) carries the same required field — so the proactive delegation duplicated coverage while the designed reactive path was never wired.

## Decision

1. Step 7 selects reviewers by blast-radius signal only (architecture iff cross-module Consumer Map nodes; uiux iff frontend signal) — no proactive requirements review.
2. Requirements coverage is reviewer-owned: uiux gained Step 4a + a required `Requirements Gaps` Return Contract field (mirroring archi/code-review); archi needed no change.
3. Any reviewer returning a non-empty `Requirements Gaps` array → relay to requirements-specialist **Mode R** (max 2 rounds), answers applied to the PLAN. This is the pipeline finally feeding Mode R its designed input.
4. Step 6d self-check gained a belt: every Acceptance Criterion addressed by ≥1 step (covers thin-map tickets that select zero reviewers).
5. Per-skill installs (skills cannot declare agent deps in the installer resolver): Step 1 gained a dependency preflight — hard deps (`plan-automation-loop-skill`, `code-review-subagent`, `pr-workflow-subagent`) abort `failed` with the `npx … add <name>` hint; reviewers/requirements/ticket-creation are soft (skip-with-note). Availability is detectable because `permission.task` deny removes an agent from the Task tool description (opencode v2 docs, verified 2026-09-18).

## Consequences

- Fresh vs adopted PLANs are now treated identically at review time (the freshness criterion was arbitrary — adopted drafts could drift just as much).
- Thin-map backend tickets get zero Step 7 reviewers by design; backstops: Step 5 re-validation, 6d criterion belt, unconditional Step 9 code review.
- Registry/README untouched (body-only edits, no frontmatter change, no add/remove).
