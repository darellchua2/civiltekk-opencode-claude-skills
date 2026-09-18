# Partial proceed-path beside a skip list

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Added**: 2026-09-18 (#399 Step 9 review)

An explicit skip list plus a partial "proceed via" enumeration in the same
instruction block leaves unnamed steps ambiguous for agent runtimes — each
unnamed step resolves arbitrarily depending on which sentence the runtime
obeys. Skip-path ∪ proceed-path must equal the full step list, or the
unnamed steps must be explicitly dispositioned.

Evidence: #399 feat/399 — pr-workflow pipeline-mode block said "skip steps
2, 2.5, and 4" then "proceed via step 1 → 5 → 6"; step 3 (coverage badges,
README-mutating) was unnamed and would have entered the PR after code
review. Caught by code-review-subagent; resolved Mode R round 2 (skip set
{2, 2.5, 3, 4}).
