---
name: civiltekk-context-optimization-skill
description: >-
  Token-overhead audits across agents, skills, and MCP servers (classification
  + optimization recommendations) and context-compaction strategy that
  preserves critical information while reducing token usage. Triggers: audit
  context budget, context budget, token overhead, how much context am I
  using, audit config bloat, check skill overhead, compact context,
  summarize session, reduce context, what can we drop, session getting
  long, preserve key decisions.
license: Apache-2.0
compatibility: opencode
metadata:
  harness: "opencode"
category: Agent Optimization
---

Consolidates context-budget-skill + strategic-compact-skill (#603).

## What I do

Optimize where a session's or a configuration's tokens go:

1. **Detect the route** (§Routes) — explicit > inferred > ask-once.
   Explicit: the request names the concern ("audit context budget",
   "token overhead", "config bloat" → `audit-overhead`; "compact
   context", "summarize session", "what can we drop" →
   `compaction-strategy`). Inferred: the complaint shape (config has
   grown, planning to add components, sluggish sessions after adding
   skills/agents/MCP → `audit-overhead`; session running long, mid-loop
   context pressure, before a PR → `compaction-strategy`). Ambiguous
   ("optimize my context") → ask once — one ask per run, then proceed on
   the answer.
2. **Load the route's values file** (`references/budget.md` /
   `references/compact.md`) and apply its contract.
3. The routes chain naturally — the audit finds the bloat, compaction
   shrinks the live session; a full optimization often uses both files,
   the route only decides which leads.

## Side files (load rules)

| Read | When | Use |
|------|------|-----|
| `references/budget.md` | route `audit-overhead` | Inventory of agents/skills/rules/MCP/config with token-estimation formulas, Always/Sometimes/Rarely classification buckets, problem-pattern detection, budget-report format, prioritized optimization guidance |
| `references/compact.md` | route `compaction-strategy` | Retention tiers (must-keep → discard), assess→classify→strategy→execute→validate workflow, session-brief output contract, when-to-compact timing and failure modes |

Side files carry VALUES only; this file carries the METHOD. A context
concern outside config auditing and session compaction (model selection,
provider context windows, embedding or retrieval stores) is not this
skill's space — route it to the matching specialist instead of
improvising.

## Routes

| Situation | Route |
|-----------|-------|
| "audit context budget", "context budget", "token overhead", "how much context am I using", "audit config bloat", "check skill overhead"; sluggish sessions after adding skills/agents/MCP; planning to add components and need headroom | `audit-overhead` |
| "compact context", "summarize session", "reduce context", "what can we drop", "session getting long", "preserve key decisions"; ~70% context capacity; between subtasks or before PR creation | `compaction-strategy` |
| Ambiguous ("optimize my context") | ask once (§What I do step 1), then route |

## Boundaries

- The two routes were formerly peer skills that cross-referenced each
  other as companions (audit identifies bloat sources; compact addresses
  runtime compression) — that boundary is internal now; the route table
  above is the boundary logic.
- Acting on audit findings (merging, archiving, or refactoring
  overlapping skills) → `opencode-skills-maintainer-skill`; persisting
  optimization patterns → `continuous-learning-skill`.
- Token estimates are approximations — use audit reports for relative
  comparison and rankings, not absolute measurements (values-file
  doctrine).

## Agent behavior rules

- One ask per run maximum (route detection); headless/CI: no asks —
  infer from the request, defaulting to `audit-overhead`
  (measure first; compaction applies to what the audit reveals about
  the live session).
- For `compaction-strategy`: present the plan before executing it, and
  validate after — if anything critical was lost, restore and
  re-compact (values-file contract).

> **Harness binding — interactive asks** (AGENTS.md §Portability contract):
> OpenCode — `question` tool. Claude Code — `AskUserQuestion`. Other/none —
> ask in a plain reply; headless/no-answer rule above applies.
