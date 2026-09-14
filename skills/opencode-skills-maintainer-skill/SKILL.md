---
name: opencode-skills-maintainer-skill
description: Scan, validate, and audit OpenCode skills for consistency, redundancy, and modularization opportunities
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: OpenCode Meta
---

## What I do

I maintain skill consistency, quality, and efficiency by:

1. **Discover All Skills**: Scan the `skills/` folder to discover all available skills
2. **Extract Skill Metadata**: Read frontmatter from each SKILL.md file (name, description, category)
3. **Validate Skill Structure**: Ensure all skills have required fields and valid frontmatter
4. **Categorize Skills**: Organize skills into logical categories (Framework, Test Generators, Linters, etc.)
5. **Detect Redundancy**: Identify overlapping functionality, duplicate capabilities, and consolidation opportunities
6. **Analyze Modularization**: Recommend skill decomposition and reusable component extraction
7. **Generate Report**: Provide comprehensive summary with validation status and optimization recommendations

## When to use me

Use this skill when:
- You want to audit all skills in the repository
- You need to validate skill metadata consistency
- You're checking for missing required fields in SKILL.md files
- You want a categorized list of all available skills
- You're debugging skill discovery issues
- You need to identify redundant functionality across multiple skills
- You're planning to refactor or consolidate the skill library
- You want to improve maintainability and reduce code duplication in skills

## Prerequisites

- Access to the repository root directory
- `jq` tool installed for JSON validation
- Python 3+ installed for YAML parsing

## Steps

### Step 1: Discover All Skills

Scan the `skills/` folder to find all skill directories:

```bash
# Find all skill directories
find skills/ -name "SKILL.md" -type f | sort
```

### Step 2: Extract Skill Metadata

For each skill, read the frontmatter to extract:

```bash
# Extract name and description from frontmatter
for skill_dir in skills/*/; do
  echo "=== $(basename "$skill_dir") ==="
  head -10 "$skill_dir/SKILL.md" | grep -E "(name:|description:)" | head -2
  echo
done
```

**Required Fields**:
- `name`: The skill identifier
- `description`: Brief description of what the skill does
- Optional: `category`, `workflow`, `audience` (from metadata section)

### Step 3: Validate Skill Structure

Check all skills for required fields and valid frontmatter:

```bash
# Validate all SKILL.md files
for dir in skills/*/; do
  skill_name=$(basename "$dir")
  echo "Validating: $skill_name"
  
  # Check for required fields
  if ! grep -q "^name:" "$dir/SKILL.md"; then
    echo "  ❌ Missing 'name:' field"
  else
    echo "  ✓ Has 'name:' field"
  fi
  
  if ! grep -q "^description:" "$dir/SKILL.md"; then
    echo "  ❌ Missing 'description:' field"
  else
    echo "  ✓ Has 'description:' field"
  fi
  
  # Validate YAML syntax (requires python3 and pyyaml)
  if python3 -c "import yaml; yaml.safe_load(open('$dir/SKILL.md'))" 2>&1; then
    echo "  ✓ Valid YAML frontmatter"
  else
    echo "  ❌ Invalid YAML frontmatter"
  fi
done
```

### Step 4: Categorize Skills

Organize skills into logical categories based on naming patterns:

| Category | Pattern | Examples |
|----------|---------|----------|
| Framework | `*-framework`, `*-workflow` | linting-workflow, test-generator-framework |
| Git/Workflow | `git-*`, `jira-*`, `pr-*`, `ticket-*` | ticket-creation-skill, jira-git-integration |
| OpenTofu/IaC | `opentofu-*` | opentofu-aws-explorer, opentofu-kubernetes-explorer |
| OpenCode Meta | `opencode-*` | opencode-agent-creation, opencode-skill-creation |
| Language-Specific | `{lang}-*`, `{framework}-*` | python-pytest-creator, nextjs-unit-test-creator |
| Code Quality | `*-linter`, `*-principle`, `*-generator` | python-ruff-linter, docstring-generator |
| Utilities | Other single-purpose | ascii-diagram-creator, tdd-workflow |

**Categorization Rule**: Match skill name against patterns above. First match wins.

### Step 5: Detect Redundancy & Modularization

Analyze skills for overlap and optimization opportunities:

**Redundancy Detection**:
- Compare skill descriptions for overlapping functionality
- Identify similar capability patterns across skills
- Flag skills with near-identical purposes or audiences
- Map skill interdependencies and coupling relationships

**Granularity Assessment**:
- Evaluate whether skills can be broken down into smaller, reusable components
- Identify compound skills that contain multiple distinct capabilities
- Assess potential for extracting shared functionality into base skills

**Analysis Commands**:
```bash
# Find skills with similar descriptions
grep -h "^description:" skills/*/SKILL.md | sort | uniq -c | sort -nr

# Analyze skill distribution by workflow type
grep -A1 "workflow:" skills/*/SKILL.md | grep "workflow:" | sort | uniq -c

# Check for naming convention compliance
ls skills/ | grep -E "^[a-z0-9]+(-[a-z0-9]+)*$"
```

**Modularization Opportunities**:
- Compound skills that can be broken into smaller components
- Shared functionality that could be extracted into base skills
- Skills that reference or build upon other skills
- Consolidation candidates with migration paths

### Step 6: Generate Report

Create a summary of all skills:

```markdown
# Skills Maintenance Report

## Skills Found: {total_count}

### Validation Summary
- ✓ Valid skills: {count}
- ❌ Invalid skills: {count}
- ⚠️ Missing optional fields: {count}

### Categories
- Framework Skills: {count}
- Language-Specific Test Generators: {count}
- Language-Specific Linters: {count}
- Project Setup: {count}
- Git/Workflow: {count}
- OpenCode Meta: {count}
- OpenTofu/Infrastructure: {count}
- Code Quality/Documentation: {count}
- Utilities: {count}

### Issues Found (if any)
- [skill-name]: Missing required field 'description'
- [skill-name]: Invalid YAML frontmatter

## Validation
✓ All required fields present
✓ All YAML frontmatter valid
✓ All skills categorized correctly
```

## Best Practices

### Categorization Logic

- **Framework**: Foundational workflows (`*-framework`, `*-workflow`)
- **Language-Specific**: Skills for specific languages/frameworks (`{lang}-*`, `{framework}-*`)
- **Meta**: Skills that create/audit other skills or agents (`opencode-*`)
- **Domain-Specific**: Skills for specific domains (`opentofu-*`, `git-*`, `jira-*`)

### Validation Rules

1. **Required Fields**: Every SKILL.md must have `name` and `description` in frontmatter
2. **YAML Syntax**: Frontmatter must be valid YAML
3. **File Naming**: Skill directory name should match the skill name (lowercase, hyphens)
4. **Description Length**: Keep descriptions between 50-150 characters

## Common Issues

### SKILL.md Not Found

**Issue**: Cannot find SKILL.md in a skill directory

**Solution**:
```bash
# Verify SKILL.md exists for all skills
for dir in skills/*/; do
  if [ ! -f "$dir/SKILL.md" ]; then
    echo "Missing SKILL.md in: $dir"
  fi
done
```

### Invalid Frontmatter

**Issue**: SKILL.md has missing or malformed frontmatter

**Solution**:
```bash
# Check for required frontmatter fields
for dir in skills/*/; do
  if ! grep -q "^name:" "$dir/SKILL.md"; then
    echo "Missing 'name:' field in: $dir/SKILL.md"
  fi
  if ! grep -q "^description:" "$dir/SKILL.md"; then
    echo "Missing 'description:' field in: $dir/SKILL.md"
  fi
done
```

### YAML Parse Errors

**Issue**: Python YAML parser fails on SKILL.md

**Solution**:
- Check for unclosed quotes in frontmatter
- Ensure proper indentation
- Verify no trailing spaces in YAML keys
- Check for special characters that need escaping

## Verification Commands

After running this skill, verify with these commands:

```bash
# Count total skills
find skills/ -name "SKILL.md" -type f | wc -l

# List all skill names
for dir in skills/*/; do
  grep "^name:" "$dir/SKILL.md" | head -1
done | sort

# Validate all YAML frontmatter
for dir in skills/*/; do
  python3 -c "import yaml; yaml.safe_load(open('$dir/SKILL.md'))" 2>&1 && echo "✓ $(basename $dir)"
done
```

**Verification Checklist**:
- [ ] All skill directories have SKILL.md files
- [ ] All SKILL.md files have valid YAML frontmatter
- [ ] All skills have required `name` field
- [ ] All skills have required `description` field
- [ ] Skill names match directory names
- [ ] All skills are categorized correctly
- [ ] Descriptions are concise and accurate

## Example Output

**Skills Found: 46**

### Validation Summary
- ✓ Valid skills: 46
- ❌ Invalid skills: 0
- ⚠️ Missing optional fields: 2

### Categories
- Framework Skills: 7
- Git/Workflow: 12
- OpenTofu/IaC: 7
- OpenCode Meta: 3
- Language-Specific: 6
- Code Quality: 8
- Utilities: 3

### Skills Missing Optional Fields
- ascii-diagram-creator: Missing 'workflow' metadata
- tdd-workflow: Missing 'audience' metadata

## Validation
✓ All required fields present
✓ All YAML frontmatter valid
✓ All skills categorized correctly

## Citation drift audit (autoresearch protocol)

When auditing skills for protocol compliance, check:

1. **Keyword-presence-without-citation**: flag any SKILL.md containing iteration-related keywords (`{"pass"`, `Iterations:`, `results.tsv`, `keep/revert`, `stuck detection`, `autoresearch`) WITHOUT a corresponding `autoresearch-core-skill/references/` path citation.
2. **Frontmatter-section mismatch**: `metadata.protocol: autoresearch-opt-in` MUST be present in frontmatter iff `## Iteration Protocol (opt-in)` section is present in body. Flag mismatches in either direction.
3. **Reference existence**: every `autoresearch-core-skill/references/<name>.md` path cited must resolve to an actual file. Stale citations (renamed/removed references) are flagged.

Report findings in standard audit output format with skill path + violation type + suggested fix.

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

### Auto-detection
If invoked on an iterative task, prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". Cache answer for session.

### Skill-specific patterns

**Citation-drift check** (rule): flag any SKILL.md containing iteration-related keywords (`{"pass"`, `Iterations:`, `results.tsv`, `keep/revert`, `stuck detection`) WITHOUT a corresponding `autoresearch-core-skill/references/` citation. Also verify `metadata.protocol: autoresearch-opt-in` frontmatter is present iff `## Iteration Protocol` section is present. **Stuck detection:** 3 consecutive audits with same finding → escalate severity. See `evaluator-contract.md` + `stuck-detection.md`.

### Citations
- `autoresearch-core-skill/references/evaluator-contract.md`
- `autoresearch-core-skill/references/stuck-detection.md`

### Imperative gating
When `AUTORESEARCH_PROTOCOL` is unset, this section is descriptive only. Default behavior is documented in all sections above.

