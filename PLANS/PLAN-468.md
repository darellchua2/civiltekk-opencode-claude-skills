# PLAN: model pins stale vs models.dev; anthropic preset pin nonexistent

**Branch**: feat/468
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/468
**Base**: main

## Acceptance Criteria
- [ ] `installer/provider-models.json`: `zai-coding-plan` gains `glm-5.2`, `glm-5.2-highspeed`, `glm-5.3-highspeed` (4→7, full catalog); `zai` gains `glm-5.2`, `glm-5.3-flash`, `glm-5.3-flashx` (14→17, full catalog); NEW `anthropic` array (full 14-model catalog, live pull 2026-09-20) and NEW `openai` array (full 48) so the #281 fail-fast guard stops skipping those presets
- [ ] `installer/provider-presets.json` anthropic: broken `claude-haiku-4-6` fast/docs pins (model does not exist in the catalog) replaced, and the preset moved to the catalog's current generation — primary `claude-opus-5`, reasoning/vision `claude-sonnet-5`, fast/docs `claude-haiku-4-5` (newest haiku; fast/docs tier semantics = cheapest fast model)
- [ ] `installer/provider-presets.json` openai refreshed to current generation — primary/reasoning/vision `gpt-5.6`, fast/docs `gpt-5.4-mini` (newest `*-mini` in the catalog)
- [ ] `deploy/models.example.json` broken `anthropic/claude-haiku-4-6` fast/docs example pins fixed (same defect, user-copied file; sweep found it)
- [ ] New offline pin check (tests/test_provider_pins.bats): every preset's `primary` + `tiers.*` pin resolves — provider prefix present in provider-models.json AND model id in its array; presets whose prefix is not catalog-backed must be explicitly allowlisted (openrouter `<model>` template, local-llm, vllm, ollama); `models.default.json` pins checked too; no network access (catalog-sync drift is #472's `--check-catalog`)
- [ ] Full gate green (bash/ps1 untouched — data + test only)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/provider-models.json` | — | `resolve-models.mjs` via `--provider-models` (guard, generic per prefix — no code change needed), the new pin test | low — additive arrays |
| `installer/provider-presets.json` | provider-models.json arrays (pins must resolve against them) | `resolve-models.mjs` `--provider/--presets` flow, `--provider-models` validation | low |
| `deploy/models.example.json` | — | users copying it as their models.json | low |
| `tests/test_provider_pins.bats` (new) | the two installer data files | CI bats job | low |

No code consumers change behavior: `resolve-models.mjs` already validates any prefix present in provider-models.json; adding arrays strictly widens coverage.

## Implementation Phases

### Phase 1: Refresh the three data files
- [ ] **1.1** provider-models.json: append the 3 missing ids to `zai-coding-plan`, the 3 missing to `zai`, add `anthropic` (14 ids) and `openai` (48 ids) arrays from the live models.dev pull (2026-09-20, `/tmp/opencode/models-dev.json`); update `$comment` to drop the "cannot validate anthropic/openai" caveat which is now false
    — **Why:** The ticket's root defect: hand-maintained pins drifted from the catalog; the guard could not catch the anthropic breakage because its data file covered only `zai*`. Full-catalog arrays make the guard authoritative for every remote preset.
    — **Done when:** node parse of the file shows zai-coding-plan = the 7 catalog ids, zai = the 17 catalog ids, anthropic = 14, openai = 48; `$comment` no longer claims anthropic/openai are unverifiable.
    — **Consumers affected:** resolve-models.mjs guard (now validates anthropic/openai pins), new pin test.
- [ ] **1.2** provider-presets.json: anthropic → primary `anthropic/claude-opus-5`, reasoning/vision `anthropic/claude-sonnet-5`, fast/docs `anthropic/claude-haiku-4-5`; openai → primary/reasoning/vision `openai/gpt-5.6`, fast/docs `openai/gpt-5.4-mini`
    — **Why:** `claude-haiku-4-6` does not exist in the catalog — selecting the Anthropic preset today writes a models.json opencode cannot resolve (the ticket's user-facing breakage). Both presets refresh to the catalog's current generation; fast/docs keep tier semantics (newest small model, not a premium one).
    — **Done when:** every pin in both presets is `provider/model` with the model id present in that provider's array in provider-models.json (spot-check + covered by 2.1 permanently).
    — **Consumers affected:** users selecting the Anthropic/OpenAI presets (working pins instead of unresolvable models).
- [ ] **1.3** deploy/models.example.json: replace both `anthropic/claude-haiku-4-6` example pins with `anthropic/claude-haiku-4-5` (and align primary/reasoning/vision with the refreshed preset so the example demonstrates a resolvable map)
    — **Why:** Same broken pin, swept repo-wide (`grep -rn claude-haiku-4-6`); the example is the file users copy — it must not teach a broken pin.
    — **Done when:** `grep -rn 'claude-haiku-4-6'` over the repo returns zero matches.
    — **Consumers affected:** users copying the example.

### Phase 2: Offline pin-resolution check + full gate
- [ ] **2.1** Add tests/test_provider_pins.bats: enumerate presets from provider-presets.json; for each pin (primary + tiers.*): split `provider/model`, require the prefix to be a key of provider-models.json OR the preset to be in the explicit allowlist (`openrouter` template `<model>`, `local-llm`, `vllm`, `ollama`); require the model id in the prefix's array; same resolution check for installer/models.default.json; assert the allowlist has no unknown presets (a future remote preset without data fails instead of silently skipping); POSIX grep + node -e only, no network
    — **Why:** AC 4 — the guard that would have caught the broken anthropic pin, as an offline unit pin. #472 later adds the network catalog-sync; this test pins internal consistency today.
    — **Done when:** `bats tests/test_provider_pins.bats` passes on this machine, and an induced broken pin (temp local mutation) fails it.
    — **Consumers affected:** CI bats job.
- [ ] **2.2** Full gate: `bash -n deploy/setup.sh`, `bats tests/` (all suites), `node --test tests/*.test.ts`; verify diff scope = the four files above, no bash/ps1 changes
    — **Why:** Gate contract; the ticket is data-only.
    — **Done when:** all green; `git diff --stat origin/main` limited to installer/provider-models.json, installer/provider-presets.json, deploy/models.example.json, tests/test_provider_pins.bats (+ PLAN/LEARNINGS).
    — **Consumers affected:** none.

## Technical Notes
- Catalog source: live `https://models.dev/api.json` pull, 2026-09-20 (cached /tmp/opencode/models-dev.json). anthropic 14 ids include dated variants (`claude-haiku-4-5-20251001` etc.) — keep them, the guard only needs membership. openai 48 ids include embeddings/image/realtime — same rationale.
- `zai-custom` stays a 2-id local exception (custom endpoint, not a catalog provider); `glm-4.6v-flash` deliberate absence documented in `$comment` is unaffected (still absent from the catalog).
- openrouter's `<model>` placeholder and the three local providers are not catalog-backed by design; the test allowlists them explicitly so a future remote preset can't silently escape.
- #472 will replace "Update as models.dev updates" (the `$comment`'s closing instruction) with a regeneration script + `--check-catalog`; this PR intentionally leaves that phrase in place.

## Dependencies
None — standalone data fix. #472 builds the freshness automation on top.

## Risks & Mitigation
- **Pin-generation choice is a judgment call** (opus-5/sonnet-5/gpt-5.6): mitigated by tier semantics (fast/docs = newest small model) and every chosen id being verified present in the live catalog; users can override via models.json (documented flow).
- **openai array is large (48 ids)**: harmless — membership list only; the guard uses it for validation, never selection.
