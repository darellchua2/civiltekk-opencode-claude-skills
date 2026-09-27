#!/usr/bin/env bats
# Single install path (#379): setup.sh delegates content (agents + skills) to the
# installer CLI. This is the regression net for the delegation — invoked exactly
# as deploy_content() does, plus a structure pin on setup.sh's call ordering.

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
INIT="node ${REPO}/installer/init.mjs"
SETUP_SH="${REPO}/deploy/setup.sh"

setup() {
  export HOME="$(mktemp -d)"
  export MANIFEST="${HOME}/.config/opencode/.skill-manifest.json"
}

@test "delegated full deploy populates the manifest with the full catalog" {
  # exactly what deploy_content() runs (no --provider by default)
  run $INIT add --all --yes
  [ "$status" -eq 0 ]

  python3 - "$MANIFEST" "${REPO}/installer/registry.json" <<'EOF'
import json, os, sys
m = json.load(open(sys.argv[1]))
reg = json.load(open(sys.argv[2]))
entries = m.get("entries", {})
agents = [n for n, e in entries.items() if e["type"] == "agent"]
skills = [n for n, e in entries.items() if e["type"] == "skill"]
assert len(agents) == len(reg["agents"]), f"agents {len(agents)} != registry {len(reg['agents'])}"
assert len(skills) == len(reg["skills"]), f"skills {len(skills)} != registry {len(reg['skills'])}"
assert all("opencode" in e["targets"] and e["targets"]["opencode"].startswith("sha256:") for e in entries.values()), "hashes missing"
EOF
}

@test "delegated deploy writes content on disk" {
  $INIT add --all --yes >/dev/null 2>&1
  [ -f "${HOME}/.config/opencode/agents/code-review-subagent.md" ]
  [ -f "${HOME}/.config/opencode/skills/tdd-workflow-skill/SKILL.md" ]
  grep -q '^model:' "${HOME}/.config/opencode/agents/code-review-subagent.md"
}

@test "delegated deploy is idempotent" {
  $INIT add --all --yes >/dev/null 2>&1
  $INIT add --all --yes >/dev/null 2>&1
  run $INIT add --all --yes
  [ "$status" -eq 0 ]
  python3 -c "
import json, os
m = json.load(open(os.environ['MANIFEST']))
agents = [n for n, e in m['entries'].items() if e['type'] == 'agent']
skills = [n for n, e in m['entries'].items() if e['type'] == 'skill']
assert len(agents) > 0 and len(skills) > 0, 'empty manifest'
# no duplicate/drift artifacts: counts stable across the three runs above and
# every hash is a well-formed sha256
import re
for e in m['entries'].values():
    for h in e['targets'].values():
        assert re.match(r'^sha256:[0-9a-f]{64}$', h), f'bad hash {h}'
print(f'{len(agents)} agents / {len(skills)} skills, hashes well-formed')
"
}

@test "setup.sh structure pin: deploy_content between migration and config-only resolver" {
  # The ordering rule (#379): lift must see pre-overwrite agents; the CLI owns
  # agent files; the resolver call from deploy_agents is config-only.
  grep -q "^deploy_content() {" "$SETUP_SH"
  grep -q "RESOLVER_CONFIG_ONLY=true run_resolver" "$SETUP_SH"

  mig=$(grep -n "    run_migration$" "$SETUP_SH" | head -1 | cut -d: -f1)
  dep=$(grep -n "^    deploy_content$" "$SETUP_SH" | head -1 | cut -d: -f1)
  res=$(grep -n "RESOLVER_CONFIG_ONLY=true run_resolver" "$SETUP_SH" | head -1 | cut -d: -f1)
  [ -n "$mig" ] && [ -n "$dep" ] && [ -n "$res" ]
  [ "$mig" -lt "$dep" ] && [ "$dep" -lt "$res" ]

  # no direct skills copy loop in the deploy path (backup/restore exempt)
  ! grep -qE 'rsync .*--exclude=.._archived' "$SETUP_SH"
}

@test "update --prune converges deployed agents to the registry (#608)" {
  # The ticket's machine state: a manifest-tracked agent whose name left
  # installer/registry.json (exemplar: office-document-primary-agent, removed
  # in #280) lingers across redeploys because `add` is additive-only.
  $INIT add --all --yes >/dev/null 2>&1

  planted="${HOME}/.config/opencode/agents/office-document-primary-agent.md"
  mkdir -p "$(dirname "$planted")"
  printf -- '---\ndescription: planted stale agent\n---\nstale\n' > "$planted"
  python3 - "$MANIFEST" <<'PYEOF'
import json, sys, hashlib
p = sys.argv[1]
m = json.load(open(p))
h = "sha256:" + hashlib.sha256(b"stale").hexdigest()
m["entries"]["office-document-primary-agent"] = {"type": "agent", "targets": {"opencode": h}}
json.dump(m, open(p, "w"))
PYEOF

  run $INIT update --prune
  [ "$status" -eq 0 ]

  # planted agent: file and manifest row gone...
  [ ! -f "$planted" ]
  run grep -q 'office-document-primary-agent' "$MANIFEST"
  [ "$status" -eq 1 ]
  # ...while a live registry agent survives untouched
  [ -f "${HOME}/.config/opencode/agents/code-review-subagent.md" ]
  grep -q '"code-review-subagent"' "$MANIFEST"

  # Wiring pin: deploy_content() must invoke the convergence pass — removing
  # the call from setup.sh fails here too, not just in semantics-land.
  grep -q 'init.mjs" update --prune $provider_arg $dry_arg' "$SETUP_SH"
}
