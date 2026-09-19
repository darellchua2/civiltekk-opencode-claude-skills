# permission.task delegate changes — 4 sync surfaces + delegate ceiling check

- **Category**: convention
- **Confidence**: 0.9
- **Scope**: project
- **Added**: 2026-08-27 (GIT-350 review)

## Rule 1 — four surfaces must stay in sync

Adding/removing a `permission.task` allow entry on an agent touches FOUR surfaces.
A diff that updates only some of them is partially stale by construction:

1. Agent frontmatter `permission.task` — `"*": deny` first, then alphabetical.
2. `deploy/registry.json` via `node deploy/build-registry.mjs` — regen is REQUIRED
   even when the agent description is unchanged (`delegatesTo = keysOf(perm.task)`,
   build-registry.mjs:140, plus reverse `requiredBy` edge :155-159).
   `--check` is the read-only CI drift gate (returns before `writeFile`; normalizes
   `generatedAt` out of comparison).
3. `README.md` Subagents delegation row — must equal registry `delegatesTo`, sorted.
4. Agent body "…Subagent Delegation" section + closing note — prose habit docs that
   drift independently of all of the above.

## Rule 2 — check the delegate's permission ceiling before writing step wording

Read the DELEGATE's frontmatter before phrasing a delegation step. Proven GIT-350:
documentation-subagent has `bash: deny` (its frontmatter :13), so pr-workflow-subagent's
step 2.5 must state the PARENT computes `git diff --name-only <base>...HEAD`, re-runs
lint, and makes the semantic commit — the delegate only reads/edits docstrings.
A step that asks a `bash: deny` delegate to diff, lint, or commit is dead-on-arrival.

## Reviewer check

For any diff touching `permission.task`:
- `node deploy/build-registry.mjs --check` exits 0;
- registry diff is exactly the expected edges + `generatedAt`;
- README row matches registry `delegatesTo`;
- grep the agent body for the delegate list (section + closing note);
- read the delegate's own permission block before approving step wording.

## Evidence

GIT-350 (feat/GIT-350, 2026-08-27): all four surfaces updated, `--check` green.
Agent-body note deliberately deferred image-analyzer-subagent (GIT-350 §1.3),
leaving the README row (4 delegates) ahead of the note (3) — accepted partial sync.

Related: `patterns/tier-model-swap-blast-radius.md` (same multi-surface discipline
for tier→model swaps).
