---
name: git-issue-labeler-skill
description: >-
  Assess GitHub issues and assign labels — GitHub defaults, priority, semver
  (major/minor/patch); auto-creates missing labels.
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

## What I do

Assess GitHub issues and assign labels via keyword + semantic analysis — auto-creating any missing label first (never fails on a missing label). PRs get exactly one semver label; issues get type + priority labels.

**Triggers**: label issue, assess labels, assign labels, semver label PR.

## Prerequisites

`gh` authenticated with write access to the repository.

## Governance

Semver label definitions follow `semantic-release-convention` (single source of truth for version-bump conventions). JIRA ticket type/priority mapping is `jira-ticket-labeler-skill`.

## Label Taxonomy

| Context | Label Set | Purpose |
|---------|-----------|---------|
| GitHub Issues | Type labels + Priority labels | Categorize and triage |
| GitHub PRs | Semver labels (`major`, `minor`, `patch`) | Version bump for release |

**Type labels** — `bug` #d73a4a · `enhancement` #a2eeef · `documentation` #0075ca · `duplicate` #cfd3d7 · `good first issue` #7057ff · `help wanted` #008672 · `invalid` #e4e669 · `question` #d876e3 · `wontfix` #ffffff

**Priority labels** — `priority: critical` #b60205 (system down, data loss, security) · `priority: high` #d93f0b (major feature broken) · `priority: medium` #fbca04 (workaround exists; default) · `priority: low` #0e8a16 (cosmetic, minor)

**Semver labels (PRs)** — `major` #d73a4a (breaking) · `minor` #fbca04 (features) · `patch` #0e8a16 (fixes/docs/refactoring)

## Steps

### Step 1: Auto-create missing labels

The `LABELS` array below is the single **machine-readable** source (colors/descriptions); the taxonomy above is the single **human-readable** source — keep both in sync.

```bash
declare -A LABELS=(
  ["bug"]="d73a4a,Something isn't working"
  ["enhancement"]="a2eeef,New feature or request"
  ["documentation"]="0075ca,Improvements or additions to documentation"
  ["duplicate"]="cfd3d7,This issue or pull request already exists"
  ["good first issue"]="7057ff,Good for newcomers"
  ["help wanted"]="008672,Extra attention is needed"
  ["invalid"]="e4e669,This doesn't seem right"
  ["question"]="d876e3,Further information is requested"
  ["wontfix"]="ffffff,This will not be worked on"
  ["priority: critical"]="b60205,System down, data loss, security vulnerability"
  ["priority: high"]="d93f0b,Major feature broken, significant user impact"
  ["priority: medium"]="fbca04,Functional issue with workaround"
  ["priority: low"]="0e8a16,Minor inconvenience, cosmetic issue"
  ["major"]="d73a4a,Breaking change (X.0.0)"
  ["minor"]="fbca04,New feature (0.X.0)"
  ["patch"]="0e8a16,Bug fix (0.0.X)"
)

existing_labels=$(gh label list --json name --jq '.[].name')

for label in "${!LABELS[@]}"; do
  if ! echo "$existing_labels" | grep -qx "$label"; then
    IFS=',' read -r color desc <<< "${LABELS[$label]}"
    gh label create "$label" --color "$color" --description "$desc" 2>/dev/null || true
  fi
done
```

> **Intended behavior (not accidental):** this step seeds the fixed 16-label taxonomy into any repo it runs in — that is the design. The fixed set is the consistent baseline across repos (`gh label list` existence check → `gh label create` for missing). Existing custom repo labels coexist untouched: no migration, no conflict handling, no per-repo taxonomy adoption.

### Step 2: Detect labels

```bash
gh issue view <issue-number> --json title,body,labels
```

> **Sync Contract**: the priority keyword lists below are mirrored in `jira-ticket-labeler-skill` — update both together.

Keywords are intent signals, not literal substring matches ("add" in "address" is not an enhancement). Content-analysis rules: analyze title AND body; check negations ("not a bug" ≠ `bug`); distinguish explicit requests from questions ("please add" vs "how to add"); comments may carry deciding context.

- **bug**: fix, error, broken, crash, fail, doesn't work, incorrect, regression
- **enhancement**: add, implement, create, new, feature, support, request
- **documentation**: document, readme, docs, guide, tutorial, manual
- **duplicate**: duplicate, same as, already exists, already reported
- **good first issue**: beginner, simple, easy, small, straightforward, newcomer
- **help wanted**: help wanted, need help, assistance, collaboration
- **invalid**: not an issue, wrong repo, user error, misunderstanding
- **question**: question, how, what, why, clarification
- **wontfix**: wontfix, out of scope, not feasible, declined
- **priority: critical**: system down, data loss, security, vulnerability, outage
- **priority: high**: blocking, unusable, major broken, regression (severity)
- **priority: medium**: default when no other priority matches
- **priority: low**: minor, cosmetic, nice to have, nit, typo

Assignment caps: exactly one priority per issue; max 3 labels (type + priority + one auxiliary).

### Step 3: Semver label (PRs only)

Structural rule on the Conventional Commit prefix of the PR title — not issue content. Governance: `semantic-release-convention`.

```bash
if [[ "$pr_title" =~ ^[^:]+\! ]]; then
  labels+=("major")
elif [[ "$pr_title" =~ ^feat ]]; then
  labels+=("minor")
else
  labels+=("patch")
fi
```

### Step 4: Assign

```bash
gh issue edit <issue-number> --add-label "<label1>,<label2>"
```

Report per issue: assigned labels + the keywords that triggered each + confidence + ambiguous-case notes.

## Edge Cases

- **`gh label create` fails (already exists)**: ignored via `|| true` by design.
- **Conflicting labels (bug + enhancement)**: decide primary intent, remove the wrong one, comment the decision.
- **Low confidence**: leave unlabeled or use `enhancement`, comment a clarification request for the author.

## Verification Commands

```bash
gh issue view <issue-number> --jq '.labels[].name'
label_count=$(gh issue view <issue-number> --jq '.labels | length'); echo "Issue has $label_count label(s)"
for label in $(gh issue view <issue-number> --jq '.labels[].name'); do
  if gh label list --search "$label" --jq 'any(.name == "'"$label"'")' | grep -q "true"; then
    echo "OK Label '$label' exists"
  else
    echo "MISSING Label '$label' does not exist"
  fi
done
```

## Compose, don't duplicate

Bulk runs: loop Steps 1-4 over `gh issue list --state open --jq '.[].number'` filtered to zero-label issues. JIRA classification: `jira-ticket-labeler-skill`. Ticket creation: `ticket-creation-skill`.

> **Removal note (2026-09-19, #409 trim per LEARNINGS #383 recipe):** dropped per-keyword example lines (26), the Best Practices prose section, expanded Common Issues narratives, the Step 5 report template, and the 42-line Automation Example loop (composition is now a pointer). Kept verbatim: frontmatter, LABELS array, taxonomy data, sync contracts, semver structural code, verification commands.
