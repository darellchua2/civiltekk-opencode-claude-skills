#!/usr/bin/env bats

# Subcommands, --list-items, presets, de-bloat, and the ps1 thin launcher
# (#474). Subcommands are ALIASES over the #470 mode flags; the ps1 is a
# bootstrap that forwards everything to setup.sh (no selection logic).

SETUP_SH="deploy/setup.sh"
SETUP_PS1="deploy/setup.ps1"

@test "subcommand_aliases_map_to_mode_flags" {
  local d; d="$(mktemp -d)"
  for pair in "update:UPDATE_ONLY" "peonping:PEONPING_ONLY" "plan:SELECT_ITEMS" "check-catalog:CHECK_CATALOG_ONLY"; do
    local sub flag
    sub="${pair%%:*}"; flag="${pair##*:}"
    run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; parse_arguments $sub; [ \"\$$flag\" = true ]"
    [ "$status" -eq 0 ]
  done
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; parse_arguments llm; [ \"\$ENABLE_LOCAL_LLM\" = true ] && [ \"\$ENABLE_VLLM\" = true ]"
  [ "$status" -eq 0 ]
  rm -rf "$d"
}

@test "rollback_subcommand_accepts_optional_target" {
  local d; d="$(mktemp -d)"
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; parse_arguments rollback 20260101_000000; echo \"\$ROLLBACK_MODE|\$ROLLBACK_TARGET\""
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"true|20260101_000000"* ]]
}

@test "list_items_dumps_registry_catalog" {
  local d; d="$(mktemp -d)"
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; LIST_ITEMS=true; build_plan; run_plan" 2>/dev/null
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"skills"'* ]]
  [[ "$output" == *'"agents"'* ]]
  [[ "$output" == *'"packs"'* ]]
}

@test "preset_save_load_roundtrip" {
  local d; d="$(mktemp -d)"
  mkdir -p "$d/.config/opencode"
  printf '{"primary":"zai-coding-plan/glm-5.3"}' > "$d/.config/opencode/models.json"
  bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; SAVE_PRESET_NAME=work; save_user_preset" >/dev/null 2>&1
  [ -f "$d/.config/opencode/presets/work/models.json" ]
  rm -f "$d/.config/opencode/models.json"
  bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; LOAD_PRESET_NAME=work; load_user_preset" >/dev/null 2>&1
  grep -q 'glm-5.3' "$d/.config/opencode/models.json"
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; LOAD_PRESET_NAME=nope; load_user_preset"
  [ "$status" -ne 0 ]
  rm -rf "$d"
}

@test "auto_update_flags_are_hinting_no_ops" {
  # Pin at parse level: -A prints the migration hint and leaves
  # ENABLE_AUTO_UPDATE=false. (Executing main end-to-end would depend on the
  # host's opencode install — the CI runner has none, so validate fails.)
  run bash -c "source '$SETUP_SH' >/dev/null 2>&1; parse_arguments -A"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Auto-update has been removed"* ]]
  run bash -c "source '$SETUP_SH' >/dev/null 2>&1; parse_arguments -A; [ \"\$ENABLE_AUTO_UPDATE\" = false ]"
  [ "$status" -eq 0 ]
  run grep -q 'auto_update_opencode' "$SETUP_SH"
  [ "$status" -ne 0 ]
}

@test "show_progress_deleted" {
  run grep -q "show_progress" "$SETUP_SH"
  [ "$status" -ne 0 ]
}

@test "hand_maintained_numeric_claims_removed" {
  run grep -q "primary sees 46 skills" "$SETUP_SH"
  [ "$status" -ne 0 ]
  run grep -q "all 4 Autodesk MCP servers" "$SETUP_SH"
  [ "$status" -ne 0 ]
}

@test "help_documents_subcommands_and_new_flags" {
  run bash "$SETUP_SH" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"install | update | rollback | peonping | llm | plan | check-catalog"* ]]
  [[ "$output" == *"--list-items"* ]]
  [[ "$output" == *"--save-preset"* ]]
}

@test "ps1_thin_launcher_forwards_and_has_no_selection_logic" {
  grep -q 'setup.sh' "$SETUP_PS1"
  grep -q 'LASTEXITCODE' "$SETUP_PS1"
  run grep -qE 'function Set-Configuration|function Deploy-Plugins|function Invoke-Resolver|function Deploy-Agents' "$SETUP_PS1"
  [ "$status" -ne 0 ]
  grep -q '\$SkillsOnly' "$SETUP_PS1"
  grep -q '\$Quick' "$SETUP_PS1"
  grep -q '26.4' "$SETUP_PS1"
}
