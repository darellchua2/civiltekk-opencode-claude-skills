# PLAN: pptx layout_name first-class targeting — port #261 to the post-restructure tree

**Branch**: feat/623
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/623
**Base**: main

**Port source**: PR #261 (branch `feat/slide_types_decoupling` @ `775dff4`, fork `086fa1b`) — applied via path-relocated per-file patches (`-p3`, split by drift) onto `skills/pptx-generate-slide-skill/scripts/`.

## Acceptance Criteria (from #623 / #261 GIT-93)
- [x] `layout_name` accepted as a first-class per-slide field targeting any template layout (8-layout cap removed)
- [x] `slide_type` documented/behaving as a semantic label, not a hard gate; `_custom_N` pseudo-type escape hatch reachable (latent gate-order bug fixed)
- [x] overflow resolution keyed by `layout_name`
- [x] generic per-field schema validation for the `layout_name` path
- [x] ported/adapted test suite at parity with the GIT-93 suite's coverage

## Port map (old path → modern path → method)

| PR file | Modern file | Method |
|---|---|---|
| `_common/scripts/layout_contract.py` | `scripts/_common/layout_contract.py` | hand-port: +`available_layouts()`, +`classify_layout_fingerprint()` after `servable_slide_types`; cosmetics skipped |
| `scripts/multipass_render.py` | same (relative) | clean `-p3` apply |
| `scripts/overflow_check.py` | same | clean `-p3` apply |
| `scripts/ppt_builder.py` | same | `--reject` apply (7/8 hunks) + hand-port: `_LAYOUTS_WITH_*` gate sets retired (field-driven fill), `_select_layout` layout_name precedence + T2.3/T2.4 gate fix + fingerprint gating, `_validate_template` slide_data_list + T2.5 relaxation, field-driven fill loop (MAJOR-1 sweep preserved, double-fill guard), chart field-presence gate |
| `scripts/schema_validator.py` | same | hand-port: import, +`_validate_generic_fields`, unknown-type routing to generic path, strict-promotion broadening (MINOR-4) |
| `scripts/schemas/slide_schemas.py` | same | append `_build_all_field_specs()` + `ALL_FIELD_SPECS` (bucket shape verified first) |
| `scripts/schemas/__init__.py` | same | export `ALL_FIELD_SPECS` |
| `scripts/tests/test_layout_name_targeting.py` | same (new) | clean apply (34-test GIT-93 suite) |
| `scripts/tests/test_multipass_render*.py` | same | clean apply (updated expectations) |

## Implementation Phases

### Phase 1: mechanical patch application
- [x] **1.1** Split the PR diff by path shape; apply the 6 cleanly-applying files via `-p3` / `--reject`
    — **Why:** 3-way apply failed atomically on 4 drifted files; per-file application isolates drift
    — **Done when:** 6 files applied, 4 isolated for hand-porting
    — **Consumers affected:** none (working tree only)
### Phase 2: hand-ported files
- [x] **2.1** Port `schemas/slide_schemas.py` + `schemas/__init__.py` (bucket-shape verified before append; import verified: 21 field specs)
    — **Why:** the validator's generic path depends on `ALL_FIELD_SPECS`
    — **Done when:** import + spec count verified
    — **Consumers affected:** schema_validator
- [x] **2.2** Port `schema_validator.py` (4 hunks)
    — **Why:** the generic per-field validation path is GIT-93 Phase 4
    — **Done when:** anchors matched; unknown-type + layout_name routing in place
    — **Consumers affected:** validate_slide_data_list callers
- [x] **2.3** Port `ppt_builder.py` (8 hunks: gate sets retired, `_select_layout` precedence + gate fix, `_validate_template` relaxation, field-driven fill loop)
    — **Why:** the core feature — layout_name targeting + field-driven fill
    — **Done when:** all hunks applied; obsolete first hunk skipped (path-chain comment removed post-#609)
    — **Consumers affected:** render loop
- [x] **2.4** Port `_common/layout_contract.py` helpers (+ restore the section separator the insert initially swallowed)
    — **Why:** P1 contract helpers used by the agent-facing layout catalog
    — **Done when:** helpers import and classify correctly (`[TITLE,BODY,OBJECT]` → `content_slide`)
    — **Consumers affected:** contract consumers
### Phase 3: validation
- [x] **3.1** Ported suite: `pytest tests/test_layout_name_targeting.py tests/test_multipass_render.py tests/test_multipass_render_merge.py` → 42 passed, 1 skipped
    — **Why:** end-to-end proof of the port
    — **Done when:** green
    — **Consumers affected:** CI (pytest runs on this dir)
- [x] **3.2** All ported files `py_compile` clean
    — **Why:** syntax gate
    — **Done when:** compile clean
    — **Consumers affected:** none

## Dependencies
#623 supersedes the closed PR #261 (intent carrier per the user-confirmed close).

## Risks & Mitigation
- **Fill-loop behavior change** → MAJOR-1 subtitle-sweep preservation + double-fill guard carried verbatim from the PR; the ported test suite exercises both.
- **Vendored `_common` sync** → layout_contract.py is vendored into all three pptx skills and must stay byte-identical across them (isolation guard) — the port edits only the generate-slide copy, so the OTHER two vendored copies must receive the same two functions before merge. **Status: done — functions copied byte-identical to `skills/pptx-generate-template-skill/scripts/_common/layout_contract.py` and `skills/pptx-template-modifier-skill/scripts/_common/layout_contract.py`.**

GATE d938960 tier=full lint=- typecheck=- build=- unit=t(pytest 535p/9s) e2e=n.a
