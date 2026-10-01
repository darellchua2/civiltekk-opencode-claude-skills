#!/usr/bin/env bats

# Tests for agent/skill count drift prevention (PLAN-GIT-312, D1+D2).
# Verifies count_agents()/Get-AgentCount exist, match disk reality, and
# no stale hardcoded agent-count literals remain in setup scripts.
# Peer to test_markitdown_skill.bats skill-count coverage (PLAN-GIT-264).

SKILLS_DIR="skills"
AGENTS_DIR="agents"

# =============================================================================
# Agent count — dynamic function vs disk
# =============================================================================

@test "agent_count_matches_disk" {
  actual=$(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
  echo "Actual agent count: $actual" >&3

  # setup.sh: source count_agents() and verify output == disk
  source <(sed -n '/^count_agents()/,/^}/p' deploy/setup.sh)
  setup_count=$(count_agents "$AGENTS_DIR" | tr -d ' ')
  echo "setup.sh count_agents output: $setup_count" >&3
  [ "$setup_count" = "$actual" ]
}

@test "agent_count_no_stale_hardcoded_in_setup_sh" {
  # Banner should use $(count_agents ...) interpolation, not literal numbers
  ! grep -qE 'AGENTS \([0-9]+\)' deploy/setup.sh
  ! grep -qE 'Configured [0-9]+ agents:' deploy/setup.sh
}

@test "agent_count_no_stale_hardcoded_in_setup_ps1" {
  ! grep -qE 'AGENTS \([0-9]+\)' deploy/setup.ps1
  ! grep -qE 'Configured [0-9]+ agents:' deploy/setup.ps1
}

@test "setup_ps1_thin_launcher_delegates_counting_to_bash" {
  # #474: setup.ps1 is a thin launcher — agent counting lives in setup.sh
  # (count_agents, pinned above); the ps1 performs no selection logic.
  grep -q 'setup.sh' deploy/setup.ps1
  run grep -q 'function Get-AgentCount' deploy/setup.ps1
  [ "$status" -ne 0 ]
}

# =============================================================================
# Skill count — regression guard (mirrors test_markitdown_skill.bats)
# =============================================================================

@test "skill_count_matches_disk" {
  actual=$(find "$SKILLS_DIR" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
  echo "Actual skill count: $actual" >&3

  source <(sed -n '/^count_skills()/,/^}/p' deploy/setup.sh)
  setup_count=$(count_skills "$SKILLS_DIR" | tr -d ' ')
  echo "setup.sh count_skills output: $setup_count" >&3
  [ "$setup_count" = "$actual" ]
}

# =============================================================================
# README count literals — derived numbers must match the file (#659)
# Pinned-phrase contract: each grep anchors its number to a README count
# context. A PR that rewords one of these phrases updates this list in the
# same PR — never grep bare numbers (false-green class #423/#512).
# =============================================================================

readme_count_assert() { # $1 = path to the README under test
    local readme="$1"
    local disk lean
    disk=$(find "$SKILLS_DIR" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
    lean=$(node -e "console.log(require(process.cwd() + '/deploy/skill-profiles.json').lean.length)")

    # skill-total contexts (same derivation as skill_count_matches_disk above)
    # every check fail-fast: a bare sequence would return only the LAST grep's
    # status and mask earlier misses (#423/#512 false-green class).
    grep -qE "\*\*${disk} ready-to-load skills" "$readme" || return 1
    grep -qE "\+ ${disk} skills\." "$readme" || return 1
    grep -qE "# ${disk} skill directories" "$readme" || return 1
    grep -qE "${disk} skills stay on disk" "$readme" || return 1
    grep -qE "Skill catalog — ${disk} skills by category" "$readme" || return 1
    grep -qE "Current count: \*\*${disk}\*\*" "$readme" || return 1
    # primary-visible context (lean array length)
    grep -qE "\(${lean} primary-visible skills" "$readme" || return 1
}

@test "readme_skill_total_and_lean_match_derived" {
    readme_count_assert "README.md"
}

@test "readme_stale_literal_fails" {
    # Negative fixture: a corrupted count must fail the helper — proves the
    # guard can fail (mirrors skill_profiles.bats' phantom-rule fixture).
    d="$(mktemp -d)"
    sed -E "s/Current count: \*\*[0-9]+\*\*/Current count: **0**/" README.md > "$d/README.md"
    grep -q 'Current count: \*\*0\*\*' "$d/README.md"   # corruption landed
    run readme_count_assert "$d/README.md"
    [ "$status" -ne 0 ]
    rm -rf "$d"
}
