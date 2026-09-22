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

Recurrence 3 (#482, 2026-09-20): PLAN-482 step 3.4 drafted plain-run +
empty `git diff` again; caught by architecture review. PLAN authors: any
registry step defaults to the `--check exits 0` form — do not re-derive
this gate from first principles.

Recurrence 4 (#519, 2026-09-21): PLAN-519 step 2.1 prescribed plain run +
"commit only if changed" + `git status --porcelain registry.json` — both the
churn and a new variant: the pathspec named `registry.json` (root) while the
artifact lives at `installer/registry.json` (`OUT_FILE`,
installer/build-registry.mjs:45), so the porcelain check matched nothing and
exited 0 — a false-green on top of the phantom-failure mode. Caught by
architecture review; rewritten to `--check` exits 0.

Recurrence 5 (#524, 2026-09-22): PLAN-524 step 3.2 drafted plain-run +
"registry.json diff reflects both agent edits" — a second unsatisfiable
variant: scoped shell rules and body prose feed no registry edges
(build-registry.mjs:180-182, :236-242), so even a content-diff expectation
can never pass. Caught by architecture review; rewritten to the `--check`
form with a `generatedAt`-only expectation.

Related: `solutions/docs-registry-is-build-site-artifact.md`,
`patterns/skill-add-count-sync-blast-radius.md`.

Recurrence 5 (#514 plan review): PLAN-514 step 4.1 drafted "second run → zero
diff" again — caught before execution. PLAN templates should hard-code
"`--check` exits 0", never "plain run → zero diff".
