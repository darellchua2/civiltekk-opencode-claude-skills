# PLAN: error_handler crashes on unbound BASH_LINENO under nounset

**Branch**: feat/501
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/501
**Base**: main

## Acceptance Criteria
- [x] Trap invocation nounset-safe: `"${BASH_LINENO[0]:-0}"` (no behavior change for real unguarded errors in `main` execution — still logs + exits non-zero)
- [x] The repro command exits 1 with no `unbound variable` on stderr
- [ ] `bats tests/` runs with zero BW01 warnings from `test_subcommands.bats`
- [x] Regression pin: new bats test asserting the sourced-context failing call yields rc 1 (not 127) and no `unbound variable` output
- [ ] `bash -n deploy/setup.sh` passes; full vendored bats suite stays green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh:492` ERR trap invocation | — | Every unguarded error path in `main` execution AND every sourced-context bare call (bats stub idiom, `bash -c` scripts) | low — diagnostic-degradation only; exit code stays non-zero |
| `error_handler()` (:457-483, untouched) | trap invocation contract (`$1` line, `$2` code) | Same as above | none — no edit |
| `tests/test_err_trap_nounset.bats` (new) | deploy/setup.sh trap fix | CI suite | low |
| `tests/test_subcommands.bats:65` (untouched) | fixed trap (asserts `-ne 0`; satisfied by rc 1) | suite | none — no edit |

Out of scope: setup.ps1 (PowerShell has no ERR-trap semantics), any redesign of trap scoping (only-trap-in-main) — larger behavior change than the bug warrants.

## Implementation Phases

### Phase 1: Nounset-safe trap + regression pin
- [ ] **1.1** In `deploy/setup.sh` line 492, change the trap invocation argument `"${BASH_LINENO[0]}"` to `"${BASH_LINENO[0]:-0}"` so the handler survives fire contexts where the array element is unset (diagnostics then report line 0 instead of crashing with 127).
    — **Why:** AC-1 — this is the root cause: the only unguarded array ref in the handler chain crashes under nounset, converting expected return-1 paths into rc 127.
    — **Done when:** the repro (`HOME=$(mktemp -d) bash -c "source deploy/setup.sh >/dev/null 2>&1; DRY_RUN=false; LOAD_PRESET_NAME=nope; load_user_preset"`) exits 1 with no `unbound variable` on stderr.
    — **Consumers affected:** all error paths — guarded (`if !`/`run_plan`) contexts never hit the trap, so their behavior is unchanged; unguarded bare failures now get the intended diagnostic + exit 1.
    — **Done:** `:-0` applied at the trap invocation (sole unguarded ref); repro exits 1, `unbound variable` grep = 0; files: deploy/setup.sh; fixes: none
- [x] **1.2** Add `tests/test_err_trap_nounset.bats` with one house-idiom test pinning the repro: sourced setup.sh + bare failing call → rc exactly 1 (not 127) and no `unbound variable` in combined output.
    — **Why:** AC-4 — the warning regressed silently once already (pre-existing on main, surfaced only via BW01); the pin makes a future nounset regression a hard red.
    — **Done when:** the new test passes and the file follows the `bash -c` stub idiom of test_subcommands.bats.
    — **Consumers affected:** CI suite.
    — **Done:** test added and green (rc==1, no unbound-variable output); files: tests/test_err_trap_nounset.bats; fixes: none

### Phase 2: Suite-level BW01 sweep
- [ ] **2.1** Run the full vendored bats suite and verify zero BW01 warnings originating from `test_subcommands.bats` (capture suite output, grep for `BW01` + the file name; a BW01 from an unrelated file, if any, is reported — not fixed here).
    — **Why:** AC-3 — the warning is per-run noise; the sweep proves the specific source is gone without claiming the whole suite is warning-free.
    — **Done when:** full suite output contains no BW01 entry citing test_subcommands.bats, and the suite is green.
    — **Consumers affected:** CI logs.

## Technical Notes
- Repro (verified on base 07fb5e7): `d=$(mktemp -d); HOME="$d" bash -c "source deploy/setup.sh >/dev/null 2>&1; DRY_RUN=false; LOAD_PRESET_NAME=nope; load_user_preset"` → stderr `BASH_LINENO[0]: unbound variable`, rc 127.
- `error_handler` treats `$1` as the line number; `:-0` degrades the diagnostic to "line 0" (same as what command-substitution contexts already printed) without touching the handler body.
- Guarded failure contexts (`run_plan`'s `if ! "$func"`, `if !` conditions generally) never fire ERR — no behavior change there.
- The preset test at test_subcommands.bats:65 asserts `[ "$status" -ne 0 ]` — rc 1 satisfies it; only the 127 crash produced BW01.

## Dependencies
None — single contained ticket, no `blocked-by:` refs.

## Risks & Mitigation
- **Masking real errors with a degraded line number** — mitigated: `:-0` only fires where the value is genuinely unavailable (sourced contexts); `main` execution has BASH_LINENO populated and keeps exact lines.
- **Suite behavior drift** — the only affected assertion is `-ne 0`; the full gate covers it.

## Gate Trace

Full tier on both phases — deploy file anchor (deploy/setup.sh) and the ticket exit gate is full unconditionally. Lint = `bash -n deploy/setup.sh`. Typecheck/build: no manifest targets — n.a. Unit = full vendored bats suite. E2E = n.a (no Playwright).

### Phase 1
- WORK LOG: full-tier escalation reason — deploy file anchor.
- GATE (pending-commit sha) tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a — bash -n ok; repro `unbound variable` hits = 0; bats 524 ok / 0 fail (523 prior + 1 new pin).
