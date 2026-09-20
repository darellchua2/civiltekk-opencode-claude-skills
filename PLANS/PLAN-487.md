# PLAN: Use upstream markitdown-mcp instead of vendored wrapper

**Branch**: feat/487
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/487
**Base**: main

## Acceptance Criteria

- [ ] AC1 — `opencode_app/opencode.json` markitdown command is `["markitdown-mcp"]`; `MARKITDOWN_ENABLE_PLUGINS=false` and `disabled: true` unchanged
- [ ] AC2 — `deploy/setup.sh` installs `markitdown-mcp==0.0.1a7` + `mcp[cli]>=2.1.1,<3.0.0` (`--user`, PEP 668 retry, pip-show + import idempotency probe, best-effort uninstall of `markitdown-local-mcp`)
- [ ] AC3 — `deploy/setup.ps1` mirrors the same swap
- [ ] AC4 — `opencode_app/Dockerfile` installs from PyPI; vendored dir `opencode_app/mcp-servers/markitdown-local-mcp/` deleted
- [ ] AC5 — `--enable-pack markitdown` end-to-end: server spawns over stdio and answers an MCP `initialize` handshake
- [ ] AC6 — markitdown-mcp and docling-mcp coexist on one `mcp` 2.x (`pip check` clean for both)
- [ ] AC7 — Tests updated and green: `test_pack_permissions`, `test_setup_ps1_vars`, `test_markitdown_skill`, `test_mcp_count_consistency`
- [ ] AC8 — Docs updated: README trust-boundary note (upstream note + residual: audio inputs upload to Google Speech; YouTube URLs contact YouTube), `THIRD_PARTY_LICENSES.md` §4, `markitdown-mcp-skill` + agent prose, `CHANGELOG.md`

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Codegraph skipped (`.codegraph/` not gitignored in this repo — rg/grep fallback used)._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` (markitdown server entry, line ~796) | Phase 1 install name exists on target machines | opencode runtime on every deployed machine; `deploy/merge-packs.mjs` (pack flip); `tests/test_mcp_count_consistency.bats` | medium |
| `deploy/setup.sh` `install_local_mcp_launchers()` | PyPI package + pin decision (0.0.1a7) | users running setup / `--enable-pack markitdown`; `run_pack_merger()` call site; `tests/test_pack_permissions.bats` greps | medium |
| `deploy/setup.ps1` `Install-LocalMcpLaunchers` | same pin decision | Windows users; `Invoke-PackMerger` call site; `tests/test_pack_permissions.bats`, `tests/test_setup_ps1_vars.bats` greps | medium |
| `opencode_app/Dockerfile` (lines ~16–28) | PyPI package | `docker compose build` (opencode_app README documents image) | low |
| `opencode_app/mcp-servers/markitdown-local-mcp/` (delete) | config + both setup scripts no longer referencing it | `THIRD_PARTY_LICENSES.md` §4 and README prose (text refs only) | low |
| `deploy/packs/pack-markitdown.json` (`$comment` only) | script rename for accurate comment | `deploy/merge-packs.mjs` ignores `$comment`; `tests/test_pack_permissions.bats` merge behavior | low |
| `tests/test_pack_permissions.bats`, `tests/test_setup_ps1_vars.bats` | final script/config shape (Phases 1–2) | CI bats suite | medium |
| `opencode_app/README.md` (Docker bake section, lines ~152–163) | Dockerfile swap (2.1); vendored dir deletion (2.2) | Docker users deciding what is safe to convert; repo AGENTS.md sync rule (mandatory file for Dockerfile changes) | medium |
| repo-root `AGENTS.md` (Office Document Extraction Routing, markitdown tier-1 row) | docs phase (residual note) | every routing agent in every session (auto-injected instructions) | low |
| Docs: `README.md`, `THIRD_PARTY_LICENSES.md`, `skills/markitdown-mcp-skill/SKILL.md`, `agents/office-document-router-subagent.md`, `agents/documentation-subagent.md`, `CHANGELOG.md` | final implementation shape | end users; routing agents | low |

Cross-module consumers exist (opencode runtime, CI, deployed user machines) — architecture review selected at plan review.

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Config + installer swap (shell + PowerShell)

- [x] **1.1** Flip the markitdown server entry in `opencode_app/opencode.json` from `"command": ["markitdown-local-mcp"]` to `["markitdown-mcp"]`, leaving `type`, `environment` (`MARKITDOWN_ENABLE_PLUGINS=false`), and `disabled: true` untouched.
    — **Why:** the config is the single source of truth the deploy copies; every later step (scripts, Docker, tests) must agree on the new entry-point name or the server fails to spawn.
    — **Done when:** `grep -n 'markitdown-mcp' opencode_app/opencode.json` matches the command array, no `markitdown-local-mcp` remains in the file, and `node -e "JSON.parse(...)"` still parses it.
    — **Consumers affected:** opencode runtime (all deployed machines), merge-packs.mjs, test_mcp_count_consistency.bats.
    — **Done:** command flipped, env/disabled untouched; files: opencode_app/opencode.json; fixes: none
- [x] **1.2** Replace `install_local_mcp_launchers()` in `deploy/setup.sh` with `install_markitdown_mcp()`: idempotency probe = `pip show markitdown-mcp` AND import check `from markitdown_mcp.__main__ import main`; install command `python3 -m pip install --user "markitdown-mcp==0.0.1a7" "mcp[cli]>=2.1.1,<3.0.0"` with the existing PEP 668 `--break-system-packages` retry; best-effort `python3 -m pip uninstall -y markitdown-local-mcp` for old installs; PATH warning now names the `markitdown-mcp` entry point.
    — **Why:** PyPI is the new source; the exact pin is required because upstream publishes only alphas (plain `pip install markitdown-mcp` fails), and `mcp[cli]` restores the shared SDK 2.x that docling-mcp also needs.
    — **Done when:** `grep -c 'markitdown-local-mcp' deploy/setup.sh` returns only the intentional uninstall reference; function compiles under `bash -n`; probe text matches upstream import path.
    — **Consumers affected:** run_pack_merger call site, test_pack_permissions.bats greps, users' `~/.local/bin`.
    — **Done:** function swapped (probe/pin/co-install/PEP 668 retry/uninstall-migration); `--force-reinstall` dropped (PyPI install heals missing deps on re-run); files: deploy/setup.sh; fixes: gate assertion count corrected to 2 intentional refs (header comment + uninstall)
- [x] **1.3** Update both `install_local_mcp_launchers` call sites in `deploy/setup.sh` (`setup_config`, `run_pack_merger`) plus help/banner text lines describing markitdown ("privacy-hardened local-only" → "upstream markitdown-mcp, stdio, plugins off").
    — **Why:** a renamed function with stale call sites crashes every deploy at the config step; stale help text misdescribes the privacy posture.
    — **Done when:** `grep -n 'install_local_mcp_launchers' deploy/setup.sh` returns zero matches; help text mentions the new package.
    — **Consumers affected:** full-setup users, `--enable-pack markitdown` users, test_pack_permissions.bats hook assertions.
    — **Done:** both call sites renamed; help line 720 + summary line 4041 reworded; files: deploy/setup.sh; fixes: none
- [x] **1.4** Mirror steps 1.2–1.3 in `deploy/setup.ps1`: rename `Install-LocalMcpLaunchers` → `Install-MarkitdownMcp`, same probe/install/uninstall-old/PATH-warn shape (Windows script dir `%APPDATA%\Python\Scripts`), update `Set-Configuration` + `Invoke-PackMerger` call sites and help text.
    — **Why:** platform parity is a repo invariant (#469) — a bash-only swap breaks Windows deploys silently.
    — **Done when:** `grep -c 'Install-LocalMcpLaunchers' deploy/setup.ps1` returns zero; both call sites reference `Install-MarkitdownMcp`; parity grep `grep -n 'markitdown-local-mcp' deploy/setup.ps1` returns only the intentional uninstall-migration reference.
    — **Consumers affected:** Windows users, Invoke-PackMerger, test_pack_permissions.bats / test_setup_ps1_vars.bats greps.
    — **Done:** function + both call sites renamed, uninstall-migration added, stale "local-dir pip install" comment fixed; files: deploy/setup.ps1; fixes: none
- [x] **1.5** Update the `$comment` in `deploy/packs/pack-markitdown.json` to describe the PyPI install (behavior keys unchanged).
    — **Why:** the comment documents the install mechanism; leaving it stale misleads the next maintainer.
    — **Done when:** comment mentions `markitdown-mcp` PyPI pin; file still parses as JSON; merge keys (`disabled:false`, permissions rule) byte-identical.
    — **Consumers affected:** merge-packs.mjs (no functional change), test_pack_permissions.bats merge assertions.
    — **Done:** comment rewritten (PyPI pin, stdio, env var); merge keys untouched; files: deploy/packs/pack-markitdown.json; fixes: none

### Phase 2: Docker + vendored removal

- [x] **2.1** In `opencode_app/Dockerfile`: drop the `COPY opencode_app/mcp-servers/markitdown-local-mcp ...` line and replace the pip install of the local dir with `pip install markitdown-mcp==0.0.1a7`; update the PLAN-GIT-262 comment.
    — **Why:** the image must bake the same server the config spawns; container isolation makes the `mcp[cli]` co-install unnecessary there.
    — **Done when:** no reference to `/tmp/markitdown-local-mcp` remains; RUN layer pins the PyPI package.
    — **Consumers affected:** `docker compose build` (opencode_app/README.md).
    — **Done:** COPY dropped, RUN layer pins `markitdown-mcp==0.0.1a7`, comment rewritten with the three-file bump ritual; files: opencode_app/Dockerfile; fixes: none
- [x] **2.2** `git rm -r opencode_app/mcp-servers/markitdown-local-mcp/` after Phases 1–2 confirm zero references on **functional surfaces only** (`opencode_app/opencode.json`, non-uninstall lines of `deploy/setup.sh`/`deploy/setup.ps1`, `opencode_app/Dockerfile`, `deploy/packs/pack-markitdown.json`).
    — **Why:** the vendored source is the thing being retired; deleting it while anything still references it breaks grep-based tests and docs.
    — **Done when:** the functional-surface grep returns zero matches. (The exhaustive repo-wide zero-reference sweep is gate 5.6, after Phases 3–4 update the test and doc surfaces.)
    — **Consumers affected:** THIRD_PARTY_LICENSES.md §4 and README prose (Phase 4 rewrites them).
    — **Done:** functional-surface grep clean, 5 vendored files git-rm'd; files: opencode_app/mcp-servers/markitdown-local-mcp/; fixes: none

### Phase 3: Tests

- [x] **3.1** Update `tests/test_pack_permissions.bats`: replace `pip show markitdown-local-mcp` greps with `pip show markitdown-mcp`, scrub the line-74 merge fixture (`"command": ["markitdown-local-mcp"]` → `["markitdown-mcp"]`), re-verify the `run_pack_merger()` hook sed-range and dry-run-safety assertions against the renamed function body.
    — **Why:** these greps are the mechanical guard that setup.sh installs the launcher on enable; stale greps false-green the CI gate.
    — **Done when:** `bats tests/test_pack_permissions.bats` passes.
    — **Consumers affected:** CI.
    — **Done:** pip-show greps, line-74 fixture, install-on-enable hook name, and the LASTEXITCODE-reset assertion (test 10, found by the full-suite gate) all updated; files: tests/test_pack_permissions.bats; fixes: stale `Install-LocalMcpLaunchers` assertion at line 167 missed in the first pass
- [x] **3.2** Update `tests/test_setup_ps1_vars.bats`: replace the `Join-Path $RepoDir "opencode_app\mcp-servers\markitdown-local-mcp"` assertion with fixed-string assertions (`grep -qF`) for BOTH clauses in setup.ps1 — the `markitdown-mcp==0.0.1a7` pin AND the `mcp[cli]>=2.1.1,<3.0.0` co-install.
    — **Why:** the test pins platform parity of the launcher install; a pin-only assertion would false-green a setup.ps1 that drops `mcp[cli]`, silently breaking AC6's docling coexistence on Windows (the Linux `pip check` in 5.5 cannot catch it). `-qF` because `[` in `mcp[cli]` and the comma in the range are regex metacharacters.
    — **Done when:** `bats tests/test_setup_ps1_vars.bats` passes; both clauses asserted.
    — **Consumers affected:** CI.
    — **Done:** test replaced with `setup_ps1_installs_pinned_markitdown_mcp_with_mcp_cli` asserting both clauses via `-qF`; files: tests/test_setup_ps1_vars.bats; fixes: none
- [x] **3.3** Run the full bats suite; fix any collateral failures (e.g. `test_markitdown_skill`, `test_mcp_count_consistency` greps) without weakening assertions.
    — **Why:** AC7 requires the suite green; collateral grep drift must surface now, not in CI.
    — **Done when:** full `bats tests/` exits 0 (or only pre-existing failures documented as such).
    — **Consumers affected:** CI, verification gate memo.
    — **Done:** full 30-file per-file sweep green (29 rc=0 + test_pack_permissions after fix); collateral findings fixed: (a) dry-run leak — installer performed a real pip install under `--dry-run` (test_headless_default hang), guarded in both scripts per #467; (b) stale function-name assertion in test_pack_permissions test 10; files: deploy/setup.sh, deploy/setup.ps1, tests/test_pack_permissions.bats; fixes: dry-run guard (gate fix 1), stale assertion (gate fix 2)

### Phase 4: Documentation

- [ ] **4.1** Rewrite README.md markitdown mentions (skills table, MCP table, PLAN-GIT-262 trust-boundary note, telemetry note): upstream note stating stdio default, plugins off via env, cloud extras present-but-dormant (Azure never registers without kwargs), and the explicit residual — audio file inputs upload to Google Speech, YouTube URLs contact YouTube.
    — **Why:** the repo advertises a privacy posture; docs must state the new, honest one or the trust-boundary claim is false.
    — **Done when:** no README line claims "local-only, privacy-hardened" for markitdown; residual caveat present.
    — **Consumers affected:** end users evaluating packs; documentation-consistency tests if any grep these lines.
- [ ] **4.2** Rewrite `THIRD_PARTY_LICENSES.md` §4: drop the vendored-wrapper paragraphs, keep markitdown MIT attribution and add markitdown-mcp attribution.
    — **Why:** license inventory must match shipped code; the wrapper's MIT text describes deleted code.
    — **Done when:** no paragraph describes the in-repo wrapper; both upstream packages attributed.
    — **Consumers affected:** license compliance readers.
- [ ] **4.3** Prose pass on `skills/markitdown-mcp-skill/SKILL.md`, `agents/office-document-router-subagent.md`, `agents/documentation-subagent.md`: swap launcher/privacy wording for the upstream mechanism; keep skill names and routing intact.
    — **Why:** agents route by these docs; stale "privacy-hardened launcher" text misleads routing decisions while names must stay stable for the permission grants.
    — **Done when:** `bats tests/test_markitdown_skill.bats` passes; no doc claims the vendored launcher exists.
    — **Consumers affected:** office-document-router-subagent, documentation-subagent, pptx/xlsx specialists (skill grants unchanged).
- [ ] **4.4** Add a CHANGELOG.md entry: swap to upstream markitdown-mcp, the 0.0.1a7 pin, mcp[cli] co-install, deleted vendored dir, and the audio/YouTube residual caveat.
    — **Why:** the repo's release flow reads CHANGELOG; behavior changes must be user-visible there.
    — **Done when:** entry present under the unreleased section in Conventional-Commits style.
    — **Consumers affected:** release tooling, users reading release notes.
- [ ] **4.5** Rewrite the Docker bake section of `opencode_app/README.md` (lines ~152–163): describe the PyPI `markitdown-mcp==0.0.1a7` install, remove the link into the deleted `mcp-servers/markitdown-local-mcp/README.md`, drop the "no `markitdown[all]`, no `azure-*`, no `SpeechRecognition`, no `youtube-transcript-api` installed" claim, and restate the audio/YouTube residual.
    — **Why:** this is the Docker doc of record; the swap makes its privacy claims false and its link dead, and repo AGENTS.md lists this file as a mandatory sync target for Dockerfile changes.
    — **Done when:** no `markitdown-local-mcp` reference remains in the file; the residual caveat is present.
    — **Consumers affected:** Docker users; documentation-consistency checks.
- [ ] **4.6** Add a one-line residual note to the repo-root `AGENTS.md` Office Document Extraction Routing section: markitdown tier-1 now runs upstream `markitdown[all]` — audio file inputs upload to Google Speech and YouTube URLs contact YouTube; born-digital office docs remain local.
    — **Why:** AGENTS.md is the declared single source of truth for routing and currently markets tier-1 markitdown as "no cloud"; agents relying on that claim would feed it audio/YouTube inputs unknowingly.
    — **Done when:** the routing section carries the residual note; no absolute "local-only/no cloud" claim remains for markitdown.
    — **Consumers affected:** every routing agent (auto-injected instructions).

### Phase 5: Verification gates

- [ ] **5.1** Syntax gates: `bash -n deploy/setup.sh`; PowerShell parse of `deploy/setup.ps1` (pwsh if available; if absent on this machine, record INCONCLUSIVE with the bats grep-parity assertions as the compensating signal per verification-loop-skill).
    — **Why:** a syntax error in either deploy script bricks setup for every user; this is the cheapest possible catch.
    — **Done when:** `bash -n` exits 0; PS gate passes or INCONCLUSIVE is recorded with compensating evidence.
    — **Consumers affected:** all setup users.
- [ ] **5.2** JSON validity: `node -e` parse of `opencode_app/opencode.json` and `deploy/packs/pack-markitdown.json`; assert the markitdown entry has the new command, env, and `disabled: true`.
    — **Why:** JSONC-comment regressions (#learned) and key drift break CI and the runtime; the parse is the mechanical check.
    — **Done when:** both files parse; assertion script exits 0.
    — **Consumers affected:** merge-packs.mjs, opencode runtime, CI.
- [ ] **5.3** Re-run full bats suite after all edits land (Phases 1–4 complete).
    — **Why:** the gate must observe the final state, not an intermediate one.
    — **Done when:** `bats tests/` exits 0 or documented pre-existing failures only.
    — **Consumers affected:** CI gate memo.
- [ ] **5.4** Dry-run smoke: `./deploy/setup.sh --dry-run --enable-pack markitdown` previews without leaking writes (no real pip/config mutations).
    — **Why:** the dry-run contract (#467) must survive the installer rewrite — a leak mutates user machines during a preview.
    — **Done when:** command exits 0; `[DRY-RUN]` markers present; no `markitdown-mcp` installed as a side effect (pip show stays negative if it was negative before).
    — **Consumers affected:** CI dry-run assertions, users previewing deploys.
- [ ] **5.5** Live smoke on this machine: run the new install path, then the stdio handshake probe (JSON-RPC `initialize` over stdin) against `markitdown-mcp`; confirm `pip check` reports no conflicts for markitdown-mcp or docling-mcp.
    — **Why:** AC5/AC6 are end-to-end claims — spawn + handshake + coexistence can only be proven by running the real server.
    — **Done when:** handshake returns a JSON-RPC result with serverInfo; `pip check` clean for both packages.
    — **Consumers affected:** this machine's broken markitdown + docling installs (repaired as a side effect).
- [ ] **5.6** Exhaustive zero-reference sweep: `grep -rn 'markitdown-local-mcp' .` in the worktree returns only the allowlisted references — setup-script uninstall-migration lines and historical CHANGELOG entries.
    — **Why:** the repo-wide gate can only pass after Phases 3–4 update the test and doc surfaces; running it here (not at 2.2) keeps every phase's gate satisfiable at its own position.
    — **Done when:** grep output contains no functional or stale-doc reference outside the allowlist.
    — **Consumers affected:** CI grep guards; future maintainers grepping for the old name.

## Technical Notes

- `markitdown-mcp` has **no stable release** — all versions are alphas (`0.0.1a1`–`0.0.1a7`, latest 2026-09-14). Plain `pip install markitdown-mcp` fails ("no matching distribution"); an exact pre-release pin (`==0.0.1a7`) installs without `--pre` and avoids enabling pre-release candidates for transitive deps.
- Co-install ranges: upstream `markitdown-mcp==0.0.1a7` requires `mcp>=2.1.1,<3.0.0`; installed `docling-mcp 3.2.0` requires `mcp[cli]>=2.0.0,<3.0.0`. Compatible — one shared SDK 2.x. The old conflict existed only because the vendored wrapper pinned `mcp<2.0`.
- stdio is upstream's default transport (no args); `--http` is opt-in and never passed. `MARKITDOWN_ENABLE_PLUGINS=false` is upstream's default too — kept in config as belt-and-suspenders.
- Accepted residual (documented, not fixed): audio file inputs upload to Google Speech (`recognizers/recognize_google`), YouTube URLs contact YouTube. Azure converters never register (kwargs-gated).
- bats greps are case-sensitive and quote-shape-sensitive — update both test files in the same phase as the scripts they assert (guard-regex quote-shape mismatch anti-pattern).
- Version bump ritual: `==0.0.1a7` appears in `deploy/setup.sh`, `deploy/setup.ps1`, `opencode_app/Dockerfile` — bump all three together.

## Dependencies

None external beyond PyPI reachability. No `blocked-by:` tickets.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| pwsh absent on the Linux CI/dev box → PowerShell parse gate inconclusive | bats grep-parity assertions on setup.ps1 carry the signal; record INCONCLUSIVE per verification-loop-skill semantics |
| 0.0.1a8+ alpha changes dependency floors silently | exact pin; bump ritual documented in Technical Notes; pin policy forces conscious re-audit |
| Doc test drift (README/tests asserting the old privacy posture) | Phase 4 rewrites docs in the same PR; full bats run in Phase 5 catches stragglers |
| pip user-site drift re-breaks the shared `mcp` later | import-probe idempotency reinstalls on detection; `pip check` step proves current coexistence |
| Vendored dir deletion orphaning references | 2.2 runs only after grep confirms zero functional references; Phase 4 rewrites the textual ones |
