# Pattern: advance-on-ship guard must cover merged PRs

In advance-on-ship pipelines, an overlap guard keyed to *still-open* PRs
misses the stale-base class: ticket N's branch is cut before an earlier
in-run PR M merges; M merges during N's implementation window; N and M
touched the same files. At N's pre-PR check no M PR is open, so the guard
passes — and N's PR opens with merge conflicts that surface as a watcher
merge-command failure, outside both the hold path and the failing-checks
report path.

**Rule:** guard base currency too — treat "PR conflicts after an earlier
in-run merge" as an overlap-hold (rebase onto the updated base, full
re-gate, re-create the PR), not a ticket failure. Evidence: PLAN-560 step
4.2 checked only open PRs while step 1.1 advances at PR creation (#560
re-review).

- **Confidence**: 0.7
- **Scope**: project
- **Date**: 2026-09-25
