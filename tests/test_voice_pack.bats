#!/usr/bin/env bats

# Tests for the voice plugin pack (issue #356; v2 shapes, PLAN-374).
# Verifies pack existence + shape, cli.json merge correctness (plugin list
# merged by package name in v2 object form, other plugins preserved,
# opencode.json untouched by cli keys), the --tui-config v1-compat fallback
# (legacy [name, options] tuples), idempotent re-runs, the no-client-config
# degrade path (Docker), and validate_enable_pack acceptance. Peer to
# tests/test_docling_skill.bats.

PACK="deploy/packs/pack-voice.json"
MERGE_SCRIPT="deploy/merge-packs.mjs"
SETUP="deploy/setup.sh"

# =============================================================================
# Pack file shape
# =============================================================================

@test "voice_pack_file_exists_and_is_valid_json" {
  [ -f "$PACK" ]
  node -e "JSON.parse(require('fs').readFileSync('$PACK','utf8'))"
}

@test "voice_pack_declares_opencode_voice_plugin" {
  node -e "
    const p = JSON.parse(require('fs').readFileSync('$PACK','utf8'));
    const arr = p.cli && p.cli.plugins;
    if (!Array.isArray(arr) || arr.length !== 1) { console.error('expected cli.plugins with exactly one entry'); process.exit(1); }
    const entry = arr[0];
    if (entry.package !== '@renjfk/opencode-voice') { console.error('expected cli.plugins[0].package === @renjfk/opencode-voice'); process.exit(1); }
    const opts = entry.options || {};
    if (!opts.endpoint || !opts.model) { console.error('endpoint+model required'); process.exit(1); }
  "
}

@test "voice_pack_clobbers_session_rename_keybind" {
  node -e "
    const p = JSON.parse(require('fs').readFileSync('$PACK','utf8'));
    if (!p.cli || !p.cli.keybinds || p.cli.keybinds.session_rename !== 'none') { console.error('cli.keybinds.session_rename must be none (frees ctrl+r)'); process.exit(1); }
  "
}

# =============================================================================
# merge-packs cli.json merge semantics (v2 primary path)
# =============================================================================

@test "voice_pack_merges_into_client_config_preserving_other_plugins" {
  local dir
  dir="$(mktemp -d)"
  echo '{"mcp":{"servers":{"codegraph":{"disabled":false}}}}' > "$dir/opencode.json"
  echo '{"$schema":"https://opencode.ai/v2/cli.json","plugins":[{"package":"other-plugin","options":{}}]}' > "$dir/cli.json"
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --client-config "$dir/cli.json" --packs-dir deploy/packs --packs voice
  node -e "
    const cli = JSON.parse(require('fs').readFileSync('$dir/cli.json','utf8'));
    const names = cli.plugins.map((e) => e.package);
    if (!names.includes('other-plugin')) { console.error('other-plugin must be preserved'); process.exit(1); }
    if (!names.includes('@renjfk/opencode-voice')) { console.error('voice plugin must be appended'); process.exit(1); }
    if (cli.keybinds.session_rename !== 'none') { console.error('keybinds must merge'); process.exit(1); }
    const cfg = JSON.parse(require('fs').readFileSync('$dir/opencode.json','utf8'));
    if (cfg.cli || cfg.tui) { console.error('cli/tui keys must NOT leak into opencode.json'); process.exit(1); }
    if (cfg.mcp.servers.codegraph.disabled !== false) { console.error('opencode.json must stay intact'); process.exit(1); }
  "
  rm -rf "$dir"
}

@test "voice_pack_merge_is_idempotent" {
  local dir
  dir="$(mktemp -d)"
  echo '{"mcp":{"servers":{}}}' > "$dir/opencode.json"
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --client-config "$dir/cli.json" --packs-dir deploy/packs --packs voice >/dev/null
  local first
  first="$(cat "$dir/cli.json")"
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --client-config "$dir/cli.json" --packs-dir deploy/packs --packs voice >/dev/null
  [ "$(cat "$dir/cli.json")" = "$first" ]
  # second run must report no change
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --client-config "$dir/cli.json" --packs-dir deploy/packs --packs voice | grep -q "client config changed: no"
  rm -rf "$dir"
}

@test "voice_pack_merge_same_name_entry_replaced_not_duplicated" {
  local dir
  dir="$(mktemp -d)"
  echo '{"mcp":{"servers":{}}}' > "$dir/opencode.json"
  echo '{"plugins":[{"package":"@renjfk/opencode-voice","options":{"endpoint":"http://old","model":"old"}}]}' > "$dir/cli.json"
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --client-config "$dir/cli.json" --packs-dir deploy/packs --packs voice >/dev/null
  node -e "
    const cli = JSON.parse(require('fs').readFileSync('$dir/cli.json','utf8'));
    const voice = cli.plugins.filter((e) => e.package === '@renjfk/opencode-voice');
    if (voice.length !== 1) { console.error('expected exactly one voice entry, got ' + voice.length); process.exit(1); }
    if (voice[0].options.model !== 'llama3.2') { console.error('same-name entry must be replaced'); process.exit(1); }
  "
  rm -rf "$dir"
}

@test "voice_pack_tui_config_legacy_fallback_writes_tuples" {
  local dir
  dir="$(mktemp -d)"
  echo '{"mcp":{"servers":{}}}' > "$dir/opencode.json"
  echo '{"$schema":"https://opencode.ai/tui.json","plugin":[["other-plugin",{}]]}' > "$dir/tui.json"
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --tui-config "$dir/tui.json" --packs-dir deploy/packs --packs voice >/dev/null
  node -e "
    const tui = JSON.parse(require('fs').readFileSync('$dir/tui.json','utf8'));
    const names = tui.plugin.map((e) => e[0]);
    if (!names.includes('other-plugin')) { console.error('legacy tuple other-plugin must be preserved'); process.exit(1); }
    const voice = tui.plugin.filter((e) => e[0] === '@renjfk/opencode-voice');
    if (voice.length !== 1) { console.error('voice must append as exactly one legacy tuple'); process.exit(1); }
    if (!voice[0][1].endpoint || voice[0][1].model !== 'llama3.2') { console.error('tuple options must carry endpoint+model'); process.exit(1); }
    if (tui.keybinds.session_rename !== 'none') { console.error('keybinds must merge in legacy path too'); process.exit(1); }
    const cfg = JSON.parse(require('fs').readFileSync('$dir/opencode.json','utf8'));
    if (cfg.cli || cfg.tui) { console.error('cli keys must not leak into opencode.json'); process.exit(1); }
  "
  rm -rf "$dir"
}

@test "voice_pack_without_client_config_warns_and_exits_zero_docker_path" {
  local dir
  dir="$(mktemp -d)"
  echo '{"mcp":{"servers":{}}}' > "$dir/opencode.json"
  run node "$MERGE_SCRIPT" --config "$dir/opencode.json" --packs-dir deploy/packs --packs voice
  [ "$status" -eq 0 ]
  [[ "$output" == *"warning"* ]]
  [[ "$output" == *"--client-config"* ]]
  rm -rf "$dir"
}

@test "voice_pack_creates_client_config_when_missing_with_schema" {
  local dir
  dir="$(mktemp -d)"
  echo '{"mcp":{"servers":{}}}' > "$dir/opencode.json"
  node "$MERGE_SCRIPT" --config "$dir/opencode.json" --client-config "$dir/cli.json" --packs-dir deploy/packs --packs voice >/dev/null
  node -e "
    const cli = JSON.parse(require('fs').readFileSync('$dir/cli.json','utf8'));
    if (cli['\$schema'] !== 'https://opencode.ai/v2/cli.json') { console.error('v2 cli.json schema must be initialized'); process.exit(1); }
    if (cli.keybinds.session_rename !== 'none') { console.error('keybinds must be written'); process.exit(1); }
  "
  rm -rf "$dir"
}

# =============================================================================
# setup.sh integration surface
# =============================================================================

@test "validate_enable_pack_accepts_voice" {
  # validate_enable_pack exits non-zero for unknown packs; voice must pass.
  bash -c "set -e; source /dev/stdin <<'EOF'
ENABLE_PACK=\"voice\"
PACKS_DIR=\"deploy/packs\"
DEPLOY_DIR=\"deploy\"
log_info() { :; }
log_error() { echo \"\$1\" >&2; }
$(sed -n '/^validate_enable_pack()/,/^}/p' "$SETUP")
validate_enable_pack
EOF"
}

@test "setup_sh_help_lists_voice_pack" {
  grep -q "Plugin pack: voice" "$SETUP"
}

@test "setup_sh_run_pack_merger_passes_client_config" {
  grep -q -- '--client-config' "$SETUP"
  # the v1 --tui-config flag must not be passed by the installer anymore
  ! grep -q -- '--tui-config' "$SETUP"
}

@test "voice_install_suggests_backend_model_combination" {
  # recommendation logic must exist: compute_cap-derived arch + per-profile model
  grep -q "compute_cap" "$SETUP"
  grep -q "Suggested combination" "$SETUP"
  grep -q "ggml-large-v3-turbo-q5_0" "$SETUP"   # Metal + modern CUDA
  grep -q "ggml-medium-q5_0" "$SETUP"           # older CUDA
  grep -q "ggml-small-q5_1" "$SETUP"            # CPU-only
}

@test "voice_install_amd_ladder_rocm_vulkan" {
  # AMD paths: HIP build when ROCm present, Vulkan fallback, ROCm install assist
  grep -q "GGML_HIP=ON" "$SETUP"
  grep -q "GGML_VULKAN=ON" "$SETUP"
  grep -q "rocminfo" "$SETUP"
  grep -q "vulkaninfo" "$SETUP"
  grep -q "install_rocm_linux" "$SETUP"
  grep -q "repo.radeon.com" "$SETUP"
}

@test "voice_install_npu_and_openvino_paths" {
  # NPU paths: VitisAI (AMD Ryzen AI) + OpenVINO (Intel iGPU), plus sttEndpoint alternatives
  grep -q "WHISPER_VITISAI=1" "$SETUP"
  grep -q "xrt-smi" "$SETUP"
  grep -q "download-vitisai-model.sh" "$SETUP"
  grep -q "WHISPER_OPENVINO=ON" "$SETUP"
  grep -q "/dev/accel/accel0" "$SETUP"
  grep -q "convert-whisper-to-openvino.py" "$SETUP"
  grep -q "audio/transcriptions" "$SETUP"
}
