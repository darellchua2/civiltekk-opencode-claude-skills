---
name: civiltekk-opencode-creation-skill
description: >-
  Generate OpenCode agents and skills following official documentation best
  practices — frontmatter contract, lean content standard, permissions,
  placement, validation. Triggers: create/generate/edit an agent or skill,
  new subagent, new skill, author agent, author skill. Not for installer
  tier/model resolution.
license: Apache-2.0
compatibility: opencode
metadata:
  harness: "opencode"
category: OpenCode Meta
---

Consolidates opencode-agent-creation-skill + opencode-skill-creation-skill (#603).

## What I do

Create or edit OpenCode artifacts — agents and skills — to the official
documentation standards each variant file carries:

1. **Detect artifact type** (agent vs skill) — explicit > inferred >
   ask-once. Explicit: the request says "agent"/"subagent" or "skill".
   Inferred: the target shape (`<name>.md` with agent frontmatter → agent;
   `skills/<name>/SKILL.md` → skill). Ambiguous ("create an artifact/tool")
   → ask once — one ask per run, then proceed on the answer.
2. **Route to the artifact variant** (§Routes).
3. **Load the variant values file** (`references/agent.md` /
   `references/skill.md`) and author or edit per its contract.

## Side files (load rules)

| Read | When | Use |
|------|------|-----|
| `references/agent.md` | variant is `agent` | required/config frontmatter keys and per-key rules, tier-aware model guidance, temperature/steps tables, permission patterns, body (system-prompt) structure, project vs global scope, name validation, examples, verification commands |
| `references/skill.md` | variant is `skill` | skill frontmatter contract, lean content standard + line budgets, content structure, skill permissions (v2), portability rules, file safety, verification |

Side files carry VALUES only; this file carries the METHOD. An artifact type
outside agent/skill (plugin, MCP config, `opencode.json`, …) is not this
skill's variant space — route it to `opencode-tooling-subagent` instead of
improvising a variant.

## Routes

| Situation | Variant |
|-----------|---------|
| "generate/edit an agent", "create a subagent", agent-shaped target file | `agent` |
| "generate/edit a skill", "create a SKILL.md", skill-shaped target dir | `skill` |
| Ambiguous ("create an artifact/tool") | ask once (§What I do step 1), then route |

## Boundaries

- **Tier/model resolution belongs to the installer's `agent-tiers.json`, not
  here.** The agent variant cites it for model guidance; never re-derive,
  re-rank, or re-assign tiers from this skill, and never default a subagent
  to the `primary` tier.
- **Registry rebuild after frontmatter changes**: any skill frontmatter
  change requires `node installer/build-registry.mjs` and a committed
  `registry.json`.
- Editing an existing artifact: `read` before `write`/`edit` — `write`
  overwrites silently.

## Agent behavior rules

- Follow the official-docs best practices each variant file carries — the
  loaded variant file is the authority for its artifact type; when it conflicts
  with memory, re-fetch the current official docs rather than guessing.
- **Never invent frontmatter keys** — unknown keys are silently ignored by
  OpenCode; emit only the keys the variant file lists.
- Ask, don't invent: a missing required field (name, description, mode /
  purpose) → one batched question round. Headless/CI: no asks — proceed only
  if every required field arrived in the original request, otherwise fail
  naming the missing fields.

> **Harness binding — interactive asks** (AGENTS.md §Portability contract):
> OpenCode — `question` tool. Claude Code — `AskUserQuestion`. Other/none —
> batch the same questions in a plain reply; proceed per the headless rule
> above if no answer comes.
