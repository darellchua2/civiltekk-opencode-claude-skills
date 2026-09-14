#!/usr/bin/env bats

# Tests for v2.0.0 backup-zip and rollback features in deploy/setup.sh.
#
# Covers:
#   - create_zip_backup: creates zip when zip available, tar.gz fallback
#   - cleanup_old_backups: also removes sibling .zip files
#   - list_backups: returns 0, lists available backups
#   - --rollback list: subcommand exits 0
#   - --rollback INVALID: exits non-zero, doesn't crash
#   - --rollback --dry-run --yes: does NOT modify ~/.config/opencode/
#   - resolve_backup_target: accepts TIMESTAMP, VERSION, latest
#   - restore_from_dir: restores files into CONFIG_DIR

PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
SETUP_SH="${PROJECT_ROOT}/deploy/setup.sh"

setup() {
    TEST_HOME="$(mktemp -d)"
    TEST_LOG="${TEST_HOME}/.opencode-setup.log"
    export HOME="$TEST_HOME"
    export LOG_FILE="$TEST_LOG"
    export BACKUP_DIR="${TEST_HOME}/.opencode-backup-$(date +%Y%m%d_%H%M%S)"
    export DRY_RUN=false
    export VERBOSE=true
    export KEEP_BACKUPS=5

    # Source the script (defines all functions; main() is guarded so it won't run)
    # shellcheck disable=SC1090
    source "$SETUP_SH" > /dev/null 2>&1

    # Create a minimal config dir layout for rollback tests
    CONFIG_DIR="${TEST_HOME}/.config/opencode"
    SKILLS_DIR="${CONFIG_DIR}/skills"
    AGENTS_DEST_DIR="${CONFIG_DIR}/agents"
    CONFIG_FILE="${CONFIG_DIR}/opencode.json"
    mkdir -p "$CONFIG_DIR" "$SKILLS_DIR" "$AGENTS_DEST_DIR"
    echo '{"test": true}' > "$CONFIG_FILE"
    echo "# AGENTS" > "${CONFIG_DIR}/AGENTS.md"
    mkdir -p "${SKILLS_DIR}/test-skill"
    echo "skill-body" > "${SKILLS_DIR}/test-skill/SKILL.md"
    echo "agent-body" > "${AGENTS_DEST_DIR}/build.md"
}

teardown() {
    rm -rf "$TEST_HOME"
}

################################################################################
# create_zip_backup
################################################################################

@test "create_zip_backup creates a .zip alongside BACKUP_DIR when zip is available" {
    if ! command -v zip > /dev/null 2>&1; then
        skip "zip not installed"
    fi
    BACKUP_DIR="${TEST_HOME}/.opencode-backup-20260719_010000"
    mkdir -p "$BACKUP_DIR"
    echo "config" > "${BACKUP_DIR}/opencode.json"
    echo "agents" > "${BACKUP_DIR}/AGENTS.md"

    ZIP_BACKUP=true
    DRY_RUN=false
    create_zip_backup
    [ -f "${BACKUP_DIR}.zip" ]
}

@test "create_zip_backup falls back to tar.gz when zip not on PATH" {
    # Simulate zip absence by temporarily masking command_exists
    BACKUP_DIR="${TEST_HOME}/.opencode-backup-20260719_020000"
    mkdir -p "$BACKUP_DIR"
    echo "config" > "${BACKUP_DIR}/opencode.json"

    ZIP_BACKUP=true
    DRY_RUN=false

    # Save real command_exists, override to make zip appear absent
    # shellcheck disable=SC2317
    _real_command_exists() { command -v "$1" > /dev/null 2>&1; }
    command_exists() { [ "$1" = "zip" ] && return 1 || _real_command_exists "$1"; }

    create_zip_backup
    local tar_path="${BACKUP_DIR}.zip.tar.gz"
    [ -f "$tar_path" ]
}

@test "create_zip_backup respects ZIP_BACKUP=false toggle" {
    if ! command -v zip > /dev/null 2>&1; then
        skip "zip not installed"
    fi
    BACKUP_DIR="${TEST_HOME}/.opencode-backup-20260719_030000"
    mkdir -p "$BACKUP_DIR"
    echo "config" > "${BACKUP_DIR}/opencode.json"

    ZIP_BACKUP=false
    DRY_RUN=false
    create_zip_backup
    [ ! -f "${BACKUP_DIR}.zip" ]
}

@test "create_zip_backup DRY_RUN prints would-be command and does not create archive" {
    if ! command -v zip > /dev/null 2>&1; then
        skip "zip not installed"
    fi
    BACKUP_DIR="${TEST_HOME}/.opencode-backup-20260719_040000"
    mkdir -p "$BACKUP_DIR"
    echo "config" > "${BACKUP_DIR}/opencode.json"

    ZIP_BACKUP=true
    DRY_RUN=true
    run create_zip_backup
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "DRY-RUN"
    [ ! -f "${BACKUP_DIR}.zip" ]
}

@test "create_zip_backup skips when BACKUP_DIR is empty" {
    BACKUP_DIR="${TEST_HOME}/.opencode-backup-20260719_050000"
    mkdir -p "$BACKUP_DIR"  # exists but empty

    ZIP_BACKUP=true
    DRY_RUN=false
    create_zip_backup
    [ ! -f "${BACKUP_DIR}.zip" ]
}

################################################################################
# cleanup_old_backups (zip-aware)
################################################################################

@test "cleanup_old_backups removes sibling .zip when removing a backup dir" {
    if ! command -v zip > /dev/null 2>&1; then
        skip "zip not installed"
    fi

    # Two backups, each with a sibling .zip
    local old_dir="${TEST_HOME}/.opencode-backup-20260710_010000"
    local new_dir="${TEST_HOME}/.opencode-backup-20260718_020000"
    mkdir -p "$old_dir" "$new_dir"
    echo "x" > "${old_dir}/f"
    echo "x" > "${new_dir}/f"
    touch "${old_dir}.zip" "${new_dir}.zip"

    KEEP_BACKUPS=1
    DRY_RUN=false
    cleanup_old_backups

    # Newest dir + zip survive
    [ -d "$new_dir" ]
    [ -f "${new_dir}.zip" ]
    # Oldest dir + zip removed
    [ ! -d "$old_dir" ]
    [ ! -f "${old_dir}.zip" ]
}

@test "cleanup_old_backups DRY_RUN reports would-remove for both dir and zip" {
    local old_dir="${TEST_HOME}/.opencode-backup-20260710_010000"
    local new_dir="${TEST_HOME}/.opencode-backup-20260718_020000"
    mkdir -p "$old_dir" "$new_dir"
    echo "x" > "${old_dir}/f"
    echo "x" > "${new_dir}/f"
    touch "${old_dir}.zip" "${new_dir}.zip"

    KEEP_BACKUPS=1
    DRY_RUN=true
    run cleanup_old_backups
    [ "$status" -eq 0 ]
    # DRY_RUN must not actually delete
    [ -d "$old_dir" ]
    [ -f "${old_dir}.zip" ]
    # Output should mention would-remove
    echo "$output" | grep -q "DRY-RUN"
}

################################################################################
# list_backups
################################################################################

@test "list_backups returns 0 even when no backups exist" {
    run list_backups
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "No backups"
}

@test "list_backups shows existing backups with timestamp" {
    local b1="${TEST_HOME}/.opencode-backup-20260710_010000"
    local b2="${TEST_HOME}/.opencode-backup-20260718_020000"
    mkdir -p "$b1" "$b2"
    echo "x" > "${b1}/file"
    echo "y" > "${b2}/file"

    run list_backups
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "20260710_010000"
    echo "$output" | grep -q "20260718_020000"
}

@test "list_backups shows zip marker when sibling .zip exists" {
    local b1="${TEST_HOME}/.opencode-backup-20260710_010000"
    mkdir -p "$b1"
    echo "x" > "${b1}/file"
    touch "${b1}.zip"

    run list_backups
    [ "$status" -eq 0 ]
    # ZIP column should say "zip" (not "-")
    echo "$output" | grep "20260710_010000" | grep -q "zip"
}

################################################################################
# resolve_backup_target
################################################################################

@test "resolve_backup_target accepts a TIMESTAMP and returns the dir path" {
    local b1="${TEST_HOME}/.opencode-backup-20260710_010000"
    mkdir -p "$b1"
    echo "x" > "${b1}/file"

    run resolve_backup_target "20260710_010000"
    [ "$status" -eq 0 ]
    [ "$output" = "$b1" ]
}

@test "resolve_backup_target returns non-zero for unknown TIMESTAMP" {
    run resolve_backup_target "19990101_000000"
    [ "$status" -ne 0 ]
}

@test "resolve_backup_target returns non-zero for malformed input" {
    run resolve_backup_target "not-a-real-target"
    [ "$status" -ne 0 ]
}

@test "resolve_backup_target falls back to zip when flat dir missing" {
    local zip_path="${TEST_HOME}/.opencode-backup-20260710_010000.zip"
    touch "$zip_path"

    run resolve_backup_target "20260710_010000"
    [ "$status" -eq 0 ]
    [ "$output" = "$zip_path" ]
}

################################################################################
# get_latest_backup
################################################################################

@test "get_latest_backup returns newest backup dir" {
    local b1="${TEST_HOME}/.opencode-backup-20260710_010000"
    local b2="${TEST_HOME}/.opencode-backup-20260718_020000"
    mkdir -p "$b1" "$b2"
    echo "x" > "${b1}/file"
    echo "y" > "${b2}/file"

    local result
    result=$(get_latest_backup)
    [ "$result" = "$b2" ]
}

@test "get_latest_backup returns non-zero when no backups exist" {
    run get_latest_backup
    [ "$status" -ne 0 ]
}

################################################################################
# restore_from_dir
################################################################################

@test "restore_from_dir restores opencode.json and AGENTS.md" {
    # Set up a source backup dir
    local src="${TEST_HOME}/restore-src"
    mkdir -p "$src"
    echo '{"restored": true}' > "${src}/opencode.json"
    echo "# RESTORED" > "${src}/AGENTS.md"

    restore_from_dir "$src"

    [ -f "${CONFIG_DIR}/opencode.json" ]
    grep -q '"restored": true' "${CONFIG_DIR}/opencode.json"
    grep -q "RESTORED" "${CONFIG_DIR}/AGENTS.md"
}

@test "restore_from_dir maps legacy config.json backups to opencode.json" {
    # Pre-v2.1 backups stored the config as config.json; restore must land it
    # on the name OpenCode v2 actually reads.
    local src="${TEST_HOME}/restore-legacy-src"
    mkdir -p "$src"
    echo '{"legacy": true}' > "${src}/config.json"

    restore_from_dir "$src"

    [ -f "${CONFIG_DIR}/opencode.json" ]
    grep -q '"legacy": true' "${CONFIG_DIR}/opencode.json"
}

@test "restore_from_dir restores skills/ from skills-backup/ when present" {
    local src="${TEST_HOME}/restore-src"
    mkdir -p "${src}/skills-backup/restored-skill"
    echo "restored" > "${src}/skills-backup/restored-skill/SKILL.md"

    restore_from_dir "$src"

    [ -f "${SKILLS_DIR}/restored-skill/SKILL.md" ]
    grep -q "restored" "${SKILLS_DIR}/restored-skill/SKILL.md"
}

################################################################################
# rollback (high-level)
################################################################################

@test "rollback list exits 0 and is idempotent (no state change)" {
    # Create some backups
    local b1="${TEST_HOME}/.opencode-backup-20260710_010000"
    local b2="${TEST_HOME}/.opencode-backup-20260718_020000"
    mkdir -p "$b1" "$b2"
    echo "x" > "${b1}/file"
    echo "y" > "${b2}/file"

    local before_count
    before_count=$(find "${TEST_HOME}" -maxdepth 1 -type d -name ".opencode-backup-*" | wc -l)

    ROLLBACK_TARGET="list"
    AUTO_ACCEPT=true
    DRY_RUN=false
    run rollback
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "Available Backups\|TIMESTAMP"

    local after_count
    after_count=$(find "${TEST_HOME}" -maxdepth 1 -type d -name ".opencode-backup-*" | wc -l)
    [ "$before_count" -eq "$after_count" ]
}

@test "rollback with invalid TIMESTAMP exits non-zero" {
    ROLLBACK_TARGET="19990101_000000"
    AUTO_ACCEPT=true
    DRY_RUN=false
    run rollback
    [ "$status" -ne 0 ]
    echo "$output" | grep -qi "No backup found"
}

@test "rollback --dry-run --yes does NOT modify CONFIG_DIR" {
    # Capture state
    local config_before
    config_before=$(cat "${CONFIG_DIR}/opencode.json" 2>/dev/null)
    local agents_before
    agents_before=$(cat "${CONFIG_DIR}/AGENTS.md" 2>/dev/null)

    # Set up a backup to roll back to (with different content)
    local b1="${TEST_HOME}/.opencode-backup-20260710_010000"
    mkdir -p "$b1"
    echo '{"different": true}' > "${b1}/opencode.json"
    echo "# DIFFERENT" > "${b1}/AGENTS.md"

    ROLLBACK_TARGET="20260710_010000"
    AUTO_ACCEPT=true
    DRY_RUN=true
    run rollback
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "DRY-RUN"

    # State must be unchanged
    [ "$(cat "${CONFIG_DIR}/opencode.json")" = "$config_before" ]
    [ "$(cat "${CONFIG_DIR}/AGENTS.md")" = "$agents_before" ]

    # And no pre-rollback backup should exist (dry-run shouldn't create one)
    local pre_count
    pre_count=$(find "${TEST_HOME}" -maxdepth 1 -type d -name ".opencode-pre-rollback-backup-*" | wc -l)
    [ "$pre_count" -eq 0 ]
}

@test "rollback latest --yes performs restore and creates pre-rollback backup" {
    # Backup with different content
    local b1="${TEST_HOME}/.opencode-backup-20260710_010000"
    mkdir -p "$b1"
    echo '{"restored": true}' > "${b1}/opencode.json"
    echo "# RESTORED" > "${b1}/AGENTS.md"

    ROLLBACK_TARGET="latest"
    AUTO_ACCEPT=true
    DRY_RUN=false
    run rollback
    [ "$status" -eq 0 ]

    # opencode.json should be the restored one
    grep -q '"restored": true' "${CONFIG_DIR}/opencode.json"
    grep -q "RESTORED" "${CONFIG_DIR}/AGENTS.md"

    # A pre-rollback backup must exist
    local pre_count
    pre_count=$(find "${TEST_HOME}" -maxdepth 1 -type d -name ".opencode-pre-rollback-backup-*" | wc -l)
    [ "$pre_count" -eq 1 ]
}

@test "rollback without target and without --yes fails (interactive requires TTY)" {
    # When AUTO_ACCEPT is true but no target is given, rollback should refuse
    # (it cannot interactively pick a backup with --yes).
    ROLLBACK_TARGET=""
    AUTO_ACCEPT=true
    DRY_RUN=false
    run rollback
    [ "$status" -ne 0 ]
}

################################################################################
# parse_arguments (new flags)
################################################################################

@test "--rollback sets ROLLBACK_MODE=true" {
    ROLLBACK_MODE=false
    parse_arguments --rollback
    [ "$ROLLBACK_MODE" = true ]
}

@test "--rollback TIMESTAMP sets ROLLBACK_TARGET" {
    ROLLBACK_MODE=false
    ROLLBACK_TARGET=""
    parse_arguments --rollback 20260719_010000
    [ "$ROLLBACK_MODE" = true ]
    [ "$ROLLBACK_TARGET" = "20260719_010000" ]
}

@test "--rollback latest sets ROLLBACK_TARGET=latest" {
    ROLLBACK_MODE=false
    ROLLBACK_TARGET=""
    parse_arguments --rollback latest
    [ "$ROLLBACK_TARGET" = "latest" ]
}

@test "--rollback list sets ROLLBACK_TARGET=list" {
    ROLLBACK_MODE=false
    ROLLBACK_TARGET=""
    parse_arguments --rollback list
    [ "$ROLLBACK_TARGET" = "list" ]
}

@test "--rollback followed by another flag does not consume it as target" {
    ROLLBACK_MODE=false
    ROLLBACK_TARGET=""
    parse_arguments --rollback --yes
    [ "$ROLLBACK_MODE" = true ]
    [ "$ROLLBACK_TARGET" = "" ]
    [ "$AUTO_ACCEPT" = true ]
}

@test "--no-zip-backup sets ZIP_BACKUP=false" {
    ZIP_BACKUP=true
    parse_arguments --no-zip-backup
    [ "$ZIP_BACKUP" = false ]
}
