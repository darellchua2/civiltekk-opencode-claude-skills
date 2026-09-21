#!/usr/bin/env bats

# ERR-trap nounset safety (#501): setup.sh installs a global ERR trap whose
# invocation read "${BASH_LINENO[0]}" unguarded. Under `set -o nounset`, the
# handler crashed with "BASH_LINENO[0]: unbound variable" whenever the trap
# fired in a context where that element is unset — e.g. sourced setup.sh + a
# bare function call returning non-zero (the suite's bash -c stub idiom) —
# and bash surfaced the crashed trap as exit 127, masking the real rc and
# emitting the BW01 warning in test_subcommands.bats on every run.

SETUP_SH="deploy/setup.sh"

@test "expected_return1_in_sourced_context_exits_1_without_unbound_crash" {
  local d; d="$(mktemp -d)"
  # load_user_preset with an unknown preset returns 1 by design; with the fix
  # the ERR trap degrades its diagnostic (line 0) instead of crashing to 127.
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; DRY_RUN=false; LOAD_PRESET_NAME=nope; load_user_preset" 2>&1
  rm -rf "$d"
  [ "$status" -eq 1 ]
  [[ "$output" != *"unbound variable"* ]]
}
