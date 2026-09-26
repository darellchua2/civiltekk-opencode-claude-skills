#!/usr/bin/env bats
# Tests for the `zcode` install target (#581): ZCode dirs ~/.zcode/{agents,skills}
# (USER SCOPE ONLY — the subagents Beta is user-level; project installs degrade),
# zcode-translate: synthesized name, permissions→tools/disallowedTools with the
# three deviations (subagent rules dropped; tools: omitted for skill-allow
# sources; steps:→maxTurns:), verbatim skills. HOME-isolated per test.

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

@test "zcode target: help lists zcode" {
  run $INIT --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q -- "--target zcode"
}

@test "zcode target: installs agent with zcode-translate (user scope, skill-allow source omits tools:)" {
  run $INIT add code-review-subagent --target zcode --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.zcode/agents/code-review-subagent.md"
  [ -f "$F" ]
  grep -q '^name: code-review-subagent' "$F"
  grep -q '^maxTurns: 30' "$F"
  ! grep -q '^model:' "$F"
  ! grep -q '^tools:' "$F"
  grep -q '^disallowedTools:' "$F"
  grep -q '  - Edit' "$F"
  grep -q '  - Bash' "$F"
  grep -q '^permissions:' "$F"
  # deviation (a): subagent rules drop with the nesting-ban warning
  echo "$output" | grep -q "cannot spawn subagents"
  # deviation (b): loud tools-omission warning on the skill-allow source
  echo "$output" | grep -q "tools: omitted"
}

@test "zcode target: non-skill source emits the positive tools: list" {
  run $INIT add image-analyzer-subagent --target zcode --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.zcode/agents/image-analyzer-subagent.md"
  grep -q '^tools:' "$F"
  grep -q '  - Read' "$F"
  grep -q '  - Bash' "$F"
  grep -q '  - WebFetch' "$F"
}

@test "zcode target: zcode overlay composed (binding heading present)" {
  run $INIT add code-review-subagent --target zcode --yes --no-deps
  [ "$status" -eq 0 ]
  grep -q "## Harness binding — ZCode" "${HOME}/.zcode/agents/code-review-subagent.md"
}

@test "zcode target: project add degrades with the no-project-destination note" {
  TMP_PROJ="$(mktemp -d)"
  run $INIT add code-review-subagent --project "$TMP_PROJ" --target zcode --yes --no-deps
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "has no project destination"
  [ ! -e "$TMP_PROJ/.zcode" ]
  rm -rf "$TMP_PROJ"
}

@test "zcode target: skills install verbatim to ~/.zcode/skills" {
  run $INIT add tdd-workflow-skill --target zcode --yes
  [ "$status" -eq 0 ]
  [ -f "${HOME}/.zcode/skills/tdd-workflow-skill/SKILL.md" ]
  [ ! -e "${HOME}/.config/opencode/skills/tdd-workflow-skill" ]
}

@test "zcode target: steps→maxTurns rename is frontmatter-scoped (body examples untouched)" {
  # Regression fixture: opencode-tooling-subagent teaches `steps: 5` inside a
  # fenced yaml body example (no steps: in its own frontmatter) — a whole-doc
  # rename would silently mutate the body (#581 review Major).
  run $INIT add opencode-tooling-subagent --target zcode --yes --no-deps
  [ "$status" -eq 0 ]
  local F="${HOME}/.zcode/agents/opencode-tooling-subagent.md"
  grep -q 'steps: 5' "$F"
  ! grep -q 'maxTurns' "$F"
  # Positive: an agent with frontmatter steps: gets the rename, body unaffected.
  run $INIT add code-review-subagent --target zcode --yes --no-deps
  [ "$status" -eq 0 ]
  [ "$(grep -c '^maxTurns: 30' "${HOME}/.zcode/agents/code-review-subagent.md")" -eq 1 ]
  ! grep -q '^steps:' "${HOME}/.zcode/agents/code-review-subagent.md"
}

@test "zcode target: remove wipes user-scope zcode copies" {
  $INIT add code-review-subagent --target zcode --yes --no-deps >/dev/null 2>&1
  [ -f "${HOME}/.zcode/agents/code-review-subagent.md" ]
  run $INIT remove code-review-subagent
  [ "$status" -eq 0 ]
  [ ! -e "${HOME}/.zcode/agents/code-review-subagent.md" ]
}

@test "zcode target: dry-run destination reports ~/.zcode" {
  run $INIT add code-review-subagent --target zcode --yes --dry-run
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '\.zcode"'
}
