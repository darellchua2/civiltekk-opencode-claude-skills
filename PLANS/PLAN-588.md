# PLAN: setup.sh must not restart the opencode service when credentials are unchanged

**Branch**: feat/588
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/588
**Base**: main

## Acceptance Criteria

From the ticket's Expected behavior:

- [ ] A re-run of `deploy/setup.sh` (full or quick path) with the credential already seeded in `~/.local/share/opencode/auth.json` AND the same key present in the environment is a credentials no-op: no re-seed, no `opencode service restart`, no interruption of a live opencode session.
- [ ] A genuinely fresh or changed key still seeds every auth_id and still restarts the background service (#573 behavior preserved), and setup **announces the restart (and its live-session impact) before performing it**.
- [ ] The pre-existing idempotency path (env var unset + already seeded → skip without prompting) keeps working unchanged.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|----------------------------------|-------------|
| `deploy/setup.sh` — `setup_provider_credentials()` identical-key gate (after key capture, ~:4119) | — | full/quick deploy plan step `credentials`; `seed_agent_keys` runs after it; live opencode sessions (the blast radius this fixes) | med |
| `deploy/setup.sh` — #573 restart block announcement (~:4153-4168) | gate semantics (1.1) | users watching a deploy; ticket AC "announces before restart" | low |
| `deploy/setup.sh` — `show_help()` #573 paragraph (~:706-710) | 1.1 + 1.2 semantics | `--help` readers; `tests/test_help_parity.bats` (prose not pinned, verify) | low |
| `tests/test_provider_credentials.bats` — new regression tests | 1.1 + 1.2 + 1.3 | CI bats suite (`tests/lib`, `tests/test_helper`) | low |

No config (`opencode.json`), agent, skill, or MCP surfaces change — the AGENTS.md "Adding Skills or Subagents" sync table is out of scope.

## Implementation Phases

### Phase 1: Idempotency gate + restart announcement (deploy/setup.sh)

- [ ] **1.1** Add an identical-key skip gate in `setup_provider_credentials()`, placed AFTER key capture (env/prompt) and BEFORE `register_provider_auth` seeding: when `auth.json` exists and EVERY auth_id already holds a key identical to the captured key, log "credentials unchanged … skipping re-seed and service restart" and `return 0` (never `exit` — non-critical plan step, LEARNING `plan-step-functions-must-return`). Key comparison happens inside a `node -e` one-liner with the key passed via environment (`AUTH_KEY="$key" node -e …`, mirroring `register_provider_auth`'s env pattern) — the key value is never logged or interpolated (LEARNING `dry-run-logs-interpolating-secrets`). Leave the existing no-env/already-seeded pre-prompt gate (~:4094-4106) untouched.
    — **Why:** This is the root-cause fix — the current gate only fires when the env var is empty, so an exported `ZAI_API_KEY` (persisted by `setup_shell_vars`) re-seeds and restarts the service on every run.
    — **Done when:** With auth.json seeded `key=X` and `ZAI_API_KEY=X` exported, sourcing setup.sh and calling `setup_provider_credentials` (PROVIDER=zai) returns 0, leaves auth.json byte-identical, and never invokes `opencode` (no verify call, no restart).
    — **Consumers affected:** the `credentials` plan step in every full/quick deploy; any live opencode session during a deploy (positively — no longer killed).

- [ ] **1.2** In the #573 restart block (~:4153-4168), before executing the real `opencode service restart`, emit one `log_info` line announcing the restart and its impact ("live opencode sessions will be interrupted"). Dry-run keeps its existing `[DRY-RUN]` line unchanged.
    — **Why:** Ticket AC requires setup to announce a genuine restart before performing it; also the honest signal for anyone running deploys beside live sessions.
    — **Done when:** A changed-key run prints the announcement line before the restart command runs; dry-run output contains no real-restart wording.
    — **Consumers affected:** deploy log readers; tests asserting the warning (2.2/2.3).

- [ ] **1.3** Update the `show_help()` "CODING AGENT DETECTION (#573)" paragraph (~:706-710): the restart happens only when a NEW key is seeded; unchanged credentials skip it.
    — **Why:** The help text currently promises an unconditional restart after key seeding — stale the moment 1.1 lands.
    — **Done when:** `./deploy/setup.sh --help` prose states the conditional restart; `tests/test_help_parity.bats` still passes.
    — **Consumers affected:** `--help` readers only.

### Phase 2: Regression tests (tests/test_provider_credentials.bats)

- [ ] **2.1** Add `same_key_env_set_skips_reseed_and_restart`: temp HOME, auth.json pre-seeded with `key=testkey123` for BOTH `zai` and `zai-coding-plan`, `ZAI_API_KEY=testkey123` exported, `opencode()` stubbed to append its args to a recording file (with `command_exists(){ return 0; }` and `timeout(){ shift; "$@"; }` stubs per the existing `verification_runs_via_opencode_when_installed` pattern). Assert: status 0, auth.json md5 unchanged, recording file absent (zero `opencode` invocations), output matches "unchanged".
    — **Why:** Pins the exact regression from the ticket — the every-run restart with an exported key.
    — **Done when:** `bats tests/test_provider_credentials.bats` passes with the new test green.
    — **Consumers affected:** CI bats suite.

- [ ] **2.2** Add `changed_key_reseeds_and_restarts`: same setup but auth.json holds `oldkey` while env holds `newkey`. Assert: both auth_ids now hold `newkey` (merge, both ids), recording file contains `service restart`, and output contains the interruption announcement from 1.2.
    — **Why:** Proves the restart path survives the new gate for genuine credential changes, with the required announcement.
    — **Done when:** Test green; restart recorded exactly once.
    — **Consumers affected:** CI bats suite.

- [ ] **2.3** Add `fresh_seed_restarts_service`: no auth.json present, env key set. Assert: auth.json created with both ids, `service restart` recorded, announcement printed.
    — **Why:** First-run behavior (#573's original case) must not regress behind the new gate.
    — **Done when:** Test green.
    — **Consumers affected:** CI bats suite.

### Phase 3: Verification gate

- [ ] **3.1** Run the full gate per `verification-loop-skill` tiering: `bash -n deploy/setup.sh`, `bats tests/test_provider_credentials.bats`, `bats tests/test_help_parity.bats`, `bats tests/test_dry_run_leaks.bats` (a dry-run-adjacent path was touched), then the repo's broader test entry per discovery. Fix any failure in the same phase's commit; record the gate memo.
    — **Why:** Lint + tests on the touched path are the repo's verification contract (no package.json scripts — bats + `bash -n` are the gate).
    — **Done when:** All listed commands exit 0; gate memo appended with `tier=full` for the exit gate.
    — **Consumers affected:** PR gate citation (Step 10a).

## Technical Notes

- Keep the diff inside `setup_provider_credentials()` plus the help paragraph; no `deploy/setup.ps1` change (thin launcher delegating to setup.sh since #474).
- Do NOT use `${VAR:+word}` conditionals on boolean string flags (`DRY_RUN`) — LEARNING `colon-plus-on-boolean-string-flags`.
- bats guards must use `grep`, not `rg` — LEARNING `ci-runners-lack-ripgrep-bats-guards-use-grep`.
- The `node -e` comparison must be fail-safe on corrupt auth.json (`2>/dev/null`, non-zero → falls through to re-seed, which `register_provider_auth` already handles by parking corrupt files).

## Dependencies

- None. #573 (closed) introduced the behavior being corrected; no open PRs or blocked-by tickets.

## Risks & Mitigations

- **Risk:** A user rotated the key in auth.json to a *different* value intentionally and expects the env key NOT to win. **Mitigation:** out of scope — current behavior already lets the env/prompt key win on every run; this PLAN only removes the no-op case.
- **Risk:** CI lacks `opencode` binary → stubs already handle (function shadows binary inside the sourced shell).
- **Risk:** Help-parity test pins the old paragraph. **Mitigation:** 1.3 runs `tests/test_help_parity.bats`; adjust wording if pinned (check the test's assertions before rewording assertions themselves — never weaken a test to pass).
