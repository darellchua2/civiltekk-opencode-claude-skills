# PLAN-491 — align models-only/migrate config base with D2 decline contract (presence-gated)

**Ticket:** #491 (exactly one ticket; its ACs are this PLAN's definition of done)
**Parent:** #464 (follow-up to #470, Mode R Gap 1)
**Branch:** feat/491 from origin/main (52795027)

## Problem

#470's D2 contract gates `--config-src` on the user's decline decision
(`SKIP_CONFIG_COPY=true` ⇒ omit ⇒ resolve-models.mjs dest-fallback patches the
existing opencode.json in place, resolve-models.mjs:283-284). `--models-only`
and `--migrate` have no decline prompt: `run_resolver` runs with
`SKIP_CONFIG_COPY=false`, so `--config-src ${SOURCE_CONFIG}` is passed
unconditionally and an existing user config is silently rebased on the stock
template (custom keys lost). Fresh-machine bootstrap legitimately needs the
stock base — the gate must be presence, not unconditional omission.

## Approach (from the ticket — Mode R conditions)

Presence-gate inside `run_resolver` (one place; all callers benefit; the
interactive path's decline decision keeps priority):

```
SKIP_CONFIG_COPY=true                                     → omit (D2, #470)
MODELS_ONLY|MIGRATE_ONLY, CONFIG_FILE exists              → omit (#491, new)
otherwise                                                 → pass --config-src
```

- resolve-models.mjs needs NO change: omitting `--config-src` with an existing
  `--config-dest` already hits its dest-fallback (in-place patch; custom keys
  survive). dest must be STRICT JSON — `stripJsonComments`
  (resolve-models.mjs:80-83) tolerates only `"$comment":` lines, so a
  `//`-commented opencode.json throws loud at readJsonMaybe (:75) BEFORE any
  write (fail-safe: no partial state).
- jsonc-sibling interaction (#432) is preserved end-to-end: presence is
  checked on `opencode.json` specifically. A user whose live config is
  `opencode.jsonc` (no `.json`) is "fresh" to the gate ⇒ stock base is written
  ⇒ `park_jsonc_sibling` (already wired after every non-dry resolver write)
  renames the sibling to `opencode.jsonc.legacy-ignored` — the run still ends
  with exactly one live config.
- AC4 (ps1 mirror): post-#474 the ps1 is a thin launcher with zero selection
  logic — the gate is mirrored by delegation, and a grep-pin enforces that no
  `--config-src` logic ever forks back into the ps1.

## Phases

### Phase 1 — presence gate in run_resolver (deploy/setup.sh)

- **1.1** Extend the `config_src_arg` decision block (setup.sh:3176-3183) with
  the models-only/migrate presence branch + an explicit `log_info` for each
  outcome. `d2_without_skip_stock_template_wins` (full path, no mode flag)
  must keep passing — the gate is mode-scoped, not global.
  — **Consumers affected:** users running `--models-only`/`--migrate` against
    — **Done:** mode-scoped presence branch added to run_resolver's config_src_arg decision (decline > presence > stock); log_info per outcome; d2_without_skip_stock_template_wins stays green; files: deploy/setup.sh; fixes: none
  an existing install keep custom config keys; fresh machines unchanged.
  **Done:** ✓
- **1.2** Bats pins in tests/test_plan_executor.bats (house home of the D2
  pins), all sandboxed to a mktemp HOME, mirroring the existing d2 test shape:
  1. `models_only_existing_config_survives_in_place_patch` — existing config
     with custom keys + `MODELS_ONLY=true; RESOLVER_CONFIG_ONLY=true;
     run_resolver` ⇒ keys survive.
  2. `models_only_fresh_bootstrap_writes_stock` — no config ⇒ opencode.json
     exists after (stock base written).
  3. `migrate_existing_config_survives_in_place_patch` — same as 1 with
     `MIGRATE_ONLY=true`.
  4. `migrate_fresh_bootstrap_writes_stock` — same as 2 with
     `MIGRATE_ONLY=true`.
  5. `models_only_jsonc_sibling_parked_exactly_one_live_config` — live
     `opencode.jsonc` + models-only ⇒ `opencode.json` written from stock and
     the sibling renamed to `opencode.jsonc.legacy-ignored` (the #432
     interaction through the presence gate).
  — **Consumers affected:** regression class "silent config rebase" is
    — **Done:** 5 pins added (models-only ×2 branches, migrate ×2 branches, jsonc-sibling parking); all green; pre-existing d2 pins unaffected; files: tests/test_plan_executor.bats; fixes: none
  mechanically pinned on both branches per mode.
  **Done:** ✓

### Phase 2 — ps1 mirror pin + docs + gate

- **2.1** tests/test_setup_ps1_vars.bats: add
  `setup_ps1_keeps_no_config_src_logic` — launcher forwards everything to
  setup.sh; `grep -q 'config-src' setup.ps1` must fail (AC4 via delegation).
  — **Consumers affected:** Windows users get the same gate with zero
    — **Done:** setup_ps1_keeps_no_config_src_logic — no 'config-src' in the launcher, forwards to setup.sh (AC4 by delegation); files: tests/test_setup_ps1_vars.bats; fixes: none
  second-implementation drift risk.
  **Done:** ✓
- **2.2** Gate: `bash -n` on setup.sh; full `bats tests/` (expect ~493 ok /
  0 fail); `node --test tests/*.test.ts` (30/0). Tick PLAN Done lines, write
  Gate Trace, commit + push.
  — **Consumers affected:** none directly; the gate is the merge precondition.
    — **Done:** bash -n ok; bats 494 ok / 0 fail (488 prior + 6 new); node --test 30 pass / 0 fail; files: PLANS/PLAN-491.md; fixes: none
  **Done:** ✓

### Phase 3 — review, PR, merge, close

- **3.1** Code review dispatch (severity-gated), fix rounds as needed.
  **Done:** ✓
- **3.2** PR (body: `Closes #491`, disclose AC4-by-delegation), CI watch
  (workflow_dispatch fallback if the pull_request event is dropped again),
  `--squash --delete-branch` on green, verify #491 closed, remove worktree.
  **Done:** ✓

## Definition of done

Ticket #491's four ACs checked; PR merged to main with green CI; #491 closed.

## Gate Trace

GATE (push head) lint=- typecheck=- build=- unit=t e2e=n.a.  (bash -n ok; bats 494 ok / 0 fail incl. 6 new #491 pins — 4 presence branches, 1 jsonc-sibling parking, 1 ps1 delegation; node --test 30 pass / 0 fail; scope = deploy/setup.sh + tests/test_plan_executor.bats + tests/test_setup_ps1_vars.bats)
