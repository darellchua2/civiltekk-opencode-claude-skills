---
name: documentation-sync-workflow-skill
description: >-
  Sync docs when adding skills or subagents — updates setup.sh, setup.ps1,
  README.md, AGENTS.md counts and listings.
license: Apache-2.0
compatibility: opencode
category: Documentation
---

## What I do

I ensure documentation files stay synchronized when adding new skills or subagents by guiding updates to 4 key files:

1. **setup.sh** - Update skill/agent counts and listings
2. **setup.ps1** - Update skill/agent counts and listings
3. **README.md** - Update tables reflecting current skills/agents
4. **AGENTS.md** - Document workflow guidance for new additions

## When to use me

Use this workflow when:
- Adding a new skill to the `skills/` directory
- Adding a new subagent to the `agents/` directory
- Removing or renaming skills/subagents
- Verifying documentation accuracy

## Prerequisites

- Write access to repository files
- Knowledge of skill category (for new skills)
- Knowledge of subagent purpose and associated skills (for new subagents)

## Files Requiring Updates

### 1. setup.sh

**AGENTS Section**: Search for `AGENTS (` to find the agent listing.
Update when: Adding a new primary agent

**SKILLS Section**: Search for `SKILLS (` to find the skill listing.
```bash
   SKILLS (49):
     Framework (7):        test-generator-framework, linting-workflow,
                           ...
     Documentation (2):    coverage-readme-workflow, docstring-generator
     ...
```
Update when: Adding a new skill - increment count and add to appropriate category

### 2. setup.ps1

**SKILLS Section**: Search for `SKILLS (` (mirrors setup.sh).
Update when: Adding a new skill - same changes as setup.sh

### 3. README.md

**Skill Categories Table**: Search for `| Category | Skills |` to locate.
```markdown
| Category | Skills | Purpose |
|-----------|---------|---------|
| **Framework** (7) | ... | Generic workflows, testing patterns |
| **Documentation** (2) | coverage-readme-workflow, docstring-generator | Documentation generation |
```
Update when: Adding a new skill - add to or update appropriate category row

**Subagents Table**: Search for `| Subagent | Purpose |` to locate.
Update when: Adding a new subagent - add row with purpose and associated skills

### 4. AGENTS.md

Add workflow guidance section when creating new documentation patterns.

## Validation Commands

### Count Skills
```bash
# Count total skills
ls -d skills/*/ | wc -l

# Compare with what's documented in setup.sh
grep "SKILLS (" setup.sh
```

### Count Subagents
```bash
# Count subagents
ls agents/*.md | wc -l

# Compare with README.md subagents table
grep -c "| \*\*" README.md
```

### Verify Counts Match in Files
```bash
# Check skill count in setup.sh
grep "SKILLS (" setup.sh

# Check skill count in setup.ps1
grep "SKILLS (" setup.ps1

# Check README.md table entries
grep -c "| \*\*" README.md
```

### Full Validation
```bash
# Verify skill counts across all files
echo "Skills in directory: $(ls -d skills/*/ | wc -l)"
echo "Skills in setup.sh: $(grep -oP 'SKILLS \(\K[0-9]+' setup.sh)"
echo "Skills in setup.ps1: $(grep -oP 'SKILLS \(\K[0-9]+' setup.ps1)"
echo "Skills in README.md: $(grep -oP '\*\*[A-Za-z]+\*\* \([0-9]+\)' README.md | wc -l)"
```

## Steps

### Step 1: Identify What Changed

```bash
# Check for new skill directories
ls -d skills/*/

# Check for new agent files
ls agents/*.md
```

### Step 2: Update setup.sh

1. Search for the appropriate category section (grep for `SKILLS (`)
2. Increment category count: `(7)` → `(8)`
3. Add skill name to the list
4. Update total count: `SKILLS (49)` → `SKILLS (50)`

### Step 3: Update setup.ps1

1. Apply identical changes to setup.ps1 (search for `SKILLS (`)
2. Maintain exact same formatting and counts as setup.sh

### Step 4: Update README.md

1. Search for the Skill Categories table (grep for `| Category | Skills |`):
   - Update category count
   - Add skill name to list
   - Ensure Purpose column remains accurate

2. If adding a subagent, search for the Subagents table (grep for `| Subagent | Purpose |`):
   - Add new row with subagent name, purpose, and associated skills

3. Search for the total skill count in the intro paragraph and update it

### Step 5: Update AGENTS.md (if needed)

Add workflow guidance section for new documentation patterns.

### Step 6: Validate

Run validation commands to ensure all counts match.

## Skill Categories Reference

| Category | Current Count | Purpose |
|----------|---------------|---------|
| Framework | 7 | Generic workflows, testing patterns, document creation |
| Language-Specific | 4 | Language-specific test, linting, documentation |
| Framework-Specific | 7 | Next.js and TypeScript workflows |
| OpenCode Meta | 4 | Agent and skill creation/maintenance |
| OpenTofu | 7 | Infrastructure as code |
| Git/Workflow | 7 | Git operations and workflows |
| Documentation | 2 | Documentation generation |
| JIRA | 4 | JIRA integration workflows |
| Code Quality | 7 | Code quality analysis and patterns |

**Total: Verify with `ls -d skills/*/ | wc -l`**

## Checklist for Adding a New Skill

- [ ] Create skill directory: `skills/<skill-name>/SKILL.md`
- [ ] Update setup.sh:
  - [ ] Increment total skill count (search for `SKILLS (`)
  - [ ] Add skill to appropriate category
  - [ ] Increment category count
- [ ] Update setup.ps1:
  - [ ] Increment total skill count (search for `SKILLS (`)
  - [ ] Add skill to appropriate category
  - [ ] Increment category count
- [ ] Update README.md:
  - [ ] Update Skill Categories table (search for `| Category | Skills |`)
  - [ ] Update total count in intro paragraph
- [ ] Run validation commands to verify counts match

## Checklist for Adding a New Subagent

- [ ] Create subagent file: `agents/<subagent-name>.md`
- [ ] Update README.md Subagents table:
  - [ ] Add row with subagent name
  - [ ] Add purpose description
  - [ ] List associated skills
- [ ] Update total subagent count in README.md
- [ ] If primary agent, update setup.sh AGENTS section
- [ ] Run validation commands to verify counts match

## Common Issues

### Count Mismatch
**Issue**: Counts differ between files

**Solution**: Run validation commands to identify which file is incorrect:
```bash
grep "SKILLS (" setup.sh setup.ps1
```

### Wrong Category
**Issue**: Skill added to wrong category

**Solution**: Review skill purpose and assign to appropriate category based on the categories reference table above.

### Missing Skill in Table
**Issue**: Skill added to setup files but not README.md

**Solution**: Ensure README.md Skill Categories table is updated with the new skill name in the appropriate category row.

## Best Practices

1. **Update all files together**: Make changes to setup.sh, setup.ps1, and README.md in the same commit
2. **Use search patterns**: Search for existing skill names to find exact update locations
3. **Validate after changes**: Always run validation commands after updates
4. **Keep counts accurate**: Total skill count should equal sum of all category counts
5. **Maintain alphabetical order**: List skills alphabetically within categories
