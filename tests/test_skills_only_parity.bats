#!/usr/bin/env bats

# Skills-only membership parity (#469): bash deploy_skills_only must ship the
# same auxiliary content as ps1 -SkillsOnly — plugins + opencode-init shim —
# not just config/agents/learnings. Regression being pinned: bash skills-only
# silently omitted the opencode-* plugins (incl. the default-enabled
# auto-continue hook) while Windows shipped them.

SETUP_SH="deploy/setup.sh"
SETUP_PS1="deploy/setup.ps1"

@test "deploy_skills_only_body_includes_plugins_and_init_shim" {
  # Extract the function body (definition line to the next top-level construct)
  local body
  body="$(awk '/^deploy_skills_only\(\) \{/{f=1} f{print} f&&/^\}$/{exit}' "$SETUP_SH")"
  echo "$body" | grep -q 'deploy_plugins || true'
  echo "$body" | grep -q 'setup_opencode_init_symlink || true'
}

@test "skills_only_real_run_deploys_plugins_and_shim" {
  local d
  d="$(mktemp -d)"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; check_dependencies(){ return 0; }; command_exists(){ return 0; }; deploy_skills_only" >/dev/null 2>&1
  [ -d "$d/.config/opencode/plugins" ]
  [ -L "$d/.local/bin/opencode-init" ]
  rm -rf "$d"
}

@test "skills_only_dry_run_creates_neither_artifact" {
  local d
  d="$(mktemp -d)"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=true; check_dependencies(){ return 0; }; command_exists(){ return 0; }; deploy_skills_only" >/dev/null 2>&1
  [ ! -d "$d/.config/opencode/plugins" ]
  [ ! -e "$d/.local/bin/opencode-init" ]
  rm -rf "$d"
}

@test "ps1_skills_only_reachable_path_chains_plugins_and_shim" {
  # setup.ps1:1832-1833 — the config path -SkillsOnly runs must keep both.
  local region
  region="$(sed -n '1825,1840p' "$SETUP_PS1")"
  echo "$region" | grep -q 'Deploy-Plugins'
  echo "$region" | grep -q 'Setup-OpencodeInitShim'
}
