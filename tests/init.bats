#!/usr/bin/env bats

# Tests for deploy/init.mjs (opencode-init) — the project-scoped selective installer.
# Covers the flag path (primary contract); the interactive TUI is not tested here
# (needs a real TTY). See PLANS/PLAN-GIT-286 Phase 5.4.

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INIT="node ${REPO}/deploy/init.mjs"
REG="${REPO}/deploy/registry.json"
OC="${REPO}/opencode_app/opencode.json"

# JSON helper: extract a value/length via python3 (already a setup.sh dependency).
jq_len() { python3 -c "import sys,json; print(len(json.load(sys.stdin)))"; }
jq_get() { python3 -c "import sys,json; d=json.load(sys.stdin); print($1)"; }

setup() {
  export TMP_PROJ="$(mktemp -d)"
  git -C "$TMP_PROJ" init -q
}
teardown() { rm -rf "$TMP_PROJ"; }

@test "registry.json exists with correct agent/skill counts" {
  [ -f "$REG" ]
  agents=$(jq_get "len(d['agents'])" < "$REG")
  skills=$(jq_get "len(d['skills'])" < "$REG")
  echo "agents=$agents skills=$skills" >&3
  # Count-agnostic: registry must match disk (excludes _archived). BT-157.
  disk_agents=$(find "${REPO}/opencode_app/.opencode/agents" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  disk_skills=$(find "${REPO}/opencode_app/.opencode/skills" -name 'SKILL.md' -not -path '*/_archived/*' 2>/dev/null | wc -l | tr -d ' ')
  [ "$agents" = "$disk_agents" ]
  [ "$skills" = "$disk_skills" ]
}

@test "--list agents is valid JSON matching registry count" {
  count=$($INIT --list agents 2>/dev/null | jq_len)
  [ "$count" = "$(jq_get "len(d['agents'])" < "$REG")" ]
}

@test "--list agents --category review filters to reviewers" {
  count=$($INIT --list agents --category review 2>/dev/null | jq_len)
  [ "$count" = "3" ]
}

@test "--list skills is valid JSON matching registry count" {
  count=$($INIT --list skills 2>/dev/null | jq_len)
  [ "$count" = "$(jq_get "len(d['skills'])" < "$REG")" ]
}

@test "--list categories is valid non-empty JSON" {
  count=$($INIT --list categories 2>/dev/null | jq_len)
  [ "$count" -gt 10 ]
}

@test "--list presets shows all 9 presets" {
  count=$($INIT --list presets 2>/dev/null | jq_len)
  [ "$count" = "9" ]
}

@test "--describe code-review-subagent returns skills+delegates+modelAvailable" {
  out=$($INIT --describe code-review-subagent 2>/dev/null)
  skills=$(echo "$out" | jq_get "len(d['requiresSkills'])")
  delegates=$(echo "$out" | jq_get "len(d['delegatesTo'])")
  avail=$(echo "$out" | jq_get "d['modelAvailable']")
  echo "skills=$skills delegates=$delegates avail=$avail" >&3
  [ "$skills" = "17" ]
  [ "$delegates" -ge 4 ]
  [ "$avail" = "True" ]
}

@test "--expand review resolves transitive closure (4 agents incl. image-analyzer)" {
  agents=$($INIT --expand review 2>/dev/null | jq_get "len(d['agents'])")
  has_img=$($INIT --expand review 2>/dev/null | jq_get "'image-analyzer-subagent' in d['agents']")
  echo "agents=$agents has_image-analyzer=$has_img" >&3
  [ "$agents" = "4" ]
  [ "$has_img" = "True" ]
}

@test "install review --yes lands exactly 4 agents + 31 skills + codegraph (resolver deps)" {
  run $INIT --project "$TMP_PROJ" --preset review --yes
  [ "$status" -eq 0 ]
  agent_files=$(ls "$TMP_PROJ/.opencode/agents/" | wc -l)
  skill_dirs=$(ls "$TMP_PROJ/.opencode/skills/" | wc -l)
  [ "$agent_files" -eq 4 ]
  [ "$skill_dirs" -eq 31 ]
}

@test "each installed agent has a model: frontmatter line" {
  $INIT --project "$TMP_PROJ" --preset review --yes >/dev/null 2>&1
  grep -q "^model:" "$TMP_PROJ/.opencode/agents/code-review-subagent.md"
}

@test "generated opencode.json is v2-shaped: skill deny-all first + scoped subagent permissions + builtins" {
  $INIT --project "$TMP_PROJ" --preset review --yes >/dev/null 2>&1
  python3 -c "
import json
d=json.load(open('$TMP_PROJ/.opencode/opencode.json'))
# top-level permissions: skill deny-all must be the FIRST rule (v2 last-match-wins)
p=d['permissions']
assert p[0]=={'action':'skill','resource':'*','effect':'deny'}, 'skill *:deny must be first, got '+json.dumps(p[0])
assert any(r.get('resource')=='reviewer-baseline-skill' and r.get('effect')=='allow' for r in p), 'review preset must allow reviewer-baseline-skill'
# scoped subagent permissions: deny-all FIRST, then per-agent allows
sub=[r for r in d['agents']['build']['permissions'] if r['action']=='subagent']
assert sub[0]=={'action':'subagent','resource':'*','effect':'deny'}, 'subagent *:deny must be first'
assert any(r['resource']=='code-review-subagent' and r['effect']=='allow' for r in sub), 'missing code-review-subagent subagent allow'
assert set(['build','plan','explore','general']).issubset(d['agents']), 'missing builtin agent blocks'
print('ok')"
}

@test "--dry-run writes nothing into the project" {
  $INIT --project "$TMP_PROJ" --preset core --yes --dry-run >/dev/null 2>&1
  [ ! -d "$TMP_PROJ/.opencode" ]
}

@test "non-TTY without --yes exits non-zero" {
  run $INIT --project "$TMP_PROJ" --preset core
  [ "$status" -ne 0 ]
}

@test "re-run install is idempotent (no error, same counts)" {
  $INIT --project "$TMP_PROJ" --preset review --yes >/dev/null 2>&1
  run $INIT --project "$TMP_PROJ" --preset review --yes
  [ "$status" -eq 0 ]
  agent_files=$(ls "$TMP_PROJ/.opencode/agents/" | wc -l)
  [ "$agent_files" -eq 4 ]
}

@test "--prune removes previously-installed entries absent from the new set" {
  $INIT --project "$TMP_PROJ" --preset review --yes >/dev/null 2>&1
  before=$(ls "$TMP_PROJ/.opencode/agents/" | wc -l)
  [ "$before" -eq 4 ]
  # switch to docs (disjoint agents) with --prune
  $INIT --project "$TMP_PROJ" --preset docs --yes --prune >/dev/null 2>&1
  # code-review-subagent should be gone (not in docs closure)
  [ ! -f "$TMP_PROJ/.opencode/agents/code-review-subagent.md" ]
}

@test "manifest is written and lists installed agents/skills" {
  $INIT --project "$TMP_PROJ" --preset core --yes >/dev/null 2>&1
  [ -f "$TMP_PROJ/.opencode/.opencode-init.manifest.json" ]
  m_agents=$(jq_get "len(d['agents'])" < "$TMP_PROJ/.opencode/.opencode-init.manifest.json")
  [ "$m_agents" -ge 1 ]
}

@test "clean-slate warning fires when ~/.config/opencode/agents is non-empty" {
  # This machine has a global deploy (51 agents). The summary (stderr) must mention it.
  run bash -c "$INIT --project '$TMP_PROJ' --preset core --dry-run 2>&1 >/dev/null"
  echo "$output" | grep -qi "GLOBAL DEPLOY DETECTED"
}
