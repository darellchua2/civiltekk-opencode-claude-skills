# PLAN: Detect coding agents; seed Z.AI key into pi + codex

**Branch**: feat/573
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/573
**Base**: main

## Acceptance Criteria

- [ ] Full-mode run prints an agent-detection table (found/missing per agent) in the banner and the setup summary
- [ ] With pi installed and a Z.AI key captured, `~/.pi/agent/models.json` gains `providers.zai` with `apiKey: "$ZAI_API_KEY"`; pre-existing providers untouched; re-run idempotent
- [ ] With codex installed, `~/.codex/config.toml` gains `[model_providers.zai]` + `[profiles.zai]`; existing content untouched; re-run idempotent
- [ ] Neither seed writes anything under `--dry-run`
- [ ] Agents not installed → no seed attempted, run still succeeds
- [ ] After key seeding with opencode installed, setup.sh restarts the opencode service (or logs the manual command if restart fails)
- [ ] `deploy/setup.ps1` mirrors the detection step; `show_help` and README mention the feature
- [ ] One bats test (temp HOME, stubbed `pi`/`codex` on PATH; `grep` not `rg`; assertions run separately, not `&&`-chained) covering: seed-written-when-present, no-write-when-absent, dry-run-writes-nothing

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` (new fns: `detect_installed_agents`, `seed_pi_provider`, `seed_codex_provider`; edits: `build_plan`, `print_summary`, `setup_provider_credentials`, `show_help`) | — | every setup mode (full/quick/skills-only); `tests/test_help_parity.bats` (help-text parity pins); new bats suite; `deploy/setup.ps1` mirror | med |
| `deploy/seed-pi-provider.mjs` | `seed_pi_provider` wrapper call | `deploy/setup.sh` seed step only | low |
| `deploy/setup.ps1` (detection mirror + help) | setup.sh shape agreed | Windows users; `tests/test_help_parity.bats` | med |
| `README.md` (feature mention) | feature built | docs readers | low |
| `tests/test_agent_detection_seed.bats` | setup.sh functions + seed helper | CI bats suite | low |

No cross-module runtime consumers beyond this repo (no skill/, agents/, installer/ consumption); no frontend signal.

## Implementation Phases

### Phase 1: Agent detection (setup.sh + setup.ps1)

- [ ] **1.1** Add `detect_installed_agents()` to `deploy/setup.sh` — read-only probe of `opencode`/`pi`/`claude`/`codex` via `command_exists` plus config-dir fallbacks (`~/.pi/agent`, `~/.kimi-code`, `~/.kilo`, `~/.codex`); sets lowercase boolean globals (`PI_INSTALLED`, `CODEX_INSTALLED`, …) and prints a found/missing table; idempotent, no writes
    — **Why:** Detection gates every downstream seed and feeds both banner and summary; must exist before any seed logic or plan wiring
    — **Done when:** `bash -c 'source deploy/setup.sh; detect_installed_agents'` from a temp HOME prints one line per agent and exits 0 with agents present and absent
    — **Consumers affected:** `seed_pi_provider`, `seed_codex_provider`, `build_plan` step, `print_summary`

- [ ] **1.2** Wire detection into `deploy/setup.sh`: non-critical plan step `detect-agents|Detect installed coding agents` early in the full-mode branch of `build_plan` (after `deps`), and a `detect_installed_agents` call inside `print_summary` so every epilogue (full/quick/skills-only) shows the table
    — **Why:** The AC requires the table in banner and summary; a single idempotent function at two call sites avoids flag plumbing for display while the early step persists globals for the seed step (run_plan executes in one shell)
    — **Done when:** `./setup.sh --dry-run -y` output contains the detection table; `print_summary` renders it even when the detect step was never a plan step
    — **Consumers affected:** full/quick/skills-only mode output; none downstream of summary

- [ ] **1.3** Mirror the detection step in `deploy/setup.ps1` (probe `Get-Command` equivalents + config dirs, print the same table) and keep help text parity for the new feature lines
    — **Why:** setup.ps1 is the Windows mirror and `test_help_parity.bats` pins setup.sh/ps1 help drift; shipping detection bash-only breaks the mirror contract
    — **Done when:** PowerShell syntax check passes and the ps1 help output includes the same feature wording as setup.sh
    — **Consumers affected:** Windows users; `tests/test_help_parity.bats`

### Phase 2: pi provider seeding

- [ ] **2.1** Create `deploy/seed-pi-provider.mjs` (node helper, zero deps, mirrors merge-packs.mjs conventions): reads `--config <models.json>` (missing file ⇒ `{}`), sets `providers.zai = { api: "openai-completions", baseUrl: "https://api.z.ai/api/paas/v4", apiKey: "$ZAI_API_KEY", models: [glm-5.3, glm-5.3-flash with contextWindow/maxTokens] }` without touching sibling providers, writes 2-space JSON with 0600 perms; `--dry-run` prints the delta and writes nothing; idempotent re-run (byte-stable output)
    — **Why:** The merge is the correctness-critical piece (never-clobber of user's other providers) and must be dry-run-gated; a node helper follows the house pattern and is directly testable
    — **Done when:** Running it twice on a config containing another provider leaves that provider byte-identical and produces identical output; `--dry-run` leaves the file untouched (mtime + content unchanged)
    — **Consumers affected:** `seed_pi_provider` wrapper in setup.sh; new bats test

- [ ] **2.2** Add `seed_pi_provider()` to `deploy/setup.sh`: gated on `PI_INSTALLED` + a captured Z.AI key; invokes the mjs helper against `~/.pi/agent/models.json`; dry-run safe; after a real write runs bounded `pi --list-models` (15s timeout, best-effort, warn-only) as verification; wire a non-critical `seed-agent-keys|Seed provider keys into detected agents` plan step immediately after `credentials` in the full branch
    — **Why:** The seed must ride the existing credential capture (#471 machinery) so the key is prompted once and never persisted by us; the plan step placement after `credentials` guarantees the key exists
    — **Done when:** Full-mode run with a stubbed `pi` on PATH and key in env writes `providers.zai` with `apiKey: "$ZAI_API_KEY"` (literal string, env-interpolation form); with `pi` absent the step is a logged no-op
    — **Consumers affected:** `~/.pi/agent/models.json` (user file, merge-only); full-mode plan order

### Phase 3: codex provider seeding

- [ ] **3.1** Add `seed_codex_provider()` to `deploy/setup.sh`: gated on `CODEX_INSTALLED` + captured key; grep-guarded append of a marked TOML block to `~/.codex/config.toml` — `[model_providers.zai]` (`name`, `base_url = "https://api.z.ai/api/v1"`, `env_key = "ZAI_API_KEY"`) + `[profiles.zai]` (`model_provider = "zai"`, `model = "glm-5.3"`); never sets global `model`/`model_provider`; `mkdir -p ~/.codex` on first seed; dry-run prints the block; called from the same `seed-agent-keys` plan step
    — **Why:** codex only supports `wire_api = "responses"` now and Z.AI's Responses endpoint is `/api/v1`; the profile scoping keeps the user's default provider untouched (opt-in via `codex --profile zai`); grep guard + append-only is idempotent and never rewrites user TOML
    — **Done when:** With a stubbed `codex` and a pre-seeded config.toml containing user content, the block appends once; second run is a no-op; `--dry-run` leaves the file unchanged
    — **Consumers affected:** `~/.codex/config.toml` (user file, append-only); full-mode plan order

### Phase 4: opencode service restart after key seeding

- [ ] **4.1** At the tail of `setup_provider_credentials` in `deploy/setup.sh`: when a key was seeded this run AND `opencode` is installed, run `timeout 15 opencode service restart` (best-effort; failure ⇒ log the manual command `opencode service restart` and continue); dry-run logs intent only
    — **Why:** The v2 background service captures its environment at start, so `{env:ZAI_API_KEY}` MCP servers (zai-web-reader/search) keep failing until restart — this is the fix for the reported bashrc symptom
    — **Done when:** A run with opencode stubbed invokes the restart; a failing stub does not fail the setup (step returns 0 with a warning); dry-run performs no restart
    — **Consumers affected:** long-lived opencode background service (restart only); none in-repo

### Phase 5: help text + README

- [ ] **5.1** Add the feature to `show_help` in `deploy/setup.sh` and the mirrored help in `deploy/setup.ps1` (one block: detection step + pi/codex seeding + service restart)
    — **Why:** Help is the operator-facing contract and parity is test-pinned (`test_help_parity.bats`) — adding to setup.sh alone would break parity CI
    — **Done when:** `./setup.sh --help` and the ps1 help both contain the new block; parity test passes
    — **Consumers affected:** `tests/test_help_parity.bats`; operators

- [ ] **5.2** Add a short feature paragraph to `README.md` (multi-agent detection + pi/codex key seeding + the service-restart note)
    — **Why:** README is the usage surface for deploy features; repo sync rules require it for setup behavior changes
    — **Done when:** README mentions the feature once in the appropriate section; no counts drift (no skill/agent counts touched)
    — **Consumers affected:** docs readers; count-drift tests (must stay green — no counts edited)

### Phase 6: tests + verification

- [ ] **6.1** Add `tests/test_agent_detection_seed.bats`: separate `@test` blocks (no `&&`-chained assertions) with temp HOME + stubbed `pi`/`codex` binaries on PATH — (a) pi present + `ZAI_API_KEY` set ⇒ `~/.pi/agent/models.json` gains `providers.zai` with `apiKey` literally `"$ZAI_API_KEY"` and a pre-seeded sibling provider survives; (b) agents absent ⇒ no `~/.pi`/`~/.codex` writes, functions return 0; (c) `DRY_RUN=true` ⇒ neither file is created/modified; (d) codex present ⇒ TOML block appended once, second call no-op. Use `grep` (not `rg`); positive control: a real (non-dry) run must change bytes
    — **Why:** The repo's LEARNINGS catalog records dry-run leaks and false-green gates as recurring bug classes; these are the exact failure modes of this change, and separate assertions avoid the chained-assertion trap
    — **Done when:** `bats tests/test_agent_detection_seed.bats` passes locally and the full suite stays green
    — **Consumers affected:** CI bats suite

- [ ] **6.2** Full verification gate: `bash -n deploy/setup.sh`; node syntax check on the mjs helper; full bats suite; confirm no `rg` usage inside the new bats file; confirm no skill/agent count surfaces changed
    — **Why:** Non-trivial logic requires the exit gate before the PR citation (verification-loop-skill tier=full for the ticket exit gate)
    — **Done when:** All checks green in one run on the final tree; gate memo appended to this PLAN's trace
    — **Consumers affected:** Step 10a PR citation

## Technical Notes

- Key delivery is env-interpolation everywhere: pi `apiKey: "$ZAI_API_KEY"` (pi resolves `$VAR` at runtime); codex `env_key = "ZAI_API_KEY"` (codex reads the env var per invocation and sends Bearer). No literal keys in any file.
- Endpoints: pi uses the chat-completions PAAS base `https://api.z.ai/api/paas/v4` with `api: "openai-completions"`; codex uses the OpenAI Responses base `https://api.z.ai/api/v1` (`wire_api = "responses"` is the only supported value since the chat removal).
- Never set codex global `model`/`model_provider` — activation stays opt-in via `codex --profile zai`.
- `detect_installed_agents` is read-only and idempotent so `print_summary` can call it directly without flag plumbing.
- OpenCode model-provider auth is NOT touched — auth.json seeding already exists (#471 `setup_provider_credentials`); only the service-restart tail is added there.
- bats rules: `grep` not `rg` (CI runners lack ripgrep); one assertion per block; positive controls so over-gating can't silently no-op.

## Dependencies

- None in-repo. External behavior references: pi models.json provider schema; codex config.toml `model_providers`; OpenCode v2 service lifecycle (`opencode service restart`).

## Risks & Mitigation

- **User TOML/JSON clobber** (highest risk): mitigated by merge-only mjs helper with byte-stable output (pi) and grep-guarded append (codex); both covered by idempotency tests in 6.1.
- **Stub-vs-real drift** (tests stub `pi`/`codex`): stubs only need to exist on PATH for gating; verification via `pi --list-models` is warn-only so a stub that "fails" the probe cannot fail setup.
- **Service restart on machines without a running service**: best-effort with timeout; failure logs the manual command, never fails the run (non-critical semantics).
- **Help parity drift**: 5.1 ships both files together; `test_help_parity.bats` backstops.
- **Drift with future pi/codex config schema changes**: endpoints and field names are commented with doc references at each definition site for the next maintainer.
