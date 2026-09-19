# PLAN: Enforce per-skill isolation for npx add installs

**Branch**: feat/437
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/437
**Base**: main

## Acceptance Criteria

- [ ] AC1: Each pptx skill's pytest suite passes from its own directory only (no `_common` outside the skill dir on the path)
- [ ] AC2: No file under `skills/` references `_common` or sibling skill paths (only the skill's own vendored `scripts/_common` is permitted)
- [ ] AC3: `skills/_common/` deleted
- [ ] AC4: AGENTS.md "Skill Isolation Contract" section exists and states duplication is intentional
- [ ] AC5: `tests/test_skill_isolation.bats` green, including pairwise-identity check on the three vendored copies
- [ ] AC6: Full bats suite passes (count-drift check included)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/_common/scripts/` (7 modules + `schemas/` + `tests/`) | — (source of vendored copies) | Today: pptx trio scripts/tests, `agents/pptx-specialist-subagent.md` docs; after this PLAN: nobody (deleted) | high (deletion; mitigated by Phase 1 copies first) |
| `pptx-generate-slide-skill/scripts/_common/` (new vendored) | Phase 1 copy | `ppt_builder.py`, slide `scripts/tests/` (conftest + 4 test files) | low |
| `pptx-template-modifier-skill/scripts/_common/` (new vendored) | Phase 1 copy | 5 modifier scripts (`constraint_checker`, `designer_promoter`, `layout_creator`, `master_cloner`, `state_machine`), modifier `scripts/tests/` | low |
| `pptx-generate-template-skill/scripts/_common/` (new vendored) | Phase 1 copy | SKILL.md inline-Python instructions (agent runtime) | low |
| Path-resolution lines in the files above | Phase 1 | Agent runtime (`sys.path` bootstrap), pytest collection | med (missed file = ImportError at runtime) |
| `agents/pptx-specialist-subagent.md` | Phase 1 | pptx-specialist agent routing docs | low |
| `AGENTS.md` (new section) | — | Repo agents, human reviewers | low |
| `tests/test_skill_isolation.bats` (new) | Phases 1–3 (asserts their end state) | Local bats run; future skill authors | low |
| `installer/registry.json` | — (must NOT change: no frontmatter edits) | installer/init.mjs | low (gate verifies zero diff) |

Cross-module consumers beyond each node's own skill: **none** (the vendored tree is consumed only inside its skill; installer untouched). This justifies Step 7 zero-reviewer triage.

## Implementation Phases

### Phase 1: Vendor the shared engine into each pptx skill
- [ ] **1.1** Copy `skills/_common/scripts` verbatim to `skills/pptx-generate-slide-skill/scripts/_common` (git add)
    — **Why:** `npx add` copies one directory; every module `ppt_builder.py` imports must live inside the skill dir (AC1/AC2).
    — **Done when:** tree exists and `diff -r` against the modifier copy (1.2) is empty.
    — **Consumers affected:** pptx-generate-slide-skill runtime + its pytest suite.

- [ ] **1.2** Copy `skills/_common/scripts` verbatim to `skills/pptx-template-modifier-skill/scripts/_common` (git add)
    — **Why:** same isolation requirement for the modifier's 5 scripts that bootstrap `_COMMON_SCRIPTS`.
    — **Done when:** tree exists; pairwise diff vs 1.1 empty.
    — **Consumers affected:** pptx-template-modifier-skill scripts + tests.

- [ ] **1.3** Create `skills/pptx-generate-template-skill/scripts/_common` by copying `skills/_common/scripts` (the skill's first `scripts/` dir)
    — **Why:** this skill has no scripts dir today — its SKILL.md imports `_common` inline, so it ships broken on `npx add` until the engine lives inside it.
    — **Done when:** tree exists; pairwise diff vs 1.1/1.2 empty.
    — **Consumers affected:** agent runtime following SKILL.md instructions.

### Phase 2: Rewire all path resolutions to the in-skill vendored copy
- [ ] **2.1** In `pptx-generate-slide-skill`: change `_COMMON_SCRIPTS` in `scripts/ppt_builder.py`, `scripts/tests/conftest.py`, and any `_common` path computation in `scripts/tests/test_common_invariants.py`, `test_fingerprint_resolution.py`, `test_multipass_render_merge.py`, `test_render_contract.py` from the `parent.parent.parent / "_common" / "scripts"` sibling escape to `Path(__file__)-relative own-dir "scripts/_common"`; repoint the C1 invariant (vendored `_common` must not import back into `ppt_builder`) and supersede PLAN-GIT-72 comments (note: per-skill vendoring per #437)
    — **Why:** the vendored copy replaces the sibling escape; every `sys.path` must resolve inside the skill or imports fail at runtime (AC1/AC2).
    — **Done when:** `grep -rn '_common' skills/pptx-generate-slide-skill` shows only own-dir `scripts/_common` refs, and `python3 -m pytest` passes from `skills/pptx-generate-slide-skill/scripts`.
    — **Consumers affected:** slide engine runtime, slide pytest suite.

- [ ] **2.2** In `pptx-template-modifier-skill`: same rewire in `scripts/constraint_checker.py`, `designer_promoter.py`, `layout_creator.py`, `master_cloner.py`, `state_machine.py`, `scripts/tests/conftest.py`, and any test file resolving `_common` (`test_master_cloner.py`, `test_masterless_guards.py`, `test_master_background.py`)
    — **Why:** identical sibling-escape pattern via `parents[2] / "_common" / "scripts"`.
    — **Done when:** own-dir-only refs remain; pytest passes from `skills/pptx-template-modifier-skill/scripts`.
    — **Consumers affected:** modifier scripts runtime, modifier pytest suite.

- [ ] **2.3** In `pptx-generate-template-skill/SKILL.md`: replace all 7 `_common` references (5× `sys.path.insert(0,'.opencode/skills/_common/scripts')`, the engine-location prose at line 40, the engine reference at line 233) with `.opencode/skills/pptx-generate-template-skill/scripts/_common` and the vendored layout
    — **Why:** the SKILL.md is the runtime instruction the deployed agent executes; a stale path breaks the skill for every `npx add` user.
    — **Done when:** `grep -c '_common' SKILL.md` refs all point at the skill's own dir; no `.opencode/skills/_common` remains.
    — **Consumers affected:** agent runtime on end-user machines.

- [ ] **2.4** Update `agents/pptx-specialist-subagent.md` `_common` references to the per-skill vendored layout
    — **Why:** the subagent routes pptx work and describes where the engine lives; stale docs misroute future edits back to a deleted dir.
    — **Done when:** no `skills/_common` reference remains in `agents/`.
    — **Consumers affected:** pptx-specialist-subagent.

### Phase 3: Delete the shared package
- [ ] **3.1** `git rm -r skills/_common`
    — **Why:** with three vendored copies live, the shared dir is dead code whose existence invites new sibling escapes (AC3); drift is now policed by the Phase 5 identity check instead of a shared source.
    — **Done when:** dir absent from the tree; repo-wide `grep -rn 'skills/_common'` (excluding `PLANS/`, `.git/`) returns nothing.
    — **Consumers affected:** none (all consumers rewired in Phase 2).

### Phase 4: Document the contract
- [ ] **4.1** Add "Skill Isolation Contract" section to root `AGENTS.md`: every `skills/<name>-skill/` must be fully self-contained so `npx add <name>` works standalone; cross-skill code duplication is intentional (per-skill copy model, #437); no new shared `_`-prefixed dirs; the pptx vendored `scripts/_common` copies must stay in sync (fix once, copy to all three)
    — **Why:** reviewers currently flag intentional duplication as a smell, and nothing stops future shared-dependency regressions (AC4).
    — **Done when:** section present with those four statements.
    — **Consumers affected:** repo agents, human reviewers, future skill authors.

### Phase 5: Isolation guard test
- [ ] **5.1** Create `tests/test_skill_isolation.bats`: (a) no file under `skills/**` computes a path escaping its skill dir (`../_common`, `parent.parent.parent`/`parents[2]` `_common` resolution, `.opencode/skills/_common`, sibling `*-skill` path references in code/SKILL.md); (b) the three vendored `scripts/_common` trees are pairwise byte-identical (`diff -r`)
    — **Why:** the contract needs a mechanical gate or it decays with the next skill addition (AC5, AC2 regression cover).
    — **Done when:** `bats tests/test_skill_isolation.bats` green.
    — **Consumers affected:** local test suite, future authors.

### Phase 6: Full verification gates
- [ ] **6.1** Run all three pptx skills' pytest suites standalone (`python3 -m pytest` from each `scripts/` dir) and the full bats suite (`bats tests/`)
    — **Why:** proves the vendoring broke nothing and pre-existing suites stay green (AC1, AC6).
    — **Done when:** all suites exit 0.
    — **Consumers affected:** none (verification only).

- [ ] **6.2** Registry sanity: run `node installer/build-registry.mjs` and confirm `installer/registry.json` is byte-identical (no frontmatter changed → no registry churn)
    — **Why:** guards against accidental registry drift from the skills/ tree change; AGENTS.md requires registry rebuild after frontmatter changes only.
    — **Done when:** `git diff --stat installer/registry.json` empty after rebuild.
    — **Consumers affected:** none (verification only).

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
