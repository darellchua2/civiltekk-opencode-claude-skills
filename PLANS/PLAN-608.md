# PLAN: Deploy never prunes agents removed from the repo

**Branch**: feat/608
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/608
**Base**: main

## Acceptance Criteria

- [ ] A redeploy (full or `--skills-only` — both route through `deploy_content()`) prunes manifest-tracked entries whose names have left `installer/registry.json`: both the installed files and the manifest rows are removed.
- [ ] The prune pass is dry-run safe: under `DRY_RUN=true` nothing is mutated, and the `--dry-run` flag is wired with the explicit-comparison spelling (the `${DRY_RUN:+…}` form is banned by `tests/test_dry_run_leaks.bats`).
- [ ] The prune pass is non-fatal on pre-#379 manifest-less installs (`init.mjs update` exits 2 with its adoption hint) — warn and continue, per the #379 contract.
- [ ] Entries still in the registry survive the prune pass untouched; regression tests cover convergence and the dry-run wiring.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` `deploy_content()` | `installer/init.mjs` `add` (runs first, creates the manifest) + `update --prune` (existing arm, init.mjs:1496-1511) | `deploy_agents()` (full + skills-only plan modes), `tests/deploy_delegate.bats` structure pin, `tests/test_dry_run_leaks.bats` spelling pins | med — deploy path; additive non-fatal call, order pinned by existing tests |
| `tests/deploy_delegate.bats` | `deploy/setup.sh` shape, `installer/init.mjs` | dev/CI regression net | low |
| `tests/test_dry_run_leaks.bats` | `deploy/setup.sh` shape | dev/CI regression net | low |

## Implementation Phases

### Phase 1: Wire the prune pass into deploy_content()

- [ ] **1.1** Add the convergence pass to `deploy_content()` in `deploy/setup.sh`, immediately after the `init.mjs add --all --yes` success check: `node "${INSTALLER_DIR}/init.mjs" update --prune $provider_arg $dry_arg` (reusing the function's existing locals), wrapped `if ! … then log_warn` so a missing pre-#379 manifest warns and continues instead of failing the deploy
    — **Why:** `add` is additive-only by design (`init.mjs:819` refuses `--prune` on add); convergence to the repo source can only ride the existing `update --prune` arm, and #379's contract keeps manifest-adoption gaps non-fatal
    — **Done when:** `bash -n deploy/setup.sh` passes and the prune invocation appears in `deploy_content()` after the `add --all` `rc` check, carrying `$dry_arg` from the existing explicit-comparison assignment
    — **Consumers affected:** `deploy_agents()` (full + skills-only deploys now converge); none other — `--select` and `--models-only` paths deliberately unchanged (curated installs / model-resolution mode)

### Phase 2: Regression net

- [ ] **2.1** Add `update --prune converges deployed agents to the registry` to `tests/deploy_delegate.bats`: full `add --all --yes` into temp HOME, plant a fake registry-removed agent (file + manifest `entries`/`agents` rows for `office-document-primary-agent`), run `update --prune`, assert the planted file and manifest rows are gone while a real agent (e.g. `code-review-subagent`) survives
    — **Why:** the delegation regression net must prove the deploy converges, not just accumulates — this is the exact machine state from the ticket
    — **Done when:** the new bats test passes against the fixed setup.sh/init.mjs and fails if the prune call is removed from `deploy_content()`
    — **Consumers affected:** dev/CI regression coverage; no runtime consumers

- [ ] **2.2** Add a wiring pin to `tests/test_dry_run_leaks.bats`: the prune invocation in `deploy/setup.sh` carries `$dry_arg` (fed by the existing pinned explicit-comparison spelling), mirroring the `setup_sh_models_only_passes_dry_run_to_manifest_update` pin style
    — **Why:** the prune pass mutates user config; the #467 leak class (real writes under `--dry-run`) must stay pinned at the wiring site
    — **Done when:** the pin test passes and `grep -Fc '${DRY_RUN:+--dry-run}' deploy/setup.sh` still finds zero occurrences
    — **Consumers affected:** dev/CI regression coverage; no runtime consumers

### Phase 3: Gate + validation

- [ ] **3.1** Run the gate: `bash -n deploy/setup.sh`, then `bats tests/deploy_delegate.bats tests/test_dry_run_leaks.bats tests/init.bats tests/update.bats tests/test_skills_only_parity.bats tests/test_default_behavior.bats tests/test_subcommands.bats` (every suite that sources or pins `deploy_content()`); fix any failure before push
    — **Why:** the touched function sits on the deploy path with existing structure/spelling pins — the pinned suites are the blast-radius proof
    — **Done when:** all listed bats suites green and `bash -n` clean on the final tree
    — **Consumers affected:** none runtime — evidence for the exit gate

## Technical Notes

- Prune semantics come from `installer/init.mjs` `cmdUpdate` (init.mjs:1496-1511): only manifest entries whose names are absent from `installer/registry.json` are pruned, across their recorded targets — user-hand-added agents outside the manifest are never touched.
- `--select` deploys (`deploy_selected_group`) and `--models-only` (`update_manifest`) are deliberately left un-pruned: curated installs and the model-resolution mode are out of the ticket's AC.
- The two exemplar files (`office-document-primary-agent.md`, `startup-founder-primary-agent.md`, removed in #280) are pruned by the machinery with no special-casing — no one-off rm in repo code.

## Dependencies

None. (`init.mjs update --prune` already shipped and tested at `tests/update.bats`.)

## Risks & Mitigations

- **Risk:** prune pass slows deploys (`update` re-hashes all entries). **Mitigation:** bounded by the manifest size, single extra pass, and it prints a one-line summary; acceptable for a deploy script.
- **Risk:** a user's locally-renamed agent that shadowed a registry name gets pruned on redeploy. **Mitigation:** that is the documented convergence semantics (manifest = system of record, #379); the backup snapshot in `deploy_content()` (`content-backup`) already preserves pre-overwrite state.
