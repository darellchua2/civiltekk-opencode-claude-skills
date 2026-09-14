---
name: documentation-consistency-skill
description: >-
  Audit and auto-fix doc consistency across PLAN, README, AGENTS.md, deploy
  scripts — count sync, drift, orphan references.
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: OpenCode Meta
---

## What I do

I detect and repair documentation drift across the repository's markdown files:

1. **Cross-File Count Sync** — Verify skill/agent counts match reality across setup.sh, setup.ps1, README.md, and AGENTS.md
2. **PLAN vs Reality Drift** — Detect stale checkboxes, mismatched acceptance criteria, and outdated scope sections in PLAN*.md files
3. **Structural Integrity** — Validate required sections exist in PLAN files, README tables, and AGENTS.md routing tables
4. **Orphan/Stale References** — Find skill/agent names in documentation that don't exist on disk, and vice versa

## When to use me

Use this skill when:
- After adding, removing, or renaming skills or subagents
- Before creating a PR to verify documentation is consistent
- After a long work session with many edits to documentation files
- When PLAN checkboxes may not reflect actual implementation state
- Periodically as a health check against documentation rot

**Trigger phrases**:
- "check documentation consistency"
- "audit docs"
- "verify doc consistency"
- "check for documentation drift"
- "consistency check"
- "validate documentation"

## Related Skills

| Skill | Relationship |
|-------|-------------|
| `documentation-sync-workflow-skill` | Sync handles **add/remove** workflows for new skills/agents. This skill handles **ongoing drift** detection. Use sync when adding a skill; use consistency when verifying everything is still aligned. |
| `plan-updater-skill` | Updater marks checkboxes after commits. This skill **validates** those marks are accurate and complete. |
| `plan-execution-skill` | Execution runs PLAN phases. This skill can verify documentation state **after** execution. |
| `verification-loop-skill` | Verification checks code vs requirements. This skill checks **documentation vs code** state. |
| `opencode-skills-maintainer-skill` | Maintainer audits skill **content** quality. This skill audits documentation **accuracy** across files. |

## Validation Levels

| Level | Categories Checked | Use Case |
|-------|-------------------|----------|
| `quick` | Cross-file counts only | Pre-commit check |
| `standard` | Counts + PLAN drift + orphans | After a work session |
| `thorough` | All 4 categories | Pre-PR, after bulk changes |
| `targeted` | Single PLAN file (all categories) | During plan execution |

---

## Audit Category 1: Cross-File Count Sync

### What It Checks

Skill and agent counts must be identical across all documentation files.

**Source of truth**: Actual files on disk.

```bash
ACTUAL_SKILLS=$(ls -d opencode_app/.opencode/skills/*/ | grep -v _archived | grep -v scripts | wc -l)
ACTUAL_AGENTS=$(ls opencode_app/.opencode/agents/*.md 2>/dev/null | wc -l)
```

### Files Checked

| File | What to Search For |
|------|--------------------|
| `deploy/setup.sh` | `SKILLS (` — total count and per-category counts |
| `deploy/setup.ps1` | `SKILLS (` — total count and per-category counts |
| `README.md` | `<N> skills` or `## Skill Modularization` intro + Skill Categories table |
| `AGENTS.md` | `<N> skill` references and directory tree comments |

### Validation Commands

```bash
ACTUAL=$(ls -d opencode_app/.opencode/skills/*/ | grep -v _archived | grep -v scripts | wc -l)
echo "Actual skills on disk: $ACTUAL"
echo "---"
echo "setup.sh:    $(grep -oP 'SKILLS \(\K[0-9]+' deploy/setup.sh | head -1)"
echo "setup.ps1:   $(grep -oP 'SKILLS \(\K[0-9]+' deploy/setup.ps1 | head -1)"
echo "README.md:   $(grep -oP '\d+ skills' README.md | head -1)"
echo "AGENTS.md:   $(grep -oP '\d+ skill' AGENTS.md | head -1)"
```

### Auto-Fix Strategy

1. Count actual skills on disk (excluding `_archived/` and `scripts/`)
2. Find all count references in each file using the search patterns above
3. For each mismatch: use `edit` tool to replace the old count with actual count
4. Verify per-category counts sum to total

---

## Audit Category 2: PLAN vs Reality Drift

### What It Checks

PLAN*.md files must accurately reflect the current implementation state.

### Checks Performed

| Check | Description |
|-------|-------------|
| **Stale checkboxes** | Completed work still showing `[ ]` or incomplete work showing `[x]` |
| **Scope vs files** | Files listed in Scope section match files actually touched on the branch |
| **Acceptance criteria** | AC items align with what's implemented |
| **Phase completion** | All checkbox items in a completed phase are marked `[x]` |
| **Branch mismatch** | PLAN branch reference matches current branch |

### Validation Commands

```bash
PLAN_FILE="PLANS/PLAN-GIT-204.md"

echo "=== Unchecked items ==="
grep -n "\- \[ \]" "$PLAN_FILE"

echo "=== Checked items ==="
grep -n "\- \[x\]" "$PLAN_FILE"

echo "=== Scope section files ==="
grep -A 20 "## Scope" "$PLAN_FILE"

echo "=== Files changed on branch ==="
git diff --name-only main...HEAD

echo "=== Branch reference ==="
grep "Branch" "$PLAN_FILE"
echo "Actual: $(git branch --show-current)"
```

### Auto-Fix Strategy

1. Compare `git diff --name-only main...HEAD` with Scope section
2. For each checkbox: check if referenced file exists and was modified on branch
3. If file exists and was modified → mark `[x]`
4. If file listed in Scope but not touched → flag as potentially stale
5. Update Scope section if new files were touched that aren't listed
6. Always preserve content — only update checkbox states and Scope entries

### PLAN File Required Sections

Every PLAN*.md should contain these sections:

```markdown
# PLAN-<ID>: <Title>

**Issue**: <link>
**Branch**: `<branch-name>`
**Status**: <status>

---

## Problem
<description>

## Solution
<description>

---

## Phase 1: <Name>
- [ ] <task>
- [ ] <task>

## Phase N: <Name>
- [ ] <task>

---

## Acceptance Criteria
- [ ] <criterion>

## Scope
| File | Action |
|------|--------|
| <path> | Create/Update |

## Risks & Mitigation
| Risk | Severity | Mitigation |
|------|----------|-----------|
```

---

## Audit Category 3: Structural Integrity

### What It Checks

Documentation files must have complete, well-formed sections and tables.

### Checks Per File

**README.md**:
- `## Skill Modularization` section exists
- Skill Categories table has correct header row: `| Category | Skills | Purpose |`
- All expected category rows present
- Subagents table exists (if applicable)
- Repository structure tree is present

**AGENTS.md**:
- `## Repository Overview` section exists
- `## Shared Config Strategy` section exists
- `## Subagent Locations` table exists
- `## CodeGraph` section exists (if configured)
- `## Adding New Subagents or Skills` section exists
- Skill count references are accurate

**deploy/setup.sh** and **deploy/setup.ps1**:
- `SKILLS (` listing section exists
- All category lines have format: `Category (N): skill1, skill2, ...`
- Category counts sum to total skill count
- Both files have identical category listings and counts

### Validation Commands

```bash
echo "=== README.md sections ==="
grep "^## " README.md

echo "=== README.md Skill Categories table ==="
grep -A 20 "Skill Categories" README.md | head -20

echo "=== AGENTS.md sections ==="
grep "^## " AGENTS.md

echo "=== setup.sh category count sum ==="
grep -oP '\(\K[0-9]+' deploy/setup.sh | head -15
```

### Auto-Fix Strategy

1. For missing sections: report with template content to insert
2. For malformed tables: suggest corrected rows
3. For count mismatches in categories: flag the specific category with expected vs actual
4. Do NOT auto-fix structural issues without confirmation — these require human judgment

---

## Audit Category 4: Orphan/Stale References

### What It Checks

Every skill, agent, and MCP reference in documentation must point to something that exists on disk.

### Checks Performed

| Check | Description |
|-------|-------------|
| **Agent names in docs** | Each agent name in AGENTS.md routing tables has a matching `.opencode/agents/<name>.md` file |
| **Skill names in docs** | Each skill name in README.md tables has a matching `.opencode/skills/<name>/SKILL.md` directory |
| **Skill names in deploy scripts** | Each skill listed in setup.sh/setup.ps1 has a matching skill directory |
| **Reverse check** | Each skill/agent on disk is listed in documentation (not hidden/undocumented) |
| **PLAN Scope references** | Files referenced in PLAN Scope sections exist |
| **Cross-skill references** | Skills mentioned in `## Related Skills` or `## Integration` sections exist |

### Validation Commands

```bash
echo "=== Agents on disk but NOT in docs ==="
for f in opencode_app/.opencode/agents/*.md; do
  name=$(basename "$f" .md)
  if ! grep -rq "$name" AGENTS.md README.md; then
    echo "  MISSING FROM DOCS: $name"
  fi
done

echo "=== Skills on disk but NOT in setup.sh ==="
for d in opencode_app/.opencode/skills/*/; do
  name=$(basename "$d")
  [[ "$name" == "_archived" || "$name" == "scripts" ]] && continue
  if ! grep -q "$name" deploy/setup.sh; then
    echo "  MISSING FROM SETUP.SH: $name"
  fi
done

echo "=== Skills in setup.sh but NOT on disk ==="
grep -oP '[a-z][a-z0-9-]+' deploy/setup.sh | sort -u | while read name; do
  if [[ "$name" == *"-skill" || "$name" == *"-workflow" || "$name" == *"-creator" ]]; then
    if [ ! -d "opencode_app/.opencode/skills/$name" ]; then
      echo "  ORPHAN IN SETUP.SH: $name"
    fi
  fi
done

echo "=== Cross-skill references check ==="
for d in opencode_app/.opencode/skills/*/SKILL.md; do
  name=$(basename "$(dirname "$d")")
  refs=$(grep -oP '[a-z][a-z0-9-]+-skill' "$d" 2>/dev/null | sort -u)
  for ref in $refs; do
    [[ "$ref" == "$name" ]] && continue
    if [ ! -d "opencode_app/.opencode/skills/$ref" ]; then
      echo "  BROKEN REF in $name: $ref"
    fi
  done
done
```

### Auto-Fix Strategy

1. For orphans in deploy scripts: remove the stale entry from the listing
2. For missing entries in deploy scripts: add to appropriate category
3. For broken cross-skill references: report for manual review (wrong to auto-delete)
4. For undocumented skills/agents: add to appropriate documentation section
5. Always update counts after adding/removing entries

---

## Validation Report Template

When running a consistency check, generate a report in this format:

```markdown
## Documentation Consistency Report

**Level**: <quick|standard|thorough|targeted>
**Date**: <ISO 8601>
**Branch**: <branch-name>

### Summary

| Category | Status | Issues Found | Fixed |
|----------|--------|-------------|-------|
| Cross-File Counts | PASS/FAIL | N | N |
| PLAN vs Reality | PASS/FAIL/SKIP | N | N |
| Structural Integrity | PASS/FAIL/SKIP | N | N |
| Orphan References | PASS/FAIL/SKIP | N | N |

### Issues

#### Cross-File Count Sync
- [ISSUE] setup.sh: expected 74 skills, found 73
  - Fix: edit deploy/setup.sh, change `SKILLS (73)` to `SKILLS (74)`
- [PASS] setup.ps1: count matches (74)
- ...

#### PLAN vs Reality Drift
- [ISSUE] PLAN-GIT-204.md: checkbox line 28 still unchecked but file exists
  - Fix: edit PLANS/PLAN-GIT-204.md, change `- [ ]` to `- [x]` on line 28
- ...

#### Structural Integrity
- [PASS] README.md: all required sections present
- ...

#### Orphan References
- [ISSUE] Agent `old-subagent` listed in AGENTS.md but no .md file on disk
  - Fix: remove from AGENTS.md routing table
- ...
```

---

## Steps

### Step 1: Determine Validation Level

Based on context or explicit request, choose a validation level:

- **quick**: Run only Audit Category 1 (counts)
- **standard**: Run Categories 1, 2, 4
- **thorough**: Run all 4 categories
- **targeted**: Run all categories for a single PLAN file

### Step 2: Run Checks

For each applicable category, execute the validation commands and collect results.

### Step 3: Generate Report

Output the Validation Report using the template above.

### Step 4: Apply Fixes (if requested)

For each issue found:
1. Present the fix to the user
2. If user confirms (or auto-fix is enabled), apply via `edit` tool
3. Re-run the specific check to verify the fix

### Step 5: Final Verification

Run the full set of validation commands one more time to confirm all issues are resolved.

---

## Common Issues

### Count Mismatch Between Files

**Issue**: `SKILLS (73)` in setup.sh but `74 skills` in README.md

**Solution**: Determine actual count from disk, then update all files to match. Always use the disk count as source of truth.

### PLAN Checkboxes Out of Sync

**Issue**: Work completed but checkboxes still `[ ]`, or checkboxes marked `[x]` for unimplemented work.

**Solution**: Cross-reference with `git diff --name-only`. If a file was modified, its corresponding checkbox should be `[x]`. If no file matches a `[x]` checkbox, flag for review.

### Stale Category Counts

**Issue**: Category says `(3)` but has 4 skills listed.

**Solution**: Count the actual skills in the category listing and update the parenthetical number.

### Orphan Agent Reference

**Issue**: Agent name in AGENTS.md but no `.md` file exists.

**Solution**: Check if it was renamed or removed. If removed, delete the reference. If renamed, update the name. If it should exist, the agent file needs to be created.

### Missing PLAN Required Section

**Issue**: PLAN file missing `## Risks & Mitigation` or `## Scope`.

**Solution**: Add the missing section with appropriate template content. Do not remove existing sections.

## Best Practices

1. **Always run thorough check before PRs** — catches all categories of drift
2. **Run quick check after any skill/agent change** — catches count mismatches early
3. **Use targeted level during plan execution** — focuses on the active PLAN file
4. **Disk is truth** — when in doubt, trust what's actually on the filesystem
5. **Don't auto-fix structural issues** — missing sections require human judgment
6. **Fix all files in one pass** — update setup.sh, setup.ps1, README.md, and AGENTS.md together
7. **Re-validate after fixes** — always run checks again to confirm resolution
8. **Keep the report** — store validation reports in `LEARNINGS/solutions/` for future reference

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

### Auto-detection
If invoked on an iterative task, prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". Cache answer for session.

### Skill-specific patterns

**TSV audit trail.** Documentation drift checks append to `documentation-consistency-results.tsv` (8-column format per `audit-trail.md`). **Crash recovery.** On missing-file error: log + skip; on YAML parse failure: log + skip; do NOT abort the entire audit. See `crash-recovery.md`.

### Citations
- `autoresearch-core-skill/references/audit-trail.md`
- `autoresearch-core-skill/references/crash-recovery.md`

### Imperative gating
When `AUTORESEARCH_PROTOCOL` is unset, this section is descriptive only. Default behavior is documented in all sections above.
