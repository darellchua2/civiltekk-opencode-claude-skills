# PLAN: Add standardized issue templates and agent ticket-intake flow

**Branch**: feat/417
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/417
**Base**: main

## Acceptance Criteria

- [ ] `.github/ISSUE_TEMPLATE/{bug_report.yml,feature_request.yml,config.yml}` exist; field labels match the skill's spec tables verbatim
- [ ] `ticket-creation-skill` documents intake cycle, field specs, render templates, ticket-vs-plan boundary rules
- [ ] `skills/ticket-creation-skill/templates/` carries the 3 forms (byte-identical to repo-level ones)
- [ ] `opencode-repo-setup-skill` offers + performs the scaffold idempotently (skip-if-present, never overwrite)
- [ ] `node installer/build-registry.mjs` run; `registry.json` committed
- [ ] Test suite passes

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/ticket-creation-skill/templates/*.yml` | field labels defined here (canonical source) | repo-level `.github/ISSUE_TEMPLATE/` (copy source), setup-skill scaffold step, distribution channels (`installer/init.mjs:397,676,836,969` recursive copy; deploy delegates to `init.mjs add --all`) | med |
| `.github/ISSUE_TEMPLATE/*.yml` | skill templates (byte-identity) | human contributors (browser issue form), triage label filters | low |
| `skills/ticket-creation-skill/SKILL.md` | templates dir (labels must match tables verbatim) | primary agent runtime (ticket creation), `installer/build-registry.mjs` (frontmatter) | med |
| `skills/opencode-repo-setup-skill/SKILL.md` | ticket skill `templates/` dir location | setup flow in target repos, `installer/build-registry.mjs` (frontmatter) | med |
| `registry.json` | both SKILL.md frontmatter files | `installer/init.mjs` registry consumers | low |

Cross-module nodes exist (templates ↔ setup-skill ↔ registry build) → architecture review selected at Step 7. No frontend signal → no uiux review.

## Implementation Phases

### Phase 1: Canonical form templates (skill-owned source of truth)

- [ ] **1.1** Write `skills/ticket-creation-skill/templates/bug_report.yml` — GitHub issue form: search-first checkbox, Problem, Steps to Reproduce, Expected vs Actual, Environment, Logs (render: shell), References; labels `["bug"]`, title prefix `[Bug]: `
    — **Why:** This file is the canonical source both the repo-level forms and the setup-skill scaffold copy from; writing it first fixes the field labels every other artifact must match.
    — **Done when:** File exists, parses as YAML, and contains the 7 labeled fields with `validations.required` marking Title/Problem/Steps/Expected-Actual/Environment required.
    — **Consumers affected:** repo-level forms (Phase 2), setup-skill scaffold (Phase 4), distribution channels.
- [ ] **1.2** Write `skills/ticket-creation-skill/templates/feature_request.yml` — GitHub issue form: search-first checkbox, Problem/Use Case, Proposed Solution, Alternatives Considered, Acceptance Criteria, References; labels `["enhancement"]`
    — **Why:** Feature path needs its own lighter variant; label auto-applied on submission drives triage.
    — **Done when:** File exists, parses as YAML, contains the 6 labeled fields with required flags set.
    — **Consumers affected:** same as 1.1.
- [ ] **1.3** Write `skills/ticket-creation-skill/templates/config.yml` — `blank_issues_enabled: false`, `contact_links` for questions
    — **Why:** Chooser config forces template use so the structured intake actually applies to humans.
    — **Done when:** File exists, parses as YAML, `blank_issues_enabled: false` present.
    — **Consumers affected:** same as 1.1.

### Phase 2: Repo-level issue forms

- [ ] **2.1** Create `.github/ISSUE_TEMPLATE/` and copy the 3 template files into it via `cp`
    — **Why:** Byte-identical copies guarantee the human-facing forms and the distributable templates never diverge at authoring time.
    — **Done when:** All 3 files exist under `.github/ISSUE_TEMPLATE/`.
    — **Consumers affected:** human contributors opening issues; triage filters.
- [ ] **2.2** Verify byte-identity: `cmp` each repo-level file against its skill template
    — **Why:** The AC requires byte-identity; verification proves the copy, not a paraphrase.
    — **Done when:** All 3 `cmp` runs exit 0.
    — **Consumers affected:** none (verification only).

### Phase 3: Ticket skill intake flow

- [ ] **3.1** Rewrite `skills/ticket-creation-skill/SKILL.md` Step 2 as the intake cycle: classify (bug | feature | task via labeler skills) → intake (batched field collection, ask-don't-invent) → validate (required fields non-empty) → preview (rendered ticket confirmed) → submit; add field-spec tables for the bug and feature/task variants with labels matching the templates verbatim; ALSO rewrite the "What I do" list and the Example Usage section so no stale 5-field intake (including Technical Notes collection) survives anywhere in the file
    — **Why:** This is the core behavioral change — the agent now runs the same required-field intake a human runs in the browser form. Review finding W1: the old intake also lives in "What I do" (:21) and Example Usage (:254-271); leaving them teaches agents the deprecated flow.
    — **Done when:** SKILL.md contains both variant tables and the 5-stage cycle; every table label string-matches a field label in the corresponding template file; the file no longer collects Technical Notes anywhere.
    — **Consumers affected:** primary agent runtime; `installer/build-registry.mjs` (frontmatter unchanged).
- [ ] **3.2** Add per-platform render templates to SKILL.md: GitHub markdown body (sections mirror form headings), Jira description mapping (Bug fields; Story renders "As a… I want… so that…" + AC checklist; Task gets feature/task fields)
    — **Why:** One canonical schema with platform renderings prevents human-created and agent-created tickets drifting structurally.
    — **Done when:** SKILL.md shows both renderings and states that labeler classification selects the variant.
    — **Consumers affected:** agent ticket creation on both platforms; Jira REST fallback path.
- [ ] **3.3** Add agent behavior rules + ticket-vs-plan boundary to SKILL.md: never invent field values; headless/CI fallback (proceed only if all required fields came in the request, else fail naming gaps); boundary rules (ticket executable without discussion context; every plan references exactly one ticket ID; Technical Notes moves to the PLAN)
    — **Why:** The boundary rules are the contract that keeps this skill upstream of plan generation (worktree-pipeline); headless fallback prevents stalls in non-interactive runs.
    — **Done when:** SKILL.md states both boundary rules verbatim and the headless fallback.
    — **Consumers affected:** `worktree-pipeline-skill` (consumes ticket refs); plan authoring skills.

### Phase 4: Setup skill scaffold offer

- [ ] **4.1** Add detection row to `skills/opencode-repo-setup-skill/SKILL.md` Step 1: GitHub remote or `.github/` present + `.github/ISSUE_TEMPLATE/` absent → offer scaffold
    — **Why:** Detection drives the menu; without the signal the offer never fires.
    — **Done when:** Row present in the Step 1 table.
    — **Consumers affected:** setup flow in target repos.
- [ ] **4.2** Add extras offer + Step 3 write sub-step: copy `bug_report.yml`, `feature_request.yml`, `config.yml` from the installed ticket-creation-skill `templates/` dir into `<repo>/.github/ISSUE_TEMPLATE/`; create-if-absent only — existing files are skipped and reported, never overwritten
    — **Why:** Distributes the forms to every repo where setup runs; idempotency respects repos that already maintain their own community health files.
    — **Done when:** SKILL.md documents the copy command, the skip-if-present rule, the source path, and the per-skill-install fallback: source templates dir absent → skip the offer with a note (mirrors the CodeGraph soft-skip).
    — **Consumers affected:** target repos' `.github/ISSUE_TEMPLATE/`; distribution channels.
- [ ] **4.3** Add Step 5 report line (files written, revert = delete dir) + Jira rule block `<!-- opencode:jira-templates -->` offering Jira description templates appended to target-repo AGENTS.md on accept
    — **Why:** Setup skill reports all writes (existing convention); Jira has no repo-file equivalent, so the rule block is the symmetric application path.
    — **Done when:** Report bullet added; rule block with marker documented alongside CodeGraph/LSP blocks.
    — **Consumers affected:** target repos' AGENTS.md; Jira-facing agent flows.

### Phase 5: Registry sync + verification gates

- [ ] **5.1** Run `node installer/build-registry.mjs`; commit regenerated `registry.json` if changed
    — **Why:** Repo contract: any SKILL.md edit must be followed by a registry rebuild and commit.
    — **Done when:** Command exits 0; `git status` shows `registry.json` either unchanged or committed.
    — **Consumers affected:** `installer/init.mjs` registry consumers.
- [ ] **5.2** Write `tests/test_issue_template_byte_identity.bats` pinning `cmp -s` on the 3 file pairs (repo-level `.github/ISSUE_TEMPLATE/*.yml` vs `skills/ticket-creation-skill/templates/*.yml`)
    — **Why:** Review finding W2: byte-identity verified only by a one-time `cmp` decays silently on the next edit to either copy; the repo idiom (LEARNINGS: bats-structure-pin) pins load-bearing invariants in bats.
    — **Done when:** Test file exists and every pair assertion passes in 5.3's run.
    — **Consumers affected:** future edits to either copy of the forms (regression net).
- [ ] **5.3** Run the bats test suite (`bats tests/`)
    — **Why:** Skill-structure and count validators must pass after new files appear inside a skill dir; the new byte-identity pin rides the same run.
    — **Done when:** All bats tests exit 0.
    — **Consumers affected:** none (verification only).
- [ ] **5.4** Tick the acceptance-criteria checkboxes on GitHub issue #417 body via `gh issue edit`
    — **Done when:** `gh issue view 417` shows all 6 checkboxes ticked.
    — **Why:** The ticket is the artifact of record; its AC must reflect verified completion before PR merge.
    — **Consumers affected:** issue #417 readers/reviewers.

## Technical Notes

Ticket carries none by design (ticket-vs-plan boundary rule). Plan-owned implementation notes:

- Do NOT parse the YAML forms at agent runtime to derive required fields — keep the field spec in SKILL.md and sync labels by verbatim match (LEARNINGS: hand-rolled YAML parsers fail on shapes richer than anticipated).
- No frontmatter changes to either SKILL.md (descriptions/triggers unchanged) → registry output should be unchanged; rebuild anyway per contract.
- Distribution channels need no code changes: the deploy path delegates content installs to `installer/init.mjs add --all`, and every copy path is recursive (verified `installer/init.mjs:397,676,836,969`; registry enumerates top-level skill dirs only, so a `templates/` subdir is invisible to it).

## Dependencies

None external; no `blocked-by:` tickets.

## Risks & Mitigation

- **Label drift between SKILL.md tables and YAML forms** → mitigated by verbatim-match check in 3.1's Done-when and byte-identity copies in Phase 2.
- **Test suite asserts skill-dir contents** (structure validators may not expect a `templates/` subdir) → 5.2 catches; if a structure pin fails, extend the validator's allowlist rather than dropping the files.
- **`config.yml` disables blank issues repo-wide** → intentional (maintainers retain the blank-issue option per GitHub semantics).
