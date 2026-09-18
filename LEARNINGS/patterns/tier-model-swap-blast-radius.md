## Pattern: Tier→model swap blast radius (7 surfaces, plus deploy-script echoes)

**Context**: When swapping a model pinned to an agent tier in this repo (models.default.json / provider-presets.json)
**Pattern**: The swap touches SEVEN distinct surfaces — audit all of them before declaring done:
1. `deploy/models.default.json` tier pins (source of truth)
2. `deploy/provider-presets.json` — every provider preset that maps the tier
3. `deploy/provider-models.json` guard arrays + `$comment` EXCEPTIONS prose (must track models.dev, not pricing pages)
4. Agent `.md` frontmatter `description` AND body → forces `deploy/registry.json` regen (same commit, or CI `--check` drift gate fails)
5. SKILL prose that routes work to the tier: error-resolver-workflow, opencode-agent-creation (templates new agents — stale pin replicates), zai-vision-analysis
6. Human docs tier tables: AGENTS.md, README.md
7. **Hardcoded model echoes in deploy scripts** — e.g. `setup.sh --status` prints `Model: zai-coding-plan/glm-4.7` (line ~3793); grep `deploy/*.sh`, `*.ps1` for the old model id, not just JSON
8. Value-pinned test assertions — `tests/init.bats` #401c asserts the fast-tier model by value (`zai-coding-plan/glm-5.3-flash`); a tier swap must update that line too (added by #401)
**Rationale**: Config-driven resolution hides prose dependencies; a stale SKILL.md or script echo keeps routing/presenting the retired model after the JSON is correct.
**Verification commands**:
- `node deploy/build-registry.mjs --check` (registry drift)
- `node deploy/resolve-models.mjs --agents-src opencode_app/.opencode/agents --agents-dest /tmp/x --tiers deploy/agent-tiers.json --default-map deploy/models.default.json --provider-models deploy/provider-models.json --dry-run` (guard passes, exit 0)
- grep for the old model id; classify each hit as exempt (research/, CHANGELOG, fallback-mechanism internals) or stale
**Trade-offs**: None — pure audit checklist.
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-08-27

**Evidence**:
- GIT-349 (vision→glm-5.3-flash native, docs→glm-5.3-flash): all 7 surfaces handled except #7 — setup.sh:3793 still echoes glm-4.7 post-swap
- Fallback-model disambiguation is part of the pattern: when native and fallback models diverge, every fallback reference must say "different model" (image-analyzer:51, error-resolver-workflow:98, zai-vision-analysis:15)
- provider.<name>.models blocks in opencode.json are pure overlays on models.dev catalog providers — safe to delete once the catalog lists the model (verified GIT-349)
