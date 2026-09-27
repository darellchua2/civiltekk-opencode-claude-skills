# PLAN: Deploy never prunes agents removed from the repo

**Branch**: feat/608
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/608
**Base**: main

## Acceptance Criteria

- [x] A redeploy (full or `--skills-only` — both route through `deploy_content()`) prunes manifest-tracked entries whose names have left `installer/registry.json`: both the installed files and the manifest rows are removed.
- [x] The prune pass is dry-run safe: under `DRY_RUN=true` nothing is mutated, and the `--dry-run` flag is wired with the explicit-comparison spelling (the `${DRY_RUN:+…}` form is banned by `tests/test_dry_run_leaks.bats`).
- [x] The prune pass is non-fatal on pre-#379 manifest-less installs (`init.mjs update` exits 2 with its adoption hint) — warn and continue, per the #379 contract.
- [x] Entries still in the registry survive the prune pass untouched; regression tests cover convergence and the dry-run wiring.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` `deploy_content()` | `installer/init.mjs` `add` (runs first, creates the manifest) + `update --prune` (existing arm, init.mjs:1496-1511) | `deploy_agents()` (full + skills-only plan modes), `tests/deploy_delegate.bats` structure pin, `tests/test_dry_run_leaks.bats` spelling pins | med — deploy path; additive non-fatal call, order pinned by existing tests |
| `tests/deploy_delegate.bats` | `deploy/setup.sh` shape, `installer/init.mjs` | dev/CI regression net | low |
| `tests/test_dry_run_leaks.bats` | `deploy/setup.sh` shape | dev/CI regression net | low |

## Implementation Phases

### Phase 1: Wire the prune pass into deploy_content()

- [x] **1.1** Add the convergence pass to `deploy_content()` in `deploy/setup.sh`, immediately after the `init.mjs add --all --yes` success check: `node "${INSTALLER_DIR}/init.mjs" update --prune $provider_arg $dry_arg` (reusing the function's existing locals), wrapped `if ! … then log_warn` so a missing pre-#379 manifest warns and continues instead of failing the deploy; the warn text mirrors `update_manifest`'s #379 adoption hint ("pre-#379 installs: one full re-run adopts the manifest")
    — **Why:** `add` is additive-only by design (`init.mjs:819` refuses `--prune` on add); convergence to the repo source can only ride the existing `update --prune` arm, and #379's contract keeps manifest-adoption gaps non-fatal — the hint wording lets pre-#379 users self-diagnose (review finding)
    — **Done when:** `bash -n deploy/setup.sh` passes and the prune invocation appears in `deploy_content()` after the `add --all` `rc` check, carrying `$dry_arg` from the existing explicit-comparison assignment
    — **Consumers affected:** `deploy_agents()` (full + skills-only deploys now converge); none other — `--select` and `--models-only` paths deliberately unchanged (curated installs / model-resolution mode; follow-up #610 owns `--select` convergence)
    — **Done:** convergence pass added after the `add --all` rc-check in `deploy_content()` — `update --prune $provider_arg $dry_arg` wrapped in `if !` with the #379-adoption-hint warn; files: deploy/setup.sh; fixes: none (note: an initial uncommitted draft of this hunk appeared in the worktree from a review delegate exceeding its read-only mandate — verified line-by-line, warn text corrected to carry the #379 hint per the review finding, adopted after gate verification)

- [x] **1.2** Append one sentence to README's update recipe (after the "Redeploy contract:" paragraph, ~README:387): "`--select` deploys add only and never auto-prune; converge manually with `update --prune` (see #610)."
    — **Why:** relay decision (Mode R): the `--select` exclusion is deliberate but must carry a documented manual path where `--select` users actually read — the canonical install/update recipe, not a closing ticket comment
    — **Done when:** the sentence is present in README's update recipe block and `grep -c "never auto-prune" README.md` returns 1
    — **Consumers affected:** `--select` deploy users (documentation only); no runtime consumers
    — **Done:** README:387 Redeploy-contract paragraph extended with the `--select` never-auto-prune sentence (#610 pointer) plus a truthful clause that full/`--skills-only` redeploys now prune; files: README.md; fixes: none

### Phase 2: Regression net

- [x] **2.1** Add `update --prune converges deployed agents to the registry` to `tests/deploy_delegate.bats`: full `add --all --yes` into temp HOME, plant a fake registry-removed agent (file + manifest `entries`/`agents` rows for `office-document-primary-agent`), run `update --prune`, assert the planted file and manifest rows are gone while a real agent (e.g. `code-review-subagent`) survives
    — **Why:** the delegation regression net must prove the prune arm's mechanics — this is the exact machine state from the ticket
    — **Done when:** the new bats test passes on the fixed tree and fails if `init.mjs`'s prune arm breaks (mechanics guard; the wiring itself is guarded by 2.2's source-level anchor)
    — **Consumers affected:** dev/CI regression coverage; no runtime consumers
    — **Done:** test added — full `add --all` into temp HOME, planted `office-document-primary-agent` (file + manifest rows), `update --prune` removes both, `code-review-subagent` survives, wiring grep embedded; files: tests/deploy_delegate.bats; fixes: none (draft from the overreaching review delegate, verified + adopted)

- [x] **2.2** Add a wiring pin to `tests/test_dry_run_leaks.bats`: anchor the invocation site in `deploy/setup.sh` — `grep -F 'init.mjs" update --prune'` matches, and that line carries `$dry_arg` (fed by the existing pinned explicit-comparison spelling) — mirroring the `setup_sh_models_only_passes_dry_run_to_manifest_update` pin style
    — **Why:** dependency-level tests (2.1) prove mechanics, not wiring — removing the prune call from `deploy_content()` would keep 2.1 green, so the wiring needs a source-level anchor (review finding); the #467 leak class must stay pinned at the wiring site
    — **Done when:** the pin test passes (anchor line found, `$dry_arg` on it) and `grep -Fc '${DRY_RUN:+--dry-run}' deploy/setup.sh` still finds zero occurrences
    — **Consumers affected:** dev/CI regression coverage; no runtime consumers
    — **Done:** pin added — anchors the literal `init.mjs" update --prune $provider_arg $dry_arg` invocation site and asserts zero banned `${DRY_RUN:+--dry-run}` spellings; files: tests/test_dry_run_leaks.bats; fixes: none

### Phase 3: Gate + validation

- [x] **3.1** Run the gate: `bash -n deploy/setup.sh`, then `bats tests/deploy_delegate.bats tests/test_dry_run_leaks.bats tests/init.bats tests/update.bats tests/test_skills_only_parity.bats tests/test_default_behavior.bats tests/test_subcommands.bats` (every suite that sources or pins `deploy_content()`); fix any failure before push
    — **Why:** the touched function sits on the deploy path with existing structure/spelling pins — the pinned suites are the blast-radius proof
    — **Done when:** all listed bats suites green and `bash -n` clean on the final tree
    — **Consumers affected:** none runtime — evidence for the exit gate
    — **Done:** `bash -n` clean; full-tier exit gate ran the ENTIRE bats suite (632 tests, 0 failures) plus the PLAN-listed suites; files: none; fixes: none

## Technical Notes

- Prune semantics come from `installer/init.mjs` `cmdUpdate` (init.mjs:1496-1511): only manifest entries whose names are absent from `installer/registry.json` are pruned, across their recorded targets — user-hand-added agents outside the manifest are never touched.
- `--select` deploys (`deploy_selected_group`) and `--models-only` (`update_manifest`) are deliberately left un-pruned: curated installs and the model-resolution mode are out of the ticket's AC. Relay decision (Mode R): the `--select` exclusion stays with a documented manual path — `node installer/init.mjs update --prune` from a clone / `npx … update --prune` (README step 1.2) — because wiring `update --prune` into a curated deploy would also re-copy every changed manifest entry (`cmdUpdate` contract, init.mjs:1450-1513); `--select` convergence + signal is follow-up **#610**.
- The two exemplar files (`office-document-primary-agent.md`, `startup-founder-primary-agent.md`, removed in #280) are pruned by the machinery with no special-casing — no one-off rm in repo code.

## Dependencies

None. (`init.mjs update --prune` already shipped and tested at `tests/update.bats`.)

## Risks & Mitigations

- **Risk:** prune pass slows deploys (`update` re-hashes all entries). **Mitigation:** bounded by the manifest size, single extra pass, and it prints a one-line summary; acceptable for a deploy script.
- **Risk:** a user's locally-renamed agent that shadowed a registry name gets pruned on redeploy. **Mitigation:** that is the documented convergence semantics (manifest = system of record, #379); the backup snapshot in `deploy_content()` (`content-backup`) already preserves pre-overwrite state.
## Trace

GATE 31c4830 tier=light lint=t typecheck=n.a build=n.a unit=t e2e=n.a
GATE 75126e2 tier=light lint=t typecheck=n.a build=n.a unit=t e2e=n.a
GATE b9eb7c9 tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a (bats 632/632 — ticket exit gate)
GATE a8566da tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a (bats 632/632 — review-fix re-gate)
