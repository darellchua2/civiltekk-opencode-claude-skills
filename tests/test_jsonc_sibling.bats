#!/usr/bin/env bats
# Issue #432: a coexisting opencode.jsonc sibling has undefined precedence vs
# opencode.json (OpenCode v2 docs define no .json/.jsonc tie-break per
# directory). Both deploy scripts must park it as *.legacy-ignored at TWO
# sites (pre-prompt coexistence + after a successful config copy), guarded on
# BOTH files present (a jsonc-only machine keeps its sole live config), and
# the mutation must be dry-run-safe (run_cmd mv / -not $DryRun).

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SETUP_SH="${REPO}/deploy/setup.sh"
SETUP_PS1="${REPO}/deploy/setup.ps1"

@test "setup.sh parks opencode.jsonc at both sites in deploy order" {
  park1=$(grep -n 'run_cmd mv "${CONFIG_DIR}/opencode\.jsonc"' "$SETUP_SH" | head -1 | cut -d: -f1)
  prompt=$(grep -n 'opencode.json already exists at' "$SETUP_SH" | head -1 | cut -d: -f1)
  copy=$(grep -n 'run_cmd cp "$SOURCE_CONFIG" "$CONFIG_FILE"' "$SETUP_SH" | head -1 | cut -d: -f1)
  park2=$(grep -n 'run_cmd mv "${CONFIG_DIR}/opencode\.jsonc"' "$SETUP_SH" | tail -1 | cut -d: -f1)
  [ -n "$park1" ] && [ -n "$prompt" ] && [ -n "$copy" ] && [ -n "$park2" ]
  [ "$park1" -lt "$prompt" ] && [ "$prompt" -lt "$copy" ] && [ "$copy" -lt "$park2" ]
}

@test "setup.sh jsonc park guards on both configs and is dry-run-safe" {
  # both-exist guard (never park a jsonc-only machine's sole live config)
  [ "$(grep -c '\[ -f "\$CONFIG_FILE" \] && \[ -f "\${CONFIG_DIR}/opencode\.jsonc" \]' "$SETUP_SH")" -eq 2 ]
  # mutation routes through run_cmd (honors --dry-run)
  [ "$(grep -c 'run_cmd mv "${CONFIG_DIR}/opencode\.jsonc"' "$SETUP_SH")" -eq 2 ]
  # negative pin: no bare mv of the jsonc anywhere
  ! grep -qE '^[[:space:]]*mv "\$\{CONFIG_DIR\}/opencode\.jsonc' "$SETUP_SH"
}

@test "setup.ps1 mirrors both opencode.jsonc parks with guard and DryRun wrap" {
  park1=$(grep -n 'Move-Item \$JsoncConfigFile "\$JsoncConfigFile\.legacy-ignored"' "$SETUP_PS1" | head -1 | cut -d: -f1)
  prompt=$(grep -n 'if (Test-Path \$ConfigFile) {' "$SETUP_PS1" | head -1 | cut -d: -f1)
  copy=$(grep -n 'Copy-Item \$configSrc \$ConfigFile' "$SETUP_PS1" | head -1 | cut -d: -f1)
  park2=$(grep -n 'Move-Item \$JsoncConfigFile "\$JsoncConfigFile\.legacy-ignored"' "$SETUP_PS1" | tail -1 | cut -d: -f1)
  [ -n "$park1" ] && [ -n "$prompt" ] && [ -n "$copy" ] && [ -n "$park2" ]
  [ "$park1" -lt "$prompt" ] && [ "$prompt" -lt "$copy" ] && [ "$copy" -lt "$park2" ]
  # both-exist guard (never park a jsonc-only machine's sole live config)
  [ "$(grep -c '(Test-Path \$ConfigFile) -and (Test-Path \$JsoncConfigFile)' "$SETUP_PS1")" -eq 2 ]
  # dry-run-safe: mutation inside the DryRun guard, never at statement start
  [ "$(grep -c 'if (-not \$DryRun) { Move-Item \$JsoncConfigFile' "$SETUP_PS1")" -eq 2 ]
  [ "$(grep -c 'Write-LogWarn "Stale opencode.jsonc' "$SETUP_PS1")" -eq 2 ]
  ! grep -qE '^[[:space:]]*Move-Item \$JsoncConfigFile' "$SETUP_PS1"
}
