# `gh api --paginate --jq` evaluates per page — aggregations count pages

**Category:** anti-pattern · **Confidence:** 0.95 · **Scope:** project · **Date:** 2026-09-19

`gh api --paginate --jq '<aggregate>'` applies the jq template **once per response
page** and concatenates the text output — it does not aggregate across pages.
Expressions like `[.items[] | select(...)] | length` therefore emit one number
per page; command substitution captures `"2\n1"` and the downstream `[ "$n" -gt 0 ]`
fails with "integer expression expected" (silently taking the else branch).
`--slurp` (the would-be fix) is mutually exclusive with `--jq` by design.

- Evidence: cli/cli `pkg/cmd/api/api.go` calls `jq.EvaluateFormatted` inside the
  pagination loop (`TODO: reuse parsed query across pagination invocations`);
  the top-level-array stitching from PR #7190 applies only to the unfiltered
  body path. Maintainer confirmation in cli/cli#10459; cli/cli#1268; live-API
  writeup dev.to/jjoyneriv (2026-09-13).
- REST `--paginate` forces `per_page=100`, so the trap arms at >100 items
  (e.g. org runners) — works fine at pilot scale, breaks silently at growth.
- Correct idiom: stream matching items, then count lines:

```bash
n=$(gh api orgs/ORG/actions/runners --paginate \
  --jq '.runners[] | select(.labels[].name=="local") | select(.status=="online" and .busy==false) | .name' \
  | wc -l)
```

Caught in #361 review: the github-runners-setup-skill dispatcher's idle-count
used `[...]|length` under `--paginate` — validated at 4 runners (single page),
would silently fall back to `ubuntu-latest` once the org crossed 100 runners.
