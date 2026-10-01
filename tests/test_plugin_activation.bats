#!/usr/bin/env bats

# Tests for deploy_plugins activation semantics (#624 follow-up): a changed
# plugin set must instruct/trigger a service restart, but NEVER from a
# headless context (tests/CI/agent runs share the user's real, global
# background service — a restart there kills live sessions), and an unchanged
# set never restarts (#588 lesson). deploy_plugins is exercised directly via
# a sourced setup.sh (top-level code is var/function defs + the guarded main).

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SETUP_SH="${REPO}/deploy/setup.sh"

setup() {
  export SANDBOX="$(mktemp -d)"
  export HOME="$SANDBOX"
  # Recorder stub: any invocation (a restart attempt) appends to $CALLS.
  export CALLS="$SANDBOX/opencode-calls"
  mkdir -p "$SANDBOX/bin"
  printf '#!/bin/bash\nprintf "%%s\\n" "$*" >> "$CALLS"\n[ "$1" = "--version" ] && echo "opencode v2.0.18-test"\nexit 0\n' > "$SANDBOX/bin/opencode"
  chmod +x "$SANDBOX/bin/opencode"
  export PATH="$SANDBOX/bin:$PATH"
}

teardown() { rm -rf "$SANDBOX"; }

run_deploy_plugins() {
  local dest="$SANDBOX/.config/opencode/plugins"
  bash -c '
    source "$1" || exit 1
    PLUGINS_DEST_DIR="$2"
    deploy_plugins
  ' _ "$SETUP_SH" "$dest"
}

@test "bash syntax valid after activation edit" {
  bash -n "$SETUP_SH"
}

@test "changed set, headless: instruction printed, restart NOT attempted" {
  run run_deploy_plugins
  [ "$status" -eq 0 ]
  # fresh sandbox → every plugin differs → changed
  [[ "$output" == *"Plugin set changed - activate with: opencode service restart"* ]]
  # headless safety: the real service was never touched
  [ ! -f "$CALLS" ]
}

@test "unchanged set on re-run: no restart needed, no instruction" {
  run run_deploy_plugins
  [ "$status" -eq 0 ]
  run run_deploy_plugins
  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin set unchanged - no service restart needed"* ]]
  [[ "$output" != *"activate with"* ]]
  [ ! -f "$CALLS" ]
}

@test "dry-run: previews the restart, copies nothing" {
  local dest="$SANDBOX/.config/opencode/plugins"
  run bash -c '
    source "$1" || exit 1
    PLUGINS_DEST_DIR="$2"
    DRY_RUN=true deploy_plugins
  ' _ "$SETUP_SH" "$dest"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[DRY-RUN] Would restart the opencode background service (plugin set changed)"* ]]
  [ ! -e "$dest" ]
  [ ! -f "$CALLS" ]
}

@test "changed plugin content (not just names) re-triggers the instruction" {
  run run_deploy_plugins
  [ "$status" -eq 0 ]
  # mutate one deployed copy → content drift must read as changed
  echo "// drift" >> "$SANDBOX/.config/opencode/plugins/opencode-location-keepalive-v2.ts"
  run run_deploy_plugins
  [ "$status" -eq 0 ]
  [[ "$output" == *"activate with: opencode service restart"* ]]
}
