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
| `skills/nextjs-pr-workflow-skill/` (delete) | badge folded (2.1); cross-refs updated (2.2-2.4) | pr-workflow-subagent, nextjs-unit-test-creator, semantic-release-convention, installer/presets/pack-frontend.json, opencode_app/opencode.json, README.md, tests (2 bats files, 5 tests), registry.json | high |
| `skills/coverage-readme-workflow-skill/SKILL.md` | — | nextjs-pr-workflow badge migration target | low |
| 6 skill descriptions (frontmatter `description:`) | — | registry.json (rebuilt), skill router | med |
| 6 skill bodies (trims) | frontmatter frozen byte-identical | quoted § pointers (LEARNINGS heading-rename rule), tests grepping literals | med |
| `skills/opencode-skill-creation-skill/SKILL.md`, `skills/opencode-skills-maintainer-skill/SKILL.md` | patterns settled (P1-P4) | future skill authors | low |
| `README.md`, `deploy/setup.sh`, `deploy/setup.ps1`, `installer/registry.json` | all skill changes (P2-P4) | test_count_drift.bats, deploy_delegate.bats, skill_profiles.bats | med |

## Implementation Phases

### Phase 1: Gate contract consolidation (AC1, AC2, AC3)

- [ ] **1.1** Rewrite `skills/verification-loop-skill/SKILL.md` as the canonical gate contract: command discovery order (package.json → Makefile → pyproject → README), gate sequence lint→typecheck→build→unit→e2e, scoped-lint rule ("zero NEW errors on changed files"), INCONCLUSIVE-is-not-pass verdict protocol, and gate-memo format `GATE <short-sha> lint=t typecheck=t build=t unit=t e2e=<t/-/n.a>`.
    — **Why:** every other pipeline surface defers to this file; it must land first.
    — **Done when:** contract file contains all five elements; its own restated generic checklists removed; references eval-harness-skill for scoring.
    — **Consumers affected:** all nodes pointing at it (1.2-1.6).
- [ ] **1.2** `plan-automation-loop-skill`: keep the phase loop and GATE discovery mechanics, replace the restated contract wording with a pointer to verification-loop-skill; add memo-write after each green gate (into the PLAN trace block).
    — **Why:** it is the per-phase gate owner; memo must be written where phases complete.
    — **Done when:** file contains no self-styled contract definition beyond the pointer; memo-write step present.
    — **Consumers affected:** worktree-pipeline Step 8 wording (1.5).
- [ ] **1.3** `pr-creation-workflow-skill`: replace the inline framework→command table with a pointer to the verification-loop contract; add memo check (same tree SHA green since last gate → skip, state it; CI remains the only unconditional re-run).
    — **Why:** removes duplicated table + implements AC2 skip logic at the PR boundary.
    — **Done when:** no inline command table; memo-check step present.
    — **Consumers affected:** pr-workflow-subagent (2.3).
- [ ] **1.4** `pr-merge-workflow-skill`: autofix response rows commit with `style:` (format) / `fix(lint):` (lint) prefixes.
    — **Why:** resolves the style-only-commit clash with the atomic-commit rule (plan-automation-loop:70).
    — **Done when:** both rows name the commit type prefix.
    — **Consumers affected:** none.
- [ ] **1.5** `worktree-pipeline-skill`: line ~121 gate restate → pointer to verification-loop contract; Step 8 note that per-phase gates write the memo and Step 10 relies on CI only.
    — **Why:** orchestrator must not define gates, only sequence them.
    — **Done when:** no gate restatement; pointers present.
    — **Consumers affected:** none.
- [ ] **1.6** `agents/pr-workflow-subagent.md` + `agents/linting-subagent.md`: drop own framework/command tables, defer to pr-creation-workflow-skill (PR checks) and language-linting-skill (lint execution); add "executor vs reference" markers to the lint trio descriptions (linting-workflow = workflow, language-linting = per-language reference, linting-subagent = executor).
    — **Why:** three lint surfaces currently allow divergent behavior.
    — **Done when:** agent files contain no command tables; trio descriptions carry router markers.
    — **Consumers affected:** registry.json (3.2 rebuild).

### Phase 2: nextjs-pr-workflow-skill deletion + consumer sync (AC4)

- [ ] **2.1** Fold the PR coverage-badge behavior into `skills/coverage-readme-workflow-skill/SKILL.md` as a short "PR badge comment" section (≤10 lines).
    — **Why:** the only unique feature of the deleted skill must survive it.
    — **Done when:** section present; no nextjs-specific wording.
    — **Consumers affected:** none (deletion in 2.7).
- [ ] **2.2** Update cross-references in `skills/nextjs-unit-test-creator-skill/SKILL.md` and `skills/semantic-release-convention-skill/SKILL.md` to point at `pr-creation-workflow-skill` instead of nextjs-pr-workflow.
    — **Why:** prevents dangling skill references after deletion.
    — **Done when:** `grep -rn "nextjs-pr-workflow" skills/` returns only the doomed skill dir.
    — **Consumers affected:** none.
- [ ] **2.3** Remove the `nextjs-pr-workflow` skills-list entry from `agents/pr-workflow-subagent.md` (its framework table is already gone via 1.6).
    — **Why:** agent must not reference a deleted skill.
    — **Done when:** grep clean in agents/.
    — **Consumers affected:** registry.json.
- [ ] **2.4** Remove the `nextjs-pr-workflow` entry from `installer/presets/pack-frontend.json` and, if present, from the skill allowlist in `opencode_app/opencode.json` and `deploy/skill-profiles.json` (lean array).
    — **Why:** installer + runtime configs must not ship a deleted skill.
    — **Done when:** grep clean outside tests/README/registry.
    — **Consumers affected:** skill_profiles.bats expectations.
- [ ] **2.5** Delete the 5 `nextjs-pr-workflow` test blocks from `tests/test_default_behavior.bats` (3) and `tests/test_autoresearch_protocol.bats` (2).
    — **Why:** tests assert on files that will no longer exist.
    — **Done when:** `grep -rn "nextjs-pr-workflow" tests/` empty; both files still parse (`bats --jit` dry parse or full run later).
    — **Consumers affected:** none.
- [ ] **2.6** `git rm -r skills/nextjs-pr-workflow-skill`.
    — **Why:** the deletion itself; consumers are clean by 2.1-2.5.
    — **Done when:** directory gone from tree.
    — **Consumers affected:** README/setup counts (2.7), registry (2.8).
- [ ] **2.7** Sync counts and listings: README.md Skill Categories table + totals, deploy/setup.sh + setup.ps1 skill lists/counts/banner, per documentation-sync rules.
    — **Why:** test_count_drift.bats enforces README/script consistency.
    — **Done when:** `bats tests/test_count_drift.bats` green.
    — **Consumers affected:** deploy tests.
- [ ] **2.8** Run `node installer/build-registry.mjs`, commit regenerated `installer/registry.json`.
    — **Why:** registry is committed and must reflect the tree (repo convention after any frontmatter/skill change).
    — **Done when:** registry.json has no nextjs-pr-workflow entry; `git diff --stat` shows it regenerated.
    — **Consumers affected:** installer consumers.

### Phase 3: Description boundaries (AC5)

- [ ] **3.1** Rewrite six frontmatter `description:` values (value-only change, shape untouched): jira-git-integration (plumbing-only, "not for" create/label/status), plan-execution (soft mode, defer hard mode to plan-automation-loop), verification-loop (canonical gate contract, scoring → eval-harness), complexity-management (tradeoff heuristics, "not for" code-smells/ponytail-audit), git-issue-updater (when-pushed trigger), test-generator-framework (framework reference loaded by the two creators + testing-subagent). Preserve ≤50-word house style + trigger phrases.
    — **Why:** descriptions are the router; boundaries stop trigger poaching.
    — **Done when:** all six carry a boundary clause + ≥3 trigger phrases; `grep -c "Triggers:"` reflects them.
    — **Consumers affected:** registry.json (3.2).
- [ ] **3.2** `node installer/build-registry.mjs`, commit registry.json.
    — **Why:** descriptions are registry content.
    — **Done when:** registry diff shows the six new descriptions.
    — **Consumers affected:** installer consumers.

### Phase 4: Body trims, #383 recipe (AC6)

- [ ] **4.1** Trim `skills/git-issue-labeler-skill/SKILL.md` 360 → ~90 lines: keep label decision table + `gh` command contract; delete worked examples and prose repetition; freeze frontmatter byte-identical; append dated removal-note blockquote.
    — **Why:** largest single bloat offender (label assignment needs a table, not 1,842 words).
    — **Done when:** frontmatter hash unchanged; all `Learning:` entries verbatim; removal note present.
    — **Consumers affected:** tests grepping its literals (sweep in 4.7).
- [ ] **4.2** Trim `skills/search-first-skill/SKILL.md`: keep the adopt/extend/compose/build decision matrix + triggers; cut exhortation prose (~318 → ~150 lines). Same preservation rules as 4.1.
    — **Why:** the matrix is the payload.
    — **Done when:** same preservation checks as 4.1.
    — **Consumers affected:** none.
- [ ] **4.3** Trim `skills/strategic-compact-skill/SKILL.md` and `skills/eval-harness-skill/SKILL.md`: decision rules + output contracts only. Same preservation rules.
    — **Why:** guidance prose the model already knows.
    — **Done when:** same preservation checks.
    — **Consumers affected:** verification-loop pointer (eval-harness scoring boundary, from 1.1).
- [ ] **4.4** Trim `skills/agent-introspection-debugging-skill/SKILL.md`: keep the diagnosis decision tree + config-validation commands. Same preservation rules.
    — **Why:** 1,771 words for a diagnostic flow.
    — **Done when:** same preservation checks.
    — **Consumers affected:** none.
- [ ] **4.5** Trim `skills/frontend-design-skill/SKILL.md`: keep the 3 AI-design-cluster red flags + anti-patterns + step skeleton; compress framework/tone/steps prose that repeats them (~2,944 → ~1,400 words). Same preservation rules.
    — **Why:** taste tables are the payload; the rest re-explains them.
    — **Done when:** same preservation checks.
    — **Consumers affected:** uiux-review-skill axis-13 sync note (keep the "synced with" pointer).
- [ ] **4.6** Sweep quoted § pointers and literal strings against trimmed files (`grep -rn "<skill-name>" skills/ agents/ tests/ README.md`), repair any pointer to a removed heading.
    — **Why:** LEARNINGS heading-rename-syncs-quoted-pointers — trims that rename/remove headings break cross-references silently.
    — **Done when:** no dangling `§`/heading quotes into trimmed files.
    — **Consumers affected:** all trimmed files.
- [ ] **4.7** Run the full gate: `bats tests/` (suite), `node installer/build-registry.mjs` + commit if drifted.
    — **Why:** bats tests grep literal strings in skill bodies; trims can break them only detected at suite time.
    — **Done when:** suite green; registry committed.
    — **Consumers affected:** all.

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

- Evidence lines verified against origin/main @ 08f9d7b on 2026-09-19 (session review): plan-automation-loop:33 scoped-lint; nextjs-pr-workflow:240,247; pr-merge:79,83; git-issue-labeler 360 lines.
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
