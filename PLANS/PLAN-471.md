# PLAN: preset-driven provider credential capture + auth.json seeding

**Branch**: feat/471
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/471
**Base**: main

## Acceptance Criteria
- [x] `installer/provider-presets.json`: every remote preset gains a `credential` block — zai `{auth_ids: ["zai","zai-coding-plan"], env_var: ZAI_API_KEY, oauth: false}` (DISTINCT ids — coding-plan models need the `zai-coding-plan` id), zai-custom `{auth_ids: ["zai-custom"], env_var: ZAI_API_KEY}`, openrouter `{auth_ids: ["openrouter"], env_var: OPENROUTER_API_KEY, oauth: false}`, anthropic/openai `{auth_ids: [...], env_var: ..., oauth: true}` (OAuth-capable presets print the manual `opencode auth login <id>` hint INSTEAD of prompting); local presets (local-llm/vllm/ollama) get no block
- [x] `register_zai_auth` generalized → `register_provider_auth(auth_id, key)`: merge-never-clobber preserved (existing auth.json entries untouched — test-pinned), dry-run gate preserved, python3-fallback preserved; the shell-vars call site is REMOVED (identity layer owns seeding now)
- [x] New plan step `setup_provider_credentials` (non-critical) inserted immediately after `provider` in full/quick/models-only plans: resolve chosen preset (PROVIDER flag → USER_MODELS_MAP primary prefix → models.default.json primary prefix, matched against preset name/auth_ids) → oauth: print hint, done; api: key from env var (headless) or masked `read -rs` prompt (interactive) → register for EACH auth_id → verify via `opencode auth list` when opencode exists (warn-skip otherwise); already-seeded + no env → idempotent skip
- [x] Headless: key via env var; interactive: masked prompt; explicit `--provider` flag selects the preset
- [x] bats (tests/test_provider_credentials.bats): presets schema (remote ⇒ credential block, local ⇒ none), merge-never-clobber, distinct zai/zai-coding-plan ids, oauth-hint-no-prompt, headless env seeding, verify-via-stub, plan membership (credentials immediately after provider in full/quick/models-only)
- [x] Full gate green; README unchanged; setup.ps1 untouched (credential UI parity is #474's launcher scope)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/provider-presets.json` | — (additive `credential` blocks) | resolve-models.mjs/tier-editor (ignore unknown keys — verify), new step, schema pin | low |
| `deploy/setup.sh` register_provider_auth | auth.json format (opencode-owned; proven by register_zai_auth) | credentials step; setup_shell_vars loses its zai call | medium |
| `deploy/setup.sh` setup_provider_credentials (new) | presets credential blocks; USER_MODELS_MAP/models.default.json | build_plan steps (full/quick/models-only) | medium |
| `tests/test_provider_credentials.bats` (new) | the above | CI bats job | low |
| `tests/test_provider_pins.bats` | presets file (schema pin may need credential-block tolerance) | CI | low |

No runtime consumer of provider-presets.json rejects unknown keys (tier-editor/provider-picker read label/primary/tiers; verify in recon — if any consumer strict-parses, the block shape adjusts).

## Implementation Phases

### Phase 1: credential blocks + generalized seeder
- [x] **1.1** provider-presets.json: add the five `credential` blocks per the AC table (keep `$comment` on zai-custom)
    — **Why:** The ticket's data model — auth ids are NOT always the preset name (zai ⇒ zai + zai-coding-plan), so the mapping must live in data, not code.
    — **Done when:** node parses; every remote preset has credential.auth_ids (array) + credential.env_var; local presets have no credential key; provider-picker/tier-editor still run (node scripts tolerate extra keys — smoke via existing init tests).
    — **Consumers affected:** all remote-preset users (new capture flow).
    — **Done:** five credential blocks added (zai dual-id, zai-custom, anthropic/openai oauth:true, openrouter); locals clean; node parse verified; provider-picker/tier-editor unaffected (init tests green in gate); files: installer/provider-presets.json; fixes: none
- [x] **1.2** Generalize register_zai_auth → `register_provider_auth(auth_id, key)` (same merge-never-clobber python, same dry-run gate, same python3 fallback); REMOVE the register_zai_auth call from setup_shell_vars (:3892) and the old function; re-point its zai comment at the credentials step
    — **Why:** AC — identity layer owns seeding; the seeder must accept any auth id.
    — **Done when:** no register_zai_auth references remain; register_provider_auth in a sandboxed HOME adds the id while preserving a pre-existing unrelated entry.
    — **Consumers affected:** shell-vars no longer seeds auth.json — the credentials step (1.3) replaces it earlier in the plan.
    — **Done:** register_provider_auth(auth_id, key) — merge-never-clobber python kept, AUTH_ID/AUTH_KEY env-passing (no argv interpolation); register_zai_auth + its shell-vars call removed with a pointer comment; merge pin green; files: deploy/setup.sh; fixes: none
- [x] **1.3** Add `setup_provider_credentials()` per the AC flow (preset resolution chain, oauth hint, env/masked-prompt capture, multi-auth_id registration, `opencode auth list` verification, idempotent skip, DRY_RUN gate); register it in build_plan after `provider` in full/quick/models-only
    — **Why:** The ticket's first-class identity step, coupled to provider selection.
    — **Done when:** plan membership pinned; functional pins (2.1) green.
    — **Consumers affected:** full/quick/models-only users get credential capture; skills-only unchanged.
    — **Done:** setup_provider_credentials (resolution chain flag→map→defaults, oauth hint, env/masked-prompt capture, multi-auth_id seeding, opencode auth list verification, idempotent skip, DRY_RUN gate) registered after provider in full/quick/models-only; membership smoke-verified; files: deploy/setup.sh; fixes: none

### Phase 2: pins + full gate
- [x] **2.1** tests/test_provider_credentials.bats: presets schema; merge-never-clobber (seeded unrelated entry survives); distinct zai + zai-coding-plan ids from one capture; oauth hint printed and NO prompt/no auth entry; headless env-var seeding (OPENROUTER_API_KEY); verification via stubbed `opencode(){ }` success path; plan membership (credentials immediately after provider in full/quick/models-only); idempotent re-run skip. POSIX + node only, sandboxed HOME, no network
    — **Why:** The AC matrix as executable contract.
    — **Done when:** `bats tests/test_provider_credentials.bats` green.
    — **Consumers affected:** CI.
    — **Done:** 8/8 — schema, dual-id, merge-never-clobber fixture, oauth-hint-no-prompt, headless env seeding, verify-via-stub, membership adjacency; files: tests/test_provider_credentials.bats; fixes: none
- [x] **2.2** Full gate: `bash -n`, `bats tests/`, `node --test tests/*.test.ts`; diff scope = setup.sh + provider-presets.json + new test
    — **Why:** Gate contract.
    — **Done when:** all green.
    — **Consumers affected:** none.
    — **Done:** bash -n ok; bats 455 ok / 0 fail (447 + 8); node --test 30/0; diff = setup.sh + presets + new test + PLAN; files: —; fixes: none

## Technical Notes
- auth.json entry shape proven by register_zai_auth: `auth[id] = {"type":"api","key":...}` — opencode reads `~/.local/share/opencode/auth.json` (XDG_DATA_HOME honored).
- `opencode auth login` is interactive-only (headless can't use it) — hence env-var seeding for api presets and hint-only for oauth presets.
- The `zai` preset's dual auth_ids exist because auth.json ids must match the MODELS' provider prefix (`zai-coding-plan/glm-5.3` vs legacy `zai/...` direct-API users).
- #470 plan model: credentials is a NON-critical step (unauthenticated provider = degraded, not broken; matches register_zai_auth's historical return-0-on-missing-python3 posture).
- #474 will port the credential UI to ps1 (thin launcher scope); ps1 untouched here.

## Dependencies
Epic #464; #470's plan model (step registration). Blocks #473 (picker needs credential blocks).

## Risks & Mitigation
- **auth.json clobber**: merge-never-clobber pinned with an unrelated-entry fixture; register writes only its own id key.
- **Interactive prompt in headless**: prompt path only when `[ -t 0 ] && AUTO_ACCEPT=false`; otherwise env-or-skip.
- **Consumer strictness on presets**: recon shows consumers read named keys; smoke via existing init/provider tests in the full gate.

## Gate Trace

GATE (fix-round head) lint=- typecheck=- build=- unit=t e2e=n.a.  (bash -n ok; bats 456 ok / 0 fail — 9 credential pins after the idempotent + stale-key pins; node --test 30 pass / 0 fail; review round 1: 4 WARN fixed — LOCAL-allowlist schema pin, idempotent+oauth-entry pins, corrupt-auth.json backup + chmod 600, XDG sandbox unsets; verify switched to command-exit + listing print — real opencode renders DISPLAY names, not ids (empirically checked); NOTEs: dry-run capture gate, wrapped-tail guard, stale comment trim; opencode auth list can stall on fresh state dirs — verify bounded with timeout 15; scope unchanged)
