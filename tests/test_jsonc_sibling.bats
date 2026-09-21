#!/usr/bin/env bats
# Issue #432: a coexisting opencode.jsonc sibling has undefined precedence vs
# opencode.json (OpenCode v2 docs define no .json/.jsonc tie-break per
# directory). Both deploy scripts park it via a shared helper (both-exist
# guard, dry-run-safe) at THREE sites — config phase, copy branch, and after
# an apply-mode resolver run — so the script's END STATE has exactly one live
# config. Ordering pins use bare [ ] lines: bats errexit exempts non-final
# links of && chains (LEARNINGS: bats-and-chain-assertions-mask-nonfinal-links).

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SETUP_SH="${REPO}/deploy/setup.sh"
SETUP_PS1="${REPO}/deploy/setup.ps1"

@test "setup.sh parks opencode.jsonc at all three sites in deploy order" {
  park1=$(grep -nE '^[[:space:]]*park_jsonc_sibling[[:space:]]*$' "$SETUP_SH" | sed -n 1p | cut -d: -f1)
  park2=$(grep -nE '^[[:space:]]*park_jsonc_sibling[[:space:]]*$' "$SETUP_SH" | sed -n 2p | cut -d: -f1)
  park3=$(grep -nE '^[[:space:]]*park_jsonc_sibling[[:space:]]*$' "$SETUP_SH" | sed -n 3p | cut -d: -f1)
  prompt=$(grep -n 'opencode.json already exists at' "$SETUP_SH" | head -1 | cut -d: -f1)
  copy=$(grep -n 'run_cmd cp "$SOURCE_CONFIG" "$CONFIG_FILE"' "$SETUP_SH" | head -1 | cut -d: -f1)
  resolver=$(grep -n 'node "$RESOLVER_SCRIPT" \\' "$SETUP_SH" | head -1 | cut -d: -f1)
  [ -n "$park1" ]
  [ -n "$park2" ]
  [ -n "$park3" ]
  [ -n "$prompt" ]
  [ -n "$copy" ]
  [ -n "$resolver" ]
  [ "$park1" -lt "$prompt" ]
  [ "$prompt" -lt "$copy" ]
  [ "$copy" -lt "$park2" ]
  [ "$park2" -lt "$resolver" ]
  [ "$resolver" -lt "$park3" ]
}

@test "setup.sh jsonc park helper guards on both configs and is dry-run-safe" {
  # helper is the single park implementation: one guard, one run_cmd mutation
  [ "$(grep -c 'park_jsonc_sibling() {' "$SETUP_SH")" -eq 1 ]
  [ "$(grep -c '\[ -f "\$CONFIG_FILE" \] && \[ -f "\${CONFIG_DIR}/opencode\.jsonc" \]' "$SETUP_SH")" -eq 1 ]
  [ "$(grep -c 'run_cmd mv "${CONFIG_DIR}/opencode\.jsonc"' "$SETUP_SH")" -eq 1 ]
  [ "$(grep -cE '^[[:space:]]*park_jsonc_sibling[[:space:]]*$' "$SETUP_SH")" -eq 3 ]
  # post-resolver park fires only after a successful apply-mode resolver run
  grep -q '\[ "\$resolver_rc" -eq 0 \] && \[ "\$DRY_RUN" != true \]' "$SETUP_SH"
  # negative pin: no bare mv of the jsonc anywhere
  ! grep -qE '^[[:space:]]*mv "\$\{CONFIG_DIR\}/opencode\.jsonc' "$SETUP_SH"
}

@test "setup.ps1 is a thin launcher — jsonc parking is inherited from setup.sh (#474)" {
  # The native-PowerShell duplicate (and its Park-JsoncSibling helpers) was
  # the parity-bug source; #474 replaced it with a bootstrap that forwards
  # everything to setup.sh, where the parking logic lives and is pinned.
  grep -q 'setup.sh' deploy/setup.ps1
  run grep -q 'Park-JsoncSibling' deploy/setup.ps1
  [ "$status" -ne 0 ]
}
