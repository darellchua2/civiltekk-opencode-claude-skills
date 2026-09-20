#!/usr/bin/env bats

# Dry-run leak pins (#467): every real write reachable under --dry-run must be
# DRY_RUN-gated. The three historical leaks: learnings _index.md heredoc, the
# local-LLM .env writer (cp + sed/append), and the models-only init.mjs update
# that re-applied for real after the resolver had only staged a preview.
# Each functional pin carries a positive control (the real run MUST change
# bytes) so a future over-gate cannot silently no-op the fix.

SETUP_SH="deploy/setup.sh"
SETUP_PS1="deploy/setup.ps1"

@test "learnings_dry_run_writes_no_index" {
  local d
  d="$(mktemp -d)"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=true; setup_learnings_dir" >/dev/null 2>&1
  [ ! -f "$d/.config/opencode/learnings/_index.md" ]
  rm -rf "$d"
}

@test "learnings_real_run_creates_index_positive_control" {
  local d
  d="$(mktemp -d)"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; setup_learnings_dir" >/dev/null 2>&1
  [ -f "$d/.config/opencode/learnings/_index.md" ]
  rm -rf "$d"
}

@test "env_file_dry_run_leaves_bytes_unchanged" {
  local d before after
  d="$(mktemp -d)"
  mkdir -p "$d/repo"
  printf 'LLM_PORT=1234\nOTHER=x\n' > "$d/repo/.env"
  before="$(md5sum < "$d/repo/.env")"
  HOME="$d" REPO_DIR="$d/repo" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=true; setup_local_llm_env" >/dev/null 2>&1
  after="$(md5sum < "$d/repo/.env")"
  [ "$before" = "$after" ]
  rm -rf "$d"
}

@test "env_file_real_run_updates_values_positive_control" {
  local d
  d="$(mktemp -d)"
  mkdir -p "$d/repo"
  printf 'LLM_PORT=1234\n' > "$d/repo/.env"
  HOME="$d" REPO_DIR="$d/repo" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; setup_local_llm_env" >/dev/null 2>&1
  grep -q '^LLM_PORT=' "$d/repo/.env"
  ! grep -q '^LLM_PORT=1234$' "$d/repo/.env"
  rm -rf "$d"
}

@test "setup_sh_models_only_passes_dry_run_to_manifest_update" {
  # The exact invocation line must carry the DRY_RUN-conditional flag —
  # cmdUpdate gates writes AND prune on !dry (init.mjs), so this is sufficient.
  grep -F 'init.mjs" update ${PROVIDER:+--provider ${PROVIDER}} ${DRY_RUN:+--dry-run}' "$SETUP_SH"
}

@test "setup_ps1_models_only_passes_dry_run_to_manifest_update" {
  grep -F 'if ($DryRun) { $updateArgs += "--dry-run" }' "$SETUP_PS1"
}
