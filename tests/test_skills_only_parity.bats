#!/usr/bin/env bats

# Skills-only membership parity (#469): the skills-only path must ship the
# same auxiliary content — plugins + opencode-init shim — not just
# config/agents/learnings. Regression being pinned: skills-only silently
# omitted the opencode-* plugins (incl. the default-enabled auto-continue
# hook). #474 re-pinned these against build_plan's LIVE step list after the
# deploy_skills_only wrapper (zero production callers) was deleted.

SETUP_SH="deploy/setup.sh"
SETUP_PS1="deploy/setup.ps1"

@test "skills_only_plan_steps_include_plugins_and_init_shim" {
  # #469 regression, re-pinned against the LIVE step list (#474 review: the
  # deploy_skills_only wrapper is gone - build_plan's skills-only branch is
  # the real path now).
  local d; d="$(mktemp -d)"
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; SKILLS_ONLY=true; build_plan; printf '%s\n' \"\${PLAN_STEPS[@]}\""
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"|plugins|"* ]]
  [[ "$output" == *"setup_opencode_init_symlink"* ]]
}

@test "skills_only_plan_real_run_deploys_plugins_and_shim" {
  local d
  d="$(mktemp -d)"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; SKILLS_ONLY=true
           check_dependencies(){ return 0; }; command_exists(){ return 0; }; validate_opencode_install(){ return 0; }
           build_plan; run_plan" >/dev/null 2>&1
  [ -d "$d/.config/opencode/plugins" ]
  [ -L "$d/.local/bin/opencode-init" ]
  rm -rf "$d"
}

@test "skills_only_plan_dry_run_creates_neither_artifact" {
  local d
  d="$(mktemp -d)"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=true; SKILLS_ONLY=true
           check_dependencies(){ return 0; }; command_exists(){ return 0; }; validate_opencode_install(){ return 0; }
           build_plan; run_plan" >/dev/null 2>&1
  [ ! -d "$d/.config/opencode/plugins" ]
  [ ! -e "$d/.local/bin/opencode-init" ]
  rm -rf "$d"
}

@test "ps1_skills_only_forwards_to_bash_skills_only" {
  # #474: skills-only parity is structural — the launcher forwards
  # -SkillsOnly to setup.sh's --skills-only, whose body is pinned above.
  grep -q '\$SkillsOnly' "$SETUP_PS1"
  grep -qF '"--skills-only"' "$SETUP_PS1"
  grep -q 'setup.sh' "$SETUP_PS1"
}
