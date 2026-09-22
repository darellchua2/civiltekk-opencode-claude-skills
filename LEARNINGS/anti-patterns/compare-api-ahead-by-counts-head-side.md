# Anti-pattern: compare API ahead_by counts the HEAD side — decision tables off field names invert silently

GitHub's compare endpoint `GET /repos/{owner}/{repo}/compare/{BASE}...{HEAD}`
returns `ahead_by` = commits on the **HEAD** side and `behind_by` = commits on
the **BASE** side. Decision tables written from the field names alone, without
pinning the operand order, read backwards: with `compare/{source}...{target}`,
`ahead_by` counts target-only commits, not source-side content.

#532's Phase 0 promotion pre-flight shipped with `compare/{source}...{target}`
and `ahead_by` labeled "commits the promotion will carry" — inverted on both
counts. Consequence class: the happy-path promotion fires a spurious backmerge
(empty-diff PR that `gh pr create` rejects) while genuinely diverged targets
go undetected. The repo already held the correct direction empirically —
`LEARNINGS/conventions/merge-method-by-head-branch-class.md:37` ("`compare/dev...uat`
showed uat 9 commits ahead of dev", i.e. HEAD side) — in-repo evidence that
contradicted the new prose. Fix: swap operands to `compare/{target}...{source}`
so the existing labels and decision table become correct as written, and check
the both-zero bullet before the `behind_by == 0` bullet (else it is unreachable).

**Rule:** any doc/agent flow keyed on `ahead_by`/`behind_by` must state the
BASE/HEAD operand order explicitly and be checked against a known-divergence
example before merge. Cross-reference
`conventions/merge-method-by-head-branch-class.md`; do not duplicate it.

- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-22
