# PLAN: Fix pptx hardcoded `.opencode/skills` snippet paths

**Branch**: feat/511
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/511
**Base**: main

## Acceptance Criteria
- [ ] Snippets execute with the skill directory at an arbitrary location (verified by copying a skill dir to a temp location and running one snippet per skill)
- [ ] Vendored `scripts/_common` trees remain byte-identical (skill-isolation guard passes)
- [ ] No `.opencode/skills/` literals remain in either SKILL.md

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/pptx-generate-template-skill/SKILL.md` | — | agents running the template pipeline; #515 guard (path-literal check) | low |
| `skills/pptx-template-modifier-skill/SKILL.md` | slide skill installed as sibling (declared prerequisite — holds at every install target) | agents running the modifier loop | low |
| `skills/pptx-generate-slide-skill/docs/DESIGN-template-agnostic.md:209` | — | maintainers (doc-only) | low |
| `scripts/_common` vendored trees (NOT edited) | — | `tests/test_skill_isolation.bats` byte-identity guard; all pptx scripts (already self-bootstrap via `__file__`) | none |

## Implementation Phases

### Phase 1: generate-template SKILL.md — env-var path resolution

- [x] **1.1** Add a `## Running the snippets` note defining `SKILL_DIR` = the directory containing that SKILL.md (the skill loader prints it; e.g. `~/.config/opencode/skills/pptx-generate-template-skill`), then rewrite the five `python -c` snippet path lines (74, 116, 139, 182, 199) from `sys.path.insert(0,'.opencode/skills/...')` to `sys.path.insert(0, os.path.join(os.environ['SKILL_DIR'], 'scripts', '_common'))` with `import os` added and the invocation prefixed `SKILL_DIR=<skill-dir> `.
    — **Why:** env-var resolution survives every bash invocation shape (double-quoted `-c`, heredocs) and every install target; the loader-stated base dir is the one path the agent always knows.
    — **Done when:** `rg -c "\.opencode/skills" skills/pptx-generate-template-skill/SKILL.md` returns 0 (after 1.2) and a snippet runs from a copied skill dir.
    — **Consumers affected:** agents executing the pipeline; none downstream in-repo.
    — **Done:** note added; 5 snippet lines rewritten (replaceAll); deviation — `export SKILL_DIR=…` once per session instead of per-invocation prefix (same env mechanism, lighter); files: skills/pptx-generate-template-skill/SKILL.md; fixes: none
- [x] **1.2** Update the doc-only engine reference (line 233) to path-neutral wording ("`scripts/_common/schema_extractor.py` inside the skill directory").
    — **Why:** same literal, same bug class, doc surface.
    — **Done when:** no `.opencode/skills` literal remains anywhere in this SKILL.md.
    — **Consumers affected:** none.
    — **Done:** engine reference path-neutral; literals 0; isolation guard green; files: skills/pptx-generate-template-skill/SKILL.md; fixes: none

### Phase 2: template-modifier SKILL.md — own dir + declared-prerequisite sibling

- [ ] **2.1** Add the same `## Running the snippets` note, rewrite block :71–72 (`SKILL_DIR` for its own scripts; `SLIDE_SKILL_DIR` defaulting in-python to the sibling `../pptx-generate-slide-skill/scripts`, overridable via env) and block :138.
    — **Why:** the modifier's cross-skill handoff is the declared prerequisite (isolation-contract exception); sibling resolution matches every install layout where `requiresSkills` co-installs side-by-side.
    — **Done when:** no `.opencode/skills` literal remains in this SKILL.md and the Capability B block imports both modules from a copied dir pair.
    — **Consumers affected:** `pptx-generate-slide-skill` (sibling-presence assumption, already contractual).
- [ ] **2.2** Update the design-doc reference (line 188) to path-neutral wording.
    — **Why:** same literal, doc surface.
    — **Done when:** no `.opencode/skills` literal remains in this file.
    — **Consumers affected:** none.

### Phase 3: slide-skill design doc + verification

- [ ] **3.1** Update `skills/pptx-generate-slide-skill/docs/DESIGN-template-agnostic.md:209` to path-neutral wording.
    — **Why:** last literal in the ticket scope; keeps #515's guard clean.
    — **Done when:** `rg -l "\.opencode/skills" skills/pptx-*/` returns nothing.
    — **Consumers affected:** maintainers.
- [ ] **3.2** Verification: copy both skill dirs to `/tmp/opencode/pptx-probe/`, run one snippet per skill with `SKILL_DIR` pointing there (extract_schema import; state_machine import with sibling slide skill), run `bats tests/test_skill_isolation.bats` (vendored trees untouched), then the full exit gate.
    — **Why:** the ticket's AC is behavioral (works from an arbitrary location), not textual.
    — **Done when:** both probe imports succeed, isolation guard green, full suite green.
    — **Consumers affected:** installer (registry unchanged — no frontmatter edits; assert byte-identical).

## Technical Notes
- The scripts already self-bootstrap (`_COMMON_SCRIPTS = Path(__file__).resolve().parent / "_common"` — e.g. master_cloner.py:29, ppt_builder.py:44); only SKILL.md prose hardcodes paths. No script edits → vendored trees stay byte-identical by construction.
- `os.environ['SKILL_DIR']` is chosen over shell interpolation (`'$SKILL_DIR/...'`) because it also works inside quoted heredocs; both snippet styles here are double-quoted `-c` strings, but uniformity survives future refactors.
- Sibling model for `SLIDE_SKILL_DIR`: `npx add` (`requiresSkills`), user-level, project-level, and `--target claude/agents/kimi/kilo` all co-install declared prerequisites as siblings of the owner skill.

## Dependencies
- #510 (portability conventions) — merged; the guard in #515 will enforce this literal ban.

## Risks & Mitigation
- *Agent copies snippets without setting `SKILL_DIR`* → the note names the loader-printed base dir explicitly; KeyError from `os.environ` fails loud, not silent.
- *Slide skill not a sibling on some exotic layout* → `SLIDE_SKILL_DIR` env override documented inline.
