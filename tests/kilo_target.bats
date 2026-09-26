#!/usr/bin/env bats
# Tests for the `kilo` install target (#455): Kilo Code native dirs
# (~/.config/kilo/agent + ~/.kilo/skills user, .kilo/{agents,skills} project),
# additive permissions→permission-map translation, verbatim skills.
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

@test "kilo target: installs agent with additive permission map (user scope, singular global dir)" {
  run $INIT add code-review-subagent --target kilo --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.config/kilo/agent/code-review-subagent.md"
  [ -f "$F" ]
  grep -q '^permission:' "$F"
  grep -q '  read: allow' "$F"
  grep -q '  edit: deny' "$F"
  grep -q '  task: deny' "$F"
  ! grep -qE '^(tools|disallowedTools):' "$F"
  ! grep -q '^model:' "$F"
  python3 -c "
import json, os
m = json.load(open(os.environ['MANIFEST']))
e = m['entries']['code-review-subagent']
assert 'kilo' in e['targets'], e['targets']
assert 'code-review-subagent' in m['agents'], m['agents']
"
}

@test "kilo target: ask effect maps to Kilo ask (zai-media-subagent)" {
  run $INIT add zai-media-subagent --target kilo --yes --no-deps
  [ "$status" -eq 0 ]
  grep -q '^  bash: ask' "${HOME}/.config/kilo/agent/zai-media-subagent.md"
}

@test "kilo target: unmappable permission rules are dropped with a warning" {
  run $INIT add code-review-subagent --target kilo --yes --no-deps
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "no Kilo equivalent — dropped:"
  echo "$output" | grep -q "skill("
  echo "$output" | grep -q "read(mcp:\*)"
}

@test "kilo target: body is the source body + composed overlay (frontmatter-only translation)" {
  run $INIT add code-review-subagent --target kilo --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.config/kilo/agent/code-review-subagent.md"
  local src_body inst_body
  src_body=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$AGENT_SRC")
  inst_body=$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$F")
  case "$inst_body" in "$src_body"*) ;; *) echo "installed body diverges from source body" >&3; return 1 ;; esac
  grep -q "## Harness binding — Kilo Code" "$F"
}

@test "kilo target: disabled renames to Kilo disable spelling" {
  cp "$AGENT_SRC" "${AGENT_SRC}.bats-bak"
  sed -i '2i disabled: true' "$AGENT_SRC"
  run $INIT add code-review-subagent --target kilo --yes --no-deps
  mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  [ "$status" -eq 0 ]
  grep -q '^disable: true' "${HOME}/.config/kilo/agent/code-review-subagent.md"
  ! grep -q '^disabled:' "${HOME}/.config/kilo/agent/code-review-subagent.md"
}

@test "kilo target: skills install verbatim to ~/.kilo/skills" {
  run $INIT add tdd-workflow-skill --target kilo --yes
  [ "$status" -eq 0 ]
  [ -f "${HOME}/.kilo/skills/tdd-workflow-skill/SKILL.md" ]
  [ ! -e "${HOME}/.config/opencode/skills/tdd-workflow-skill" ]
}

@test "kilo target: update is idempotent and re-copies on source drift (translated)" {
  $INIT add code-review-subagent --target kilo --yes --no-deps >/dev/null 2>&1
  run $INIT update
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 0 · unchanged 1"
  cp "$AGENT_SRC" "${AGENT_SRC}.bats-bak"
  echo "bats kilo marker" >> "$AGENT_SRC"
  run $INIT update
  mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 1"
  grep -q "bats kilo marker" "${HOME}/.config/kilo/agent/code-review-subagent.md"
  [ "$(grep -c '^model:' "${HOME}/.config/kilo/agent/code-review-subagent.md")" -eq 0 ]
}

@test "kilo target: remove wipes user-scope kilo copies" {
  $INIT add code-review-subagent --target kilo --yes --no-deps >/dev/null 2>&1
  [ -f "${HOME}/.config/kilo/agent/code-review-subagent.md" ]
  run $INIT remove code-review-subagent
  [ "$status" -eq 0 ]
  [ ! -e "${HOME}/.config/kilo/agent/code-review-subagent.md" ]
}

@test "kilo target: project scope lands in .kilo with no opencode artifacts" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT add code-review-subagent --project "$TMP_PROJ" --target kilo --yes --no-deps
  [ "$status" -eq 0 ]
  local F="$TMP_PROJ/.kilo/agents/code-review-subagent.md"
  [ -f "$F" ]
  grep -q '^permission:' "$F"
  ! grep -qE '^(tools|disallowedTools):' "$F"
  [ ! -e "$TMP_PROJ/.opencode" ]
  [ ! -e "$TMP_PROJ/opencode.json" ]
  [ ! -e "$TMP_PROJ/models.json" ]
  [ ! -e "$TMP_PROJ/AGENTS.md" ]
  rm -rf "$TMP_PROJ"
}

@test "kilo target: project-scope downgrade preserved for agents/claude targets" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT add tdd-workflow-skill --project "$TMP_PROJ" --target agents --yes
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "has no project destination"
  [ ! -e "${HOME}/.agents" ]
  run $INIT add tdd-workflow-skill --project "$TMP_PROJ" --target claude --yes
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "has no project destination"
  rm -rf "$TMP_PROJ"
}

@test "kilo target: preset flow dies on non-opencode --target" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT --project "$TMP_PROJ" --preset core --target kilo --yes
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "not supported here"
  rm -rf "$TMP_PROJ"
}

@test "kilo target: skills corpus stays free of Kilo-executable inline commands" {
  # Kilo executes !`cmd` snippets in trusted (global) skills behind one approval
  # prompt; the corpus is verified clean — this pins it.
  ! grep -rqE '!\`' "${REPO}/skills/"
}

@test "kilo target: agents corpus stays free of legacy disabled spelling" {
  # The kilo transform renames disabled→disable; corpus has none today — pin it.
  ! grep -rq '^disabled:' "${REPO}/agents/"
}
