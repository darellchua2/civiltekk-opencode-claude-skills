# PLAN: Park stale opencode.jsonc sibling during config deploy

**Branch**: feat/432
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/432
**Base**: main

## Acceptance Criteria

- [ ] `deploy/setup.sh` parks a pre-existing `~/.config/opencode/opencode.jsonc` as `opencode.jsonc.legacy-ignored` (data preserved, never deleted) during the config phase, with a `log_warn` naming the rename
- [ ] `deploy/setup.ps1` mirrors the same behavior with `Write-LogWarn`
- [ ] A bats regression test pins the park block in both scripts (existence + ordering before the config-exists prompt); the suite passes
- [ ] README documents that stale `opencode.jsonc` siblings are parked as `.legacy-ignored`

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. CodeGraph unavailable on this branch (index not gitignored — rg/grep fallback used)._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` config phase (~line 2440) | legacy `config.json` migration block stays first | users running deploy; README:778 claim; new bats test | low |
| `deploy/setup.ps1` config phase (~line 1710) | `$LegacyConfigFile` migration block stays first | Windows users; README parity; new bats test | low |
| `tests/test_jsonc_sibling.bats` (new) | both setup scripts' anchors existing | CI bats suite | low |
| `README.md` deploy section (~line 778) | shipped script behavior | readers of install docs | low |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: bash deploy fix

- [ ] **1.1** Add the `opencode.jsonc` park block to `deploy/setup.sh` immediately after the legacy `config.json` migration if/elif block: `mv "${CONFIG_DIR}/opencode.jsonc" "${CONFIG_DIR}/opencode.jsonc.legacy-ignored"` guarded by `[ -f ... ]`, with a `log_warn` naming the rename (mirrors the adjacent `config.json.legacy-ignored` pattern, bare `mv` like its neighbor)
    — **Why:** this is the ticket's defect — a stale `.jsonc` sibling has undefined precedence vs `opencode.json` (v2 docs define no tie-break per directory); placement after the adjacent migrate block keeps all sibling-parking in one place and before the config-exists prompt, so it also applies when the user declines the overwrite
    — **Done when:** `grep -n 'opencode\.jsonc\.legacy-ignored' deploy/setup.sh` hits at a line number lower than the `opencode.json already exists at` prompt line
    — **Consumers affected:** the deploy path of `setup.sh`; Phase 2 parity; step 1.2's test anchors
- [ ] **1.2** Create `tests/test_jsonc_sibling.bats` with a structure pin (house pattern from `tests/deploy_delegate.bats:61`, per `LEARNINGS/patterns/bats-structure-pin-call-order.md`): assert the park line exists in `setup.sh` and its line number precedes the config-exists prompt line; assert the park is a rename (`mv` … `legacy-ignored`), never a bare delete
    — **Why:** the correctness here is positional inside a 4k-line script; the repo's established regression net for deploy-path ordering is a grep line-ordering pin
    — **Done when:** `bats tests/test_jsonc_sibling.bats` exits 0
    — **Consumers affected:** CI bats suite
- [ ] **1.3** Run the new test plus `tests/deploy_delegate.bats` (the existing deploy-path pin suite)
    — **Why:** prove the new block passes its own pin and did not break the existing deploy-path ordering pins
    — **Done when:** both bats invocations exit 0
    — **Consumers affected:** none beyond CI

### Phase 2: PowerShell mirror

- [ ] **2.1** Add the matching park block to `deploy/setup.ps1` immediately after the `$LegacyConfigFile` migration if/elseif block: `$JsoncConfigFile = Join-Path $ConfigDir "opencode.jsonc"`; `Move-Item` to `.legacy-ignored` guarded by `Test-Path`, with `Write-LogWarn` (function exists at `setup.ps1:184`)
    — **Why:** Windows deploys have the identical undefined-precedence defect; parity between the two deploy scripts is a repo convention
    — **Done when:** `grep -n 'opencode\.jsonc\.legacy-ignored' deploy/setup.ps1` and `grep -n 'Write-LogWarn "Stale opencode.jsonc' deploy/setup.ps1` both hit
    — **Consumers affected:** the deploy path of `setup.ps1`; step 2.2's test anchors
- [ ] **2.2** Extend `tests/test_jsonc_sibling.bats` with a second `@test` pinning the ps1 mirror (both grep anchors from 2.1)
    — **Why:** pin the mirror so the two deploy scripts cannot silently drift apart again
    — **Done when:** `bats tests/test_jsonc_sibling.bats` exits 0 with both tests
    — **Consumers affected:** CI bats suite

### Phase 3: docs + full gate

- [ ] **3.1** Update the README deploy bullet at line 778 to state that a stale `opencode.jsonc` sibling found during deploy is parked as `opencode.jsonc.legacy-ignored` (data preserved)
    — **Why:** docs must match deployed behavior — the bullet currently implies `opencode.json` is the only config file the deploy manages
    — **Done when:** README contains the parking claim adjacent to the existing config-copy bullet
    — **Consumers affected:** README readers; no code consumers
- [ ] **3.2** Run the full bats suite as the phase-3 verification gate input
    — **Why:** the touched scripts anchor several other pins (`deploy_delegate`, `test_backup_rollback`); the full suite is the gate contract's evidence
    — **Done when:** `bats tests/` exits 0
    — **Consumers affected:** none beyond CI

## Technical Notes

- OpenCode v2 docs (`https://opencode.ai/v2/docs/config/#locations`) document merge order across directories but define no `.json` vs `.jsonc` tie-break when both live in the same directory — hence "undefined precedence".
- The park (rename, not delete) mirrors the existing `config.json.legacy-ignored` behavior in both scripts; data is never destroyed.
- Local machine impact: on this machine the 50-byte schema-only stub at `~/.config/opencode/opencode.jsonc` gets parked on the next real deploy — no manual action needed. The pipeline does NOT touch `~/.config/opencode/` itself.
- `--dry-run` parity: the adjacent migrate block uses bare `mv` (not `run_cmd`), so the park block matches that precedent exactly.

## Dependencies

None — single contained fix, no blocked-by tickets.

## Risks & Mitigation

- **User's `.jsonc` was their real config** (not a stub): risk is low — the rename preserves it verbatim and the warning names the new path; the same trade-off was already accepted for `config.json.legacy-ignored`. Mitigation: warning message states the exact rename.
- **Grep anchors drift** if the prompt wording changes: mitigation — the pin greps the stable string `opencode.json already exists at`, unchanged since the v2 migration.
