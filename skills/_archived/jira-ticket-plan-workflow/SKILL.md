---
name: jira-ticket-plan-workflow
description: Standardized JIRA ticket creation workflow with structured description, branch creation, PLAN.md generation, and phased execution
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: jira-planning
---

## What I do

I implement a standardized JIRA ticket creation and planning workflow:

1. **Gather Ticket Requirements**: Prompt user for structured ticket description following industry best practices
2. **Determine Ticket Scope**: Ask if ticket is a Story (with subtasks) or a single Task
3. **Create JIRA Ticket**: Use Atlassian MCP server to create ticket in specified project
4. **Create Git Branch**: Generate branch from ticket key (e.g., `PROJ-123`)
5. **Generate PLAN-{TICKET_KEY}.md**: Create comprehensive plan with phases and todo list
6. **Commit and Push**: Commit PLAN-{TICKET_KEY}.md with semantic formatting and push to remote
7. **Prompt Execution**: Ask user if they want to proceed with plan execution

## When to use me

Use this workflow when:
- Starting a new development task that needs JIRA tracking
- You want a standardized approach to ticket creation and planning
- You need to break down large work into structured phases
- Following the practice of planning before implementation

## Prerequisites

- Active Atlassian/JIRA account with project access
- Git repository initialized with remote configured
- Write access to repository
- Atlassian MCP server configured

## Steps

### Step 1: Gather Ticket Description

Prompt the user for a structured ticket description with these sections:

**Required Information**:
1. **Summary**: Concise title (max 72 characters)
2. **Overview**: Brief description of what needs to be done
3. **Acceptance Criteria**: Definition of done (bullet points)
4. **Scope**: Files or areas affected
5. **Technical Notes**: Implementation considerations (optional)

**Prompt Template**:
```
Please provide the following for your JIRA ticket:

1. **Summary** (required): Brief title for the ticket
   Example: "Implement user authentication API"

2. **Overview** (required): What does this ticket accomplish?
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

### Step 2: Determine Ticket Scope

Ask user to choose ticket type:

**Question**: "Is this a large piece of work that should be broken into subtasks?"

**Options**:
- **Story with Subtasks**: Creates a Story ticket, then prompts for subtasks (Task tickets linked to parent)
- **Single Task**: Creates one Task ticket for contained work

**Story Flow**:
```markdown
If Story selected:
1. Create parent Story ticket
2. Prompt for subtasks (repeat until done):
   - Subtask summary
   - Subtask description
3. Create each subtask linked to parent Story
4. Branch name uses Story key (e.g., PROJ-123)
```

**Task Flow**:
```markdown
If Task selected:
1. Create single Task ticket
2. Branch name uses Task key (e.g., PROJ-124)
```

### Step 3: Select JIRA Project

If project not specified, prompt user:

```bash
# List available projects
atlassian_getVisibleJiraProjects --cloudId "$CLOUD_ID"

# Prompt user to select
"Which JIRA project should this ticket be created in?"
- Display project keys and names
- User selects by key (e.g., IBIS, PROJ, DA)
```

### Step 4: Create JIRA Ticket(s)

**For Single Task**:
```bash
atlassian_createJiraIssue \
  --cloudId "$CLOUD_ID" \
  --projectKey "$PROJECT_KEY" \
  --issueTypeName "Task" \
  --summary "$SUMMARY" \
  --description "$FORMATTED_DESCRIPTION"
```

**For Story with Subtasks**:
```bash
# Create parent Story first
STORY_KEY=$(atlassian_createJiraIssue \
  --cloudId "$CLOUD_ID" \
  --projectKey "$PROJECT_KEY" \
  --issueTypeName "Story" \
  --summary "$SUMMARY" \
  --description "$FORMATTED_DESCRIPTION")

# Create each subtask
for subtask in "${SUBTASKS[@]}"; do
  atlassian_createJiraIssue \
    --cloudId "$CLOUD_ID" \
    --projectKey "$PROJECT_KEY" \
    --issueTypeName "Sub-task" \
    --summary "$subtask.summary" \
    --description "$subtask.description" \
    --parent "$STORY_KEY"
done
```

**Formatted Description Template**:
```markdown
## Overview
$OVERVIEW

## Acceptance Criteria
$ACCEPTANCE_CRITERIA

## Scope
$SCOPE

## Technical Notes
$TECHNICAL_NOTES
```

### Step 5: Create Git Branch

**Branch Naming Convention**:
- Use ticket key as branch name: `PROJ-123`
- For features, can prefix: `feature/PROJ-123`
- All lowercase, no spaces

```bash
# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
  echo "Warning: You have uncommitted changes"
  read -p "Continue anyway? (y/n): " CONTINUE
  [ "$CONTINUE" != "y" ] && exit 1
fi

# Create and checkout branch
git checkout -b "$TICKET_KEY"

echo "✓ Created branch: $TICKET_KEY"
```

### Step 6: Generate PLAN-{TICKET_KEY}.md

Create comprehensive PLAN file with ticket-specific naming:

**File Location**: All PLAN files are stored in the `PLANS/` directory at the project root.

**Filename Pattern**:
- **JIRA tickets**: `PLANS/PLAN-{TICKET_KEY}.md` (e.g., `PLANS/PLAN-PROJ-123.md`, `PLANS/PLAN-IBIS-456.md`)
- **GitHub issues**: `PLANS/PLAN-GIT-{ISSUE_NUMBER}.md` (e.g., `PLANS/PLAN-GIT-76.md`)

**Template**:
```markdown
# Plan: $TICKET_SUMMARY

## Ticket Reference
- **Key**: $TICKET_KEY
- **Type**: Task | Story
- **URL**: $JIRA_URL/browse/$TICKET_KEY
- **Project**: $PROJECT_KEY

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
_List any external dependencies or blocked-by tickets_

## Risks & Mitigation
_Identify potential risks and how to mitigate them_

## Success Metrics
_How will we measure success?_
```

### Step 7: Commit and Push PLAN-{TICKET_KEY}.md

```bash
# Check if PLANS directory exists, create if not
if [ ! -d "PLANS" ]; then
  mkdir -p PLANS
  echo "Created PLANS directory"
fi

# Stage PLAN file
git add "PLANS/PLAN-${TICKET_KEY}.md"

# Commit with semantic message
git commit -m "docs(plan): add PLAN-${TICKET_KEY}.md for ${TICKET_KEY}"

# Push to remote
git push -u origin "$TICKET_KEY"

echo "✓ Committed and pushed PLANS/PLAN-${TICKET_KEY}.md"
```

### Step 8: Update JIRA with Initial Progress

Add comment to JIRA ticket:

```bash
COMMENT="**Planning Complete**

- Branch created: \`$TICKET_KEY\`
- PLANS/PLAN-${TICKET_KEY}.md committed with implementation phases
- Ready to begin execution

**Next Steps**:
1. Review PLANS/PLAN-${TICKET_KEY}.md
2. Begin Phase 1: Setup & Analysis"

atlassian_addCommentToJiraIssue \
  --cloudId "$CLOUD_ID" \
  --issueIdOrKey "$TICKET_KEY" \
  --commentBody "$COMMENT"
```

### Step 9: Prompt for Plan Execution

Ask user if they want to proceed:

```
✓ JIRA ticket created: $TICKET_KEY
✓ Branch created and checked out: $TICKET_KEY
✓ PLANS/PLAN-${TICKET_KEY}.md committed and pushed

Would you like to proceed with executing the plan?
- Yes: Start with Phase 1 tasks
- No: Stop here and execute manually later

[If Yes]: Begin executing todo items from PLANS/PLAN-${TICKET_KEY}.md
[If No]: Workflow complete. Run tasks manually when ready.
```

## Best Practices

### Ticket Description
- **Be specific**: "Add JWT authentication" vs "Add auth"
- **Include context**: Why is this needed?
- **Define done**: Clear acceptance criteria
- **Limit scope**: One feature/fix per ticket

### Branch Naming
- Use ticket key for traceability
- Keep it short and descriptive
- Use lowercase with hyphens

### PLANS/PLAN-{TICKET_KEY}.md Structure
- Start with phases for large work
- Each phase has clear todo items
- Todos are actionable and verifiable
- Include success criteria
- Use ticket-specific filename for traceability
- Store in PLANS/ directory for organization

### Commit Messages
- Use semantic commits: `docs(plan):`, `feat:`, `fix:`
- Reference ticket key in message
- Keep first line under 72 chars

## Common Issues

### Cannot Create JIRA Ticket
**Issue**: Permission denied or project not found

**Solution**:
- Verify project key is correct
- Check user has create permissions
- Use `atlassian_getVisibleJiraProjects` to list accessible projects

### Branch Already Exists
**Issue**: Branch with same name exists

**Solution**:
```bash
# Switch to existing branch
git checkout "$TICKET_KEY"

# Or force create new
git checkout -B "$TICKET_KEY"
```

### Push Rejected
**Issue**: Remote has updates

**Solution**:
```bash
git pull --rebase origin main
git push -u origin "$TICKET_KEY"
```

### Subtask Creation Fails
**Issue**: Cannot link subtask to parent

**Solution**:
- Ensure parent Story exists first
- Use correct parent key format
- Verify subtask issue type is enabled in project

## Troubleshooting Checklist

**Before starting**:
- [ ] JIRA account has project access
- [ ] Git repository initialized
- [ ] Remote repository configured
- [ ] Working directory clean

**After ticket creation**:
- [ ] Ticket key captured
- [ ] Ticket accessible via URL
- [ ] Subtasks created (if Story)

**After branch creation**:
- [ ] Branch name matches ticket key
- [ ] Branch checked out successfully

**After PLANS/PLAN-{TICKET_KEY}.md**:
- [ ] All sections populated
- [ ] Phases have actionable todos
- [ ] Acceptance criteria listed
- [ ] Filename includes ticket key
- [ ] File stored in PLANS/ directory

**After commit/push**:
- [ ] PLANS/PLAN-{TICKET_KEY}.md committed with semantic message
- [ ] Branch pushed to remote
- [ ] JIRA ticket updated with progress

## Example Usage

```
User: Create a JIRA ticket for adding user authentication

Agent: I'll help you create a JIRA ticket. Please provide:

1. **Summary**: [Brief title, max 72 chars]
2. **Overview**: [What this ticket accomplishes]
3. **Acceptance Criteria**: [Definition of done]
4. **Scope**: [Files/areas affected]
5. **Technical Notes**: [Implementation details, optional]

User: 
1. Implement user authentication API
2. Add JWT-based authentication endpoints
3. Users can register, login, logout. Protected routes work.
4. src/api/auth/, src/middleware/
5. Use bcrypt, 24h token expiry

Agent: Is this a large piece of work that should be broken into subtasks?
- Story with Subtasks
- Single Task

User: Single Task

Agent: Which JIRA project?
- IBIS
- PROJ
- DA

User: IBIS

Agent: 
✓ Created JIRA ticket: IBIS-456
✓ Created branch: IBIS-456
✓ Created PLANS/PLAN-IBIS-456.md with 5 phases
✓ Committed and pushed to remote

Proceed with plan execution? (yes/no)
```
