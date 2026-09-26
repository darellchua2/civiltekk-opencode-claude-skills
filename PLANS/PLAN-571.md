# PLAN: --help UX fixes + setup.ps1 flag parity with setup.sh

**Branch**: feat/571
**Issue:** https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/571
**Base**: main

## Acceptance Criteria

- [ ] `./deploy/setup.sh --help` footer points to `https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues`
- [ ] `node installer/init.mjs -h` prints the same help as `--help`
- [ ] `printHelp` output contains copy-pasteable `npx github:darellchua2/civiltekk-opencode-claude-skills ...` example lines
- [ ] `deploy/setup.ps1 -Help` prints setup.sh help without requiring node ≥ 26.4
- [ ] Every flag setup.sh parses has a setup.ps1 parameter mapping (accepted no-ops still forward, matching setup.sh's behavior of printing the removal notice)
- [ ] `.\setup.ps1 rollback latest` forwards `--rollback latest` (no silent menu fallback); all 7 subcommands forward correctly
- [ ] Existing test suite passes (bats tests/, including any setup.sh/ps1-related guards)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` (show_help heredoc lines ~804 + markitdown bump-ritual comment ~line 2590) | — | `deploy/setup.ps1` (forwards `--help`/`-h` into show_help); end users reading help; `tests/test_setup_ps1_vars.bats` greps (DRY_RUN_PREVIEW_DIR, `--preview-dir`, markitdown-pin presence — all untouched by this change) | low |
| `deploy/setup.ps1` (param block + `$forward` translation + `$args` forwarding + help path) | setup.sh at b483687 accepting every forwarded flag/subcommand | Windows end users; `tests/test_setup_ps1_vars.bats` (undefined-variable audit: every `$Var` read must be param/assigned/auto; no `markitdown-mcp==` literal; no `config-src`) | medium — a mistranslated flag silently changes deploy behavior |
| `installer/init.mjs` (SHORT_FLAGS map + printHelp body) | — | npx end users; setup.sh call sites `deploy_content`/`update_manifest` (invoke `init.mjs add/update` — flag surface unchanged there); `tests/init.bats`, `tests/update.bats` | low |
| `tests/test_help_parity.bats` (new) | Phases 1–3 landed | CI gate; future regressions | low |

## Implementation Phases

### Phase 1: setup.sh help corrections

- [ ] **1.1** Point the `show_help` "Report issues" footer at `https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues` (replacing `anomalyco/opencode`)
    — **Why:** the current URL misroutes this repo's bug reports to the upstream project's tracker.
    — **Done when:** `./deploy/setup.sh --help` output contains the darellchua2 issues URL and zero `anomalyco` references.
    — **Consumers affected:** end users reading help; `deploy/setup.ps1 -Help` (forwards into this output).

- [ ] **1.2** Fix the stale markitdown bump-ritual comment: drop `deploy/setup.ps1` from the "bump all three together" list (the ps1 carries no pin since #474; only `deploy/setup.sh` and `opencode_app/Dockerfile` do)
    — **Why:** the comment instructs writing the pin into the ps1, which `tests/test_setup_ps1_vars.bats:setup_ps1_delegates_the_487_pinned_install_to_bash` explicitly forbids — following the comment as written would break CI.
    — **Done when:** the comment names exactly the two files that still carry the pin; the bats pin stays green.
    — **Consumers affected:** maintainers bumping the markitdown pin.

### Phase 2: installer/init.mjs help UX

- [ ] **2.1** Add `"-h": "help"` to the `SHORT_FLAGS` map (`installer/init.mjs:115`)
    — **Why:** `-h` is the universal help convention (setup.sh supports it); it currently falls through to `rest` and silently does nothing.
    — **Done when:** `node installer/init.mjs -h` prints the help and exits 0, identical to `--help`.
    — **Consumers affected:** CLI users; the value-eat guard consuming SHORT_FLAGS inherits the new alias automatically.

- [ ] **2.2** Add an EXAMPLES section to `printHelp()` with npx-prefixed, copy-paste-ready commands (list categories, add one skill, dry-run an add with deps, project scope, claude target)
    — **Why:** every USAGE line is prefixed `opencode-skill` — a bin name that only exists mid-npx-invocation, so npx users cannot copy-paste any line as-is (the gap that motivated #571).
    — **Done when:** help output contains ≥4 `npx github:darellchua2/civiltekk-opencode-claude-skills ...` example lines exercising add/--dry-run/--project/--target/--list.
    — **Consumers affected:** npx end users; no code path parses the help body.

### Phase 3: setup.ps1 flag parity

- [ ] **3.1** Add the 14 missing parameters to the param block with their `$forward` translations: `Help, Verbose, CheckUpdate, Peonping, KeepBackups (string), NoZipBackup, Mix, EnableLocalLlm, EnableVllm, LocalLlm, Vllm, EnableAutoUpdate, DisableAutoUpdate, ScheduleUpdate (string)` → `--help, --verbose, --check-update, --peonping, --keep-backups <N>, --no-zip-backup, --mix, --enable-local-llm, --enable-vllm, --local-llm, --vllm, --enable-auto-update, --disable-auto-update, --schedule-update <schedule>`
    — **Why:** these flags currently fail parameter binding ("A parameter cannot be found") — 14 of setup.sh's accepted flags are unusable from Windows.
    — **Done when:** every flag arm in setup.sh's `parse_arguments` has a corresponding ps1 parameter or documented subcommand/positional path (checklist verified in review); value-flags validate their argument the same way setup.sh does (KeepBackups numeric check matches setup.sh's `^-?[0-9]+$` gate).
    — **Consumers affected:** Windows end users; the undefined-variable audit (new params are read only inside `if ($X)` guards → audit-clean).

- [ ] **3.2** Forward positional args (`$args`) verbatim after the translated flags so all 7 subcommands (`install|update|rollback|peonping|llm|plan|check-catalog`) reach setup.sh's own subcommand parser
    — **Why:** positionals currently vanish (param() without ValueFromRemainingArgs drops them), so `.\setup.ps1 rollback latest` silently runs the interactive-menu default instead of rolling back — wrong-mode execution with no error. setup.sh already parses its own subcommand tokens, so verbatim forwarding gives full parity with zero translation table.
    — **Done when:** `$forward` receives `$args` (statically pinned by bats grep; no pwsh on this host — runtime proof is INCONCLUSIVE locally and rides CI).
    — **Consumers affected:** Windows end users running subcommand forms.

- [ ] **3.3** Handle `-Help` before the node ≥ 26.4 bootstrap gate: move the bash-host discovery ahead of the node check, forward `--help` and exit immediately when `$Help` is set
    — **Why:** printing help requires bash only; today the bootstrap would refuse to run help on machines without node ≥ 26.4, defeating the purpose of a help flag (AC: help without node).
    — **Done when:** in file order, the `$Help` forward precedes the node version gate (pinned by a bats line-order assertion); the ps1 still fails fast on missing bash.
    — **Consumers affected:** Windows end users on node-less or old-node machines.

### Phase 4: verification

- [ ] **4.1** Add `tests/test_help_parity.bats` pinning the new surface: setup.sh issues URL (and no anomalyco in show_help), `-h` in SHORT_FLAGS, npx example lines in printHelp, `$args` forwarding in the ps1, `$Help` forward preceding the node gate, and one representative new-switch translation
    — **Why:** non-trivial new logic leaves one runnable check behind; the repo's established style for launcher/CLI pins is grep-based bats (see test_setup_ps1_vars.bats), and CI (no local pwsh/bats guarantee) enforces it on every PR.
    — **Done when:** the new bats file passes locally when bats is available; each assertion greps the exact string the phases introduced.
    — **Consumers affected:** CI gate; future regressions.

- [ ] **4.2** Run the verification gate: `bash -n deploy/setup.sh`, `node --check installer/init.mjs`, `node installer/init.mjs -h` probe, full `bats tests/` if bats is installed; record INCONCLUSIVE for ps1 runtime (no pwsh on host) and for any unavailable tool, per verification-loop-skill
    — **Why:** the ticket exit gate must be full-tier with an honest memo; ps1 runtime coverage rides CI (the PR watcher treats red CI as a failure).
    — **Done when:** a `GATE <sha> tier=full` memo line exists in the PLAN trace with per-gate outcomes and explicit INCONCLUSIVE notes where applicable.
    — **Consumers affected:** Step 9 code review and the Step 10a PR citation.

## Technical Notes

- setup.ps1 targets PowerShell 5.1+ (per test_setup_ps1_vars.bats:74 comment) — no `[CmdletBinding()]`, so `[switch]$Verbose` is legal (common-parameter names are only reserved in advanced scripts). Do not add CmdletBinding.
- The undefined-variable audit strips comments, then requires every `$Var` read to be a param, assigned, or auto-whitelisted (`args`, `LASTEXITCODE`, …). New locals must be assigned before first read.
- README.md/CHANGELOG.md `anomalyco/opencode#NNN` references are legitimate upstream cross-references — out of scope.
- `SHORT_FLAGS` doc comment at installer/init.mjs:112-114 says "a fourth short updates one place" — adding `-h` exercises exactly that property.

## Dependencies

None — self-contained; no blocked-by tickets (#564/#563 touch different surfaces).

## Risks & Mitigation

- **Mistranslated flag silently changes a deploy** (medium): mitigation — 3.1 Done-when requires a full side-by-side checklist of setup.sh parse arms vs ps1 params; bats pins one representative translation; Step 9 code review re-verifies the table.
- **`$args` forwarding swallows a typo'd positional** (low): identical behavior to bash side (setup.sh's `*` arm errors on unknown options; unknown positionals were already dropped before — forwarding strictly narrows the divergence).
- **No local pwsh/bats** (low): static bats greps + CI carry it; INCONCLUSIVE recorded in the gate memo rather than silently claimed.
