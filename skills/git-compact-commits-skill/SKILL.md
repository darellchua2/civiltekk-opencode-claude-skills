---
name: git-compact-commits-skill
description: "Concise commits within strict budgets — 72-char subject, 150-word body, semantic grouping. Triggers: compact commit, concise commit, terse commit."
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

## What I Do

Enforce commit-length budgets, semantic grouping, and compact writing. **This skill is the authority** for length budgets, grouping strategy, and commitlint enforcement; `git-semantic-commits-skill` owns types/scopes/breaking-change format; `semantic-release-convention` owns the release pipeline.

## When to Use Me

Commits running long; squashing a branch into one message; "concise commit", "terse commit"; tightening commitlint rules.

## Two use cases (both apply in a squash-merge workflow)

1. **Branch commits (pre-squash)** — keep `git log` readable during review; subject + 1-2 line body + `Refs:` footer.
2. **Squash-merge output** — the permanent record: subject + body (what+why, not per-commit narration) + `BREAKING CHANGE:` footer if any + `Closes <ticket>`.

## Length budgets (hard limits)

| Part | Ideal | Hard limit |
|------|-------|-----------|
| Subject | 50 chars | **72 chars** (GitHub truncation) |
| Body | ≤100 words | **150 words** |
| Body/footer line | 72 chars | 72 chars |
| Whole message | ≤200 words | 250 words |

Check: `echo "$SUBJ" | wc -c` ≤ 72; body `sed '1,/^$/d' | wc -w` ≤ 150.

## Semantic grouping (Section 1 condensed)

Group changes by **semantic concern**, not by file or chronological order: one commit = one reviewer-legible concern (schema change + its consumers can be one; schema change + unrelated UI fix never). Order within a branch: migrations/models first, then logic, then tests, then docs. **Anti-patterns:** mega-commits mixing concerns; splitting a single concern across commits (unreviewable); grouping by file type ("all .test.ts files"); empty-body subjects for non-trivial changes.

## Compact writing techniques (Section 3 condensed)

Active voice, imperative mood ("add", not "added"/"adds") · scopes absorb context (`feat(auth):` beats a subject repeating "the auth module") · omit HOW — what + why only · bullets not paragraphs for multi-item bodies · consolidate similar items ("update 6 test fixtures" not six lines) · standard abbreviations (config, auth, impl, refactor) — never invented ones · drop articles where lossy-safe (`add retry` not `add a retry mechanism`).

## Enforcement

commitlint rules this skill mandates (beyond defaults): `subject-max-length: 72` (hard), `body-max-line-length: 72`, `footer-max-line-length: 72`, and a body-word budget via `body-max-body-length`-style custom rule or CI check (`sed '1,/^$/d' | wc -w` gate). Project `.commitlintrc` may tighten (e.g. 100-word bodies); never loosen past the hard limits above without a recorded decision.
