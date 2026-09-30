# Merged tickets' PLAN edits never route through the worktree pipeline

**Date:** 2026-09-30 · **Confidence:** high · **Scope:** worktree-pipeline runs; any request to fix stale PLAN content on already-merged tickets

## Body

`worktree-pipeline-skill` Step 2's merged-ticket check (`gh pr list --state merged --head feat/<KEY>`)
skips the ticket **before** any PLAN work — Step 6 PLAN adoption never runs — so a pipeline run cannot
edit a merged ticket's PLAN (tick completed steps, relabel stale actor names). Observed with
canvastekk-workflow-engine DA-3151/DA-3152: both PRs merged (#488/#487), PLANs on `dev` still showed the
PR step unchecked with the pre-relabel actor name; a `canvastekk-workflow-engine/DA-3151` pipeline run
would have reported two skips and done nothing.

Route PLAN reconciliation on merged tickets as a **direct docs PR** against the ticket's base branch
(cut branch, edit PLAN, PR, green checks, merge) — no new ticket, no pipeline run. The pipeline remains
correct for its purpose: the skip-guard exists to avoid re-doing merged work.
