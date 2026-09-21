# Merge method is chosen by head-branch class, never a squash default

- **Category**: convention
- **Confidence**: high
- **Scope**: project
- **Added**: 2026-09-21 (#519)

## Rule

PR merge method is classified by the **head** branch, not the base, and there
is no unconditional squash default:

- **Long-lived head** (`main`, `master`, `dev`, `develop`, `development`,
  `production`, `prod`, `uat`, `staging`, `stage`, `preprod`, `pre-dev`, `qa`,
  `test`, `integration`, `release`, `release/*`) → `gh pr merge --merge`
  (merge commit). Canonical list lives in
  `skills/pr-merge-workflow-skill/SKILL.md` Phase 1 step 3, mirrored verbatim
  in `skills/semantic-release-convention-skill/SKILL.md` §4.
- **Any other head** (feature/*, fix/*, hotfix/*, chore/*, …) → squash,
  regardless of base.
- **Override**: explicit user instruction for that specific PR, in either
  direction; forcing squash on a long-lived head requires a prior SHA-
  divergence warning. Autonomous loops (pr-merge Step 3b) never override.

## Why

The squash harm exists only when the **head branch survives the merge**:
squash re-creates the head's content as one new-SHA commit on the base, so the
same content lives under different SHAs on both branches and `git log a..b`
never empties. A feature head dies at merge — squash is safe even into `main`.
Base-class rules misfire twice: they forbid squash on ordinary feature→main
PRs in trunk-based repos, and they miss promotion shapes.

## Evidence

nus-cee/betekk-keycloak dev→uat promotion PRs #55 and #72 (2026-09-21) were
squash-merged: `compare/dev...uat` showed uat 9 commits ahead of dev with ~5
orphan artifacts; history shows the workarounds (surgical promotion
PLAN-DA-2457, reconciliation PR #69, promotion train PR #72/#76).

Related: `anti-patterns/exact-match-branch-taxonomy-fallthrough.md`.
