#!/usr/bin/env bats

# opencode-setup shim: setup.sh must be invocable through a PATH symlink
# (the artifact setup_opencode_setup_symlink installs, and npm bin links).
# A naive `dirname BASH_SOURCE` resolves REPO_DIR to the shim's parent —
# deploys then copy nothing and the version read falls back to 2.0.0.

SETUP_SH="deploy/setup.sh"

@test "setup_sh_resolves_repo_dir_through_symlink" {
  local d shim ver
  d="$(mktemp -d)"
  shim="$d/opencode-setup"
  ln -s "$(pwd)/$SETUP_SH" "$shim"
  ver="$(tr -d '[:space:]' < VERSION)"
  # VERSION is read from $REPO_DIR/VERSION at source time, before main() —
  # --help prints "v${SCRIPT_VERSION}". Wrong resolution prints v2.0.0.
  run bash -c "HOME='$d' bash '$shim' --help"
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"v${ver}"* ]]
  [[ "$output" != *"VERSION file not found"* ]]
}

@test "full_plan_steps_include_setup_shim" {
  local d; d="$(mktemp -d)"
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; build_plan; printf '%s\n' \"\${PLAN_STEPS[@]}\""
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"setup_opencode_setup_symlink"* ]]
}

@test "skills_only_plan_real_run_installs_setup_shim" {
  local d
  d="$(mktemp -d)"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; SKILLS_ONLY=true
           check_dependencies(){ return 0; }; command_exists(){ return 0; }; validate_opencode_install(){ return 0; }
           build_plan; run_plan" >/dev/null 2>&1
  [ -L "$d/.local/bin/opencode-setup" ]
  rm -rf "$d"
}

@test "skills_only_plan_dry_run_creates_no_setup_shim" {
  local d
  d="$(mktemp -d)"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=true; SKILLS_ONLY=true
           check_dependencies(){ return 0; }; command_exists(){ return 0; }; validate_opencode_install(){ return 0; }
           build_plan; run_plan" >/dev/null 2>&1
  [ ! -e "$d/.local/bin/opencode-setup" ]
  rm -rf "$d"
}

@test "package_json_exposes_opencode_setup_bin" {
  # npx -p github:... opencode-setup runs the full deploy remotely; the
  # opencode-skill bin (name == package name) stays the bare-npx default.
  grep -q '"opencode-setup": "./deploy/setup.sh"' package.json
}
