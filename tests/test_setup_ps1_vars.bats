#!/usr/bin/env bats

# StrictMode undefined-variable guard for deploy/setup.ps1 (issue #465).
# setup.ps1 runs under Set-StrictMode -Version Latest but no pwsh exists on
# Linux CI, so these are STATIC pins: every variable read in code must be
# either assigned somewhere in the file or bound by a param() block.
# Regression: $AppDir (rename leftover) and $DryRunPreviewDir (never defined,
# and the resolver was never told --preview-dir so dry-run staged nothing).

SETUP_PS1="deploy/setup.ps1"

# =============================================================================
# The two #465 instances, pinned as literals
# =============================================================================

@test "setup_ps1_defines_dry_run_preview_dir_at_script_scope" {
  count=$(grep -cE '^\$DryRunPreviewDir = Join-Path \$ConfigDir "\.dry-run-preview"$' "$SETUP_PS1")
  [ "$count" -eq 1 ]
}

@test "setup_ps1_has_no_appdir_reference" {
  ! grep -q 'Join-Path \$AppDir' "$SETUP_PS1"
}

@test "setup_ps1_launcher_dir_derived_from_repo_dir" {
  grep -qE 'Join-Path \$RepoDir "opencode_app\\mcp-servers\\markitdown-local-mcp"' "$SETUP_PS1"
}

@test "setup_ps1_resolver_dry_run_passes_preview_dir" {
  # resolve-models.mjs writes NOTHING on bare --dry-run; the pack merger and
  # skill profile read the staged preview, so --preview-dir must be passed.
  grep -q -- '--preview-dir' "$SETUP_PS1"
  grep -q 'resolverArgs += @("--dry-run", "--preview-dir"' "$SETUP_PS1"
  # The stale-preview clear is a separate clause of the same fix — pin it too
  # (bash: rm -rf "$DRY_RUN_PREVIEW_DIR" before staging, setup.sh:3008).
  grep -q 'Remove-Item \$DryRunPreviewDir -Recurse -Force' "$SETUP_PS1"
}

# =============================================================================
# Class-level guard: zero undefined-variable reads in the whole file
# =============================================================================

@test "setup_ps1_has_zero_undefined_variable_reads" {
  command -v python3 >/dev/null || skip "python3 not available"
  python3 - "$SETUP_PS1" <<'PYEOF'
import re, sys
src = open(sys.argv[1]).read()
# Strip comments first: prose may legitimately mention $Var names.
src = re.sub(r'<#[\s\S]*?#>', '', src)
src = re.sub(r'(?m)#.*$', '', src)
param_vars = set()
for m in re.finditer(r'param\s*\(', src):
    i, depth = m.end(), 1
    while depth and i < len(src):
        if src[i] == '(': depth += 1
        elif src[i] == ')': depth -= 1
        i += 1
    param_vars |= set(re.findall(r'\$([A-Za-z][A-Za-z0-9_]*)', src[m.end():i]))
assigned = set(re.findall(r'\$([A-Za-z][A-Za-z0-9_]*)\s*(?:=[^=]|\+=)', src))
assigned |= set(re.findall(r'foreach\s*\(\s*\$([A-Za-z][A-Za-z0-9_]*)\s+in', src))
all_vars = set(re.findall(r'\$([A-Za-z][A-Za-z0-9_]*)', src))
auto = {'true','false','null','args','_','LASTEXITCODE','Matches','Error',
        'MyInvocation','PSItem','env','global','script','host','Input',
        'ErrorActionPreference','InformationPreference','VerbosePreference',
        'WarningPreference','ErrorAction','ProgressPreference','HOME',
        'PROFILE','PSScriptRoot','PSVersionTable'}
# Deliberately NOT whitelisted: $IsWindows/$IsLinux/$IsMacOS — automatic only
# in PowerShell Core. setup.ps1 targets 5.1+ (:27), where they are undefined
# under StrictMode, so a future `if ($IsWindows)` must FAIL this audit.
undefined = sorted(all_vars - assigned - param_vars - auto)
assert not undefined, f"undefined variables in {sys.argv[1]}: {undefined}"
PYEOF
}
