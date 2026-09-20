#!/usr/bin/env bats
# Tests for the `agents` install target (#453): verbatim copies into the
# cross-tool shared dir ~/.agents/{agents,skills}/ (read by Kimi Code and pi).
# HOME-isolated per test (same mechanism as update.bats).

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INIT="node ${REPO}/installer/init.mjs"
SKILL_SRC="${REPO}/skills/tdd-workflow-skill/SKILL.md"
AGENT_SRC="${REPO}/agents/code-review-subagent.md"

setup() {
  export HOME="$(mktemp -d)"
  export MANIFEST="${HOME}/.config/opencode/.skill-manifest.json"
}

teardown() {
  [ -f "${SKILL_SRC}.bats-bak" ] && mv "${SKILL_SRC}.bats-bak" "$SKILL_SRC"
  [ -f "${AGENT_SRC}.bats-bak" ] && mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  rm -rf "$HOME"
}

@test "agents target: installs skill verbatim to ~/.agents/skills + manifest targets.agents" {
  run $INIT add tdd-workflow-skill --target agents --yes
  [ "$status" -eq 0 ]
  [ -f "${HOME}/.agents/skills/tdd-workflow-skill/SKILL.md" ]
  [ ! -e "${HOME}/.config/opencode/skills/tdd-workflow-skill" ]
  python3 -c "
import json, os
m = json.load(open(os.environ['MANIFEST']))
e = m['entries']['tdd-workflow-skill']
assert 'agents' in e['targets'], e['targets']
"
}

@test "agents target: installs agent verbatim (unpinned) to ~/.agents/agents" {
  run $INIT add code-review-subagent --target agents --yes --no-deps
  [ "$status" -eq 0 ]
  [ -f "${HOME}/.agents/agents/code-review-subagent.md" ]
  [ ! -e "${HOME}/.config/opencode/agents" ]
  [ "$(grep -c '^model:' "${HOME}/.agents/agents/code-review-subagent.md")" -eq "$(grep -c '^model:' "$AGENT_SRC")" ]
  python3 -c "
import json, os
m = json.load(open(os.environ['MANIFEST']))
assert 'code-review-subagent' in m['agents'], m['agents']
"
}

@test "agents target: --dry-run previews and writes nothing" {
  run $INIT add code-review-subagent --target agents --yes --dry-run
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"destinations"'
  echo "$output" | grep -q '.agents'
  [ ! -e "${HOME}/.agents" ]
}

@test "update: shared-copy source mutation re-copies verbatim (no model injection)" {
  $INIT add code-review-subagent --target agents --yes --no-deps >/dev/null 2>&1
  cp "$AGENT_SRC" "${AGENT_SRC}.bats-bak"
  echo "bats shared marker" >> "$AGENT_SRC"
  run $INIT update
  mv "${AGENT_SRC}.bats-bak" "$AGENT_SRC"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 1"
  grep -q "bats shared marker" "${HOME}/.agents/agents/code-review-subagent.md"
  [ "$(grep -c '^model:' "${HOME}/.agents/agents/code-review-subagent.md")" -eq 0 ]
}

@test "remove: wipes opencode + claude + shared copies of a tri-target install" {
  $INIT add tdd-workflow-skill --yes >/dev/null 2>&1
  $INIT add tdd-workflow-skill --target claude --yes >/dev/null 2>&1
  $INIT add tdd-workflow-skill --target agents --yes >/dev/null 2>&1
  [ -d "${HOME}/.config/opencode/skills/tdd-workflow-skill" ]
  [ -d "${HOME}/.claude/skills/tdd-workflow-skill" ]
  [ -d "${HOME}/.agents/skills/tdd-workflow-skill" ]
  run $INIT remove tdd-workflow-skill
  [ "$status" -eq 0 ]
  [ ! -e "${HOME}/.config/opencode/skills/tdd-workflow-skill" ]
  [ ! -e "${HOME}/.claude/skills/tdd-workflow-skill" ]
  [ ! -e "${HOME}/.agents/skills/tdd-workflow-skill" ]
}

@test "agents target: invalid --target value dies listing all four" {
  run $INIT add tdd-workflow-skill --target bogus --yes
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "Use: opencode, claude, agents, or both."
}

@test "update: agents-target entry is idempotent without source mutation" {
  $INIT add code-review-subagent --target agents --yes --no-deps >/dev/null 2>&1
  run $INIT update
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 0 · unchanged 1"
}

@test "update: agents-only manifest produces zero HIDDEN advisory lines" {
  mkdir -p "${HOME}/.config/opencode"
  echo '{"permissions":[{"action":"skill","resource":"*","effect":"deny"}]}' > "${HOME}/.config/opencode/opencode.json"
  $INIT add tdd-workflow-skill --target agents --yes >/dev/null 2>&1
  run $INIT update
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "HIDDEN"
}

@test "update: unknown manifest target key is a warned no-op (never fallback dispatch)" {
  $INIT add tdd-workflow-skill --target agents --yes >/dev/null 2>&1
  python3 - "$MANIFEST" <<'EOF'
import json, os, sys
p = sys.argv[1]
m = json.load(open(p))
m["entries"]["tdd-workflow-skill"]["targets"]["bogus"] = "sha256:deadbeef"
json.dump(m, open(p, "w"), indent=2)
EOF
  run $INIT update
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "unknown install target 'bogus'"
  [ -f "${HOME}/.agents/skills/tdd-workflow-skill/SKILL.md" ]
}

@test "agents target: --project keeps note-and-downgrade (no ~/.agents write)" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT add tdd-workflow-skill --project "$TMP_PROJ" --target agents --yes
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "applies to user scope only"
  [ -d "$TMP_PROJ/.opencode/skills/tdd-workflow-skill" ]
  [ ! -e "${HOME}/.agents" ]
  rm -rf "$TMP_PROJ"
}
