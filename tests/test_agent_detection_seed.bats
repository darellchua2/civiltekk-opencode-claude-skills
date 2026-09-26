#!/usr/bin/env bats

# #573 pins: coding-agent detection + Z.AI key seeding into pi/codex.
# Style follows test_dry_run_leaks.bats — temp HOME, PATH stubs, one
# assertion concern per @test (never &&-chained), plain grep (CI images
# lack ripgrep). Positive controls ride the real-run tests so an over-gated
# dry-run can't silently no-op the feature.

SETUP_SH="deploy/setup.sh"
SEED_MJS="deploy/seed-pi-provider.mjs"

# Shared harness: temp HOME + stubbed pi/codex that only need to exist.
seed_env() {
  local d="$1" stub="${2:-true}"
  mkdir -p "$d/bin"
  if [ "$stub" = true ]; then
    printf '#!/bin/sh\nexit 0\n' > "$d/bin/pi"
    printf '#!/bin/sh\nexit 0\n' > "$d/bin/codex"
    chmod +x "$d/bin/pi" "$d/bin/codex"
  fi
}

@test "detection_lists_all_six_agents" {
  local d
  d="$(mktemp -d)"
  HOME="$d" PATH="$d/emptybin:$PATH" bash -c "source '$SETUP_SH' >/dev/null 2>&1; detect_installed_agents" 2>/dev/null | grep -cE '^  [✓✗] (opencode|pi|codex|claude|kimi|kilo): '
  rm -rf "$d"
}

@test "detection_config_dir_fallback_reports_agent_without_binary" {
  local d
  d="$(mktemp -d)"
  mkdir -p "$d/.pi/agent" "$d/.codex"
  HOME="$d" PATH="$d/emptybin:$PATH" bash -c "source '$SETUP_SH' >/dev/null 2>&1; detect_installed_agents >/dev/null; echo \"PI=\$PI_INSTALLED CODEX=\$CODEX_INSTALLED\"" 2>/dev/null | grep -q "PI=true CODEX=true"
  rm -rf "$d"
}

@test "pi_seed_writes_provider_and_preserves_sibling" {
  local d
  d="$(mktemp -d)"
  seed_env "$d"
  mkdir -p "$d/.pi/agent"
  printf '{"providers":{"openrouter":{"baseUrl":"https://openrouter.ai/api/v1","apiKey":"$OR_KEY"}}}' > "$d/.pi/agent/models.json"
  HOME="$d" PATH="$d/bin:$PATH" bash -c "source '$SETUP_SH' >/dev/null 2>&1; PI_INSTALLED=true; CODEX_INSTALLED=false; ZAI_API_KEY=fakekey1234567890; seed_pi_provider" >/dev/null 2>&1
  grep -qF '"apiKey": "$ZAI_API_KEY"' "$d/.pi/agent/models.json"
  grep -qF '"api": "openai-completions"' "$d/.pi/agent/models.json"
  grep -qF '"baseUrl": "https://api.z.ai/api/paas/v4"' "$d/.pi/agent/models.json"
  grep -qF '"apiKey": "$OR_KEY"' "$d/.pi/agent/models.json"
  rm -rf "$d"
}

@test "pi_absent_seed_is_noop_no_write" {
  local d
  d="$(mktemp -d)"
  seed_env "$d"
  HOME="$d" PATH="$d/bin:$PATH" bash -c "source '$SETUP_SH' >/dev/null 2>&1; PI_INSTALLED=false; ZAI_API_KEY=fakekey1234567890; seed_pi_provider" >/dev/null 2>&1
  [ ! -d "$d/.pi" ]
  rm -rf "$d"
}

@test "codex_absent_seed_is_noop_no_write" {
  local d
  d="$(mktemp -d)"
  seed_env "$d"
  HOME="$d" PATH="$d/bin:$PATH" bash -c "source '$SETUP_SH' >/dev/null 2>&1; CODEX_INSTALLED=false; ZAI_API_KEY=fakekey1234567890; seed_codex_provider" >/dev/null 2>&1
  [ ! -d "$d/.codex" ]
  rm -rf "$d"
}

@test "dry_run_seeds_write_nothing" {
  local d
  d="$(mktemp -d)"
  seed_env "$d"
  HOME="$d" PATH="$d/bin:$PATH" bash -c "source '$SETUP_SH' >/dev/null 2>&1; PI_INSTALLED=true; CODEX_INSTALLED=true; ZAI_API_KEY=fakekey1234567890; DRY_RUN=true; seed_agent_keys" >/dev/null 2>&1
  [ ! -d "$d/.pi" ]
  [ ! -d "$d/.codex" ]
  rm -rf "$d"
}

@test "codex_toml_appends_once_preserves_user_content" {
  local d
  d="$(mktemp -d)"
  seed_env "$d"
  mkdir -p "$d/.codex"
  printf 'model = "gpt-5.4"\n\n[profiles.fast]\nmodel = "gpt-5-mini"\n' > "$d/.codex/config.toml"
  HOME="$d" PATH="$d/bin:$PATH" bash -c "source '$SETUP_SH' >/dev/null 2>&1; CODEX_INSTALLED=true; PI_INSTALLED=false; ZAI_API_KEY=fakekey1234567890; seed_codex_provider" >/dev/null 2>&1
  HOME="$d" PATH="$d/bin:$PATH" bash -c "source '$SETUP_SH' >/dev/null 2>&1; CODEX_INSTALLED=true; PI_INSTALLED=false; ZAI_API_KEY=fakekey1234567890; seed_codex_provider" >/dev/null 2>&1
  [ "$(grep -c '^\[model_providers\.zai\]' "$d/.codex/config.toml")" -eq 1 ]
  [ "$(grep -c '^\[profiles\.zai\]' "$d/.codex/config.toml")" -eq 1 ]
  grep -qF 'env_key = "ZAI_API_KEY"' "$d/.codex/config.toml"
  grep -qF 'base_url = "https://api.z.ai/api/v1"' "$d/.codex/config.toml"
  grep -qF 'model = "gpt-5.4"' "$d/.codex/config.toml"
  rm -rf "$d"
}

@test "codex_user_defined_zai_provider_left_untouched" {
  local d
  d="$(mktemp -d)"
  seed_env "$d"
  mkdir -p "$d/.codex"
  printf '[model_providers.zai]\nbase_url = "https://my-proxy"\n' > "$d/.codex/config.toml"
  HOME="$d" PATH="$d/bin:$PATH" bash -c "source '$SETUP_SH' >/dev/null 2>&1; CODEX_INSTALLED=true; PI_INSTALLED=false; ZAI_API_KEY=fakekey1234567890; seed_codex_provider" >/dev/null 2>&1
  grep -qF 'https://my-proxy' "$d/.codex/config.toml"
  [ "$(wc -l < "$d/.codex/config.toml")" -eq 2 ]
  rm -rf "$d"
}

@test "seed_mjs_missing_config_starts_fresh" {
  local d
  d="$(mktemp -d)"
  node "$SEED_MJS" --config "$d/nested/dir/models.json" >/dev/null 2>&1
  grep -qF '"apiKey": "$ZAI_API_KEY"' "$d/nested/dir/models.json"
  [ "$(stat -c '%a' "$d/nested/dir/models.json")" = "600" ]
  rm -rf "$d"
}

@test "seed_mjs_malformed_json_fails_without_write" {
  local d
  d="$(mktemp -d)"
  printf '{broken' > "$d/models.json"
  run node "$SEED_MJS" --config "$d/models.json"
  [ "$status" -ne 0 ]
  grep -qF '{broken' "$d/models.json"
  rm -rf "$d"
}
