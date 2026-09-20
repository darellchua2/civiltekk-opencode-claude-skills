#!/usr/bin/env bats

# Headless default-path pin (#466): bare ./setup.sh with no TTY must take the
# menu-default (skills-only) path deterministically — notice printed, exit 0,
# no prompt left to hit EOF. Stubs keep it deterministic in CI sandboxes:
# check_network (no flaky net dependency) and command_exists/check_dependencies
# (no opencode install required in the runner).

PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
SETUP_SH="${PROJECT_ROOT}/deploy/setup.sh"

setup() {
    TEST_HOME="$(mktemp -d)"
    export HOME="$TEST_HOME"
}

teardown() {
    rm -rf "$TEST_HOME"
}

@test "headless bare run defaults to skills-only with a notice" {
    run bash -c "source '$SETUP_SH' >/dev/null 2>&1; check_network(){ return 0; }; check_dependencies(){ return 0; }; command_exists(){ return 0; }; main --dry-run" </dev/null
    [ "$status" -eq 0 ]
    [[ "$output" == *"No TTY detected"* ]]
    [[ "$output" == *"Skills deployment complete!"* ]]
}

@test "headless run with -y keeps the documented full path (no menu, no notice)" {
    # The pin is the TTY-gate clause only: -y skips the menu, so the notice
    # must never print. Exit status is NOT pinned here — the -y full chain
    # runs setup.sh's real environment gates (node version etc.), which may
    # legitimately abort in a sandbox; that is setup.sh doing its job.
    run bash -c "source '$SETUP_SH' >/dev/null 2>&1; check_network(){ return 0; }; check_dependencies(){ return 0; }; command_exists(){ return 0; }; main --dry-run -y" </dev/null
    [[ "$output" != *"No TTY detected"* ]]
}
