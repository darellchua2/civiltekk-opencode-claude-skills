# PLAN: worktree-pipeline: CodeGraph init in worktree at Step 4

**Branch**: feat/416
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/416
**Base**: main

## Acceptance Criteria

- [ ] After `git worktree add` in Step 4, iff the main checkout has `.codegraph/`, run `codegraph init -i` inside the new worktree, before Step 5 re-validation
- [ ] `codegraph` CLI absent or init fails → soft-skip with a one-line note, pipeline continues on grep fallback (mirrors `opencode-repo-setup-skill` soft-skip policy)
- [ ] Main repo without `.codegraph/` → no init attempt, no note noise
- [ ] Frontmatter untouched → no `build-registry.mjs` rerun needed, no count syncs (no skill/agent/MCP change per the AGENTS.md sync-rules table)
- [ ] `.codegraph/` not ignored on the ticket branch → skip init entirely with the one-line note (guard via `git check-ignore`; never write ignore entries) ← from Step 7 review, resolved via Mode R relay

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Use `codegraph_callers` (code) or `tofu graph` + grep (IaC)._

Evidence: `rg -l "worktree-pipeline"` over the worktree — 25 files reference the skill (initial count 17; delta: 5 PLANS, CHANGELOG, LEARNINGS, `registry.json`, `opencode_app/opencode.json`); all key on its **name/description/trigger phrases** (unchanged by a body edit) or restate its step contract (Step 10 interplay with pr-workflow-subagent — unchanged by a new init sub-step). Classification holds for every hit. Verified: `.codegraph/` is committed to `.gitignore` (line 29) in this repo; `package.json` has no `scripts`; CI = `.github/workflows/release.yml` running bats tests on PRs to main (includes `test_count_drift.bats`, `test_mcp_count_consistency.bats`, `skill_profiles.bats`).

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/worktree-pipeline-skill/SKILL.md` (body: Step 4 + Guarantees) | — | OpenCode skill loader (frontmatter+triggers — unchanged); `installer/registry.json` (frontmatter-derived — unchanged); `deploy/skill-profiles.json`, `README.md` (name/description — unchanged); cross-referencing skills/agents (`pr-workflow-subagent`, `plan-automation-loop-skill`, `ticket-creation-skill`, `wayfinder-skill`, `grilling*`, `jira-status-updater-skill`, `discovery/requirements/technical-design` agents — name/contract refs, unchanged); future pipeline runs in codegraph-enabled repos (new init sub-step — intended behavior change) | low |

Cross-module nodes exist (registry/README/deploy refs), so architecture review is selected at pipeline Step 7; uiux skipped (no frontend signal).

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Step 4 conditional init

- [x] **1.1** Add the conditional CodeGraph init block to Step 4 in `skills/worktree-pipeline-skill/SKILL.md`, immediately after the `git worktree add` sentence: iff `<main-repo>/.codegraph` exists, first run `git -C <worktree> check-ignore -q .codegraph/` — exit 0 (ignored on the ticket branch) → run `npx @colbymchenry/codegraph init -i` **inside the new worktree** (before Step 5); exit 1 → skip init entirely with the one-line note (".codegraph/ not ignored in target repo — skipping init to keep commits clean") and continue on the rg/grep fallback (stated outright — §6c names grep only as the IaC path); CLI absent or init failure → one-line soft-skip note and continue on rg/grep; no `.codegraph/` in the main checkout → skip silently; never write ignore entries (tracked `.gitignore` edits stage into per-phase commits; per-worktree `info/exclude` is not honored by linked worktrees — verified on git 2.43.0); explicitly forbid symlinking the main checkout's `.codegraph/` into the worktree (index reflects the main checkout's branch/paths; sharing undocumented).
    — **Why:** Worktrees are created outside the main repo tree, where codegraph's nearest-`.codegraph/`-above resolution cannot see the main checkout's index, so §6c's preferred `codegraph_callers` path is dead on arrival without per-worktree init; the ticket's acceptance criteria (conditional init, soft-skip, silent skip, no symlink) plus the Step 7 review's ignore-hygiene gap (Mode R verdict: guard by conditional skip, not ignore-file writes) all land in this one edit point.
    — **Done when:** SKILL.md Step 4 contains the conditional init, the check-ignore guard, the rg/grep fallback stated outright, the soft-skip note rule, the silent-skip rule, the never-write-ignores rule, and the no-symlink caution, verified by grep in Phase 3.
    — **Consumers affected:** Future pipeline runs in codegraph-enabled repos gain a 5–60s init sub-step (soft-skip on failure or unignored index); all file-level consumers keyed on name/description are untouched.
    — **Done:** Step 4 now carries the full conditional init block (probe → guard → init/note paths → silent skip → never-write-ignores → no-symlink); files: skills/worktree-pipeline-skill/SKILL.md; fixes: none

### Phase 2: Guarantees line

- [x] **2.1** Append one line to the Guarantees section of `skills/worktree-pipeline-skill/SKILL.md`: each worktree gets a CodeGraph index when the main checkout has one, soft-skipped on failure.
    — **Why:** Guarantees is the contract summary downstream readers (pr-workflow contract reviewers, pipeline operators) rely on; omitting the new behavior there would leave the summary out of sync with Step 4.
    — **Done when:** The Guarantees section contains the new line and no other line changed.
    — **Consumers affected:** Same as 1.1 — documentation-only.
    — **Done:** Guarantees gained the CodeGraph-index bullet (present/absent/unignored/CLI-fail cases); files: skills/worktree-pipeline-skill/SKILL.md; fixes: none

### Phase 3: Verification gate

- [x] **3.1** Assert scope discipline: `git diff` shows changes only in `skills/worktree-pipeline-skill/SKILL.md` and no frontmatter lines (`---`-delimited block at file top); grep asserts the Phase 1 "Done when" markers are present.
    — **Why:** Acceptance criterion 4 requires frontmatter to be untouched (count syncs and registry rebuild hinge on it); asserting it in the gate prevents silent drift.
    — **Done when:** Diff scope assertion and all grep assertions exit 0.
    — **Consumers affected:** `installer/registry.json`, `deploy/skill-profiles.json`, `README.md` — proven unchanged.
    — **Done:** Diff vs origin/main = exactly SKILL.md + PLAN-416.md + the LEARNINGS file; frontmatter byte-identical; 7/7 content markers present; files: none changed by this step (assertion only); fixes: none
- [x] **3.2** Run the CI-equivalent checks: `node installer/build-registry.mjs --check` must exit 0 (plain runs rewrite `registry.json` with a fresh `generatedAt` timestamp — `--check` is the drift guard, per the `docs-registry-is-build-site-artifact` learning); run the bats suite (`tests/`, vendored `tests/lib/bats-core` if present, system bats otherwise) — at minimum `test_count_drift.bats`, `test_mcp_count_consistency.bats`, `skill_profiles.bats`; run the full suite if the runner is available.
    — **Why:** These are the exact PR-gate checks in `.github/workflows/release.yml`; the change must be proven green locally before the Step 10 CI gate. The `--check` flag matters: a plain registry run always churns `generatedAt`, making a literal "zero diff" gate impossible and risking timestamp churn in the PR.
    — **Done when:** `build-registry.mjs --check` exits 0 and the selected bats tests exit 0.
    — **Consumers affected:** CI (release.yml) — confidence that the PR gate passes on first run.
    — **Done:** `--check` exits 0; full bats suite (system bats) 340 ok / 0 failed — exceeds the three-file minimum; files: none changed by this step (verification only); fixes: none

## Technical Notes

- Init command provenance: `opencode-repo-setup-skill` §CodeGraph setup reference (`npx @colbymchenry/codegraph init -i`, 5–60s, index gitignored).
- `.codegraph/` is already committed to this repo's `.gitignore` (line 29) — init in the worktree leaves `git status` clean.
- Keep the house query-discipline rule intact: main session uses lightweight codegraph lookups only; broad `codegraph_explore` goes to explore agents (`opencode-repo-setup-skill`).
- `package.json` has no `scripts`; the repo's verification surface is bats + build-registry (mirrors CI).

## Dependencies

None — single-file documentation-of-behavior change; no blocked-by tickets.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| npx cold-fetch latency or registry outage makes init slow/flaky | Soft-skip with a one-line note (AC 2) — pipeline never blocks on the index |
| Target repo does not ignore `.codegraph/` (untracked index rides into per-phase commits) | `check-ignore` guard skips init with a note — index loss limited to unignored repos, made visible by the note; never write ignore entries (Step 7 review + Mode R relay) |
| Count/consistency tests drift | Frontmatter untouched (3.1) + local bats run (3.2) before push |
| Doc drift with `opencode-repo-setup-skill` phrasing | Mirror its exact soft-skip policy wording and command reference |
