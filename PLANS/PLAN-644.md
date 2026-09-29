# PLAN: Harden Step 10b merge watcher guard against SKIPPED checks

**Branch**: feat/644
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/644
**Base**: main

## Acceptance Criteria

- [x] Step 10b states the red-verdict conclusion set (`FAILURE`/`TIMED_OUT`/`CANCELLED` + the existing pending-at-timeout rule); `SKIPPED`/`NEUTRAL` explicitly never red.
- [x] A green watch (exit 0) proceeds to merge even when the rollup contains `SKIPPED` entries.
- [x] The no-checks-reported direct-merge path and the 30-minute bound are unchanged.

## Dependency & Consumer Map

_Single-node docs-only change. Consumer check done at plan time: repo-wide grep for "merge only when green" / "pr checks" / "RED-OR-BLOCKED" / "statusCheckRollup" found no other file restating the red-verdict set (adjacent hits in `verification-loop-skill`, `civiltekk-pr-workflow-skill`, `agents/pr-workflow-subagent.md` are CI-as-merge-gate prose, not conclusion-set logic). No `statusCheckRollup` text exists anywhere yet — the misfiring guard was ad-hoc watcher prose in the #642 run, never committed._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/worktree-pipeline-skill/SKILL.md` (Step 10b block) | — | Future Step 10b merge-watchers (orchestrator reads this prose as its watch/merge guard); `installer/registry.json` `description`/`category` metadata (unchanged — no frontmatter edits) | low |

## Implementation Phases

### Phase 1: Step 10b red-verdict guard + shipped jq snippet

- [x] **1.1** Edit `skills/worktree-pipeline-skill/SKILL.md` Step 10b: state that a red verdict matches only `FAILURE`/`TIMED_OUT`/`CANCELLED` conclusions (plus the existing pending-at-timeout rule), that `SKIPPED` and `NEUTRAL` are never red, that `gh pr checks --watch` exit 0 remains the primary green signal, and ship the tested jq snippet `[.statusCheckRollup[] | select(.conclusion == "FAILURE" or .conclusion == "TIMED_OUT" or .conclusion == "CANCELLED")] | length` so implementers don't re-derive it.
    — **Why:** This is the ticket's entire fix — during #642 the ad-hoc watcher counted `SKIPPED` rollup entries as red and refused to merge a fully green PR (#643), forcing a manual squash merge; without the conclusion set every future docs-only PR misfires the same way.
    — **Done when:** `grep` on the file finds the three conclusion names, the "SKIPPED"/"NEUTRAL never red" statement, the exit-0 primary-green sentence, and the jq snippet within the 10b block; `git diff --stat` shows only this file changed.
    — **Consumers affected:** Future pipeline Step 10b watchers (behavior: SKIPPED/NEUTRAL rollups no longer block merge); no other file.
    — **Done:** red-verdict guard inserted as one hunk at SKILL.md:261-275 (15 insertions): conclusion set, SKIPPED/NEUTRAL never-red, exit-0 primary green, jq snippet in a bash fence with the nonzero/zero reading; jq proven live (SKIPPED/NEUTRAL rollup → 0, FAILURE → 1); files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **1.2** Verify the unchanged invariants: the no-checks-reported direct-merge sentence and the 30-minute `timeout 1800` bound survive the edit untouched, and no other Step 10b behavior text (merge command, `-R` flag mandate, no-local-git-mutations rule) was altered.
    — **Why:** Acceptance criterion 3 requires these paths unchanged; the guard addition must be strictly additive so existing watcher behavior for real failures and no-CI repos is preserved.
    — **Done when:** `git diff` on the file contains no deleted lines touching the "Zero configured checks" sentence or `timeout 1800`, and the full bats suite (`bats tests/*.bats`, vendored bats-core when present) passes.
    — **Consumers affected:** none (verification-only step).
    — **Done:** diff is 15 insertions / 0 deletions, single hunk inside the 10b block — "Zero configured checks", `timeout 1800`, merge command, `-R` mandate, and no-local-git-mutations text all outside the hunk, untouched; files: none (verification-only); fixes: none
- [x] **1.3** Run the verification gate at `tier=full` (repo gate: `bats tests/*.bats` via vendored bats-core; content self-check from 1.1/1.2) on the final tree, commit the edit, and push `feat/644`.
    — **Why:** The ticket exit gate is full and must be green on the exact SHA Step 10a cites in the PR body; committing and pushing the PLAN-riding edit is what makes the branch PR-ready.
    — **Done when:** The PLAN trace block carries a `GATE <short-sha> tier=full` line whose SHA matches the pushed HEAD, and `git log origin/feat/644` shows the commit.
    — **Consumers affected:** Step 10a (cites the memo line in the PR body); CI (runs the same bats suite).
    — **Done:** exit gate tier=full green on implementation SHA cc2b2f0 (pushed) — `bats tests/*.bats` exit 0, 642 ok / 0 failed (system bats; no vendored bats-core, CI parity), lint/typecheck/build n.a. (no scripts in package.json), e2e n.a.; deviation: the Gate Trace memo below names gated impl SHA cc2b2f0 while the final HEAD rides the docs-only end-of-ticket learnings commit (worktree-pipeline Step 9 sweep carve-out: "its memo names the gated implementation SHA Step 10a cites"); files: skills/worktree-pipeline-skill/SKILL.md, PLANS/PLAN-644.md; fixes: none

## Gate Trace

GATE cc2b2f0 tier=full lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a. (bats 642/642 exit 0 — ticket exit gate; docs-only change, repo has no lint/typecheck/build scripts; Step 9 review: 0 BLOCK / 0 WARN / 1 NOTE, no fix commits, no re-gate owed)

## Technical Notes

- Evidence from the misfire (PR #643, run 2026-09-29): `watch_exit=0` yet the log said `RED-OR-BLOCKED: merge not attempted` — GitHub marks not-applicable jobs `SKIPPED` in `statusCheckRollup`, so docs-only PRs always looked red to an "everything not SUCCESS/NEUTRAL is red" guard. Merged manually at `60657ed`.
- Minimal fix per the ticket's deletion bias: one guard clause + one jq snippet in existing 10b prose. No new tooling, no frontmatter/registry changes, no code.
- The jq snippet counts only red conclusions; a nonzero count = red, zero = not red, and the watch exit code stays the primary signal.

## Dependencies

None — single self-contained ticket, no `blocked-by:`.

## Risks & Mitigation

- **Drift with future GitHub conclusion values**: if GitHub adds new conclusions, the explicit allowlist-of-red keeps them non-red by default (safe direction — a missed red surfaces at the next boundary, a false red blocks merges).
- **Prose ambiguity for watcher implementers**: mitigated by shipping the exact jq snippet in the skill text, as the ticket requires.
