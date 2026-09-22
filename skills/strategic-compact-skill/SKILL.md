---
name: strategic-compact-skill
description: Suggest optimal context compaction strategies for AI agent sessions, preserving critical information while reducing token usage
license: Apache-2.0
compatibility: opencode
metadata:
  harness: "opencode"
category: Agent Optimization
---

## What I do

Analyze session context and compact it: classify content by retention priority, generate a session brief that preserves actionable state, and plan session breakpoints.

**Trigger phrases**: "compact context", "summarize session", "reduce context", "what can we drop", "session getting long", "preserve key decisions".

## Retention Tiers

| Tier | Content | Handling |
|------|---------|----------|
| **1 — Must keep** | Current task + acceptance criteria; uncommitted changes and their purpose; active debugging state (hypothesis, what's been tried); blockers and dependencies; auth/security context | Keep verbatim |
| **2 — Should keep** | Architecture decisions + rationale; key file locations; API contracts/data models; test results; partial solutions with reasoning | Keep, tighten |
| **3 — Compressible** | Dead-end explorations ("tried X, failed because Y"); code-review findings (drop the back-and-forth); error resolutions (keep solution, drop the process); unchanged file contents (keep paths only) | One line each |
| **4 — Discard** | Greetings; redundant explanations; abandoned approaches with no learning value; intermediate iterations; content already in files (reference, don't inline) | Drop |

## Workflow

1. **Assess**: token estimate, open tasks, decisions made, files modified, errors resolved.
2. **Classify** content into the four tiers.
3. **Strategy**: list keep-full / summarize / discard items; present the plan before executing.
4. **Execute**: generate the session brief; persist critical info to `LEARNINGS/` or project config; update AGENTS.md if a project-level finding emerged; define the next session's starting point.
5. **Validate**: all active tasks tracked, all decisions preserved with rationale, all error/solution pairs documented, next steps clear. If anything critical was lost — restore and re-compact.

## Session Brief (output contract)

```markdown
## Session Brief (Compacted)

### Active Task
[one line]

### State
- [x] Completed: …
- [ ] In Progress: …
- [ ] Remaining: …

### Key Decisions
1. [decision]: [why] → [impact]

### Files
| File | Status | Notes |
|------|--------|-------|
| path | Modified/Created/Unchanged | what + why |

### Blockers
- …

### Next Steps
1. …
```

## When to Compact

- Proactively at ~70% context capacity, not reactively.
- Between subtasks; after a solved debug (keep the fix, drop the process); before PR creation (changes + rationale only).
- Common failure modes: over-compacting loses the "why" behind decisions; under-compacting keeps raw conversation; dropping context another skill/agent depends on.

## Integration

- `continuous-learning-skill` — extract patterns before compacting (Tier 1)
- `verification-loop-skill` — compaction preserves gate memos + verification state
- `eval-harness-skill` — eval results are Tier 2 (keep summaries)
- `plan-execution-skill` (--update) — PLAN.md files are natural compaction anchors

> **Removal note (2026-09-19, #409 trim per LEARNINGS #383 recipe):** dropped the worked compaction-strategy example, the multi-session plan template (variant of the session brief), the Example Usage section, and Best Practices prose (compressed into "When to Compact"). Kept verbatim: frontmatter, retention tiers, workflow contract, session-brief output template.
