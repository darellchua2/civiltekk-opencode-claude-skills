## Pattern: Tier→model swap blast radius (7 surfaces, plus deploy-script echoes)

**Context**: When swapping a model pinned to an agent tier in this repo (models.default.json / provider-presets.json)
**Pattern**: The swap touches SEVEN distinct surfaces — audit all of them before declaring done:
1. `installer/models.default.json` tier pins (source of truth)
2. `installer/provider-presets.json` — every provider preset that maps the tier
3. `installer/provider-models.json` guard arrays + `$comment` EXCEPTIONS prose (must track models.dev, not pricing pages)
4. Agent `.md` frontmatter `description` AND body → forces `installer/registry.json` regen (same commit, or CI `--check` drift gate fails)
5. SKILL prose that routes work to the tier: error-resolver-workflow, opencode-agent-creation (templates new agents — stale pin replicates). (Formerly also zai-vision-analysis; skill removed GIT-364 — native multimodal vision agents are the only path.)
6. Human docs tier tables: AGENTS.md, README.md
7. **Hardcoded model echoes in deploy scripts** — grep `deploy/*.sh`, `*.ps1` for the old model id, not just JSON. (The former `setup.sh --status` hardcoded `Model: zai-coding-plan/glm-4.7` echo is resolved — it now prints the resolved `Model: ${primary_model}` dynamically; a future hardcoded echo would reintroduce this surface.)
8. Value-pinned test assertions — `tests/init.bats` #401c asserts the fast-tier model by value (`zai-coding-plan/glm-5.3-flash`); a tier swap must update that line too (added by #401)
**Rationale**: Config-driven resolution hides prose dependencies; a stale SKILL.md or script echo keeps routing/presenting the retired model after the JSON is correct.
**Verification commands** (run verbatim; both verified green 2026-09-21):
- `node installer/build-registry.mjs --check` (registry drift)
- `node installer/resolve-models.mjs --agents-src agents --agents-dest /tmp/opencode/x --tiers installer/agent-tiers.json --default-map installer/models.default.json --provider-models installer/provider-models.json --dry-run` (guard passes, exit 0)
- grep for the old model id; classify each hit as exempt (research/, CHANGELOG, fallback-mechanism internals) or stale
**Trade-offs**: None — pure audit checklist.
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-08-27

> **Update 2026-09-21 (#506):** all `deploy/` paths above moved to `installer/` in #378; the
> resolver's `--agents-src` is the root `agents/` tree (`opencode_app/.opencode/agents` no longer
> exists), and surface 7's hardcoded echo was replaced by the dynamic `Model: ${primary_model}`
> print. Both verification commands above were re-run verbatim on this tree and pass.

**Evidence**:
- GIT-349 (vision→glm-5.3-flash native, docs→glm-5.3-flash): all 7 surfaces handled except #7 — setup.sh:3793 still echoed glm-4.7 post-swap (since resolved; see the update note above)
- Fallback-model disambiguation is part of the pattern: when native and fallback models diverge, every fallback reference must say "different model" (image-analyzer:51, error-resolver-workflow:98, zai-vision-analysis:15)
- provider.<name>.models blocks in opencode.json are pure overlays on models.dev catalog providers — safe to delete once the catalog lists the model (verified GIT-349)
