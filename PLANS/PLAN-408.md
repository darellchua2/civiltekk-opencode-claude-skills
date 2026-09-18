# PLAN: Consolidate plan execution skills into one skill with modes

**Branch**: feat/408
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/408
**Base**: main

## Acceptance Criteria
- [ ] One execution skill directory remains (`skills/plan-execution-skill/`); directory name equals skill name
- [ ] All three former entry points map to a documented mode: `--soft` (old plan-execution), `--gate` (old plan-automation-loop; default for `/run-plan`), `--update` (old plan-updater); description ≤50 words preserving triggers (`run-plan`, `execute plan`, `automation loop`, `implement PLAN-*.md`, `update plan progress`)
- [ ] Updater semantics preserved: rationale triple (`**Why:**` / `**Done when:**` / `**Consumers affected:**`) kept verbatim on `[ ]`→`[x]`; branch patterns `GIT-123`/`issue-123`/`123`/`PROJECT-123`; PLAN naming table; graceful skip; malformed-step flag primitive (warning-only, no auto-rewrite); progress log; semantic commit
- [ ] Gate semantics preserved: verification gate defers to `verification-loop-skill` §The gate contract (#409 dedup respected — do not re-inline); gate memo line `GATE <short-sha> lint=t typecheck=t build=t unit=t e2e=<t|-|n.a>`; fix-on-fail ≤3 per step, ≤20 total; never push red code; one atomic commit + push per phase; `— Done:` + `fixes:` traceability; completed phase = zero unchecked boxes; HALT terminal + `[goal:evidence]`/`[goal:complete]`/`[goal:blocked]` markers; guardrails table (12 phases / 20 fixes / protected branch); idempotent re-runs; E2E rule
- [ ] Protocol test pins intact: `## Iteration Protocol (opt-in)` heading present; `metadata.protocol: autoresearch-opt-in`; cites `autoresearch-core-skill/references/evaluator-contract.md` + `stuck-detection.md` (tests/test_autoresearch_protocol.bats:210-231)
- [ ] `skills/plan-updater-skill/` and `skills/plan-automation-loop-skill/` deleted; zero live references (agents frontmatter, allowlists, presets, registry, cross-skill pointers) — CHANGELOG, LEARNINGS, and PLANS/ history exempt
- [ ] Agent frontmatter: 4 `plan-updater-skill` allows re-pointed to `plan-execution-skill` (pr-workflow, repo-ops, tdd, testing subagents)
- [ ] Sync surfaces: lean profile 46→45 + `tests/skill_profiles.bats` six-site re-pin; `opencode_app/opencode.json` allowlist; `installer/presets/pack-devops.json`; README counts 148→146 (root ×3 + `opencode_app/README.md:30`) + Git/Workflow category row + migration-history line; `installer/registry.json` regenerated
- [ ] `bats tests/` suite passes

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/plan-execution-skill/SKILL.md` (survivor) | — | `/run-plan` invocations; `worktree-pipeline-skill` (Step 8 executor); `verification-loop-skill` (gate memo writer row); `tests/test_autoresearch_protocol.bats:210-231` (path + frontmatter + heading pins); `tests/test_default_behavior.bats` (comment cites — name survives, zero edits); `agents/repo-ops-specialist-subagent.md` (existing allow); lean profile; `opencode_app/opencode.json`; `installer/presets/pack-devops.json`; registry; README | med |
| `skills/plan-updater-skill/` (delete) | — | 4 agent frontmatter allows (pr-workflow:60, repo-ops:86, tdd:36, testing:57); lean profile (46→45 + bats re-pin); `opencode_app/opencode.json:220`; `installer/presets/pack-devops.json:34`; registry; cross-skill refs (verification-loop:65, strategic-compact:71, documentation-consistency:30); README | med |
| `skills/plan-automation-loop-skill/` (delete) | plan-execution name (composes it) | `worktree-pipeline-skill` ×3 (lines 20, 48, 118); `verification-loop-skill:47`; `tdd-workflow-skill:30`; `language-linting-skill:31`; `opencode_app/opencode.json`; registry; README; shipped-only allowlist entry | med |
| `installer/registry.json` | `installer/build-registry.mjs` + `skills/*` | installer `add`, presets, CI drift `--check` | med |
| `README.md` + `opencode_app/README.md` | `skills/` listing (BT-157 hand-maintained; count-guarded by bats) | doc-consistency, CI | med |
| `skills/grilling-skill/SKILL.md` | names both deleted skills in `--plan` emitter prose (#407 output) | readers | low |
| `deploy/setup.sh` / `setup.ps1` counts | dynamic (`count_skills()`), drift-guarded by `test_count_drift.bats` | none to edit — auto-satisfied by 3.1 | low |

## Implementation Phases

### Phase 1: Consolidate skill content
- [ ] **1.1** Rewrite `skills/plan-execution-skill/SKILL.md`: keep frontmatter keys (`name: plan-execution-skill`, `license: Apache-2.0`, `compatibility: opencode`, `metadata.protocol: autoresearch-opt-in`, `category: Git/Workflow`); rewrite description ≤50 words preserving all five triggers; add a Modes section that explicitly supersedes restatements — `--soft` (the existing Core Workflow Steps 0-7: verbatim playbook discipline, branch detection, parse, awk current-state, execute+delegate, per-phase auto-update, final validation, report), `--gate` (the automation-loop phase loop: resolve plan, gate discovery deferring to `verification-loop-skill` §The gate contract, clean baseline, 4a-4h loop incl. memo line, delegate matrix, E2E rule, traceability `— Done:`/`fixes:`, commit+push, guardrails table, completion markers, stop conditions), `--update` (updater Steps 1-6: branch patterns `GIT-123`/`issue-123`/`123`/`PROJECT-123`, PLAN naming table, checkbox rules with verbatim-triple preservation, malformed-step flag primitive, progress log, semantic commit, graceful skip, error handling); keep the `## Iteration Protocol (opt-in)` block verbatim with its citations; remove every `plan-updater-skill` / `plan-automation-loop-skill` string
    — **Why:** the survivor must become the single execution entry before the siblings are deleted, or `/run-plan`, agent allows, and the cross-skill pointers orphan
    — **Done when:** Modes documented for all three invocations with the supersede clause; zero `plan-updater-skill`/`plan-automation-loop-skill` strings; description ≤50 words with all five triggers; `## Iteration Protocol (opt-in)` heading + `metadata.protocol` + both autoresearch citations intact (test-pinned); updater's verbatim-triple rule and malformed-step primitive present; gate's memo line, fix bounds, and marker protocol present
    — **Consumers affected:** `/run-plan` users, `worktree-pipeline-skill` Step 8, `verification-loop-skill` gate-memo row, 4 re-pointed agents, registry (3.2), README (2.4)
- [ ] **1.2** Update `skills/grilling-skill/SKILL.md` `--plan` emitter prose: `plan-automation-loop-skill` parses → `plan-execution-skill --gate` parses; `plan-updater` flips → `plan-execution-skill --update` flips
    — **Why:** #407's fresh output references the deleted names; stale on arrival otherwise
    — **Done when:** zero deleted-name strings in the file
    — **Consumers affected:** `--plan` emitter users

### Phase 2: Reference and allowlist sweep (deleted dirs still present — harmless)
- [ ] **2.1** Re-point 4 agent frontmatter allows `plan-updater-skill` → `plan-execution-skill`: `agents/pr-workflow-subagent.md:60`, `agents/repo-ops-specialist-subagent.md:86`, `agents/tdd-subagent.md:36`, `agents/testing-subagent.md:57`; dedupe the repo-ops duplicate allow (it already allows `plan-execution-skill` at line 89 — keep one)
    — **Why:** deleted skills in `permissions.resource` are dead allows; subagents lose PLAN-sync ability at merge instant otherwise
    — **Done when:** zero `plan-updater-skill`/`plan-automation-loop-skill` resources across `agents/*.md`; repo-ops has exactly one `plan-execution-skill` allow
    — **Consumers affected:** the 4 subagents' PLAN-update behavior
- [ ] **2.2** Update allowlists: `deploy/skill-profiles.json` remove `plan-updater-skill` (lean 46→45; `plan-automation-loop-skill` is shipped-only — remove from its list too) keeping `plan-execution-skill`; `tests/skill_profiles.bats` re-pin 46→45 at all six sites (header comments ×2, test names ×2, count assertion, `45 deny-ok non-skill-ok` output); `opencode_app/opencode.json` remove the two deleted-skill allows; `installer/presets/pack-devops.json` remove `plan-updater-skill`. Do NOT backfill
    — **Why:** dead config + pinned lean count is a deliberate change-detector; #407 precedent (six literal sites)
    — **Done when:** JSON ×3 valid; zero deleted names in all three; `grilling`-style grep: lean has 45 keys with exactly one `plan-execution-skill`; `grep -nE '\b46\b' tests/skill_profiles.bats` empty
    — **Consumers affected:** `setup.sh --skill-profile lean|full`; CI release workflow; Docker runtime; devops preset users
- [ ] **2.3** Update cross-skill pointers: `skills/worktree-pipeline-skill/SKILL.md` ×3 (`plan-automation-loop-skill` → `plan-execution-skill --gate`); `skills/verification-loop-skill/SKILL.md:47` (gate-memo row) + `:65` (plan-updater → `--update`); `skills/strategic-compact-skill/SKILL.md:71`; `skills/tdd-workflow-skill/SKILL.md:30`; `skills/language-linting-skill/SKILL.md:31`; `skills/documentation-consistency-skill/SKILL.md:30`
    — **Why:** the six live cross-skill pointers would name deleted skills
    — **Done when:** all six files contain zero deleted-name strings
    — **Consumers affected:** readers/users of those skills
- [ ] **2.4** Update `README.md`: 148→146 at the three count sites (file tree, `34 agents +` line, `All 148 skills`); Git/Workflow category row — drop the two deleted names, fix the per-category count; append migration-history note `Post-#408: −2 execution siblings (`plan-updater-skill`, `plan-automation-loop-skill` merged into `plan-execution-skill` modes `--update`/`--gate`) → 146`. Update `opencode_app/README.md` count site 148→146
    — **Why:** BT-157 hand-maintained counts; both READMEs count-guarded by bats
    — **Done when:** no 148 skill-count hits remain in either README; Git/Workflow row count matches its cell
    — **Consumers affected:** README readers, doc-consistency checks, CI

### Phase 3: Deletion, registry (land together — no red intermediate commit)
- [ ] **3.1** `git rm -r skills/plan-updater-skill skills/plan-automation-loop-skill`
    — **Why:** both fully absorbed into survivor modes; #407 precedent — deletion bundled with counts + registry so the phase commit is green
    — **Done when:** both directories absent from `git ls-files`
    — **Consumers affected:** all swept in Phase 2
- [ ] **3.2** Run `node installer/build-registry.mjs` (regen; `agents=34, skills=146`) and verify zero deleted names in `installer/registry.json`
    — **Why:** registry is generated — hand edits overwritten; AC requires regeneration + commit
    — **Done when:** build exits 0; grep of deleted names in registry → 0
    — **Consumers affected:** installer `add`, presets, CI `--check`

### Phase 4: Verification gate
- [ ] **4.1** Repo-wide sweeps: `grep -rn "plan-updater-skill\|plan-automation-loop-skill"` excluding `node_modules/`, `.git/`, `_archived/`, `PLANS/`, `CHANGELOG.md`, `LEARNINGS/`, and this PLAN → zero hits; bare fragments (`plan-updater`, `automation-loop`) likewise; confirm `bats tests/test_autoresearch_protocol.bats` plan-execution pins pass unchanged
    — **Why:** AC requires zero live references; historical records exempt per #407 precedent; path-pinned tests must stay green
    — **Done when:** sweeps empty on live surfaces; protocol bats subset green
    — **Consumers affected:** none (verification)
- [ ] **4.2** Run gates: `bats tests/` (full suite) + `node installer/build-registry.mjs` (or `--check` where supported) + JSON validity ×3; commit generated artifacts; working tree clean
    — **Why:** AGENTS.md gate; count-guard and profile-guard bats suites enforce the sync surfaces on merge
    — **Done when:** bats exit 0; registry build exit 0; `git status` clean after artifact commit
    — **Consumers affected:** CI, Step 9 review, PR checks

## Technical Notes
- Survivor `plan-execution-skill` chosen: path-pinned by `tests/test_autoresearch_protocol.bats` (3 assertions on `$SKILLS_DIR/plan-execution-skill/SKILL.md`), already allow-listed in `agents/repo-ops-specialist-subagent.md`, generic lifecycle name. `test_default_behavior.bats` cites are comments — no edits.
- #409 interplay: gate contract + memo live canonically in `verification-loop-skill`; the `--gate` mode defers there (one pointer), preserving that dedup. Do NOT copy gate sequencing back inline.
- The `--plan` emitter contract (`grilling-skill`) targets this skill's parser: `^### Phase`, `- [ ] **N.M**`, `[x]`, rationale triple — PLAN-407's structure is the fixture this skill's parse rules describe.
- Delegate matrix carries #409's fix: refactor/DRY handled directly (`code-review-subagent` is read-only).
- Literal-count test class: `skill_profiles.bats` six-site re-pin (46→45); both READMEs count-guarded — sweep `grep -rn 'skill director\|lean has exactly\|deny-ok' tests/` before finishing.
- This PLAN dogfoods the `--plan` emitter contract.

## Dependencies
None external. #407 merged (PR #420) — its `--plan` emitter prose is updated by 1.2. #409 merged — its verification-loop deferral is preserved by 1.1.

## Risks & Mitigation
- *Registry drift* → regenerate only (3.2).
- *Count drift* → all count sites updated together (2.4); pinned bats tests verify.
- *Lean orphaning* → survivor keeps its lean slot (2.2); profile tests fail closed on missing keys.
- *Lost triggers* → description diff-checked against both deleted skills' descriptions in 1.1 self-review.
- *Protocol test regression* → 1.1 Done-when pins the three tested properties; 4.1 runs the protocol bats subset.
- *Red intermediate commits* → deletion + counts + registry bundled in Phase 3.
- *Duplicate allow in repo-ops* → 2.1 dedupes.
