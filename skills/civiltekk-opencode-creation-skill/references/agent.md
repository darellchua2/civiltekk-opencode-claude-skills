# Agent variant (values)

Everything needed to generate or edit an OpenCode agent. The host SKILL.md
carries the METHOD (detect → route → load); this file carries the VALUES.

## What this variant does

- Guide you through creating a new OpenCode agent by prompting for required configuration
- Generate agent files in Markdown format with proper YAML frontmatter
- Determine appropriate mode (primary or subagent) based on agent purpose
- Configure permissions, temperature, steps, and other agent options
- Create agent files in `.opencode/agents/` (project) or `~/.config/opencode/agents/` (global)
- Ensure description is provided and all required fields are set correctly
- Validate frontmatter against current OpenCode documentation standards

## When to use this variant

- You want to create a new OpenCode agent without manually formatting configuration
- You need to ensure your agent follows official documentation standards
- You want to avoid repetitive setup when creating multiple agents
- You're creating specialized subagents for specific tasks
- You need to configure tool permissions and access levels

Ask clarifying questions about:

- Agent's purpose and intended behavior
- Mode: primary (main assistant) or subagent (specialized)
- Required tool permissions
- Whether it should be project-level or global

## Prerequisites

- Write access to `.opencode/agents/` (project) or `~/.config/opencode/agents/` (global)
- Understanding of OpenCode agent structure and frontmatter
- Knowledge of the agent's purpose and required permissions

## Requirements intake

**Required Fields**:
- **Name**: Agent identifier (lowercase, hyphens, e.g., `code-reviewer`)
- **Description**: Brief description of what the agent does (REQUIRED)
- **Mode**: `primary` or `subagent`

**Configuration Options**:
- **Model**: Provider/model-id — primary agents use `zai-coding-plan/glm-5.3` (1M context); subagents tier by purpose (see `installer/agent-tiers.json`): `glm-5.3` (reasoning/review/refactor), `glm-5.3-flash` (explore/low-impact and docs/lint), `zai-coding-plan/glm-5.3-flash` (vision — native multimodal, image/video/pdf input; `image-analyzer-subagent`/`error-resolver-subagent`/`uiux-reviewer-subagent` run here and see images directly, no vision MCP server needed; for text-only sessions they embed an inline direct-API fallback recipe calling `glm-5.3-flash` directly over HTTP). Never default a subagent to the `primary` tier.
- **Temperature**: 0.0-1.0 (default: 0.7)
- **Steps**: Max agentic iterations (default: 5)
- **Hidden**: Hide from @ autocomplete (default: false, subagents only)
- **Color**: UI color — hex or named value (e.g., `primary`, `#FF5733`)
- **Permissions**: Tool access configuration

**Prompt Template**:
```
Please provide the following information for your new agent:

1. **Agent Name**: (lowercase, hyphens, e.g., code-reviewer)
2. **Description**: (what this agent does)
3. **Mode**: primary | subagent
4. **Model**: (default: uses system default)
5. **Temperature**: (default: 0.7, range: 0.0-1.0)
6. **Steps**: (max iterations, default: 5)
7. **Scope**: project | global

For subagents, also specify:
8. **Hidden**: Should this be hidden from @ autocomplete? (default: false)
9. **Color**: UI color (hex or named: primary, accent)

Example:
  - Name: code-reviewer
  - Description: Review code for quality, security, and best practices
  - Mode: subagent
  - Model: zai-coding-plan/glm-5.3
  - Temperature: 0.3
  - Steps: 3
  - Scope: project
```

## Scope (project vs global)

| Scope | Location | Use Case |
|-------|----------|----------|
| Project | `.opencode/agents/<name>.md` | Team-shared, project-specific |
| Global | `~/.config/opencode/agents/<name>.md` | Personal, available across projects |

Ask where the agent should be created; options: "Project level (Recommended)"
or "User level (global)".

## Name validation

Ensure the agent name follows naming conventions (the host's question round
gathers it; validate before writing):

```bash
# Check name format (lowercase, hyphens)
if [[ ! $agent_name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Error: Agent name must be lowercase alphanumeric with single hyphens"
  exit 1
fi

# Check for double hyphens
if [[ $agent_name =~ -- ]]; then
  echo "Error: Agent name cannot contain double hyphens"
  exit 1
fi

# Check for leading/trailing hyphens
if [[ $agent_name =~ ^- || $agent_name =~ -$ ]]; then
  echo "Error: Agent name cannot start or end with hyphen"
  exit 1
fi
```

## Frontmatter generation

Create the frontmatter section based on agent type:

**Primary Agent Example**:
```yaml
---
description: Main coding assistant for Python development
mode: primary
model: zai-coding-plan/glm-5.3
temperature: 0.7
steps: 10
permission:
  read: allow
  write: allow
  edit: allow
  bash: ask
  webfetch: allow
color: primary
---
```

**Subagent Example**:
```yaml
---
description: Review code for quality and security issues
mode: subagent
model: zai-coding-plan/glm-5.3
temperature: 0.3
steps: 3
hidden: true
permission:
  read: allow
  write: deny
  edit: deny
  bash: deny
  webfetch: allow
  task:
    "*": deny
    "testing-*": allow
color: "#FF5733"
---
```

## Permissions configuration

**Permission Values**:
- `allow`: Operation permitted without approval
- `ask`: Prompt for approval before operation
- `deny`: Operation disabled

**Common Permission Patterns**:

| Agent Type | read | write | edit | bash | webfetch |
|------------|------|-------|------|------|----------|
| Code reviewer | allow | deny | deny | deny | allow |
| Code generator | allow | allow | allow | ask | allow |
| Read-only explorer | allow | deny | deny | deny | deny |
| DevOps agent | allow | allow | allow | allow | allow |

**Task Permissions** (for subagents that spawn other subagents):
```yaml
permission:
  task:
    "*": deny
    "reviewer-*": allow
    "testing-*": allow
```

**Skill Permissions**:
```yaml
permission:
  skill:
    "*": deny
    "python-*": allow
    "testing-*": allow
```

## Body (system prompt) structure

Structure the agent instructions:

```markdown
You are a [agent purpose] specialized in [domain/task].

## Core Responsibilities

1. [Primary responsibility]
2. [Secondary responsibility]
3. [Additional responsibilities]

## When to Use

This agent is invoked when:
- [Condition 1]
- [Condition 2]

## Behavior Guidelines

- [Guideline 1]
- [Guideline 2]

## Output Format

[Describe expected output format]
```

## File creation

**IMPORTANT: Always use `read` tool before using `write` or `edit` on existing files.**

```bash
# For NEW files, write directly:
# Project-level
write filePath=".opencode/agents/<name>.md" content="<frontmatter + content>"

# Global
write filePath="$HOME/.config/opencode/agents/<name>.md" content="<frontmatter + content>"
```

## Validation & verification

Verify the agent was created correctly:

```bash
# Check file exists
test -f ".opencode/agents/<name>.md" && echo "✓ Agent file created"

# Validate YAML frontmatter (requires python3 and pyyaml)
python3 -c "import yaml; yaml.safe_load(open('.opencode/agents/<name>.md'))" && echo "✓ Valid frontmatter"

# Check required fields
grep -q "^description:" ".opencode/agents/<name>.md" && echo "✓ Has description"
grep -q "^mode:" ".opencode/agents/<name>.md" && echo "✓ Has mode"
```

Post-creation verification commands:

```bash
# List all project-level agents
ls -la .opencode/agents/

# List all global agents
ls -la ~/.config/opencode/agents/

# Validate agent frontmatter
python3 -c "import yaml; yaml.safe_load(open('.opencode/agents/<name>.md'))"

# Check for required fields
grep -E "^(description|mode):" .opencode/agents/<name>.md
```

**Verification Checklist**:
- [ ] Agent name follows naming conventions
- [ ] Agent file created in correct location
- [ ] YAML frontmatter is valid
- [ ] `description` field present and descriptive
- [ ] `mode` specified (`primary` or `subagent`)
- [ ] Using `permission` not `tools`
- [ ] Using `steps` not `maxSteps`
- [ ] Task/skill permissions configured if needed
- [ ] `hidden` only set for subagents

## Best practices

### Naming Conventions

- **Use descriptive names**: `code-reviewer` (good), `agent-1` (bad)
- **Include role**: `security-scanner`, `test-generator`, `doc-writer`
- **Follow lowercase**: `api-tester` (good), `APITester` (bad)
- **Single hyphens only**: `code-reviewer` (good), `code--reviewer` (bad)

### Mode Selection

**Use `primary` when**:
- Agent is a main assistant users interact with directly
- Agent should be cycled via Tab key
- Agent handles general-purpose tasks

**Use `subagent` when**:
- Agent performs specialized, focused tasks
- Agent is invoked via @mention or Task tool
- Agent has limited scope and permissions

### Temperature Guidelines

| Temperature | Use Case |
|-------------|----------|
| 0.0-0.3 | Code review, security analysis, linting |
| 0.4-0.6 | Code generation, refactoring, documentation |
| 0.7-0.9 | Creative tasks, brainstorming, exploration |
| 1.0 | Maximum creativity, unpredictable outputs |

### Steps Configuration

- **Low (1-3)**: Simple, focused tasks (review, analysis)
- **Medium (4-7)**: Standard tasks (generation, refactoring)
- **High (8-15)**: Complex tasks (multi-file changes, integration)

### Security Considerations

- **Deny bash access** for read-only agents
- **Use `ask` for destructive operations** (write, edit, bash)
- **Limit task spawning** to prevent recursive agent chains
- **Restrict skill access** to only what's needed

## Common issues

### Invalid Frontmatter

**Issue**: Agent file has malformed YAML frontmatter

**Solution**:
```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('.opencode/agents/<name>.md'))"
```

### Missing Required Fields

**Issue**: Agent missing `description` or `mode` field

**Solution**:
- `description` is REQUIRED - every agent must have one
- `mode` must be either `primary` or `subagent`

### Deprecated Fields

**Issue**: Using deprecated field names

**Solution**:
- Replace `tools` with `permission`
- Replace `maxSteps` with `steps`
- Remove any `api_key` fields (use environment variables)

### Permission Errors

**Issue**: Agent cannot access required tools

**Solution**:
- Review `permission` section in frontmatter
- Ensure needed tools are set to `allow` or `ask`
- Check for pattern-based permissions (e.g., `task: "reviewer-*": allow`)

## Example output

### Created Agent: code-reviewer

**Location**: `.opencode/agents/code-reviewer.md`

**Frontmatter**:
```yaml
---
description: Review code for quality, security, and best practices
mode: subagent
model: zai-coding-plan/glm-5.3
temperature: 0.3
steps: 3
hidden: true
permission:
  read: allow
  write: deny
  edit: deny
  bash: deny
  webfetch: allow
color: "#FF5733"
---
```

**Content Sections**:
- ✓ Core responsibilities defined
- ✓ When to use conditions specified
- ✓ Behavior guidelines included
- ✓ Output format documented

**Validation**:
- ✓ YAML valid
- ✓ Required fields present
- ✓ Naming conventions followed
- ✓ Permissions configured appropriately
