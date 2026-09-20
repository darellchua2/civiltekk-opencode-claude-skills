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
  local d before after escape
  d="$(mktemp -d)"
  mkdir -p "$d/repo"
  printf 'LLM_PORT=1234\nOTHER=x\n' > "$d/repo/.env"
  before="$(md5sum < "$d/repo/.env")"
  # Sandbox-escape detector: the worktree .env (untracked user config) must be
  # untouched afterwards — a source-time REPO_DIR clobber would mutate it here.
  if [ -f .env ]; then escape="$(md5sum < .env)"; fi
  # REPO_DIR is assigned AFTER source on purpose: setup.sh:70 unconditionally
  # reassigns it from SCRIPT_DIR, clobbering any env-prefix sandbox (#467).
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=true; REPO_DIR='$d/repo'; setup_local_llm_env" >/dev/null 2>&1
  after="$(md5sum < "$d/repo/.env")"
  [ "$before" = "$after" ]
  if [ -n "$escape" ]; then [ "$escape" = "$(md5sum < .env)" ]; fi
  rm -rf "$d"
}

@test "env_file_real_run_updates_values_positive_control" {
  local d
  d="$(mktemp -d)"
  mkdir -p "$d/repo"
  printf 'LLM_PORT=1234\n' > "$d/repo/.env"
  HOME="$d" bash -c "source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; REPO_DIR='$d/repo'; setup_local_llm_env" >/dev/null 2>&1
  grep -q '^LLM_PORT=17851' "$d/repo/.env"
  # Negated assertions (`! grep`) are errexit-exempt and can NEVER fail a bats
  # test — use run + explicit status instead (#467 round 1).
  run grep -q '^LLM_PORT=1234$' "$d/repo/.env"
  [ "$status" -eq 1 ]
  rm -rf "$d"
}

@test "setup_sh_models_only_passes_dry_run_to_manifest_update" {
  # Conditional-assignment form, pinned positively AND by banning the
  # ${DRY_RUN:+...} spelling that expanded on the string "false" and silently
  # dried real models-only runs (#467 round 1 BLOCK).
  grep -F '[ "$DRY_RUN" = true ] && dry_arg="--dry-run"' "$SETUP_SH"
  grep -F '${dry_arg}' "$SETUP_SH"
  run grep -Fc '${DRY_RUN:+--dry-run}' "$SETUP_SH"
  [ "$status" -eq 1 ]
  # Semantics pin documenting WHY the spelling is banned:
  run bash -c 'DRY_RUN=false; echo ${DRY_RUN:+expanded}'
  [ "$output" = "expanded" ]
}

@test "setup_ps1_models_only_passes_dry_run_to_manifest_update" {
  grep -F 'if ($DryRun) { $updateArgs += "--dry-run" }' "$SETUP_PS1"
}
