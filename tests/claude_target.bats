#!/usr/bin/env bats
# Tests for the claude agents install (#457): ~/.claude/agents/ with additive
# tools/disallowedTools translation + name synthesis (#377 reversal).
# HOME-isolated per test (same mechanism as update.bats).

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INIT="node ${REPO}/installer/init.mjs"
AGENT_SRC="${REPO}/agents/code-review-subagent.md"

setup() {
  export HOME="$(mktemp -d)"
  export MANIFEST="${HOME}/.config/opencode/.skill-manifest.json"
}

teardown() {
  [ -f "${AGENT_SRC}.bats-bak" ] && mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  rm -rf "$HOME"
}

@test "claude agents: installs with synthesized name + tools allowlist" {
  run $INIT add code-review-subagent --target claude --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.claude/agents/code-review-subagent.md"
  [ -f "$F" ]
  grep -q '^name: code-review-subagent' "$F"
  grep -q '^tools:' "$F"
  grep -q '  - Read' "$F"
  grep -q '  - WebFetch' "$F"
  ! grep -q '^model:' "$F"
  python3 -c "
import json, os
m = json.load(open(os.environ['MANIFEST']))
e = m['entries']['code-review-subagent']
assert 'claude' in e['targets'], e['targets']
assert 'code-review-subagent' in m['agents'], m['agents']
"
}

@test "claude agents: task deny carries to disallowedTools, never to tools" {
  run $INIT add code-review-subagent --target claude --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.claude/agents/code-review-subagent.md"
  python3 - "$F" <<'EOF'
import sys
section, tools, disallowed = None, [], []
for line in open(sys.argv[1]).read().splitlines():
    if line == "tools:": section = "t"; continue
    if line == "disallowedTools:": section = "d"; continue
    if line.startswith("  - ") and section == "t": tools.append(line[4:])
    elif line.startswith("  - ") and section == "d": disallowed.append(line[4:])
    elif line and not line.startswith(" "): section = None
assert "Task" in disallowed, f"task deny not carried: {disallowed}"
assert "Task" not in tools, f"Task leaked into tools: {tools}"
EOF
}

@test "claude agents: unmappable permission rules are dropped with a warning" {
  run $INIT add code-review-subagent --target claude --yes --no-deps
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "no Claude agent-frontmatter equivalent — dropped:"
  echo "$output" | grep -q "skill("
  echo "$output" | grep -q "read(mcp:\*)"
}

@test "claude agents: body bytes stay identical to source" {
  run $INIT add code-review-subagent --target claude --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.claude/agents/code-review-subagent.md"
  diff <(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$F") \
       <(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$AGENT_SRC") >/dev/null
}

@test "claude target: skills output unchanged (model-strip path intact)" {
  run $INIT add tdd-workflow-skill --target claude --yes
  [ "$status" -eq 0 ]
  [ -f "${HOME}/.claude/skills/tdd-workflow-skill/SKILL.md" ]
  [ ! -e "${HOME}/.config/opencode/skills/tdd-workflow-skill" ]
}

@test "claude target: both installs agents to ~/.claude/agents too" {
  run $INIT add code-review-subagent --target both --yes --no-deps
  [ "$status" -eq 0 ]
  [ -f "${HOME}/.claude/agents/code-review-subagent.md" ]
  [ -f "${HOME}/.config/opencode/agents/code-review-subagent.md" ]
  # the two copies differ: opencode is model-injected, claude is not
  ! diff -q "${HOME}/.claude/agents/code-review-subagent.md" \
            "${HOME}/.config/opencode/agents/code-review-subagent.md" >/dev/null
}

@test "claude agents: update is idempotent and re-copies on source drift (translated)" {
  $INIT add code-review-subagent --target claude --yes --no-deps >/dev/null 2>&1
  run $INIT update
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 0 · unchanged 1"
  cp "$AGENT_SRC" "${AGENT_SRC}.bats-bak"
  echo "bats claude marker" >> "$AGENT_SRC"
  run $INIT update
  mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 1"
  grep -q "bats claude marker" "${HOME}/.claude/agents/code-review-subagent.md"
  [ "$(grep -c '^model:' "${HOME}/.claude/agents/code-review-subagent.md")" -eq 0 ]
}

@test "claude agents: remove wipes ~/.claude/agents copies" {
  $INIT add code-review-subagent --target claude --yes --no-deps >/dev/null 2>&1
  [ -f "${HOME}/.claude/agents/code-review-subagent.md" ]
  run $INIT remove code-review-subagent
  [ "$status" -eq 0 ]
  [ ! -e "${HOME}/.claude/agents/code-review-subagent.md" ]
}

@test "claude target: --project keeps downgrade note (user-scope agents only)" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT add tdd-workflow-skill --project "$TMP_PROJ" --target claude --yes
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "has no project destination"
  [ -d "$TMP_PROJ/.opencode/skills/tdd-workflow-skill" ]
  [ ! -e "${HOME}/.claude/agents" ]
  rm -rf "$TMP_PROJ"
}

@test "claude agents: --dry-run previews and writes nothing" {
  run $INIT add code-review-subagent --target claude --yes --dry-run
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"destinations"'
  [ ! -e "${HOME}/.claude" ]
}

@test "claude agents: pre-existing tools key still gets required name synthesis" {
  cp "$AGENT_SRC" "${AGENT_SRC}.bats-bak"
  sed -i '2i tools: Read, Grep' "$AGENT_SRC"
  run $INIT add code-review-subagent --target claude --yes --no-deps
  mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  [ "$status" -eq 0 ]
  local F="${HOME}/.claude/agents/code-review-subagent.md"
  grep -q '^name: code-review-subagent' "$F"
  ! grep -q '^  - WebFetch' "$F"
}

@test "claude agents: pre-existing name + tools returns verbatim" {
  cp "$AGENT_SRC" "${AGENT_SRC}.bats-bak"
  sed -i '2i name: custom-name\ntools: Read, Grep' "$AGENT_SRC"
  run $INIT add code-review-subagent --target claude --yes --no-deps
  mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  [ "$status" -eq 0 ]
  local F="${HOME}/.claude/agents/code-review-subagent.md"
  grep -q '^name: custom-name' "$F"
  ! grep -q '^  - WebFetch' "$F"
}
