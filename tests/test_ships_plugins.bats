#!/usr/bin/env bats

# Tests for shipsPlugins (#533): installing a ponytail skill also delivers the
# enforcement plugin (opencode-ponytail-scoped.ts + ponytail/ + ATTRIBUTION.md)
# to the target's opencode plugin dir; --no-deps and non-opencode targets skip
# with a notice. HOME is sandboxed so user-scope writes never touch the real one.

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
ADD="node ${REPO}/installer/init.mjs add"

setup() {
  export SANDBOX="$(mktemp -d)"
  export HOME="$SANDBOX"
  export TMP_PROJ="$(mktemp -d)"
  git -C "$TMP_PROJ" init -q
}
teardown() { rm -rf "$SANDBOX" "$TMP_PROJ"; }

@test "user-scope ponytail skill install ships plugin artifacts + manifest records them" {
  run $ADD ponytail-audit-skill --yes
  [ "$status" -eq 0 ]
  # the three artifacts landed under the sandboxed global plugin dir
  [ -f "$SANDBOX/.config/opencode/plugins/opencode-ponytail-scoped.ts" ]
  [ -f "$SANDBOX/.config/opencode/plugins/ponytail/SKILL.md" ]
  [ -f "$SANDBOX/.config/opencode/plugins/ponytail/instructions.cjs" ]
  [ -f "$SANDBOX/.config/opencode/plugins/ATTRIBUTION.md" ]
  # manifest lists them
  grep -q '"plugins"' "$SANDBOX/.config/opencode/.skill-manifest.json"
  grep -q 'opencode-ponytail-scoped.ts' "$SANDBOX/.config/opencode/.skill-manifest.json"
}

@test "user-scope install is idempotent (second run re-copies cleanly)" {
  run $ADD ponytail-audit-skill --yes
  [ "$status" -eq 0 ]
  run $ADD ponytail-review-skill --yes
  [ "$status" -eq 0 ]
  [ -f "$SANDBOX/.config/opencode/plugins/opencode-ponytail-scoped.ts" ]
}

@test "--no-deps skips plugin shipping" {
  run $ADD ponytail-audit-skill --yes --no-deps
  [ "$status" -eq 0 ]
  [ ! -e "$SANDBOX/.config/opencode/plugins" ]
}

@test "dry-run lists plugins without writing" {
  run $ADD ponytail-audit-skill --yes --dry-run
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"plugins"'
  echo "$output" | grep -q 'opencode-ponytail-scoped.ts'
  [ ! -e "$SANDBOX/.config/opencode/plugins" ]
}

@test "non-opencode user target (--target claude) prints notice, ships nothing" {
  run $ADD ponytail-audit-skill --yes --target claude
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "skipped for target 'claude'"
  [ ! -e "$SANDBOX/.config/opencode/plugins" ]
  [ ! -e "$SANDBOX/.claude/plugins" ]
}

@test "non-skill-plugin install ships no plugins (control)" {
  run $ADD unslop-skill --yes
  [ "$status" -eq 0 ]
  [ ! -e "$SANDBOX/.config/opencode/plugins" ]
}

@test "project-scope install ships plugins into .opencode/plugins/" {
  run $ADD ponytail-debt-skill --yes --project "$TMP_PROJ"
  [ "$status" -eq 0 ]
  [ -f "$TMP_PROJ/.opencode/plugins/opencode-ponytail-scoped.ts" ]
  [ -f "$TMP_PROJ/.opencode/plugins/ponytail/instructions.cjs" ]
  grep -q '"plugins"' "$TMP_PROJ/.opencode/.opencode-init.manifest.json"
}

@test "project-scope non-opencode target (--project --target kimi) prints notice, ships nothing" {
  run $ADD ponytail-debt-skill --yes --project "$TMP_PROJ" --target kimi
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "skipped for kimi project target"
  [ ! -e "$TMP_PROJ/.opencode/plugins" ]
  [ ! -e "$TMP_PROJ/.kimi-code/plugins" ]
}
