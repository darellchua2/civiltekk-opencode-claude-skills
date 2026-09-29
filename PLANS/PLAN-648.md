# PLAN: Start ticket transition — In Progress at worktree creation

**Branch**: feat/648
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/648
**Base**: main

## Acceptance Criteria
- [ ] AC1 — `ticketing-skill` SKILL.md documents a Start lifecycle op with a check-first idempotency guard; `references/jira.md` §Transitions defines the in-progress target selection
- [ ] AC2 — `worktree-pipeline-skill` Step 4 transitions tracker tickets to In Progress after worktree creation; JIRA-unavailable degrades with a report (MCP Availability Guard), GitHub issues no-op with a note
- [ ] AC3 — `--dry-run` and `/worktree-pipeline-preview` perform no transitions (read-only contract intact)
- [ ] AC4 — Failed/deferred tickets may legitimately remain In Progress — documented as honest state
- [ ] AC5 — Guard tests updated where they pin Step 4 or the lifecycle op list (none currently pin — verified 2026-09-29; sweep confirms)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/ticketing-skill/SKILL.md` | — | `skills/worktree-pipeline-skill/SKILL.md` Step 4 (new §Start call), runtime agent lifecycle routing, `README.md` Git/Workflow row, `installer/registry.json` (frontmatter description extraction), `skills/ticketing-skill/README.md` flow | low |
| `skills/ticketing-skill/references/jira.md` | `skills/ticketing-skill/SKILL.md` §Start (method placement) | `skills/ticketing-skill/SKILL.md` §Start (values load rule), §Close (existing transitions section) | low |
| `skills/worktree-pipeline-skill/SKILL.md` (Step 4) | `skills/ticketing-skill/SKILL.md` §Start | `/run-worktree-pipeline` + `/run-worktree-pipeline-v2` runtime, `tests/test_v2_pipeline_contract.bats` (pins v2 key, not Step 4 prose) | medium |
| `README.md` (Git/Workflow category row) | both SKILL.md docs | docs readers (no count change — no skill added/removed) | low |
| `installer/build-registry.mjs` | `skills/ticketing-skill/SKILL.md` frontmatter description | produces `installer/registry.json` (not edited here) | low |
| `installer/registry.json` | `installer/build-registry.mjs` (producer) | `installer/init.mjs` (registry-only reads) | low |
| `agents/repo-ops-specialist-subagent.md` (line 133) | `skills/ticketing-skill/SKILL.md` lifecycle list | repo-ops agent runtime guidance | low |

## Implementation Phases

### Phase 1: ticketing-skill Start op
- [x] **1.1** Add a `### Start (execution begins)` section between Classify/Label and Update in `skills/ticketing-skill/SKILL.md`: check current status first (in-progress-or-later → skip, mirroring §Close's transition-once guard), transition to the in-progress-category target per the side file; GitHub = no-op with a note (issues have no status field; `Closes #N` covers close-on-merge); one line documenting failed/deferred tickets legitimately remaining In Progress (AC4)
    — **Why:** The Start op is the method home every consumer routes through; placing it before §Update matches chronological lifecycle order (create → classify → start → update → close).
    — **Done when:** `grep -n "### Start" skills/ticketing-skill/SKILL.md` resolves; the section contains the check-first guard, GitHub no-op, and the honest-state line; the §Lifecycle routing line (line ~22) reads `create · classify/label · start · update · close · git plumbing`.
    — **Consumers affected:** worktree-pipeline-skill Step 4 (Phase 2), README row (Phase 3), registry (Phase 3).
    — **Done:** §Start section inserted with check-first guard + GitHub no-op + honest-state line; routing line updated; files: `skills/ticketing-skill/SKILL.md`; fixes: none
- [x] **1.2** Update the `description` frontmatter of `skills/ticketing-skill/SKILL.md` to include start (in-progress) in the lifecycle list and the trigger phrases, keeping house style (≤50 words, triggers preserved)
    — **Why:** The frontmatter description is the runtime trigger surface; without it, "start ticket" style invocations don't route to the skill.
    — **Done when:** frontmatter contains `start` in both the lifecycle list and the Triggers line; word count ≤50.
    — **Consumers affected:** `installer/registry.json` (rebuilt in 3.2).
    — **Done:** description carries `start (in-progress)` + `create·start·label·update·close` trigger; 33 words (≤50); files: `skills/ticketing-skill/SKILL.md`; fixes: none
- [x] **1.3** Extend `## Transitions` in `skills/ticketing-skill/references/jira.md` with the start-progress target selection: priority `to.statusCategory.key == "indeterminate"` → any transition whose target is the project's in-progress state (jq example alongside the existing Done selector); note the method (check-first) is SKILL.md §Start
    — **Why:** jira.md carries VALUES only; without a start target rule, callers have no endpoint vocabulary for the new op.
    — **Done when:** the section defines both close and start target selection; existing close content unchanged.
    — **Consumers affected:** none beyond SKILL.md §Start.
    — **Done:** §Transitions retitled with `### Close (done target)` (content unchanged) + `### Start (in-progress target)` with indeterminate-category jq selector; files: `skills/ticketing-skill/references/jira.md`; fixes: none
- [x] **1.4** Add start to the lifecycle restatements in `skills/ticketing-skill/README.md`: the prose lifecycle list (line 4) and the lifecycle flow diagram
    — **Why:** The skill-local README restates the lifecycle in two places; leaving either stale is exactly the documented doc-drift class.
    — **Done when:** both the line-4 prose list and the flow include start between create/classify and update.
    — **Consumers affected:** docs readers.
    — **Done:** prose list + mermaid `|start|` node added between classify and update; files: `skills/ticketing-skill/README.md`; fixes: none

### Phase 2: worktree-pipeline-skill Step 4 wiring
- [ ] **2.1** Add to Step 4 of `skills/worktree-pipeline-skill/SKILL.md`, after the worktree-creation prose: tracker tickets get the `ticketing-skill` §Start transition once the worktree exists; GitHub issues skip with a note (no status field); Atlassian MCP Availability Guard applies — JIRA unavailable → report the transition skipped, never block the run; explicitly state the dry-run/preview read-only contract is untouched (AC2, AC3)
    — **Why:** Step 4 is the "work has physically begun" boundary the ticket names as the In Progress trigger point.
    — **Done when:** Step 4 contains the Start sentence with MCP-guard degrade and GitHub no-op wording; Step 1 `--dry-run` bullet and the preview command template remain unmodified (`git diff` shows no changes outside Step 4's paragraph).
    — **Consumers affected:** both pipeline command arms at runtime (inherit automatically); no template changes.

### Phase 3: downstream consumer sync
- [ ] **3.1** Update the Git/Workflow category row in `README.md` ("the full ticket lifecycle (create/classify/update/close …)") to include start
    — **Why:** README is a registered consumer of the lifecycle wording; directory-scoped sweeps miss root docs (documented anti-pattern).
    — **Done when:** the row mentions start; no count numbers change (120 unchanged — no skill added).
    — **Consumers affected:** docs readers.
- [ ] **3.2** Regenerate `installer/registry.json` (`node installer/build-registry.mjs`) and verify the diff touches only the ticketing-skill entry's description
    — **Why:** House rule — after ANY frontmatter change, registry is rebuilt and committed; a stale registry breaks installer reads.
    — **Done when:** `git diff installer/registry.json` shows only ticketing-skill description text; `node installer/build-registry.mjs` exits 0.
    — **Consumers affected:** `installer/init.mjs`.
- [ ] **3.3** Sweep guard tests for newly-created pins: run `grep -rn "classify/label\|create/classify" tests/` and the isolation/v2 guards; record the AC5 verdict (expected: no pins exist, no test edits needed)
    — **Why:** AC5 is conditional — the sweep is the evidence that the condition stayed false after the edits.
    — **Done when:** sweep output recorded in the step's Done line; zero unexpected test failures.
    — **Consumers affected:** none.
- [ ] **3.4** Update the lifecycle restatement in `agents/repo-ops-specialist-subagent.md` (line 133) to include start, matching the SKILL.md list
    — **Why:** Plan review's restatement sweep found this agent guidance lists the old four-op lifecycle; a stale list leaves the Start op unroutable from repo-ops guidance.
    — **Done when:** line 133's lifecycle list includes start; `grep -rn "create, classify/label" agents/` returns no start-less restatements.
    — **Consumers affected:** repo-ops-specialist-subagent runtime guidance.

### Phase 4: exit verification
- [ ] **4.1** Full verification gate on the final tree: run the repo's guard-test suite scoped to touched areas (`tests/test_skill_isolation.bats`, `tests/test_v2_pipeline_contract.bats`, plus any ticketing-named guard), confirm all green
    — **Why:** Ticket exit gate runs full unconditionally; this is the tier=full memo the PR citation names.
    — **Done when:** all invoked guards exit 0; the `GATE <sha> tier=full` memo line is appended to this PLAN's trace block.
    — **Consumers affected:** Step 10a PR citation.

## Technical Notes
- Insertion anchors (verified on origin/main at b61022d): routing line `skills/ticketing-skill/SKILL.md:22`; §Close at `:180-195` (transition-once guard pattern to mirror); jira.md `## Transitions (post-merge close)` at `:112-120`; Step 4 worktree prose at `skills/worktree-pipeline-skill/SKILL.md:121-147`; Done site `:308-310` (unchanged).
- JIRA start target selection mirrors the close rule's fallback chain; endpoint rows already exist in jira.md (`GET/POST /rest/api/3/issue/{key}/transitions`, lines 49-50) — no new endpoints.
- GitHub truth: issues have no status field; close-on-merge rides `Closes #N` (Step 10a mandates it). Start is JIRA/tracker-only.
- Registry rebuild is order-dependent on 1.2 (frontmatter edit lands first).
- No command-template changes in `deploy/opencode.json` — both pipeline arms load the same skill file.

## Dependencies
None — no blocked-by tickets.

## Risks & Mitigation
- Registry rebuild diffs unrelated entries → verify diff scope in 3.2 before committing; investigate any out-of-scope hunk.
- A guard test pinned to lifecycle wording but not matching the grep → 3.3's sweep plus 4.1's full guard run catches it; AC5 verdict recorded either way.
- Frontmatter description drift beyond 50 words → word-count check in 1.2's Done when.
