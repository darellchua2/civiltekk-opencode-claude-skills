#!/usr/bin/env bats

# Prune-verb tests (#610): `init.mjs prune` removes manifest-tracked entries
# whose names left installer/registry.json — the surgical --select convergence
# arm (Option B). Unlike `update --prune` (set-replace against the full
# catalog), live-but-unselected entries always survive and no re-copy arm
# runs. Dry-run is report-only (test_dry_run_leaks conventions).
#
# PATH SAFETY: the manifest path is resolved INSIDE each test (after setup()
# swaps HOME to TMP_HOME) — never at file-parse time.

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INIT="node ${REPO}/installer/init.mjs"

setup() {
  export TMP_HOME="$(mktemp -d)"
  export HOME="$TMP_HOME"
}
teardown() { rm -rf "$TMP_HOME"; }

manifest_path() {
  echo "$HOME/.config/opencode/.skill-manifest.json"
}

inject_zombie() {
  python3 - "$(manifest_path)" <<'PYEOF'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m["entries"]["zombie-skill"] = {"type": "skill", "targets": {"opencode": "deadbeef"}}
m.setdefault("skills", []).append("zombie-skill")
json.dump(m, open(p, "w"), indent=2)
PYEOF
}

@test "prune_verb_removes_registry_removed_and_keeps_live" {
  run bash -c "$INIT add civiltekk-git-commits-skill --yes"
  [ "$status" -eq 0 ]
  inject_zombie
  grep -q 'zombie-skill' "$(manifest_path)"
  run bash -c "$INIT prune"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "pruned 1 registry-removed entries: zombie-skill"
  [ ! -d "$HOME/.config/opencode/skills/zombie-skill" ]
  grep -q 'civiltekk-git-commits-skill' "$(manifest_path)"
  grep -q 'zombie-skill' "$(manifest_path)" && echo "zombie survived" && return 1 || return 0
}

@test "prune_verb_dry_run_reports_without_mutation" {
  run bash -c "$INIT add civiltekk-git-commits-skill --yes"
  [ "$status" -eq 0 ]
  inject_zombie
  before=$(cat "$(manifest_path)")
  run bash -c "$INIT prune --dry-run"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "registry-removed (present locally): zombie-skill"
  after=$(cat "$(manifest_path)")
  [ "$before" = "$after" ]
  [ -d "$HOME/.config/opencode/skills/civiltekk-git-commits-skill" ]
}

@test "prune_verb_performs_no_recopy" {
  # Option-B invariant: prune must never touch live entries' files, even when
  # their installed bytes drift from the registry (that is update's job).
  run bash -c "$INIT add civiltekk-git-commits-skill --yes"
  [ "$status" -eq 0 ]
  target="$HOME/.config/opencode/skills/civiltekk-git-commits-skill/SKILL.md"
  echo "# deliberately corrupted local bytes" >> "$target"
  before=$(sha256sum "$target" | cut -d' ' -f1)
  inject_zombie
  run bash -c "$INIT prune"
  [ "$status" -eq 0 ]
  after=$(sha256sum "$target" | cut -d' ' -f1)
  [ "$before" = "$after" ]
}
