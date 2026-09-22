# PLAN: Promote-with-backmerge flow for branch promotions

**Branch**: feat/532
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/532
**Base**: main

## Acceptance Criteria
- [x] "promote dev to uat" triggers the flow; uat-only commits produce a merged backmerge PR before the promote PR
- [x] Neither side ahead → "nothing to promote" report, stop
- [x] Backmerge conflict or review block → report and stop; `--admin` never used
- [x] `required_linear_history` removed from the protection payload (key retained, value flipped to `false`; script + both SKILL.md blocks), re-run note added for onboarded repos
- [x] Step 10 pins `--squash` for short-lived heads
- [x] Triggers added to `pr-merge-workflow-skill` description (`promote X to Y`, `backmerge`); `registry.json` rebuilt via `build-registry.mjs`
- [x] `test_skill_isolation.bats`, `test_autoresearch_protocol.bats`, `test_default_behavior.bats` stay green

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. `installer/build-registry.mjs` is included as the producer node of the generated artifact._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/build-registry.mjs` (producer node — unchanged) | — | `installer/registry.json` regeneration | — |
| `skills/version-bump-standard-skill/scripts/setup-branch-protection.sh` | — | repo onboarding flow (version-bump-standard-skill users); uat/main branch protection on onboarded repos | medium |
| `skills/version-bump-standard-skill/SKILL.md` | 1.1 (doc payload must match the flipped script payload) | agents following the skill's setup steps | low |
| `skills/pr-merge-workflow-skill/SKILL.md` | 1.1 (promotion merge commits must be legal under protection) | agents triggering on "pr merge to [branch]" and the new "promote X to Y"; `semantic-release-convention-skill` §two-tier merge cites this rule | medium |
| `skills/worktree-pipeline-skill/SKILL.md` | 1.1 (the flip removes the accidental guard that rejected `--merge` on feat PRs — the pin exists because of it) | `/run-worktree-pipeline` runs (Step 10 merge decision) | low |
| `installer/registry.json` (generated) | producer `installer/build-registry.mjs`; input: `pr-merge-workflow-skill` description frontmatter | the `npx ... add` installer (`installer/init.mjs`, bin `opencode-skill` — reads registry.json) | low |

Cross-module edges exist (generated registry; script↔doc payload sync) → architecture review selected at Step 7. No frontend signal → uiux not selected.

## Implementation Phases

### Phase 1: Linear-history blocker fix (version-bump-standard-skill)
- [x] **1.1** Flip `"required_linear_history": true` → `false` in `skills/version-bump-standard-skill/scripts/setup-branch-protection.sh` (payload line 57) and update the header docstring (line 15 "Linear history enforced") to state merge commits are allowed for promotion merges.
    — **Why:** GitHub rejects merge commits on linear-history branches; promotions (dev→uat, uat→main) require merge commits per `pr-merge-workflow-skill` Phase 1 and `semantic-release-convention-skill` §Promotion Merge Commits — the current setting makes every promotion PR unmergeable on onboarded repos.
    — **Done when:** `grep -c '"required_linear_history": true' skills/version-bump-standard-skill/scripts/setup-branch-protection.sh` returns 0, the payload line reads `"required_linear_history": false`, the docstring no longer says "Linear history enforced", and `bash -n` on the script passes.
    — **Consumers affected:** future onboardings of uat/main protection; existing onboarded repos need the idempotent script re-run (covered by 1.2's note).
    — **Done:** payload flipped to `false` (script:58), docstring rewritten to "Merge commits allowed (required_linear_history: false …)" (script:15-16); grep count 0, "Linear history enforced" 0 matches, `bash -n` OK; files: setup-branch-protection.sh; fixes: none
- [x] **1.2** Mirror the flip in `skills/version-bump-standard-skill/SKILL.md` (both protection payload blocks, lines 234 and 253) and add a note that already-onboarded repos must re-run the idempotent `setup-branch-protection.sh` to pick up the change.
    — **Why:** the SKILL.md payloads are the documented source agents copy; leaving `true` there recreates the blocker wherever the doc (not the script) is followed, and existing repos will not self-heal without the re-run note.
    — **Done when:** `grep -c '"required_linear_history": true' skills/version-bump-standard-skill/SKILL.md` returns 0; both blocks read `false`; a re-run note is present in the branch-protection section.
    — **Consumers affected:** agents and humans following the SKILL.md setup path.
    — **Done:** both payload blocks flipped (SKILL.md:234, 259), re-run + rationale note added after the uat block (SKILL.md:241-245); grep count 0; files: version-bump-standard-skill/SKILL.md; fixes: none

### Phase 2: Promotion pre-flight (pr-merge-workflow-skill)
- [x] **2.1** Extend the `description` frontmatter of `skills/pr-merge-workflow-skill/SKILL.md` with the new trigger phrases: "promote <branch> to <branch>", "promote to uat", "backmerge <target> into <source>", keeping the existing "Not 'create pr'" boundary.
    — **Why:** trigger discovery is how agents route "promote dev to uat" to this skill; the registry embeds this description, so the edit must precede the 4.1 regeneration.
    — **Done when:** the description block contains the promote and backmerge triggers, retains "Not 'create pr'", and stays within the 1024-char frontmatter limit.
    — **Consumers affected:** `installer/registry.json` (regenerated in 4.1); agent skill selection.
    — **Done:** description rewritten — pre-flight summary + 6 trigger phrases + "Not 'create pr'" retained; 379 chars ≤1024; files: pr-merge-workflow-skill/SKILL.md (frontmatter only); fixes: none
- [x] **2.2** Insert "## Phase 0: Promotion Pre-flight" between the Prerequisites section and "## Phase 1: Merge the PR": divergence check via `gh api repos/{owner}/{repo}/compare/{source}...{target}` (ahead_by/behind_by, one call, no local checkout); when the target holds commits the source lacks → create+merge the backmerge PR target→source first (`chore(backmerge): <target> → <source>`, merge-commit method `--merge --delete-branch=false`, then the Phase 2 CI watch) before the promotion PR (`chore(promote): <source> → <target>` per `semantic-release-convention-skill`); full-auto when the user requested a promotion and no PR exists, confirm-once when merging a specific open PR (a backmerge mutates that PR's head branch and re-triggers its CI); edge cases — neither side ahead → "nothing to promote" report and stop; source-ahead-only → straight to Phase 1; backmerge conflicts → report and stop; review-blocked → merge when mergeable, otherwise stop and report; `--admin` never used; Phase 0 runs only when head AND base are both long-lived lanes per the existing Phase 1 classifier list.
    — **Why:** this is the ticket's core feature — the backmerge-then-promote sequencing no skill currently orchestrates; keying on the long-lived-head classifier keeps `feat/*` pipeline PRs (worktree-pipeline-skill Step 10) unaffected.
    — **Done when:** the SKILL.md contains the Phase 0 section with the compare API call, backmerge steps, both modes, all four edge-case rules, and the long-lived-lane scope note; existing Phase 1–4 text, "Iteration Protocol (opt-in)", the imperative gating preamble, and the citations are byte-identical (`git diff` shows additions only in that region); the new section must not reuse the preamble string "DO NOT execute any of the following unless" nor evaluator tokens (`results.tsv`, `Iterations:`) — each is asserted exactly-once / section-scoped by `tests/test_default_behavior.bats`.
    — **Consumers affected:** agents handling "pr merge to [branch]" on long-lived→long-lived merges; pipeline Step 10 untouched (feat heads never enter Phase 0).
    — **Done:** Phase 0 inserted (SKILL.md:28-56) — divergence check, backmerge steps, two modes, scope note; diff additions-only in body (2 deletions = old description lines from 2.1); preamble string count 1; no evaluator tokens added; bats test_default_behavior + test_autoresearch_protocol green (169 ok / 0 failed); files: pr-merge-workflow-skill/SKILL.md; fixes: none

### Phase 3: Worktree pipeline squash pin (worktree-pipeline-skill)
- [x] **3.1** Amend the Step 10 CI-gate sentence in `skills/worktree-pipeline-skill/SKILL.md` ("merge when green", line ~175) to pin the merge method: `gh pr merge <num> --squash` for the short-lived `feat/<KEY>` head, citing the `pr-merge-workflow-skill` head-class classifier.
    — **Why:** Phase 1's linear-history flip removes the accidental guard that rejected a wrong `--merge` on feat PRs; pinning squash prevents the SHA-divergence harm the classifier exists to stop.
    — **Done when:** Step 10 specifies `--squash` with the classifier citation and no longer leaves the merge method implicit.
    — **Consumers affected:** `/run-worktree-pipeline` Step 10 merge decision; no downstream text depends on the old wording.
    — **Done:** CI-gate sentence now pins `gh pr merge <num> --squash` with the Phase 1 classifier citation and an explicit never-`--merge` rationale (SKILL.md:175-179); affected suite test_tiered_gating.bats green (23 ok, incl. step10 tier=full citation test); files: worktree-pipeline-skill/SKILL.md; fixes: none

### Phase 4: Registry regeneration + verification gates (exit gate: full)
- [x] **4.1** Run `node installer/build-registry.mjs` from the repo root and stage the regenerated `installer/registry.json` with the phase commit.
    — **Why:** repo rule — after ANY skill frontmatter change, rebuild and commit registry.json; a regenerated-but-unstaged artifact is the known generated-artifact anti-pattern.
    — **Done when:** `git diff installer/registry.json` shows the new pr-merge description; `git status` shows no unstaged `installer/registry.json` after staging; `node installer/build-registry.mjs --check` exits 0 (mechanical drift gate).
    — **Consumers affected:** `installer/init.mjs`, the `npx ... add` installer path.
    — **Done:** registry rebuilt (agents=34, skills=146), diff shows only the pr-merge description line, `--check` → "registry OK … no drift", staged with the phase commit; files: installer/registry.json; fixes: none
- [x] **4.2** Run the full exit gate: `bash -n` on the edited script; `bats tests/test_skill_isolation.bats tests/test_autoresearch_protocol.bats tests/test_default_behavior.bats`; fix any failure before proceeding.
    — **Why:** the ticket's final AC names these three suites; the isolation guard and the pr-merge behavior tests (iteration protocol, gating preamble, citations) must stay green after the SKILL.md additions.
    — **Done when:** all three bats suites exit 0 and the `GATE <short-sha> tier=full` memo line is recorded in the PLAN trace block.
    — **Consumers affected:** CI parity; the Step 9/10 gate-memo citation chain.
    — **Done:** bash -n OK; all three suites green — 174 ok / 0 failed; memo line appended below; files: (gate only); fixes: none

## Gate Trace

GATE cc060c6 tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a
GATE 57f9981 tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a
GATE a9a3f4b tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a (post-merge re-gate)

## Progress Log

- 2026-09-22: All 4 phases complete — linear-history flip (7163a1d), Phase 0 pre-flight (671e90d), squash pin (c367d58), registry regen + full exit gate (cc060c6, 174 ok / 0 failed). Acceptance criteria ticked: content in place + gates green per step Done lines.
- 2026-09-22: Code review — 1 BLOCK (compare API ahead_by/behind_by inverted; operands swapped to {target}...{source}), 2 minors (hazard clause dropped, description word-count informational). Full gate re-run on 57f9981: 174 ok / 0 failed, bash -n OK, registry --check no drift. LEARNINGS: compare-api anti-pattern + build-registry Recurrence 6.
- 2026-09-22: origin/main advanced (#531) — registry.json conflict resolved by regeneration from merged tree (a9a3f4b); full gate re-run: 174 ok / 0 failed.

## Technical Notes
- Promotion message conventions already exist: `semantic-release-convention-skill` §Promotion Merge Commits (`chore(promote): <from> → <to> (#N)`) — Phase 0 references, not duplicates.
- The long-lived lane list is owned by `pr-merge-workflow-skill` Phase 1 (exact, case-sensitive matching; unlisted environment-shaped names → treat as long-lived or ask). Phase 0 reuses that list verbatim; no duplicated taxonomy.
- `enforce-dev-to-uat.yml` fires only on PRs targeting uat — the uat→dev backmerge PR is unaffected; `setup-branch-protection.sh` protects only uat/main, so dev-side backmerges face no required-review wall.
- A merge-time backmerge updates the promote PR's head branch (auto-synchronize) — hand-created promotion PRs self-heal; no second pre-flight site needed.

## Dependencies
- None external. No `blocked-by:` refs on #532.

## Risks & Mitigation
- Bats tests grep SKILL.md text → keep all existing sections byte-identical; additions only. Mitigation: `git diff` review per Done-when; the three named suites gate 4.2.
- Registry drift → rebuild via the canonical command only (4.1), never hand-edit registry.json.
- Protection drift on already-onboarded repos → the 1.2 re-run note; the script is idempotent by design.
