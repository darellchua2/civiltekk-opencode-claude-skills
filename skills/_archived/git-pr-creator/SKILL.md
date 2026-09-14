---
name: git-pr-creator
description: Create Git PRs with semantic versioning labels (major/minor/patch), JIRA ticket updates, and image attachments using git-semantic-commits formatting
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: pr-creation
---

## What I do

I implement a complete Git PR creation workflow with optional JIRA integration:

1. **Check JIRA Integration**: Ask user if JIRA is used for the project
2. **Create Pull Request**: Create a GitHub/GitLab PR with comprehensive description
3. **Use git-semantic-commits**: Format PR title following Conventional Commits specification
4. **Apply Semantic Versioning Label**: Auto-apply major/minor/patch label based on PR title
5. **Scan for Diagrams/Images**: Search for workflow-related images and diagrams
6. **Attach Images to JIRA**: Upload local/temporary images directly to JIRA (not just links)
7. **Add JIRA Comments**: Use `git-issue-updater` to create comments with PR details and attachments
8. **Update JIRA Status** (Optional): Delegate to `jira-status-updater` to transition ticket status after manual merge


## When to use me

Use this workflow when:
- You've completed work on a feature or fix and need to create a PR
- You want to update JIRA tickets with PR information
- You have diagrams or images that need to be attached to JIRA (not just linked)
- You need to ensure JIRA tickets are updated with actual image files for visibility
- You want to maintain traceability between PRs and JIRA tickets

## Prerequisites

- Git repository with commits to push
- GitHub CLI (`gh`) or GitLab CLI (`glab`) installed and authenticated
- If using JIRA: Atlassian account with appropriate permissions
- JIRA cloud ID and project key
- Existing JIRA ticket(s) to update

## Steps

### Step 1: Check Git Status
- Verify current git status:
  ```bash
  git status
  ```
- Ensure all changes are committed
- Check for uncommitted changes that need attention

### Step 2: Ask About JIRA Integration
- Prompt the user: "Is JIRA used for this project? (yes/no)"
- If yes, proceed with JIRA integration steps
- If no, skip JIRA-related steps and only create the PR

### Step 3: Get JIRA Ticket Information (if JIRA is used)
- Ask the user for the JIRA ticket ID (e.g., "IBIS-101")
- Verify the ticket exists using Atlassian MCP tools
- Get the cloud ID if not provided

### Step 4: Create Pull Request
- Push the current branch to remote:
   ```bash
  git push -u origin <branch-name>
  ```
- **Use git-semantic-commits for PR title formatting**:
  - Format PR title following Conventional Commits specification
  - Examples: `feat: add login functionality`, `fix(auth): resolve session timeout`, `docs: update API documentation`
  - Include scope when relevant: `feat(api): add user authentication`, `fix(ui): resolve layout issue`
  - Use breaking change indicator if applicable: `feat!: change API signature` or `feat(api)!: breaking change to authentication`
- Create the PR with a comprehensive description:
   ```bash
  gh pr create --title "<PR Title>" --body "<PR Description>"
  ```
- PR description should include:
   - Overview of changes
   - JIRA ticket reference (if applicable)
   - Files changed
   - Testing performed
   - Screenshots/diagrams (as references)

### Step 5: Apply Semantic Versioning Label

After PR creation, automatically apply version label based on PR title:
```bash
# Get PR number from last created PR
PR_NUMBER=$(gh pr list --head "$(git branch --show-current)" --json number --jq '.[0].number')

# Detect version bump type from PR title
PR_TITLE="<PR Title>"

if [[ "$PR_TITLE" =~ ^[^:]+\! ]]; then
  # Breaking change (e.g., "feat!:" or "feat(scope)!")
  VERSION_LABEL="major"
elif [[ "$PR_TITLE" =~ ^feat ]]; then
  # New feature
  VERSION_LABEL="minor"
elif [[ "$PR_TITLE" =~ ^fix ]]; then
  # Bug fix
  VERSION_LABEL="patch"
else
  # Default to patch for docs, refactor, style, test, chore
  VERSION_LABEL="patch"
fi

# Apply the label
gh pr edit "$PR_NUMBER" --add-label "$VERSION_LABEL"

echo "Applied '$VERSION_LABEL' label to PR #$PR_NUMBER"
```

**Label mapping**:
- `feat!` or `feat(scope)!` → `major` (breaking changes)
- `feat` → `minor` (new features)
- `fix`, `docs`, `refactor`, `style`, `test`, `chore` → `patch` (bug fixes/improvements)

### Step 6: Scan for Diagrams and Images
- Search for image files in the repository:
  ```bash
  # Common image locations
  find . -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.svg" \) -not -path "*/node_modules/*"
  
  # Check diagrams directory
  ls -la diagrams/
  
  # Check tmp directory
  ls -la /tmp/*.png /tmp/*.jpg /tmp/*.svg 2>/dev/null
  ```
- Identify workflow-related images:
  - Look for files with names like: `workflow`, `diagram`, `flow`, `process`, `architecture`
  - Check recent image creation timestamps
  - Ask user to confirm which images are relevant

### Step 7: Categorize Images
- For each image found, determine:
  - **Accessible images**: Hosted on public URLs or cloud storage (can be linked)
  - **Local/temporary images**: Files in `/tmp/`, local directories, or private servers (must be attached)

### Step 8: Upload Local Images to JIRA (if JIRA is used)

For each local/temporary image that needs to be shared on JIRA:

1. **Upload the image to JIRA**:
   Use Atlassian MCP tool `atlassian_addAttachmentToJiraIssue` with:
   - cloudId: The Atlassian cloud ID
   - issueIdOrKey: The JIRA ticket key
   - attachment: Path to the local image file
   
2. **Get the attachment URL**:
   - The response will include the attachment URL hosted on JIRA
   - This URL is accessible within the JIRA ecosystem

3. **Store attachment URLs** for use in comments

### Step 9: Create JIRA Comments (if JIRA is used)

Create a comprehensive comment on the JIRA ticket with PR details using `atlassian_addCommentToJiraIssue`.

**Comment Template**:
```markdown
## Pull Request Created

**PR**: #<PR_NUMBER> - <PR_TITLE>
**URL**: <PR_URL>
**Branch**: <branch-name>

### Changes Summary
<Brief description of what was implemented>

### Files Modified
<list of key files changed>

### Diagrams/Visuals
<embed uploaded images using JIRA attachment format>

### Testing Performed
<test coverage and results>

### Review Request
@reviewer1 @reviewer2
```

### Step 10: Verify and Report

- Verify PR creation:
  ```bash
  gh pr view
  ```
- Verify JIRA comment (if applicable)
- Display summary:
  ```
  ✅ Pull request created successfully!
  ✅ Branch pushed to remote
  ✅ JIRA ticket updated (if applicable)
  ✅ Images attached to JIRA (if applicable)
  
  **PR Details**:
  - PR: #<number>
  - URL: <pr-url>
  - Title: <title>
  
  **JIRA Update**:
   - Ticket: <TICKET-KEY>
   - Comments added: Yes
   - Images attached: <count>
   ```

### Step 11: Update JIRA Ticket Status (Optional)

**Purpose**: Provide option to update JIRA ticket status after manual PR merge

**When to use**:
- PR was manually merged (not through pr-creation-workflow)
- You want to transition JIRA ticket to "Done" status
- You have merged the PR outside of the automated workflow

**Implementation**:

For JIRA ticket status updates after PR merge, delegate to the `jira-status-updater` skill which handles:
- Ticket detection from PR title, commits, and branch name
- Smart target status detection
- Pre-flight checks to avoid unnecessary transitions
- Comprehensive error handling

## Image Handling Strategy

> **Note**: For the detailed JIRA image upload workflow (attachment API usage, URL retrieval, error handling), refer to the `jira-git-integration` skill. The section below provides a brief summary specific to PR creation.
### For Accessible Images (Public URLs)
If the image is already hosted on a public URL (e.g., GitHub, S3, cloud storage):
- Embed directly in JIRA comment using markdown:
  ```markdown
  ![Diagram](https://example.com/workflow.png)
  ```
- No need to upload as attachment

### For Local/Temporary Images
If the image is a local file that won't be accessible from JIRA:
- **Must upload as attachment to JIRA**
- Use the `atlassian_addAttachmentToJiraIssue` tool
- Reference the uploaded image in the comment using the attachment URL

**Example**:
```bash
# Upload local image
atlassian_addAttachmentToJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey "IBIS-101" \
  --attachment "/tmp/workflow-diagram.png"

# Response returns attachment URL:
# https://yourcompany.atlassian.net/secure/attachment/12345/workflow-diagram.png

# Use this URL in the comment
```

**Correct JIRA Comment with Attachment**:
```markdown
### Workflow Diagram

![Workflow Diagram](https://company.atlassian.net/secure/attachment/12345/workflow-diagram.png)
```

**Incorrect JIRA Comment (local file path)**:
```markdown
### Workflow Diagram

![Workflow Diagram](/tmp/workflow-diagram.png)
```

## Examples

### Example 1: PR with JIRA Integration and Local Image

**User**: "Create a PR for the login feature. Yes, JIRA is used. Ticket is IBIS-101."

**Execution**:
1. Push branch `feature/login` to remote
2. Create PR #42 with title "Implement login feature"
3. Scan for images:
   - Found: `/tmp/login-flow.png` (local, not accessible)
   - Found: `diagrams/architecture.png` (local, not accessible)
4. Upload images to JIRA:
   - Upload `/tmp/login-flow.png` → Gets attachment URL
   - Upload `diagrams/architecture.png` → Gets attachment URL
5. Create JIRA comment with embedded images

**JIRA Comment Created**:
```markdown
## Pull Request Created

**PR**: #42 - Implement login feature
**URL**: https://github.com/org/repo/pull/42
**Branch**: feature/login

### Changes Summary
Implemented user authentication with email/password login, session management, and password reset functionality.

### Files Modified
- src/auth/login.ts
- src/auth/session.ts
- src/components/LoginForm.tsx
- src/api/auth.ts

### Workflow Diagram

![Login Flow](https://company.atlassian.net/secure/attachment/10001/login-flow.png)

### Architecture

![System Architecture](https://company.atlassian.net/secure/attachment/10002/architecture.png)

### Testing Performed
- Unit tests: 100% coverage
- Integration tests: All passing
- Manual testing: Verified login flow end-to-end

### Review Request
@tech-lead @senior-dev
```

### Example 2: PR with Public URL Image

**User**: "Create a PR for the dashboard. Yes, JIRA is used. Ticket is IBIS-102."

**Execution**:
1. Push branch `feature/dashboard` to remote
2. Create PR #43
3. Scan for images:
   - Found: `https://cdn.example.com/dashboard-mockup.png` (public URL)
   - Found: `/tmp/notes.png` (local, not accessible)
4. Upload only local image to JIRA
5. Create JIRA comment with both public URL and embedded attachment

**JIRA Comment Created**:
```markdown
## Pull Request Created

**PR**: #43 - Implement dashboard
**URL**: https://github.com/org/repo/pull/43

### Changes Summary
Built responsive dashboard with data visualization and analytics.

### UI Mockup (Design Spec)

![Dashboard Mockup](https://cdn.example.com/dashboard-mockup.png)

### Technical Implementation Notes

![Notes](https://company.atlassian.net/secure/attachment/10003/notes.png)
```

### Example 3: PR without JIRA

**User**: "Create a PR for the bug fix. No, JIRA is not used."

**Execution**:
1. Push branch `fix/crash-issue` to remote
2. Create PR #44
3. Skip JIRA integration
4. Display summary

**Output**:
```
✅ Pull request created successfully!
✅ Branch pushed to remote

**PR Details**:
- PR: #44
- URL: https://github.com/org/repo/pull/44
- Title: Fix crash on login page

No JIRA integration requested.
```

## Image Detection and Categorization

> **Note**: The categorization logic below is a summary. For comprehensive image handling including download-and-retry for inaccessible URLs, see `jira-git-integration`.

### Detection Patterns

Search for images in these locations:
```bash
# Project diagrams
./diagrams/**/*.png
./diagrams/**/*.svg

# Recent images in tmp
/tmp/*.png
/tmp/*.jpg

# Documentation images
./docs/images/**/*.png
./assets/images/**/*.png

# Workflow-related (by filename pattern)
**/*workflow*.png
**/*diagram*.png
**/*flow*.png
**/*architecture*.png
**/*sequence*.png
```

### Categorization Logic

```bash
# Check if URL is accessible
if [[ "$image_path" =~ ^https?:// ]]; then
  # It's a URL - test if accessible
  if curl -s -o /dev/null -w "%{http_code}" "$image_path" | grep -q "200"; then
    TYPE="accessible_url"
  else
    TYPE="inaccessible_url"
  fi
else
  # It's a file path
  if [[ -f "$image_path" ]]; then
    TYPE="local_file"
  else
    TYPE="not_found"
  fi
fi
```

### Handling Each Type
- **accessible_url**: Embed directly in JIRA comment
- **inaccessible_url**: Download and upload as JIRA attachment
- **local_file**: Upload as JIRA attachment
- **not_found**: Warn user and skip

## Atlassian MCP Tools Reference

### atlassian_getAccessibleAtlassianResources
```bash
atlassian_getAccessibleAtlassianResources
```
Returns: List of accessible Atlassian resources with cloud IDs

### atlassian_addAttachmentToJiraIssue
```bash
atlassian_addAttachmentToJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey <TICKET_KEY> \
  --attachment <file-path>
```
Returns: Attachment metadata including URL

### atlassian_addCommentToJiraIssue
```bash
atlassian_addCommentToJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey <TICKET_KEY> \
  --commentBody <markdown-content>
```
Returns: Comment ID and details

### atlassian_getJiraIssue
```bash
atlassian_getJiraIssue \
  --cloudId <CLOUD_ID> \
  --issueIdOrKey <TICKET_KEY>
```
Returns: Issue details including status, assignee, etc.

## Best Practices

- Always confirm JIRA usage with the user before proceeding
- **Use git-semantic-commits for PR title formatting** to ensure consistent semantic versioning
- **Follow Conventional Commits specification**: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
- **Include scopes** in PR titles to identify affected components (e.g., feat(api):, fix(ui):)
- **Use breaking change indicator** (!) when appropriate: `feat!: breaking API change`
- Upload local/temporary images as JIRA attachments, don't link to local paths
- **Use git-issue-updater for consistent JIRA ticket comments** with user, date, time, and PR details
- Use descriptive filenames for images before uploading
- Organize images in a `diagrams/` directory for consistency
- Include PR number and brief description in JIRA comments
- Tag relevant team members in JIRA comments using `@username`
- Verify image accessibility before embedding URLs
- Clean up temporary images after uploading to JIRA
- Keep JIRA comments concise and well-formatted
- Always verify that the PR was created successfully
- Test JIRA attachments by opening the URL in a browser

## Common Issues

### Image Upload Fails
**Issue**: `atlassian_addAttachmentToJiraIssue` returns an error

**Solution**:
- Verify file path is correct
- Check file size limits (JIRA typically limits to 10-100MB per attachment)
- Ensure you have permission to add attachments to the issue
- Verify the file is not corrupted

### JIRA Comment Not Visible
**Issue**: Comment added but doesn't display images

**Solution**:
- Use the attachment URL returned by the upload API
- Don't use local file paths in comments
- Ensure markdown syntax is correct:
  ```markdown
  ![Alt text](attachment-url)
  ```

### Too Many Images
**Issue**: Too many images found in the repository

**Solution**:
- Ask user which images are relevant
- Filter by timestamp (e.g., images created in last hour)
- Focus on workflow-related images
- Allow user to select specific images to upload

### Branch Not Pushed
**Issue**: PR creation fails because branch isn't on remote

**Solution**:
```bash
# Push current branch with upstream tracking
git push -u origin $(git branch --show-current)
```

### JIRA Ticket Not Found
**Issue**: Cannot access the specified JIRA ticket

**Solution**:
- Verify the ticket ID format (e.g., IBIS-101)
- Check that you have access to the JIRA project
- Use `atlassian_getVisibleJiraProjects` to list accessible tickets
- Verify the cloud ID is correct

## Troubleshooting Checklist

Before creating PR:
- [ ] All changes are committed
- [ ] Current branch is correct
- [ ] Branch name follows conventions
- [ ] User confirmed JIRA usage (yes/no)
- [ ] PR title follows Conventional Commits format (if applicable)

Before JIRA integration (if yes):
- [ ] JIRA ticket ID is valid
- [ ] Atlassian MCP tools are available
- [ ] User has permissions to comment/attach
- [ ] Cloud ID is configured

Before image handling:
- [ ] Image files exist and are accessible
- [ ] Image sizes are within limits
- [ ] User has confirmed which images to include
- [ ] Local images will be uploaded as attachments

After completion:
- [ ] PR is created and accessible
- [ ] PR description is complete
- [ ] JIRA comment is added (if applicable)
- [ ] Images are properly embedded (not broken links)
- [ ] Summary is displayed to user

## Related Commands

```bash
# Check git status
git status

# View current branch
git branch --show-current

# Push branch with upstream
git push -u origin $(git branch --show-current)

# Create PR
gh pr create --title "Title" --body "Description"

# View PR
gh pr view

# List PRs
gh pr list

# Find recent images
find . -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.svg" \) -mtime -1

# Find images by pattern
find . -name "*workflow*.png" -o -name "*diagram*.png"

# Check file type
file workflow.png

# Get image dimensions
identify workflow.png
```

## Governance

This skill follows the conventions defined in `semantic-release-convention`:
- PR title format: Conventional Commits
- Version bump labels: `major`/`minor`/`patch` (single decision factor)
- Label mapping: `feat!` → major, `feat` → minor, `fix`/others → patch
- Release tags: Branch-aware `v{version}` on prod, `v{version}-{branch}.N` on non-prod

## Semantic Versioning Labels

Add version bump labels to indicate release impact:

| Label | Color | Description | Version Bump | Examples |
|-------|-------|-------------|--------------|----------|
| `major` | #d73a4a (red) | Breaking changes | X.0.0 | API removal, breaking refactor |
| `minor` | #fbca04 (yellow) | New features | 0.X.0 | New API, new component |
| `patch` | #0e8a16 (green) | Bug fixes | 0.0.X | Bug fix, typo correction |

**Label Mapping from Commit Type**:
- `feat!` or `feat(scope)!` → `major` (breaking change)
- `feat` → `minor` (new feature)
- `fix` → `patch` (bug fix)
- `refactor` → `patch` (code improvement)
- `docs` → `patch` (documentation)

**Usage with JIRA Integration**:
```bash
# Add version label to PR during creation
gh pr create --title "feat: add user auth [IBIS-123]" --add-label "minor"

# Add label to existing PR
gh pr edit <PR_NUMBER> --add-label "minor"

# Remove incorrect label
gh pr edit <PR_NUMBER> --remove-label "patch" --add-label "minor"
```

**Automated Labeling**:
When creating PRs with semantic commit messages, automatically apply version labels:
- PR title starts with `feat:` → suggest `minor` label
- PR title starts with `fix:` → suggest `patch` label
- PR title contains `!` → suggest `major` label

