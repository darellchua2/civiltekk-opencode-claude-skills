#!/usr/bin/env bats

# #571 pins: --help UX fixes + setup.ps1 ↔ setup.sh flag parity. Grep-based,
# the repo's established launcher/CLI pin style (see test_setup_ps1_vars.bats).
# CI images carry no pwsh — PowerShell runtime proof is delegated to the
# undefined-variable audit in test_setup_ps1_vars.bats plus review of the
# translation table; everything here is statically checkable.

SETUP_PS1="deploy/setup.ps1"
SETUP_SH="deploy/setup.sh"
INIT_MJS="installer/init.mjs"

# ── setup.sh help footer (#571 AC1) ──

@test "setup_sh_help_points_at_this_repo_not_upstream" {
  grep -qF 'Report issues: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues' "$SETUP_SH"
  run grep -q anomalyco "$SETUP_SH"
  [ "$status" -ne 0 ]
}

@test "setup_sh_markitdown_bump_comment_names_only_pin_carriers" {
  # The ps1 carries no pin since #474; the ritual comment must not instruct
  # writing one there (test_setup_ps1_vars.bats fails the ps1 if it appears).
  grep -qF 'deploy/setup.sh and opencode_app/Dockerfile — bump both' "$SETUP_SH"
}

# ── installer/init.mjs help UX (#571 AC2/AC3) ──

@test "init_mjs_supports_short_h_help_flag" {
  grep -qF '"-h": "help"' "$INIT_MJS"
}

@test "init_mjs_help_has_npx_copy_paste_examples" {
  grep -qF 'npx github:darellchua2/civiltekk-opencode-claude-skills --list categories' "$INIT_MJS"
  grep -qF 'npx github:darellchua2/civiltekk-opencode-claude-skills add api-design-skill' "$INIT_MJS"
  grep -qF 'npx github:darellchua2/civiltekk-opencode-claude-skills add pdf-specialist-skill --dry-run' "$INIT_MJS"
  grep -qF 'npx github:darellchua2/civiltekk-opencode-claude-skills add code-review-subagent --project .' "$INIT_MJS"
  grep -qF 'npx github:darellchua2/civiltekk-opencode-claude-skills add gsap-core --target claude' "$INIT_MJS"
}

# ── setup.ps1 parity (#571 AC4-AC6) ──

@test "setup_ps1_forwards_positional_subcommands_verbatim" {
  # Without this line `.\setup.ps1 rollback latest` fell through to the
  # interactive-menu default (positionals were silently dropped).
  grep -qF '$forward += $args' "$SETUP_PS1"
}

@test "setup_ps1_help_fast_path_precedes_node_gate" {
  local help_ln gate_ln
  help_ln=$(grep -nF 'if ($Help)' "$SETUP_PS1" | head -1 | cut -d: -f1)
  gate_ln=$(grep -nF 'required for --select' "$SETUP_PS1" | head -1 | cut -d: -f1)
  [ -n "$help_ln" ]
  [ -n "$gate_ln" ]
  [ "$help_ln" -lt "$gate_ln" ]
}

@test "setup_ps1_maps_every_setup_sh_flag_family" {
  # One param-read + one translation-arm grep per flag that had no ps1
  # mapping before #571. The exhaustive setup.sh-parse-arm ↔ ps1-param
  # checklist is review-verified (PLAN-571 3.1 Done-when).
  local pairs=(
    'Verbose:--verbose'
    'CheckUpdate:--check-update'
    'Peonping:--peonping'
    'KeepBackups:--keep-backups'
    'ScheduleUpdate:--schedule-update'
    'NoZipBackup:--no-zip-backup'
    'Mix:--mix'
    'EnableLocalLlm:--enable-local-llm'
    'EnableVllm:--enable-vllm'
    'LocalLlm:--local-llm'
    'Vllm:--vllm'
    'EnableAutoUpdate:--enable-auto-update'
    'DisableAutoUpdate:--disable-auto-update'
  )
  local pair name flag
  for pair in "${pairs[@]}"; do
    name="${pair%%:*}"
    flag="${pair##*:}"
    grep -qF "\$$name" "$SETUP_PS1" || { echo "param not read: \$$name"; return 1; }
    grep -qF "\"$flag\"" "$SETUP_PS1" || { echo "flag not forwarded: $flag"; return 1; }
  done
  # -Help rides the fast-path (bare --help literal), not the $forward table.
  grep -qF '$setupSh --help' "$SETUP_PS1"
}
