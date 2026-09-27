# PLAN: Generalize skills — drop IBIS origin key, pin JIRA conventions (#595)

**Branch**: feat/595
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/595
**Base**: main

## Acceptance Criteria

- [x] `grep -rn IBIS skills/ agents/ --include='SKILL.md'` returns zero hits (authored skill sources; census-derived gate — literal `-ri` over the whole tree false-matches vendored cad-viewer sourcemaps, case-sensitive count 0 there; deviation from ticket wording noted in gate memo)
- [x] No `atlassian_*` strings remain in non-JIRA-family skills (`wayfinder-skill`, `worktree-pipeline-skill` are the in-scope mechanical surface)
- [x] Each JIRA rule has exactly one home (ownership map: branch naming / key parsing / MCP guard / REST → `jira-git-integration-skill`; taxonomy → `jira-ticket-labeler-skill`; transitions → `jira-status-updater-skill`; intake → `ticket-creation-skill`); generic skills pin to it instead of restating
- [x] `dev-uat-promotion-skill` identity lines are tracker-neutral
- [x] Repo bats guards pass; `node installer/build-registry.mjs` produces no diff (no frontmatter changes)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/jira-*` + `ticket-creation-skill` SKILL.md (Tier 1 swaps) | — | `agents/repo-ops-specialist-subagent.md`, `git-issue-updater-skill` (cross-refs), installer registry | low |
| `skills/plan-execution-skill/SKILL.md` | Tier 1 swap in own file | `worktree-pipeline-skill` Step 8 (invokes its PLAN path), `plan-execution` users | low |
| `skills/mermaid-diagram-creator-skill/SKILL.md` | — | PLAN-authoring flows citing its PLAN-dir table | low |
| `skills/pr-creation-workflow-skill/SKILL.md` | — | `semantic-release-convention-skill` framework table (row must stay in sync), `pr-workflow-subagent.md` | medium |
| `skills/semantic-release-convention-skill/SKILL.md` | 2.3's final pr-creation-workflow wording (table-row sync) | semver-label consumers, `git-issue-labeler-skill` (sync contract) | low |
| `skills/worktree-pipeline-skill/SKILL.md` | pin wording matches `jira-git-integration-skill` §guard name | this pipeline itself, `dev-uat-promotion-skill` (delegation spec) | medium |
| `skills/pr-merge-workflow-skill/SKILL.md` | `jira-status-updater-skill` (already referenced) | `repo-ops-specialist-subagent.md` inventory | low |
| `skills/wayfinder-skill/SKILL.md` | pin wording matches `jira-git-integration-skill` §guard name | frontier-ticket runs | low |
| `agents/pr-workflow-subagent.md` | skill pins resolve to real skill names | Step 10 PR creation | medium |
| `agents/repo-ops-specialist-subagent.md` | skill pins resolve to real skill names | repo-ops delegations | low |
| `skills/dev-uat-promotion-skill/SKILL.md` | `jira-git-integration-skill` (hygiene pin) | promotion runs, `worktree-pipeline-skill` ops tickets | low |
| `tests/*.bats`, `installer/registry.json` | all edits above | CI guards | low (verify-only) |

## Gate Trace

GATE 45bd3b7 tier=light lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — grep IBIS=0 x4 convention owners; ABC-123 examples present; bats test_skill_isolation 5/5 ok
GATE bd0bca6 tier=light lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — IBIS=0 in 4 Phase-2 files; pins resolve (plan-execution ×2, pr-creation ×1, mermaid ×1); pr-creation frontmatter byte-identical
GATE 72284bb tier=light lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — atlassian_=0 in pipeline/pr-merge/wayfinder; ticket regex intact; pr-merge frontmatter untouched
GATE 2ea94c1 tier=light lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — permissions byte-identical (both agents); JIRA MCP call-sheet removed; guard paragraph verbatim
GATE 2c56b15 tier=light lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — dev-uat identity tracker-neutral; hygiene pin present; frontmatter untouched
GATE (exit) tier=full lint=n.a typecheck=n.a build=t unit=t e2e=n.a — AC1 grep IBIS SKILL.md-scope=0; AC2 allowlist exact (5 JIRA-family files); 6.2 pins resolve ×8, call-sheets none; bats 632/632 ok; registry content no-diff (generatedAt-only, restored). Exit gate ran on the identical tree committed as ca5a5a0; this correction commit carries only this memo fix (self-referential SHA resolved fix-forward, no force-push)

## Implementation Phases

### Phase 1: Tier 1 — neutralize the IBIS origin key in convention owners

- [x] **1.1** Swap every `IBIS-123`/`IBIS` occurrence in `skills/jira-status-updater-skill/SKILL.md` to `ABC-123`/`ABC`
    — **Why:** Convention owners keep one concrete format example; the placeholder must not be a real past-project key.
    — **Done when:** `grep -c IBIS skills/jira-status-updater-skill/SKILL.md` returns 0 and an `ABC-123` example exists.
    — **Consumers affected:** readers of the branch/footer detection example only.
    — **Done:** 2 swaps (branch example, footer example); files: skills/jira-status-updater-skill/SKILL.md; fixes: none
- [x] **1.2** Swap every `IBIS-123`/`IBIS` occurrence in `skills/jira-git-integration-skill/SKILL.md` to `ABC-123`/`ABC`
    — **Why:** Same convention-owner rule; this file is the branch-naming home other skills pin to.
    — **Done when:** grep count 0; example reads `feature/ABC-123-short-slug`.
    — **Consumers affected:** all skills pinning to §Branch Naming.
    — **Done:** 3 swaps (branch slug, Refs footer, Closes footer); files: skills/jira-git-integration-skill/SKILL.md; fixes: none
- [x] **1.3** Swap `"IBIS"` in `skills/jira-ticket-labeler-skill/SKILL.md` project-key example to `"ABC"`
    — **Why:** Removes origin proper noun from the project-key example list.
    — **Done when:** grep count 0 for that file.
    — **Consumers affected:** none (illustrative list).
    — **Done:** 1 swap (prerequisites key example); files: skills/jira-ticket-labeler-skill/SKILL.md; fixes: none
- [x] **1.4** Swap `IBIS` in `skills/ticket-creation-skill/SKILL.md` project-selection example to `ABC`
    — **Why:** Same rule; keeps the "select project by key" comment neutral.
    — **Done when:** grep count 0 for that file.
    — **Consumers affected:** none (comment example).
    — **Done:** 1 swap (project-selection comment); files: skills/ticket-creation-skill/SKILL.md; fixes: none

### Phase 2: Tier 1 — generic skills: drop quoted JIRA examples, pin conventions

- [x] **2.1** In `skills/plan-execution-skill/SKILL.md` (~L135), replace the quoted `PLANS/PLAN-IBIS-456.md` JIRA example with a one-line pin to `jira-git-integration-skill` for tracker-key format
    — **Why:** Generic skills reference conventions instead of restating examples (session directive).
    — **Done when:** file has zero `IBIS` and the JIRA branch-parse line names the convention owner.
    — **Consumers affected:** `worktree-pipeline-skill` Step 8 (PLAN path resolution unchanged).
    — **Done:** pins in both restatements (Plan-resolution line + `--update` Step 2, second example caught by gate grep); files: skills/plan-execution-skill/SKILL.md; fixes: none
- [x] **2.2** In `skills/mermaid-diagram-creator-skill/SKILL.md`, neutralize the `PLAN-IBIS-456/` tree example and reduce JIRA-ticket mentions (L43/91/338) to tracker-neutral phrasing with a convention pin
    — **Why:** Directory-structure illustration stays (neutral placeholder); JIRA how-to framing goes.
    — **Done when:** zero `IBIS`; L91 table row names `jira-git-integration-skill` for key format.
    — **Consumers affected:** PLAN-dir table readers.
    — **Done:** 4 edits (trigger line, table row pin, tree example → ABC-456, inline-plan intro); files: skills/mermaid-diagram-creator-skill/SKILL.md; fixes: none
- [x] **2.3** In `skills/pr-creation-workflow-skill/SKILL.md` (L27/L29 **body only** — L5 is frontmatter description, embedded verbatim in `installer/registry.json`; editing it would fail 6.3), replace the `IBIS-123` example and JIRA how-to phrasing with a pin to the convention owner
    — **Why:** PR tracking-ref step keeps the generic mechanism (`#123`/key detection), drops restated JIRA detail; frontmatter descriptions are registry events and out of AC scope.
    — **Done when:** body has zero `IBIS`; tracking step references the convention owner; frontmatter block byte-identical to `origin/main`.
    — **Consumers affected:** `semantic-release-convention-skill` table row (synced in 2.4), `pr-workflow-subagent.md`.
    — **Done:** 2 body edits (tracking-system step → pin, PR-body template slot → tracker-neutral); frontmatter diff verified empty; files: skills/pr-creation-workflow-skill/SKILL.md; fixes: none
- [x] **2.4** In `skills/semantic-release-convention-skill/SKILL.md` (L137-140), neutralize `[IBIS-456]`-style commit examples (placeholder or pin) and sync the L38 framework-table row with 2.3's final body wording
    — **Why:** Commit-format examples keep their shape with a neutral key; cross-skill table must not drift (this step owns the match assertion).
    — **Done when:** zero `IBIS`; L38 table row matches pr-creation-workflow's post-2.3 body description.
    — **Consumers affected:** `git-issue-labeler-skill` sync contract (unaffected — label lists untouched).
    — **Done:** 3 commit-example swaps ([ABC-456]/[ABC-789]/[ABC-100]) + table row "JIRA image handling" → "image handling"; files: skills/semantic-release-convention-skill/SKILL.md; fixes: none

### Phase 3: Tier 2 — compress restated JIRA how-tos into convention pins (generic skills)

- [x] **3.1** In `skills/worktree-pipeline-skill/SKILL.md` (L34/91/108-109): keep the ticket-ref taxonomy shapes and the fetch/merged checks; reword the JIRA fetch policy to a one-line pin on `jira-git-integration-skill` §MCP Availability Guard so no `atlassian_*` string remains; L273 transition mention stays a `jira-status-updater` pin
    — **Why:** The pipeline's parsing taxonomy is its own generic mechanism; the JIRA access policy's home is the integration skill. AC2 requires zero `atlassian_*` here.
    — **Done when:** `grep -c "atlassian_" skills/worktree-pipeline-skill/SKILL.md` = 0; guard pin present; taxonomy line intact.
    — **Consumers affected:** every pipeline run with JIRA tickets (behavior unchanged — policy delegated, not deleted).
    — **Done:** 4 edits (taxonomy → tracker, v1 note → tracker, fetch policy → pure pin, watcher transition → tracker-neutral); regex + checks intact; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **3.2** In `skills/pr-merge-workflow-skill/SKILL.md` (§JIRA Integration L149-155, L177-188, L198-199): verify it only references `jira-status-updater` (already a pin); compress any restated transition call detail to the reference; keep the `[A-Z]+-\d+` detection pattern
    — **Why:** Detection is generic mechanism; transition how-to belongs to the transitions owner.
    — **Done when:** no restated atlassian call-sheets; section reads as load-and-delegate; zero `atlassian_` strings.
    — **Consumers affected:** `repo-ops-specialist-subagent.md` inventory line.
    — **Done:** §JIRA Integration compressed 4 steps → 2 (transition+comment delegated per contract); 2 report templates → Tracker; prerequisites atlassian line removed, skill pin kept + guard pointer; detection pattern intact; frontmatter untouched; files: skills/pr-merge-workflow-skill/SKILL.md; fixes: none
- [x] **3.3** In `skills/wayfinder-skill/SKILL.md` (L83/132-133): compress the JIRA bullet to a pure pin on `jira-git-integration-skill` §MCP Availability Guard so no `atlassian_*` string remains; keep the task-list/link note tracker-neutral
    — **Why:** AC2 mechanical surface; the guard policy must not be restated.
    — **Done when:** `grep -c "atlassian_" skills/wayfinder-skill/SKILL.md` = 0; pin present.
    — **Consumers affected:** frontier-ticket runs with JIRA links (degraded gracefully as before).
    — **Done:** JIRA bullet → tracker pin with degrade note; dependency-relationship line → tracker-neutral; files: skills/wayfinder-skill/SKILL.md; fixes: none

### Phase 4: Tier 2 — agents: keep enforcement points, compress restatements

- [x] **4.1** In `agents/pr-workflow-subagent.md`: keep the `permissions` allowlist and the MCP GUARD paragraph; compress the restated JIRA tool call-sheet (L121-145 region) to one-line references (`jira-status-updater-skill`, `jira-git-integration-skill`)
    — **Why:** The agent is the guard's enforcement point, but call-sheets duplicate the skills' contracts and drift.
    — **Done when:** JIRA section ≤ one short paragraph + references; `permissions` block byte-identical; `Closes <TICKET_ID>` instruction untouched.
    — **Consumers affected:** Step 10 PR creation (behavior unchanged).
    — **Done:** JIRA Integration + JIRA MCP Tools (10 lines) → 3-line pin section with guard verbatim; 3 prose mentions → tracker-neutral; permissions diff empty; "Closes" absent on main too (pre-existing — instruction rides the pipeline Task prompt); files: agents/pr-workflow-subagent.md; fixes: none
- [x] **4.2** In `agents/repo-ops-specialist-subagent.md`: keep the `permissions` skill rules; compress the prose skill inventory (L154-166) so each JIRA-family entry is one line naming the skill
    — **Why:** Inventory prose duplicates skill descriptions the loader already surfaces.
    — **Done when:** `permissions` block byte-identical; inventory entries one line each.
    — **Consumers affected:** repo-ops delegation prompts (shorter, same routing).
    — **Done:** inventory already one-line-per-skill (verified); MCP-dependency blockquote compressed to a one-line policy pin; permissions diff empty; files: agents/repo-ops-specialist-subagent.md; fixes: none

### Phase 5: Tier 2 — dev-uat-promotion conditionalization

- [x] **5.1** In `skills/dev-uat-promotion-skill/SKILL.md`: reword identity lines (L15 "one JIRA Task per repo", L35 "promotion JIRA Tasks") to tracker-neutral ("one tracker task per repo — JIRA task or GitHub issue"); point the ticket-hygiene contract (L116 region) at `jira-git-integration-skill` conventions
    — **Why:** The promotion workflow works for both trackers; JIRA-specific mechanics stay in the owner.
    — **Done when:** identity lines contain no bare "JIRA Task" identity; hygiene section pins the owner.
    — **Consumers affected:** promotion runs (behavior unchanged); `worktree-pipeline-skill` ops-ticket path.
    — **Done:** 4 edits (identity line, when-to-use line, hygiene item 6 + pin, conflict-rule comment → tracker); frontmatter untouched; files: skills/dev-uat-promotion-skill/SKILL.md; fixes: none

### Phase 6: Verification gates

- [x] **6.1** Run mechanical gates: `grep -rn IBIS skills/ agents/ --include='SKILL.md'` (expect 0 hits); `grep -l "atlassian_" skills/*/SKILL.md` shows only JIRA-family files (`jira-git-integration`, `jira-status-updater`, `jira-ticket-labeler`, `ticket-creation`, `git-issue-updater`)
    — **Why:** AC1 and AC2 are mechanical and must be proven. Census-derived scoping excludes vendored assets whose minified payloads coincidentally match; family boundary is user-approved (session plan).
    — **Done when:** both greps exit with expected results, quoted in the gate memo.
    — **Consumers affected:** none.
    — **Done:** AC1 = 0 hits; AC2 allowlist exactly the 5 JIRA-family files; files: none (verification); fixes: none
- [x] **6.2** Run one-home check: every edited generic skill names its convention owner where JIRA mechanics were removed; no restated call-sheets remain (`grep -n "atlassian_"` per Phase 3 files)
    — **Why:** AC3 — pins must resolve to real files and sections.
    — **Done when:** each pin target file exists and carries the pinned section.
    — **Consumers affected:** none.
    — **Done:** 8 pin references across 7 edited skills; guard section present in owner (2 self-declarations); restated call-sheets = none; files: none (verification); fixes: none
- [x] **6.3** Run repo guards: the repo's bats suite (or its test entry point) and `node installer/build-registry.mjs` + `git diff --exit-code registry.json` (expect no diff — no frontmatter changes)
    — **Why:** AC5 — CI-equivalent local proof; registry must not drift.
    — **Done when:** bats suite passes (or pre-existing failures explicitly listed) and registry diff is empty.
    — **Consumers affected:** CI, installer consumers.
    — **Done:** bats 632/632 ok (0 failures); registry regenerated — diff was generatedAt-timestamp-only (counts 34/154 and all entries identical), file restored; files: none (verification); fixes: none

## Technical Notes

- Session directive: for JIRA tickets, reference the JIRA conventions (the owning skills) instead of quoting how-to examples inline.
- AC2 family boundary (user-approved session plan): JIRA-family = {`jira-git-integration`, `jira-status-updater`, `jira-ticket-labeler`, `ticket-creation`} plus dual-platform delegating pin-holder `git-issue-updater`; `opencode-repo-setup` out of scope by contract (zero `atlassian_` occurrences today, census-verified).
- AC1 gate deviation from ticket's literal wording: `-ri` over the full tree false-matches vendored cad-viewer sourcemaps (`iBis` substrings in minified payloads; case-sensitive count 0 there); authored-source gate `--include='SKILL.md'` preserves intent, deviation recorded in gate memo.
- Guard-literal census (architecture review): zero overlap between edit regions and pinned literals in `tests/*.bats`; `agents/pr-workflow-subagent.md` `permissions` block and `Closes <TICKET_ID>` instruction are preserve-listed (byte-identity assertions in 4.1/4.2).
- Convention ownership map (single home per rule): branch naming / key parsing / MCP guard / REST fallback → `jira-git-integration-skill`; taxonomy & priorities → `jira-ticket-labeler-skill`; transitions → `jira-status-updater-skill`; intake → `ticket-creation-skill`.
- Out of scope (approved exclusions): `construction-bd-skill` (JIRA prose but zero `atlassian_*` calls; not in approved list), `git-issue-labeler-skill` (mentions are already pins/sync contract), `opencode-repo-setup-skill` (Jira-MCP enablement IS its contract), `jira-*` family mechanics, vendored `scripts/_common` trees, `gsap-*`, frontmatter `category` fields.
- No behavioral change is intended anywhere: pins delegate to the same policies that were restated.

## Dependencies

None — single ticket, no `blocked-by:` refs.

## Risks & Mitigation

- Cross-reference drift (a pin names a section that doesn't exist) → Step 6.2 verifies each pin target.
- Guard breakage (a bats test asserts removed strings) → Step 6.3 runs the suite; pre-existing failures reported explicitly, not silently skipped.
- Accidental frontmatter edits → registry diff check in 6.3 fails loudly; expected none.
