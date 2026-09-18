# PLAN: Add cad-redraw-skill — Linux DWG/DXF/PDF/image redraw via ezdxf

**Branch**: feat/402
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/402
**Base**: main

## Acceptance Criteria

- [ ] `skills/cad-redraw-skill/SKILL.md` conforming to the house frontmatter contract (name = directory, Apache-2.0, compatibility opencode, ≤50-word description preserving trigger phrases: dwg redraw, image to dxf, pdf to dxf)
- [ ] `references/`: `redraw-spec.md` (JSON spec schema), `validation.md` (acceptance policies + dispositions), `linux-toolchain.md` (ODA install, LibreDWG fallback, DWG degradation caveats)
- [ ] 7 scripts with self-checks: `fingerprint.py`, `fingerprint_diff.py`, `spec_to_dxf.py`, `render_preview.py`, `preflight_image.py`, `compare_visual.py`, `pdf_vector_to_dxf.py`
- [ ] Evidence levels + 5 profiles (`strict-dimensioned`, `general`, `hybrid`, `visual-trace`, `geometry-only`) enforced in spec validation; no unit/scale anchor forces `visual-trace`/`unitless`, never a silent mm default
- [ ] DWG input degrades gracefully: odafc → LibreDWG → clear error with install guidance; converter used + fidelity reported on every DWG path
- [ ] `agents/cad-specialist-subagent.md`: permission allow rule + routing line + count 14 → 15
- [ ] `installer/registry.json` rebuilt via `node installer/build-registry.mjs` (lists `cad-redraw-skill` with correct frontmatter-derived metadata; `--check` exits 0); `installer/presets/pack-cad.json` regenerated (15 skills); `docs/registry.json` out of scope — gitignored release artifact of `build-site.mjs`, regenerates from the installer registry at release
- [ ] `deploy/setup.sh`, `deploy/setup.ps1`, `README.md` listings synced, including the five hand-maintained totals 149→150 (README.md ~15/250/409/566, opencode_app/README.md ~30) and the README preset-table row ~266 (documentation-sync-workflow pass)
- [ ] E2E smoke passes: fingerprint → diff fails on drifted fixture → regenerate → diff passes → preview renders
- [ ] `ruff` lint green; `bats tests/` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/cad-redraw-skill/SKILL.md` | — (defines contract the scripts implement) | opencode skill loader, `cad-specialist-subagent.md` routing, `installer/build-registry.mjs` frontmatter scan, presets, doc counts | medium |
| `skills/cad-redraw-skill/references/*.md` | SKILL.md section names (quoted pointers must match) | SKILL.md instructions, script `--help` text | low |
| `skills/cad-redraw-skill/scripts/fingerprint.py` | ezdxf runtime; optional odafc/LibreDWG | `fingerprint_diff.py` (JSON shape), SKILL.md Mode A | medium |
| `skills/cad-redraw-skill/scripts/fingerprint_diff.py` | `fingerprint.py` JSON shape | SKILL.md validation gate; E2E smoke | low |
| `skills/cad-redraw-skill/scripts/spec_to_dxf.py` | `references/redraw-spec.md` schema; ezdxf | SKILL.md Mode C; `render_preview.py` output chain | medium |
| `skills/cad-redraw-skill/scripts/render_preview.py` | ezdxf drawing add-on (matplotlib backend) | SKILL.md handoff (cad-viewer-skill), `compare_visual.py` | low |
| `skills/cad-redraw-skill/scripts/preflight_image.py` | Pillow/NumPy/OpenCV (optional, import-guarded) | SKILL.md Mode C step 1 | low |
| `skills/cad-redraw-skill/scripts/compare_visual.py` | OpenCV (optional, import-guarded); preview PNG | SKILL.md Mode C step 6 | low |
| `skills/cad-redraw-skill/scripts/pdf_vector_to_dxf.py` | PyMuPDF (optional, import-guarded); ezdxf | SKILL.md Mode B | low |
| `agents/cad-specialist-subagent.md` | `LEARNINGS/conventions/task-delegate-permission-sync.md` conventions; skill dir existing | opencode agent loader, registry frontmatter scan, pack-cad description, README agent references | medium |
| `installer/registry.json` | all skill/agent frontmatter final | `build-registry.mjs` output (`--check` guard); preset derivation; docs site regenerates its gitignored `docs/registry.json` copy from it at release | medium |
| `installer/presets/pack-cad.json` | `registry.json` final | `installer/init.mjs --preset cad` | low |
| `deploy/setup.sh`, `deploy/setup.ps1` | skills dir final | deploy users (dynamic `count_skills`, banner text) | low |
| `README.md` (CAD row ~598, preset-table row ~266, hand-maintained totals ~15/250/409/566, Subagents table) and `opencode_app/README.md` (~30 total) | registry counts final | human readers; doc-consistency checks (BT-157 sync markers) | low |

Cross-module consumers exist (registry ← frontmatter, presets ← registry, routing ← skill), so architecture review is selected at plan review.

## Implementation Phases

### Phase 1: Skill contract and references

- [x] **1.1** Create `skills/cad-redraw-skill/SKILL.md` with house-contract frontmatter (`name: cad-redraw-skill`, `license: Apache-2.0`, `compatibility: opencode`, `category: CAD & Hardware Design`, `metadata: {protocol, pattern}`, no `model:`) and a ≤50-word description preserving triggers `dwg redraw`, `image to dxf`, `pdf to dxf`; body sections: provenance credit (methodology from pengxiaoan, zero code reused), non-negotiable rules (evidence levels `known/scaled/inferred/unreadable`, pixels never override written dimensions, visual similarity ≠ dimensional accuracy, conflicts → `needs_review`, never overwrite source), Mode A/B/C workflows, 5 profiles, validation contract, viewer handoff, DWG I/O
    — **Why:** the SKILL.md is the runtime contract every later script and sync surface derives from; writing it first fixes the vocabulary (modes, profiles, dispositions) all other steps use
    — **Done when:** frontmatter parses, name equals directory name, description ≤50 words containing all three trigger phrases, and the six body sections exist; `node installer/build-registry.mjs` has been run so `--check` exits 0 within this phase's commit (registry-vs-disk tests `init.bats`/`deploy_delegate.bats` are per-commit invariants — deviation from the ticket's phase-5-only registry landing, see Technical Notes)
    — **Consumers affected:** skill loader, build-registry scan, cad-specialist routing (later steps)
    — **Done:** SKILL.md authored and contract-verified (name=dir, 41-word description, 3 triggers, six body sections); registry rebuilt in-commit (skills=150, `--check` green); files: skills/cad-redraw-skill/SKILL.md, installer/registry.json; fixes: none
- [x] **1.2** Write `references/redraw-spec.md` defining the JSON spec schema: views with independent calibration, anchor lists, evidence levels per value, constraint records, entity records (LINE, ARC, CIRCLE, LWPOLYLINE, TEXT, MTEXT, DIMENSION) with stable IDs, source vs CAD coordinate system separation
    — **Why:** the spec JSON is the interchange format between spec authoring, `spec_to_dxf.py` validation, and drawing; the schema must exist before the validator/drawer encode it
    — **Done when:** every entity type the drawer will support is documented with required/optional fields and an evidence field
    — **Consumers affected:** `spec_to_dxf.py` (2.3), spec authors
    — **Done:** redraw-spec.md authored — top-level shape, views/calibration, all 7 entity types with geometry shapes, constraint kinds, layers, evidence rules; files: skills/cad-redraw-skill/references/redraw-spec.md; fixes: none
- [x] **1.3** Write `references/validation.md`: acceptance policies per profile, the fingerprint-diff gate contract (missing dims/leaders in target = failure when source has them), the 5 dispositions (`pass`, `pass_with_warnings`, `needs_review`, `blocked`, `fail`) with trigger conditions, and the pixel-comparison prohibition
    — **Why:** reviewers and the executor need the pass/fail vocabulary fixed before any script reports results
    — **Done when:** all 5 dispositions defined with at least one concrete trigger each
    — **Consumers affected:** `fingerprint_diff.py` exit semantics (2.2), SKILL.md Mode C step 7
    — **Done:** validation.md authored — two-axis separation, fingerprint-diff gate contract, per-profile spec gate table, 5 dispositions with triggers, report contract; files: skills/cad-redraw-skill/references/validation.md; fixes: none
- [x] **1.4** Write `references/linux-toolchain.md`: ODA File Converter install + headless `QT_QPA_PLATFORM=offscreen` note, LibreDWG `dwg2dxf` fallback and coverage caveat, converter precedence (odafc → dwg2dxf → error with install guidance), and inherent degradation caveats (proxy/custom objects, SHX text, annotative dims, dynamic blocks)
    — **Why:** the DXF-first promise and graceful DWG degradation (an acceptance criterion) must be documented where users will look first
    — **Done when:** converter precedence chain and all four degradation caveats are listed
    — **Consumers affected:** `fingerprint.py` converter code (2.1), SKILL.md DWG I/O section
    — **Done:** linux-toolchain.md authored — ODA→LibreDWG→named-error precedence, QT_QPA_PLATFORM=offscreen guidance, 4 degradation caveats, fidelity-reporting rule, FreeCAD as import target only; files: skills/cad-redraw-skill/references/linux-toolchain.md; fixes: none

### Phase 2: Core scripts (fingerprint, diff, spec-to-dxf, preview)

- [x] **2.1** Create `scripts/fingerprint.py`: DXF/DWG → `<prefix>-fingerprint.json` (entity counts by type/space/layer, layer table with colors/linetypes, block inventory, text/dim styles, annotation inventory, extents, DWG version/producer) + `<prefix>-redraw-prompt.md`; DWG handled via odafc → `dwg2dxf` → clear error naming the missing converter; include `--self-check` generating an in-memory ezdxf fixture and asserting fingerprint fields
    — **Why:** Mode A profiling is the entry point of the whole redraw flow and defines the JSON shape the diff gate consumes
    — **Done when:** `python scripts/fingerprint.py --self-check` exits 0; running on a fixture DXF emits both output files with all fingerprint sections populated
    — **Consumers affected:** `fingerprint_diff.py` (2.2), E2E smoke (2.5)
    — **Done:** fingerprint.py implemented (fingerprint JSON + redraw prompt; odafc→dwg2dxf→exit-2-with-hints DWG path); self-check PASS (verified independently); files: skills/cad-redraw-skill/scripts/fingerprint.py; fixes: none
- [x] **2.2** Create `scripts/fingerprint_diff.py`: source vs target fingerprint → structured delta JSON + human summary; exit 0 only when required classes match (dims/leaders present in source but missing in target = failure); `--self-check` proving drift detection
    — **Why:** the fingerprint diff is the deterministic validation gate separating Mode A pass from fail
    — **Done when:** `--self-check` exits 0; identical fingerprints pass, a fixture with one removed dimension fails with a named delta
    — **Consumers affected:** SKILL.md Mode A validation step; E2E smoke (2.5)
    — **Done:** fingerprint_diff.py implemented (per-type/per-space counts, styles, dims/leaders failure semantics, tolerance, --json delta); self-check PASS; E2E: drift names `DIMENSION source=1 target=0`; files: skills/cad-redraw-skill/scripts/fingerprint_diff.py; fixes: none
- [x] **2.3** Create `scripts/spec_to_dxf.py`: JSON spec → ezdxf DXF (explicit units, layers from spec, LWPOLYLINE/CIRCLE/ARC/LINE/TEXT/MTEXT/DIMENSION) plus `--check-only --report` validation mode enforcing schema, unique IDs, positive dims, arithmetic constraints, evidence requirements per profile (strict-dimensioned requires units + anchors; no anchor → must be visual-trace/unitless, never silent mm); include `--geometry-only`; `--self-check` covering draw + reject paths
    — **Why:** this is both the Mode C drawer and the spec validation gate; encoding the profile/evidence rules here is what makes evidence levels enforced rather than decorative
    — **Done when:** `--self-check` exits 0 (valid spec draws; invalid specs rejected: duplicate ID, negative dim, strict-dimensioned without units)
    — **Consumers affected:** SKILL.md Mode C steps 3–4; `render_preview.py` chain
    — **Done:** spec_to_dxf.py implemented (draw + --check-only; profile/evidence gates, 7 constraint kinds, geometry-only); self-check PASS rejecting duplicate_id/non_positive/profile codes; files: skills/cad-redraw-skill/scripts/spec_to_dxf.py; fixes: lintetype→linetype typo corrected in references/redraw-spec.md (subagent-caught doc defect, drawer accepts both)
- [x] **2.4** Create `scripts/render_preview.py`: DXF → PNG (+ optional PDF) via the ezdxf drawing add-on with matplotlib backend, deterministic extents; `--self-check` rendering the fixture
    — **Why:** visual review and `compare_visual.py` need a deterministic raster of the CAD output, and the viewer handoff depends on it
    — **Done when:** `--self-check` exits 0 and produces a non-empty PNG
    — **Consumers affected:** SKILL.md handoff; `compare_visual.py` (3.2)
    — **Done:** render_preview.py implemented (matplotlib backend, deterministic 2200×1700 PNG + optional PDF, import-guarded); self-check PASS; files: skills/cad-redraw-skill/scripts/render_preview.py; fixes: none
- [x] **2.5** Run the core E2E smoke in a scratch dir: fixture DXF → fingerprint → remove one dimension → diff fails → regenerate → diff passes → preview renders
    — **Why:** the ticket's E2E acceptance criterion is observable only when the whole core chain runs against real files
    — **Done when:** the scripted sequence produces exactly one failing diff then one passing diff plus a rendered PNG
    — **Consumers affected:** none (verification only)
    — **Done:** smoke run twice (subagent /tmp/opencode/phase2-smoke + orchestrator /tmp/opencode/phase2-verify): identical diff exit 0, drifted diff exit 1 naming DIMENSION, preview.png non-empty; files: none (scratch only); fixes: none

### Phase 3: Image pipeline scripts

- [ ] **3.1** Create `scripts/preflight_image.py`: hash, resolution, blur, contrast, skew/perspective estimate, visible unit/scale-anchor detection → JSON report with `warning` vs `blocker` classified by the selected profile; Pillow/NumPy/OpenCV import-guarded with named `pip install` hints; `--self-check` on a synthetic image
    — **Why:** Mode C step 1 is the evidence gate; a quality warning must become a blocker exactly when the profile requires evidence the image cannot provide
    — **Done when:** `--self-check` exits 0; degraded synthetic image yields flagged report
    — **Consumers affected:** SKILL.md Mode C step 1
- [ ] **3.2** Create `scripts/compare_visual.py`: anchors JSON → affine/homography registration, side-by-side, overlay, difference image, edge coverage + distance stats, all output labelled "visual only"; OpenCV import-guarded; `--self-check` with synthetic anchors
    — **Why:** Mode C step 6 needs registered comparison to find omitted/shifted geometry while never asserting dimensional accuracy
    — **Done when:** `--self-check` exits 0 producing the four comparison artifacts
    — **Consumers affected:** SKILL.md Mode C step 6
- [ ] **3.3** Create `scripts/pdf_vector_to_dxf.py`: PyMuPDF vector paths → ezdxf DXF on generic layers (LINEWORK, TEXT, BORDER, DIM), text written as TEXT only when extractable, else marked uncertain; PyMuPDF import-guarded; `--self-check` on a generated single-page PDF
    — **Why:** Mode B depends on vector-first PDF extraction with honest fallback labeling
    — **Done when:** `--self-check` exits 0; output DXF passes `fingerprint.py`
    — **Consumers affected:** SKILL.md Mode B
- [ ] **3.4** Verify optional-dependency degradation across all image-path scripts: with opencv/pymupdf unavailable, each script exits with a named install hint and no traceback
    — **Why:** the DXF-first zero-required-deps promise is a design decision reviewers will check
    — **Done when:** forced-import-failure run of each script prints the hint and exits non-zero cleanly
    — **Consumers affected:** SKILL.md runtime requirements section

### Phase 4: Agent routing

- [ ] **4.0** Read `LEARNINGS/conventions/task-delegate-permission-sync.md` and apply its 4-sync-surfaces + delegate-ceiling checklist to this phase before editing
    — **Why:** the learning documents exactly this class of change (permission/task delegate edits) and its known blast radius
    — **Done when:** checklist items mapped to steps 4.1–4.3 in the phase notes
    — **Consumers affected:** all Phase 4 edits
- [ ] **4.1** Edit `agents/cad-specialist-subagent.md`: add the `cad-redraw-skill` skill allow rule after the existing cad rules (order matters — last match wins), update the description count 14 → 15, add a routing line (source-DWG/PDF/image redraw → cad-redraw-skill; 3D solids → cad-generation-skill)
    — **Why:** the skill is subagent-only like the whole CAD family; without the allow rule and routing the skill is dead weight
    — **Done when:** grep shows 15 `action: skill` rules including `cad-redraw-skill`, description reads 15, routing line present; `node installer/build-registry.mjs` rerun so `--check` exits 0 (agent frontmatter is scanned into the registry — same per-commit invariant as step 1.1)
    — **Consumers affected:** opencode agent loader, registry frontmatter scan, pack-cad description
- [ ] **4.2** Sweep `README.md` (Subagents table) and `deploy/setup.sh` / `deploy/setup.ps1` help text for hardcoded "14"/skill-count claims tied to cad-specialist and sync any found
    — **Why:** stale counts fail documentation-consistency checks and mislead `npx add` users
    — **Done when:** `grep -rnE "orchestrat(es|ing) 14" README.md deploy/` returns nothing (installer/ surfaces are owned by 5.2/5.4, which run after pack-cad lands)
    — **Consumers affected:** deploy users, doc-consistency gates

### Phase 5: Registry and docs sync

- [ ] **5.1** Run `node installer/build-registry.mjs` and verify `installer/registry.json` lists `cad-redraw-skill` with correct frontmatter-derived metadata; run `node installer/build-registry.mjs --check` as the drift guard. `docs/registry.json` is out of scope: gitignored copy emitted by `installer/build-site.mjs` at release (release.yml) from the installer registry — never committed, never hand-generated
    — **Why:** AGENTS.md mandates the registry rebuild after any frontmatter change, and `--check` makes the done-when CI-verifiable; asserting the gitignored docs copy would be an unachievable check
    — **Done when:** `installer/registry.json` contains the skill and `--check` exits 0
    — **Consumers affected:** preset derivation (5.2), doc totals (5.3)
- [ ] **5.2** Hand-edit `installer/presets/pack-cad.json` (verified: the `/tmp/gen-presets.mjs` generator no longer exists and no generator lives in `installer/`): skills array to 15 entries including `cad-redraw-skill`, description count 14 → 15; verify array contents exactly match the registry's cad-family skill set
    — **Why:** `init.mjs --preset cad` must install the new skill; the derivation source is the freshly rebuilt registry, and the hand-edit path is pre-authorized by the file's own `$comment` fallback and PLAN risk #3
    — **Done when:** pack-cad.json lists 15 skills including `cad-redraw-skill`, description reads 15, and the array equals the registry's cad set
    — **Consumers affected:** installer preset users
- [ ] **5.3** Update the doc count surfaces: `README.md` CAD & Hardware Design row (~598: count 14 → 15, add `cad-redraw-skill` + blurb), README preset-table row (~266: `15 (CAD & Hardware Design)`), the four hand-maintained totals in README.md (~15, ~250, ~409, ~566: "149 skill directories" → 150), and `opencode_app/README.md` (~30: 149 → 150); agents stay 34, categories stay 24
    — **Why:** these are number-keyed bare counts (two without BT-157 markers) that no name-keyed sweep can flag; house precedent PLAN-GIT-364 §4.1 bumps totals in-ticket
    — **Done when:** `grep -rn "149 skill" README.md opencode_app/README.md` returns nothing, all five sites read 150, and the preset row reads `15 (CAD & Hardware Design)`
    — **Consumers affected:** doc-consistency checks, humans, installer users
- [ ] **5.4** Run the documentation-sync-workflow pass (or equivalent manual sweep) across `deploy/setup.sh`, `deploy/setup.ps1`, `opencode_app/README.md`, and banner text for any remaining stale CAD counts or missing listing
    — **Why:** the sync workflow is the house gate catching orphan references the targeted edits miss
    — **Done when:** full number- and verb-keyed sweep `grep -rnE "orchestrat(es|ing) 14|149 skill" README.md deploy/ installer/ opencode_app/` returns nothing and the workflow reports zero drift for cad-redraw-skill surfaces
    — **Consumers affected:** all doc surfaces
- [ ] **5.5** Run full verification gates: `ruff check` + `ruff format --check` on the new scripts (fallback `python -m py_compile` if ruff absent), `bats tests/`, all script `--self-check`s, and the Phase 2 E2E smoke; fix any red
    — **Why:** the ticket's final acceptance criteria are the gates, and the pipeline PR cannot open on red
    — **Done when:** ruff (or compile fallback), bats, self-checks, and smoke all exit 0
    — **Consumers affected:** PR CI (Step 10), code review

## Technical Notes

- Draw engine: ezdxf; DWG via `ezdxf.addons.odafc` when ODA File Converter installed, LibreDWG `dwg2dxf` fallback; DXF is the default deliverable
- FreeCAD: out of scope as a dependency; documented as import/inspection target only
- 3D solids defer to `cad-generation-skill` (build123d)
- Validation: fingerprint diff + dispositions (`pass`, `pass_with_warnings`, `needs_review`, `blocked`, `fail`); pixel comparison never proves dimensional accuracy
- Commit sequence: ① `feat(skills): add cad-redraw-skill contract and references` → ② `feat(skills): add cad-redraw fingerprint and spec-to-dxf scripts` → ③ `feat(skills): add cad-redraw image pipeline scripts` → ④ `feat(agents): route dwg/image redraw to cad-redraw-skill` → ⑤ `chore(registry): register cad-redraw-skill`
- Deviation from the ticket's commit plan: `installer/registry.json` rebuilds ride commits ① and ④ (not only ⑤) because `tests/init.bats` + `tests/deploy_delegate.bats` enforce registry-vs-disk equality per commit (BT-157); step 5.1 remains as the final `--check` verification pass
- House frontmatter contract per root `AGENTS.md`; no `model:` in agent edits (tier-injected at deploy)
- Untouched by design: `deploy/skill-profiles.json`, `opencode_app/opencode.json` (skill stays subagent-only)

## Dependencies

- None external (no blocked-by tickets). Optional runtime deps (ezdxf required; ODA/LibreDWG, Pillow, NumPy, OpenCV, PyMuPDF optional with import guards) are user-installed, not repo dependencies.

## Risks & Mitigation

- ODA File Converter is GUI-linked; headless may need `QT_QPA_PLATFORM=offscreen` → documented in `linux-toolchain.md` and reported per-run by `fingerprint.py`
- LibreDWG coverage of recent DWG versions is partial → converter + fidelity always reported; ODA recommended for modern DWGs
- Preset regeneration path: generator verified absent (`/tmp/gen-presets.mjs` gone, none in `installer/`) → surgical hand-edit pre-authorized, verified against the rebuilt registry (step 5.2)
- Stale "14" counts scattered in docs → dedicated sweep steps 4.2 and 5.4 plus doc-sync pass
- Optional deps absent in CI/dev → import guards with named hints; self-checks skip image-path assertions only when deps are truly absent, and say so
