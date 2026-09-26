#!/usr/bin/env bats
# Tests for the `copilot` install target (#581): agents ~/.copilot/agents (user),
# .claude/agents + .github/skills (project — per-content-type documented dirs),
# claude-translate reuse, skillsDir null at user scope (agents-only target).
# HOME-isolated per test (same mechanism as kimi/kilo suites).

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INIT="node ${REPO}/installer/init.mjs"
AGENT_SRC="${REPO}/agents/code-review-subagent.md"

setup() {
  export HOME="$(mktemp -d)"
  export MANIFEST="${HOME}/.config/opencode/.skill-manifest.json"
}

teardown() {
  rm -rf "$HOME"
}

@test "copilot target: help lists copilot" {
  run $INIT --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -- "--target copilot"
}

@test "copilot target: user-scope agents install claude-format translated (~/.copilot/agents)" {
  run $INIT add code-review-subagent --target copilot --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.copilot/agents/code-review-subagent.md"
  [ -f "$F" ]
  grep -q '^name: code-review-subagent' "$F"
  grep -q '^tools:' "$F"
  grep -q '  - Read' "$F"
  grep -q '^disallowedTools:' "$F"
  ! grep -q '^model:' "$F"
  grep -q "## Harness binding — GitHub Copilot" "$F"
}

@test "copilot target: user-scope skills are not installed (agents-only target)" {
  run $INIT add tdd-workflow-skill --target copilot --yes
  [ "$status" -eq 0 ]
  [ ! -e "${HOME}/.copilot/skills" ]
}

@test "copilot target: project scope lands in .claude/agents + .github/skills" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT add code-review-subagent --project "$TMP_PROJ" --target copilot --yes --no-deps
  [ "$status" -eq 0 ]
  [ -f "$TMP_PROJ/.claude/agents/code-review-subagent.md" ]
  grep -q '^name: code-review-subagent' "$TMP_PROJ/.claude/agents/code-review-subagent.md"
  grep -q '^tools:' "$TMP_PROJ/.claude/agents/code-review-subagent.md"
  run $INIT add tdd-workflow-skill --project "$TMP_PROJ" --target copilot --yes
  [ "$status" -eq 0 ]
  [ -f "$TMP_PROJ/.github/skills/tdd-workflow-skill/SKILL.md" ]
  [ ! -e "$TMP_PROJ/.opencode" ]
  rm -rf "$TMP_PROJ"
}

@test "copilot target: remove wipes user-scope copilot copies" {
  $INIT add code-review-subagent --target copilot --yes --no-deps >/dev/null 2>&1
  [ -f "${HOME}/.copilot/agents/code-review-subagent.md" ]
  run $INIT remove code-review-subagent
  [ "$status" -eq 0 ]
  [ ! -e "${HOME}/.copilot/agents/code-review-subagent.md" ]
}

@test "copilot target: dry-run destination reports ~/.copilot" {
  run $INIT add code-review-subagent --target copilot --yes --dry-run
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '\.copilot"'
}
