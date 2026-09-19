#!/usr/bin/env bats

# Tests for the requiresSkills installer edge (#439, PLANS/PLAN-439.md).
# dependency-map.json skill->skill auto-install: `add <skill>` installs the
# declared prerequisite with a visible notice; --no-deps opts out; dry-run and
# the user-scope manifest list the auto-added skill; the map entry is pinned to
# tests/test_skill_isolation.bats HANDOFF_OWNER/HANDOFF_TARGET (source of truth
# per AGENTS.md §Skill Isolation Contract).

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INIT="node ${REPO}/installer/init.mjs"
DEPMAP="${REPO}/installer/dependency-map.json"
GUARD="${REPO}/tests/test_skill_isolation.bats"

MODIFIER="pptx-template-modifier-skill"
SLIDE="pptx-generate-slide-skill"

setup() {
  export TMP_HOME="$(mktemp -d)"
  export HOME="$TMP_HOME"
}
teardown() { rm -rf "$TMP_HOME"; }

@test "requires_skills_add_auto_installs_prerequisite_with_notice" {
  run bash -c "$INIT add $MODIFIER --yes 2>&1"
  [ "$status" -eq 0 ]
  # Visible notice naming the auto-added prerequisite (AC2) — assert the skill
  # name + the notice verb, not exact phrasing.
  echo "$output" | grep -q "also installing required skill: $SLIDE"
  [ -d "$HOME/.config/opencode/skills/$MODIFIER" ]
  [ -d "$HOME/.config/opencode/skills/$SLIDE" ]
}

@test "requires_skills_manifest_tracks_auto_added_skill" {
  $INIT add "$MODIFIER" --yes >/dev/null 2>&1
  python3 - "$HOME/.config/opencode/.skill-manifest.json" "$MODIFIER" "$SLIDE" <<'PYEOF'
import json, sys
m = json.load(open(sys.argv[1]))
for name in sys.argv[2:4]:
    assert name in m["skills"], f"{name} missing from manifest skills"
    assert m["entries"][name]["type"] == "skill", f"{name} entry type wrong"
print("ok")
PYEOF
}

@test "requires_skills_no_deps_installs_only_named_skill" {
  run bash -c "$INIT add $MODIFIER --no-deps --yes 2>&1"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "also installing" && return 1 || true
  [ -d "$HOME/.config/opencode/skills/$MODIFIER" ]
  [ ! -d "$HOME/.config/opencode/skills/$SLIDE" ]
}

@test "requires_skills_dry_run_lists_auto_added_skill" {
  run bash -c "$INIT add $MODIFIER --dry-run 2>/dev/null"
  [ "$status" -eq 0 ]
  echo "$output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for name in sys.argv[1:3]:
    assert name in d['skills'], f'{name} missing from dry-run skills'
" "$MODIFIER" "$SLIDE"
}

@test "requires_skills_map_entry_matches_isolation_guard_handoff_pair" {
  # AGENTS.md: HANDOFF_OWNER/HANDOFF_TARGET in the guard are the source of
  # truth — the installer edge must be exactly that pair, never drift.
  HANDOFF_OWNER="$(grep -oE '^HANDOFF_OWNER="[^"]+"' "$GUARD" | cut -d'"' -f2)"
  HANDOFF_TARGET="$(grep -oE '^HANDOFF_TARGET="[^"]+"' "$GUARD" | cut -d'"' -f2)"
  [ -n "$HANDOFF_OWNER" ] && [ -n "$HANDOFF_TARGET" ]
  python3 - "$DEPMAP" "$HANDOFF_OWNER" "$HANDOFF_TARGET" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
expected = {sys.argv[2]: [sys.argv[3]]}
got = d.get("requiresSkills", {})
assert got == expected, f"requiresSkills {got} != guard handoff pair {expected}"
print("ok")
PYEOF
}
