# Fix-round PLAN sync stopped at the AC block — Technical Notes and gate trace left stale

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Added**: 2026-09-20 (#448 re-review, fix round 1)

## Problem

When a review/Mode-R fix round changes shipped behavior, the fixer syncs the PLAN's
Acceptance Criteria (amended AC text, ticked) but leaves the plan-body restatements
alone. In #448 the drop rule changed from "items with no usable `options` array are
dropped" to "keep with `options: []`" — the plugin header comment, code, and tests
were all updated, and the AC was amended, yet `PLANS/PLAN-448.md` Technical Notes
still taught the old drop rule verbatim, and the step-1.2 coverage list still said
"items without options dropped" while the Gate Trace ended at the pre-fix 11/11 run
with no memo for the re-gate commit.

PLAN files are the durable contract: an agent or maintainer extending the plugin
from the PLAN reimplements the superseded rule — reintroducing the exact bug the
fix round removed (silent question loss).

## Rule

A behavior-changing fix commit sweeps EVERY restatement of the changed rule in the
PLAN: Technical Notes (normative present-tense prose), step coverage enumerations,
and the Gate Trace (append a `GATE <sha>` memo for the re-run — step templates
already require it). Syncing only the AC block is incomplete. Grep the PLAN for the
old rule's key phrase before declaring the sync done; same genus as
`rule-added-example-stale`, at the contract-document level.
