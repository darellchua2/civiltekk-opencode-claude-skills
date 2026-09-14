---
name: git-compact-commits-skill
description: "Concise commits within strict budgets — 72-char subject, 150-word body, semantic grouping. Triggers: compact commit, concise commit, terse commit."
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

## What I Do

I provide compact commit message authoring and CI enforcement:

1. **Semantic Grouping**: Combine related changes into single commits by phase, concern, or module
2. **Compact Authoring**: Write commit messages within strict word/character budgets (150-word body, 72-char subject)
3. **CI Enforcement**: Configure commitlint with custom word-count plugin and GitHub Actions workflow
4. **Local Enforcement**: Pre-commit hook alternative for local validation

This is a **guidance + enforcement skill** — I teach compact authoring AND provide the CI/CD config to enforce it.

For commit type definitions and scope conventions, see `git-semantic-commits`.
For the full release pipeline (PR titles, merge strategy, release tags), see `semantic-release-convention`.

## When to Use Me

Use this skill when:
- Writing commit messages that need to stay within word/character limits
- Grouping multiple related file changes into a single commit
- Setting up commitlint with word-count enforcement in GitHub Actions
- Creating a local pre-commit hook for message length validation
- Preparing commits before a squash-merge PR workflow

## Authority Boundaries

| Concern | Authority Skill | Role |
|---------|----------------|------|
| Commit types, scopes, breaking changes | `git-semantic-commits` | Format definition |
| Release pipeline, PR titles, merge strategy | `semantic-release-convention` | CI/CD workflow |
| **Length budgets, grouping, compact writing** | **`git-compact-commits` (this skill)** | **Config details** |
| commitlint config with extended rules | `git-compact-commits` (this skill) | Enforcement rules |

## Scope: Two Use Cases

This skill targets **both** commit scenarios in a squash-merge workflow:

### 1. Branch Commits (Pre-Squash)

Individual commits during development on a feature branch. These keep `git log` readable during code review and make `git rebase -i` easier.

```
feat(auth): add JWT token refresh and session store

Implement automatic token refresh when access token expires.
Add session storage for persisting auth state across reloads.

Refs: BT-54
```

### 2. Squash-Merge Output

The canonical commit produced by squash-merging a PR. This becomes the permanent record in the target branch.

```
feat(auth): add OAuth2 support with token refresh and session persistence

Implement OAuth2 authentication flow with support for Google and GitHub
providers. Add automatic token refresh when access token expires.
Include session storage for persisting auth state across page reloads
and browser restarts.

BREAKING CHANGE: auth config schema has changed

Closes BT-54
```

---

## Section 1: Semantic Grouping Strategy

### Decision Matrix

```
GROUP into 1 commit when:              SPLIT into N commits when:
├─ Same concern (all auth changes)     ├─ Different concerns (auth + billing)
├─ Same phase (all setup changes)      ├─ Different phases (setup + test)
├─ Same module/directory               ├─ Different modules (api + ui)
├─ Mutually dependent changes          ├─ Independent changes
└─ Combined body ≤ 150 words          └─ Each deserves its own context
```

### Grouping Patterns

#### By Phase

Group changes that belong to the same development phase:

```
Phase: Setup
  - Add config file
  - Add environment variables
  - Create database migration
  → 1 commit: feat(db): add database schema and migration config

Phase: Implementation
  - Add model class
  - Add repository layer
  - Add service layer
  → 1 commit: feat(api): implement user CRUD with repository pattern

Phase: Testing
  - Add unit tests
  - Add integration test
  - Update test fixtures
  → 1 commit: test(api): add unit and integration tests for user CRUD
```

#### By Concern

Group changes that address the same business concern:

```
Concern: Authentication
  - Add login endpoint
  - Add token middleware
  - Add session handler
  → 1 commit: feat(auth): add login flow with JWT and session handling

Concern: Error Handling
  - Add error boundary
  - Add global error handler
  - Add error logging
  → 1 commit: feat(core): add error handling with boundary and logging
```

#### By Module

Group changes in the same directory or module:

```
Module: src/components/Button/
  - Button.tsx
  - Button.test.tsx
  - Button.styles.ts
  → 1 commit: feat(ui): add Button component with tests and styles
```

### Anti-Patterns

**Don't group unrelated changes:**
```
BAD: feat: add login endpoint, fix typo in readme, update deps
GOOD: 3 separate commits for each concern
```

**Don't group if the body exceeds 150 words:**
```
BAD: A single commit covering 5 unrelated features
GOOD: 5 focused commits, each under 150 words
```

**Don't group fixes with features:**
```
BAD: feat: add user registration and fix login timeout
GOOD: feat(auth): add user registration + fix(auth): resolve login timeout
```

---

## Section 2: Length Budgets

### Character and Word Limits

| Part | Ideal | Hard Limit | Rationale |
|------|-------|-----------|-----------|
| Subject line | 50 chars | 72 chars | GitHub truncates at 72 |
| Body | ≤100 words | 150 words | Readability in git log |
| Body line | 72 chars | 72 chars | Terminal width convention |
| Footer line | 72 chars | 72 chars | Consistency with body |
| Total message | ≤200 words | 250 words | Enforce brevity |

### Length Calculation

```bash
count_subject_chars() {
  echo "$1" | sed 's/^[^:]*: //' | wc -c
}

count_body_words() {
  echo "$1" | sed '1,/^$/d' | wc -w
}

count_body_lines_over_72() {
  echo "$1" | sed '1,/^$/d' | awk 'length > 72'
}
```

---

## Section 3: Compact Writing Techniques

### 1. Use Active Voice, Imperative Mood

```
BAD:  Added authentication middleware that validates tokens
GOOD: Add token validation middleware

BAD:  Fixed the bug where users couldn't log in
GOOD: Prevent login failure on expired tokens
```

### 2. Use Scopes to Absorb Context

The scope replaces explanatory text:

```
BAD:  feat: add user registration endpoint to the API
GOOD: feat(api): add user registration endpoint

BAD:  fix: resolve CSS layout issue on the login page mobile view
GOOD: fix(ui): resolve mobile layout on login page
```

### 3. Omit "How" — Focus on "What" and "Why"

```
BAD:  feat(auth): add JWT refresh by checking expiry and calling
      the /token/refresh endpoint with the stored refresh token
GOOD: feat(auth): add automatic token refresh on expiry

The "how" belongs in the code, not the commit message.
```

### 4. Use Bullet Points, Not Paragraphs

```
BAD (paragraph):
feat(auth): add OAuth2 support with Google and GitHub providers
including token refresh mechanism, error handling for expired
tokens, session persistence across page reloads, and automatic
redirect to login when session expires

GOOD (bullets):
feat(auth): add OAuth2 support for third-party providers

- Add Google and GitHub provider integration
- Implement automatic token refresh on expiry
- Persist auth state across page reloads
- Redirect to login on session expiration
```

### 5. Consolidate Similar Items

```
BAD:
feat(api): add user registration
feat(api): add user login
feat(api): add user logout

GOOD:
feat(api): add user registration, login, and logout endpoints
```

### 6. Use Abbreviations Strategically

```
BAD:  feat: add continuous integration and continuous deployment pipeline
GOOD: feat: add CI/CD pipeline

BAD:  fix: fix representational state transfer application programming interface
GOOD: fix(api): resolve REST endpoint routing
```

---

## Section 4: Commit Templates

### Template: Multi-File Grouped Commit

```
<type>(<scope>): <concise subject>

- Change 1 description
- Change 2 description
- Change 3 description

[Optional: Why these changes are related]

Refs: <ticket>
```

**Example:**
```
feat(auth): add OAuth2 login flow with session management

- Add Google and GitHub OAuth2 provider configuration
- Implement token exchange and refresh endpoints
- Add session middleware for auth state persistence

Refs: BT-54
```

### Template: Phase-Based Grouped Commit

```
<type>(<scope>): <phase> <concise subject>

<phase-specific details>

Refs: <ticket>
```

**Example (setup phase):**
```
chore(infra): set up database and migration tooling

- Add PostgreSQL connection config and environment variables
- Create initial schema migration for users table
- Configure migration runner with seed data support

Refs: BT-54
```

### Template: Multi-Concern (Squash-Merge Output)

```
<type>(<scope>): <primary feature summary>

<primary feature details>

- <secondary concern 1>
- <secondary concern 2>

[Optional footer]

Closes: <ticket>
```

**Example:**
```
feat(api): add user authentication with OAuth2 and session management

Implement OAuth2 authentication flow supporting Google and GitHub
providers with automatic token refresh and error handling.

- Add session middleware for auth state persistence
- Add CSRF protection for OAuth2 callback
- Update API docs with authentication endpoints

BREAKING CHANGE: auth config schema has changed

Closes BT-54
```

### Template: Compact Fix

```
fix(<scope>): <root cause> → <effect>

<one-line explanation of the fix>

Refs: <ticket>
```

**Example:**
```
fix(auth): handle expired refresh tokens gracefully

Check token expiry before refresh attempt to prevent
401 errors on stale sessions.

Refs: BT-54
```

---

## Section 5: GitHub Actions Enforcement

### commitlint.config.js

```js
// commitlint.config.js
// Authority: git-compact-commits-skill
// This is the single source of truth for commitlint length rules.
// The CI workflow in semantic-release-convention-skill section 6.1
// references this config.

module.exports = {
  extends: ['@commitlint/config-conventional'],
  plugins: ['./commitlint-word-count.js'],
  rules: {
    'header-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 72],
    'footer-max-line-length': [2, 'always', 72],
    'body-word-count': [2, 'always', 150],
  },
}
```

### Custom Word Count Plugin

```js
// commitlint-word-count.js
// Custom commitlint rule for body word count enforcement

module.exports = {
  rules: {
    'body-word-count': (parsed, when, value) => {
      const body = parsed.body || ''
      const wordCount = body.trim().split(/\s+/).filter(Boolean).length

      if (wordCount === 0) return [true, '']

      const max = value || 150
      const pass = when === 'always' ? wordCount <= max : wordCount > max

      return [
        pass,
        pass
          ? ''
          : `Body has ${wordCount} words (${when === 'always' ? 'maximum' : 'minimum'} ${max}). Group related changes or use bullet points to stay within the limit.`,
      ]
    },
  },
}
```

### GitHub Actions Workflow

```yaml
# .github/workflows/commit-lint.yml
name: Commit Lint
on: [push, pull_request]

permissions:
  contents: read
  pull-requests: read

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: wagoid/commitlint-github-action@v6
        with:
          configFile: commitlint.config.js
```

### Package.json Dev Dependency

```json
{
  "devDependencies": {
    "@commitlint/cli": "^19.0.0",
    "@commitlint/config-conventional": "^19.0.0"
  }
}
```

---

## Section 6: Local Git Hook

### Pre-Commit Hook (commit-msg)

```bash
#!/bin/bash
# .git/hooks/commit-msg
# Validates commit message follows compact conventions

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# --- Subject length (72 chars hard limit) ---
SUBJECT=$(echo "$COMMIT_MSG" | head -1)
if [ ${#SUBJECT} -gt 72 ]; then
  echo "ERROR: Subject line is ${#SUBJECT} chars (max 72)"
  echo "Subject: $SUBJECT"
  exit 1
fi

# --- Word count (150 words hard limit) ---
BODY=$(echo "$COMMIT_MSG" | sed '1,/^$/d')
if [ -n "$BODY" ]; then
  WORD_COUNT=$(echo "$BODY" | wc -w)
  if [ "$WORD_COUNT" -gt 150 ]; then
    echo "ERROR: Body is ${WORD_COUNT} words (max 150)"
    echo "Tip: Use bullet points or split into multiple commits"
    exit 1
  fi
fi

# --- Body line length (72 chars) ---
if [ -n "$BODY" ]; then
  LONG_LINES=$(echo "$BODY" | awk 'length > 72')
  if [ -n "$LONG_LINES" ]; then
    echo "WARNING: Some body lines exceed 72 characters:"
    echo "$LONG_LINES" | while read -r line; do
      echo "  (${#line} chars): $line"
    done
  fi
fi

echo "Commit message validated successfully"
exit 0
```

### Installation

```bash
# Make hook executable
chmod +x .git/hooks/commit-msg

# Or use Husky for team sharing
npm install --save-dev husky
npx husky init
echo 'npx --no -- commitlint --edit "\$1"' > .husky/commit-msg
```

---

## Section 7: Integration with Existing Skills

### Relationship Map

```
git-semantic-commits          (types, scopes, format)
         │
         ├── defines ──→ format structure
         │
         ▼
git-compact-commits           (length, grouping, compact writing)
         │
         ├── extends ──→ length budgets + grouping strategy
         ├── provides ──→ commitlint.config.js (authority for rules)
         │
         ▼
semantic-release-convention   (CI/CD workflow, PR titles, release tags)
         │
         ├── consumes ──→ commitlint config from git-compact-commits
         ├── governs ──→ PR title format, merge strategy, release pipeline
         │
         ▼
     GitHub Actions           (enforcement)
```

### Data Flow

1. `git-semantic-commits` defines WHAT a commit message looks like (type, scope, format)
2. `git-compact-commits` defines HOW LONG it should be and HOW TO GROUP changes
3. `semantic-release-convention` defines WHERE the commitlint config is used in CI

### Cross-References

- `git-semantic-commits` validation section → points here for extended length enforcement
- `semantic-release-convention` section 6.1 → points here for commitlint config details

---

## Section 8: Verification Commands

### Check Subject Length

```bash
# Check last commit's subject length
git log -1 --pretty=%s | awk '{print length($0), $0}'

# Check if subject exceeds 72 chars
git log -1 --pretty=%s | awk '{if (length>72) print "FAIL:", length, "chars"; else print "OK:", length, "chars"}'
```

### Check Body Word Count

```bash
# Count words in last commit's body
git log -1 --pretty=%b | wc -w

# Check if body exceeds 150 words
git log -1 --pretty=%b | awk '{words+=NF} END {if (words>150) print "FAIL:", words, "words"; else print "OK:", words, "words"}'
```

### Check Body Line Length

```bash
# Find lines exceeding 72 chars in body
git log -1 --pretty=%b | awk 'length > 72 {print length, $0}'
```

### Validate Full Message

```bash
# Full validation of last commit
echo "=== Commit Message Validation ==="
SUBJECT=$(git log -1 --pretty=%s)
BODY=$(git log -1 --pretty=%b)
echo "Subject (${#SUBJECT} chars): $SUBJECT"
[ ${#SUBJECT} -gt 72 ] && echo "  FAIL: exceeds 72 chars" || echo "  OK"
echo "Body words: $(echo "$BODY" | wc -w)"
echo "Body lines over 72 chars:"
echo "$BODY" | awk 'length > 72 {print "  ", length, "chars:", $0}'
```

### Lint with commitlint

```bash
# Install commitlint
npm install -g @commitlint/cli @commitlint/config-conventional

# Lint last commit message
echo "$(git log -1 --pretty=%B)" | commitlint

# Lint specific message
echo "feat(auth): add OAuth2 support" | commitlint
```

---

## Section 9: Quick Reference Card

### Length Budgets

```
Subject:  ≤ 72 chars  (50 ideal)
Body:     ≤ 150 words (100 ideal)
Lines:    ≤ 72 chars per line
Total:    ≤ 250 words (200 ideal)
```

### Grouping Rules

```
GROUP when: same concern + same phase + same module + ≤ 150 words
SPLIT when: different concern OR different phase OR > 150 words
```

### Compact Writing Checklist

```
☐ Subject under 72 chars?
☐ Imperative mood? ("add" not "added")
☐ Scope absorbs context? (feat(api): not "add api endpoint for")
☐ Body uses bullets, not paragraphs?
☐ "How" omitted (only "what" and "why")?
☐ Similar items consolidated?
☐ Body under 150 words?
☐ Lines wrapped at 72 chars?
```

---

## References

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Chris Beams - How to Write a Git Commit Message](https://cbea.ms/posts/git-commit/)
- [Tim Pope - A Note About Git Commit Messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
- [commitlint Documentation](https://commitlint.js.org/)
- [commitlint Rules Reference](https://commitlint.js.org/reference/rules)
- [wagoid/commitlint-github-action](https://github.com/wagoid/commitlint-github-action)
