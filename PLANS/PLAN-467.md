# PLAN: dry-run mutates real files — learnings _index.md, .env, models-only manifest update

**Branch**: feat/467
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/467
**Base**: main

## Acceptance Criteria
- [ ] `setup_learnings_dir` (setup.sh:3524): the `_index.md` heredoc write is DRY_RUN-gated — dry-run prints a would-do line and writes nothing (the surrounding mkdir/touch already go through run_cmd)
- [ ] `setup_local_llm_env` (setup.sh:2921): the `.env`-from-example `cp` goes through run_cmd, and the `set_env_var` helper (sed -i / append) logs "[DRY-RUN] Would set KEY=VALUE" and returns without writing under DRY_RUN — `.env` bytes unchanged after a dry-run call
- [ ] `--models-only` (setup.sh:4208): the `init.mjs update` call passes `--dry-run` when DRY_RUN (cmdUpdate honors it: writes AND prune are `!dry`-gated, init.mjs:1202/1239)
- [ ] setup.ps1 `ModelsOnly` (:2911): `$updateArgs` gains `--dry-run` under `$DryRun` (mirroring the add path at :2324)
- [ ] ps1 learnings block already dry-gated — verified, no change (its unconditional "Created _index.md template" log in dry-run is cosmetic and left as-is)
- [ ] New tests/test_dry_run_leaks.bats: functional pins for learnings + .env (unchanged under DRY_RUN=true, CHANGED under DRY_RUN=false as positive control, sandboxed REPO_DIR/LEARNINGS_DIR) + source pins for both scripts' models-only `--dry-run` pass-through
- [ ] Full gate green; no behavior change outside dry-run

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` three sites | — | dry-run users (cron/CI previews); real-run path byte-identical | low |
| `deploy/setup.ps1` ModelsOnly | — | Windows dry-run users | low |
| `installer/init.mjs` | — (unchanged; `--dry-run` is a shipped, honored flag) | both scripts | none |
| `tests/test_dry_run_leaks.bats` (new) | the two setup.sh edits | CI bats job | low |

## Implementation Phases

### Phase 1: gate the three bash leaks + the ps1 twin
- [ ] **1.1** setup.sh:3524 — wrap the `_index.md` heredoc in `if [ "$DRY_RUN" = true ]`, logging "[DRY-RUN] Would create _index.md template"; keep the success log only on the real path
    — **Why:** The bare `cat >` bypasses run_cmd and creates a real file in a dry run — the only real write in an otherwise dry-safe function.
    — **Done when:** with DRY_RUN=true and an empty LEARNINGS_DIR, no `_index.md` exists after the call; with DRY_RUN=false it is created.
    — **Consumers affected:** dry-run users only; real runs unchanged.
- [ ] **1.2** setup.sh:2921 — route the `.env` creation `cp` through run_cmd; add a DRY_RUN early-return (with "[DRY-RUN] Would set KEY=VALUE" log) at the top of `set_env_var`
    — **Why:** Both write paths (sed -i in place; `>>` append) bypass run_cmd and mutate the user's real repo `.env` during a preview.
    — **Done when:** with DRY_RUN=true and a prepared `.env`, its bytes are identical after the call; with DRY_RUN=false the values change (positive control); a missing `.env` under dry-run still takes the "not found" warn branch without creating anything.
    — **Consumers affected:** `--enable-local-llm` dry-run users only.
- [ ] **1.3** setup.sh:4208 — append `${DRY_RUN:+--dry-run}` to the `init.mjs update` invocation; ps1:2912 — add `if ($DryRun) { $updateArgs += "--dry-run" }` after the provider append
    — **Why:** The resolver in the same block respects --dry-run but the very next line re-applied manifest changes for real — the models-only preview was half-preview.
    — **Done when:** both source sites conditionally pass `--dry-run` (pinned in 2.1); `cmdUpdate`'s `!dry` gates (init.mjs:1202, :1239) make the flag sufficient — no init.mjs change.
    — **Consumers affected:** `--models-only --dry-run` users on both platforms.
- [ ] **1.4** Verify no other bare writes in the dry-run path: grep setup.sh for `cat >`, `sed -i`, `>> "` outside run_cmd within functions reachable in dry-run, and confirm each remaining hit is already DRY_RUN-gated or outside deploy flow
    — **Why:** The ticket names three sites; this audit ensures no fourth instance of the same class ships unnoticed (the #468 lesson: fix the class, not the instance).
    — **Done when:** the sweep output is either empty or every remaining site carries a same-function DRY_RUN guard (documented in the PLAN Done line).
    — **Consumers affected:** none (audit only).

### Phase 2: leak pins + full gate
- [ ] **2.1** New tests/test_dry_run_leaks.bats: (a) learnings — source with sandboxed LEARNINGS_DIR; DRY_RUN=true call → no _index.md; DRY_RUN=false call → exists (positive control); (b) .env — sandboxed REPO_DIR with a seeded .env; DRY_RUN=true setup_local_llm_env → bytes identical; DRY_RUN=false → changed; (c) source pins — setup.sh models-only block contains the DRY_RUN-conditional `--dry-run` for init.mjs update; ps1 ModelsOnly contains `$updateArgs += "--dry-run"` under DryRun; POSIX-safe, no network
    — **Why:** Each leak gets a functional regression pin with a positive control (the pattern that catches both false greens and silent no-ops).
    — **Done when:** `bats tests/test_dry_run_leaks.bats` green.
    — **Consumers affected:** CI bats job.
- [ ] **2.2** Full gate: `bash -n deploy/setup.sh`, `bats tests/`, `node --test tests/*.test.ts`; diff scope = setup.sh, setup.ps1, new test file
    — **Why:** Gate contract.
    — **Done when:** all green; scope as stated.
    — **Consumers affected:** none.

## Technical Notes
- `run_cmd` no-ops under DRY_RUN (prints "[DRY-RUN] Would execute") — the established dry-safe wrapper; the leaks are precisely the writes that bypass it.
- init.mjs `--dry-run` is documented at init.mjs:22 ("print manifest, write nothing") and cmdUpdate gates both mutation classes on `!dry` — no installer change needed.
- ps1 learnings already gates writes under `-not $DryRun` (#463-era work); only bash had the bare heredoc.

## Dependencies
None — standalone. Part of epic #464.

## Risks & Mitigation
- **Vacuous CI pass** (runner env aborts before reaching a leak): mitigated by calling the functions directly with sandboxed dirs instead of driving main end-to-end — each pin is self-contained.
- **sed -i portability**: unchanged real-path behavior (GNU sed as before); dry-run never reaches sed.
