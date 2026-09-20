#!/usr/bin/env bats

# Provider credential capture + auth.json seeding pins (#471). The identity
# step (setup_provider_credentials) resolves the chosen preset from
# provider-presets.json credential blocks, captures the key (env var headless,
# masked prompt interactive), seeds auth.json for EVERY auth_id via
# register_provider_auth (merge-never-clobber), and verifies via
# `opencode auth list` when opencode is installed.

SETUP_SH="deploy/setup.sh"
PRESETS="installer/provider-presets.json"

@test "presets_schema_remote_have_credential_local_do_not" {
  node -e '
    const pp = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    const presets = pp.presets || pp;
    for (const [name, p] of Object.entries(presets)) {
      if (!p.primary) continue;
      const remote = ["zai", "zai-custom", "anthropic", "openai", "openrouter"].includes(name);
      if (remote) {
        const c = p.credential;
        if (!c || !Array.isArray(c.auth_ids) || c.auth_ids.length === 0 || !c.env_var) {
          throw new Error(name + ": missing/invalid credential block");
        }
      } else if (p.credential) {
        throw new Error(name + ": local preset must not carry a credential block");
      }
    }
  ' "$PRESETS"
}

@test "zai_preset_lists_distinct_zai_and_zai_coding_plan_auth_ids" {
  node -e '
    const pp = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    const presets = pp.presets || pp;
    const ids = presets.zai.credential.auth_ids;
    if (!ids.includes("zai") || !ids.includes("zai-coding-plan")) {
      throw new Error("zai credential must seed BOTH zai and zai-coding-plan: " + ids);
    }
  ' "$PRESETS"
}

@test "register_provider_auth_merge_never_clobbers_existing_entries" {
  local d; d="$(mktemp -d)"
  mkdir -p "$d/.local/share/opencode"
  printf '{"existing_provider": {"type": "api", "key": "keep"}}' > "$d/.local/share/opencode/auth.json"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; register_provider_auth new-provider newkey" >/dev/null 2>&1
  node -e '
    const a = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    if (a.existing_provider.key !== "keep") throw new Error("clobbered existing entry");
    if (!a["new-provider"] || a["new-provider"].key !== "newkey") throw new Error("new entry missing");
  ' "$d/.local/share/opencode/auth.json"
  rm -rf "$d"
}

@test "zai_capture_seeds_both_distinct_auth_ids" {
  local d; d="$(mktemp -d)"
  bash -c "export HOME='$d'; export ZAI_API_KEY='testkey123'; source '$SETUP_SH' >/dev/null 2>&1
           DRY_RUN=false; AUTO_ACCEPT=true; PROVIDER=zai; setup_provider_credentials" >/dev/null 2>&1
  node -e '
    const a = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    if (!a.zai || a.zai.key !== "testkey123") throw new Error("zai id not seeded");
    if (!a["zai-coding-plan"] || a["zai-coding-plan"].key !== "testkey123") throw new Error("zai-coding-plan id not seeded");
  ' "$d/.local/share/opencode/auth.json"
  rm -rf "$d"
}

@test "oauth_preset_prints_hint_instead_of_prompting" {
  local d; d="$(mktemp -d)"
  run bash -c "export HOME='$d'; export ANTHROPIC_API_KEY=''; source '$SETUP_SH' >/dev/null 2>&1
           DRY_RUN=false; AUTO_ACCEPT=false; PROVIDER=anthropic; setup_provider_credentials" </dev/null
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"opencode auth login anthropic"* ]]
}

@test "headless_env_var_seeds_openrouter_credential" {
  local d; d="$(mktemp -d)"
  bash -c "export HOME='$d'; export OPENROUTER_API_KEY='or-key-1'; source '$SETUP_SH' >/dev/null 2>&1
           DRY_RUN=false; AUTO_ACCEPT=true; PROVIDER=openrouter; setup_provider_credentials" >/dev/null 2>&1
  node -e '
    const a = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    if (!a.openrouter || a.openrouter.key !== "or-key-1") throw new Error("openrouter not seeded from env");
  ' "$d/.local/share/opencode/auth.json"
  rm -rf "$d"
}

@test "verification_runs_via_opencode_when_installed" {
  local d; d="$(mktemp -d)"
  run bash -c "export HOME='$d'; export OPENROUTER_API_KEY='or-key-2'; source '$SETUP_SH' >/dev/null 2>&1
           DRY_RUN=false; AUTO_ACCEPT=true; PROVIDER=openrouter
           command_exists(){ return 0; }
           opencode(){ if [ \"\$1\" = auth ]; then echo 'Provider: openrouter'; fi; }
           setup_provider_credentials"
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"verified via"* ]]
}

@test "credentials_step_follows_provider_in_content_plans" {
  local d; d="$(mktemp -d)"
  for flags in "QUICK_SETUP=true" "MODELS_ONLY=true" "FORCE_FULL=1"; do
    run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; $flags; build_plan
        printf '%s\n' \"\${PLAN_STEPS[@]}\""
    [ "$status" -eq 0 ]
    local pi ci
    pi=$(echo "$output" | grep -n "|provider|" | cut -d: -f1)
    ci=$(echo "$output" | grep -n "|credentials|" | cut -d: -f1)
    [ -n "$pi" ]
    [ -n "$ci" ]
    [ "$ci" -eq "$((pi + 1))" ]
  done
  rm -rf "$d"
}
