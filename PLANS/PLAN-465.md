# PLAN: setup.ps1 undefined $AppDir/$DryRunPreviewDir (StrictMode crash)

**Branch**: feat/465
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/465
**Base**: main

## Acceptance Criteria
- [x] `$DryRunPreviewDir` defined at script scope in deploy/setup.ps1, mirroring bash `DRY_RUN_PREVIEW_DIR="${CONFIG_DIR}/.dry-run-preview"` (setup.sh:121)
- [x] Invoke-Resolver's dry-run path passes `--preview-dir $DryRunPreviewDir` and clears a stale preview dir first — parity with setup.sh:3006–3010 (currently `--dry-run` only, so the resolver stages NOTHING: resolve-models.mjs:398 "dry-run, no preview-dir: write nothing")
- [x] `$AppDir` reference eliminated: markitdown launcher dir derived from `$RepoDir` exactly as bash inlines `${SCRIPT_DIR}/../opencode_app/mcp-servers/markitdown-local-mcp` (setup.sh:2580) and as setup.ps1:135 derives `$SourceConfig`
- [x] Zero undefined-variable reads remain in setup.ps1 (paren-balanced audit: read-but-never-assigned-and-not-param = none)
- [x] New structural pin suite (tests/test_setup_ps1_vars.bats) proves all four points on Linux runners (no pwsh available — static analysis is the only executable verification here)
- [x] Full existing gate stays green (bash untouched — this PR must not modify setup.sh)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.ps1` | — | Windows users running the deploy (CI only greps it, never executes) | low |
| `installer/resolve-models.mjs` | — (unchanged; its `--preview-dir` contract already exists :396–467) | setup.sh (already passes it), setup.ps1 (starts passing it here) | none — not modified |
| `tests/test_setup_ps1_vars.bats` (new) | the three setup.ps1 edits | CI "Run bats tests" job | low |

No cross-module consumers: both edits are internal to setup.ps1; the resolver contract it starts using is already shipped and bash-proven.

## Implementation Phases

### Phase 1: Fix the two undefined variables + the resolver staging gap
- [x] **1.1** Define `$DryRunPreviewDir` at script scope directly under `$ConfigDir` (setup.ps1:96), commented as the bash-parity contract
    — **Why:** The variable is read at setup.ps1:1894 and :1940 but never defined; StrictMode -Version Latest crashes there before any dry-run preview can stage. Defining it at script scope (not inside a function) is what both read sites assume.
    — **Done when:** `grep -n 'DryRunPreviewDir = Join-Path \$ConfigDir' deploy/setup.ps1` matches exactly once, at script scope near :96.
    — **Consumers affected:** Invoke-PackMerger (:1894), Invoke-SkillProfile (:1940), Invoke-Resolver (via 1.2).
    — **Done:** defined at :100 (`Join-Path $ConfigDir ".dry-run-preview"`), bash-parity comment; grep count 1; files: deploy/setup.ps1; fixes: none
- [x] **1.2** Replace setup.ps1:1867 `if ($DryRun) { $resolverArgs += "--dry-run" }` with the bash-parity block: clear a stale `$DryRunPreviewDir` (Remove-Item -Recurse -Force, Test-Path-guarded) then append `@("--dry-run", "--preview-dir", $DryRunPreviewDir)`
    — **Why:** resolve-models.mjs:398 writes NOTHING on `--dry-run` without `--preview-dir`, so even with 1.1 fixed the pack merger/skill profile would hit their "Dry-run preview config not found" aborts (:1895–1899, :1941–1945). The stale-dir clear mirrors `rm -rf "$DRY_RUN_PREVIEW_DIR"` (setup.sh:3008) so a preview never mixes runs.
    — **Done when:** the dry-run block in Invoke-Resolver contains both `Remove-Item` on `$DryRunPreviewDir` and the `--preview-dir` argument; no other line in setup.ps1 changed in this hunk.
    — **Consumers affected:** Invoke-PackMerger, Invoke-SkillProfile (now find a staged preview), Windows dry-run users.
    — **Done:** block at :1871–1879 (Test-Path-guarded Remove-Item + `@("--dry-run","--preview-dir",...)`); files: deploy/setup.ps1; fixes: none
- [x] **1.3** Change setup.ps1:2096 to `$launcherDir = Join-Path $RepoDir "opencode_app\mcp-servers\markitdown-local-mcp"`
    — **Why:** `$AppDir` does not exist anywhere in the script (rename leftover) — StrictMode crash reachable on every non-dry-run deploy with the markitdown pack (call sites :1783, :1915). `$RepoDir`-derived is the established house pattern ($SourceConfig :135) and equals bash's inlined path (setup.sh:2580); no new global needed.
    — **Done when:** `grep -n 'Join-Path \$AppDir' deploy/setup.ps1` matches nothing; the launcher line resolves to `<repo>\opencode_app\mcp-servers\markitdown-local-mcp`.
    — **Consumers affected:** Install-LocalMcpLaunchers callers (:1783 config deploy, :1915 pack merger).
    — **Done:** launcher dir at :2110 via $RepoDir; zero `Join-Path $AppDir` matches; files: deploy/setup.ps1; fixes: none

### Phase 2: Structural pin suite + full gate
- [x] **2.1** Add tests/test_setup_ps1_vars.bats: (a) `$DryRunPreviewDir` assignment present at script scope; (b) no `Join-Path $AppDir` anywhere; (c) launcher path uses `Join-Path $RepoDir "opencode_app`; (d) Invoke-Resolver dry-run block carries `--preview-dir`; (e) paren-balanced undefined-variable audit of setup.ps1 (read-but-never-assigned-and-not-param must be empty), `command -v python3 || skip`-guarded, POSIX grep only (no ripgrep on CI runners)
    — **Why:** No pwsh exists in this environment or on CI, so a static pin is the only executable regression guard for the whole bug class, not just the two instances.
    — **Done when:** `bats tests/test_setup_ps1_vars.bats` passes 5/5 on this machine.
    — **Consumers affected:** CI bats job.
    — **Done:** 5/5 ok; audit strips block+line comments (my own comments referencing `$DRY_RUN_PREVIEW_DIR`/`$AppDir` false-positived the first run — stripping is the root-cause fix); files: tests/test_setup_ps1_vars.bats; fixes: none
- [x] **2.2** Run the full gate: `bash -n deploy/setup.sh`, `bats tests/*.bats`, `node --test tests/*.test.ts`; verify setup.sh is byte-untouched (`git diff --stat` shows only setup.ps1 + the new test)
    — **Why:** Gate contract (lint/typecheck n.a.; unit = full suites) plus the AC that bash is unmodified.
    — **Done when:** all suites green; diff stat limited to the two files.
    — **Consumers affected:** none.
    — **Done:** bash -n ok; bats 409 ok / 0 fail (404 baseline + 5 new); node --test fail 0; diff = setup.ps1 + new test + PLAN; files: —; fixes: none

## Technical Notes
- Fixed sites: setup.ps1:96 area (new var), :1867 (resolver dry-run block), :2096 (launcher dir). The comment at :1879 ("in DryRun mode the resolver stages to $DryRunPreviewDir/opencode.json") documents the intended contract — the code just never implemented it; 1.2 makes code match comment.
- bash reference behavior: setup.sh:121 (definition), :3006–3010 (rm + flags), :3062/:3291 (merger/profile preview targets — already correct in ps1 once the var exists), :2580 (launcher path).
- Audit tool: the bats-embedded python3 audit is paren-balanced (function param blocks contain `[Parameter(...)]` attributes whose inner parens break naive `[^)]*` extraction — false positives without balancing).

## Dependencies
None — standalone bug fix. No blocked-by.

## Risks & Mitigation
- **No Windows/pwsh in this environment**: the crash itself cannot be reproduced live here. Mitigation: the paren-balanced static audit is the same analysis StrictMode performs at runtime (undefined script-scope read), applied to the whole file; residual Windows live-run verification is noted in the PR body for the maintainer.
- **Regex drift breaking the pin suite**: the pins grep stable literals (variable names, flag strings); if setup.ps1 is restructured later, the audit (e) still holds as the class-level guard while (a)–(d) may need updating — acceptable, they are one file.
