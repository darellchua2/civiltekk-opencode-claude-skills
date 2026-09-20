#!/usr/bin/env bats
# Tests for the `kimi` install target (#454): Kimi Code native dirs
# (~/.kimi-code/{agents,skills} user, .kimi-code/{agents,skills} project),
# additive permissions→tools/disallowedTools translation, verbatim skills.
# HOME-isolated per test (same mechanism as update.bats).

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INIT="node ${REPO}/installer/init.mjs"
AGENT_SRC="${REPO}/agents/code-review-subagent.md"
WEB_AGENT="$(basename "$(grep -rl 'action: websearch' "${REPO}/agents/" | sort | head -1)" .md)"

setup() {
  export HOME="$(mktemp -d)"
  export MANIFEST="${HOME}/.config/opencode/.skill-manifest.json"
}

teardown() {
  [ -f "${AGENT_SRC}.bats-bak" ] && mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  rm -rf "$HOME"
}

@test "kimi target: installs agent with additive translation (user scope)" {
  run $INIT add code-review-subagent --target kimi --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.kimi-code/agents/code-review-subagent.md"
  [ -f "$F" ]
  grep -q '^tools:' "$F"
  grep -q '  - Read' "$F"
  grep -q '^disallowedTools:' "$F"
  grep -q '  - mcp__\*' "$F"
  grep -q '^permissions:' "$F"
  ! grep -q '^model:' "$F"
  python3 -c "
import json, os
m = json.load(open(os.environ['MANIFEST']))
e = m['entries']['code-review-subagent']
assert 'kimi' in e['targets'], e['targets']
assert 'code-review-subagent' in m['agents'], m['agents']
"
}

@test "kimi target: web tools map to FetchURL/WebSearch (Kimi registry names)" {
  run $INIT add "$WEB_AGENT" --target kimi --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.kimi-code/agents/${WEB_AGENT}.md"
  grep -q '  - FetchURL' "$F"
  grep -q '  - WebSearch' "$F"
  ! grep -q 'WebFetch' "$F"
}

@test "kimi target: unmappable permission rules are dropped with a warning" {
  run $INIT add code-review-subagent --target kimi --yes --no-deps
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "no Kimi equivalent — dropped:"
  echo "$output" | grep -q "skill("
}

@test "kimi target: body bytes stay identical to source" {
  run $INIT add code-review-subagent --target kimi --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.kimi-code/agents/code-review-subagent.md"
  diff <(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$F") \
       <(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$AGENT_SRC") >/dev/null
}

@test "kimi target: skills install verbatim" {
  run $INIT add tdd-workflow-skill --target kimi --yes
  [ "$status" -eq 0 ]
  [ -f "${HOME}/.kimi-code/skills/tdd-workflow-skill/SKILL.md" ]
  [ ! -e "${HOME}/.config/opencode/skills/tdd-workflow-skill" ]
}

@test "kimi target: update is idempotent and re-copies on source drift (translated)" {
  $INIT add code-review-subagent --target kimi --yes --no-deps >/dev/null 2>&1
  run $INIT update
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 0 · unchanged 1"
  cp "$AGENT_SRC" "${AGENT_SRC}.bats-bak"
  echo "bats kimi marker" >> "$AGENT_SRC"
  run $INIT update
  mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 1"
  grep -q "bats kimi marker" "${HOME}/.kimi-code/agents/code-review-subagent.md"
  [ "$(grep -c '^model:' "${HOME}/.kimi-code/agents/code-review-subagent.md")" -eq 0 ]
}

@test "kimi target: remove wipes user-scope kimi copies" {
  $INIT add code-review-subagent --target kimi --yes --no-deps >/dev/null 2>&1
  [ -f "${HOME}/.kimi-code/agents/code-review-subagent.md" ]
  run $INIT remove code-review-subagent
  [ "$status" -eq 0 ]
  [ ! -e "${HOME}/.kimi-code/agents/code-review-subagent.md" ]
}

@test "kimi target: project scope lands in .kimi-code with no opencode artifacts" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT add code-review-subagent --project "$TMP_PROJ" --target kimi --yes --no-deps
  [ "$status" -eq 0 ]
  [ -f "$TMP_PROJ/.kimi-code/agents/code-review-subagent.md" ]
  grep -q '^tools:' "$TMP_PROJ/.kimi-code/agents/code-review-subagent.md"
  [ ! -e "$TMP_PROJ/.opencode" ]
  [ ! -e "$TMP_PROJ/opencode.json" ]
  [ ! -e "$TMP_PROJ/models.json" ]
  [ ! -e "$TMP_PROJ/AGENTS.md" ]
  rm -rf "$TMP_PROJ"
}

@test "kimi target: project-scope downgrade preserved for agents/claude targets" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT add tdd-workflow-skill --project "$TMP_PROJ" --target agents --yes
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "has no project destination"
  [ -d "$TMP_PROJ/.opencode/skills/tdd-workflow-skill" ]
  [ ! -e "${HOME}/.agents" ]
  run $INIT add tdd-workflow-skill --project "$TMP_PROJ" --target claude --yes
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "has no project destination"
  rm -rf "$TMP_PROJ"
}

@test "kimi target: project prune-only wipes .kimi-code installs" {
  TMP_PROJ="$(mktemp -d)"
  $INIT add code-review-subagent --project "$TMP_PROJ" --target kimi --yes --no-deps >/dev/null 2>&1
  [ -f "$TMP_PROJ/.kimi-code/agents/code-review-subagent.md" ]
  run $INIT --project "$TMP_PROJ" --prune --target kimi --yes
  [ "$status" -eq 0 ]
  [ ! -e "$TMP_PROJ/.kimi-code/agents/code-review-subagent.md" ]
  rm -rf "$TMP_PROJ"
}

@test "kimi target: preset flow dies on non-opencode --target" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT --project "$TMP_PROJ" --preset core --target kimi --yes
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "not supported here"
  rm -rf "$TMP_PROJ"
}

@test "kimi target: agent corpus stays free of Kimi template variables" {
  # Kimi renders agent bodies as ${var} templates (cwd/os/shell/now/...); the
  # corpus is verified clean — this pins it so future bash examples can't
  # silently substitute at Kimi's prompt-build time.
  ! grep -rqE '\$\{(cwd|os|shell|now|base_prompt|plugin_sections)\}' "${REPO}/agents/"
}
