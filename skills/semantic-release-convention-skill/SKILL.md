---
name: semantic-release-convention-skill
description: >-
  Source of truth for commit-to-PR-to-merge-to-release conventions — semver
  labels, branch-aware tagging, changelogs, release pipelines.
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

## What I do

I define the standardized conventions for the entire release pipeline from commit to deployment:

1. **Commit Message Convention**: Conventional Commits format with types, scopes, and breaking change indicators
2. **PR Title Convention**: PR titles must follow Conventional Commits format
3. **PR Label Rules**: Every PR requires exactly one semver label (`major`/`minor`/`patch`) as the version bump decision factor
4. **Merge Strategy**: Squash merge with conventional commit title and PR description as body
5. **Release Tag Convention**: Branch-aware versioned tags with prerelease suffixes
6. **GitHub Actions Requirements**: Four CI/CD workflows for enforcement

This is a **governance skill** - it defines conventions that other skills and agents MUST follow. It does not execute workflows itself.

## When to use me

- When creating commit messages, PR titles, or release tags
- When determining version bump type for a PR
- When generating release tags for different branches
- When setting up GitHub Actions for release enforcement
- When any skill needs to know the correct convention for commits, PRs, or releases

## Governed Skills

| Skill | What It Consumes |
|-------|-----------------|
| `git-semantic-commits` | Commit type definitions and format rules |
| `git-compact-commits` | Length budgets (72-char subject, 150-word body), semantic grouping strategy, commitlint config authority |
| `pr-creation-workflow` | PR title format, label mapping, merge conventions, JIRA image handling |
| `nextjs-pr-workflow` | Inherits via `pr-creation-workflow` |
| `git-issue-labeler` | Semver label definitions and detection |
| `changelog-python-cliff` | Changelog category structure from commit types |
| `version-bump-standard` | Release tag formats, branch-aware pre-release suffixes, workflow templates for dev/uat/main flow |

## Consumed By

| Consumer | Type | Usage |
|----------|------|-------|
| `pr-workflow-subagent` | Agent | PR creation with release conventions |
| `ticket-creation-skill` | Skill | Version label assignment during ticket creation (primary direct load) |

---

## 1. Commit Message Convention

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Rules

- **type**: Required. One of the allowed types (see below)
- **scope**: Optional. Identifies affected component/package. Lowercase, short
- **subject**: Required. Imperative mood, no period, under 72 characters
- **body**: Optional. Explains what and why (not how). Wrap at 72 characters
- **footer**: Optional. `BREAKING CHANGE:`, `Closes #123`, `Refs: #456`

### Allowed Types

| Type | Description | Version Impact |
|------|-------------|---------------|
| `feat` | New feature | MINOR |
| `fix` | Bug fix | PATCH |
| `docs` | Documentation only | PATCH (via PR label) |
| `style` | Formatting, whitespace | PATCH (via PR label) |
| `refactor` | Code restructuring | PATCH (via PR label) |
| `test` | Adding/correcting tests | PATCH (via PR label) |
| `chore` | Build, config, deps | PATCH (via PR label) |
| `perf` | Performance improvement | PATCH or MINOR |
| `ci` | CI/CD changes | PATCH (via PR label) |
| `build` | Build system changes | PATCH (via PR label) |
| `revert` | Revert previous commit | Depends on reverted commit |

### Breaking Changes

Indicate breaking changes using EITHER:

**Option 1**: Exclamation mark after type/scope:
```
feat(api)!: change authentication endpoint URL structure
```

**Option 2**: `BREAKING CHANGE:` in footer:
```
feat(api): add new authentication flow

BREAKING CHANGE: The authentication API has been updated.
```

Breaking changes trigger MAJOR version increment.

### Examples

```
feat(auth): add OAuth2 support for third-party providers
fix(ui): resolve mobile layout issue on login page
docs(readme): update installation instructions for v2
refactor(api): extract user service into separate module
test(auth): add unit tests for token refresh mechanism
chore(deps): upgrade React to v18
perf(db): optimize query performance for user search
feat(api)!: remove deprecated v1 endpoints
```

---

## 2. PR Title Convention

### Rules

- PR titles MUST follow Conventional Commits format (same as commit messages)
- This ensures consistency between commits and PRs when using squash merge

### Format

```
<type>(<scope>): <subject> [${TRACKING_ID}]
```

### Examples

```
feat: add user authentication [IBIS-456]
fix(ui): resolve layout issue [#158]
feat(api)!: breaking change to authentication [IBIS-789]
docs: update API documentation [IBIS-100]
chore(deps): upgrade dependencies [#200]
```

---

## 3. PR Label Rules (Version Bump Decision Factor)

### Core Principle

**The PR label is THE single decision factor for determining the version bump.** Not the commit type, not the PR title. The label must be explicitly applied.

### Required Labels

Every PR MUST have exactly ONE of these semver labels:

| Label | Color | Hex | Version Bump | When to Apply |
|-------|-------|-----|-------------|---------------|
| `major` | Red | #d73a4a | X.0.0 | Breaking changes (API removal, incompatible changes) |
| `minor` | Yellow | #fbca04 | 0.X.0 | New features, new APIs, new components |
| `patch` | Green | #0e8a16 | 0.0.X | Bug fixes, documentation, refactoring, tests, chores |

### Auto-Detection Logic

Labels are auto-detected from PR title using this mapping:

| PR Title Pattern | Label |
|-----------------|-------|
| `feat!` or `feat(scope)!` | `major` |
| `feat` | `minor` |
| `fix`, `docs`, `refactor`, `style`, `test`, `chore`, `perf`, `ci`, `build` | `patch` |

```bash
if [[ "$PR_TITLE" =~ ^[^:]+\! ]]; then
  VERSION_LABEL="major"
elif [[ "$PR_TITLE" =~ ^feat ]]; then
  VERSION_LABEL="minor"
else
  VERSION_LABEL="patch"
fi
```

### Application

```bash
gh pr edit "$PR_NUMBER" --add-label "$VERSION_LABEL"
```

### Enforcement

A PR MUST NOT be merged without exactly one semver label. GitHub Actions should enforce this.

---

## 4. Merge Strategy

### Convention: Squash Merge

All PRs are merged using **squash merge** to maintain a clean, conventional commit history.

### Merge Commit Format

- **Title**: PR title (already in Conventional Commits format)
- **Body**: PR description

This produces one conventional commit per PR in the target branch, making the git history clean and changelog generation reliable.

### GitHub Settings

Configure in repository settings:
- **Allow squash merging**: Yes
- **Squash merge commit title**: PR title
- **Squash merge commit message**: PR body
- **Allow merge commits**: No (or disabled for enforcement)
- **Allow rebase merging**: Optional

---

## 5. Release Tag Convention

### Tag Format

All release tags use the `v` prefix followed by SemVer:

- **Production**: `v{MAJOR}.{MINOR}.{PATCH}` (no suffix)
- **Non-production**: `v{MAJOR}.{MINOR}.{PATCH}-{BRANCH}.{N}` (prerelease suffix with auto-increment)

### Branch-Aware Tag Mapping

| Branch | Tag Format | Example |
|--------|-----------|---------|
| `main` / `master` / `production` | `v1.0.0` | `v1.2.3` |
| `uat` | `v1.0.0-uat.1` | `v1.2.3-uat.5` |
| `staging` | `v1.0.0-staging.1` | `v1.2.3-staging.2` |
| `dev` | `v1.0.0-dev.1` | `v1.2.3-dev.8` |
| `pre-dev` | `v1.0.0-pre-dev.1` | `v1.2.3-pre-dev.3` |

### Rules

1. **`v` prefix** on ALL tags (industry standard, expected by GitHub, semantic-release, etc.)
2. **No suffix** on production branches (clean SemVer for releases)
3. **Prerelease suffix** on non-production branches (valid SemVer per specification)
4. **Auto-incrementing counter** (`.1`, `.2`, `.3`) per branch for each version
5. The **base version** is determined by the PR label that was merged
6. The **suffix** only indicates the environment, not the version impact

### Version Bump Source

The version bump comes from the PR label:

| PR Label | Base Version Change |
|----------|-------------------|
| `major` | X.0.0 |
| `minor` | 0.X.0 |
| `patch` | 0.0.X |

### Tag Creation

```bash
# On production branch
git tag -a "v1.2.3" -m "Release v1.2.3"

# On dev branch
git tag -a "v1.2.3-dev.4" -m "Pre-release v1.2.3-dev.4 for dev"
```

---

## 6. GitHub Actions Requirements

Four workflows enforce and automate these conventions:

### 6.1. Commit Lint

**Purpose**: Enforce Conventional Commits on every push

**Tool**: `commitlint` with `@commitlint/config-conventional`

**Trigger**: Push to any branch

> **Note**: The commitlint configuration with extended length rules (72-char subject, 150-word body, custom word-count plugin) is maintained in `git-compact-commits-skill`. That skill is the **authority** for `commitlint.config.js` and the word-count plugin. The workflow below uses that config.

```yaml
name: Commit Lint
on: [push]
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

### 6.2. PR Title Validation

**Purpose**: Validate PR title follows Conventional Commits

**Tool**: `action-semantic-pull-request`

**Trigger**: Pull request opened, edited, synchronize

```yaml
name: PR Title Validation
on:
  pull_request:
    types: [opened, edited, synchronize]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            docs
            style
            refactor
            test
            chore
            perf
            ci
            build
            revert
```

### 6.3. Semver Label Enforcement

**Purpose**: Ensure every PR has exactly one semver label before merge

**Trigger**: Pull request labeled, unlabeled, opened

```yaml
name: Semver Label Check
on:
  pull_request:
    types: [labeled, unlabeled, opened, synchronize]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - name: Check semver label
        env:
          PR_LABELS: ${{ toJson(github.event.pull_request.labels) }}
        run: |
          SEMVER_LABELS=$(echo "$PR_LABELS" | jq -r '.[].name' | grep -cE '^(major|minor|patch)$' || true)
          if [ "$SEMVER_LABELS" -ne 1 ]; then
            echo "ERROR: PR must have exactly one semver label (major, minor, or patch)"
            echo "Found: $SEMVER_LABELS semver label(s)"
            exit 1
          fi
          echo "Semver label check passed"
```

### 6.4. Automated Release

**Purpose**: Auto-version, tag, and create GitHub Release on merge

**Tool**: `semantic-release` or custom workflow reading PR label

**Trigger**: Push to main/master/production (after PR merge)

**Behavior**:
1. Read the merged PR's semver label
2. Determine version bump (major/minor/patch)
3. Detect current branch for prerelease suffix
4. Calculate new version with auto-incrementing prerelease counter
5. Create git tag
6. Generate changelog from conventional commits
7. Create GitHub Release with changelog notes

---

## Quick Reference

### Decision Flow

```
1. Developer writes commit → Must follow Conventional Commits
2. Developer creates PR → Title must follow Conventional Commits
3. PR gets semver label → Auto-detected from title, manually adjustable
4. PR is reviewed → Label enforcement ensures exactly 1 semver label
5. PR is squash-merged → Title becomes commit message in target branch
6. GitHub Action fires → Reads PR label, determines version bump
7. Release tag created → Branch-aware: v1.2.3 (prod) or v1.2.3-dev.1 (dev)
8. GitHub Release created → With auto-generated changelog
```

### Conventions Summary

| Aspect | Convention |
|--------|-----------|
| Commit format | `<type>(<scope>): <subject>` |
| PR title format | `<type>(<scope>): <subject> [TICKET]` |
| Version decision factor | PR label (`major`/`minor`/`patch`) |
| Merge strategy | Squash merge |
| Production tags | `v1.0.0` |
| Non-production tags | `v1.0.0-{branch}.N` |
| Breaking changes | `feat!:` or `BREAKING CHANGE:` in footer |

---

## References

- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/)
- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [commitlint](https://commitlint.js.org/)
- [action-semantic-pull-request](https://github.com/amannn/action-semantic-pull-request)
- [semantic-release](https://semantic-release.gitbook.io/semantic-release/)
