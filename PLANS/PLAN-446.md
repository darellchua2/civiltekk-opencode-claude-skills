# PLAN: #446 — flag long-lived PRs whose base has drifted into conflict

**Branch**: feat/446
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/446
**Base**: main @ 75868d57

## Acceptance Criteria
- [x] Open PRs with `mergeStateStatus` CONFLICTING/DIRTY get a visible flag (option a: scheduled workflow, daily) — label `conflicted` + one comment with the update-branch hint
- [x] The mechanism never fails on transient `mergeable: UNKNOWN`
- [x] No new required status checks
- [x] `build-registry --check` PASS; full bats green

## Grilled decisions
Option (a) scheduled workflow over (b) pipeline-doc check — self-enforcing, covers PRs nobody pipelines. Defaults: daily cron, new `conflicted` label, comment-once via marker, unlabel on resolution (self-healing).

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `.github/scripts/pr-conflict-labeler.sh` | — | the workflow job; local dry-runs | low (standalone, DRY_RUN mode) |
| `.github/workflows/pr-conflict-labeler.yml` | 1.1 | GitHub Actions scheduler | low (no required checks added) |
| `tests/test_pr_conflict_labeler.bats` | 1.1/1.2 | CI guard | low |

## Implementation Phases

### Phase 1: labeler script + workflow
- [x] **1.1** Author `.github/scripts/pr-conflict-labeler.sh`: create `conflicted` label if missing; classify open PRs by `mergeStateStatus` (DIRTY/CONFLICTING → label-if-absent + comment-once via `<!-- pr-conflict-labeler -->` marker; UNKNOWN → skip; anything else → remove stale `conflicted` label); `DRY_RUN=1` prints planned actions without mutating
    — **Why:** the ticket's enforcement core; script-as-file keeps it locally dry-run-able before it ever runs scheduled
    — **Done when:** `bash -n` clean; `DRY_RUN=1` against the live repo prints the correct plan (current UNKNOWN PRs skipped, nothing mutated)
    — **Consumers affected:** the workflow job only
    — **Done:** script authored + live dry-run clean (label-create planned, UNKNOWN PRs skipped, zero mutations); fixes: review round 1 — marker-count now streams --paginate bodies + grep -cF (page-1-only trap, LEARNINGS #361); resolved branch deletes stale marker comments so re-conflicts get a fresh hint (grilled gap answer); --limit ceiling + draft-PR descope documented
- [x] **1.2** Author `.github/workflows/pr-conflict-labeler.yml`: daily cron (`17 3 * * *`) + `workflow_dispatch`, `permissions: {issues: write, pull-requests: write}`, `timeout-minutes: 10`, checkout + run the script
    — **Why:** the ~24h flagging AC; workflow_dispatch enables manual verification without waiting a day
    — **Done when:** shape greps pass (cron, dispatch, both permissions, script path) — no YAML-parser dependency added
    — **Consumers affected:** repo contributors (labels/comments only; zero required checks)
    — **Done:** workflow authored (cron + dispatch + timeout + wiring); fixes: review round 1 — `contents: read` added to the permissions block (explicit block sets unlisted scopes to none; checkout 403s without it), pinned in the shape test

### Phase 2: guard tests + gates
- [x] **2.1** `tests/test_pr_conflict_labeler.bats`: script exists + `bash -n` clean; `set -euo pipefail`; UNKNOWN skip + marker + DRY_RUN strings present; workflow carries cron/dispatch/permissions/script-path
    — **Why:** mechanical enforcement of the AC invariants (UNKNOWN tolerance, comment-once)
    — **Done when:** new tests green
    — **Consumers affected:** CI
    — **Done:** 4 bats tests incl. gh-shim behavior fixture; stub-logging bug caught by the fixture itself; fixes: review round 1 — shape test pins `contents: read`; fixture extended with the chatty-PR path (marker past page 1 → labeled, not re-commented) + comments stub returns valid JSON array
- [x] **2.2** Gates: `node installer/build-registry.mjs --check` + full bats suite
    — **Why:** repo gate contract
    — **Done when:** both green
    — **Consumers affected:** CI
    — **Done:** --check PASS; full bats 357/357 (353 + 4 new); fixes: none
GATE 75868d5 lint=- typecheck=- build=- unit=t e2e=n.a.
GATE 2e86073 lint=- typecheck=- build=- unit=t e2e=n.a.
