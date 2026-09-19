# PLAN: #445 — reviewers never write LEARNINGS; entries returned as content

**Branch**: feat/445
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/445
**Base**: main @ 69ee3cc9

## Acceptance Criteria
- [x] No reviewer agent frontmatter permits `edit` on `LEARNINGS/**` — guard test enforces (both quote shapes)
- [x] `code-review-subagent` + `uiux-reviewer-subagent` bodies carry the return-as-content delivery contract
- [x] `worktree-pipeline-skill` Step 9 instructs the orchestrator to collect returned candidates and commit them in the worktree
- [x] `node installer/build-registry.mjs --check` PASS; full bats suite green

## Root cause (from the 2026-09-19 run, 2 occurrences)
`agents/code-review-subagent.md` (and `uiux-reviewer-subagent.md`) frontmatter carries
`- action: edit / resource: 'LEARNINGS/**' / effect: allow` AFTER the blanket
`edit: '*' deny`. Last-matching-rule-wins ⇒ LEARNINGS writes are licensed. The
subagent's cwd is the session checkout (base branch), so writes landed on main's
working tree — twice, dirtying the main checkout and briefly shipping a learning
file without its `_index.md` entry.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `agents/code-review-subagent.md` | — | every pipeline Step 9 review | low (permissions + one body line) |
| `agents/uiux-reviewer-subagent.md` | — | uiux reviews (Step 7/9) | low |
| `skills/worktree-pipeline-skill/SKILL.md` | 1.1 wording | every pipeline run (Step 9 orchestrator duty) | low |
| `tests/test_reviewer_no_writes.bats` | 1.1 | CI regression guard | low |
| `installer/registry.json` | any frontmatter edit | deploy tooling | generated — regen, never hand-edit |

## Implementation Phases

### Phase 1: strip the write-allow, add the return-as-content contract
- [x] **1.1** Delete the `edit`/`LEARNINGS/**` allow block from `agents/code-review-subagent.md` and `agents/uiux-reviewer-subagent.md` frontmatter (the preceding `edit: '*' deny` then covers LEARNINGS under last-rule-wins)
    — **Why:** the carve-out is the exact license for the two wrong-checkout writes observed
    — **Done when:** `grep -A1 -E "resource: ['\"]?LEARNINGS" agents/*.md` shows no `effect: allow` in either file
    — **Consumers affected:** every Step 9 review; no other agent touched (arch/language reviewers never had the carve-out)
    — **Done:** edit/LEARNINGS allow block deleted from both reviewers; blanket edit:* deny now covers it; guard test enforces both quote shapes; fixes: none
- [x] **1.2** Add the delivery contract to both reviewer bodies next to the existing LEARNINGS recall line: candidates are returned in the report (Category / File / Confidence / Scope / Summary / Date); the agent has no write access
    — **Why:** grilled decision (a) — delivery by content, never by writes
    — **Done when:** both bodies state candidates-returned-as-content; neither instructs persisting
    — **Consumers affected:** pipeline Step 7 + Step 9 review consumers
    — **Done:** return-as-content contract added (code-review: after recall line; uiux: after Patterns line); both Output lines flipped from "learning entries saved: N" to LEARNINGS candidates block; fixes: none
- [x] **1.3** `skills/worktree-pipeline-skill/SKILL.md` Step 9: add the orchestrator duty — collect reviewer-returned LEARNINGS candidates, write them into the worktree, commit with the review-fix commit
    — **Why:** closes the capture loop after write access is gone (patterns must still persist)
    — **Done when:** Step 9 text names the collect-and-commit duty explicitly
    — **Consumers affected:** all future pipeline runs
    — **Done:** Step 9 gained the collect-and-commit duty (write LEARNINGS/<category>/<slug>.md + _index.md entry, commit with review-fix commit); fixes: none
- [x] **1.4** New guard test `tests/test_reviewer_no_writes.bats`: no reviewer agent carries an `edit` allow on `LEARNINGS/**` (single- and double-quoted resource shapes)
    — **Why:** mechanical-enforcement doctrine — the regression this ticket fixes must be guard-proofed
    — **Done when:** test green on the fixed tree; grep logic covers both quote spellings (guard-regex-quote-shape-mismatch learning)
    — **Consumers affected:** CI
    — **Done:** tests/test_reviewer_no_writes.bats: 2 tests (existence + no-edit-allow), quote-shape safe; fixes: none

- [x] **1.5** `skills/reviewer-baseline-skill/SKILL.md`: flip the Mandatory Post-Review Learning Gate to the return-as-content contract (Steps 3-5 rewritten: candidate rubric qualifies report entries; Step 4 = emit `LEARNINGS candidates:` block, never write; Step 5 tally wording)
    — **Why:** the baseline gate is a BLOCKING instruction layer ordering reviewers to persist files — found during diff prep; leaving it gives reviewers contradictory orders (skill says write, permissions deny, contract says return)
    — **Done when:** no "persist/entries saved" phrasing remains in the gate; Steps 3-5 carry the candidates-block contract
    — **Consumers affected:** every reviewer loading the baseline skill (all four reviewer agents)
    — **Done:** gate Steps 3-5 rewritten to candidates-block contract; zero "persist/entries saved" phrasing left in the gate; arch-reviewer Output line flipped too; fixes: none

### Phase 2: generated artifact + gates
- [x] **2.1** `node installer/build-registry.mjs` regen; verify the diff is exactly the two edited agents' entries
    — **Why:** generated-artifact doctrine — frontmatter changed, registry must follow
    — **Done when:** regen diff limited to those entries; `--check` PASS
    — **Consumers affected:** deploy tooling
    — **Done:** registry regen churn timestamp-only (1+/1-); --check PASS; fixes: none
- [x] **2.2** Full bats suite
    — **Why:** repo gate; new test included
    — **Done when:** suite green (351 + 1 new = 352 expected)
    — **Consumers affected:** CI
    — **Done:** full bats 353/353 (351 prior + 2 new); fixes: none
GATE 69ee3cc lint=- typecheck=- build=- unit=t e2e=n.a.
GATE 4fbc712 lint=- typecheck=- build=- unit=t e2e=n.a.
