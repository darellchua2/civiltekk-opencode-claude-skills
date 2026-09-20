#!/usr/bin/env bats

# models.dev regeneration + --check-catalog drift pins (#472). The regen
# script is byte-stable, preserves uncataloged prefixes, and refuses to drop
# known-catalog providers; the check mode warns on drift (warn-only) and
# fails only when the catalog itself is unavailable. Tests run offline via
# --catalog fixtures.

REGEN="deploy/regen-provider-models.mjs"
FIXTURE="tests/fixtures/models-dev-fixture.json"
TARGET="installer/provider-models.json"
SETUP_SH="deploy/setup.sh"

# Tests mutate the shipped provider-models.json — snapshot and restore around
# every test so a failed run never leaves the worktree drifted.
setup() {
  BACKUP="$(mktemp -d)/pm-backup-472.json"
  cp "$TARGET" "$BACKUP"
}

teardown() {
  cp "$BACKUP" "$TARGET"
  rm -rf "$(dirname "$BACKUP")"
}

setup_catalog_primed_target() {
  # A shipped file whose catalog-backed providers all exist in the fixture.
  node -e '
    const fs = require("fs");
    const shipped = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    shipped["zai-coding-plan"] = ["glm-5.3", "glm-5.3-flash"];
    shipped["anthropic"] = ["claude-opus-5", "claude-haiku-4-5", "claude-opus-4-8"];
    fs.writeFileSync(process.argv[1], JSON.stringify(shipped, null, 2) + "\n");
  ' "$TARGET"
}

@test "regen_matches_fixture_catalog_and_preserves_uncataloged" {
  setup_catalog_primed_target
  node "$REGEN" --catalog "$FIXTURE"
  node -e '
    const m = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    if (JSON.stringify(m["zai-coding-plan"]) !== JSON.stringify(["glm-5.3","glm-5.3-flash","glm-5.3-highspeed"])) throw new Error("zai-coding-plan not regenerated: " + m["zai-coding-plan"]);
    if (JSON.stringify(m["anthropic"]) !== JSON.stringify(["claude-haiku-4-5","claude-opus-5"])) throw new Error("anthropic not regenerated");
    if (JSON.stringify(m["zai-custom"]) !== JSON.stringify(["glm-5.3","glm-5.3-flash"])) throw new Error("zai-custom must be preserved verbatim");
    if (typeof m.$comment !== "string") throw new Error("$comment lost");
  ' "$TARGET"
}

@test "regen_is_byte_stable_on_second_run" {
  setup_catalog_primed_target
  node "$REGEN" --catalog "$FIXTURE"
  cp "$TARGET" /tmp/opencode/regen-first.json
  node "$REGEN" --catalog "$FIXTURE"
  cmp -s /tmp/opencode/regen-first.json "$TARGET"
  rm -f /tmp/opencode/regen-first.json
}

@test "regen_refuses_to_drop_known_catalog_provider_missing_upstream" {
  setup_catalog_primed_target
  # Fixture lacking anthropic (a KNOWN catalog provider) must hard-fail.
  local f; f="$(mktemp -d)/fixture.json"
  node -e '
    const fs = require("fs");
    const f = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    delete f.anthropic;
    fs.writeFileSync(process.argv[2], JSON.stringify(f, null, 2));
  ' "$FIXTURE" "$f"
  run node "$REGEN" --catalog "$f"
  rm -rf "$(dirname "$f")"
  [ "$status" -ne 0 ]
  [[ "$output" == *"anthropic"* ]]
}

@test "check_catalog_warns_on_induced_drift_and_exits_zero" {
  setup_catalog_primed_target
  run node "$REGEN" --check --catalog "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"glm-5.3-highspeed"* ]]
  [[ "$output" == *"claude-opus-4-8"* ]]
  [[ "$output" == *"[check-catalog]"* ]]
}

@test "check_catalog_green_after_fresh_regen" {
  setup_catalog_primed_target
  node "$REGEN" --catalog "$FIXTURE"
  run node "$REGEN" --check --catalog "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"matches the live models.dev catalog"* ]]
}

@test "check_catalog_fails_when_catalog_unavailable" {
  setup_catalog_primed_target
  run node "$REGEN" --check --catalog /tmp/opencode/nonexistent-catalog-472.json
  [ "$status" -ne 0 ]
}

@test "check_catalog_mode_registered_in_conflict_validator" {
  grep -q 'CHECK_CATALOG_ONLY" = true ] && modes+=("--check-catalog")' "$SETUP_SH"
  grep -q 'CHECK_CATALOG_ONLY" = true ] && packless+=("--check-catalog")' "$SETUP_SH"
}

@test "check_catalog_fatal_rule_nonfatal_branch_preserves_partial_catalog" {
  # The refined fatal rule's NON-firing branch (arch: guard-error-branches):
  # a catalog with <=1 known provider is partial-scope — the omitted known
  # provider is preserved verbatim and the regen exits 0 (never always-fatal).
  setup_catalog_primed_target
  local f; f="$(mktemp -d)/fixture.json"
  node -e '
    const fs = require("fs");
    const f = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    delete f.anthropic; delete f.openai; delete f.zai;
    fs.writeFileSync(process.argv[2], JSON.stringify(f, null, 2));
  ' "$FIXTURE" "$f"
  run node "$REGEN" --catalog "$f"
  rm -rf "$(dirname "$f")"
  [ "$status" -eq 0 ]
  node -e '
    const m = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    if (JSON.stringify(m.anthropic) !== JSON.stringify(["claude-opus-5", "claude-haiku-4-5", "claude-opus-4-8"])) throw new Error("anthropic not preserved verbatim: " + m.anthropic);
  ' "$TARGET"
}

@test "setup_sh_wires_check_catalog_into_plan_and_help" {
  grep -q 'CHECK_CATALOG_ONLY=false' "$SETUP_SH"
  grep -q -- '--check-catalog)' "$SETUP_SH"
  grep -q 'CHECK_CATALOG_ONLY" = true' "$SETUP_SH"
  grep -q 'regen-provider-models.mjs" --check' "$SETUP_SH"
  local help_count
  help_count=$(bash deploy/setup.sh --help 2>/dev/null | grep -ci "check-catalog")
  [ "$help_count" -ge 2 ]
}
