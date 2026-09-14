#!/usr/bin/env bats

# Tests for MCP provider pack permission rules (issue #370; v2 shapes, PLAN-374).
# All MCP packs must flip server state via `mcp.servers.<name>.disabled: false`
# and permissions via `permissions` array rules ({action, resource, effect}),
# never the v1 `enabled` flag, the v1 root `permission` map, the deprecated
# top-level `tools` map, or the inert nested `permission.tool` key. Peer to
# tests/test_voice_pack.bats (cli-only pack — intentionally NOT covered here).

MERGE_SCRIPT="deploy/merge-packs.mjs"
SETUP="deploy/setup.sh"
SETUP_PS1="deploy/setup.ps1"

# pack-name:server-keys pairs (explicit enumeration — no dir glob: voice is
# tui-only and legitimately carries no permission key)
PACK_SERVERS="markitdown:markitdown docling:docling chrome-devtools:chrome-devtools nextjs:next-devtools autodesk:autodesk-revit,autodesk-model-data,autodesk-fusion,autodesk-help"

# =============================================================================
# Pack file shape (all 5 MCP packs)
# =============================================================================

@test "all_five_mcp_packs_exist_and_are_valid_json" {
  for entry in $PACK_SERVERS; do
    pack="${entry%%:*}"
    f="deploy/packs/pack-${pack}.json"
    [ -f "$f" ]
    node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))"
  done
}

@test "mcp_packs_use_v2_permissions_array_rules" {
  for entry in $PACK_SERVERS; do
    pack="${entry%%:*}"
    node -e "
      const p = JSON.parse(require('fs').readFileSync('deploy/packs/pack-${pack}.json','utf8'));
      const keys = Object.keys(p);
      if (keys[0] !== '\$comment') { console.error('${pack}: \$comment must be first key (merge-packs stripJsonComments strips whole-line entries only)'); process.exit(1); }
      if (p.tools !== undefined) { console.error('${pack}: top-level tools is deprecated'); process.exit(1); }
      if (p.permission !== undefined) { console.error('${pack}: v1 root permission map is dead in v2 — use permissions array'); process.exit(1); }
      if (!Array.isArray(p.permissions) || p.permissions.length === 0) { console.error('${pack}: permissions array required'); process.exit(1); }
      for (const r of p.permissions) {
        if (typeof r.action !== 'string' || !r.action.endsWith('*')) { console.error('${pack}: rule action ' + JSON.stringify(r.action) + ' must be a wildcard pattern'); process.exit(1); }
        if (r.effect !== 'allow') { console.error('${pack}: rule effect must be \"allow\" (got ' + JSON.stringify(r.effect) + ')'); process.exit(1); }
        if (typeof r.resource !== 'string') { console.error('${pack}: rule resource must be a string'); process.exit(1); }
      }
    "
  done
}

@test "mcp_packs_ship_servers_with_disabled_false" {
  for entry in $PACK_SERVERS; do
    pack="${entry%%:*}"
    servers="${entry#*:}"
    node -e "
      const p = JSON.parse(require('fs').readFileSync('deploy/packs/pack-${pack}.json','utf8'));
      const want = '${servers}'.split(',');
      for (const s of want) {
        const def = p.mcp && p.mcp.servers && p.mcp.servers[s];
        if (!def) { console.error('${pack}: missing mcp.servers.' + s); process.exit(1); }
        if (def.disabled !== false) { console.error('${pack}: mcp.servers.' + s + '.disabled must be false'); process.exit(1); }
        if (def.enabled !== undefined) { console.error('${pack}: v1 enabled key is dead in v2 (mcp.servers.' + s + ')'); process.exit(1); }
      }
    "
  done
}

# =============================================================================
# merge-packs semantics: pack allow flips a v2 deny rule in place (the #370 bug class)
# =============================================================================

@test "pack_merge_flips_disabled_and_deny_rule_in_place" {
  local dir
  dir="$(mktemp -d)"
  cat > "$dir/opencode.json" <<'EOF'
{
  "mcp": { "servers": { "markitdown": { "type": "local", "command": ["markitdown-local-mcp"], "disabled": true } } },
  "permissions": [
    { "action": "codegraph*", "resource": "*", "effect": "deny" },
    { "action": "markitdown*", "resource": "*", "effect": "deny" }
  ]
}
EOF
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --packs-dir deploy/packs --packs markitdown >/dev/null
  node -e "
    const c = JSON.parse(require('fs').readFileSync('$dir/opencode.json','utf8'));
    if (c.mcp.servers.markitdown.disabled !== false) { console.error('disabled must flip to false'); process.exit(1); }
    const rules = c.permissions.filter((r) => r.action === 'markitdown*');
    if (rules.length !== 1) { console.error('no duplicate rules allowed, got ' + rules.length); process.exit(1); }
    if (rules[0].effect !== 'allow') { console.error('deny rule must flip to allow, got ' + JSON.stringify(rules[0])); process.exit(1); }
    if (c.permissions[0].action !== 'codegraph*') { console.error('rule order must be preserved (in-place replace)'); process.exit(1); }
    if (c.permissions.length !== 2) { console.error('array length must be unchanged, got ' + c.permissions.length); process.exit(1); }
  "
  rm -rf "$dir"
}

@test "pack_merge_preserves_unrelated_permission_rules" {
  local dir
  dir="$(mktemp -d)"
  cat > "$dir/opencode.json" <<'EOF'
{
  "mcp": { "servers": {} },
  "permissions": [
    { "action": "codegraph*", "resource": "*", "effect": "allow" },
    { "action": "docling*", "resource": "*", "effect": "deny" },
    { "action": "read", "resource": "mcp:*", "effect": "deny" }
  ]
}
EOF
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --packs-dir deploy/packs --packs markitdown >/dev/null
  node -e "
    const c = JSON.parse(require('fs').readFileSync('$dir/opencode.json','utf8'));
    const byAction = (a) => c.permissions.find((r) => r.action === a);
    if (!byAction('codegraph*') || byAction('codegraph*').effect !== 'allow') { console.error('unrelated allow must survive'); process.exit(1); }
    if (!byAction('docling*') || byAction('docling*').effect !== 'deny') { console.error('unrelated deny must survive'); process.exit(1); }
    const rd = byAction('read');
    if (!rd || rd.resource !== 'mcp:*' || rd.effect !== 'deny') { console.error('distinct-resource rule must survive'); process.exit(1); }
    if (c.permissions.length !== 4) { console.error('markitdown allow must be appended (4 rules), got ' + c.permissions.length); process.exit(1); }
  "
  rm -rf "$dir"
}

# =============================================================================
# Install-on-enable surface (setup.sh + setup.ps1 mirror)
# =============================================================================

@test "setup_sh_installer_has_installed_check" {
  grep -q 'pip show markitdown-local-mcp' "$SETUP"
}

@test "setup_sh_run_pack_merger_gates_install_on_enable_pack" {
  # hook must be dry-run-safe and keyed to the markitdown pack
  grep -q 'grep -qw "markitdown"' "$SETUP"
  grep -q 'install_local_mcp_launchers' "$SETUP"
  local hook
  hook="$(sed -n '/run_pack_merger()/,/^}/p' "$SETUP" | grep -A2 'grep -qw "markitdown"')"
  [[ "$hook" == *'DRY_RUN'* ]]
}

@test "setup_ps1_mirrors_rc_gated_install_hook" {
  grep -q 'mergeRc = \$LASTEXITCODE' "$SETUP_PS1"
  # EnablePack regex gate: '(^|,)markitdown(,|$)'
  grep -qF ',)markitdown(,' "$SETUP_PS1"
  grep -q 'Install-LocalMcpLaunchers' "$SETUP_PS1"
  grep -q 'pip show markitdown-local-mcp' "$SETUP_PS1"
}

@test "installer_has_pep668_break_system_packages_fallback" {
  # Debian 12+/Ubuntu 23.04+ block plain `pip install --user` (PEP 668);
  # the installer must detect and retry with --break-system-packages.
  grep -q 'externally-managed-environment' "$SETUP"
  grep -q -- '--break-system-packages' "$SETUP"
  grep -q 'externally-managed-environment' "$SETUP_PS1"
  grep -q -- '--break-system-packages' "$SETUP_PS1"
}

@test "setup_ps1_hook_resets_lastexitcode_for_caller" {
  # Invoke-PackMerger's install hook + Install-LocalMcpLaunchers early returns
  # must reset $global:LASTEXITCODE = 0 (best-effort) — the caller checks it
  # right after (Invoke-DeployAgents 'Provider-pack application failed').
  local fn
  fn="$(sed -n '/function Invoke-PackMerger/,/^}/p' "$SETUP_PS1")"
  [[ "$fn" == *'Install-LocalMcpLaunchers'* ]]
  [[ "$fn" == *'$global:LASTEXITCODE = 0'* ]]
  local inst
  inst="$(sed -n '/function Install-LocalMcpLaunchers/,/^}/p' "$SETUP_PS1")"
  [ "$(grep -c 'global:LASTEXITCODE = 0' <<<"$inst")" -ge 3 ]
}

@test "no_doc_teaches_dead_permission_keys" {
  # Class regression guard (#269, #310, #370): no doc may instruct users to
  # write the dead keys (nested permission.tool, legacy top-level tools).
  # Covers the skills/agents tree, repo-root docs, and the Dockerfile.
  # markitdown-mcp-skill/SKILL.md is whitelisted — it carries the explanatory
  # migration note.
  local hits
  hits="$(grep -rnE 'permission\.tool|tools\."|tools\["|"tools"[[:space:]]*:|`tools` block|`tools` map|tools\.<ns>|`tools\.\*`' \
    --include='*.md' skills agents MIGRATION.md README.md deploy/.AGENTS.md 2>/dev/null \
    | grep -v 'skills/markitdown-mcp-skill/SKILL.md' || true)"
  hits+="
$(grep -nE 'permission\.tool|tools\."|tools\["|"tools"[[:space:]]*:|`tools` block|`tools` map|tools\.<ns>|`tools\.\*`' \
    opencode_app/Dockerfile 2>/dev/null || true)"
  if [ -n "${hits//[[:space:]]/}" ]; then echo "$hits" >&2; fi
  [ -z "${hits//[[:space:]]/}" ]
}
