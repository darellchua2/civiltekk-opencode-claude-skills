# PLAN: add + --prune is silently ignored — reject explicitly

**Branch**: feat/567
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/567
**Base**: main (0f10e16)

## Acceptance Criteria

- [ ] `add <name> --prune` (user scope), `add <name> --project <dir> --prune`, and `add --all --prune` all exit non-zero naming the flag and pointing at the preset flow / prune-only mode / remove
- [ ] Preset flow `--prune` and prune-only mode still work unchanged (existing tests stay green)
- [ ] No shipped caller passes `--prune` to `add` (setup.sh, setup.ps1, opencode_app, CI) — verified on origin/main @ 2cace4b (re-verified in-tree at Step 5)
- [ ] Help text documents that `--prune` is preset-flow/prune-only
- [ ] New tests per path; full `bats tests/` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` `cmdAdd` top guard | — | every `add` invocation (named, `--all`, both scopes) | low |
| `installer/init.mjs` `printHelp` `--prune` line | guard | CLI users | low |
| preset flow + prune-only mode | NOT touched | `doPrune` consumers (existing tests :320) | none |
| `tests/init.bats` | installer behavior | CI | low |

`doPrune` itself is untouched — the guard only blocks the flag from entering `cmdAdd`, where it was dead. Honoring it was rejected (single-name set-replace would delete unrelated installs — data loss); rejection message mirrors the sibling `remove --project: use --prune instead` die (:1286).

## Implementation Phases

### Phase 1: guard + help + tests

- [ ] **1.1** In `installer/init.mjs` `cmdAdd`: first statement (before the `--all` branch) — `if (opts.prune) die("'--prune' is not an add flag — it belongs to the preset/init flow (set replace) and prune-only mode. 'add' already migrates legacy copies of the names it installs; to remove entries use 'remove' (user scope) or the preset flow with --prune.", 2);`
    — **Why:** silent ignore is drift bait, and the flag can never be honored here without set-replace semantics deleting unrelated installs (data loss). Explicit rejection matches the `remove --project` die style.
    — **Done when:** `node --check` passes; `add tdd-workflow-skill --prune --yes`, `add tdd-workflow-skill --project <tmp> --prune --yes`, and `add --all --prune --yes` each exit 2 printing the message; `add --all --yes` (no prune) still works.
    — **Consumers affected:** every add path (verified: setup.sh `add --all --yes` / `add $names`, setup.ps1, opencode_app, CI — none pass `--prune`).
- [ ] **1.2** Help text: the `--prune` USAGE line (:1684) gains "(preset flow / prune-only; add rejects it)".
    — **Done when:** `--help` shows the note.
    — **Why:** undocumented rejection is a support burden.
    — **Consumers affected:** CLI users.
- [ ] **1.3** Tests in `tests/init.bats`: three rejection invocations (user scope, project scope, `--all`) each asserting non-zero exit + message fragment in output + no install dir created. Existing prune-only test (:320) must stay green.
    — **Done when:** the new test passes and `bats tests/init.bats` is green.
    — **Why:** the guard is contract — pin all three entry paths.
    — **Consumers affected:** CI gates.
- [ ] **1.4** Gate: `bats tests/init.bats` green.
    — **Done when:** exit 0.
    — **Why:** behavioral proof before the exit gate.
    — **Consumers affected:** Phase 2 gate.

### Phase 2: Full exit gate

- [ ] **2.1** Full `bats tests/`.
    — **Why:** ticket exit gate — full tier.
    — **Done when:** exit 0; `GATE <short-sha> tier=full` appended to the trace below.
    — **Consumers affected:** Step 9/10 citations.

## Technical Notes

- Guard is command-scoped (in `cmdAdd`), not global like the `-g`+`--project` guard — `--prune` remains valid for the preset flow and prune-only mode.
- `remove --project` already dies pointing at `--prune` (:1286) — that flow is unaffected and keeps its meaning.

## Dependencies

None (no `blocked-by:`).

## Risks & Mitigation

- **Caller regression** (a script passing `--prune` to add would now fail loudly): mitigated by the Step 5 caller sweep — setup.sh/ps1/opencode_app/CI verified clean; a loud failure is the desired outcome for that case anyway.

## Gate Trace
