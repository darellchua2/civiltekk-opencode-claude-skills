# PLAN: Park stale opencode.jsonc sibling during config deploy

**Branch**: feat/432
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/432
**Base**: main
**Review**: architecture-review approved 2026-09-19 (WARN-1 dry-run guard, WARN-2 coexistence guard folded in; Mode R relay resolutions applied)

## Acceptance Criteria

- [ ] `deploy/setup.sh` parks a coexisting `~/.config/opencode/opencode.jsonc` as `opencode.jsonc.legacy-ignored` (rename, never delete) in two places: (a) before the config-exists prompt, guarded on BOTH files present, and (b) after a successful config copy, so exactly one live config remains on every exit path; each park uses `run_cmd mv` (dry-run-safe) with a `log_warn` naming the rename
- [ ] `deploy/setup.ps1` mirrors both parks with the both-exist guard, `if (-not $DryRun)` around `Move-Item`, and `Write-LogWarn`
- [ ] `tests/test_jsonc_sibling.bats` pins both park sites in both scripts (existence, both-exist guard form, dry-run form, ordering before the config-exists prompt); the suite passes
- [ ] README documents the parking behavior and that `--rollback` restores prior state (undoing a park)
- [ ] A jsonc-only machine (no `opencode.json`) that declines the config copy keeps its live `opencode.jsonc` untouched — no park fires

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. CodeGraph unavailable on this branch (index not gitignored — rg/grep fallback used)._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` config phase (~line 2440) | legacy `config.json` migration block stays first | users running deploy; README:778 claim; new bats test | low |
| `deploy/setup.ps1` config phase (~line 1710) | `$LegacyConfigFile` migration block stays first | Windows users; README parity; new bats test | low |
| `tests/test_jsonc_sibling.bats` (new) | both setup scripts' anchors existing | CI bats suite (auto-globs `tests/*.bats`, no wiring needed) | low |
| `README.md` deploy section (~line 778) | shipped script behavior | readers of install docs | low |
| `LEARNINGS/anti-patterns/*.md` (2 new) | review evidence (this ticket) | future sessions' review/plan recall | low |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: bash deploy fix

- [x] **1.1** Add the pre-prompt coexistence park to `deploy/setup.sh` immediately after the legacy `config.json` migration if/elif block: guarded on `[ -f "$CONFIG_FILE" ] && [ -f "${CONFIG_DIR}/opencode.jsonc" ]`, body `run_cmd mv "${CONFIG_DIR}/opencode.jsonc" "${CONFIG_DIR}/opencode.jsonc.legacy-ignored"` plus a `log_warn` naming the rename
    — **Why:** the ticket's defect is undefined `.json`/`.jsonc` precedence (v2 docs define no tie-break per directory); the both-exist guard (per review WARN-2 + Mode R Gap 1) covers the verified coexistence scenario without ever disabling a jsonc-only user's sole live config, and `run_cmd` (review WARN-1 + Mode R Gap 2) keeps `--dry-run` preview-only
    — **Done when:** `grep -n 'run_cmd mv "${CONFIG_DIR}/opencode.jsonc"' deploy/setup.sh` hits at a line number lower than the `opencode.json already exists at` prompt line, and the guarding line contains both `-f "$CONFIG_FILE"` and `-f "${CONFIG_DIR}/opencode.jsonc"`
    — **Consumers affected:** the deploy path of `setup.sh`; Phase 2 parity; step 1.3's test anchors
    — **Done:** pre-prompt park inserted after the legacy config.json migration block (both-exist guard, `run_cmd mv`, `log_warn`); files: deploy/setup.sh; fixes: none
- [x] **1.2** Add the copy-accept park inside the `if [ "$SKIP_CONFIG_COPY" != true ]; then` branch immediately after the config `run_cmd cp`: same both-exist guard, `run_cmd mv` to `opencode.jsonc.legacy-ignored`, `log_warn`
    — **Why:** Mode R Gap 1 residual — a jsonc-only user who accepts the copy prompt recreates coexistence; parking at the moment the deploy creates `opencode.json` restores the ticket's "exactly one config file remains" end-state on the accept path too
    — **Done when:** a second `run_cmd mv "${CONFIG_DIR}/opencode.jsonc"` anchor exists in `setup.sh` at a line number greater than the config-copy line
    — **Consumers affected:** the deploy path of `setup.sh`; step 1.3's test anchors
    — **Done:** copy-accept park inserted after the config `run_cmd cp` + `log_success`; files: deploy/setup.sh; fixes: none
- [x] **1.3** Create `tests/test_jsonc_sibling.bats` with structure pins (house pattern from `tests/deploy_delegate.bats:61`, per `LEARNINGS/patterns/bats-structure-pin-call-order.md`): (a) both park anchors exist with line ordering pre-prompt-park < prompt < copy < copy-accept-park; (b) the park guard is the both-exist form (both `-f`/`Test-Path` operands present), not jsonc-only; (c) the bash mutation is `run_cmd mv`, never a bare `mv`; (d) a negative grep that no bare `mv "${CONFIG_DIR}/opencode.jsonc"` exists
    — **Why:** correctness here is positional and contract-shaped inside a 4k-line script; the repo's established regression net for deploy-path ordering is a grep line-ordering pin
    — **Done when:** `bats tests/test_jsonc_sibling.bats` exits 0
    — **Consumers affected:** CI bats suite
    — **Done:** structure-pin bats file created (deploy-order pin, both-exist guard count=2, run_cmd count=2, bare-mv negative grep); files: tests/test_jsonc_sibling.bats; fixes: none
- [x] **1.4** Run the new test plus `tests/deploy_delegate.bats` (the existing deploy-path pin suite)
    — **Why:** prove the new blocks pass their own pins and did not break the existing deploy-path ordering pins
    — **Done when:** both bats invocations exit 0
    — **Consumers affected:** none beyond CI
    — **Done:** test_jsonc_sibling 2/2 ok, deploy_delegate 4/4 ok; files: none; fixes: none

### Phase 2: PowerShell mirror

- [x] **2.1** Add both parks to `deploy/setup.ps1` mirroring Phase 1: `$JsoncConfigFile = Join-Path $ConfigDir "opencode.jsonc"`; pre-prompt park after the `$LegacyConfigFile` migration block and copy-accept park inside the copy branch, each guarded on `Test-Path $ConfigFile` **-and** `Test-Path $JsoncConfigFile`, mutation wrapped in `if (-not $DryRun) { Move-Item ... }`, with `Write-LogWarn` (function at `setup.ps1:184`; guard pattern per `setup.ps1:1692,1701,1750`)
    — **Why:** Windows deploys have the identical defect; parity between the two deploy scripts is a repo convention, and the Mode R resolutions (both-exist + dry-run safety) apply to both scripts equally
    — **Done when:** `grep -n 'opencode\.jsonc\.legacy-ignored' deploy/setup.ps1` hits twice and `grep -n 'Write-LogWarn "Stale opencode.jsonc' deploy/setup.ps1` hits twice
    — **Consumers affected:** the deploy path of `setup.ps1`; step 2.2's test anchors
    — **Done:** `$JsoncConfigFile` var added to the config-var block; both parks inserted (pre-prompt after the legacy migrate block, copy-accept after the config Copy-Item) with both-exist guard + DryRun wrap + Write-LogWarn; files: deploy/setup.ps1; fixes: none
- [x] **2.2** Extend `tests/test_jsonc_sibling.bats` with a ps1 `@test` pinning both parks: two `.legacy-ignored` anchors, both-exist guard form (`Test-Path $ConfigFile` -and the jsonc operand), and `if (-not $DryRun)` wrapping
    — **Why:** pin the mirror so the two deploy scripts cannot silently drift apart again
    — **Done when:** `bats tests/test_jsonc_sibling.bats` exits 0 with all tests
    — **Consumers affected:** CI bats suite
    — **Done:** ps1 pin added (deploy-order pin park1<prompt<copy<park2, both-exist guard count=2, DryRun wrap count=2, statement-start Move-Item negative); files: tests/test_jsonc_sibling.bats; fixes: none

### Phase 3: docs, learnings, full gate

- [ ] **3.1** Update the README deploy bullet at line 778 to state that a coexisting `opencode.jsonc` found during deploy is parked as `opencode.jsonc.legacy-ignored` (data preserved, never deleted), that this fires only when `opencode.json` is or becomes present, and that `--rollback` restores prior state and can undo a park
    — **Why:** docs must match deployed behavior — the bullet currently implies `opencode.json` is the only config file the deploy manages; the rollback sentence covers review NOTE-2
    — **Done when:** README contains the parking claim and the rollback sentence adjacent to the existing config-copy bullet
    — **Consumers affected:** README readers; no code consumers
- [ ] **3.2** Persist the two review-proposed learnings as `LEARNINGS/anti-patterns/park-read-config-file-needs-conflict-guard.md` and `LEARNINGS/anti-patterns/bare-mv-beside-run-cmd-breaks-dry-run.md` (2-line form per memory-hygiene house rules, evidence: this ticket + review session)
    — **Why:** the architecture reviewer requested persistence; both patterns are generalizable beyond this fix (parking a runtime-READ config needs a conflict guard; new mutations must route through `run_cmd`/`-not $DryRun` because the legacy migrate block's bare `mv` is a leaky precedent)
    — **Done when:** both files exist under `LEARNINGS/anti-patterns/` and are committed in their own commit
    — **Consumers affected:** future LEARNINGS recall in this repo
- [ ] **3.3** Run the full bats suite as the phase-3 verification gate input
    — **Why:** the touched scripts anchor several other pins (`deploy_delegate`, `test_backup_rollback`); the full suite is the gate contract's evidence
    — **Done when:** `bats tests/` exits 0
    — **Consumers affected:** none beyond CI

## Technical Notes

- OpenCode v2 docs (`https://opencode.ai/v2/docs/config/#locations`) document merge order across directories but define no `.json` vs `.jsonc` tie-break when both live in the same directory — hence "undefined precedence".
- Parks are renames, never deletes (data preserved), matching the `config.json.legacy-ignored` precedent — but with a both-exist guard, because unlike `config.json` (never read by v2), `opencode.jsonc` IS read by v2 and can be a user's sole live config (review WARN-2, Mode R Gap 1).
- Dry-run safety: new mutations route through `run_cmd mv` (bash) / `if (-not $DryRun)` (ps1). The adjacent legacy migrate block's bare `mv` (`setup.sh:2445,2448`; `setup.ps1:1712,1715`) is a PRE-EXISTING dry-run leak — explicitly out of scope for #432 (candidate follow-up ticket), deliberately not copied.
- Local machine impact: on this machine the 50-byte schema-only stub at `~/.config/opencode/opencode.jsonc` gets parked on the next real deploy — no manual action needed. The pipeline does NOT touch `~/.config/opencode/` itself.

## Dependencies

None — single contained fix, no blocked-by tickets.

## Risks & Mitigation

- **User's `.jsonc` was hand-authored (not a stub):** mitigated by design — the both-exist guard leaves a jsonc-only machine untouched, and any park is a data-preserving rename with a warning naming the new path.
- **Grep anchors drift** if the prompt wording changes: mitigation — the pin greps the stable string `opencode.json already exists at`, unchanged since the v2 migration.
- **Re-park overwrites an earlier parked copy** (review NOTE-1): accepted — data loss confined to an already-parked file; mirror-faithful with the `config.json` block; the warning names each rename.

## Execution Trace

- Phase 1 (1.1–1.4): GATE 9130a36 lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — bash -n clean; bats test_jsonc_sibling 2/2 ok, deploy_delegate 4/4 ok; lint/typecheck: none configured (no shellcheck/eslint/tsc manifests)
- Phase 2 (2.1–2.2): GATE ec59536 lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — bats test_jsonc_sibling 3/3 ok (incl. ps1 mirror pin), deploy_delegate 4/4 ok; pwsh parser absent — structural pins are the ps1 gate
