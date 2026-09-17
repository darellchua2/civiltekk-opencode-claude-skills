#!/usr/bin/env bats

# Tests for markitdown-mcp-skill (PLAN-GIT-264).
# Verifies skill existence, frontmatter validity, required sections, exact MCP
# tool name reference, agent routing grants, and cross-file skill count
# consistency. Peer to tests/test_mcp_count_consistency.bats (PLAN-GIT-262).

SKILL_MD="skills/markitdown-mcp-skill/SKILL.md"
AGENTS_DIR="agents"

# Agents that should have markitdown-mcp-skill: allow in their permission.skill
AGENTS_WITH_SKILL_GRANT=(
  "office-document-primary-agent"
  "documentation-subagent"
  "requirements-specialist-subagent"
  "technical-design-specialist-subagent"
  "discovery-specialist-subagent"
)

# =============================================================================
# Skill existence + frontmatter
# =============================================================================

@test "markitdown_skill_file_exists" {
  [ -f "$SKILL_MD" ]
}

@test "markitdown_skill_frontmatter_parses" {
  python3 -c "import yaml; d=open('$SKILL_MD').read(); fm=yaml.safe_load(d.split('---')[1]); assert fm['name']=='markitdown-mcp-skill'; assert 'license' in fm; assert 'compatibility' in fm; assert 'metadata' in fm"
}

@test "markitdown_skill_required_sections_present" {
  for section in "## What this skill does" "## Requirements & Honesty Note" \
                 "## opencode.json Configuration" "## Available MCP Tools" \
                 "## Format Coverage" "## Decision Tree" "## Usage Patterns" \
                 "## Troubleshooting" "## Fallback Strategy (No MCP)" \
                 "## Privacy Guarantees"; do
    grep -qF "$section" "$SKILL_MD"
  done
}

@test "markitdown_skill_references_exact_tool_name" {
  # The exact MCP tool name must appear in the skill so agents can call it
  grep -q 'convert_to_markdown' "$SKILL_MD"
}

@test "markitdown_skill_decision_tree_covers_pdf_specialist_collision" {
  # Per arch-C2: skill must disambiguate markitdown vs pdf-specialist-skill
  grep -q 'pdf-specialist-skill' "$SKILL_MD"
}

# =============================================================================
# Agent routing — 5 agents should grant markitdown-mcp-skill: allow
# =============================================================================

@test "agents_have_markitdown_skill_grant" {
  for agent in "${AGENTS_WITH_SKILL_GRANT[@]}"; do
    echo "  checking $agent" >&3
    grep -q "markitdown-mcp-skill: allow" "$AGENTS_DIR/$agent.md"
  done
}

@test "office_document_primary_agent_has_routing_matrix_row" {
  # Peer-conventional row format (not "Direct MCP call")
  grep -qF 'Load `markitdown-mcp-skill` → call `markitdown` MCP' \
    "$AGENTS_DIR/office-document-primary-agent.md"
}

# =============================================================================
# Cross-file skill count consistency (dynamic: count_skills == disk == README)
# =============================================================================

@test "skill_count_consistent_across_docs" {
  # Active count excludes _archived (matches count_skills/Get-SkillCount). BT-157.
  actual=$(find skills -maxdepth 2 -name SKILL.md -not -path '*/_archived/*' | wc -l | tr -d ' ')
  echo "Actual skill count: $actual" >&3

  # setup.sh: dynamic via count_skills() helper — source it, verify output == disk,
  # and confirm no stale hardcoded literal remains. BT-157.
  source <(sed -n '/^count_skills()/,/^}/p' deploy/setup.sh)
  setup_count=$(count_skills skills | tr -d ' ')
  echo "setup.sh count_skills output: $setup_count" >&3
  [ "$setup_count" = "$actual" ]
  ! grep -qE 'SKILLS \([0-9]+\)' deploy/setup.sh

  # setup.ps1: dynamic via Get-SkillCount — verify helper present + no stale literal.
  grep -q 'function Get-SkillCount' deploy/setup.ps1
  ! grep -qE 'SKILLS \([0-9]+\)' deploy/setup.ps1

  # opencode_app/README.md skill directory count
  docker_count=$(grep -oE '[0-9]+ skill director(y|ies)' opencode_app/README.md | grep -oE '[0-9]+' | head -1)
  echo "opencode_app/README.md count: $docker_count" >&3
  [ "$docker_count" = "$actual" ]

  # README.md skill directory count
  readme_count=$(grep -oE '[0-9]+ skill director(y|ies)' README.md | grep -oE '[0-9]+' | head -1)
  echo "README.md count: $readme_count" >&3
  [ "$readme_count" = "$actual" ]
}

@test "configuration_category_count_is_three" {
  # Category counts drift as skills are merged/recategorized (BT-157);
  # README's Configuration count must equal registry.json's.
  actual=$(grep -oE '\*\*Configuration\*\* \([0-9]+\)|Configuration \([0-9]+\)' README.md | grep -oE '[0-9]+' | head -1)
  expected=$(node -e "const r=require('./installer/registry.json'); console.log((r.skills||[]).filter(s=>s.category==='Configuration').length)")
  echo "README.md Configuration count: $actual, registry: $expected" >&3
  [ "$actual" = "$expected" ]
}
