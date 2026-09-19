---
name: git-issue-plan-workflow
description: Standardized GitHub issue creation workflow with structured description, branch creation, PLAN.md generation, and phased execution
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: github-planning
---

## What I do

I implement a standardized GitHub issue creation and planning workflow:

1. **Gather Issue Requirements**: Prompt user for structured issue description following industry best practices
2. **Determine Issue Scope**: Ask if issue needs to be broken into sub-issues
3. **Create GitHub Issue**: Use GitHub CLI to create issue with appropriate labels
4. **Create Git Branch**: Generate branch from issue number (e.g., `GIT-123`)
5. **Generate PLAN file**: Create comprehensive plan with phases and todo list in `PLANS/` directory
6. **Commit and Push**: Commit PLAN file with semantic formatting and push to remote
7. **Prompt Execution**: Ask user if they want to proceed with plan execution

## Framework Skills Used

This workflow delegates to these framework skills for specialized functionality:

| Skill | Purpose | Used In |
|-------|---------|---------|
| `git-issue-labeler` | Intelligent label assessment and assignment | Step 3 |
| `git-semantic-commits` | Conventional commit message formatting | Step 7 |
| `git-issue-updater` | Progress updates to GitHub issues | Step 8 |

## When to use me

Use this workflow when:
- Starting a new development task tracked in GitHub Issues
- You want a standardized approach to issue creation and planning
- You need to break down large work into structured phases
- Following the practice of planning before implementation

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Git repository initialized with GitHub remote
- Write access to repository
- `gh auth status` shows valid authentication

## Steps

### Step 1: Gather Issue Description

Prompt the user for a structured issue description with these sections:

**Required Information**:
1. **Title**: Concise title (max 72 characters)
2. **Overview**: Brief description of what needs to be done
3. **Acceptance Criteria**: Definition of done (bullet points)
4. **Scope**: Files or areas affected
5. **Technical Notes**: Implementation considerations (optional)

**Prompt Template**:
```
Please provide the following for your GitHub issue:

1. **Title** (required): Brief title for the issue
   Example: "Implement user authentication API"

2. **Overview** (required): What does this issue accomplish?
   Example: "Add JWT-based authentication endpoints for user login/registration"

3. **Acceptance Criteria** (required): How do we know it's done?
   Example:
   - Users can register with email/password
   - Users can login and receive JWT token
   - Protected routes validate JWT

4. **Scope** (required): What files/areas will be affected?
   Example: src/api/auth/, src/middleware/, tests/auth/

5. **Technical Notes** (optional): Any implementation details?
   Example: Use bcrypt for password hashing, 24h token expiry
```

### Step 2: Determine Issue Scope

Ask user to choose issue complexity:

**Question**: "Should this be broken into smaller sub-issues?"

**Options**:
- **Parent with Sub-issues**: Creates a parent issue, then prompts for sub-issues
- **Single Issue**: Creates one issue for contained work

**Parent Issue Flow**:
```markdown
If Parent selected:
1. Create parent issue
2. Prompt for sub-issues (repeat until done):
   - Sub-issue title
   - Sub-issue description
3. Create each sub-issue and link to parent
4. Branch name uses parent issue number (e.g., GIT-123)
```

**Single Issue Flow**:
```markdown
If Single selected:
1. Create single issue with appropriate labels
2. Branch name uses issue number (e.g., GIT-124)
```

### Step 3: Determine Labels

**Delegate to `git-issue-labeler` skill** for intelligent label assessment:

```bash
# Use git-issue-labeler to determine appropriate labels
# The skill analyzes issue content and assigns GitHub default labels
# See: skills/git-issue-labeler/SKILL.md
```

**Available Labels** (handled by `git-issue-labeler`):
- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Improvements or additions to documentation
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed
- `question` - Further information is requested
- `invalid` - This doesn't seem right
- `wontfix` - This will not be worked on
- `duplicate` - This issue or pull request already exists
- `major`, `minor`, `patch` - Semantic versioning labels

**Integration Pattern**:
```
After user provides issue description:
1. Combine title + overview + technical notes into issue content
2. Invoke git-issue-labeler skill to analyze and assign labels
3. Use returned labels in gh issue create command
```

### Step 4: Create GitHub Issue(s)

**For Single Issue**:
```bash
ISSUE_URL=$(gh issue create \
  --title "$TITLE" \
  --body "$FORMATTED_BODY" \
  --label "$LABELS" \
  --assignee @me)

# Extract issue number
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
```

**For Parent with Sub-issues**:
```bash
# Create parent issue first
PARENT_URL=$(gh issue create \
  --title "$TITLE" \
  --body "$FORMATTED_BODY" \
  --label "$LABELS" \
  --assignee @me)

PARENT_NUMBER=$(echo "$PARENT_URL" | grep -oE '[0-9]+$')

# Create each sub-issue
for subissue in "${SUBISSUES[@]}"; do
  gh issue create \
    --title "$subissue.title" \
    --body "$subissue.body\n\nParent: #$PARENT_NUMBER" \
    --label "$subissue.labels" \
    --assignee @me
done
```

**Formatted Body Template**:
```markdown
## Overview
$OVERVIEW

## Acceptance Criteria
$ACCEPTANCE_CRITERIA

## Scope
$SCOPE

## Technical Notes
$TECHNICAL_NOTES

---
*Created with git-issue-plan-workflow*
```

### Step 5: Create Git Branch

**Branch Naming Convention**:
- Use issue number: `GIT-123` (required format)
- All uppercase, no spaces
- Pattern: `GIT-{ISSUE_NUMBER}`

```bash
# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
  echo "Warning: You have uncommitted changes"
  read -p "Continue anyway? (y/n): " CONTINUE
  [ "$CONTINUE" != "y" ] && exit 1
fi

# Create and checkout branch
git checkout -b "GIT-$ISSUE_NUMBER"

echo "✓ Created branch: GIT-$ISSUE_NUMBER"
```

### Step 6: Generate PLAN file

**File Location**: All PLAN files are stored in the `PLANS/` directory at the project root.

- **GitHub issues**: `PLANS/PLAN-GIT-{ISSUE_NUMBER}.md` (e.g., `PLANS/PLAN-GIT-123.md`)

**PLANS Folder Check**:
```bash
# Check if PLANS directory exists, create if not
if [ ! -d "PLANS" ]; then
  mkdir -p PLANS
  echo "✓ Created PLANS directory"
fi
```

Create comprehensive PLAN file with phases and todos:

**Template**:
```markdown
# Plan: $ISSUE_TITLE

## Issue Reference
- **Number**: #$ISSUE_NUMBER
- **URL**: $GITHUB_URL/issues/$ISSUE_NUMBER
- **Labels**: $LABELS

## Overview
$OVERVIEW

## Acceptance Criteria
- [ ] $CRITERION_1
- [ ] $CRITERION_2
- [ ] $CRITERION_3

## Scope
$SCOPE

---

## Implementation Phases

### Phase 1: Setup & Analysis
- [ ] Review existing codebase for affected areas
- [ ] Identify dependencies and potential conflicts
- [ ] Set up development environment if needed
- [ ] Create feature flags (if applicable)

### Phase 2: Core Implementation
- [ ] Implement primary functionality
- [ ] Add error handling and edge cases
- [ ] Update affected modules/components
- [ ] Add logging and monitoring

### Phase 3: Testing
- [ ] Write unit tests for new functionality
- [ ] Write integration tests
- [ ] Perform manual testing
- [ ] Test edge cases and error scenarios

### Phase 4: Documentation & Cleanup
- [ ] Update code documentation/docstrings
- [ ] Update README if applicable
- [ ] Remove debug code and comments
- [ ] Code review preparation

### Phase 5: Final Validation
- [ ] Run all tests (unit, integration, e2e)
- [ ] Verify acceptance criteria met
- [ ] Performance testing (if applicable)
- [ ] Security review (if applicable)

---

## Technical Notes
$TECHNICAL_NOTES

## Dependencies
_List any external dependencies or blocked-by issues_

## Risks & Mitigation
_Identify potential risks and how to mitigate them_

## Success Metrics
_How will we measure success?_
```

### Step 7: Commit and Push PLAN file

**Use `git-semantic-commits` skill** for proper commit message formatting:

```bash
# Check if PLANS directory exists, create if not
if [ ! -d "PLANS" ]; then
  mkdir -p PLANS
  echo "Created PLANS directory"
fi

# Stage PLAN file
git add "PLANS/PLAN-GIT-${ISSUE_NUMBER}.md"

# Format commit message using git-semantic-commits pattern
# Type: docs (documentation), Scope: plan, Subject: descriptive
# See: skills/git-semantic-commits/SKILL.md
COMMIT_MSG="docs(plan): add PLAN-GIT-${ISSUE_NUMBER}.md for issue #$ISSUE_NUMBER

Plan file created for issue #$ISSUE_NUMBER tracking implementation phases."

git commit -m "$COMMIT_MSG"

# Push to remote
git push -u origin "GIT-$ISSUE_NUMBER"

echo "✓ Committed and pushed PLANS/PLAN-GIT-${ISSUE_NUMBER}.md"
```

**Semantic Commit Format**:
- Type: `docs` (PLAN files are documentation)
- Scope: `plan` (identifies plan-related commits)
- Subject: Describes the PLAN file added
- Body: Optional additional context

### Step 8: Update Issue with Initial Progress

**Use `git-issue-updater` skill** to add progress comment to GitHub issue:

```bash
# Use git-issue-updater for consistent issue progress updates
# See: skills/git-issue-updater/SKILL.md

# Format progress update following git-issue-updater standards
gh issue comment "$ISSUE_NUMBER" --body "## Planning Complete - $(date '+%Y-%m-%d %H:%M')

**Branch**: \`GIT-$ISSUE_NUMBER\`
**PLAN File**: \`PLANS/PLAN-GIT-${ISSUE_NUMBER}.md\`
**Status**: Ready to begin execution

### Completed
- [x] GitHub issue created
- [x] Branch created and checked out
- [x] PLAN file generated with implementation phases
- [x] Initial commit pushed to remote

### Next Steps
1. Review \`PLANS/PLAN-GIT-${ISSUE_NUMBER}.md\`
2. Begin Phase 1: Setup & Analysis

---
*Tracking progress with git-issue-plan-workflow*"
```

**git-issue-updater Integration**:
For subsequent commits, use `git-issue-updater` skill to maintain consistent progress tracking with user, date, time, and file statistics.

### Step 9: Prompt for Plan Execution

Ask user if they want to proceed:

```
✓ GitHub issue created: #$ISSUE_NUMBER
✓ Branch created and checked out: GIT-$ISSUE_NUMBER
✓ PLANS/PLAN-GIT-${ISSUE_NUMBER}.md committed and pushed

Would you like to proceed with executing the plan?
- Yes: Start with Phase 1 tasks
- No: Stop here and execute manually later

[If Yes]: Begin executing todo items from PLANS/PLAN-GIT-${ISSUE_NUMBER}.md
[If No]: Workflow complete. Run tasks manually when ready.
```

## Best Practices

### Issue Description
- **Be specific**: "Add JWT authentication" vs "Add auth"
- **Include context**: Why is this needed?
- **Define done**: Clear acceptance criteria
- **Limit scope**: One feature/fix per issue

### Labels
- Use appropriate labels for discoverability
- `bug` vs `enhancement` distinction
- `help wanted` for community contributions
- `good first issue` for newcomers

### Branch Naming
- Use `GIT-{number}` format for traceability
- Keep it consistent with PLAN file naming

### PLAN File Structure
- Start with phases for large work
- Each phase has clear todo items
- Todos are actionable and verifiable
- Include success criteria

### Commit Messages
- Use semantic commits: `docs(plan):`, `feat:`, `fix:`
- Reference issue number in message
- Keep first line under 72 chars

## Common Issues

### GitHub CLI Not Authenticated
**Issue**: `gh` command fails with auth error

**Solution**:
```bash
gh auth login
gh auth status
```

### Cannot Create Issue
**Issue**: Permission denied or repo not found

**Solution**:
- Verify repository URL: `git remote -v`
- Check user has write access
- Ensure repository exists on GitHub

### Branch Already Exists
**Issue**: Branch with same name exists

**Solution**:
```bash
# Switch to existing branch
git checkout "GIT-$ISSUE_NUMBER"

# Or force create new
git checkout -B "GIT-$ISSUE_NUMBER"
```

### Push Rejected
**Issue**: Remote has updates

**Solution**:
```bash
git pull --rebase origin main
git push -u origin "GIT-$ISSUE_NUMBER"
```

### Sub-issue Linking
**Issue**: Cannot create linked sub-issues

**Solution**:
- Reference parent manually in body: "Parent: #123"
- Use GitHub's task lists for hierarchical tracking
- Consider using Projects for complex hierarchies

## Troubleshooting Checklist

**Before starting**:
- [ ] GitHub CLI authenticated: `gh auth status`
- [ ] Git repository initialized
- [ ] Remote repository configured
- [ ] Working directory clean

**After issue creation**:
- [ ] Issue number captured
- [ ] Issue accessible via URL
- [ ] Labels assigned correctly
- [ ] Sub-issues created (if parent)

**After branch creation**:
- [ ] Branch name includes issue number
- [ ] Branch checked out successfully

**After PLAN file**:
- [ ] File created in PLANS/ directory
- [ ] All sections populated
- [ ] Phases have actionable todos
- [ ] Acceptance criteria listed

**After commit/push**:
- [ ] PLAN file committed with semantic message
- [ ] Branch pushed to remote
- [ ] GitHub issue updated with progress

## Example Usage

```
User: Create a GitHub issue for adding user authentication

Agent: I'll help you create a GitHub issue. Please provide:

1. **Title**: [Brief title, max 72 chars]
2. **Overview**: [What this issue accomplishes]
3. **Acceptance Criteria**: [Definition of done]
4. **Scope**: [Files/areas affected]
5. **Technical Notes**: [Implementation details, optional]

User: 
1. Implement user authentication API
2. Add JWT-based authentication endpoints
3. Users can register, login, logout. Protected routes work.
4. src/api/auth/, src/middleware/
5. Use bcrypt, 24h token expiry

Agent: Should this be broken into smaller sub-issues?
- Parent with Sub-issues
- Single Issue

User: Single Issue

Agent: Labels detected: enhancement
Creating issue...

✓ Created GitHub issue: #456
✓ Created branch: GIT-456
✓ Created PLANS/PLAN-GIT-456.md with 5 phases
✓ Committed and pushed to remote

Proceed with plan execution? (yes/no)
```

## GitHub vs JIRA Comparison

| Aspect | GitHub Issues | JIRA |
|--------|---------------|------|
| Issue Type | Labels only | Task, Story, Bug, Subtask |
| Hierarchy | Manual linking | Native parent/subtask |
| Labels | Custom + defaults | Components, Labels |
| Projects | GitHub Projects | JIRA Boards |
| Branch naming | `GIT-123` | `PROJ-123` |
