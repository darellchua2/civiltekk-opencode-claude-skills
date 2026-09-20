#!/usr/bin/env bats

# Guard for #446: the PR conflict labeler must keep its AC invariants —
# transient UNKNOWN states are skipped (never failed), comments are
# once-per-PR (marker-scoped), DRY_RUN exists for local verification,
# and the workflow stays labels/comments-only (no required checks).

SCRIPT=".github/scripts/pr-conflict-labeler.sh"
WORKFLOW=".github/workflows/pr-conflict-labeler.yml"

@test "labeler_script_exists_and_parses" {
  [ -f "$SCRIPT" ]
  bash -n "$SCRIPT"
}

@test "labeler_script_keeps_ac_invariants" {
  grep -q "set -euo pipefail" "$SCRIPT"
  grep -q 'UNKNOWN)' "$SCRIPT"                      # transient state skipped
  grep -q "pr-conflict-labeler" "$SCRIPT"           # comment-once marker
  grep -q 'DRY_RUN' "$SCRIPT"                       # local verification mode
  grep -q "mergeStateStatus" "$SCRIPT" || grep -q "ms" "$SCRIPT"
}

@test "labeler_workflow_shape" {
  [ -f "$WORKFLOW" ]
  grep -q "cron:" "$WORKFLOW"                       # daily schedule
  grep -q "workflow_dispatch" "$WORKFLOW"           # manual verification
  grep -q "issues: write" "$WORKFLOW"
  grep -q "pull-requests: write" "$WORKFLOW"
  grep -q "pr-conflict-labeler.sh" "$WORKFLOW"      # wired to the script
  ! grep -qE "pull_request(_target)?:|^on:.*pull_request" "$WORKFLOW"  # never on PR events
}

@test "labeler_behavior_all_four_paths" {
  # Stub `gh` with canned data; assert the script labels new conflicts,
  # comments once, skips UNKNOWN, and unlables resolved PRs.
  local stub log fixture
  stub="$(mktemp -d)"; log="$(mktemp)"; fixture="$(mktemp)"
  # shellcheck disable=SC2016
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'LOG="${LOG:?}"' \
    'case "$1 $2" in' \
    '  "api "*) case "$2" in' \
    '    *"/labels/conflicted"*) exit 1;;' \
    '    *"/comments"*) echo 0;;' \
    '    *) exit 0;; esac;;' \
    'esac' \
    'case "$1 $2" in' \
    '  "pr list") cat "$FIXTURE";; \' \
    '  "pr edit"*) echo "edit $*" >> "$LOG";; \' \
    '  "pr comment"*) echo "comment $*" >> "$LOG";; \' \
    '  "label "*) echo "label-create" >> "$LOG";; \' \
    '  *) exit 0;; esac' > "$stub/gh"
  chmod +x "$stub/gh"
  printf '%s\n' \
    $'1\tUNKNOWN\tUNKNOWN\tfalse' \
    $'2\tUNKNOWN\tDIRTY\tfalse' \
    $'3\tUNKNOWN\tCONFLICTING\ttrue' \
    $'4\tUNKNOWN\tBEHIND\ttrue' > "$fixture"
  LOG="$log" FIXTURE="$fixture" PATH="$stub:$PATH" \
    GITHUB_REPOSITORY="acme/repo" bash "$SCRIPT" > /dev/null
  # PR 2: newly conflicted → labeled + commented
  grep -q "edit pr edit 2 --repo acme/repo --add-label conflicted" "$log"
  # PR 3: already labeled, never commented → comment fires (comment-once)
  grep -q "comment pr comment 3" "$log"
  # PR 4: resolved → label removed
  grep -q "edit pr edit 4 --repo acme/repo --remove-label conflicted" "$log"
  # PR 1: UNKNOWN → untouched
  ! grep -q "edit pr edit 1" "$log"
  ! grep -q "comment pr comment 1" "$log"
  # label created once (missing at start)
  [ "$(grep -c "label-create" "$log")" -eq 1 ]
  rm -rf "$stub" "$log" "$fixture"
}
