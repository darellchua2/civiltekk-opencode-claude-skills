---
name: context-budget-skill
description: >-
  Audit token overhead across agents, skills, and MCP servers — classification
  and optimization recommendations.
license: Apache-2.0
compatibility: opencode
category: Agent Optimization
---

## What I do

I audit the token overhead of every loaded component in an OpenCode configuration and surface actionable optimizations:

1. **Inventory**: Scan all agents, skills, rules, and MCP servers that consume context
2. **Classify**: Bucket each component by necessity (Always / Sometimes / Rarely needed)
3. **Detect Issues**: Identify bloat, redundancy, and common problem patterns
4. **Report**: Produce a structured context budget report with prioritized recommendations

## When to use me

Use this skill when:
- Session performance feels sluggish or output quality is degrading
- You've recently added many skills, agents, or MCP servers
- You want to know how much context headroom you actually have
- Planning to add more components and need to know if there's room
- Before deploying configuration changes to catch bloat early

**Trigger phrases**:
- "audit context budget"
- "context budget"
- "token overhead"
- "how much context am I using"
- "audit config bloat"
- "check skill overhead"

## Core Workflow

### Step 1: Inventory

Scan all component directories and estimate token consumption.

**Agents** (`opencode_app/.opencode/agents/*.md`)
- Count files and estimate tokens per file (`words × 1.3`)
- Extract `description` frontmatter length
- Flag: files >200 lines (heavy), description >50 words (bloated frontmatter)

**Skills** (`opencode_app/.opencode/skills/*/SKILL.md`)
- Count directories and estimate tokens per SKILL.md (`words × 1.3`)
- Flag: files >300 lines (heavy)
- Note: skills are loaded on demand, so only description fields consume always-on context

**Rules / Instructions** (AGENTS.md chain)
- Path 1: `AGENTS.md` (repo-level instructions)
- Path 2: `deploy/.AGENTS.md` (user-space deployment)
- Path 3: `opencode_app/AGENTS.md` (Docker mode)
- Measure file size, section count
- Flag: combined total >500 lines

**MCP Servers** (`opencode_app/opencode.json` → `mcpServers`)
- Count configured servers
- Estimate schema overhead at ~100-200 tokens per server
- Flag: servers with >20 tools, servers that wrap simple CLI commands

**Config** (`deploy/config.json`)
- Count agent definitions, complexity of routing rules
- Estimate ~50-100 tokens per agent definition

### Step 2: Classify

Sort every component into a bucket:

| Bucket | Criteria | Action |
|--------|----------|--------|
| **Always needed** | Referenced in AGENTS.md, backs active workflows, or matches current project type | Keep |
| **Sometimes needed** | Domain-specific (e.g. language skills), not referenced in primary routing | Consider on-demand loading |
| **Rarely needed** | No routing reference, overlapping content, or no obvious project match | Remove or archive |

### Step 3: Detect Issues

Identify problem patterns:

| Pattern | Detection Method | Impact |
|---------|-----------------|--------|
| **Bloated agent descriptions** | `description` >50 words in frontmatter | Inflates Task tool context on every spawn |
| **Heavy agents** | Files >200 lines | Large agent files consume context on spawn |
| **Redundant skills** | Skills that duplicate agent logic or other skills | Double-loading same knowledge |
| **MCP over-subscription** | >10 servers, or servers wrapping CLI tools already available | Each server adds schema overhead |
| **AGENTS.md bloat** | Verbose explanations, outdated sections, instructions that should be skills | Always-loaded, impacts every session |
| **Skill-skill overlap** | Multiple skills covering same domain with similar content | Confusion for agent selection |
| **Stale components** | Skills/agents not referenced in any workflow or routing | Dead weight in configuration |

### Step 4: Report

Produce the context budget report:

```
Context Budget Report
═══════════════════════════════════════
Total estimated overhead: ~XX,XXX tokens

Component Breakdown:
┌─────────────────┬────────┬───────────┐
│ Component        │ Count  │ Tokens    │
├─────────────────┼────────┼───────────┤
│ Agents           │ N      │ ~X,XXX    │
│ Skills           │ N      │ ~X,XXX    │
│ MCP servers      │ N      │ ~XX,XXX   │
│ AGENTS.md chain  │ N      │ ~X,XXX    │
│ Config           │ N      │ ~X,XXX    │
└─────────────────┴────────┴───────────┘

Issues Found (N):
  [ranked by token savings potential]

Top 3 Optimizations:
  1. [action] → save ~X,XXX tokens
  2. [action] → save ~X,XXX tokens
  3. [action] → save ~X,XXX tokens

Potential savings: ~XX,XXX tokens (XX% of current overhead)
```

## Token Estimation

| Content Type | Formula | Notes |
|-------------|---------|-------|
| Prose / markdown | `word_count × 1.3` | Standard text estimation |
| Code-heavy files | `char_count / 4` | Code has denser token ratio |
| YAML frontmatter | `line_count × 5` | Structured data is more token-dense |
| MCP tool schemas | `~100-200 tokens per tool` | Each tool description + parameters |
| Agent descriptions | Exact word count × 1.3 | Loaded into Task tool context always |

## Classification Buckets

### Always Needed
- Agents referenced in AGENTS.md routing tables
- Skills that back primary workflows (linting, testing, PR creation)
- MCP servers actively used (CodeGraph, Atlassian, web tools)
- Core AGENTS.md instructions

### Sometimes Needed
- Language-specific skills (Python, TypeScript, Go patterns)
- Domain-specific agents (startup-ceo, construction-bd)
- Framework-specific skills (Next.js, Django, FastAPI)
- Optional MCP servers

### Rarely Needed
- Skills with no routing reference
- Agents never mentioned in workflows
- Overlapping skills (same domain, similar content)
- MCP servers wrapping CLI tools already available

## Problem Patterns

### Bloated Agent Descriptions
Agent `description` fields are loaded into the Task tool context on every session, even if the agent is never spawned. Keep descriptions under 50 words.

**Fix**: Move detailed instructions into the agent body; keep description as a concise one-liner.

### Heavy Agents
Agents >200 lines inflate context when spawned via Task tool. Each line costs tokens during the subagent session.

**Fix**: Split large agents into focused specialists. Use skill loading (`permission.skill`) to inject domain knowledge on demand.

### Redundant Components
Multiple skills covering the same domain create confusion for agent selection and waste context.

**Fix**: Consolidate into one authoritative skill. Use `opencode-skills-maintainer-skill` to detect overlaps.

### MCP Over-subscription
Each MCP server adds tool descriptions to the context. A server with 20 tools costs ~2,000-4,000 tokens.

**Fix**: Remove servers that wrap CLI tools already available (git, gh, npm). Use `codegraph_*` tools instead of separate MCP servers for code exploration.

### AGENTS.md Bloat
AGENTS.md is loaded on every session. Verbose explanations, outdated sections, or instructions that belong in skills waste tokens.

**Fix**: Move detailed instructions to skills. Keep AGENTS.md as routing tables and concise rules.

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `strategic-compact-skill` | Budget audit identifies bloat sources; compact addresses runtime context compression |
| `continuous-learning-skill` | Store audit findings as optimization patterns for future reference |
| `eval-harness-skill` | Use eval scoring to assess whether removing a component impacts quality |
| `opencode-skills-maintainer-skill` | Act on redundancy findings — merge, archive, or refactor overlapping skills |
| `documentation-consistency-skill` | Cross-validate counts between budget report and documentation |

## Best Practices

### Running Audits
- Run after adding any new agent, skill, or MCP server
- Run before major configuration changes to establish a baseline
- Compare reports across audits to track bloat trends
- Focus on "Always needed" bucket first — those cost tokens every session

### Prioritizing Fixes
- MCP servers have the highest per-component token cost
- Agent descriptions are loaded always, even when agents aren't used
- Skills are loaded on demand, so their full content rarely costs tokens
- AGENTS.md is loaded every session — keep it lean

### Estimation Accuracy
- Token estimates are approximations (`words × 1.3`)
- Actual token counts depend on the model's tokenizer
- Use reports for relative comparison, not absolute measurements
- Focus on percentages and rankings, not exact numbers

## Example Usage

### Basic audit

```
"Audit my context budget"
```

The skill will:
1. Scan all agents, skills, MCP servers, and config files
2. Estimate token overhead per component
3. Classify each component by necessity
4. Detect problem patterns
5. Generate report with top optimization recommendations

### Check before adding components

```
"I want to add 5 more MCP servers, do I have room?"
```

The skill will:
1. Calculate current overhead as percentage of estimated context
2. Project additional overhead from 5 new servers
3. Recommend what to remove to stay under budget
4. Suggest which servers could be replaced by CLI tools

### Find redundant skills

```
"Are any of my skills overlapping?"
```

The skill will:
1. Scan all skill descriptions and content
2. Compare domains and workflow tags
3. Identify skills with >50% content overlap
4. Recommend consolidation or archival

## References

- `strategic-compact-skill` - Runtime context compression (companion to this audit skill)
- `opencode-skills-maintainer-skill` - Act on redundancy findings
- `continuous-learning-skill` - Persist optimization patterns
