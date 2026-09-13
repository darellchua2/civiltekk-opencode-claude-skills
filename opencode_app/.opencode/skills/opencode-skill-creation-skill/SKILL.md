---
name: opencode-skill-creation-skill
description: Generate OpenCode skills following official documentation best practices
license: Apache-2.0
compatibility: opencode
category: OpenCode Meta
---

## What I do

I guide you through creating a new OpenCode skill from scratch by:

1. **Collect Requirements**: Prompt for skill name, description, purpose, and category
2. **Generate Frontmatter**: Create proper YAML frontmatter with all required fields
3. **Structure Content**: Build complete skill documentation following official standards
4. **Validate**: Ensure skill meets naming rules and documentation guidelines
5. **Create Files**: Write SKILL.md to appropriate directory structure

## When to use me

Use this when:
- You want to create a new OpenCode skill without manually formatting SKILL.md
- You need to ensure your skill follows official documentation standards
- You want to avoid repetitive setup when creating multiple skills

Ask clarifying questions about:
- Skill's primary purpose and capabilities
- Category for the installer registry (testing, linting, deployment, etc.)
- Prerequisites and dependencies
- Expected inputs and outputs

## Prerequisites

- Write access to the skills/ directory
- Understanding of OpenCode skill structure
- Knowledge of the skill's purpose and requirements
- Python 3+ for YAML validation (optional but recommended)

## Steps

### Step 1: Gather Skill Requirements

Prompt the user for the following information:

**Required Fields**:
- **Name**: Unique skill identifier (1-64 chars, lowercase alphanumeric with single hyphens)
- **Description**: Brief description (1-1024 chars) specific enough for agents to choose correctly
- **License**: Usually "Apache-2.0" but can be specified

**Optional Fields**:
- **Compatibility**: Usually "opencode" but can specify framework compatibility
- **Category**: Installer-registry grouping (required by build-registry.mjs, init.mjs, setup.sh counts — invisible to OpenCode runtime but never omit)
- **Metadata**: Opaque string map; only `protocol`/`pattern` are house-kept (bats/registry test signals). Do not add audience/workflow/languages/trigger keys

**Prompt Template**:
```
Please provide the following information for your new skill:

1. **Skill Name**: (lowercase, alphanumeric, single hyphens, 1-64 chars)
2. **Description**: (1-1024 characters, specific for skill selection)
3. **License**: (default: Apache-2.0)
4. **Compatibility**: (default: opencode)
5. **Target Audience**: (e.g., developers, DevOps, QA)
6. **Workflow Type**: (e.g., testing, linting, deployment)

Example:
  - Name: python-pytest-creator
  - Description: Generate comprehensive pytest test files for Python using test-generator-framework
  - Audience: developers
  - Workflow: testing
```

### Step 2: Validate Skill Name

Ensure the skill name follows naming rules:

```bash
# Check name length (1-64 characters)
if [ ${#skill_name} -lt 1 ] || [ ${#skill_name} -gt 64 ]; then
  echo "Error: Skill name must be 1-64 characters"
  exit 1
fi

# Check for valid characters (lowercase alphanumeric and single hyphens)
if [[ ! $skill_name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Error: Skill name must be lowercase alphanumeric with single hyphens"
  exit 1
fi

# Check for double hyphens
if [[ $skill_name =~ -- ]]; then
  echo "Error: Skill name cannot contain double hyphens"
  exit 1
fi

# Check for leading/trailing hyphens
if [[ $skill_name =~ ^- || $skill_name =~ -$ ]]; then
  echo "Error: Skill name cannot start or end with hyphens"
  exit 1
fi
```

### Step 3: Generate YAML Frontmatter

Create the frontmatter section with all provided fields:

```yaml
---
name: <skill-name>
description: <skill-description>
license: <license-type>
compatibility: opencode
category: <registry-category>
---
```

**Example**:
```yaml
---
name: python-pytest-creator
description: Generate comprehensive pytest test files for Python using test-generator-framework
license: Apache-2.0
compatibility: opencode
category: testing
---
```

**Important**: Only these frontmatter fields are recognized by OpenCode:
- `name` (required, MUST equal the directory name)
- `description` (required, 1-1024 characters; house style ≤50 words with trigger phrases)
- `license` (optional)
- `compatibility` (optional)
- `metadata` (optional, string-to-string map)

Unknown frontmatter fields are ignored by OpenCode. `category` is installer-registry-only (required by this repo's tooling). After any frontmatter change, run `node deploy/build-registry.mjs` and commit `registry.json`.

### Step 4: Build Skill Content

Structure the skill documentation with the following sections:

#### Required Sections

**"## What I do"** (What the skill achieves):
- List primary capabilities (3-7 items)
- Use bullet points with action verbs
- Be specific about what the skill does
- Include any frameworks or tools used

**"## When to use me"** (Usage scenarios):
- List scenarios when to use this skill
- Use bullet points with specific conditions
- Include examples of tasks
- Mention alternatives (if any)

#### Optional Sections (Recommended)

**"## Prerequisites"**: Requirements to run the skill
**"## Steps"**: Detailed workflow steps
**"## Best Practices"**: Recommended approaches
**"## Common Issues"**: Troubleshooting guide
**"## Verification Commands"**: Commands to validate results

### Step 5: Create Directory and File

Create the skill directory structure:

```bash
# Create skill directory
mkdir -p "skills/<skill-name>"

# Create SKILL.md file
touch "skills/<skill-name>/SKILL.md"
```

**Example**:
```bash
mkdir -p skills/python-pytest-creator-skill
touch skills/python-pytest-creator-skill/SKILL.md
```

### Step 6: Write Skill Documentation

Write the complete SKILL.md file:

```bash
# For NEW files (created in Step 5), you can write directly:
cat > "skills/<skill-name>/SKILL.md" << 'EOF'
---
name: <skill-name>
description: <skill-description>
license: <license-type>
compatibility: opencode
category: <registry-category>
---

## What I do

- [Capability 1]
- [Capability 2]
- [Capability 3]

## When to use me

Use this when:
- [Scenario 1]
- [Scenario 2]

## [Optional sections...]

EOF

# For EXISTING files, ALWAYS read first:
# 1. Read the file
read filePath="PLAN.md"

# 2. Now use edit to make targeted changes
edit filePath="PLAN.md" oldString="old content" newString="new content"

# OR use write with full content (only if you have the full context)
write filePath="PLAN.md" content="full updated content after reading"
```

### Step 7: Validate Created Skill

Verify the skill was created correctly:

```bash
# Check file exists
if [ ! -f "skills/<skill-name>/SKILL.md" ]; then
  echo "Error: SKILL.md was not created"
  exit 1
fi

# Validate YAML syntax (requires python3 and pyyaml)
python3 -c "import yaml; yaml.safe_load(open('skills/<skill-name>/SKILL.md'))" 2>&1

# Check frontmatter fields
grep -q "^name:" "skills/<skill-name>/SKILL.md" || echo "Warning: Missing 'name' field"
grep -q "^description:" "skills/<skill-name>/SKILL.md" || echo "Warning: Missing 'description' field"
```

## Best Practices

### Naming Conventions

- **Use descriptive names**: `python-pytest-creator` (good), `skill-1` (bad)
- **Include workflow type**: `-test`, `-lint`, `-setup`, `-workflow`
- **Follow lowercase**: `nextjs-standard-setup` (good), `NextJS-Standard-Setup` (bad)
- **Single hyphens only**: `git-pr-creator` (good), `git--pr-creator` (bad)
- **No underscores**: `python_pytest` (bad), `python-pytest` (good)

### Description Guidelines

- **Be specific**: "Generate pytest tests" (good), "Create tests" (vague)
- **Include framework**: "using test-generator-framework" (good)
- **Mention capabilities**: "for Next.js 16 with App Router" (good)
- **Length**: 1-1024 characters (optimal: 50-150 chars)

### Content Structure

- **Start with capabilities**: "## What I do" section first
- **Follow with scenarios**: "## When to use me" section
- **Add details**: Optional sections based on complexity
- **Use code blocks**: Include examples with triple backticks
- **Be thorough**: More detail is better than less

### File Safety

- **ALWAYS read before writing**: Use `read` tool before `write` or `edit` on any existing file
- The `write` tool completely overwrites existing files — reading first prevents data loss
- Use `edit` for targeted changes; only use `write` when you have the complete file content
- Common files requiring read-first: PLAN.md, README.md, SKILL.md, config.json

### Validation

- **Always validate YAML**: Check frontmatter syntax
- **Test the skill**: Try using it after creation
- **Review documentation**: Ensure clarity and completeness
- **Check naming**: Verify skill follows naming conventions

### Configuring Skill Permissions

Skills can be controlled via permissions in agent configurations: frontmatter (legacy `permission.skill` map spelling — opencode v2 auto-translates) or the v2 `permissions` array in config.json:

**For custom agents (markdown frontmatter)**:
```yaml
---
description: My agent description
mode: subagent
permission:
  skill:
    "documents-*": allow
    "internal-*": deny
    "experimental-*": ask
---
```

**For built-in agents (config.json)** — v2 `permissions` array (last matching rule wins; deny rules first, allows after):
```json
{
  "agents": {
    "plan": {
      "permissions": [
        { "action": "skill", "resource": "*", "effect": "allow" },
        { "action": "skill", "resource": "internal-*", "effect": "deny" }
      ]
    }
  }
}
```

Permission behaviors:
- `allow`: Skill loads immediately
- `deny`: Skill hidden from agent, access rejected
- `ask`: User prompted for approval before loading

Note: The legacy `tools: skill: false` approach is deprecated. Use skill rules (`action:"skill"`) in the `permissions` array (config) or agent frontmatter instead — frontmatter still uses the legacy `permission.skill` map spelling, which opencode v2 auto-translates.

## Common Issues

### Invalid Skill Name

**Issue**: Skill name doesn't follow naming rules

**Solution**:
```bash
# Valid examples
python-pytest-creator ✓
nextjs-standard-setup ✓
linting-workflow ✓

# Invalid examples
PythonPytestCreator ✗ (uppercase)
python--pytest ✗ (double hyphens)
-python ✗ (leading hyphen)
python_ ✗ (underscore)
```

### YAML Validation Errors

**Issue**: Frontmatter has invalid YAML syntax

**Solution**:
- Check for proper indentation (2 spaces for lists)
- Ensure quotes around special characters
- Verify no trailing spaces after colons
- Use Python YAML validator:
  ```bash
  python3 -c "import yaml; yaml.safe_load(open('SKILL.md'))"
  ```

### Description Too Vague

**Issue**: Agents can't determine when to use the skill

**Solution**:
- Include specific frameworks or tools
- Mention target languages or domains
- Specify workflow type (testing, linting, etc.)
- Keep description between 50-150 characters

**Bad**: "Create tests for code"
**Good**: "Generate comprehensive pytest test files for Python using test-generator-framework"

### Accidental Data Loss

**Issue**: File content overwritten when using `write` tool without reading first

**Solution**:
- **ALWAYS use `read` before `write` or `edit` on existing files**
- The `write` tool completely overwrites files without warning
- Always read the file first to see existing content
- Use `edit` for targeted changes when possible
- Only use `write` when you have the complete file content

**Example of What NOT To Do**:
```bash
# BAD - This overwrites everything!
write filePath="PLAN.md" content="just the new tasks"
```

**Correct Approach**:
```bash
# GOOD - Read first to preserve existing content
read filePath="PLAN.md"
# Now you have the full context
edit filePath="PLAN.md" oldString="old text" newString="new text"
```

**Common Files Requiring Read First**:
- **PLAN.md** – Contains task statuses that must be preserved
- **README.md** – Contains documentation structure
- **Existing SKILL.md** – Contains complete skill documentation
- **config.json** – Contains agent and MCP server configurations

## Configuring Agent Access to Skills

When creating skills, consider how agents will access them. Use skill rules (`action:"skill"`) in the `permissions` array (config.json) or agent frontmatter:

**Pattern-based Permissions**:

| Pattern | Example Matches | Behavior |
|---------|-----------------|----------|
| `*` | All skills | Wildcard match |
| `prefix-*` | `prefix-docs`, `prefix-tools` | Prefix wildcard |
| `*-suffix` | `docs-suffix`, `tools-suffix` | Suffix wildcard |
| `exact-name` | `exact-name` only | Exact match |

**Permission Values**:
- `allow`: Skill loads immediately
- `deny`: Skill hidden from agent, access rejected
- `ask`: User prompted for approval before loading

**Example Agent Config**:
```yaml
---
description: Read-only exploration agent
mode: subagent
permission:
  read: allow
  write: deny
  edit: deny
  bash: deny
  skill:
    "*": deny
    "explore-*": allow
    "code-search": allow
---
```

This agent can only access skills matching `explore-*` or `code-search`, all others are denied.

## Verification Commands

After creating a skill, verify with these commands:

```bash
# 1. Check skill directory exists
ls -la skills/<skill-name>/

# 2. Verify SKILL.md exists
test -f skills/<skill-name>/SKILL.md && echo "✓ SKILL.md exists"

# 3. Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('skills/<skill-name>/SKILL.md'))" && echo "✓ YAML valid"

# 4. Check required fields
grep "^name:" skills/<skill-name>/SKILL.md && echo "✓ Name field present"
grep "^description:" skills/<skill-name>/SKILL.md && echo "✓ Description field present"
```

**Verification Checklist**:
- [ ] Skill name follows naming rules (1-64 chars, lowercase, single hyphens)
- [ ] SKILL.md file created in skills/<skill-name>/ directory
- [ ] YAML frontmatter is valid and complete
- [ ] "## What I do" section is present and descriptive
- [ ] "## When to use me" section is present and specific
- [ ] Optional sections added based on complexity
- [ ] Skill can be invoked and executes correctly
- [ ] **Read tool was used before modifying any existing files** (PLAN.md, README.md, etc.)

## Example Output

### Created Skill: python-pytest-creator-skill

**Location**: `skills/python-pytest-creator-skill/SKILL.md`

**Frontmatter**:
```yaml
---
name: python-pytest-creator-skill
description: Generate comprehensive pytest test files for Python using test-generator-framework
license: Apache-2.0
compatibility: opencode
category: testing
---
```

**Content Sections**:
- ✓ What I do (5 capabilities listed)
- ✓ When to use me (4 scenarios described)
- ✓ Prerequisites (3 requirements)
- ✓ Steps (7 detailed steps)
- ✓ Best Practices (5 guidelines)
- ✓ Verification Commands (4 commands)

**Validation**:
- ✓ YAML valid
- ✓ Required fields present
- ✓ Naming conventions followed
- ✓ Description is specific (78 characters)

