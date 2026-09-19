#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << 'EOF'
create-labels.sh — Create semantic-versioning labels for the version-bump standard

Usage:
    create-labels.sh <org>/<repo>

Description:
    Creates the patch, minor, and major labels with governance-standard colors.
    Idempotent: skips labels that already exist.

Labels created:
    patch  — #0e8a16 (green)  — Bug fixes, config changes, infra tweaks
    minor  — #fbca04 (yellow) — New features, new resources, additive changes
    major  — #d73a4a (red)    — Breaking changes, destructive migrations

Colors are governed by semantic-release-convention-skill.

Options:
    --help    Show this help message

Example:
    create-labels.sh myorg/myrepo
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

if [[ $# -ne 1 ]]; then
    echo "Error: <org>/<repo> argument required" >&2
    usage
    exit 1
fi

REPO="$1"

if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo "Error: Invalid repo format. Expected <org>/<repo>, got: $REPO" >&2
    exit 1
fi

echo "Creating semantic-versioning labels for $REPO..."

gh label create patch \
    --color "0e8a16" \
    --description "Version bump: patch (bug fixes, config changes)" \
    --repo "$REPO" 2>/dev/null && echo "  Created: patch" || echo "  Exists:  patch (skipped)"

gh label create minor \
    --color "fbca04" \
    --description "Version bump: minor (new features, additive changes)" \
    --repo "$REPO" 2>/dev/null && echo "  Created: minor" || echo "  Exists:  minor (skipped)"

gh label create major \
    --color "d73a4a" \
    --description "Version bump: major (breaking changes)" \
    --repo "$REPO" 2>/dev/null && echo "  Created: major" || echo "  Exists:  major (skipped)"

echo "Done. Labels verified for $REPO."
