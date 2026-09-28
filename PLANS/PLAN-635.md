# PLAN: code-review-inline-skill — thin in-session wrapper for Step 9 code review, rewire /run-worktree-pipeline-v2

**Branch**: feat/635
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/635
**Base**: main

## Acceptance Criteria

- [ ] `skills/code-review-inline-skill/SKILL.md` ships with contract-conformant frontmatter; body pins the no-subagent rule, stop-on-unresolvable-checklist, and the portability binding block (#515)
- [ ] Skill loads `reviewer-baseline-skill` first, then the deployed `agents/code-review-subagent.md` as in-session checklist with resolution paths + stop fallback
- [ ] `dependency-map.json` requiresSkills closure (`reviewer-baseline-skill`, `language-review-checklists-skill`); `registry.json` rebuilt and committed
- [ ] Visibility wired: skill-allow rule in `deploy/opencode.json`, lean entry in `deploy/skill-profiles.json`, `pack-inline-workers` membership + description update
- [ ] `/run-worktree-pipeline-v2` Step 9 invokes the skill; "spawn NO subagents" pin and unconditional-backstop stop rule preserved; `worktree-pipeline-skill` inline-arm preflight + Step 9 note updated
- [ ] `tests/test_v2_pipeline_contract.bats` pins the new routing; new bats test covers the skill; count pins swept (`init.bats`, `setup.sh`, `setup.ps1`, README)
- [ ] Full test suite green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/code-review-inline-skill/SKILL.md` (new) | — | primary session (v2 pipeline Step 9), `installer/build-registry.mjs` → `registry.json`, `installer/presets/pack-inline-workers.json`, new test file | low (new file) |
| `installer/dependency-map.json` | skill dir exists | `installer/init.mjs` dependency resolution, per-skill `add` auto-install | med |
| `installer/registry.json` (generated) | SKILL.md frontmatter | `installer/init.mjs`, `--list`, tests/init.bats count-agnostic pin | med (must regen + commit) |
| `deploy/opencode.json` (permissions + v2 command template) | — | opencode runtime (skill gating, `/run-worktree-pipeline-v2` invocation), `deploy/setup.sh` copy, `tests/test_v2_pipeline_contract.bats`, `tests/test_ships_plugins.bats` | high (command behavior + gating) |
| `deploy/skill-profiles.json` (lean array) | — | `deploy/setup.sh --skill-profile lean`, README:220 count, `tests/skill_profiles.bats` (pins lean count == 68 at lines 41-43, 78) | med |
| `installer/presets/pack-inline-workers.json` | skill dir exists | `installer/init.mjs --preset inline-workers`, membership test in test_v2_pipeline_contract.bats | med |
| `skills/worktree-pipeline-skill/SKILL.md` (preflight + Step 9) | — | every pipeline run (both arms), arm-aware grep pin in test_v2_pipeline_contract.bats | med (shared arm prose — v1 semantics must survive) |
| `tests/test_v2_pipeline_contract.bats` | template change lands first | CI contract guard | low |
| `tests/test_code_review_inline_skill.bats` (new) | SKILL.md + wiring land first | CI | low |
| `README.md` | — | humans, doc-drift audits | low |
| `deploy/setup.sh` (line ~3304 comment) | — | readers of the profile comment | low |

## Implementation Phases

### Phase 1: Skill authoring + metadata wiring

- [x] **1.1** Create `skills/code-review-inline-skill/SKILL.md` — frontmatter: `name: code-review-inline-skill`, description ≤50 words with trigger phrases (inline code review, review diff in-session, pipeline Step 9 inline review), `license: Apache-2.0`, `compatibility: opencode`, `metadata: {mirrors: code-review-subagent}`, `category: Code Quality`; body: in-session delegate role, decision tree (skip check → checklist unresolvable → report unavailable, stop), no-subagent pin (never spawn in place of the checklist), checklist resolution binding (OpenCode CLI `~/.config/opencode/agents/code-review-subagent.md`; Claude Code `~/.claude/agents/…`; other → stop; NO `/app/.opencode/agents` Docker dead-letter path per test_v2_pipeline_contract.bats:34-38 ruling), loop contract (load `reviewer-baseline-skill` first → checklist → diff computed by caller/`git -C` → severity gates BLOCK/WARN/NOTE + Direct-Caller Verification → Requirements Gaps array → LEARNINGS written directly → max 2 fix→re-review iterations → full re-gate before fix pushes per `verification-loop-skill`), enforcement-deltas table vs the subagent, reviewer Return Contract (Status/Output/Summary/Issues/Requirements Gaps/Patterns applied-violated)
    — **Why:** the skill is the deliverable; every later step consumes or pins it
    — **Done when:** file exists, frontmatter passes the contract (name==dir, ≤50-word description, Apache-2.0, category present), body contains the no-subagent pin, the stop-on-unresolvable rule, and the reviewer-baseline-first step
    — **Consumers affected:** registry build, preset, tests, v2 pipeline Step 9
    — **Done:** skill authored (45-word description, Apache-2.0, mirrors=code-review-subagent, category Code Quality; body: no-subagent pin, stop-on-unresolvable, CLI/claude/other resolution, baseline-first loop, re-gate citation, reviewer Return Contract); files: skills/code-review-inline-skill/SKILL.md; fixes: none

- [x] **1.2** Add `"code-review-inline-skill": ["reviewer-baseline-skill", "language-review-checklists-skill"]` to `installer/dependency-map.json`
    — **Why:** per-skill `add code-review-inline-skill` must auto-install its knowledge closure — the installer cannot resolve skills→agents, so the closure is declared here
    — **Done when:** JSON parses and the new key resolves both skills that exist on disk
    — **Consumers affected:** installer init/add flows
    — **Done:** edge added + $comment names HANDOFF4; guard test_skill_isolation.bats gained HANDOFF4_OWNER/TARGETS wired through argv (the map↔guard invariant demanded it — PLAN under-specified, deviation logged: guard edit folded into 1.2, not 4.x); files: installer/dependency-map.json, tests/test_skill_isolation.bats; fixes: none

- [x] **1.3** Rebuild the registry (`node installer/build-registry.mjs`) and verify `registry.json` gained the skill with `category: Code Quality`
    — **Why:** AGENTS.md frontmatter contract: any frontmatter change requires the rebuild + commit; init.bats pins registry==disk counts
    — **Done when:** `registry.json` lists 120 skills, new entry present, `git status` shows it staged with Phase 1
    — **Consumers affected:** installer `--list`, init.mjs, tests/init.bats
    — **Done:** rebuilt — 120 skills, entry present with category Code Quality, staged with this phase commit; files: installer/registry.json; fixes: none

### Phase 2: Visibility + packaging

- [ ] **2.1** Add `{action: skill, resource: code-review-inline-skill, effect: allow}` to `deploy/opencode.json` permissions, adjacent to the inline-family allows (after `plan-execution-inline-skill`)
    — **Why:** deny-all-first allowlist — without the allow the skill is invisible to the primary that invokes it during v2 runs
    — **Done when:** JSON parses; rule count for action=skill increases by 1; deny-all remains first
    — **Consumers affected:** runtime skill gating on every deploy

- [ ] **2.2** Append `code-review-inline-skill` to the `lean` array in `deploy/skill-profiles.json` (68 → 69)
    — **Why:** lean is the default deploy profile; the primary must see the skill at startup
    — **Done when:** array parses, length 69, README:220 restated to 69 in Phase 4
    — **Consumers affected:** `setup.sh --skill-profile lean` deploys

- [ ] **2.3** Add `code-review-inline-skill` to `pack-inline-workers.json` members and extend its `$comment`/`description` to name it
    — **Why:** the preset is the per-project install unit for the v2 inline family — its contract test asserts members resolve on disk and the family description must not drift
    — **Done when:** members length 17, description mentions the code-review inline skill, `tests/test_v2_pipeline_contract.bats` preset tests still pass
    — **Consumers affected:** `--preset inline-workers` installs, contract test

### Phase 3: v2 pipeline rewiring

- [ ] **3.1** Rewrite the Step 9 sentence of `commands.run-worktree-pipeline-v2` in `deploy/opencode.json`: replace the inline-checklist instruction ("load agents/code-review-subagent.md as your in-session checklist … review the diff yourself — compute git -C … write LEARNINGS …") with "invoke the skill `code-review-inline-skill` for the Step 9 review (pass the ticket repo + `origin/<base>` diff base; the skill owns baseline-first + checklist resolution — it reports unavailable → you stop: Step 9 is the unconditional backstop with no further net)"; keep the trailing "max 2 fix-and-re-review iterations + full re-gate before fix pushes" clause; Steps 7/8/10 sentences and the "spawn NO subagents" directive untouched
    — **Why:** single invocation path — the skill owns mechanics the template currently restates; template shrinks, contract unchanged
    — **Done when:** template still carries the zero-subagent directive + pr-workflow checklist + reviewer-baseline pins; no `/app/.opencode/agents` substring anywhere in the file; the phrase "agents/code-review-subagent.md as your in-session checklist" is gone from the template
    — **Consumers affected:** every `/run-worktree-pipeline-v2` run, contract test pins

- [ ] **3.2** Update `skills/worktree-pipeline-skill/SKILL.md`: dependency-preflight bullet — inline arm hard-requires `plan-execution-inline-skill` (Step 8) + **skill `code-review-inline-skill`** (Step 9, which itself resolves the deployed `agents/code-review-subagent.md` checklist) + `agents/pr-workflow-subagent.md` file (Step 10); Step 9 section — prepend one routing sentence ("inline arm: invoke `code-review-inline-skill` — it owns checklist resolution and the review loop"), keep the v1 arm's spawn mechanics + edit:deny rationale intact
    — **Why:** the skill's own preflight is arm-aware and pins hard deps; drift between template and skill prose breaks per-skill installs
    — **Done when:** both arm strings present; grep pins for `plan-execution-inline-skill` and `resolved per arm` still hit; v1 Step 9 prose unchanged in meaning
    — **Consumers affected:** pipeline runs on both arms, per-skill install preflight

- [ ] **3.3** Update `tests/test_v2_pipeline_contract.bats` lines 27-32: replace the `agents/code-review-subagent.md as your in-session checklist` pin with `code-review-inline-skill`; keep pr-workflow + reviewer-baseline pins
    — **Why:** the contract guard exists to be updated WITH the contract, not after — same PR or drift ships
    — **Done when:** `bats tests/test_v2_pipeline_contract.bats` green
    — **Consumers affected:** CI

### Phase 4: New skill test + docs sweep + suite

- [ ] **4.1** Create `tests/test_code_review_inline_skill.bats` pinning: frontmatter (name==dir, Apache-2.0, category `Code Quality`, mirrors metadata), body invariants (no-subagent directive, stop-on-unresolvable rule, reviewer-baseline-first, `verification-loop-skill` re-gate citation, absence of `/app/.opencode/agents` dead-letter path), wiring (dependency-map entry, pack-inline-workers membership, lean membership, opencode.json allow rule)
    — **Why:** per-feature contract guard, mirroring the v2 guard's rationale — reshaped contracts need drift pins
    — **Done when:** `bats tests/test_code_review_inline_skill.bats` green
    — **Consumers affected:** CI

- [ ] **4.2** Docs count sweep: README.md — line 5 "119 ready-to-load skills" → 120; line 76 "34 agents + 119 skills" → 120; line 102 "119 skill directories" → 120; line 220 "68 primary-visible" → 69; line 259/261 catalog count 119 → 120; line 274-278 Code Quality row (14) → (15) + add `code-review-inline-skill` to the row; line 24 two-flavors prose gains the skill name; `deploy/setup.sh:3304` comment "67 primary-visible" → 69 (pre-existing stale-by-one — reality was 68; note in commit body); `tests/skill_profiles.bats` — lean-count pins 68 → 69 (lines ~41-43 header comment 3, ~78 test name + assertion)
    — **Why:** README/setup counts are restatements that drift silently; LEARNINGS `directory-scoped-rename-sweep-misses-root-docs` + PLAN-597 3.2 precedent demand a full sweep
    — **Done when:** `grep -rn "119" README.md deploy/setup.sh` clean of skill-count hits; `grep -rn "68" tests/skill_profiles.bats` clean; Code Quality row lists the new skill; bats docs tests (if any) green
    — **Consumers affected:** README readers, doc-drift audits

- [ ] **4.3** Run the full bats suite; fix failures until green
    — **Why:** exit gate — registry consistency, isolation guard, target tests, deploy guards all run here
    — **Done when:** `bats tests/` (all files) exits 0
    — **Consumers affected:** CI, merge watcher

## Technical Notes

- Single source of truth: the review checklist STAYS in `agents/code-review-subagent.md`; the skill is an invocation wrapper. Never copy checklist content into the skill.
- test_v2_pipeline_contract.bats:34-38 bans `/app/.opencode/agents` in deploy/opencode.json (Docker dead-letter, #613 review) — the new SKILL.md must not reintroduce it either.
- init.bats registry pin is count-agnostic (registry==disk), no numeric edit needed.
- setup.ps1 and opencode_app carry no count restatements (verified 2026-09-28) — no edits there.
- The three pptx vendored `_common` trees are untouched — isolation guard's byte-identical check unaffected.
- Gate memo: phase gates are light (docs/config changes); ticket exit gate full (bats suite + registry + JSON validity + template greps).

## Dependencies

- Hard: none beyond repo state (all touched files in-repo; no npm deps — `node installer/build-registry.mjs` uses stdlib).
- Install closure declared: `reviewer-baseline-skill`, `language-review-checklists-skill` (already in pack-inline-workers — no preset growth beyond the 1 new member).

## Risks & Mitigation

- **Shared-arm prose regression** (worktree-pipeline-skill serves v1+with v2): Step 9 edit is prepend-only; v1 sentences untouched; contract test + arm-aware greps guard it.
- **Registry drift** (`generated-artifact-unstaged-regn` LEARNING): rebuild in 1.3 and commit within the same phase commit, never leave registry.json unstaged.
- **Count restatement misses**: sweep is a dedicated step (4.2) with a verification grep, not a side effect.
- **Template over-shrink**: 3.1 keeps the backstop-stop + iteration + re-gate clauses verbatim; the contract test update (3.3) lands in the same phase.
- **Stale-deploy confusion for users**: README line 24 notes the skill is the Step 9 path on fresh deploys; users on pre-#618 deploys still see old behavior until redeploy (out of scope).
