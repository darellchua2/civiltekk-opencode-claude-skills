---
name: agent-introspection-debugging-skill
description: Debug why agents or skills aren't working as expected with systematic diagnosis, configuration validation, and fix recommendations
license: Apache-2.0
compatibility: opencode
category: Agent Optimization
---

## What I do

I systematically diagnose why agents, skills, or subagents aren't producing expected output:

1. **Configuration Validation**: Verify agent/skill files are correctly formatted and loadable
2. **Permission Auditing**: Check tool access permissions match the agent's needs
3. **Context Analysis**: Identify context-related issues (too much, too little, missing references)
4. **Behavioral Diagnosis**: Trace why an agent makes unexpected decisions
5. **Fix Recommendations**: Provide specific, actionable fixes for diagnosed issues

## When to use me

Use this skill when:
- An agent or subagent produces unexpected or wrong output
- A skill doesn't trigger when it should
- A subagent fails to use tools you expected it to use
- An agent ignores instructions from AGENTS.md or its own .md file
- An MCP tool isn't being called when it should be
- You want to understand why an agent chose a particular approach
- A skill loads but its workflow isn't being followed

**Trigger phrases**:
- "debug agent"
- "why is the agent not working"
- "agent introspection"
- "skill not triggering"
- "agent ignoring instructions"
- "fix agent behavior"
- "diagnose subagent"

## Core Workflow

### Step 1: Identify the Problem

Clarify what's wrong:

| Symptom | Category | Likely Cause |
|---------|----------|-------------|
| Agent doesn't spawn | Config | Missing .md file, wrong name, permission issue |
| Agent spawns but does nothing | Permissions | Tools denied, no skill access, step limit too low |
| Agent produces wrong output | Behavior | Missing context, conflicting instructions, model limitations |
| Agent ignores AGENTS.md | Routing | AGENTS.md not loaded, routing rules override |
| Skill doesn't trigger | Discovery | Skill name mismatch, trigger not matched, skill not installed |
| Agent can't use tools | Permissions | Tool not in permission allowlist |
| Agent loops or repeats | Behavior | Missing termination condition, unclear task prompt |
| MCP tools not called | Discovery | MCP server not configured, tool name unknown to agent |

### Step 2: Validate Configuration

Check the agent/skill file structure:

```markdown
## Configuration Checklist

### Agent (.md file in agents/)
- [ ] File exists at `opencode_app/.opencode/agents/<name>.md`
- [ ] YAML frontmatter has `description` field (required)
- [ ] `description` is under 50 words (loaded into Task tool context)
- [ ] `mode` field is set (usually `subagent`)
- [ ] `model` field is set to valid model ID
- [ ] `steps` field is set (recommended: 10-25)
- [ ] `permission` block exists with tool access rules
- [ ] No YAML syntax errors (check indentation, quoting)
- [ ] File is valid markdown after frontmatter

### Skill (SKILL.md in skills/<name>/)
- [ ] Directory exists at `opencode_app/.opencode/skills/<name>/`
- [ ] SKILL.md file exists inside the directory
- [ ] YAML frontmatter has `name` field matching directory name exactly
- [ ] YAML frontmatter has `description` field (under 200 chars)
- [ ] `license` and `compatibility` fields present
- [ ] `metadata.audience` and `metadata.workflow` set
- [ ] Required sections present: "What I do", "When to use me", "Core Workflow"
- [ ] No YAML syntax errors
```

### Step 3: Audit Permissions

Verify the agent can access what it needs:

```markdown
## Permission Audit

### Tool Access
For each tool the agent needs:
- Is the tool listed in `permission` with `allow`?
- Is there a `deny` rule that overrides it?
- If using `task` delegation, are target subagents allowed?

### Skill Access
For each skill the agent loads:
- Is the skill listed in `permission.skill` with `allow`?
- Does the skill directory exist with a valid SKILL.md?
- Is the skill name correct (case-sensitive, hyphenated)?

### Common Permission Issues
| Issue | Symptom | Fix |
|-------|---------|-----|
| Missing `read: allow` | Agent can't read files | Add `read: allow` to permission block |
| Missing `glob: allow` | Agent can't find files | Add `glob: allow` to permission block |
| Missing `task` delegation | Agent can't spawn subagents | Add allowed subagent names to `permission.task` |
| `edit: deny` but needs to edit | Agent reads but never modifies | Change to `edit: allow` |
| `bash: deny` for build agents | Agent can't run commands | Change to `bash: allow` with caution |
| Skill name mismatch | Agent can't load skill | Match exact skill directory name |
```

### Step 4: Analyze Behavior

Trace why the agent makes unexpected decisions:

#### 4a. Check Context Loading
- Is AGENTS.md being loaded for the project?
- Are the right instructions being picked up from AGENTS.md routing tables?
- Is the agent's own .md file being used as the system prompt?

#### 4b. Check Skill Discovery
- Does the skill name match the trigger phrase?
- Is the skill description clear enough for the primary agent to select it?
- Is the skill in the correct directory with correct naming?

#### 4c. Check Task Prompt Quality
When spawning a subagent, is the Task prompt:
- Specific about what to do?
- Providing enough context (file paths, requirements)?
- Setting clear expectations for the return format?
- Including CodeGraph guidance if `.codegraph/` exists?

#### 4d. Check Model Selection
- Is the `model` field appropriate for the task complexity?
- Is the model available in the current OpenCode configuration?
- Would a different model produce better results?

### Step 5: Diagnose and Fix

Generate a diagnosis report:

```markdown
## Diagnosis Report

**Agent/Skill**: [name]
**Symptom**: [what's wrong]
**Root Cause**: [diagnosed cause]
**Confidence**: [high/medium/low]

### Evidence
1. [Finding 1 — e.g., "Agent .md file has read: deny but needs to read files"]
2. [Finding 2 — e.g., "Task prompt doesn't mention CodeGraph availability"]
3. [Finding 3 — e.g., "Permission.skill missing required skill name"]

### Recommended Fix
[Specific, actionable fix — e.g., "Add `read: allow` and `glob: allow` to agent's permission block"]

### Verification
[How to confirm the fix works — e.g., "Re-run the agent with a test prompt and verify it reads files"]
```

## Common Problem Patterns

### Pattern: Agent Produces Generic Output

**Cause**: Task prompt is too vague; agent lacks project-specific context.
**Fix**: Include file paths, technology stack, and specific requirements in the Task prompt.

### Pattern: Agent Can't Find Files

**Cause**: `glob: deny` or `read: deny` in permission block.
**Fix**: Add `glob: allow` and `read: allow` to permissions.

### Pattern: Agent Ignores Skills

**Cause**: Skill not in `permission.skill` allowlist, or skill name doesn't match directory.
**Fix**: Verify skill names match exactly (case-sensitive, with `-skill` suffix).

### Pattern: Agent Loops Repeatedly

**Cause**: Missing termination condition in agent instructions; unclear success criteria.
**Fix**: Add explicit "return contract" with clear completion criteria to the agent .md file.

### Pattern: Agent Doesn't Use CodeGraph

**Cause**: `.codegraph/` doesn't exist in project, or Task prompt doesn't mention CodeGraph.
**Fix**: Initialize CodeGraph (`codegraph init -i`) and include CodeGraph guidance in Task prompts.

### Pattern: Skill Doesn't Trigger

**Cause**: Primary agent doesn't know when to load the skill; trigger phrases not in skill description.
**Fix**: Ensure skill description clearly states when to use it; add trigger phrases to "When to use me" section.

### Pattern: Subagent Returns Irrelevant Output

**Cause**: Task prompt not specific enough; subagent exploring wrong area.
**Fix**: Constrain the Task prompt with specific file paths, function names, and expected output format.

### Pattern: MCP Tools Not Called

**Cause**: MCP server not configured in `opencode.json`, or agent doesn't know the tool exists.
**Fix**: Check `opencode_app/opencode.json` → `mcpServers` section for the expected server.

## Diagnostic Tools

| Tool | Purpose | When to Use |
|------|---------|------------|
| `glob` | Find agent/skill files | Verifying file existence |
| `read` | Read agent .md or SKILL.md content | Checking configuration, permissions |
| `grep` | Search for tool references, permission rules | Finding why tools aren't accessible |
| `codegraph_search` | Find symbol definitions agents reference | Verifying agent references valid code |

## Integration with Other Skills

| Skill | Integration |
|-------|-------------|
| `context-budget-skill` | Budget audit may reveal agent is consuming too much context |
| `continuous-learning-skill` | Store debugging findings as anti-patterns for future reference |
| `eval-harness-skill` | Evaluate whether fix improved agent output quality |
| `opencode-skills-maintainer-skill` | Validate skill format after fixing issues |
| `opencode-agent-creation-skill` | Reference agent creation best practices when fixing agents |

## Best Practices

### Preventing Agent Issues
- Always set `steps` limit (recommended: 10-25)
- Always include a return contract in agent .md files
- Test new agents with a simple prompt before complex tasks
- Keep agent descriptions under 50 words (loaded into Task tool always)
- Use `permission.skill` to give agents access to domain knowledge

### Preventing Skill Issues
- Match skill directory name exactly in YAML `name` field
- Include clear trigger phrases in "When to use me" section
- Test skills by loading them explicitly before relying on auto-discovery
- Keep skill descriptions specific (helps primary agent select the right skill)

### Debugging Efficiency
- Start with configuration validation (most common issues)
- Check permissions before analyzing behavior (quick win)
- Compare against working agents/skills as reference
- Make one change at a time and re-test
- Document fixes as learnings for future debugging

## Example Usage

### Debug a subagent that won't edit files

```
"The repo-ops-specialist-subagent reads files but never edits them"
```

The skill will:
1. Read `repo-ops-specialist-subagent.md` configuration
2. Check `permission.edit` field
3. Diagnose: likely `edit: deny` in permission block
4. Recommend: change to `edit: allow`
5. Provide exact edit to make

### Debug a skill that doesn't trigger

```
"The search-first-skill never gets loaded when I ask about libraries"
```

The skill will:
1. Verify skill directory and SKILL.md exist
2. Check skill description for relevant trigger phrases
3. Verify the skill name matches directory name exactly
4. Diagnose: likely missing trigger phrases or unclear description
5. Recommend: add "library" and "find existing" to trigger phrases

### Debug an agent that produces generic output

```
"The architecture-review-subagent gives generic advice instead of specific feedback"
```

The skill will:
1. Read agent configuration and Task prompt pattern
2. Check if CodeGraph tools are referenced
3. Check if project-specific context is being passed
4. Diagnose: likely Task prompt lacks file paths and project context
5. Recommend: include CodeGraph guidance and specific file references in Task prompt

## References

- `opencode-agent-creation-skill` - Agent creation best practices
- `opencode-skill-creation-skill` - Skill creation best practices
- `opencode-skills-maintainer-skill` - Skill format validation
- `continuous-learning-skill` - Store debugging patterns
