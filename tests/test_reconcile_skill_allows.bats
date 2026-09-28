#!/usr/bin/env bats

# Reconcile-mode tests (#625): `apply-skill-profile.mjs --reconcile-shipped`
# migrates a stale deployed config's skill-allow rules against the shipped
# config — add missing shipped allows, drop rules whose resource exists in
# NEITHER the repo skills dir NOR the deployed skills dir, preserve everything
# non-skill, keep deny-first ordering. Dry-run is report-only.

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
RECONCILE="node ${REPO}/deploy/apply-skill-profile.mjs"

SHIPPED=""
DEPLOYED=""
SKILLS_DIR=""
DEPLOYED_SKILLS=""

setup() {
  SHIPPED="$(mktemp -d)/shipped-opencode.json"
  DEPLOYED="$(mktemp -d)/deployed-opencode.json"
  SKILLS_DIR="$(mktemp -d)"
  DEPLOYED_SKILLS="$(mktemp -d)"
}

write_shipped() {
  cat > "$SHIPPED" <<'EOF'
{
  "model": "zai-coding-plan/glm-5.3",
  "mcp": { "servers": { "codegraph": { "enabled": true } } },
  "theme": "opencode",
  "permissions": [
    { "action": "skill", "resource": "*", "effect": "deny" },
    { "action": "skill", "resource": "civiltekk-new-skill", "effect": "allow" },
    { "action": "agent", "resource": "code-review-subagent", "effect": "allow" }
  ]
}
EOF
}

write_deployed() {
  cat > "$DEPLOYED" <<'EOF'
{
  "model": "custom-model-x",
  "mcp": { "servers": { "custom-server": { "enabled": true } } },
  "theme": "user-dark",
  "permissions": [
    { "action": "skill", "resource": "*", "effect": "deny" },
    { "action": "skill", "resource": "old-skill", "effect": "allow" },
    { "action": "skill", "resource": "user-custom-skill", "effect": "allow" },
    { "action": "agent", "resource": "my-own-agent", "effect": "allow" }
  ]
}
EOF
  mkdir -p "$DEPLOYED_SKILLS/user-custom-skill"
}

@test "reconcile_adds_shipped_drops_dead_keeps_custom_and_non_skill" {
  write_shipped
  write_deployed
  mkdir -p "$SKILLS_DIR/civiltekk-new-skill"
  run bash -c "$RECONCILE --reconcile-shipped '$SHIPPED' --config '$DEPLOYED' --skills-dir '$SKILLS_DIR' --deployed-skills-dir '$DEPLOYED_SKILLS'"
  [ "$status" -eq 0 ]
  python3 - "$DEPLOYED" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
perm = d["permissions"]
# house shape (matches apply-skill-profile lean): [non-skill rules..., deny, ...allows]
deny_idx = next(i for i, r in enumerate(perm) if r.get("action") == "skill" and r["resource"] == "*")
first_allow_idx = next(i for i, r in enumerate(perm) if r.get("action") == "skill" and r.get("resource") != "*" and r.get("effect") == "allow")
assert deny_idx < first_allow_idx, "deny rule must precede all skill allows (last-match-wins)"
allows = [r["resource"] for r in perm if r.get("action") == "skill" and r.get("effect") == "allow" and r["resource"] != "*"]
assert "civiltekk-new-skill" in allows, "shipped allow not added"
assert "user-custom-skill" in allows, "custom (deployed-dir) allow dropped"
assert "old-skill" not in allows, "dead allow survived"
# non-skill preserved
assert d["model"] == "custom-model-x"
assert d["theme"] == "user-dark"
assert "custom-server" in d["mcp"]["servers"]
assert any(r.get("resource") == "my-own-agent" for r in perm), "agent rule dropped"
print("ok")
PYEOF
}

@test "reconcile_dry_run_reports_without_mutation" {
  write_shipped
  write_deployed
  mkdir -p "$SKILLS_DIR/civiltekk-new-skill"
  before=$(cat "$DEPLOYED")
  run bash -c "$RECONCILE --reconcile-shipped '$SHIPPED' --config '$DEPLOYED' --skills-dir '$SKILLS_DIR' --deployed-skills-dir '$DEPLOYED_SKILLS' --dry-run"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "would add 1"
  echo "$output" | grep -q "would drop 1"
  after=$(cat "$DEPLOYED")
  [ "$before" = "$after" ]
}

@test "reconcile_then_lean_applies_cleanly" {
  write_shipped
  write_deployed
  mkdir -p "$SKILLS_DIR/civiltekk-new-skill"
  run bash -c "$RECONCILE --reconcile-shipped '$SHIPPED' --config '$DEPLOYED' --skills-dir '$SKILLS_DIR' --deployed-skills-dir '$DEPLOYED_SKILLS'"
  [ "$status" -eq 0 ]
  # the shipped config's lean list must now resolve against the reconciled config
  python3 - "$SHIPPED" "$DEPLOYED" <<'PYEOF'
import json, sys
shipped = json.load(open(sys.argv[1]))
deployed = json.load(open(sys.argv[2]))
shipped_allows = {r["resource"] for r in shipped["permissions"] if r.get("action") == "skill" and r.get("effect") == "allow" and r["resource"] != "*"}
deployed_allows = {r["resource"] for r in deployed["permissions"] if r.get("action") == "skill" and r.get("effect") == "allow" and r["resource"] != "*"}
missing = shipped_allows - deployed_allows
assert not missing, f"lean keys still missing after reconcile: {missing}"
print("ok")
PYEOF
}
