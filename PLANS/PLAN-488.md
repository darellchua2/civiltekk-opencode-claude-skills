# PLAN: Tiered verification gates — light per-phase, full at ticket exit

**Branch**: feat/488
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/488
**Base**: main

## Acceptance Criteria

_Inherited verbatim from #488 — the PLAN never rewrites ticket AC._

- [x] `verification-loop-skill` §The gate contract defines the two tiers, escalation anchors, the unsure→full rule, and the tier memo marker (canonical — other surfaces defer, no restating)
- [x] `plan-execution-skill` 4c: light gate is the per-phase default; full gate on anchor hit / judgment / ticket exit gate; escalation reasons go to the WORK LOG; no logging for the light default
- [x] `worktree-pipeline-skill`: Step 8 references tiered gating; Step 9 review-fix commits trigger one full re-gate; Step 10's green citation requires the `tier=full` GATE line
- [x] Memo-format consumers (`pr-workflow-subagent`, `pr-creation-workflow-skill`) grepped and updated or verified compatible with the tier marker
- [x] Full gate runs the full unit suite; light gate runs affected tests only
- [x] Unchanged: never-push-red, CI as only unconditional re-run, unconditional Step 9 code review
- [x] bats suite passes; changed behavior is covered by tests

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/verification-loop-skill/SKILL.md` §The gate contract | — | plan-execution-skill (4c), worktree-pipeline-skill (Steps 8–10), pr-workflow-subagent, pr-creation-workflow-skill, linting-subagent, eval-harness-skill — all defer here | high (canonical contract, 5+ consumers) |
| `skills/plan-execution-skill/SKILL.md` (4c, phase-advance invariant, memo example) | verification-loop contract (Phase 1) | every `/run-plan` invocation; worktree-pipeline Step 8 | high |
| `skills/worktree-pipeline-skill/SKILL.md` (Steps 8/9/10) | both above (Phases 1–2) | pipeline runs (orchestrator behavior) | medium |
| `agents/pr-workflow-subagent.md`, `skills/pr-creation-workflow-skill/SKILL.md` + any doc restating the memo format | memo format (Phase 1) | PR creation flow | low–medium (only if they parse/echo the memo shape) |
| `tests/test_tiered_gating.bats` (new) | the three SKILL.md edits | CI bats suite | low |

## Implementation Phases

_Every step is atomic and carries rationale. Any step missing a field is malformed (6d gate)._

### Phase 1: Canonical tiered-gate contract (verification-loop-skill)

- [x] **1.1** Add a "Tiered gating" subsection to §The gate contract defining: the light gate (scoped lint + typecheck + affected tests only), the full gate (existing LINT→TYPECHECK→BUILD→UNIT→E2E sequence with the FULL unit suite), one-directional escalation (light is the default and needs no justification; full is triggered, never justified away), the escalation anchors (dependency manifests, config/CI/deploy, entry points, schema/migrations, auth/security paths, cross-module Dependency & Consumer Map nodes), the unsure→full rule, and the ticket exit gate (last gate before PR per ticket runs full unconditionally)
    — **Why:** this file is the canonical contract every other surface defers to; the tiers must exist here before executors can reference them without restating
    — **Done when:** one findable subsection defines light/full/anchors/unsure→full/exit-gate, and no other section of the file contradicts it
    — **Consumers affected:** plan-execution-skill 4c, worktree-pipeline-skill Steps 8–10, pr-workflow-subagent, pr-creation-workflow-skill, linting-subagent, eval-harness-skill
    — **Done:** Tiered gating subsection added to §The gate contract (light/full definitions, anchors, unsure→full, exit gate, one-directional escalation); files: skills/verification-loop-skill/SKILL.md; fixes: none
- [x] **1.2** Extend §Gate memo with the tier marker format `GATE <short-sha> tier=light|full lint=t typecheck=t build=t|- unit=t|-|n.a e2e=t|-|n.a` and state the push invariant: the pushed SHA must carry a green `tier=full` memo (exit gate plus any post-gate fix re-gate); include the n.a gloss — a memo axis with no applicable check records `n.a` (e.g. `unit=n.a` on a light gate with zero affected tests); `n.a` means non-applicable, never INCONCLUSIVE; `unit=n.a` is valid only on `tier=light` memos, since the full gate always runs the full unit suite the push-authorizing `tier=full` memo can never carry it
    — **Why:** the memo line is the cross-surface evidence currency; Step 10's PR-time citation keys off it; without the n.a gloss a docs-only light phase cannot record zero affected tests
    — **Done when:** the memo format block renders the tier token, the `-`/`n.a` conventions are reused (no new syntax), the push invariant is stated in one sentence, and the gloss covers light-only `unit=n.a` plus `n.a` ≠ INCONCLUSIVE
    — **Consumers affected:** plan-execution-skill (memo writer), worktree-pipeline Step 10 (citation), pr-creation-workflow-skill (PR Quality Checks slot)
    — **Done:** memo format now carries `tier=light|full` and `unit=t|-|n.a`; n.a gloss present (light-only `unit=n.a`, `n.a` ≠ INCONCLUSIVE); push-invariant bullet added; files: skills/verification-loop-skill/SKILL.md; fixes: none
- [x] **1.3** Create `tests/test_tiered_gating.bats` with assertions pinning the Phase-1 contract tokens in verification-loop-skill (`tier=light|full` in the memo example, the light-gate definition, unsure→full, exit gate) using case-insensitive greps over the historical spellings actually written; also pin the unchanged invariant that CI remains the only unconditional re-run (§Gate memo bullet — Phase 1 edits that very section)
    — **Why:** skill prose is this repo's runtime surface; the bats suite is its regression gate — and grep gates over prose false-green on case/anchor mismatches (LEARNINGS `case-sensitive-grep-gates-false-green`, `guard-regex-quote-shape-mismatch`)
    — **Done when:** the new bats file passes standalone via `bats tests/test_tiered_gating.bats` and mutation checks: deleting the Tiered gating subsection fails ≥1 assertion, deleting the CI-only-unconditional-rerun bullet fails the invariant assertion
    — **Consumers affected:** CI bats suite
    — **Done:** 9 assertions green standalone; mutation canaries verified by running the target test alone — subsection deletion fails 5 tests, CI-bullet deletion fails 1, restore returns 9/9; files: tests/test_tiered_gating.bats; fixes: one grep was missing its file argument (caught by its own failing assertion, fixed)

### Phase 2: Executor integration (plan-execution-skill)

- [x] **2.1** Rewrite 4c VERIFY to select the gate tier per the verification-loop contract by deference: light gate is the per-phase default; full gate when an anchor is hit, the agent judges risk high, or the agent is unsure; the ticket exit gate (the last gate of this PLAN run) is full
    — **Why:** the executor runs the gates; without this rewrite every phase still runs the full sequence regardless of what it touched
    — **Done when:** 4c names the tier selection and defers anchor definitions to the contract (no restating), and no 4c text implies the full sequence runs every phase
    — **Consumers affected:** every `/run-plan --gate` invocation; worktree-pipeline-skill Step 8
    — **Done:** 4c rewritten to tier selection by deference (light default, anchors/judgment/unsure defer to contract, exit gate full, push invariant); files: skills/plan-execution-skill/SKILL.md; fixes: none
- [x] **2.2** Add the escalation logging rule to 4c/Traceability: one WORK LOG line per full-gate escalation naming the anchor or judgment reason; no logging for the light default
    — **Why:** one-directional escalation must be auditable without burying every phase in ceremony
    — **Done when:** the rule appears once, tied to the existing WORK LOG mechanism
    — **Consumers affected:** PLAN trace-block readers; worktree-pipeline Step 10 citation
    — **Done:** escalation logging sentence added to 4c, tied to the existing WORK LOG (anchor/judgment reason; nothing for light); fixes: none
- [x] **2.3** Update the phase-advance invariant to "A phase advances ONLY when its applicable gate tier is green" and the 4c memo-line example to include `tier=`
    — **Why:** stale invariant wording would contradict the tiered contract inside the same file
    — **Done when:** `grep` for the old unconditional phrasing returns nothing contradicting; memo example carries the tier token
    — **Consumers affected:** readers of the skill; existing tests pinning 4c wording (checked in 4.3)
    — **Done:** phase-advance invariant now reads "applicable gate tier is green"; 4c memo example carries tier=; fixes: none
- [x] **2.4** Extend `tests/test_tiered_gating.bats` with plan-execution assertions: light default present, exit-gate rule present, tier token in the memo example, escalation-logging rule present, and the unchanged "Never push red" rule in 4d (Phase 2 edits the surrounding text)
    — **Why:** pin executor behavior so later edits cannot silently revert to full-gate-per-phase or drop the never-push-red invariant while rewriting 4c/4d
    — **Done when:** assertions pass standalone and mutation checks (deleting the 4c tier sentence, deleting the never-push-red sentence) each fail at least one
    — **Consumers affected:** CI bats suite
    — **Done:** 5 new assertions (14 total green standalone); mutation checks: 4c deletion fails 4 tests, never-push-red deletion fails 1; fixes: none

### Phase 3: Orchestrator integration (worktree-pipeline-skill)

- [x] **3.1** Step 8: state that the executor runs tiered gates per the verification-loop contract and that the ticket exit gate is full
    — **Why:** the orchestrator owns sequencing semantics; its wording currently describes the executor gate without tiers
    — **Done when:** Step 8 defers to the contract and names the exit gate, without restating anchor lists
    — **Consumers affected:** pipeline runs; Step 10 citation chain
    — **Done:** Step 8 now defers tier selection to verification-loop §Tiered gating and names the ticket exit gate as full; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **3.2** Step 9: review-fix commits trigger exactly one full re-gate (memo line recorded for the final pushed SHA) before the fix commit is pushed
    — **Why:** closes the latent hole where review fixes land on a SHA that was never gated, weakening the Step 10 citation
    — **Done when:** Step 9 text contains the re-gate rule and ties the memo line to the pushed SHA
    — **Consumers affected:** Step 10 green assertion; PR merge decision
    — **Done:** re-gate rule added: fix commits re-run the full gate once on the fixed tree and append a tier=full memo line before push; fixes: none
- [x] **3.3** Step 10: the PR Task prompt's gate citation must reference the `tier=full` GATE line for the pushed SHA
    — **Why:** PR-time assertion strength — a tier=light line must not satisfy the pipeline's green claim
    — **Done when:** Step 10 wording requires the tier=full line
    — **Consumers affected:** pr-workflow-subagent Task prompt; PR creation flow
    — **Done:** Step 10 citation now requires the `GATE <short-sha> tier=full` line; tier=light explicitly never satisfies it; fixes: none
- [x] **3.4** Extend `tests/test_tiered_gating.bats` with worktree-pipeline assertions: exit-gate reference in Step 8, re-gate rule in Step 9, tier=full citation in Step 10, and Step 9's unconditional code-review backstop reference (Phase 3 edits Step 9 itself)
    — **Why:** pin orchestrator behavior symmetrically with the other two surfaces, including the invariant its own edits could break
    — **Done when:** assertions pass standalone; mutation checks (deleting the Step 9 re-gate sentence, deleting the unconditional-review backstop clause) each fail at least one
    — **Consumers affected:** CI bats suite
    — **Done:** 4 new assertions (18 total green); mutation checks: re-gate-sentence deletion and backstop-clause deletion each fail tests, restore green; fixes: exit-gate assertion made wrap-tolerant after the phrase wrapped across markdown lines (caught by its own failing assertion)

### Phase 4: Memo-consumer sweep + suite green

- [x] **4.1** Census every GATE-memo consumer: case-insensitive `grep -rniE 'GATE (<short-sha>|<sha>)|lint=t|tier=light|tier=full'` across `agents/ skills/ deploy/ installer/ opencode_app/ tests/ README.md AGENTS.md MIGRATION.md` and record the hit list with update/no-change classification in the WORK LOG; name the deliberate no-change exclusions up front — `PLANS/`, `LEARNINGS/`, `CHANGELOG.md` are immutable run history (historical trace memos stay tierless by design; never rewrite them on a re-run)
    — **Why:** the format change has blast radius beyond the three edited files — single-surface deltas and root-doc restatements are known miss patterns (LEARNINGS `delta-derived-from-single-surface`, `directory-scoped-rename-sweep-misses-root-docs`); unnamed exclusions invite history rewrites on a later repo-wide re-run
    — **Done when:** the census output is captured and every hit is classified; zero unclassified hits; the three exclusions are named in the census record itself
    — **Consumers affected:** pr-workflow-subagent, pr-creation-workflow-skill, any doc that teaches the memo shape
    — **Done:** census run across the declared scope: 4 hit-groups, all classified (3 edited files tiered + own tests = no-change; pr-creation-workflow-skill:25 = update); exclusions named: PLANS/ (PLAN-448/453/476/482), LEARNINGS/anti-patterns/plan-fix-round-ac-only-sync.md — immutable run history; census record in WORK LOG
- [x] **4.2** Update the classified consumers so none parse or echo the old memo shape only (e.g. pr-creation-workflow-skill PR Quality Checks slot, pr-workflow-subagent prompt, README pipeline docs if they restate the memo)
    — **Why:** a consumer expecting the tierless shape must not false-negative on `tier=full` lines or teach the stale format
    — **Done when:** re-running the census grep shows every remaining `lint=t` example carries a tier token or is explicitly format-agnostic; no consumer text contradicts tiered gating
    — **Consumers affected:** PR creation flow; documentation readers
    — **Done:** pr-creation-workflow-skill step 3 memo check now requires `GATE <sha> tier=full`, states tier=light never satisfies it; census re-run shows every in-scope example tiered or format-agnostic (ALL_TIERED_OR_AGNOSTIC)
- [x] **4.3** Run the full verification gate on the worktree (this is the ticket exit gate — tier=full) including the complete bats suite, and fix any fallout including tests pinning pre-tier wording (e.g. `tests/test_default_behavior.bats`)
    — **Why:** the change edits prompt-level contracts consumed across the estate; the exit gate is where the whole ticket state is verified once, fully
    — **Done when:** gate green end-to-end and the `GATE <short-sha> tier=full …` memo line is appended to this PLAN's trace block
    — **Consumers affected:** CI; downstream skill consumers
    — **Done:** ticket exit gate run full: bats suite 452/452 green, registry regen idempotent (timestamp-only), tiered_gating 19/19; this memo line appended below

## Technical Notes

- Robustness framing: full verification sits at boundaries (exit gate, CI, code review); cheap detection runs per phase. No check runs twice for the same risk.
- Unchanged invariants (ticket AC): never-push-red, bounded fix-on-fail, unconditional Step 9 code review, CI as the only unconditional re-run.
- The `category`/frontmatter contract is untouched — content edits only, no skill/agent additions, so no setup.sh/README count sync is triggered.
- CodeGraph: `.codegraph/` is not ignored in this repo → pipeline Step 4 soft-skipped index init in the worktree; searches use rg/grep fallback.

## Dependencies

- None (no `blocked-by:` tickets).

## Risks & Mitigation

- **Prose drift between the three files** (same contract stated three ways) → mitigated by strict deference wording + the shared bats file asserting tokens in all three.
- **Grep-gated tests false-green on case/spelling** → mitigated by case-insensitive patterns over the spellings actually written, plus mutation checks per phase (LEARNINGS `guard-regex-quote-shape-mismatch`).
- **Existing bats tests pin old wording** → caught by 4.3 exit gate; fix in the same phase.
- **Memo-format consumers missed by the sweep** → census runs case-insensitively across repo root and all config/doc dirs, not just the three edited files.

## Trace

_Per-step Done lines live inline; gate memo lines below (axes with no applicable command record n.a; tier=full per cross-module Consumer Map anchor)._


GATE 3933316 tier=full lint=n.a typecheck=n.a build=t unit=t e2e=n.a
GATE 11bdcd5 tier=full lint=n.a typecheck=n.a build=t unit=t e2e=n.a
GATE 5603d70 tier=full lint=n.a typecheck=n.a build=t unit=t e2e=n.a
GATE 63d280b tier=full lint=n.a typecheck=n.a build=t unit=t e2e=n.a
