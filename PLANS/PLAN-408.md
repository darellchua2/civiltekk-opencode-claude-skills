# PLAN: Consolidate plan execution skills into one skill with modes

**Branch**: feat/408
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/408
**Base**: main

## Acceptance Criteria
- [x] One execution skill directory remains (`skills/plan-execution-skill/`); directory name equals skill name
- [x] All three former entry points map to a documented mode: `--soft` (old plan-execution), `--gate` (old plan-automation-loop; default for `/run-plan`), `--update` (old plan-updater); description ≤50 words preserving triggers (`run-plan`, `execute plan`, `automation loop`, `implement PLAN-*.md`, `update plan progress`)
- [x] Updater semantics preserved: rationale triple kept verbatim on `[ ]`→`[x]`; branch patterns `GIT-123`/`issue-123`/`123`/`PROJECT-123`; PLAN naming table; graceful skip; malformed-step flag primitive (warning-only); progress log; semantic commit
- [x] Gate semantics preserved: defers to `verification-loop-skill` §The gate contract (#409 dedup — do not re-inline); gate memo `GATE <short-sha> lint=t typecheck=t build=t unit=t e2e=<t|-|n.a>`; fix-on-fail ≤3/step, ≤20 total; never push red; one atomic commit + push per phase; `— Done:`/`fixes:` traceability; zero unchecked boxes per phase; HALT terminal + `[goal:*]` markers; guardrails table; idempotent; E2E rule
- [x] Protocol pins intact: `## Iteration Protocol (opt-in)` heading; `metadata.protocol: autoresearch-opt-in`; citation union `iteration-safety` + `stuck-detection` + `evaluator-contract` (gate override subsection folded in)
- [x] `skills/plan-updater-skill/` and `skills/plan-automation-loop-skill/` deleted; zero live references — CHANGELOG, LEARNINGS, PLANS/, and README migration-history lines exempt
- [x] `/run-plan` command template re-pointed to the survivor (opencode.json `template`), keeping the description's `/goal` mention (docker-compose.yml:29 comment reads it)
- [x] Agent frontmatter AND body prose: zero deleted-name strings anywhere in `agents/*.md`; 4 `plan-updater-skill` allows re-pointed (repo-ops deduped)
- [x] Sync surfaces: lean 46→**44** (both deleted keys are lean members) + `tests/skill_profiles.bats` six-site re-pin to 44; `opencode_app/opencode.json` skill allows 104→102 + `/run-plan` template; `installer/presets/pack-devops.json`; stale prose literals re-derived (setup.sh:3240 + setup.ps1:1900 + README:397/400: "48 primary-visible"→44, "107 allows"→102); README counts 148→146 (root ×3 + `opencode_app/README.md:30`) + Git/Workflow row + history line; `installer/registry.json` regenerated
- [x] `bats tests/` suite passes

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/plan-execution-skill/SKILL.md` (survivor) | — | `/run-plan` template (opencode.json:605, re-pointed); `worktree-pipeline-skill` (Step 8); `verification-loop-skill:47,65`; `tests/test_autoresearch_protocol.bats:210-233` (path/frontmatter/heading pins); `tests/test_default_behavior.bats` (comment cites); `agents/repo-ops-specialist-subagent.md:89` (existing allow); lean profile; opencode.json allows; pack-devops; registry; README | med |
| `skills/plan-updater-skill/` (delete) | — | lean profile:37 (→44 + bats re-pin); 4 agent frontmatter allows (pr-workflow:60, repo-ops:86, tdd:36, testing:57) + body prose (tdd:98, pr-workflow:159,168, repo-ops:167); opencode.json:220; pack-devops:34; registry; cross-skills (verification-loop:65, strategic-compact:71, documentation-consistency:30); README | med |
| `skills/plan-automation-loop-skill/` (delete) | plan-execution name | lean profile:35 (→44); opencode.json:605 template + allow :215; worktree-pipeline ×3 (20, 48, 118); verification-loop:47; tdd-workflow:30; language-linting:31; registry; README | high |
| `installer/registry.json` | build-registry.mjs + `skills/*` | installer `add`, presets, CI `--check` | med |
| `README.md` + `opencode_app/README.md` + setup-script comments | `skills/` listing (BT-157); count-guarded by bats | doc-consistency, CI, new deployers | med |
| `skills/grilling-skill/SKILL.md:104` | name-agnostic emitter prose (sharpened by 1.2) | `--plan` users | low |
| `deploy/setup.sh` / `setup.ps1` `count_skills()` | dynamic | auto-satisfied by 3.1; comment literals owned by 2.2 | low |

## Implementation Phases

### Phase 1: Consolidate skill content
- [x] **1.1** Rewrite `skills/plan-execution-skill/SKILL.md`: keep frontmatter keys (`name`, `license: Apache-2.0`, `compatibility: opencode`, `metadata.protocol: autoresearch-opt-in`, `category: Git/Workflow`); description ≤50 words preserving all five triggers; Modes section with supersede clause — `--soft` (existing Core Workflow Steps 0-7), `--gate` (automation-loop phase loop: plan resolution, gate discovery deferring to `verification-loop-skill` §The gate contract, clean baseline, 4a-4h incl. memo line, delegate matrix with #409's read-only code-review fix, E2E rule, traceability, commit+push, guardrails table, completion markers, stop conditions), `--update` (updater Steps 1-6: branch patterns, naming table, verbatim-triple checkbox rules, malformed-step flag primitive, progress log, semantic commit, graceful skip, error handling). Iteration Protocol merge rule: ONE `## Iteration Protocol (opt-in)` heading; citation union `iteration-safety` + `stuck-detection` + `evaluator-contract`; fold in the gate skill's Skill-specific override subsection. Remove every `plan-updater-skill`/`plan-automation-loop-skill` string
    — **Why:** the survivor must become the single execution entry before the siblings are deleted, or `/run-plan`, agent allows, and cross-skill pointers orphan
    — **Done when:** three modes documented + supersede clause; zero deleted-name strings; description ≤50 words, five triggers present; `## Iteration Protocol (opt-in)` + `metadata.protocol` + all three citation paths intact; verbatim-triple rule + malformed-step primitive present; memo line, fix bounds, marker protocol present
    — **Consumers affected:** `/run-plan` users, worktree-pipeline Step 8, verification-loop gate-memo row, 4 re-pointed agents, registry (3.2), README (2.4)
    — **Done:** modes merged (--soft steps 0-7, --gate 4a-4h loop, --update steps 1-6); Iteration Protocol heading + metadata.protocol + citation union (iteration-safety/stuck-detection/evaluator-contract); 41-word description, five triggers; zero sibling-name strings; files: skills/plan-execution-skill/SKILL.md; fixes: none
- [x] **1.2** Sharpen `skills/grilling-skill/SKILL.md:104`: name the survivor explicitly — "the canonical contract `plan-execution-skill` parses (`--soft`/`--gate`)" replacing "the execution skills parse"
    — **Why:** post-consolidation there is exactly one parser; the name-agnostic phrasing hides the mode mapping (reviewer W3: step was a no-op as originally drafted — this is the real sharpening)
    — **Done when:** line names `plan-execution-skill`; zero deleted-name strings in the file
    — **Consumers affected:** `--plan` emitter users
    — **Done:** emitter prose names plan-execution-skill (--soft/--gate); files: skills/grilling-skill/SKILL.md; fixes: none

### Phase 2: Reference and allowlist sweep (deleted dirs still present — harmless)
- [x] **2.1** Re-point 4 agent frontmatter allows `plan-updater-skill` → `plan-execution-skill`: `agents/pr-workflow-subagent.md:60`, `agents/repo-ops-specialist-subagent.md:86` (dedupe with existing :89 — keep one), `agents/tdd-subagent.md:36`, `agents/testing-subagent.md:57`; fix body prose too: `agents/tdd-subagent.md:98`, `agents/pr-workflow-subagent.md:159,168`, `agents/repo-ops-specialist-subagent.md:167`
    — **Why:** dead allows break subagent PLAN-sync at merge instant; body prose would trip the 4.1 fragment sweep unowned
    — **Done when:** zero deleted-name strings anywhere in `agents/*.md` (resources and prose); repo-ops has exactly one `plan-execution-skill` allow
    — **Consumers affected:** the 4 subagents' PLAN-update behavior
    — **Done:** 4 allows re-pointed (pr-workflow:60, tdd:36, testing:57) + repo-ops deduped (updater block removed, execution kept); body prose fixed (tdd:98, pr-workflow:159,168, testing:123, pr-workflow:168); agents/*.md zero sibling strings; files: agents/pr-workflow-subagent.md agents/repo-ops-specialist-subagent.md agents/tdd-subagent.md agents/testing-subagent.md; fixes: none
- [x] **2.2** Update allowlists and pinned literals: `deploy/skill-profiles.json` remove BOTH `plan-updater-skill` (:37) AND `plan-automation-loop-skill` (:35) — both are lean members; keep `plan-execution-skill` → lean 44. Re-pin `tests/skill_profiles.bats` six sites 46→44 (headers ×2, test names ×2, `-eq` assertion, `"44 deny-ok non-skill-ok"`). `opencode_app/opencode.json`: remove the two deleted-skill allow rules (:215, :220) → 104→102 skill allows. `installer/presets/pack-devops.json:34` remove `plan-updater-skill`. Re-derive stale prose literals: `deploy/setup.sh:3240` and `deploy/setup.ps1:1900` "48 primary-visible skills" → 44; `README.md` "107 allows" → 102 and "48 primary-visible" → 44 (both :397-region lines). Do NOT backfill
    — **Why:** profile membership verified on disk (both keys at :35,:37) — keeping either makes the disk-match bats test fail at 3.1; the prose literals are the third recurrence of `new-skill-count-literal-gates` — own them with disk+delta values
    — **Done when:** JSON ×3 valid; lean = 44 with exactly one `plan-execution-skill` and zero deleted names; `grep -nE '\b46\b' tests/skill_profiles.bats` empty; setup.sh/setup.ps1/README prose say 44 and 102
    — **Consumers affected:** `setup.sh --skill-profile`, CI release workflow, Docker runtime, devops preset users, new deployers reading the picker-size promise
    — **Done:** lean 46→44 (BOTH keys were lean members — B1 verified at :35,:37); bats six sites 44; allows 104→102; pack-devops updater removed; prose literals 44/102 (setup.sh:3240, setup.ps1:1900, README ×3); JSON ×3 valid; files: deploy/skill-profiles.json tests/skill_profiles.bats opencode_app/opencode.json installer/presets/pack-devops.json deploy/setup.sh deploy/setup.ps1 README.md; fixes: none
- [x] **2.3** Update cross-skill pointers: `skills/worktree-pipeline-skill/SKILL.md` ×3 (20, 48, 118 — `plan-automation-loop-skill` → `plan-execution-skill --gate`); `skills/verification-loop-skill/SKILL.md:47` (memo row → survivor `--gate`) + `:65` (→ `--update`); `skills/strategic-compact-skill/SKILL.md:71`; `skills/tdd-workflow-skill/SKILL.md:30`; `skills/language-linting-skill/SKILL.md:31`; `skills/documentation-consistency-skill/SKILL.md:30`
    — **Why:** six live cross-skill pointers would name deleted skills
    — **Done when:** all six files zero deleted-name strings
    — **Consumers affected:** readers/users of those skills
    — **Done:** six cross-skill pointers re-pointed (worktree-pipeline ×3 → --gate, verification-loop:47,65 → --gate/--update, strategic-compact:71, tdd-workflow:30, language-linting:31, documentation-consistency:30); files: skills/{worktree-pipeline,verification-loop,strategic-compact,tdd-workflow,language-linting,documentation-consistency}-skill/SKILL.md; fixes: none
- [x] **2.4** Update `README.md`: 148→146 at three count sites (:15 tree, :250 `34 agents +`, :409 `All 148`); Git/Workflow category row (:582) — drop the two deleted names, count (16)→(14); append migration-history note `Post-#408: −2 execution siblings (`plan-updater-skill`, `plan-automation-loop-skill` merged into `plan-execution-skill` modes `--update`/`--gate`) → 146`. Update `opencode_app/README.md:30` 148→146
    — **Why:** BT-157 hand-maintained counts; both READMEs count-guarded by bats
    — **Done when:** no 148 skill-count hits in either README; Git/Workflow row count matches cell
    — **Consumers affected:** README readers, doc-consistency, CI
    — **Done:** README 148→146 ×3 + opencode_app/README:30 + Git/Workflow row (16)→(14) + Post-#408 history line; no stale 148 count sites; files: README.md opencode_app/README.md; fixes: none
- [x] **2.5** Re-point the `/run-plan` command template `opencode_app/opencode.json:605`: `"Load the skill \`plan-execution-skill\` in --gate mode and run it to fully implement the plan file given as the argument: $ARGUMENTS"`; keep the :604 description untouched (its `/goal` mention is load-bearing for the `docker-compose.yml:29` healthcheck comment)
    — **Why:** the template hard-loads a deleted skill — `/run-plan` breaks at merge instant without this; the ticket's headline `--gate` mapping lives here
    — **Done when:** template names `plan-execution-skill`; :604 description unchanged; JSON valid
    — **Consumers affected:** every `/run-plan` user; Docker healthcheck docs
    — **Done:** /run-plan template → plan-execution-skill --gate; :594 description /goal mention kept; JSON valid; files: opencode_app/opencode.json; fixes: none

### Phase 3: Deletion, registry (land together — no red intermediate commit)
- [x] **3.1** `git rm -r skills/plan-updater-skill skills/plan-automation-loop-skill`
    — **Why:** fully absorbed into survivor modes; bundled with counts + registry for a green phase commit (#407/#409 precedent)
    — **Done when:** both directories absent from `git ls-files`
    — **Consumers affected:** all swept in Phase 2
    — **Done:** git rm of both sibling dirs; absent from git ls-files; files: skills/plan-updater-skill/ skills/plan-automation-loop-skill/ (deleted); fixes: none
- [x] **3.2** Run `node installer/build-registry.mjs` (`agents=34, skills=146`); verify zero deleted names in `installer/registry.json`
    — **Why:** registry is generated — hand edits overwritten
    — **Done when:** build exits 0; grep deleted names in registry → 0
    — **Consumers affected:** installer `add`, presets, CI `--check`
    — **Done:** build-registry regenerated agents=34, skills=146; zero sibling names in registry; files: installer/registry.json; fixes: none

### Phase 4: Verification gate
- [x] **4.1** Repo-wide sweeps: `grep -rn "plan-updater-skill\|plan-automation-loop-skill"` + bare fragments (`plan-updater`, `automation-loop`), excluding `node_modules/`, `.git/`, `_archived/`, `PLANS/`, `CHANGELOG.md`, `LEARNINGS/`, README/PLAN migration-history lines, and this PLAN → zero hits on live surfaces; run `bats tests/test_autoresearch_protocol.bats` plan-execution subset
    — **Why:** AC requires zero live references; README history lines are mandated by 2.4 and exempt (reviewer B3 — sweep must be satisfiable)
    — **Done when:** sweeps empty on live surfaces; protocol subset green
    — **Consumers affected:** none (verification)
    — **Done:** full-name + fragment sweeps clean on live surfaces (exemptions: node_modules/.git/_archived/PLANS/CHANGELOG/LEARNINGS/README history lines); protocol bats subset 83-85 ok; files: none; fixes: none
- [x] **4.2** Run gates: `bats tests/` + `node installer/build-registry.mjs` + JSON validity ×3; commit generated artifacts; working tree clean
    — **Why:** AGENTS.md gate; count/profile guards enforce sync surfaces at merge
    — **Done when:** bats exit 0; registry build exit 0; tree clean after artifact commit
    — **Consumers affected:** CI, Step 9 review, PR checks
    — **Done:** bats tests/ 334 ok exit 0; build-registry exit 0; JSON x3 valid (2.2); tree clean after artifact commit; files: none; fixes: none

## Technical Notes
- Survivor `plan-execution-skill`: path-pinned by `tests/test_autoresearch_protocol.bats`, already allowed in repo-ops, generic lifecycle name. `test_default_behavior.bats` cites are comments — zero edits.
- #409 interplay: gate contract + memo canonical in `verification-loop-skill`; `--gate` defers there. Do not re-inline.
- Profile-membership arithmetic (reviewer B1 + proposed learning): before writing N−k targets, grep which profile arrays actually contain each removed key — `deploy/skill-profiles.json` held BOTH deleted skills, so the correct target is 44, not 45.
- Literal-count class: six-site bats re-pin (46→44); prose literals in setup scripts + README owned this time (third recurrence of `new-skill-count-literal-gates`).
- The `--plan` emitter contract targets this skill's parser; PLAN-407 structure is the fixture.
- This PLAN dogfoods the emitter contract.

## Dependencies
None external. #407 merged (PR #420) — its emitter prose sharpened by 1.2. #409 merged — deferral preserved by 1.1.

## Risks & Mitigation
- *Registry drift* → regenerate only (3.2).
- *Count drift* → all sites updated together (2.2, 2.4); pinned bats verify.
- *Lean orphaning* → survivor keeps lean slot; profile tests fail closed.
- *Lost triggers* → description diff-checked against both deleted descriptions in 1.1.
- *Protocol regression* → 1.1 pins heading/metadata/citations; 4.1 runs the subset.
- *Red intermediates* → Phase 3 bundles deletion + counts + registry.
- *repo-ops duplicate allow* → 2.1 dedupes.
- *Unsatisfiable sweep* → exemptions fixed per B3 (README history lines).
