#!/usr/bin/env bats

# v2 CLI package pin (#499): deploy/setup.sh must install, update, and
# version-check the v2 scoped npm package @opencode/cli — never the frozen
# v1 line opencode-ai — and must offer v1 installs the official
# uninstall-then-install migration (v2 migrate-v1 docs: remove the
# package-managed v1 install BEFORE installing v2; the two packages fight
# over the same `opencode` bin link).

SETUP_SH="deploy/setup.sh"

# Common stub scaffold: captures run_cmd invocations as "RUN-CMD: ..." lines
# so tests can assert the exact npm commands the deploy logic would run.
v1_env() {
  cat <<'STUB'
command_exists(){ case "$1" in opencode|npm) return 0;; *) return 1;; esac; }
opencode(){ echo "opencode v1.18.31"; }
npm(){ echo "2.0.11"; }
prompt_yes_no(){ echo "PROMPT: $1"; [ "${2:-n}" = "y" ]; }
run_cmd(){ echo "RUN-CMD: $*"; }
STUB
}

@test "setup_opencode_detects_v1_and_offers_uninstall_then_install_migration" {
  local d; d="$(mktemp -d)"
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; $(v1_env); setup_opencode"
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"OpenCode v1 detected (v1.18.31)"* ]]
  [[ "$output" == *"PROMPT: Migrate v1 to v2 now"* ]]
  [[ "$output" == *"RUN-CMD: npm uninstall -g opencode-ai"* ]]
  [[ "$output" == *"RUN-CMD: npm install -g @opencode/cli@latest"* ]]
  [[ "$output" != *"RUN-CMD: npm install -g opencode-ai"* ]]
}

@test "setup_opencode_v2_current_version_equality_is_normalized" {
  local d; d="$(mktemp -d)"
  # `opencode --version` prints "opencode v2.0.11" — the probe must strip the
  # prefix or the equality check reports a perpetual "update available".
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1
    command_exists(){ return 0; }; opencode(){ echo 'opencode v2.0.11'; }; npm(){ echo '2.0.11'; }
    prompt_yes_no(){ echo \"PROMPT: \$1\"; return 1; }; run_cmd(){ echo \"RUN-CMD: \$*\"; }
    setup_opencode"
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"@opencode/cli is already up to date"* ]]
  [[ "$output" != *"update is available"* ]]
}

@test "setup_opencode_fresh_install_targets_v2_package" {
  local d; d="$(mktemp -d)"
  # run_cmd stub flips INSTALLED so the post-install existence check takes the
  # success branch (a bare stub would leave `opencode` missing and exercise
  # the failure path + sourced ERR trap instead).
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1
    INSTALLED=''
    command_exists(){ [ \"\$1\" = npm ] || { [ \"\$1\" = opencode ] && [ -n \"\$INSTALLED\" ]; }; }
    npm(){ echo '2.0.11'; }
    prompt_yes_no(){ echo \"PROMPT: \$1\"; [ \"\${2:-n}\" = 'y' ]; }
    run_cmd(){ INSTALLED=1; echo \"RUN-CMD: \$*\"; }
    setup_opencode"
  rm -rf "$d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PROMPT: Install OpenCode v2 now"* ]]
  [[ "$output" == *"RUN-CMD: npm install -g @opencode/cli"* ]]
}

@test "setup_sh_has_no_v1_package_install_or_probe_references" {
  # The ONLY permitted opencode-ai references are the v1-detection/migration
  # strings (uninstall target + explanatory prose). Install/update/probe must
  # name @opencode/cli. Patterns are npm-anchored: a bare `install -g
  # opencode-ai` would substring-match the required `npm uninstall -g
  # opencode-ai` migration line and false-positive.
  run grep -nE "npm install -g opencode-ai|npm view opencode-ai" "$SETUP_SH"
  [ "$status" -eq 1 ]
  run grep -c "npm view @opencode/cli version" "$SETUP_SH"
  [ "$output" -ge 3 ]
}
