# PLAN: Consolidate verification gates, sharpen skill routing, trim skill bodies

**Branch**: feat/409
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/409
**Base**: main

## Acceptance Criteria

- [ ] AC1 — `verification-loop-skill` is the single gate contract; `pr-creation-workflow`, `plan-automation-loop`, `worktree-pipeline`, `pr-workflow-subagent` defer via pointer, no restated gate tables
- [ ] AC2 — Gate memo convention (`GATE <sha> lint=t typecheck=t …`) checked before re-runs; CI stays the only unconditional re-run
- [ ] AC3 — `pr-merge-workflow` autofix commits use `style:`/`fix(lint):` prefixes
- [ ] AC4 — `nextjs-pr-workflow-skill` removed; coverage badge folded into `coverage-readme-workflow-skill`; README, setup.sh/.ps1 counts, `registry.json` synced
- [ ] AC5 — Colliding descriptions (jira-git-integration, plan-execution, verification-loop, complexity-management, git-issue-updater, test-generator-framework) carry "not for X" boundaries + trigger phrases
- [ ] AC6 — Top body offenders (git-issue-labeler, search-first, strategic-compact, eval-harness, agent-introspection-debugging, frontend-design) trimmed per LEARNINGS #383 recipe; full bats suite green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/verification-loop-skill/SKILL.md` | — | plan-automation-loop, pr-creation-workflow, worktree-pipeline, pr-workflow-subagent (new pointers) | high |
| `skills/plan-automation-loop-skill/SKILL.md` | verification-loop contract (1.1) | worktree-pipeline Step 8 | med |
| `skills/pr-creation-workflow-skill/SKILL.md` | verification-loop contract + memo format (1.1) | pr-workflow-subagent, nextjs-pr-workflow (deleted in P2) | med |
| `skills/pr-merge-workflow-skill/SKILL.md` | — | worktree-pipeline Step 10 | low |
| `skills/worktree-pipeline-skill/SKILL.md` | verification-loop contract (1.1) | user sessions (`/run-worktree-pipeline`) | low |
| `agents/pr-workflow-subagent.md` | pr-creation-workflow + verification-loop pointers (1.1) | sessions, registry.json | med |
| `agents/linting-subagent.md` | — | linting-workflow/language-linting marker sync | low |
| `skills/nextjs-pr-workflow-skill/` (delete) | badge folded (2.1); cross-refs updated (2.2-2.4) | pr-workflow-subagent, nextjs-unit-test-creator, semantic-release-convention, installer/presets/pack-frontend.json, opencode_app/opencode.json, README.md, opencode_app/README.md, tests/test_default_behavior.bats (3 tests), tests/test_autoresearch_protocol.bats (3 tests), installer/registry.json | high |
| `skills/coverage-readme-workflow-skill/SKILL.md` | — | nextjs-pr-workflow badge migration target | low |
| 6 skill descriptions (frontmatter `description:`) | — | registry.json (rebuilt), skill router | med |
| 6 skill bodies (trims) | frontmatter frozen byte-identical | quoted § pointers (LEARNINGS heading-rename rule), tests grepping literals | med |
| `skills/opencode-skill-creation-skill/SKILL.md`, `skills/opencode-skills-maintainer-skill/SKILL.md` | patterns settled (P1-P4) | future skill authors | low |
| `README.md`, `deploy/setup.sh`, `deploy/setup.ps1`, `installer/registry.json` | all skill changes (P2-P4) | test_count_drift.bats, deploy_delegate.bats, skill_profiles.bats | med |

## Implementation Phases

### Phase 1: Gate contract consolidation (AC1, AC2, AC3)

- [x] **1.1** Rewrite `skills/verification-loop-skill/SKILL.md` as the canonical gate contract: command discovery order (package.json → Makefile → pyproject → README), gate sequence lint→typecheck→build→unit→e2e, scoped-lint rule ("zero NEW errors on changed files"), INCONCLUSIVE-is-not-pass verdict protocol, and gate-memo format `GATE <short-sha> lint=t typecheck=t build=t unit=t e2e=<t/-/n.a>`.
    — **Why:** every other pipeline surface defers to this file; it must land first.
    — **Done when:** contract file contains all five elements; its own restated generic checklists removed; references eval-harness-skill for scoring; preserves test-pinned invariants: `## Iteration Protocol (opt-in)` heading, `metadata.protocol: autoresearch-opt-in`, all autoresearch-core-skill citations, `DO NOT execute…` preamble exactly once with results.tsv tokens.
    — **Consumers affected:** all nodes pointing at it (1.2-1.6).
    — **Done:** verification-loop-skill rewritten as canonical gate contract (sequence, discovery, scoped-lint, verdicts, memo, defer table); Iteration Protocol section verbatim; files: skills/verification-loop-skill/SKILL.md; fixes: none
- [x] **1.2** `plan-automation-loop-skill`: keep the phase loop and GATE discovery mechanics, replace the restated contract wording with a pointer to verification-loop-skill; add memo-write after each green gate (into the PLAN trace block).
    — **Why:** it is the per-phase gate owner; memo must be written where phases complete.
    — **Done when:** file contains no self-styled contract definition beyond the pointer; memo-write step present.
    — **Consumers affected:** worktree-pipeline Step 8 wording (1.5).
    — **Done:** gate restate replaced with contract pointer; memo-write added to 4c; compose line updated; files: skills/plan-automation-loop-skill/SKILL.md; fixes: none
- [x] **1.3** `pr-creation-workflow-skill`: replace the inline framework→command table with a pointer to the verification-loop contract; add memo check per the Memo surface definition (pre-creation read = PLAN trace block when a PLAN is in play; pipeline mode = orchestrator assertion; no memo for current SHA → run gates, never skip on absent evidence); fill the PR body's Quality Checks slot from the memo/assertion as the durable record.
    — **Why:** removes duplicated table + implements AC2 skip logic at the PR boundary.
    — **Done when:** no inline command table; memo-check step present; preserves test-pinned invariants (Iteration Protocol heading, opt-in metadata, autoresearch citations, preamble-once).
    — **Consumers affected:** pr-workflow-subagent (2.3).
    — **Done:** inline framework table replaced with gate contract + memo check per relay ruling; files: skills/pr-creation-workflow-skill/SKILL.md; fixes: none
- [x] **1.4** `pr-merge-workflow-skill`: autofix response rows commit with `style:` (format) / `fix(lint):` (lint) prefixes.
    — **Why:** resolves the style-only-commit clash with the atomic-commit rule (plan-automation-loop:70).
    — **Done when:** both rows name the commit type prefix; preserves test-pinned invariants (Iteration Protocol heading, opt-in metadata, autoresearch citations, preamble-once).
    — **Consumers affected:** none.
    — **Done:** autofix rows now commit as fix(lint)/fix(types)/fix(test)/fix(build)/style prefixes; files: skills/pr-merge-workflow-skill/SKILL.md; fixes: none
- [x] **1.5** `worktree-pipeline-skill`: line ~121 gate restate → pointer to verification-loop contract; Step 8 note that per-phase gates write the memo and Step 10 relies on CI only.
    — **Why:** orchestrator must not define gates, only sequence them.
    — **Done when:** no gate restatement; pointers present.
    — **Consumers affected:** none.
    — **Done:** step 8 gate restate to contract pointer; step 10 assertion cites final GATE memo line; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **1.6** `agents/pr-workflow-subagent.md` + `agents/linting-subagent.md` (body-only edits — no frontmatter/description changes, so no registry impact): drop own framework/command tables, defer to pr-creation-workflow-skill (PR checks) and language-linting-skill (lint execution reference); keep the pipeline-mode block (:179) coherent with the deleted framework-check sections.
    — **Why:** three lint surfaces currently allow divergent behavior; body-only keeps Phase 1 registry-clean.
    — **Done when:** agent files contain no command tables; pipeline-mode block references only surviving sections.
    — **Consumers affected:** none (description markers move to 3.1).
    — **Done:** pr-workflow-subagent table dropped for contract deferral + pipeline block coherence; linting-subagent table to language-linting pointer; files: agents/pr-workflow-subagent.md agents/linting-subagent.md; fixes: none
- [x] **1.7** Phase gate: `bats tests/test_default_behavior.bats tests/test_autoresearch_protocol.bats` + `node installer/build-registry.mjs --check`.
    — **Why:** Phase 1 rewrites files with test-pinned invariants; CI runs this check on every push, so the phase must exit green locally.
    — **Done when:** both bats files green; registry check clean.
    — **Consumers affected:** none (verification only).
    — **Done:** bats default_behavior+autoresearch_protocol exit 0 (0 failures, 175 ok); build-registry --check OK (agents=34 skills=149 no drift); files: none; fixes: none

### Phase 2: nextjs-pr-workflow-skill deletion + consumer sync (AC4)

- [x] **2.1** Fold the PR coverage-badge behavior into `skills/coverage-readme-workflow-skill/SKILL.md` as a short "PR badge comment" section (≤10 lines).
    — **Why:** the only unique feature of the deleted skill must survive it.
    — **Done when:** section present; no nextjs-specific wording.
    — **Consumers affected:** none (deletion in 2.7).
    — **Done:** PR badge comment section added before Iteration Protocol; files: skills/coverage-readme-workflow-skill/SKILL.md; fixes: none
- [x] **2.2** Update cross-references in `skills/nextjs-unit-test-creator-skill/SKILL.md` and `skills/semantic-release-convention-skill/SKILL.md` to point at `pr-creation-workflow-skill` instead of nextjs-pr-workflow.
    — **Why:** prevents dangling skill references after deletion.
    — **Done when:** `grep -rn "nextjs-pr-workflow" skills/` returns only the doomed skill dir.
    — **Consumers affected:** none.
    — **Done:** unit-test-creator repointed to pr-creation-workflow + gate contract; semantic-release consumption row removed; files: skills/nextjs-unit-test-creator-skill/SKILL.md skills/semantic-release-convention-skill/SKILL.md; fixes: none
- [x] **2.3** Remove every `nextjs-pr-workflow` reference from `agents/pr-workflow-subagent.md` — all four sites: frontmatter `permissions` allow rule `resource: nextjs-pr-workflow-skill` (:54), skills list (:116), and the two body notes (:161, :173).
    — **Why:** agent must not reference a deleted skill; the frontmatter permission rule is the consumer class most often missed.
    — **Done when:** `grep -rn "nextjs-pr-workflow" agents/` empty.
    — **Consumers affected:** registry.json (2.8 rebuild).
    — **Done:** all 4 sites removed (permissions rule, workflows list, chaining note, workflow step 5); files: agents/pr-workflow-subagent.md; fixes: none
- [x] **2.4** Remove the `nextjs-pr-workflow` entry from `installer/presets/pack-frontend.json` (hand-edit is the only path — the generator script is gone; update the file's `$comment` header accordingly) and, if present, from the skill allowlist in `opencode_app/opencode.json`. Not in the lean skill profile (verified, `tests/skill_profiles.bats:29-33`) — no profile change needed.
    — **Why:** installer + runtime configs must not ship a deleted skill.
    — **Done when:** grep clean outside tests/READMEs/registry; `$comment` no longer claims generator-only edits.
    — **Consumers affected:** none.
    — **Done:** preset entry removed + comment updated; opencode.json allowlist block removed; lean profile untouched (verified not present); files: installer/presets/pack-frontend.json opencode_app/opencode.json; fixes: none
- [x] **2.5** Delete the 6 `nextjs-pr-workflow` test blocks: 3 in `tests/test_default_behavior.bats` (:777, :782, :788) and 3 in `tests/test_autoresearch_protocol.bats` (:487, :492, :497).
    — **Why:** tests assert on files that will no longer exist.
    — **Done when:** `grep -rn "nextjs-pr-workflow" tests/` empty; both files still parse.
    — **Consumers affected:** none.
    — **Done:** 6 test blocks cut (3+3); tests/ grep clean; files: tests/test_default_behavior.bats tests/test_autoresearch_protocol.bats; fixes: none
- [x] **2.6** `git rm -r skills/nextjs-pr-workflow-skill`.
    — **Why:** the deletion itself; consumers are clean by 2.1-2.5.
    — **Done when:** directory gone from tree.
    — **Consumers affected:** README/setup counts (2.7), registry (2.8).
    — **Done:** skill directory removed via git rm; files: skills/nextjs-pr-workflow-skill/; fixes: none
- [x] **2.7** Sync counts and listings: `README.md` AND `opencode_app/README.md` skill totals (149 → 148) + category tables. `deploy/setup.sh`/`setup.ps1` counts are dynamic (`count_skills()`) — verify no hardcoding, expected no-op.
    — **Why:** the enforcing test is `test_markitdown_skill.bats:74-110` (disk == both READMEs == registry), which the plan previously missed; `test_count_drift.bats` guards the scripts.
    — **Done when:** `bats tests/test_markitdown_skill.bats tests/test_count_drift.bats` green.
    — **Consumers affected:** deploy tests.
    — **Done:** both READMEs 149 to 148 (tree, overview, profile-immunity, modularization, ledger Post-#409, category 11 to 10, subagent table, tier3 15 to 14); files: README.md opencode_app/README.md; fixes: none
- [x] **2.8** Run `node installer/build-registry.mjs`, commit regenerated `installer/registry.json`.
    — **Why:** registry is committed and must reflect the tree (repo convention after any frontmatter/skill change).
    — **Done when:** registry.json has no nextjs-pr-workflow entry; `git diff --stat` shows it regenerated.
    — **Consumers affected:** installer consumers.
    — **Done:** registry rebuilt at agents=34 skills=148 and committed; files: installer/registry.json; fixes: none

### Phase 3: Description boundaries (AC5)

- [x] **3.1** Rewrite six frontmatter `description:` values (value-only change, shape untouched): jira-git-integration (plumbing-only, "not for" create/label/status), plan-execution (soft mode, defer hard mode to plan-automation-loop), verification-loop (canonical gate contract, scoring → eval-harness), complexity-management (tradeoff heuristics, "not for" code-smells/ponytail-audit), git-issue-updater (when-pushed trigger), test-generator-framework (framework reference loaded by the two creators + testing-subagent). Preserve ≤50-word house style + trigger phrases.
    — **Why:** descriptions are the router; boundaries stop trigger poaching. Also lands the lint-trio router markers moved from 1.6: linting-workflow = executor reference, language-linting = per-language rules reference, linting-subagent = executor.
    — **Done when:** all six carry a boundary clause + ≥3 trigger phrases; trio descriptions carry executor/reference markers.
    — **Consumers affected:** registry.json (3.2).
    — **Done:** 9 descriptions rewritten (6 priority + lint-trio markers) — boundary clauses + triggers, value-only shape; files: skills/{jira-git-integration,plan-execution,verification-loop,complexity-management,git-issue-updater,test-generator-framework,linting-workflow,language-linting}-skill/SKILL.md agents/linting-subagent.md; fixes: none
- [x] **3.2** `node installer/build-registry.mjs`, commit registry.json.
    — **Why:** descriptions are registry content.
    — **Done when:** registry diff shows the six new descriptions.
    — **Consumers affected:** installer consumers.
    — **Done:** registry rebuilt (148 skills) with new descriptions, check clean; files: installer/registry.json; fixes: none

### Phase 4: Body trims, #383 recipe (AC6)

- [x] **4.1** Trim `skills/git-issue-labeler-skill/SKILL.md` 360 → ~90 lines: keep label decision table + `gh` command contract; delete worked examples and prose repetition; freeze frontmatter byte-identical; append dated removal-note blockquote.
    — **Why:** largest single bloat offender (label assignment needs a table, not 1,842 words).
    — **Done when:** frontmatter hash unchanged; all `Learning:` entries verbatim; removal note present.
    — **Consumers affected:** tests grepping its literals (sweep in 4.7).
    — **Done:** 360 to ~115 lines; LABELS array, taxonomy, sync contracts, semver code, verification kept; examples/prose dropped with removal note; files: skills/git-issue-labeler-skill/SKILL.md; fixes: none
- [x] **4.2** Trim `skills/search-first-skill/SKILL.md`: keep the adopt/extend/compose/build decision matrix + triggers; cut exhortation prose (~318 → ~150 lines). Same preservation rules as 4.1.
    — **Why:** the matrix is the payload.
    — **Done when:** same preservation checks as 4.1; preserves test-pinned invariants: `DO NOT execute…` preamble exactly once with results.tsv tokens, Iteration Protocol heading, opt-in metadata, autoresearch citations.
    — **Consumers affected:** none.
    — **Done:** 318 to ~105 lines; decision matrix, criteria, channels, anti-patterns kept; 4 worked examples + Best Practices dropped; files: skills/search-first-skill/SKILL.md; fixes: none
- [x] **4.3** Trim `skills/strategic-compact-skill/SKILL.md` and `skills/eval-harness-skill/SKILL.md`: decision rules + output contracts only. Same preservation rules.
    — **Why:** guidance prose the model already knows.
    — **Done when:** same preservation checks as 4.1; eval-harness keeps its pinned preamble/protocol invariants.
    — **Consumers affected:** verification-loop pointer (eval-harness scoring boundary, from 1.1).
    — **Done:** strategic-compact 247 to ~80, eval-harness 284 to ~95; tiers/thresholds/protocol kept, templates/examples dropped; files: skills/strategic-compact-skill/SKILL.md skills/eval-harness-skill/SKILL.md; fixes: none
- [x] **4.4** Trim `skills/agent-introspection-debugging-skill/SKILL.md`: keep the diagnosis decision tree + config-validation commands. Same preservation rules.
    — **Why:** 1,771 words for a diagnostic flow.
    — **Done when:** same preservation checks.
    — **Consumers affected:** none.
    — **Done:** 294 to ~105 lines; symptom/permission tables + output contract kept, 3 worked examples dropped, v1 permission refs corrected to v2 permissions array; files: skills/agent-introspection-debugging-skill/SKILL.md; fixes: none
- [x] **4.5** Trim `skills/frontend-design-skill/SKILL.md`: keep the 3 AI-design-cluster red flags + anti-patterns + step skeleton; compress framework/tone/steps prose that repeats them (~2,944 → ~1,400 words). Same preservation rules.
    — **Why:** taste tables are the payload; the rest re-explains them.
    — **Done when:** same preservation checks as 4.1; keeps pinned preamble/protocol invariants (preamble-once with results.tsv tokens, Iteration Protocol heading, opt-in metadata, autoresearch citations).
    — **Consumers affected:** uiux-review-skill axis-13 sync note (keep the "synced with" pointer).
    — **Done:** 421 to ~155 lines; cluster table, tokens, 13-axis check, verification kept, framework/steps prose compressed; files: skills/frontend-design-skill/SKILL.md; fixes: none (initial write missed protocol section, caught and appended before commit)
- [x] **4.6** Sweep quoted § pointers and literal strings against trimmed files (`grep -rn "<skill-name>" skills/ agents/ tests/ README.md opencode_app/README.md`), repair any pointer to a removed heading.
    — **Why:** LEARNINGS heading-rename-syncs-quoted-pointers — trims that rename/remove headings break cross-references silently.
    — **Done when:** no dangling `§`/heading quotes into trimmed files.
    — **Consumers affected:** all trimmed files.
    — **Done:** pointer sweep clean — no cross-file references into removed headings; false positives only (other skills own sections); files: none; fixes: none
- [x] **4.7** Commit the #383 recipe file `LEARNINGS/patterns/skill-trim-verbatim-preservation.md` (exists untracked in the main checkout) so AC6's normative citation resolves in the merged tree.
    — **Why:** AC6 and steps 4.1-4.5 cite this recipe; an untracked citation is a dangling reference for every future auditor.
    — **Done when:** file tracked on feat/409, content identical to the main-checkout copy.
    — **Consumers affected:** none.
    — **Done:** LEARNINGS/patterns/skill-trim-verbatim-preservation.md tracked on feat/409 (committed 76b752b); files: LEARNINGS/patterns/skill-trim-verbatim-preservation.md; fixes: none
- [x] **4.8** Run the full gate: `bats tests/` (suite), `node installer/build-registry.mjs` + commit if drifted.
    — **Why:** bats tests grep literal strings in skill bodies; trims can break them only detected at suite time.
    — **Done when:** suite green; registry committed.
    — **Consumers affected:** all.
    — **Done:** full bats suite exit 0, 326 ok, 0 failures; build-registry --check OK; files: none; fixes: none

### Phase 5: Prevention + final gate (AC1-AC6 enforcement)

- [ ] **5.1** Add to `skills/opencode-skill-creation-skill/SKILL.md` an authoring rule: body sections must be decision rules / boundaries / commands / templates / edge cases; worked examples ≤1 per non-obvious concept, none for stdlib-level knowledge.
    — **Why:** prevention — future skills stay lean without audits.
    — **Done when:** rule present in the skill's authoring-checklist section.
    — **Consumers affected:** none.
- [ ] **5.2** Add to `skills/opencode-skills-maintainer-skill/SKILL.md` two audit checks: description-without-boundary-clause, and tutorial-fence density (non-template skills >12 fences flag).
    — **Why:** makes this review's findings mechanically detectable next time.
    — **Done when:** both checks present in its audit list.
    — **Consumers affected:** none.
- [ ] **5.3** Final verification: full `bats tests/` green + `git status` clean + AC checklist fully ticked in PLAN and ticket body updated (`gh issue edit` closing-comment summary).
    — **Why:** phase gate for the last phase; ticket traceability.
    — **Done when:** suite green; PLAN-409.md all `[x]`; issue comment posted.
    — **Consumers affected:** PR body (Step 10).

## Technical Notes

### Gate-surface enumeration (requirements relay ruling, Gap 1)

AC1's ten gate-truth surfaces (ticket #409 audit): (1) verification-loop-skill — rewritten as the canonical contract (1.1); (2–6) plan-automation-loop, pr-creation-workflow, worktree-pipeline, pr-workflow-subagent, linting-subagent — defer via pointer (1.2–1.6); (7) nextjs-pr-workflow — deleted together with its gate table (Phase 2); (8–9) linting-workflow + language-linting — keep lint execution/reference authority under 1.6's trio markers and must not define the 5-gate sequence or pass semantics; (10) deploy/.AGENTS.md §Verification Gates — the ticket's tenth named surface, outside the ticket's Scope, explicitly left untouched (consolidating it is a separate ticket). deprecated-code-cleanup-skill's per-phase `tsc → lint → build` (SKILL.md:23,43) and pr-merge-workflow's CI failure-response rows (SKILL.md:79–83,158) are domain mechanics, not gate-sequence restatements — out of scope. AC1 verifies mechanically: after Phase 2, surfaces 2–7 contain zero restated gate tables/sequences — only the pointer lines remain.

### Memo surface definition (requirements relay ruling, Gap 2)

`/run-plan` writes `GATE <short-sha> lint=t typecheck=t build=t unit=t e2e=<t/-/n.a>` memos into the PLAN trace block after each green gate (1.2); at the PR boundary the memo check reads that trace block when a PLAN is in play, and in pipeline mode — where pr-workflow-subagent receives no PLAN path — the orchestrator's explicit green-gates assertion in the Task prompt counts as the memo, with 1.5's Step-10 edit making that assertion cite the final GATE line for the pushed SHA. Standalone runs with no memo for the current tree SHA run the gates — skipping on absent evidence is forbidden. pr-creation-workflow fills the PR body's existing Quality Checks slot (SKILL.md:41) from the memo/assertion so the SHA→green record survives into the PR for later re-run decisions; CI (`gh pr checks`) stays the only unconditional re-run.

### Evidence- Evidence lines verified against origin/main @ 08f9d7b on 2026-09-19 (session review): plan-automation-loop:33 scoped-lint; nextjs-pr-workflow:240,247; pr-merge:79,83; git-issue-labeler 360 lines.
- Repo gate reality: no lint/typecheck/build scripts configured (markdown + shell + .mjs repo); GATE.unit/e2e = `bats tests/`; build-equivalent = `node installer/build-registry.mjs`; lint-equivalent = `bash -n deploy/setup.sh` when touched. Gates that don't exist are reported INCONCLUSIVE, never skipped silently.
- nextjs-pr-workflow consumer sweep @ 08f9d7b: pr-workflow-subagent.md, installer/presets/pack-frontend.json, installer/registry.json, opencode_app/opencode.json, README.md, nextjs-unit-test-creator-skill, semantic-release-convention-skill, tests/test_autoresearch_protocol.bats, tests/test_default_behavior.bats.
- Trim preservation contract per LEARNINGS #383: frontmatter byte-identical; `Learning:` entries verbatim; keep workflow contracts/gates/budgets; dated removal-note blockquote.
- Node touching installer/* and deploy/* must respect: package-lock.json committed; `npm ci` hard-fails on drift → any dependency change runs `npm install` (none planned).

## Dependencies

None external. Single ticket, no `blocked-by:`.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| bats tests grep literals in trimmed/deleted skills | Step 2.5 removes affected tests deliberately; 4.6-4.7 sweep + full suite before phase close |
| Count drift across README/setup.sh/setup.ps1/profiles | Step 2.7 + test_count_drift.bats as the gate |
| Trim accidentally alters frontmatter or Learnings | Byte-identity check in every trim step's Done-when (hash compare) |
| Gate-contract rewrite changes behavior mid-pipeline | Contract is additive (pointers + memo); no gate command changes; CI remains authoritative post-push |
