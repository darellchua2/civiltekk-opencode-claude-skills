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
  actual=$(find "$SKILLS_DIR" -maxdepth 2 -name SKILL.md -not -path '*/_archived/*' | wc -l | tr -d ' ')
  echo "Actual skill count: $actual" >&3

  source <(sed -n '/^count_skills()/,/^}/p' deploy/setup.sh)
  setup_count=$(count_skills "$SKILLS_DIR" | tr -d ' ')
  echo "setup.sh count_skills output: $setup_count" >&3
  [ "$setup_count" = "$actual" ]
}
