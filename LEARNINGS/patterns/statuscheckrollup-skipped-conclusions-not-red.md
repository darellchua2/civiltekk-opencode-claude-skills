# Pattern: statusCheckRollup SKIPPED conclusions are not red

A merge-watcher red verdict must match only the conclusions that mean
failure — `FAILURE`, `TIMED_OUT`, `CANCELLED` — never "everything that is
not SUCCESS/NEUTRAL". GitHub marks not-applicable jobs `SKIPPED`, so
docs-only and partially-skipped PRs carry `SKIPPED` entries in
`statusCheckRollup` while being fully green; a denylist-of-green guard
reads them as red and refuses to merge a good PR.

Evidence: the #642 pipeline run's ad-hoc Step 10b guard reported
`RED-OR-BLOCKED: merge not attempted` on PR #643 with `watch_exit=0` and
all checks green (`Run bats tests: pass`, release/Pages jobs skipping) —
merged manually at `60657ed` (#644). Classification jq:

```
jq '[.statusCheckRollup[] | select(.conclusion == "FAILURE" or .conclusion == "TIMED_OUT" or .conclusion == "CANCELLED")] | length'
```

Allowlist-of-red fails safe: future unknown conclusion values default to
non-red (a missed red surfaces at the next boundary; a false red blocks
merges). `gh pr checks --watch` exit 0 stays the primary green signal —
the count only gates the red declaration, never authorizes a merge.

- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-29
