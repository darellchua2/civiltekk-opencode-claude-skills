# PLAN: Purge glm-5v-turbo, standardize vision on glm-5.3-flash

**Branch**: feat/516
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/516
**Base**: main

## Acceptance Criteria
- [x] `agents/image-analyzer-subagent.md` fallback recipe sends `"model": "glm-5.3-flash"`
- [x] `grep -rniE "5v[-_]?turbo" . --exclude-dir=.git --exclude-dir=PLANS` returns hits only in `CHANGELOG.md` (historical release record, untouched; committed `PLANS/PLAN-516.md` is likewise a historical record describing this purge — excluded per PLAN-507 precedent)
- [x] `glm-5v-turbo` removed from `installer/provider-models.json` (array entry + `$comment`)
- [x] `bats tests/test_provider_pins.bats` and `tests/test_skill_isolation.bats` pass
- [x] `node installer/build-registry.mjs` run; `registry.json` committed if it diffs
- [x] Zero references to pre-5.3 vision models (`glm-5v-turbo`, `glm-4.5v`, `glm-4.6v` incl. `-flash`) outside `CHANGELOG.md` (PLANS excluded) — vision = `glm-5.3-flash` only
- [x] `installer/provider-models.json` arrays carry no vision model older than `glm-5.3-flash`; frontier `glm-5.3` and non-vision models untouched

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `agents/image-analyzer-subagent.md` | — | `agents/error-resolver-subagent.md` + `skills/error-resolver-workflow-skill/SKILL.md` (prose references to the recipe) | low |
| `agents/error-resolver-subagent.md` | image-analyzer recipe wording (prose ref) | — | low |
| `skills/error-resolver-workflow-skill/SKILL.md` | image-analyzer recipe wording (prose ref) | `error-resolver-subagent` (orchestrates this skill) | low |
| `skills/opencode-agent-creation-skill/SKILL.md` | `installer/agent-tiers.json` (prose ref) | users authoring agents | low |
| `AGENTS.md`, `README.md` | tier registry (prose description) | humans/agents reading docs | low |
| `installer/agent-tiers.json` | — | `installer/resolve-models.mjs` (deploy-time model injection), `deploy/setup.sh` | med — `$comment` only, no tier values change |
| `installer/provider-models.json` | — | `installer/resolve-models.mjs` (`--provider-models` fail-fast guard), `deploy/regen-provider-models.mjs`, `tests/test_provider_pins.bats` | med — `zai` array entry removal + `$comment` |

Cross-module consumers exist (`resolve-models.mjs`, regen script, tests) → architecture review selected at Step 7.

## Implementation Phases

### Phase 1: Agent files — functional recipe + prose
- [x] **1.1** Update `agents/image-analyzer-subagent.md`: change the fallback recipe payload from `"model": "glm-5v-turbo"` to `"model": "glm-5.3-flash"`, and reword the L68 prose from "using `glm-5v-turbo` on the pay-as-you-go endpoint — a different model from the native one" to describe calling the same multimodal model (`glm-5.3-flash`) directly via API.
    — **Why:** the recipe payload is the only functional use of the dead model; prose must match it or the file self-contradicts.
    — **Done when:** `grep -c "glm-5v-turbo" agents/image-analyzer-subagent.md` returns 0 and the payload line reads `"model": "glm-5.3-flash"`.
    — **Consumers affected:** error-resolver-subagent + error-resolver-workflow-skill reference the recipe by name (prose only; updated in 1.2/2.1).
    — **Done:** payload L94 + fallback prose L68-69 now name glm-5.3-flash; files: agents/image-analyzer-subagent.md; fixes: none
- [x] **1.2** Update `agents/error-resolver-subagent.md` screenshot-analysis prose: replace "the inline direct-API fallback recipe in `image-analyzer-subagent` (`glm-5v-turbo`, a different model)" with wording naming `glm-5.3-flash` (no "different model" caveat — it no longer is one). Keep the `glm-4.6v-flash` "do NOT invoke" warning (still valid: that free endpoint was retired).
    — **Why:** stale prose would direct readers to a purged model.
    — **Done when:** `grep -c "glm-5v-turbo" agents/error-resolver-subagent.md` returns 0.
    — **Consumers affected:** none (self-contained prose).
    — **Done:** fallback reference now reads "(`glm-5.3-flash`, the same model called directly over HTTP)"; glm-4.6v warning kept; files: agents/error-resolver-subagent.md; fixes: none

### Phase 2: Skill prose
- [x] **2.1** Update `skills/error-resolver-workflow-skill/SKILL.md` §Image Input Routing step 2: replace "(`glm-5v-turbo` — a different model from the native one)" with `glm-5.3-flash` wording.
    — **Why:** routing doc must name the model the recipe actually calls after 1.1.
    — **Done when:** `grep -c "glm-5v-turbo" skills/error-resolver-workflow-skill/SKILL.md` returns 0.
    — **Consumers affected:** error-resolver-subagent (orchestrates this skill; prose consistency only).
    — **Done:** step 2 now names glm-5.3-flash "the same multimodal model the vision tier runs on, called directly over HTTP"; files: skills/error-resolver-workflow-skill/SKILL.md; fixes: none
- [x] **2.2** Update `skills/opencode-agent-creation-skill/SKILL.md` Model-field guidance: replace "inline direct-API fallback recipe calling `glm-5v-turbo` — a different model" with `glm-5.3-flash` wording.
    — **Why:** this skill teaches agent authoring; it must not propagate the purged name.
    — **Done when:** `grep -c "glm-5v-turbo" skills/opencode-agent-creation-skill/SKILL.md` returns 0.
    — **Consumers affected:** users authoring agents (docs accuracy).
    — **Done:** Model-field guidance now reads "calling `glm-5.3-flash` directly over HTTP"; files: skills/opencode-agent-creation-skill/SKILL.md; fixes: none

### Phase 3: Repo docs
- [x] **3.1** Rewrite `AGENTS.md` §Subagent Model Tiering vision-fallback paragraph: fallback calls `glm-5.3-flash` (same multimodal model, direct API transport; coding-plan endpoint preferred, PAAS fallback, `ZAI_API_KEY`). Drop the "different model" and the stale "Free `glm-4.6v-flash` is a cost-constrained option" sentence (endpoint retired — see error-resolver-subagent warning).
    — **Why:** AGENTS.md is the injected behavioral doc; stale model names misroute future sessions.
    — **Done when:** `grep -cE "glm-5v-turbo|glm-4\.6v-flash" AGENTS.md` returns 0.
    — **Consumers affected:** all sessions injecting this file.
    — **Done:** fallback paragraph rewritten (same model, raw-HTTP transport); retired-4.6v sentence dropped; files: AGENTS.md; fixes: none
- [x] **3.2** Rewrite `README.md` vision-tier note (the blockquote at ~L134-142) to match 3.1: fallback calls `glm-5.3-flash` via direct API.
    — **Why:** README is the public install doc; must not advertise the purged model.
    — **Done when:** `grep -c "glm-5v-turbo" README.md` returns 0.
    — **Consumers affected:** repo readers; none functional.
    — **Done:** blockquote now reads "calling the same `glm-5.3-flash` model via direct API"; files: README.md; fixes: none

### Phase 4: Installer registry
- [x] **4.1** Update `installer/agent-tiers.json` `$comment`: replace the sentence "text-only sessions fall back to the inline direct-API recipe embedded in image-analyzer-subagent (glm-5v-turbo via the pay-as-you-go `zai` path)" with glm-5.3-flash wording. No tier values change.
    — **Why:** the registry comment documents fallback design; it must not name the purged model.
    — **Done when:** `grep -c "glm-5v-turbo" installer/agent-tiers.json` returns 0 and `python3 -c "import json; json.load(open('installer/agent-tiers.json'))"` exits 0.
    — **Consumers affected:** `resolve-models.mjs` (reads tiers, not comments — zero behavior change).
    — **Done:** fallback sentence now names glm-5.3-flash (same model, raw HTTP, coding-plan preferred); files: installer/agent-tiers.json; fixes: none
- [x] **4.2** Update `installer/provider-models.json`: remove the `"glm-5v-turbo"` string from the `zai` array entirely, and rewrite the `$comment` to drop the glm-5v-turbo PAYG-escape-hatch documentation (keep the glm-4.6v-flash deliberate-absence note accurate if it references the fallback — reword to name glm-5.3-flash).
    — **Why:** user mandate — no shipped config or registry may carry the entry; the comment must not document a model the file no longer lists.
    — **Done when:** `grep -c "glm-5v-turbo" installer/provider-models.json` returns 0 and `python3 -c "import json; json.load(open('installer/provider-models.json'))"` exits 0.
    — **Consumers affected:** `resolve-models.mjs` guard (nothing references the removed id anymore, so no new warnings); `deploy/regen-provider-models.mjs` (see Risks).
    — **Done:** array entry removed; `$comment` fallback clause reworded; files: installer/provider-models.json; fixes: none
- [x] **4.3** Scope expansion — purge pre-5.3 vision models from `installer/provider-models.json`: remove `"glm-4.5v"` and `"glm-4.6v"` from the `zai` array, and drop the glm-4.6v-flash "deliberate absence" NOTE from the `$comment` (obsolete once the model class is purged). Keep frontier `glm-5.3` and non-vision models (`glm-4.5-flash`, `glm-4.7-flash`, `glm-5.3-flashx`) untouched.
    — **Why:** user mandate — vision is `glm-5.3-flash` only; a capability manifest naming dead/retired vision models misleads tier authors.
    — **Done when:** `grep -cE "glm-4\.5v|glm-4\.6v" installer/provider-models.json` returns 0 and `python3 -c "import json; json.load(open('installer/provider-models.json'))"` exits 0 and `"glm-5.3"` + `"glm-4.7-flash"` still present in the `zai` array.
    — **Consumers affected:** `resolve-models.mjs` guard (no tier/pin references the removed ids — verified by plan review); `deploy/regen-provider-models.mjs` (see Risks).
    — **Done:** glm-4.5v + glm-4.6v removed from `zai`; `$comment` NOTE replaced by one no-roster standardization sentence ("pre-5.3 vision models deliberately absent"); glm-5.3/glm-4.7-flash/glm-5.3-flashx verified present; files: installer/provider-models.json; fixes: comment reworded once to drop model-name roster (first draft self-hit the 6.1 gate)

### Phase 5: Older-vision-model purge in prose (scope expansion)
- [x] **5.1** Update `agents/error-resolver-subagent.md`: drop the "Do NOT invoke `glm-4.6v-flash` (that free endpoint was retired due to rate-limiting);" clause — with the model class purged everywhere, the warning has no referent and the surrounding "no external vision API" statement already governs.
    — **Why:** last prose mention of a pre-5.3 vision model in agents/.
    — **Done when:** `grep -cE "glm-4\.5v|glm-4\.6v" agents/error-resolver-subagent.md` returns 0 and the glm-5.3-flash fallback reference from 1.2 is intact.
    — **Consumers affected:** none (self-contained prose).
    — **Done:** 4.6v clause dropped, fallback reference intact; files: agents/error-resolver-subagent.md; fixes: none
- [x] **5.2** Rewrite `MIGRATION.md` "Default tier models" blockquote to current reality: vision tier = `zai-coding-plan/glm-5.3-flash` native multimodal (image-analyzer/error-resolver/uiux-reviewer/zai-media), `zai-vision-analysis-skill` removed (GIT-364), exposed-model guard sentence preserved.
    — **Why:** the block still claims vision runs on `docs` (`glm-4.7`) + the removed skill + opt-in `zai/glm-4.6v` — three generations stale; upgraders following it misconfigure.
    — **Done when:** `grep -cE "glm-4\.5v|glm-4\.6v|glm-5v" MIGRATION.md` returns 0 and the block names `glm-5.3-flash` as the vision tier.
    — **Consumers affected:** users migrating older installs.
    — **Done:** block rewritten to vision-tier reality (#349/#372, GIT-364 note, guard sentence kept); files: MIGRATION.md; fixes: none
- [x] **5.3** Update `README.md` historical skills-count narrative (~L611): drop "free `glm-4.6v-flash`" from the `zai-vision-analysis-skill` mention (keep the narrative and counts).
    — **Why:** live README prose must not advertise the retired model.
    — **Done when:** `grep -cE "glm-4\.6v" README.md` returns 0.
    — **Consumers affected:** repo readers; none functional.
    — **Done:** model name dropped from the count narrative, counts intact; files: README.md; fixes: none

### Phase 6: Verification + registry sync
- [x] **6.1** Repo-wide purge proof: `grep -rniE "5v[-_]?turbo|glm-4\.5v|glm-4\.6v" . --exclude-dir=.git --exclude-dir=PLANS` — case-insensitive, variant-tolerant, excluding `.git/` and the tracked plan file itself (historical record; it must name the tokens to specify the purge).
    — **Why:** ticket AC — purge must be total outside immutable release history; the hardened pattern closes the case-sensitive-grep false-green class flagged in plan review.
    — **Done when:** the only match path is `CHANGELOG.md`.
    — **Consumers affected:** none.
    — **Done:** sole match = CHANGELOG.md (historical); files: none (verification); fixes: none
- [x] **6.2** Run gates: full bats suite `bats tests/` (ticket exit gate — includes `test_provider_pins`, `test_provider_regen`, `test_skill_isolation`, `test_mcp_count_consistency`).
    — **Why:** provider-models.json is consumed by the deploy-time guard and regen script; skill-isolation guards the two touched skills.
    — **Done when:** `bats tests/` exits 0.
    — **Consumers affected:** deploy guard users (confidence).
    — **Done:** 529/529 ok, exit 0; files: none (verification); fixes: none
- [x] **6.3** Run `node installer/build-registry.mjs`; commit `registry.json` if it diffs.
    — **Why:** house sync rule after registry-adjacent file changes.
    — **Done when:** command exits 0; `git status` clean after commit.
    — **Consumers affected:** installer registry consumers.
    — **Done:** regenerated; timestamp-only diff (agents=34, skills=146 unchanged) committed as 5139d03; files: installer/registry.json; fixes: none

## Technical Notes
- `glm-5.3-flash` is natively multimodal (image_url content blocks, URL or base64) and served on both `https://api.z.ai/api/coding/paas/v4` and `https://api.z.ai/api/paas/v4` — verified against Z.AI docs (guides/vlm/glm-5.3-flash), so the recipe's dual-endpoint key resolution needs no change.
- Scope boundary (user directive, 2026-09-21): vision = `glm-5.3-flash` only; pre-5.3 vision models (`glm-4.5v`, `glm-4.6v`, `glm-4.6v-flash`, `glm-5v-turbo`) purged. Frontier reasoning keeps `glm-5.3`. Non-vision models (`glm-4.5-flash`, `glm-4.7-flash`, `glm-5.3-flashx`) and text-tier models are out of scope.
- Agent `.md` frontmatter is untouched (model comes from tier injection at deploy time) — only bodies change.
- `CHANGELOG.md` is the release record; its historical `glm-5v-turbo` entry (#326) stays by design.

## Dependencies
None — single ticket, no `blocked-by`.

## Gate Trace
GATE 54cb78a tier=light lint=n.a typecheck=n.a build=n.a unit=n.a e2e=n.a
GATE a83a00b tier=light lint=n.a typecheck=n.a build=n.a unit=n.a e2e=n.a
GATE a58c09f tier=light lint=n.a typecheck=n.a build=n.a unit=n.a e2e=n.a
GATE 4afd089 tier=light lint=n.a typecheck=n.a build=n.a unit=t(scoped: provider_pins+provider_regen, 14 ok) e2e=n.a
GATE 7c0b49b tier=light lint=n.a typecheck=n.a build=n.a unit=n.a e2e=n.a
GATE d87303b tier=light lint=n.a typecheck=n.a build=n.a unit=n.a e2e=n.a
GATE 5139d03 tier=full lint=n.a typecheck=n.a build=n.a unit=t(bats tests/ 529/529) e2e=n.a

## Plan-Review Adjudications (architecture review, 2026-09-21)
- **Purge gate vs the plan file itself (MAJOR, fixed):** `PLANS/PLAN-516.md` is git-tracked and persists post-merge (precedent: `PLANS/PLAN-507.md`), yet must name the token to describe the purge. AC#2 / step 5.1 therefore exclude `--exclude-dir=PLANS` and harden to `grep -rniE "5v[-_]?turbo"`.
- **`glm-4.6v-flash` sentence removal (in scope):** adjacent cleanup of the same stale-design paragraph; corroborated in-repo (`provider-models.json` `$comment` records the model as deliberately absent; error-resolver keeps the "do NOT invoke" warning). Scope addition to be noted in the PR body.
- **No live API probe:** endpoint support for `glm-5.3-flash` accepted at catalog level — `provider-models.json` (pinned to models.dev) lists it under both `zai` (`:97`) and `zai-coding-plan` (`:9`), covering both endpoints the recipe's key resolution can select; a live probe would require reading `auth.json` (secret-hygiene cost).

## Risks & Mitigation
- **Regen may re-add the model id**: `deploy/regen-provider-models.mjs` regenerates catalog-derived keys from models.dev, which may still list `glm-5v-turbo` under `zai`. Mitigation: shipped file is purged per ticket mandate; test_provider_regen runs in 5.2 to prove current pipeline green. If regen re-adds, that is a deliberate future action, not drift introduced here.
- **Guard warning churn**: removing the `zai` entry while some preset still referenced `zai/glm-5v-turbo` would warn at deploy. Mitigation: grep in 5.1 proves nothing references it.
- **Doc drift between AGENTS.md and user-level deployed copy**: deployed `~/.config/opencode/AGENTS.md` refreshes on next `deploy/setup.sh` run — out of scope for this PR (source-of-truth rule: never edit deployed copies).
