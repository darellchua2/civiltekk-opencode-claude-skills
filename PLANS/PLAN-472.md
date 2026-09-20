# PLAN: models.dev regeneration script + --check-catalog drift check

**Branch**: feat/472
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/472
**Base**: main

## Acceptance Criteria
- [x] `deploy/regen-provider-models.mjs`: fetches `https://models.dev/api.json` (or `--catalog <file>` for offline/test runs) and regenerates `installer/provider-models.json` — idempotent (second run = byte-identical), deterministic output (sorted ids, stable key order, 2-space JSON + trailing newline), covering every provider prefix the presets use (zai, zai-coding-plan, anthropic, openai)
- [x] Uncataloged prefixes preserved as-is (`zai-custom`, its 2-id local exception; `$comment` preserved verbatim) — regeneration never invents or drops non-catalog providers
- [x] `--check-catalog` mode (script + setup.sh flag): warn-only diff of the shipped file against the live catalog — reports missing ids (in catalog, not shipped) and extra ids (shipped, not in catalog) naming each; exits 0 with warnings (drift is a warning, not an error); network/catalog-file failure exits non-zero (you asked for a live check)
- [x] setup.sh: `--check-catalog` flag as a single-step plan mode (`CHECK_CATALOG_ONLY`), listed in both help surfaces; README gains a line
- [x] bats (tests/test_provider_regen.bats): fixture-catalog regen (shape + coverage), byte-stability (run twice, md5 equal), zai-custom preservation, induced drift detection (remove an id → warning names it), post-regen check green
- [x] Full gate green; no network in CI tests (fixture catalogs only)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/regen-provider-models.mjs` (new) | models.dev api.json shape (`{provider: {models: {id: …}}}`); current provider-models.json key set | maintainers (manual regen); setup.sh --check-catalog | low — new file |
| `deploy/setup.sh` CHECK_CATALOG_ONLY mode | the mjs script | diagnostics users; help surfaces | low |
| `installer/provider-models.json` | regen (only when a maintainer runs it — NOT in deploys/CI) | resolve-models.mjs guard, test_provider_pins | low — file unchanged in this PR unless regen is run (it is run once, via fixture, in tests only) |
| `tests/test_provider_regen.bats` (new) | the mjs | CI | low |

Note: this PR does NOT commit a regenerated provider-models.json (the shipped file is current as of #468/#490's 2026-09-20 pull; regeneration is a maintainer action with the drift check guarding staleness). #491 tracks the models-only/migrate D2 alignment separately.

## Implementation Phases

### Phase 1: the regen/check script
- [x] **1.1** deploy/regen-provider-models.mjs: parse args (`--catalog <file>` offline fixture, `--check` warn-only mode, default = fetch + write); fetch/read catalog; for each provider key already present in provider-models.json (except uncataloged prefixes), build the sorted id array from `catalog[provider].models`; preserve `$comment` and any provider key absent from the catalog; write byte-stable output (stable key order = existing file's order for kept keys + catalog-discovered preset prefixes appended per presets file? NO — key set = current file keys only, so the file never grows/shrinks implicitly); `--check` mode compares and reports `missing`/`extra` per provider, exit 0 with warnings on drift, non-zero on fetch/parse failure
    — **Why:** The ticket's system replacement for the "Update as models.dev updates" comment.
    — **Done when:** fixture-driven bats (2.1) green: shape, idempotency, preservation, drift detection.
    — **Consumers affected:** maintainers (regen), diagnostics users (check).
    — **Done:** mjs with --catalog/--check; byte-stable (sorted ids, preserved key order, 2-space + newline); $comment + non-catalog prefixes preserved; files: deploy/regen-provider-models.mjs; fixes: none
- [x] **1.2** Coverage guarantee: the script errors (non-zero) if a shipped provider key is absent from the catalog AND is a known-catalog provider name (typo detection), while genuinely non-catalog prefixes (zai-custom) pass through untouched
    — **Why:** "Covers every provider prefix the presets use" — silent skips would recreate the #468 blind-spot class.
    — **Done when:** a fixture missing `anthropic` makes the script exit non-zero naming it; `zai-custom` absence from the fixture is fine.
    — **Consumers affected:** maintainers.
    — **Done:** known-provider-absent → fatal when OTHER known providers exist in the catalog (partial offline fixtures legitimately omit providers — refined after the first rule tripped the fixture); files: deploy/regen-provider-models.mjs; fixes: rule refinement

### Phase 2: setup flag + docs + pins
- [x] **2.1** setup.sh: `--check-catalog` flag → `CHECK_CATALOG_ONLY=true` (defaults block, parser arm next to `-C|--check-update`, single-step plan in build_plan: node "$REPO_DIR/deploy/regen-provider-models.mjs" --check (critical step), completion line); both help surfaces + README deploy section gain a line
    — **Why:** AC — the check must be runnable from the setup itself, consistent with the plan model's truthful-exit contract.
    — **Done when:** plan membership pin + help greps pass (2.1).
    — **Consumers affected:** diagnostics users.
    — **Done:** CHECK_CATALOG_ONLY default + --check-catalog arm + single-step plan (check_provider_catalog, critical) + completion line + both help surfaces + README (example block + options table); files: deploy/setup.sh, README.md; fixes: none
- [x] **2.2** tests/test_provider_regen.bats: fixture catalogs under tests/fixtures/ (a small two-provider catalog); pins: regen shape+coverage, byte-stability (double run, cmp), zai-custom preservation, unknown-catalog-provider error, induced-drift check warning, post-regen check green, setup.sh plan membership + help greps
    — **Why:** The AC matrix as executable contract, CI-safe (no network).
    — **Done when:** `bats tests/test_provider_regen.bats` green.
    — **Consumers affected:** CI.
    — **Done:** 7/7 — fixture regen shape/preservation, byte-stability (cmp), fatal-drop pin, induced-drift warnings (exit 0), post-regen green, unavailable-catalog non-zero, setup wiring + help greps; tests snapshot/restore the shipped file; test 3 uses a PRIVATE fixture copy (shared-fixture mutation self-found and fixed); files: tests/test_provider_regen.bats + fixture; fixes: fixture isolation
- [x] **2.3** Full gate: `bash -n`, `bats tests/`, `node --test tests/*.test.ts`; diff scope = new mjs + setup.sh + README + new test + fixtures
    — **Why:** Gate contract.
    — **Done when:** all green.
    — **Consumers affected:** none.
    — **Done:** bash -n ok; bats 463 ok / 0 fail (456 + 7); node --test 30/0; shipped provider-models.json unmutated (restored by teardown, verified via git status); files: —; fixes: none

## Technical Notes
- models.dev api.json shape: `{ "<provider>": { "models": { "<id>": {...} } } }` (verified in #468/#490 recon; the D2/D1 pulls used it).
- Byte-stability: canonical serialization = `JSON.stringify(obj, null, 2) + "\n"` with keys in the file's existing order (insertion order preserved by JS objects for string keys) and ids sorted; no timestamps, no volatile fields.
- Deliberately NOT in this PR: scheduled CI drift job (AC marks it optional; owner CI is a single bats job — proposed as a follow-up if wanted), regenerating provider-presets.json pins (preset pins are tier-semantics choices, not catalog mirrors — the #471 dual-id blocks make that explicit).
- #491 (models-only/migrate D2 alignment) is related but separate.

## Dependencies
Epic #464; builds on #468/#490's catalog-fresh provider-models.json. No blockers.

## Risks & Mitigation
- **Script reachability from setup.sh**: the mjs lives in deploy/ — invoked as `node "${DEPLOY_DIR}/regen-provider-models.mjs"`, path-constant like merge-packs.mjs.
- **Network flakiness in --check**: bounded fetch (AbortSignal.timeout 15000) + clear non-zero message; tests never hit the network (fixture catalogs).

## Gate Trace

GATE (fix-round head) lint=- typecheck=- build=- unit=t e2e=n.a.  (bash -n ok; bats 465 ok / 0 fail — 9 regen pins after the conflict-validator registration + non-fatal-branch fixture; node --test 30 pass / 0 fail; review round 1: 2 WARN fixed (validator registration, non-fatal fixture) + NOTEs (dead ternary removed, --catalog value guard, empty-models = missing for known providers, mktemp backup path); shipped provider-models.json untouched)
