# PLAN: deploy subcommands, de-bloat, ps1 thin launcher

**Branch**: feat/474
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/474
**Base**: main

## Acceptance Criteria
- [x] Positional subcommands (aliases over the existing mode flags): `install` (full), `update`, `rollback [TARGET]`, `peonping`, `llm`, `plan` (per-item picker), `check-catalog` — each documented in both help surfaces and behavior-pinned
- [x] `--list-items`: catalog dump from installer/registry.json (skills/agents ids grouped) via a single-step plan mode
- [x] `--save-preset <name>` / `--preset <name>`: user-level `~/.config/opencode/presets/<name>/` round-trip of models.json + deploy-plan.json (save = single-step plan mode; load = a first-class full/quick plan step that copies the preset into CONFIG_DIR before config deploy)
- [x] De-bloat: dead `show_progress` deleted; hand-maintained numeric claims replaced with non-numeric or generated text (skill-profile 46/105 comment, Autodesk "4 servers" example, MCP listings); auto-update subsystem demoted — `-A`/`-S` flags remain accepted but become NO-OPS printing a migration hint ("schedule updates externally, e.g. cron: `./setup.sh --update`"), `auto_update_opencode()` and its main invocation removed (decision recorded: demoted no-ops, not removal — old flags keep working per AC), `--check-update`/`-C` and `should_check_for_updates`/`update_last_check_time` STAY (the -C check mode is a #466/#470 plan mode, not part of the auto-update subsystem)
- [x] setup.ps1 → thin launcher: the ps1 body is replaced by (a) a translated parameter block accepting the historical ps1 flags and (b) a bootstrap that requires node (26+) and forwards ALL arguments to `bash deploy/setup.sh "$@"` via Git-Bash/WSL detection; NO selection logic remains in ps1 (the D2 decline gate, #471 credential UI, and picker parity are inherited from bash by delegation — resolving the #490/#491 divergences); pwsh parse-ability pinned structurally (no pwsh on CI — brace/param sanity via a node-based tokenizer check) plus behavioral pins on the forwarding contract
- [x] Old flags still work as aliases (parse_arguments unchanged apart from additions); README updated for subcommands/presets/launcher
- [x] bats (tests/test_subcommands.bats): subcommand→flag mapping, --list-items output shape, preset save/load round-trip (sandboxed), auto-update no-op + hint pins, show_progress deletion pin, generated-listing pins (no stale numeric claims), ps1 thin-launcher pins (no Set-Configuration body, forwards to setup.sh, param block present)
- [x] Full gate green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` parse_arguments + main | build_plan/run_plan (#470, landed) | all users | medium |
| ps1 → thin launcher | bash (Git-Bash/WSL) on the host | Windows users | **high** — platform behavior change, disclosed in PR + ticket comment |
| `deploy/setup.sh` de-bloat sites | — | docs/help readers | low |
| `tests/test_subcommands.bats` (new) | the above | CI | low |

Known consequence (disclosed): the ps1 launcher requires a bash host (Git-Bash or WSL) — the previous native-PowerShell duplicate is the parity-bug source this ticket removes; #491's ps1 D2 gate is absorbed by the same delegation.

## Implementation Phases

### Phase 1: subcommands + list-items + presets
- [x] **1.1** parse_arguments: positional subcommand recognition (first non-flag arg) mapping to the existing flags — `install`→full (no-op alias), `update`→UPDATE_ONLY, `rollback`→ROLLBACK_MODE (+optional target positional), `peonping`→PEONPING_ONLY, `llm`→ENABLE_LOCAL_LLM+ENABLE_VLLM, `plan`→SELECT_ITEMS, `check-catalog`→CHECK_CATALOG_ONLY; `--list-items`→LIST_ITEMS; `--save-preset <name>`→SAVE_PRESET_NAME; `--preset <name>`→LOAD_PRESET_NAME; defaults block entries for the new globals
    — **Why:** Stable subcommand spelling over the existing mode machinery — aliases, not a second parser.
    — **Done when:** each subcommand sets the expected flags (pinned 2.1); unknown positional still errors.
    — **Consumers affected:** CLI users (new spellings); existing flags untouched.
    — **Done:** 7 subcommands + --list-items/--save-preset/--preset parsed (aliases over mode flags; unknown positional still errors); validator registers --list-items/--save-preset; files: deploy/setup.sh; fixes: none
- [x] **1.2** `--list-items`: LIST_ITEMS single-step plan mode (critical `dump_catalog` step printing skills/agents ids grouped by category/tier from registry.json via node; packs + plugins names) + completion
    — **Why:** AC — machine-readable catalog for tooling.
    — **Done when:** plan membership + output-shape pin (2.1).
    — **Consumers affected:** tooling users.
    — **Done:** dump_catalog single-step plan mode (skills by category, agents by tier, packs/plugins/extras) + completion line; files: deploy/setup.sh; fixes: none
- [x] **1.3** Presets: `save_user_preset <name>` (mkdir ~/.config/opencode/presets/<name>; cp USER_MODELS_MAP + SELECT_PLAN_FILE when present; single-step plan mode SAVE_PRESET via `--save-preset`) and `load_user_preset <name>` (cp back into CONFIG_DIR; a critical first content step in full/quick when LOAD_PRESET_NAME set; unknown preset ⇒ critical failure with a clear message)
    — **Why:** AC — presets round-trip at the user level.
    — **Done when:** round-trip pin (2.1): save → wipe CONFIG_DIR/models.json → load → file restored byte-identically.
    — **Consumers affected:** users switching deployments.
    — **Done:** save_user_preset (single-step mode) + load_user_preset (critical first content step in full/quick); round-trip + unknown-preset pins green; files: deploy/setup.sh; fixes: none

### Phase 2: de-bloat
- [x] **2.1** Delete dead `show_progress` (:1866, zero callers); replace the hand-maintained numeric claims (:352 skill-profile 46/105 comment → non-numeric pointer to deploy/skill-profiles.json; :640 "all 4 Autodesk MCP servers" → "the Autodesk MCP servers"; ps1 equivalents if present); demote auto-update: `-A`/`-S`/`--enable-auto-update`/`--update-schedule` flags print the migration hint and become no-ops (flags accepted = old scripts keep working), `auto_update_opencode()` + its main call removed, help text demoted to a hint line; `-C`/`--check-update` and its helpers stay
    — **Why:** AC de-bloat list; the decision (no-op demotion over removal) is recorded here per the ticket's implementer-documents clause.
    — **Done when:** grep shows no show_progress / auto_update_opencode; `-A` prints the hint and exits 0; -C still works; bats 2.1 pins.
    — **Consumers affected:** auto-update users get a one-time migration hint instead of silent scheduled updates.
    — **Done:** show_progress deleted (zero callers); 46/105 + Autodesk-4 numeric claims non-numeric; -A/-S hinting no-ops (flags accepted); auto_update_opencode + main call removed; -C/check-update helpers retained; files: deploy/setup.sh; fixes: none
- [x] **2.2** Slim help regeneration: remove the demoted auto-update option rows, add the subcommand block + `--list-items`/`--preset`/`--save-preset` rows to both help surfaces; keep every existing row (aliases unchanged)
    — **Why:** The help is the discoverability surface for the new spellings.
    — **Done when:** help greps for subcommands pass; demoted flags show the hint row.
    — **Consumers affected:** help readers.
    — **Done:** help gains the SUBCOMMANDS block + --list-items/--save-preset/--preset rows; -A row demoted to (removed) hint; files: deploy/setup.sh; fixes: none

### Phase 3: ps1 thin launcher + pins + gate
- [x] **3.1** Replace deploy/setup.ps1's body with a thin launcher: comment header documenting the delegation decision (selection logic lives in bash; #491 D2 gate + #471 credentials + #473 picker inherited by delegation), translated param block (historical ps1 switch names → the equivalent bash args string), host detection (Git-Bash via common install paths / WSL bash), forward `bash setup.sh <mapped args>` with exit-code propagation, `-DryRun` passthrough; NO selection logic (no Set-Configuration/Deploy-Plugins/etc.)
    — **Why:** AC — one interactive implementation everywhere; the duplicated 80% was the parity-bug source (#465/#466/#469).
    — **Done when:** the ps1 contains no deploy logic functions; forwarding + param block pinned (2.1); pwsh parse can't run on CI — a node-based brace/quote balance check stands in (documented residual: full parse needs a Windows/ps1 host, noted in the PR).
    — **Consumers affected:** Windows users (must have Git-Bash/WSL — disclosed; the bootstrap errors with install guidance when neither exists).
    — **Done:** ps1 = 102-line launcher (was 3121): param block (historical flags), node >= 26.4 bootstrap, Git-Bash/WSL discovery, full flag translation, exit-code propagation; ZERO selection logic (grep-pinned); pwsh absent on CI — structural pins stand in (documented residual); files: deploy/setup.ps1; fixes: WSL branch simplified to cwd auto-translation
- [x] **3.2** Full gate: `bash -n`, `bats tests/`, `node --test tests/*.test.ts`, ps1 structural pin suite green; diff scope = setup.sh, setup.ps1, README, new test
    — **Why:** Gate contract.
    — **Done when:** all green.
    — **Consumers affected:** none.
    — **Done:** bash -n ok; bats 486 ok / 0 fail (9 subcommand pins + 6 obsolete ps1-internal pins flipped to delegation assertions); node --test 30/0; files: tests/test_subcommands.bats + 5 test files' ps1 pins; fixes: none

## Technical Notes
- Subcommands are ALIASES over mode flags — the #470 executor stays the single dispatch; no new step types beyond list-items/preset save/load.
- The auto-update demotion keeps `-A`/`-S` parse-accepted (no-op + hint) so existing scripts/aliases don't break — the AC's "kept as no-ops" option.
- ps1 launcher forwards with `& bash $bashPath deploy/setup.sh @forwardArgs` after Git-Bash discovery (standard install roots + `where.exe bash`); WSL fallback `wsl bash -c "…"`. Exit code propagates via `exit $LASTEXITCODE`.
- #491 (models-only/migrate D2 alignment) and the #474-scoped items from #490's disclosure are absorbed/documented: D2 parity arrives via delegation; the MODE_R conditions recorded on #491 remain for the follow-up.

## Dependencies
Epic #464; everything else landed (#465-#473). Final child.

## Risks & Mitigation
- **Windows launcher requires bash**: disclosed in help/README/PR; the bootstrap fails with actionable guidance (install Git-Bash or WSL) rather than misbehaving.
- **Auto-update removal surprise**: flags stay as documented no-ops with a migration hint; the -C check mode remains fully functional.
- **ps1 parse risk without pwsh**: the launcher is drastically smaller (bootstrap + forward); structural pins + a node-based balance check + optional maintainer pwsh parse noted in the PR.

## Gate Trace

GATE (fix-round head) lint=- typecheck=- build=- unit=t e2e=n.a.  (bash -n ok; bats 486 ok / 0 fail; node --test 30 pass / 0 fail; review round 1: 1 BLOCK fixed — ps1 stray-brace/duplicate tail removed; 7 WARN fixed — -Help/-SkillProfile mapped, WSL wslpath resolution, .gitattributes LF pins, preset step survives every rebuild branch + help wording, remaining numeric claims de-numbered, dead deploy_skills_only deleted with parity pins re-pointed at the live step list, -A test sandboxed; preset name/JSON guards added; scope = deploy/setup.sh + deploy/setup.ps1 + .gitattributes + README.md + tests)
