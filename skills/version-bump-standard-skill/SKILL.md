---
name: version-bump-standard-skill
description: >-
  Consistent version bumping and release workflows — dev-to-uat-to-main flow,
  PR-label-driven semver. Use when setting up or auditing release workflows or
  onboarding a repo.
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

# Version Bump Standard

## What I do

I ensure consistent version bumping and release workflows across all CanvasTekk repositories. I enforce the dev → uat → main branch flow with PR-label-driven semantic versioning.

## When to use me

Use this skill when you need to:
- Set up or audit a repository's release workflow
- Standardize version bumping across repos
- Create or update `.github/workflows/bump-version-and-push-tag.yml`
- Configure branch protection rules for dev/uat/main
- Create enforcement workflows for branch promotion
- Attach audit bundles to production releases
- Onboard a new repo to the CanvasTekk release standard

## The Standard

### Branch Flow

```
feature branch
    │
    ▼
   dev ──────► auto-deploy dev, tag: vX.Y.Z-dev.N
    │
    │  PR: dev → uat (1 review, enforce-dev-to-uat check)
    ▼
   uat ──────► auto-deploy uat, tag: vX.Y.Z-uat.N
    │
    │  PR: uat → main (1 review, enforce-uat-to-main check, label: patch/minor/major)
    ▼
   main ─────► deploy prod, tag: vX.Y.Z (clean), GitHub Release + audit bundle
```

**No `prod` branch.** `main` is the production branch.

### Version Tag Format

| Branch | Tag Format     | Pre-release | Example       |
| ------ | -------------- | ----------- | ------------- |
| dev    | `vX.Y.Z-dev.N` | Yes         | `v1.40.0-dev.3` |
| uat    | `vX.Y.Z-uat.N`  | Yes         | `v1.40.0-uat.1`  |
| main   | `vX.Y.Z`       | No (latest) | `v1.40.0`     |

### Version Bump Determination

**For `main` (production releases):**
The PR label determines the bump type:

| PR Label  | Bump Type | Example              | When to use                          |
| --------- | --------- | -------------------- | ------------------------------------ |
| `patch`     | Patch     | v1.40.0 → v1.40.1    | Bug fixes, config changes, infra tweaks |
| `minor`     | Minor     | v1.40.0 → v1.41.0    | New features, new resources, additive changes |
| `major`     | Major     | v1.40.0 → v2.0.0     | Breaking changes, destructive migrations |

Fallback (no label): commit message analysis via `mathieudutour/github-tag-action`.

**For `dev`/`uat` (pre-releases):**
Auto-increment the pre-release number (`.N`). No label needed.

### Audit Bundle (main releases only)

Each production release includes:

```
GitHub Release vX.Y.Z
├── CHANGELOG.md          (auto-generated from PR titles since last main tag)
├── terraform-plan.txt    (tofu plan output — what changed in prod)
├── state-checksum.txt    (SHA256 of terraform.tfstate for integrity)
└── resource-diff.json    (created/modified/destroyed resource summary)
```

## Required Workflow Files

### 1. `bump-version-and-push-tag.yml` (release workflow)

Every repo MUST have this workflow. Template:

```yaml
name: Release

on:
  push:
    branches: [dev, uat, main]

permissions:
  contents: write

concurrency:
  group: ${{ github.workflow }}-${{ github.ref_name }}
  cancel-in-progress: false

jobs:
  release:
    runs-on: ubuntu-latest
    outputs:
      new_tag: ${{ steps.tag_version.outputs.new_tag }}
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Determine pre-release suffix
        id: prerelease
        run: |
          BRANCH="${GITHUB_REF_NAME}"
          case "$BRANCH" in
            dev)     SUFFIX="dev" ;;
            uat)     SUFFIX="uat" ;;
            main)    SUFFIX=""    ;;
            *)       SUFFIX="$BRANCH" ;;
          esac
          echo "suffix=$SUFFIX" >> "$GITHUB_OUTPUT"
          echo "branch=$BRANCH" >> "$GITHUB_OUTPUT"

      - name: Determine version bump type from PR label
        id: bump_type
        if: github.ref_name == 'main'
        uses: actions/github-script@v7
        with:
          script: |
            // Find the merge commit's PR and check for version labels
            const prs = await github.rest.repos.listPullRequestsAssociatedWithCommit({
              owner: context.repo.owner,
              repo: context.repo.repo,
              commit_sha: context.sha
            });
            const labels = prs.data[0]?.labels?.map(l => l.name) || [];
            if (labels.includes('major')) core.setOutput('type', 'major');
            else if (labels.includes('minor')) core.setOutput('type', 'minor');
            else core.setOutput('type', 'patch'); // default fallback

      - name: Bump version and push tag
        id: tag_version
        uses: mathieudutour/github-tag-action@v6.2
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          pre_release_suffix: ${{ steps.prerelease.outputs.suffix }}
          tag_prefix: v
          default_bump: ${{ steps.bump_type.outputs.type || 'patch' }}

      - name: Create a GitHub release
        if: steps.tag_version.outputs.new_tag != ''
        uses: ncipollo/release-action@v1.21.0
        with:
          tag: ${{ steps.tag_version.outputs.new_tag }}
          name: ${{ steps.tag_version.outputs.new_tag }}
          body: ${{ steps.tag_version.outputs.changelog }}
          prerelease: ${{ steps.prerelease.outputs.suffix != '' }}
          makeLatest: ${{ steps.prerelease.outputs.suffix == '' }}
```

### 2. `enforce-dev-to-uat.yml` (branch enforcement)

```yaml
name: Enforce dev-to-uat only
on:
  pull_request:
    branches: [uat]
    types: [opened, synchronize, reopened, edited]
permissions:
  contents: read
  pull-requests: read
jobs:
  check-source-branch:
    runs-on: ubuntu-latest
    steps:
      - name: Verify PR source branch is dev
        run: |
          if [[ "${{ github.head_ref }}" != "dev" ]]; then
            echo "::error::Only PRs from 'dev' branch are allowed to merge into 'uat'."
            echo "::error::Source branch was: '${{ github.head_ref }}'"
            exit 1
          fi
          echo "::notice::PR is from 'dev' → 'uat'. Approved."
```

### 3. `enforce-uat-to-main.yml` (branch enforcement)

```yaml
name: Enforce uat-to-main only
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened, edited]
permissions:
  contents: read
  pull-requests: read
jobs:
  check-source-branch:
    runs-on: ubuntu-latest
    steps:
      - name: Verify PR source branch is uat
        run: |
          if [[ "${{ github.head_ref }}" != "uat" ]]; then
            echo "::error::Only PRs from 'uat' branch are allowed to merge into 'main'."
            echo "::error::Source branch was: '${{ github.head_ref }}'"
            exit 1
          fi
          echo "::notice::PR is from 'uat' → 'main'. Approved."
```

## Branch Protection Setup

### dev branch
- No special protection (direct pushes allowed for fast iteration)

### uat branch
```bash
gh api repos/<org>/<repo>/branches/uat/protection --method PUT --input - << 'EOF'
{
  "required_status_checks": { "strict": true, "contexts": ["check-source-branch"] },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

### main branch
```bash
gh api repos/<org>/<repo>/branches/main/protection --method PUT --input - << 'EOF'
{
  "required_status_checks": { "strict": true, "contexts": ["check-source-branch"] },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

## Required GitHub Labels

Every repo must have these labels for version bumping:

```bash
gh label create patch --color "0e8a16" --description "Version bump: patch (bug fixes, config changes)" --repo <org>/<repo> || true
gh label create minor --color "fbca04" --description "Version bump: minor (new features, additive changes)" --repo <org>/<repo> || true
gh label create major --color "d73a4a" --description "Version bump: major (breaking changes)" --repo <org>/<repo> || true
```

## Onboarding Checklist for a New Repo

1. [ ] Create `dev` branch from `main`
2. [ ] Create `uat` branch from `dev`
3. [ ] Add `bump-version-and-push-tag.yml` workflow
4. [ ] Add `enforce-dev-to-uat.yml` workflow
5. [ ] Add `enforce-uat-to-main.yml` workflow
6. [ ] Create labels: `patch`, `minor`, `major`
7. [ ] Set branch protection on `uat` (PR required, enforcement check, 1 review)
8. [ ] Set branch protection on `main` (PR required, enforcement check, 1 review)
9. [ ] Test: push to dev → verify `vX.Y.Z-dev.1` tag created
10. [ ] Test: PR dev → uat → merge → verify `vX.Y.Z-uat.1` tag created
11. [ ] Test: PR uat → main (label: patch) → merge → verify `vX.Y.Z` tag + GitHub Release created

## Audit Checklist for Existing Repos

1. [ ] Does `bump-version-and-push-tag.yml` exist?
2. [ ] Does it trigger on `dev`, `uat`, `main`?
3. [ ] Does it create pre-release tags for dev/uat and clean tags for main?
4. [ ] Does it read PR labels for version bump on main?
5. [ ] Does `enforce-dev-to-uat.yml` exist?
6. [ ] Does `enforce-uat-to-main.yml` exist?
7. [ ] Is branch protection set on `uat`?
8. [ ] Is branch protection set on `main`?
9. [ ] Are `patch`/`minor`/`major` labels created?
10. [ ] Are audit bundles attached to main releases?

## Templates & Scripts

This skill ships reusable assets in `templates/` and `scripts/` directories:

### Workflow Templates (`templates/`)

| File | Purpose |
|------|---------|
| `templates/bump-version-and-push-tag.yml` | Release workflow — triggers on dev/uat/main, creates versioned tags and GitHub releases |
| `templates/enforce-dev-to-uat.yml` | Branch enforcement — only allows PRs from `dev` into `uat` |
| `templates/enforce-uat-to-main.yml` | Branch enforcement — only allows PRs from `uat` into `main` |

**Usage**: Copy these files into `.github/workflows/` in your target repository.

### Helper Scripts (`scripts/`)

| Script | Purpose |
|--------|---------|
| `scripts/onboard-repo.sh` | Onboarding runner — sets up branches, labels, and branch protection for a new repo |
| `scripts/audit-repo.sh` | Read-only audit — checks a repo for standard compliance (prints pass/fail report) |
| `scripts/setup-branch-protection.sh` | Sets branch protection rules on `uat` and `main` via `gh api` |
| `scripts/create-labels.sh` | Creates `patch`/`minor`/`major` labels with governance-standard colors |

**Usage**:
```bash
# Onboard a new repo
scripts/onboard-repo.sh <org>/<repo>

# Audit an existing repo
scripts/audit-repo.sh <org>/<repo>

# Create labels only
scripts/create-labels.sh <org>/<repo>

# Set branch protection only
scripts/setup-branch-protection.sh <org>/<repo>
```

All scripts accept `--help` for usage details.

## Governance

This skill is governed by **`semantic-release-convention-skill`** — the single source of truth for commit-to-release conventions. The label colors, version tag formats, and PR-label-driven bumping rules defined here implement the conventions established by that governance skill.

| Convention | Source |
|------------|--------|
| Label colors (`patch=#0e8a16`, `minor=#fbca04`, `major=#d73a4a`) | `semantic-release-convention-skill` |
| Semver label requirement (exactly one per PR) | `semantic-release-convention-skill` |
| Branch-aware tag formats (`vX.Y.Z-dev.N`, `vX.Y.Z-uat.N`, `vX.Y.Z`) | `semantic-release-convention-skill` |
| Commit message fallback for version bump | `git-semantic-commits-skill` |
