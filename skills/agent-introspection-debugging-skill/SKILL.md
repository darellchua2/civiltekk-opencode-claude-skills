---
name: agent-introspection-debugging-skill
description: Debug why agents or skills aren't working as expected with systematic diagnosis, configuration validation, and fix recommendations
license: Apache-2.0
compatibility: opencode
category: Agent Optimization
---

## What I do

Systematically diagnose why agents, skills, or subagents misbehave: configuration validation → permission audit → context/behavior analysis → specific fix recommendations.

**Trigger phrases**: "debug agent", "why is the agent not working", "agent introspection", "skill not triggering", "agent ignoring instructions", "fix agent behavior", "diagnose subagent".

## Step 1: Symptom → Likely Cause

| Symptom | Category | Likely Cause |
|---------|----------|-------------|
| Agent doesn't spawn | Config | Missing .md file, wrong name, permission issue |
| Spawns but does nothing | Permissions | Tools denied, no skill access, step limit too low |
| Wrong output | Behavior | Missing context, conflicting instructions, model limits |
| Ignores AGENTS.md | Routing | AGENTS.md not loaded, routing rules override |
| Skill doesn't trigger | Discovery | Name mismatch, trigger phrases missing, not installed |
| Can't use tools | Permissions | Tool not in `permissions` allowlist |
| Loops or repeats | Behavior | Missing termination condition, unclear success criteria |
| MCP tools not called | Discovery | Server not configured, tool unknown to agent |

## Step 2: Configuration Checklist

**Agent (`agents/<name>.md`)**: file exists · `description` present and <50 words (always in Task context) · `mode` set · `model` valid · `steps` set (10-25) · `permissions` rules array present (v2 shape) · YAML parses · body is valid markdown.

**Skill (`skills/<name>/SKILL.md`)**: directory name == frontmatter `name` exactly · `description` present · `license` + `compatibility` present · required sections present ("What I do", "When to use me", workflow) · YAML parses.

## Step 3: Permission Audit

For each needed tool: allowed in `permissions`? Any `deny` overriding it? `task` delegation targets allowed? For each loaded skill: allowed via `action: skill` rule? Directory exists with valid SKILL.md? Name case-exact?

| Issue | Symptom | Fix |
|-------|---------|-----|
| Missing `read` allow | Can't read files | Add `{action: read, effect: allow}` |
| Missing `glob` allow | Can't find files | Add glob allow rule |
| Missing `task` targets | Can't spawn subagents | Allow the subagent names (action: task) |
| `edit: deny` but must edit | Reads, never modifies | Allow edit (scoped to task paths) |
| `bash: deny` on build agent | Can't run commands | Allow bash with caution |
| Skill name mismatch | Skill won't load | Match exact directory name |

## Step 4: Behavior Analysis

- **Context loading**: is AGENTS.md loaded? Right routing table entries? Agent .md used as system prompt?
- **Skill discovery**: do trigger phrases match how the user asks? Is the description selective enough?
- **Task prompt quality**: specific? Enough context (paths, requirements)? Return format stated? CodeGraph guidance included when `.codegraph/` exists?
- **Model selection**: model appropriate for complexity? Available in current config?

## Step 5: Diagnosis Report (output contract)

```markdown
**Agent/Skill**: <name> · **Symptom**: <what's wrong> · **Root Cause**: <cause> · **Confidence**: h/m/l

### Evidence
1. <finding, e.g. "permissions denies edit but the task requires writes">

### Recommended Fix
<specific, actionable>

### Verification
<how to confirm the fix works>
```

## Common Patterns (cause → fix)

- **Generic output** → Task prompt too vague: add file paths, stack, specific requirements
- **Can't find files** → read/glob denied: add allow rules
- **Ignores skills** → skill missing from `permissions` skill rules, or name mismatch (case-sensitive, `-skill` suffix)
- **Loops forever** → no return contract: add explicit completion criteria to the agent .md
- **Never uses CodeGraph** → no `.codegraph/` or prompt doesn't mention it: `codegraph init -i` + prompt guidance
- **Skill never triggers** → trigger phrases absent from description/When-to-use: add them
- **Irrelevant subagent output** → constrain the Task prompt: specific paths, function names, output format
- **MCP tools not called** → server not in `opencode.json` or tool unknown: check config; follow the MCP Availability Guard

## Debugging Efficiency

Config first (most common), permissions second (quick win), behavior last. One change at a time, re-test after each. Compare against a working agent/skill as reference. Persist fixes as learnings.

## Integration

- `context-budget-skill` — context bloat is a diagnosis outcome
- `opencode-skills-maintainer-skill` — post-fix format validation
- `opencode-agent-creation-skill` / `opencode-skill-creation-skill` — authoring rules referenced when fixing
- `continuous-learning-skill` — store diagnosed anti-patterns

## References

- `opencode-agent-creation-skill` — agent authoring best practices
- `opencode-skill-creation-skill` — skill authoring best practices
- `opencode-skills-maintainer-skill` — skill format validation
- `continuous-learning-skill` — debugging-pattern storage

> **Removal note (2026-09-19, #409 trim per LEARNINGS #383 recipe):** dropped the three worked debugging examples, Best Practices prose (compressed into "Debugging Efficiency"), verbose checklist markdown, and the `metadata.audience`/`metadata.workflow` checklist item (deliberate — the v2 frontmatter contract reserves metadata sub-keys `protocol`/`pattern` only). Also corrected legacy v1 `permission`-block references to the v2 `permissions` rules array (post-#380 shape). Kept verbatim: frontmatter, symptom table, permission-issue table, output contract, pattern list.
