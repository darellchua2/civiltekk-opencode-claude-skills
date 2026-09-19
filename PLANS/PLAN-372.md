# PLAN: Move uiux-reviewer-subagent to vision tier (native multimodal)

**Branch**: feat/372
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/372
**Base**: main

## Acceptance Criteria

- [x] `deploy/agent-tiers.json`: `uiux-reviewer-subagent` → `vision` (+ short `$comment` NOTE, house style)
- [x] `uiux-reviewer-subagent.md` frontmatter `description`: native multimodal reading, image-analyzer delegation on failure/request
- [x] `uiux-reviewer-subagent.md` Step 3 (~line 74): mandatory-delegation rule → native-first, delegate on request/failure
- [x] `uiux-reviewer-subagent.md` §Screenshot Delegation Rule (~lines 107-109): replace text-only claims with hybrid rule + `Status: partial` escape hatch
- [x] `uiux-reviewer-subagent.md` echo sites (~lines 146, 158, 187-188, 198): no line mandates universal delegation; success/partial status definitions reflect the hybrid rule
- [x] `opencode-agent-creation-skill/SKILL.md:52`: vision-tier enumeration includes `uiux-reviewer-subagent`
- [x] `uiux-review-skill/SKILL.md:65`: evidence gate accepts native multimodal reading OR image-analyzer evidence; still rejects vision-unbacked claims
- [x] Root `AGENTS.md` tier table: uiux removed from reasoning row, added to vision row (+ fallback sentence)
- [x] `deploy/registry.json` regenerated (`node deploy/build-registry.mjs`)
- [x] `node deploy/resolve-models.mjs --dry-run` → uiux resolves to `zai-coding-plan/glm-5.3-flash`, guard exit 0
- [x] `node deploy/build-registry.mjs --check` → no drift
- [x] stale-claim sweep on the two edited uiux files → no stale text-only/delegation-mandate claims (fallback-condition mentions retained intentionally)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/agent-tiers.json` | — | `resolve-models.mjs` (deploy-time model injection), `build-registry.mjs` (embeds `tier`), README/AGENTS tier tables (human docs) | med — a typo'd tier name breaks deploy resolution; guard in 1.2 fail-fasts |
| `opencode_app/.opencode/agents/uiux-reviewer-subagent.md` | `deploy/agent-tiers.json` (model injected at deploy time) | `deploy/registry.json` (generated: description, delegatesTo, tier), `responsive-audit-subagent.md` + `worktree-pipeline-skill` (delegation references — unchanged, still true) | med — description flows into the registry, so registry regen rides the same commit as each frontmatter-affecting step (1.3, 2.1); final regen + drift check in 4.3 |
| `opencode_app/.opencode/skills/uiux-review-skill/SKILL.md` | — | `uiux-reviewer-subagent.md` (loads it as rubric source of truth), `deploy/registry.json` (requiresSkills) | low |
| `AGENTS.md` (root, tier table) | `deploy/agent-tiers.json` (mirrors it) | human readers; `deploy/.AGENTS.md` does NOT contain the table (verified) | low |
| `deploy/registry.json` | generated from agent-tiers.json + agent/skill frontmatter | installer (`init.mjs`, `setup.sh` counts), CI `--check` drift gate | low (generated artifact) |

**Cross-module consumers exist** (deploy tooling consumes the tier registry) → architecture review selected at Step 7. No frontend signal (no tsx/jsx/vue/svelte/css) → uiux review skipped. Freshly generated PLAN → requirements review selected.

## Implementation Phases

### Phase 1: Tier registry + resolution guard
- [x] **1.1** In `deploy/agent-tiers.json`, change line 16 to `"uiux-reviewer-subagent": "vision"` and append one `$comment` NOTE sentence documenting the move (house style of the #294/#357 NOTEs)
    — **Why:** tier registry is the source of truth; every other surface (model injection, registry, docs) derives from it, so it must flip first
    — **Done when:** file is valid JSON, the entry reads `"vision"`, and the `$comment` NOTE names the reviewer and the vision rationale
    — **Consumers affected:** `resolve-models.mjs`, `build-registry.mjs`, AGENTS.md tier table
    — **Done:** tier flipped + entry moved into the vision block + NOTE (#372) appended; files: deploy/agent-tiers.json; fixes: none
- [x] **1.2** Run `node deploy/resolve-models.mjs --agents-src opencode_app/.opencode/agents --agents-dest /tmp/opencode/plan-372 --tiers deploy/agent-tiers.json --default-map deploy/models.default.json --provider-models deploy/provider-models.json --dry-run` and confirm the guard exits 0 with `uiux-reviewer-subagent` resolving to `zai-coding-plan/glm-5.3-flash`
    — **Why:** fail-fast proof that the tier move resolves cleanly under the Z.AI default map and every provider guard, before any prose or generated files change
    — **Done when:** command exit 0 and its output line for `uiux-reviewer-subagent` shows `zai-coding-plan/glm-5.3-flash`
    — **Consumers affected:** none (verification only)
    — **Done:** exit 0, line `uiux-reviewer-subagent vision zai-coding-plan/glm-5.3-flash WRITE`; files: none; fixes: none
- [x] **1.3** Regenerate `deploy/registry.json` via `node deploy/build-registry.mjs` and commit it in the SAME commit as 1.1
    — **Why:** the registry embeds each agent's `tier`; the `tier-model-swap-blast-radius` learning requires same-commit regen or intermediate per-phase CI runs hit the `--check` drift gate
    — **Done when:** the Phase 1 commit contains both the tier flip and a registry showing `"tier": "vision"` for `uiux-reviewer-subagent`
    — **Consumers affected:** installer registry consumers (`init.mjs`, `setup.sh` counts — counts unchanged)
    — **Done:** `wrote registry.json (agents=33, skills=148)`, `registry OK … no drift`, uiux entry tier=vision at registry.json:644; files: deploy/registry.json; fixes: none

### Phase 2: Agent prose — hybrid vision policy
- [x] **2.1** In `opencode_app/.opencode/agents/uiux-reviewer-subagent.md`, rewrite the frontmatter `description` to: review-only UI/UX design review — 13-axis rubric over screenshots, source, live URLs; native multimodal screenshot reading with image-analyzer delegation on failure or request — then regenerate `deploy/registry.json` in the same commit
    — **Why:** the description drives invocation routing AND flows into `deploy/registry.json`; leaving "delegates screenshots to image-analyzer" would understate the new native capability in both places, and same-commit regen keeps the CI `--check` gate green per phase
    — **Done when:** description reads ≤1024 chars, preserves the trigger phrases from `README.md:668` ("design review", "UI audit", "UX review", "visual review", "review UI design"), mentions native multimodal reading, and the registry diff shows the new description
    — **Consumers affected:** `deploy/registry.json`, primary-session routing
    — **Done:** description rewritten (trigger phrase "design review" preserved); registry regenerated in-phase, `--check` clean ("no drift"); files: opencode_app/.opencode/agents/uiux-reviewer-subagent.md, deploy/registry.json; fixes: none
- [x] **2.2** Rewrite Step 3 (~line 74): replace the "Mandatory delegation rule: the primary session is text-only — you MUST NOT attempt to interpret screenshot pixels yourself" block with native-first interpretation of captured screenshots at each breakpoint, delegating to `image-analyzer-subagent` via the Task tool only when explicitly requested or when native perception fails, keeping the expected-output finding-schema contract
    — **Why:** the operative workflow step still mandates universal delegation, which would leave the vision-tier capability unused and contradict 2.1
    — **Done when:** Step 3 states native interpretation as primary, delegation as conditional, and retains the rubric-question + finding-schema handoff text for the delegated path
    — **Consumers affected:** `uiux-review-skill` §evidence gate (aligned in 3.1)
    — **Done:** Step 3 retitled "Visual Analysis (native first, delegate on failure)"; delegation now conditional (explicit request OR perception failure); finding-schema handoff retained; files: opencode_app/.opencode/agents/uiux-reviewer-subagent.md; fixes: none
- [x] **2.3** Rewrite §Screenshot Delegation Rule (~lines 107-109) from the text-only hard constraint to the hybrid rule — mirror `error-resolver-subagent.md:64-71` phrasing: runs on `zai-coding-plan/glm-5.3-flash` and sees screenshots directly; delegate to `image-analyzer-subagent` on explicit request or native-perception failure; if both paths are unavailable report `Status: partial` with `Issues: visual findings unavailable` — never fabricate visual findings; also reword the line-103 reference to "the `image-analyzer-subagent` delegation rule" to match
    — **Why:** these are the hard-constraint statements that forbid what the new model can do; stale text-only claims would make the agent self-describe a false capability limit
    — **Done when:** stale-claim sweep clean — no line claims the agent is text-only or mandates universal delegation (fallback-conditional mentions of "text-only session" describing the FAILURE path are intentional, mirroring `error-resolver-subagent.md:67`); no-fabrication escape hatch survives
    — **Consumers affected:** `responsive-audit-subagent.md` + `worktree-pipeline-skill` delegation references (verified still-true: delegation path continues to exist)
    — **Done:** §Screenshot Vision Rule rewritten (hybrid, escape hatch preserved, "BOTH paths" partial trigger); line-103 reference reworded; sweep `runs in a text-only model context|never inline|always delegate|MUST NOT attempt to interpret` → 0 hits; intentional deviation: 2 fallback-context "text-only session" mentions retained per the mirror-error-resolver instruction; files: opencode_app/.opencode/agents/uiux-reviewer-subagent.md; fixes: none
- [x] **2.4** Sweep the remaining mandatory-delegation restatements in `uiux-reviewer-subagent.md` to the hybrid rule: line ~146 Delegation bullet ("**Screenshots**: always `image-analyzer-subagent` (never inline)"), line ~158 output field ("Screenshots delegated to image-analyzer: N"), lines ~187-188 success/partial status definitions, line ~198 do-not-return item ("Inline screenshot interpretations (always delegate)")
    — **Why:** these echo sites re-state the old universal-delegation rule WITHOUT containing the string "text-only" (review finding), so the 4.3 grep gate cannot see them; left untouched, the agent contradicts its own native-first policy and a native-only review can never return `success`
    — **Done when:** no line in the file mandates universal delegation; `success` requires visual findings read natively or verified via `image-analyzer-subagent`; `partial` triggers only when BOTH paths are unavailable; the output field reports native reads with a delegated count when delegation was used; the do-not-return item becomes "visual findings without vision-derived backing"
    — **Consumers affected:** `responsive-audit-subagent.md` + `worktree-pipeline-skill` references (tier-agnostic, verified)
    — **Done:** all 4 echo sites rewritten (:146 delegation bullet, :158 output field "read natively: N (delegated: M, when used)", :187-188 status definitions, :198 do-not-return item); files: opencode_app/.opencode/agents/uiux-reviewer-subagent.md; fixes: none

### Phase 3: Skill evidence gate
- [x] **3.1** In `opencode_app/.opencode/skills/uiux-review-skill/SKILL.md` line 65, change the evidence check to accept screenshot evidence from native multimodal reviewer reading OR `image-analyzer-subagent`, rejecting only visual findings with no vision-derived backing (fabricated or code-inferred pixel claims)
    — **Why:** the current gate ("If screenshot interpreted inline, **reject**") would invalidate the reviewer's own native vision evidence — the exact capability this change ships
    — **Done when:** the gate names both valid evidence sources and keeps an explicit reject condition for vision-unbacked claims
    — **Consumers affected:** `uiux-reviewer-subagent` (its rubric source of truth)
    — **Done:** QA-gate check 2 rewritten to accept native multimodal reads OR image-analyzer output; reject condition scoped to vision-unbacked claims; files: opencode_app/.opencode/skills/uiux-review-skill/SKILL.md; fixes: none

### Phase 4: Docs, generated artifacts, verification gate
- [x] **4.1** In root `AGENTS.md`, remove `uiux` from the reasoning row's reviewer list, add `uiux-reviewer-subagent` to the vision row's agent list, and fold it into the vision-fallback sentence
    — **Why:** the tier table is the human-facing mirror of `agent-tiers.json`; drifting tables misroute future tier decisions
    — **Done when:** `rg -n "language/uiux" AGENTS.md` returns nothing and the vision row names `uiux-reviewer-subagent`
    — **Consumers affected:** human readers; none programmatic
    — **Done:** uiux removed from reasoning reviewers list, added to vision row, folded into vision-fallback sentence; sweep `language/uiux` → 0 hits; files: AGENTS.md; fixes: none
- [x] **4.2** In `opencode_app/.opencode/skills/opencode-agent-creation-skill/SKILL.md` line 52, extend the vision-tier enumeration to include `uiux-reviewer-subagent` alongside `image-analyzer-subagent`/`error-resolver-subagent`
    — **Why:** this skill templates new agents; its resident list is the LEARNINGS blast-radius surface #5 ("stale pin replicates") and the only remaining doc that names vision-tier residents without uiux
    — **Done when:** the vision clause at that line names all three agents
    — **Consumers affected:** future agent authoring (templates)
    — **Done:** vision clause now names all three agents; files: opencode_app/.opencode/skills/opencode-agent-creation-skill/SKILL.md; fixes: none (an over-edit removing "review" from the reasoning purpose list was reverted in-step — other reviewers remain reasoning-tier)
- [x] **4.3** Regenerate `deploy/registry.json` via `node deploy/build-registry.mjs`, then run `node deploy/build-registry.mjs --check` (expect clean) and the stale-claim sweep `rg -n "runs in a text-only model context|primary session is text-only|never inline|always \`image-analyzer-subagent\`|always delegate|MUST NOT attempt to interpret" opencode_app/.opencode/agents/uiux-reviewer-subagent.md opencode_app/.opencode/skills/uiux-review-skill/SKILL.md` (expect no hits; fallback-conditional "text-only session" mentions describing the failure path are intentional)
    — **Why:** the registry embeds `tier` and `description` and CI runs a `--check` drift gate — this final idempotent regen captures any residual drift; the refined pattern targets stale CLAIMS (not the hybrid rule's own fallback-condition phrasing, which must remain)
    — **Done when:** `--check` exits 0 and the stale-claim sweep returns nothing
    — **Consumers affected:** installer registry consumers (`init.mjs`, `setup.sh` counts — counts unchanged)
    — **Done:** regen + `--check` "no drift"; stale-claim sweep exit 1 (zero hits); files: deploy/registry.json (idempotent); fixes: none

## Technical Notes

- Source agent `.md` files ship no `model:` — the resolver injects it at deploy time from the tier registry. Nothing to edit in deployed copies.
- Blast radius pre-audited per `LEARNINGS/patterns/tier-model-swap-blast-radius.md`: all 7 surfaces, including surface #5 (agent-creation template) now handled by step 4.2 and surface #4 echo sites by step 2.4 (review findings). Explicitly NO change: `deploy/provider-presets.json` (every preset already maps the vision tier — verified), `deploy/provider-models.json` (`glm-5.3-flash` natively mapped under `zai-coding-plan` — verified), `deploy/setup.sh`/`setup.ps1` (no per-agent model echoes for uiux — verified), README counts/tables (no per-agent model claims for uiux), and the "text-only" claims in `frontend-design-skill`/`image-analyzer-subagent`/`error-resolver-subagent` (they describe the primary session or their own fallbacks — still true, verified). Known pre-existing drift OUT of scope: `MIGRATION.md:62-67` still describes the pre-#294 vision arrangement (follow-up ticket candidate, unrelated to this change).
- Vision policy (ticket decision): hybrid — native interpretation primary; delegation mandatory only on explicit request or native-perception failure (mirrors `error-resolver-subagent`).
- Code-review fixes (post-implementation): README.md:102 vision-tier blockquote now lists `uiux-reviewer-subagent` (WARN — missed sweep surface; the "README tables only" audit claim was too narrow) and the README/agent-creation fallback phrasing now correctly says agents fall back to the recipe embedded in `image-analyzer-subagent` (only image-analyzer embeds it). Remaining review NOTEs pre-existing/out-of-scope: frontend-design-skill:375 unconditional checklist, deploy/.AGENTS.md:9 "always image-analyzer" steering, agent-tiers.json pptx block placement, MIGRATION.md:62-67 drift.
- No dependency changes → no `npm install`/lockfile work. No runtime code → verification gate is the registry `--check` + resolver dry-run + grep sweeps.

## Dependencies

None — single contained change, no blocked-by tickets.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Tier name typo breaks deploy resolution | Step 1.2 resolver dry-run guard immediately after the JSON edit |
| Registry drift fails CI | Step 4.2 regen + `--check` in the same phase; repo rule: registry committed with the change |
| Stale text-only prose left in sibling skills | Post-change grep sweep (4.3, widened pattern) scoped to the two edited uiux files; sibling claims verified still-true in Technical Notes |
| Reviewer hallucinating pixels if native perception silently unavailable | Hybrid rule keeps the no-fabrication escape hatch: both paths unavailable → `Status: partial` |
