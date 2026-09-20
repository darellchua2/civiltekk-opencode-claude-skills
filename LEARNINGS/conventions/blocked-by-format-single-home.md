# `blocked-by:` format has one parser, multiple producers

- **Category**: convention
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #476

## Rule

The `blocked-by: <ref>` issue-body line has **one parser** —
`worktree-pipeline-skill` Step 1's skip-guard (whole-body scan, ticket regex
`^(#\d+|[\w.-]+/[\w.-]+#\d+|[A-Z][A-Z0-9]+-\d+)$`) — and **two producers**:
`ticket-creation-skill` (Step 4b, this convention's origin) and
`wayfinder-skill`. Producers restate the format minimally and point at the
parser's rule (`policy-single-home-pointer-shape`); they must never extend or
reinterpret it (e.g. no heading-requirement assumptions — the guard scans the
whole body). Any parser change (regex, semantics, link-traversal) must sweep
every producer in the same change.
