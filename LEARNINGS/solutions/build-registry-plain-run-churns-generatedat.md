# build-registry plain run always rewrites generatedAt — "zero diff" done-whens must use --check

- **Category**: solution
- **Confidence**: 1.0
- **Scope**: project
- **Added**: 2026-09-19 (#416 plan review)

## Symptom

PLAN verification steps worded as "run `node installer/build-registry.mjs`;
`git diff installer/registry.json` must be empty." This done-when can never
pass literally, even when frontmatter is untouched.

## Cause

Non-check mode stamps `generatedAt: new Date().toISOString()`
(installer/build-registry.mjs:238) and writes unconditionally (:258). Only
`--check` mode compares with `generatedAt` normalized away (:246-255), so a
plain run always leaves a one-line timestamp diff.

## Solution

Word registry gates as "`node installer/build-registry.mjs --check` exits 0"
(the drift guard). Never as plain-run + empty `git diff`. Registry entries
are frontmatter-derived only (name/description/category/audience/workflow/
requiredByAgents — build-registry.mjs:27-31, frontmatterLines:58-59; no body
hash), so body-only SKILL.md edits genuinely need no rebuild. An executor
following the plain-run wording will either halt on a phantom failure or
commit timestamp churn into the PR.

## Evidence

#416 plan review: PLAN-416 step 3.2 prescribed the plain-run + zero-diff
gate; caught before implementation. Same class as #402's phantom done-when
(see `solutions/docs-registry-is-build-site-artifact.md`, which prescribes
`--check` but not the churn mechanism).

Related: `solutions/docs-registry-is-build-site-artifact.md`,
`patterns/skill-add-count-sync-blast-radius.md`.
