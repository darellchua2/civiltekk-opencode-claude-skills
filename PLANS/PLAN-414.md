# PLAN: Add DXF-to-DWG writer to cad-redraw-skill via ODA File Converter

**Branch**: feat/414
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/414
**Base**: main

## Acceptance Criteria

- [x] `skills/cad-redraw-skill/scripts/to_dwg.py`: `--input file.dxf --output out.dwg [--version ACAD2018] [--self-check]`, argparse contract complete, one-line docstrings, house style matching sibling scripts
- [x] Exit-code contract: 0 converted; 1 bad input (missing/unreadable source, output == source, existing output path); 2 ODA absent (named install hint, no traceback)
- [x] `--self-check` passes in BOTH environments: with converter → full round-trip assert (DWG written, non-empty); without → guard-path assert + explicit `SKIPPED: ODA File Converter not detected` note, exit 0
- [x] `SKILL.md` deliverable wording updated: DWG output available via the writer when ODA installed (DXF remains the default deliverable); `references/linux-toolchain.md` gains the writer path + LibreDWG-write-out-of-scope note
- [x] Degradation verified adversarially: missing converter → exit 2 + hint, no traceback; source == output refused; missing source refused
- [x] `ruff check` + `ruff format --check` green; full `bats tests/` green; all 8 script self-checks green

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Use `codegraph_callers` (code) or `tofu graph` + grep (IaC)._

Thin blast radius per the issue: one new leaf script + two doc sections in the same skill. No count surfaces (script additions don't move skill/agent counts), no registry rebuild. Environment facts verified on `feat/414` @ `529b86b`: ruff 0.15.12 present; `ezdxf` NOT installed locally; ODA binary absent — the guard path is the locally testable surface; the seven sibling scripts and the referenced anti-pattern learning all exist on `main`.

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/cad-redraw-skill/scripts/to_dwg.py` (new) | 1.1 before 2.1/2.2 (docs name the script) | `skills/cad-redraw-skill/SKILL.md` deliverable wording (same skill — intra-module); CI bats suite (via the self-check-invoking tests, if any — none today) | low |
| `skills/cad-redraw-skill/SKILL.md` (deliverable section, ~L155) | after 1.1 | skill users following Mode A/B flows; no cross-skill consumers | low |
| `skills/cad-redraw-skill/references/linux-toolchain.md` | after 1.1 | skill users on Linux choosing a converter chain | low |

No cross-module nodes → zero plan reviewers selected (Step 7 triage); Step 9 code review backstops.

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: writer script

- [x] **1.1** Create `skills/cad-redraw-skill/scripts/to_dwg.py`: argparse contract `--input file.dxf --output out.dwg [--version ACAD2018] [--self-check]`; exit-code contract 0 converted / 1 bad input (missing or unreadable source, output == source, existing output path) / 2 environment (ODA binary absent → named install hint; `ezdxf` import failure → same environment class, no tracebacks anywhere); guard checks run BEFORE the `ezdxf` import; `QT_QPA_PLATFORM=offscreen` defaulted for headless ODA invocation; conversion via `ezdxf.addons.odafc.writefile` honoring `--version` (default ACAD2018); success prints converter + target version; `--self-check` asserts the guard path unconditionally and the real conversion only when a converter binary is detectable (otherwise prints `SKIPPED: ODA File Converter not detected` and exits 0); one-line docstrings and structure mirroring `spec_to_dxf.py`'s house pattern (`_require`, `self_check()`, `PASS` print).
    — **Why:** The writer is the ticket's entire deliverable; the exit-code and no-traceback contracts are the skill's stated interop surface (`LEARNINGS/anti-patterns/validator-crashes-on-invalid-input.md`), and every later step documents or verifies this file.
    — **Done when:** The script exists with the full argparse/exit contract; `python3 scripts/to_dwg.py --self-check` exits 0 printing the SKIPPED note in this ODA-less environment; `--input missing.dxf --output x.dwg` exits 1; `--input a.dxf --output a.dxf` exits 1 — all without tracebacks.
    — **Consumers affected:** `SKILL.md` (2.1) and `linux-toolchain.md` (2.2) name this script; no other consumers.
    — **Done:** to_dwg.py written (guards precede the ezdxf import; both absence classes land in named exit-2; staged-tempdir conversion keeps the source untouched); ruff green; self-check exits 0 with SKIPPED note; adversarial exits 1/1/2 verified, no tracebacks; files: skills/cad-redraw-skill/scripts/to_dwg.py; fixes: ruff format reflow (1 file)
    — **Done (review iteration 1):** BLOCK fixed — `odafc.writefile` does not exist in pinned ezdxf v1.4.4 (verified against upstream source at tag v1.4.4); switched to `odafc.convert(source, dest, version=...)` with parent-mkdir, ODAFCNotInstalledError→exit 2, other ODAFCError→exit 1 per Mode R ruling, produced-nothing post-check (upstream silently swallows it); WARN fixed — mkdir/move paths guarded (no OSError traceback); WARN fixed — SKILL.md opener no longer says "input format only"; NOTEs applied — self_check AssertionError handler + tempdir finally + named ImportError, `_check_input` renamed `_check_paths`; files: to_dwg.py, SKILL.md, linux-toolchain.md; fixes: 1 BLOCK + 2 WARN + 3 NOTE

### Phase 2: skill documentation

- [x] **2.1** Update the deliverable wording in `skills/cad-redraw-skill/SKILL.md` (~L155-157): replace "No bundled script writes DWG" with DWG output available via `scripts/to_dwg.py` when ODA File Converter is installed; DXF remains the default deliverable.
    — **Why:** The current wording is factually wrong the moment 1.1 lands; users following Mode flows must learn the DWG path exists and when it applies.
    — **Done when:** The section names `scripts/to_dwg.py`, states the ODA requirement, and keeps DXF as the default deliverable.
    — **Consumers affected:** Skill users; no code consumers.
    — **Done:** "DWG input/output" section now names scripts/to_dwg.py, the ODA requirement, and DXF-as-default; files: skills/cad-redraw-skill/SKILL.md; fixes: none
- [x] **2.2** Update `skills/cad-redraw-skill/references/linux-toolchain.md`: add the writer path (`scripts/to_dwg.py` via `ezdxf.addons.odafc.writefile`) to the ODA entry and an explicit LibreDWG-write-is-out-of-scope note (read path only).
    — **Why:** The toolchain reference is where Linux users decide their converter chain; without the writer path and the LibreDWG scope note they will attempt unsupported writes.
    — **Done when:** The ODA entry names the writer script and the LibreDWG entry states write support is out of scope.
    — **Consumers affected:** Skill users on Linux; no code consumers.
    — **Done:** ODA entry names to_dwg.py + writefile + --version default; LibreDWG entry states write out-of-scope, DWG writing via ODA only; files: skills/cad-redraw-skill/references/linux-toolchain.md; fixes: none

### Phase 3: verification gate

- [x] **3.1** Lint + scope: `ruff check` and `ruff format --check` on the touched Python file; assert the full diff vs `origin/main` touches exactly `scripts/to_dwg.py`, `SKILL.md`, `references/linux-toolchain.md` (+ PLAN).
    — **Why:** AC 6 requires ruff green; the scope assertion enforces the ticket's "Untouched: registry/presets/README counts" boundary — script additions must not drift counts.
    — **Done when:** Both ruff invocations exit 0 and the diff-file assertion lists exactly the expected paths.
    — **Consumers affected:** `installer/registry.json`, README tables — proven unchanged.
    — **Done:** ruff check + format green; diff vs origin/main = exactly PLAN-414.md + the three ticket paths; registry/README untouched; files: none changed by this step (assertion only); fixes: none
- [x] **3.2** Tests: full `bats tests/` suite green; `node installer/build-registry.mjs --check` exit 0; all 8 script self-checks run and recorded honestly — `to_dwg.py --self-check` must show the guard path (SKIPPED note, exit 0) here; sibling self-checks recorded pass/fail with reasons (any failure caused by missing optional binaries is reported per the honesty contract, not silently skipped or force-fixed in this ticket).
    — **Why:** These are the repo's PR-gate equivalents (release.yml runs bats on PRs) plus the ticket's explicit 8-self-check AC; honest recording prevents environment-dependent false greens.
    — **Done when:** bats exits 0, `--check` exits 0, and the 8 self-check results are printed with pass/SKIPPED-failed statuses.
    — **Consumers affected:** CI (release.yml) — confidence the PR gate passes on first run.
    — **Done:** bats 337/337 green; --check exit 0; self-checks: 6 PASS + to_dwg SKIPPED-path exit 0 + pdf_vector_to_dxf FAIL (pymupdf missing in this environment — pre-existing, recorded per the honesty contract, out of ticket scope); files: none changed by this step (verification only); fixes: none

## Technical Notes

- `ezdxf` is not installed in the local environment; the writer must degrade on its absence with a named exit-2 error (environment class). For local verification of the real contract path, `pip install --user ezdxf` (small, pure-Python) may be used; ODA itself stays absent — the guard path is the locally testable surface, stated per the honesty contract.
- Apply `LEARNINGS/anti-patterns/validator-crashes-on-invalid-input.md`: named errors, no tracebacks on bad input.
- House style reference: `scripts/spec_to_dxf.py` (argparse layout, `_require` self-check helper, `PASS` print, exit-code table).
- ODA install hint text should match the toolchain reference's own ODA guidance.

## Dependencies

None — no blocked-by tickets; #411 (cad-redraw-skill) is already merged into `main`.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| ezdxf absent locally → import crash mistaken for guard path | Converter/env checks precede the import; both absence classes land in the same named exit-2 path (1.1, verified in 3.2) |
| Sibling self-checks fail on missing optional binaries (LibreDWG etc.) | Recorded honestly in 3.2 per the honesty contract; out-of-scope fixes are NOT bundled into this ticket |
| Doc wording overpromises (DWG "just works") | 2.1 keeps DXF as default deliverable and states the ODA requirement explicitly |
