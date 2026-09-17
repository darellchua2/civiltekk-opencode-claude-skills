## Pattern: Frontmatter SHAPE change blast radius — 6 consumer classes (tests included)

**Context**: Changing the frontmatter *format* of `agents/*.md` (e.g. #380 `permission:` map → `permissions:` array), as opposed to changing a value.
**Pattern**: Sweep SIX consumer classes before sign-off — the two existing surface checklists (task-delegate-permission-sync: 4 surfaces; tier-model-swap-blast-radius: 7 surfaces) cover neither test class:
1. Structural parsers — `installer/build-registry.mjs` parseFrontmatter (the only keysOf/fm.permission consumer)
2. **Tests that grep literal shape strings** — `grep -q "<skill>: allow"` dies when the map line becomes `- resource: <skill>` (test_autoresearch_skills.bats:137,141,145; test_markitdown_skill.bats:59; test_docling_skill.bats:129)
3. **Tests that YAML-parse the shape** — `python3 yaml.safe_load` then `fm['permission']['edit']` KeyErrors post-flip (test_autoresearch_skills.bats:111,124)
4. Deploy injectors — regex-only `^model:` line filters are shape-agnostic (init.mjs:448, resolve-models.mjs:85, tui-primitives.mjs:186) — verify, don't assume
5. Docs claiming the spelling — README.md:252,268,409; opencode_app/README.md:189; opencode-skill-creation-skill/SKILL.md:283,317
6. Runtime (opencode v2 native read / auto-translate path)
**Rationale**: Literal-string and yaml-parse test assertions are invisible to `grep -rn 'permission'` sweeps that only look for the key in code; they fail only at full-suite time (Phase 4), the latest possible moment.
**Verification**: `grep -rn ': allow\|: deny' tests/*.bats` + `grep -rn 'permission' tests/*.bats` + `grep -rn 'legacy.*permission\.' --include='*.md' .`
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-17

**Evidence**: #380 plan review — 8 test blocks in 3 bats files structurally consume the legacy map form; plan's consumer map listed only registry/init/resolve/setup/runtime and would have hit red CI at Phase 4 with no owning step.
— **including agent-body fenced examples**: opencode-tooling-subagent.md:169-184,:352 taught the `permission:` map shape inside its own body docs — caught at code review post-#380 (body byte-identity had deliberately deferred it; fixed in the same hash-churn branch).
