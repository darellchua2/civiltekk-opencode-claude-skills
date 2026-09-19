# PLAN: Park stale opencode.jsonc sibling during config deploy

**Branch**: feat/432
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/432
**Base**: main
**Review**: architecture-review approved 2026-09-19 (WARN-1 dry-run guard, WARN-2 coexistence guard folded in; Mode R relay resolutions applied)

## Acceptance Criteria

- [x] `deploy/setup.sh` parks a coexisting `~/.config/opencode/opencode.jsonc` as `opencode.jsonc.legacy-ignored` (rename, never delete) via a shared `park_jsonc_sibling()` helper (both-exist guard, `run_cmd mv` = dry-run-safe, `log_warn` naming the rename), called from THREE sites: (a) before the config-exists prompt, (b) after a successful config copy, and (c) after an apply-mode resolver run — so the script's END STATE has exactly one live config on every apply-mode path (main flow incl. decline-copy, `--models-only`, `--migrate-only`) (Mode R round 2, AC-R1/R3)
- [x] `deploy/setup.ps1` mirrors the helper (`Park-JsoncSibling`) and all three call sites with the both-exist guard, `if (-not $DryRun)` around `Move-Item`, `Write-LogWarn`, and a post-resolver call gated on `-not $DryRun -and $LASTEXITCODE -eq 0`
- [x] `tests/test_jsonc_sibling.bats` pins both scripts: three-site ordering, helper contract (single guard/mutation), resolver-park gate line, and bare `[ ]` assertions (no `&&` chains — bats errexit exempts non-final links); the suite passes
- [x] README documents the parking behavior and that `--rollback` restores prior state (undoing a park)
- [x] A jsonc-only machine (no `opencode.json`) that declines the config copy keeps its live `opencode.jsonc` untouched by the config phase — no park fires there (both-exist guard requires `-f "$CONFIG_FILE"`; pinned by the guard-count assertion); the end state after the resolver write is governed by AC-1's post-resolver park

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
- [x] **3.1** Update the README deploy bullet at line 778 to state that a coexisting `opencode.jsonc` found during deploy is parked as `opencode.jsonc.legacy-ignored` (data preserved, never deleted), that this fires only when `opencode.json` is or becomes present, and that `--rollback` restores prior state and can undo a park
    — **Why:** docs must match deployed behavior — the bullet currently implies `opencode.json` is the only config file the deploy manages; the rollback sentence covers review NOTE-2
    — **Done when:** README contains the parking claim and the rollback sentence adjacent to the existing config-copy bullet
    — **Consumers affected:** README readers; no code consumers
    — **Done:** parking bullet + rollback sentence added under "The setup scripts automatically"; files: README.md; fixes: none
- [x] **3.2** Persist the two review-proposed learnings as `LEARNINGS/anti-patterns/park-read-config-file-needs-conflict-guard.md` and `LEARNINGS/anti-patterns/bare-mv-beside-run-cmd-breaks-dry-run.md` (2-line form per memory-hygiene house rules, evidence: this ticket + review session)
    — **Why:** the architecture reviewer requested persistence; both patterns are generalizable beyond this fix (parking a runtime-READ config needs a conflict guard; new mutations must route through `run_cmd`/`-not $DryRun` because the legacy migrate block's bare `mv` is a leaky precedent)
    — **Done when:** both files exist under `LEARNINGS/anti-patterns/` and are committed in their own commit
    — **Consumers affected:** future LEARNINGS recall in this repo
    — **Done:** both entries committed in their own commit (51bd95e) with ticket + review-session evidence; files: LEARNINGS/anti-patterns/{park-read-config-file-needs-conflict-guard,bare-mv-beside-run-cmd-breaks-dry-run}.md; fixes: none
- [x] **3.3** Run the full bats suite as the phase-3 verification gate input
    — **Why:** the touched scripts anchor several other pins (`deploy_delegate`, `test_backup_rollback`); the full suite is the gate contract's evidence
    — **Done when:** `bats tests/` exits 0
    — **Consumers affected:** none beyond CI
    — **Done:** full suite 340/340 ok, exit 0; files: none; fixes: none

### Phase 4: review fixes (code-review round 1: WARN-1 vacuous ps1 pin, WARN-2 resolver seam; Mode R round 2: end-state scope)

- [x] **4.1** Factor the bash park into `park_jsonc_sibling()` (helper defined above `setup_config()`, holding the both-exist guard + `run_cmd mv` + `log_warn`) and replace both inline park blocks in `setup_config` with bare calls
    — **Why:** review WARN-2's fix needs the park callable from the resolver path too, and the two duplicated inline blocks were one repetition from Rule-of-Three; consolidation also removes the park-2 message drift flagged as Minor
    — **Done when:** `grep -c 'park_jsonc_sibling() {' deploy/setup.sh` == 1, bare-call count == 2 at this step, `run_cmd mv` count == 1, and `bash -n deploy/setup.sh` exits 0
    — **Consumers affected:** the deploy path of `setup.sh`; step 4.4's pins
    — **Done:** helper added above setup_config(); both inline blocks replaced with bare calls; files: deploy/setup.sh; fixes: none
- [x] **4.2** Call `park_jsonc_sibling` at the end of `run_resolver` gated on `[ "$resolver_rc" -eq 0 ] && [ "$DRY_RUN" != true ]`, returning the preserved resolver rc — closing the resolver seam on the decline-copy path and in `--models-only`/`--migrate-only` modes
    — **Why:** Mode R round 2 scoped the invariant to the script's END STATE (in-ticket, required): the resolver unconditionally writes `opencode.json` in apply mode (resolve-models.mjs:463-466), recreating the ticket's exact defect after a declined copy; in-function placement covers all three resolver call sites with zero new wiring
    — **Done when:** bare-call count == 3, the gate line `[ "$resolver_rc" -eq 0 ] && [ "$DRY_RUN" != true ]` is present, and the call sits at a line number greater than `node "$RESOLVER_SCRIPT" \`
    — **Consumers affected:** `run_resolver` callers (deploy_agents, `--models-only`, `--migrate-only`); step 4.4's pins
    — **Done:** post-resolver park added with rc preservation (`return "$resolver_rc"`); files: deploy/setup.sh; fixes: none
- [x] **4.3** Mirror in `deploy/setup.ps1`: `Park-JsoncSibling` helper above `Set-Configuration`, bare calls replacing both inline parks, and a post-node call inside `Invoke-Resolver` gated on `-not $DryRun -and $LASTEXITCODE -eq 0`
    — **Why:** Windows parity for the same seam and the same consolidation rationale
    — **Done when:** `function Park-JsoncSibling` count == 1, bare-call count == 3, guard/mutation/warn counts == 1 each, gate line `if (-not $DryRun -and $LASTEXITCODE -eq 0) {` present
    — **Consumers affected:** the deploy path of `setup.ps1`; step 4.4's pins
    — **Done:** helper + both bare calls + gated post-resolver call added; files: deploy/setup.ps1; fixes: none
- [x] **4.4** Rewrite `tests/test_jsonc_sibling.bats`: three-site ordering pins with the unique anchors (`node "$RESOLVER_SCRIPT" \` / `& node $ResolverScript @resolverArgs` / ps1 prompt anchored on `Write-LogWarn "opencode.json already exists at`), helper-contract counts, resolver-gate line assertions, and every ordering assertion on its own bare `[ ]` line
    — **Why:** review WARN-1 — the old ps1 anchor matched setup.ps1:644 and `&&`-chained assertions mask non-final link failures under bats errexit, so the pin was green while broken; bare assertions are fail-fast
    — **Done when:** `bats tests/test_jsonc_sibling.bats` exits 0 with 4 tests, and flipping any single park line in a scratch copy makes the corresponding pin fail
    — **Consumers affected:** CI bats suite
    — **Done:** 4/4 tests ok; scratch-copy mutation test (first park commented out) detected: park1 fell to 2503 > prompt 2471, ordering assertion fails; files: tests/test_jsonc_sibling.bats; fixes: none
- [x] **4.5** Amend `LEARNINGS/anti-patterns/park-read-config-file-needs-conflict-guard.md` evidence to the end-state scope (post-resolver park) once 4.2 lands
    — **Why:** review NOTE — the entry claimed "every exit path" before the resolver seam was closed; docs must match the shipped behavior
    — **Done when:** the entry cites the resolver placement and the invariant reads as end-state
    — **Consumers affected:** future LEARNINGS recall
    — **Done:** entry amended to three-site end-state coverage with resolver evidence; files: LEARNINGS/anti-patterns/park-read-config-file-needs-conflict-guard.md; fixes: none
- [x] **4.6** Run the full bats suite as the phase-4 verification gate input
    — **Why:** the helper refactor moves anchors other pins may reference; full-suite green is the gate contract's evidence before re-review
    — **Done when:** `bats tests/` exits 0
    — **Consumers affected:** none beyond CI
    — **Done:** full suite 341/341 ok, exit 0; files: none; fixes: none

## Plan Review Trace

- Architecture review (pre-implementation): approved — WARN-1 dry-run guard, WARN-2 both-exist guard folded into the PLAN before execution; Requirements Gaps relayed to requirements-specialist round 1 (both-exist + copy-accept park, dry-run safety)
- Mode R round 2 (post code review): invariant scoped to the setup script's END STATE, in-ticket — post-resolver park via shared helper required (AC-R1/R2/R3)
- Code review round 1 (feat/432 9130a36..7e2f83ca): fix-first — WARN-1 vacuous ps1 ordering pin (non-unique anchor + &&-chain masking), WARN-2 resolver seam; both addressed in Phase 4

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
- Phase 3 (3.1–3.3): GATE 51bd95e lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — full bats suite 340/340 ok exit 0
- Phase 4 (4.1–4.6): GATE 7c79909 lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — bash -n clean; test_jsonc_sibling 4/4 ok incl. mutation canary (pin fails when first park removed); full suite 341/341 ok
