# PLAN: Enforce per-skill isolation for npx add installs

**Branch**: feat/437
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/437
**Base**: main

## Acceptance Criteria

- [x] AC1: Each pptx skill's pytest suite passes from its own directory only (no `_common` outside the skill dir on the path)
- [x] AC2: No file under `skills/` references `_common` or sibling skill paths, except (a) each skill's own vendored `scripts/_common` and (b) the single declared handoff `pptx-template-modifier-skill → pptx-generate-slide-skill` (documented prerequisite + guard allowlist)
- [x] AC3: `skills/_common/` deleted
- [x] AC4: AGENTS.md "Skill Isolation Contract" section exists and states duplication is intentional
- [x] AC5: `tests/test_skill_isolation.bats` green, including pairwise-identity check on the three vendored copies
- [x] AC6: Full bats suite passes (count-drift check included)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/_common/scripts/` (7 modules + `schemas/` + `tests/`) | — (source of vendored copies) | Today: pptx trio scripts/tests, `agents/pptx-specialist-subagent.md` docs; after this PLAN: nobody (deleted) | high (deletion; mitigated by Phase 1 copies first) |
| `pptx-generate-slide-skill/scripts/_common/` (new vendored) | Phase 1 copy | `ppt_builder.py`, slide `scripts/tests/` (conftest + 4 test files) | low |
| `pptx-template-modifier-skill/scripts/_common/` (new vendored) | Phase 1 copy | 5 modifier scripts (`constraint_checker`, `designer_promoter`, `layout_creator`, `master_cloner`, `state_machine`), modifier `scripts/tests/` | low |
| `pptx-generate-template-skill/scripts/_common/` (new vendored) | Phase 1 copy | SKILL.md inline-Python instructions (agent runtime) | low |
| Path-resolution lines in the files above | Phase 1 | Agent runtime (`sys.path` bootstrap), pytest collection | med (missed file = ImportError at runtime) |
| `agents/pptx-specialist-subagent.md` | Phase 1 | pptx-specialist agent routing docs | low |
| `pptx-template-modifier-skill → pptx-generate-slide-skill` (declared handoff: modifier extends template, slide engine fills) | — (intentional capability split, kept per #437) | modifier SKILL.md runtime step, modifier tests (`_FILLER_SCRIPTS`) | med (guard allowlist pins it to exactly this edge) |
| `AGENTS.md` (new section) | — | Repo agents, human reviewers | low |
| `tests/test_skill_isolation.bats` (new) | Phases 1–3 (asserts their end state) | Local bats run; future skill authors | low |
| `installer/registry.json` | — (must NOT change: no frontmatter edits) | installer/init.mjs | low (gate verifies zero diff) |

Cross-module consumers beyond each node's own skill: **none** (the vendored tree is consumed only inside its skill; installer untouched). This justifies Step 7 zero-reviewer triage.

## Implementation Phases

### Phase 1: Vendor the shared engine into each pptx skill
- [x] **1.1** Copy `skills/_common/scripts` verbatim to `skills/pptx-generate-slide-skill/scripts/_common` (git add)
    — **Why:** `npx add` copies one directory; every module `ppt_builder.py` imports must live inside the skill dir (AC1/AC2).
    — **Done when:** tree exists and `diff -r` against the modifier copy (1.2) is empty.
    — **Consumers affected:** pptx-generate-slide-skill runtime + its pytest suite.
    — **Done:** vendored 10-file tree (7 modules + schema + 2 tests) staged and committed; files: `skills/pptx-generate-slide-skill/scripts/_common/`; fixes: none

- [x] **1.2** Copy `skills/_common/scripts` verbatim to `skills/pptx-template-modifier-skill/scripts/_common` (git add)
    — **Why:** same isolation requirement for the modifier's 5 scripts that bootstrap `_COMMON_SCRIPTS`.
    — **Done when:** tree exists; pairwise diff vs 1.1 empty.
    — **Consumers affected:** pptx-template-modifier-skill scripts + tests.
    — **Done:** vendored tree staged and committed; `diff -r` vs 1.1 empty; files: `skills/pptx-template-modifier-skill/scripts/_common/`; fixes: none

- [x] **1.3** Create `skills/pptx-generate-template-skill/scripts/_common` by copying `skills/_common/scripts` (the skill's first `scripts/` dir)
    — **Why:** this skill has no scripts dir today — its SKILL.md imports `_common` inline, so it ships broken on `npx add` until the engine lives inside it.
    — **Done when:** tree exists; pairwise diff vs 1.1/1.2 empty.
    — **Consumers affected:** agent runtime following SKILL.md instructions.
    — **Done:** created `scripts/` dir + vendored tree; `diff -r` vs 1.1/1.2 empty; files: `skills/pptx-generate-template-skill/scripts/_common/`; fixes: none

### Phase 2: Rewire all path resolutions to the in-skill vendored copy
- [x] **2.1** In `pptx-generate-slide-skill`: change `_COMMON_SCRIPTS` in `scripts/ppt_builder.py`, `scripts/tests/conftest.py`, and any `_common` path computation in `scripts/tests/test_common_invariants.py`, `test_fingerprint_resolution.py`, `test_multipass_render_merge.py`, `test_render_contract.py` from the `parent.parent.parent / "_common" / "scripts"` sibling escape to `Path(__file__)-relative own-dir "scripts/_common"`; repoint the C1 invariant (vendored `_common` must not import back into `ppt_builder`) and supersede PLAN-GIT-72 comments (note: per-skill vendoring per #437)
    — **Why:** the vendored copy replaces the sibling escape; every `sys.path` must resolve inside the skill or imports fail at runtime (AC1/AC2).
    — **Done when:** `grep -rn '_common' skills/pptx-generate-slide-skill` shows only own-dir `scripts/_common` refs, and `python3 -m pytest` passes from `skills/pptx-generate-slide-skill/scripts`.
    — **Consumers affected:** slide engine runtime, slide pytest suite.
    — **Done:** rewired ppt_builder.py + conftest.py + test_multipass_render_merge.py path escapes; test_common_invariants docstring re-scoped (locator was already import-relative); fingerprint/render tests carry prose-only mentions (remain accurate); vendored-copy resolution proven via `layout_contract.__file__`; files: scripts/ppt_builder.py, scripts/tests/{conftest,test_common_invariants,test_multipass_render_merge}.py; fixes: none

- [x] **2.2** In `pptx-template-modifier-skill`: same rewire in `scripts/constraint_checker.py`, `designer_promoter.py`, `layout_creator.py`, `master_cloner.py`, `state_machine.py`, `scripts/tests/conftest.py`, and any test file resolving `_common` (`test_master_cloner.py`, `test_masterless_guards.py`, `test_master_background.py`)
    — **Why:** identical sibling-escape pattern via `parents[2] / "_common" / "scripts"`.
    — **Done when:** own-dir-only refs remain; pytest passes from `skills/pptx-template-modifier-skill/scripts`.
    — **Consumers affected:** modifier scripts runtime, modifier pytest suite.
    — **Done:** rewired 4 scripts (layout_creator, state_machine, constraint_checker, master_cloner — designer_promoter had no own bootstrap), conftest.py, test_master_cloner.py, test_masterless_guards.py; pytest 120 passed; files: scripts/{constraint_checker,layout_creator,master_cloner,state_machine}.py, scripts/tests/{conftest,test_master_cloner,test_masterless_guards}.py; fixes: none

- [x] **2.3** In `pptx-generate-template-skill/SKILL.md`: replace all 7 `_common` references (5× `sys.path.insert(0,'.opencode/skills/_common/scripts')`, the engine-location prose at line 40, the engine reference at line 233) with `.opencode/skills/pptx-generate-template-skill/scripts/_common` and the vendored layout
    — **Why:** the SKILL.md is the runtime instruction the deployed agent executes; a stale path breaks the skill for every `npx add` user.
    — **Done when:** `grep -c '_common' SKILL.md` refs all point at the skill's own dir; no `.opencode/skills/_common` remains.
    — **Consumers affected:** agent runtime on end-user machines.
    — **Done:** 5 sys.path lines + engine prose + engine-path reference now point at own scripts/_common; files: SKILL.md; fixes: none

- [x] **2.4** Update `agents/pptx-specialist-subagent.md` `_common` references to the per-skill vendored layout
    — **Why:** the subagent routes pptx work and describes where the engine lives; stale docs misroute future edits back to a deleted dir.
    — **Done when:** no `skills/_common` reference remains in `agents/`.
    — **Consumers affected:** pptx-specialist-subagent.
    — **Done:** 4 sys.path lines repointed per driving skill (template-check→generate-template's copy, render stages→slide's, modifier flow→modifier's); files: agents/pptx-specialist-subagent.md; fixes: none

- [x] **2.5** Declare the modifier→slide handoff: add a Prerequisites section to `pptx-template-modifier-skill/SKILL.md` naming `pptx-generate-slide-skill` with its `npx … add` install command (the fill engine import at line 66 is an intentional capability split, kept per #437); delete dead `_REPO_ROOT = _SCRIPT_DIR.parents[3]` escape in slide `ppt_builder.py` (computed, never used)
    — **Why:** Phase 2 re-audit found deploy-path sibling refs (`\.opencode/skills/<sibling>/scripts`) the original `../`-relative audit grep missed; the split stays intentional, so it must be declared for `npx add` users and pinned in the Phase 5 allowlist rather than silently banned or silently kept.
    — **Done when:** modifier SKILL.md carries the prerequisite + install hint; `_REPO_ROOT` gone; the only sibling path refs under `skills/` are the declared modifier→slide ones.
    — **Consumers affected:** modifier skill end users (install guidance), slide ppt_builder (dead line removed), Phase 5 guard (allowlist source).
    — **Done:** Prerequisites block added naming pptx-generate-slide-skill + npx install command; `_REPO_ROOT` deleted from ppt_builder.py; dead `_SKILLS/_REPO_ROOT/_FILLER_SCRIPTS` lines removed identically from all 3 vendored test_master_repairer.py copies (pairwise identity re-proven); sibling-path grep shows only the 2 declared modifier→slide refs; files: pptx-template-modifier-skill/SKILL.md, pptx-generate-slide-skill/scripts/ppt_builder.py, 3× scripts/_common/tests/test_master_repairer.py; fixes: none

### Phase 3: Delete the shared package
- [x] **3.1** `git rm -r skills/_common`
    — **Why:** with three vendored copies live, the shared dir is dead code whose existence invites new sibling escapes (AC3); drift is now policed by the Phase 5 identity check instead of a shared source.
    — **Done when:** dir absent from the tree; repo-wide `grep -rn 'skills/_common'` (excluding `PLANS/`, `.git/`) returns nothing.
    — **Consumers affected:** none (all consumers rewired in Phase 2).
    — **Done:** dir removed (10 files); repo-wide grep (excl. PLANS/.git) returns zero hits; bats 341/341 green; files: skills/_common/ (deleted); fixes: none

### Phase 4: Document the contract
- [x] **4.1** Add "Skill Isolation Contract" section to root `AGENTS.md`: every `skills/<name>-skill/` must be fully self-contained so `npx add <name>` works standalone; cross-skill code duplication is intentional (per-skill copy model, #437); no new shared `_`-prefixed dirs; the pptx vendored `scripts/_common` copies must stay in sync (fix once, copy to all three)
    — **Why:** reviewers currently flag intentional duplication as a smell, and nothing stops future shared-dependency regressions (AC4).
    — **Done when:** section present with those four statements.
    — **Consumers affected:** repo agents, human reviewers, future skill authors.
    — **Done:** section added after Source of Truth with all four statements + the declared modifier→slide exception rule; files: AGENTS.md; fixes: none

### Phase 5: Isolation guard test
- [x] **5.1** Create `tests/test_skill_isolation.bats`: (a) no file under `skills/**` computes a path escaping its skill dir (`../_common`, `parent.parent.parent`/`parents[2]` `_common` resolution, `.opencode/skills/_common`, sibling `*-skill` path references in code — except the declared allowlisted `pptx-template-modifier-skill → pptx-generate-slide-skill` edge); (b) the three vendored `scripts/_common` trees are pairwise byte-identical (`diff -r`)
    — **Why:** the contract needs a mechanical gate or it decays with the next skill addition (AC5, AC2 regression cover).
    — **Done when:** `bats tests/test_skill_isolation.bats` green.
    — **Consumers affected:** local test suite, future authors.
    — **Done:** 4 guards shipped; sibling scan scoped to runtime carriers (SKILL.md + *.py) after it correctly flagged slide's design-doc file-tree diagram as prose-only; mutation canary proves each test fails on exactly its own violation class (M1 shared-common→test1, M2 py-sibling→test3, M3 drift→test4, M4 SKILL.md-sibling→test3); files: tests/test_skill_isolation.bats; fixes: sibling-scan scope (docs/** prose excluded — diagram false positive)

### Phase 6: Full verification gates
- [x] **6.1** Run all three pptx skills' pytest suites standalone (`python3 -m pytest` from each `scripts/` dir) and the full bats suite (`bats tests/`)
    — **Why:** proves the vendoring broke nothing and pre-existing suites stay green (AC1, AC6).
    — **Done when:** all suites exit 0.
    — **Consumers affected:** none (verification only).
    — **Done:** slide 529 passed/9 skipped (incl. vendored 23), modifier 120 passed, generate-template vendored suite 23 passed from its own dir, full bats 345/345 (341 pre-existing + 4 new guards); files: none (verification); fixes: none

- [x] **6.2** Registry sanity: run `node installer/build-registry.mjs` and confirm `installer/registry.json` is byte-identical (no frontmatter changed → no registry churn)
    — **Why:** guards against accidental registry drift from the skills/ tree change; AGENTS.md requires registry rebuild after frontmatter changes only.
    — **Done when:** `git diff --stat installer/registry.json` empty after rebuild.
    — **Consumers affected:** none (verification only).
    — **Done:** rebuild produced identical counts (34 agents / 146 skills) and zero entry diffs — only the `generatedAt` timestamp churned; reverted the timestamp to keep the tree clean, content proven unchanged; files: none; fixes: none

## Technical Notes

- Vendored files themselves stay **unedited** (byte-identical by design) — all changes are in the consuming files' path computations. This keeps the Phase 5 identity check trivial and future syncs are plain copies.
- `pptx-generate-slide-skill` already has its own `schemas/` and `schema_validator.py` — flat merging would collide; the `scripts/_common/` subdir layout avoids it.
- The three-skill split of the pptx family is intentional (#437 discussion); this PLAN does NOT merge the skills — it isolates each.
- No installer changes: `registry.json` and `init.mjs` are untouched; `_common` was never a registry entry, so counts don't move.

## Dependencies

- None external. `python-pptx`, `Pillow`, `pytest` verified present. `bats` on PATH.

## Risks & Mitigation

- **Missed `_common` path computation → runtime ImportError**: Phase 2 done-when greps + Phase 5 guard + pytest per skill.
- **Vendored copies drift after future fixes**: Phase 5 byte-identity check fails loudly; AGENTS.md §Skill Isolation Contract documents the fix-once-copy-thrice rule.
- **C1 invariant test semantic change** (`_common` must not import back into `ppt_builder`): repointed at the vendored copy in 2.1 — still meaningful, now scoped per skill.
- **Hidden consumers of `skills/_common` outside skills/ and agents/**: repo-wide grep in 3.1 done-when; only `agents/pptx-specialist-subagent.md` found in audit.
- **Audit blind spot (found in Phase 2)**: the original audit grepped `../`-relative sibling refs only and missed deploy-path strings (`.opencode/skills/<sibling>/scripts`). Re-audit via `grep -rn "skills/[a-z0-9-]*-skill" skills/ --include='*'` covers both; the modifier→slide handoff it surfaced is declared (2.5), not banned.

## Gate Log

- Phase 1 (1.1–1.3): GATE 2c04437 lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — full bats suite 341/341 ok exit 0; pairwise `diff -r` of the three vendored trees empty; lint/typecheck/build: none configured (no scripts/Makefile manifests)
- Phase 2 (2.1–2.5): GATE 8ea7258 lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — slide pytest 529 passed/9 skipped (incl. vendored 23), modifier 120 passed, full bats 341/341 ok; vendored trees pairwise identical after cleanup; PLAN amended pre-commit (6f4132e) to declare modifier→slide handoff
- Phase 3 (3.1): GATE c7a4d0e lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — repo-wide grep zero `skills/_common` refs (excl. PLANS/.git); full bats suite 341/341 ok
- Phase 4 (4.1): GATE 832e73b lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — full bats suite 341/341 ok; section verified present with all four contract statements + exception rule
- Phase 5 (5.1): GATE 1c568b1 lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — guard 4/4 ok; mutation canary (4 planted violations → each caught by exactly its test); full bats suite 345/345 ok
- Phase 6 (6.1–6.2): GATE final lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — slide 529✓/9skip, modifier 120✓, generate-template vendored 23✓ (each from own dir, skills/_common now deleted so external resolution is impossible); full bats 345/345; registry rebuild content-identical (timestamp-only churn reverted); all 6 ACs verified
- Code review round 1 (d95d28a): 3 Major fixed — guard test-2 regex false-negatives (empirically 8/10 spellings missed, incl. the exact pre-#437 lines), test-3 scanner misses (../ and non-suffix siblings; now catalog-driven ±-skill, fence-scoped — kills attribution-URL/credits-table/target-project false positives), AGENTS.md contract overstated enforcement (new test-5 `_`-dir ban; HANDOFF_* named source of truth). NOTEs fixed: dead `_SCRIPT_DIR`, `-eq 1` grep semantics, test-1 scope skills/+agents/, add-trees-here comment. Learning persisted: guard-regex-quote-shape-mismatch. Post-fix: guard 5/5 + re-canaries (gsap hop, parents[2] single-segment, fenced SKILL.md sibling, _-dir), slide 529✓/9skip, full bats 346/346. Requirements Gap (installer prerequisite hint on `add`) judged out-of-scope — follow-up ticket material, not a merge blocker
- Code review round 2 (f348b68): re-review confirmed all 3 Majors resolved (reviewer re-verified empirically); 1 new WARN + 5 NOTEs fixed — test-2 extended to SKILL.md fence spans (unclosed-fence tail included), alt-3 `Path("x") / "scripts"` paren form, test-5 skills/ pre-assert, test-1 + README/MIGRATION. Round-1 canary lesson persisted (non-reproducing canary = finding). Final: guard 5/5 clean, byte-exact per-test canaries, full bats 346/346. Review loop closed at iteration 2 of 2

