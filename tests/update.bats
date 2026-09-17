#!/usr/bin/env bats
# Tests for `opencode-skill update` (#379): manifest-driven drift upgrade.
# update compares WOULD-WRITE hashes (post model-injection / model-strip) vs the
# stored per-target hashes, so source mutations are detected and deterministic
# re-runs are not. Source files are mutated only between cp backup/restore pairs.

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INIT="node ${REPO}/installer/init.mjs"
SKILL_SRC="${REPO}/skills/tdd-workflow-skill/SKILL.md"

setup() {
  export HOME="$(mktemp -d)"
  export MANIFEST="${HOME}/.config/opencode/.skill-manifest.json"
  $INIT add tdd-workflow-skill --yes >/dev/null 2>&1
}

teardown() {
  [ -f "${SKILL_SRC}.bats-bak" ] && mv "${SKILL_SRC}.bats-bak" "$SKILL_SRC"
  rm -rf "$HOME"
}

@test "update: source mutation re-copies to recorded targets" {
  cp "$SKILL_SRC" "${SKILL_SRC}.bats-bak"
  echo "bats mutation marker" >> "$SKILL_SRC"
  run $INIT update
  mv "${SKILL_SRC}.bats-bak" "$SKILL_SRC"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 1"
  grep -q "bats mutation marker" "${HOME}/.config/opencode/skills/tdd-workflow-skill/SKILL.md"
}

@test "update: no mutation is idempotent (unchanged)" {
  run $INIT update
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "updated 0 · unchanged 1"
}

@test "update: --dry-run prints the plan and writes nothing" {
  cp "$SKILL_SRC" "${SKILL_SRC}.bats-bak"
  echo "bats dryrun marker" >> "$SKILL_SRC"
  run $INIT update --dry-run
  mv "${SKILL_SRC}.bats-bak" "$SKILL_SRC"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"updated"'
  echo "$output" | grep -q "tdd-workflow-skill"
  ! grep -q "bats dryrun marker" "${HOME}/.config/opencode/skills/tdd-workflow-skill/SKILL.md"
}

@test "update: registry-removed orphan reported, kept without --prune" {
  python3 - "$MANIFEST" <<'EOF'
import json, sys, os
p = sys.argv[1]
m = json.load(open(p))
m["entries"]["ghost-skill"] = {"type": "skill", "targets": {"opencode": "sha256:deadbeef"}}
m["skills"].append("ghost-skill")
json.dump(m, open(p, "w"), indent=2)
d = os.path.join(os.environ["HOME"], ".config/opencode/skills/ghost-skill")
os.makedirs(d, exist_ok=True)
open(os.path.join(d, "SKILL.md"), "w").write("x")
EOF
  run $INIT update
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "registry-removed"
  echo "$output" | grep -q "ghost-skill"
  [ -d "${HOME}/.config/opencode/skills/ghost-skill" ]
}

@test "update: --prune removes the orphan" {
  python3 - "$MANIFEST" <<'EOF'
import json, sys, os
p = sys.argv[1]
m = json.load(open(p))
m["entries"]["ghost-skill"] = {"type": "skill", "targets": {"opencode": "sha256:deadbeef"}}
m["skills"].append("ghost-skill")
json.dump(m, open(p, "w"), indent=2)
d = os.path.join(os.environ["HOME"], ".config/opencode/skills/ghost-skill")
os.makedirs(d, exist_ok=True)
open(os.path.join(d, "SKILL.md"), "w").write("x")
EOF
  run $INIT update --prune
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "pruned: ghost-skill"
  [ ! -d "${HOME}/.config/opencode/skills/ghost-skill" ]
}

@test "update: legacy manifest without entries upgrades cleanly" {
  python3 - "$MANIFEST" <<'EOF'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m.pop("entries", None)
json.dump(m, open(p, "w"), indent=2)
EOF
  run $INIT update
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "legacy manifest upgraded"
  python3 -c "
import json, os
m = json.load(open(os.environ['MANIFEST']))
assert 'tdd-workflow-skill' in m.get('entries', {}), 'entry missing after legacy upgrade'
"
}
