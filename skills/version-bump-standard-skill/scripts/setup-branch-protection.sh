#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << 'EOF'
setup-branch-protection.sh — Set branch protection rules for uat and main

Usage:
    setup-branch-protection.sh <org>/<repo>

Description:
    Applies branch protection rules to the 'uat' and 'main' branches:
    - Required status check: check-source-branch (strict)
    - 1 required approving review
    - Linear history enforced
    - No force pushes, no deletions
    - Admins enforced

    Idempotent: safe to re-run (overwrites existing rules).

Options:
    --help    Show this help message

Example:
    setup-branch-protection.sh myorg/myrepo
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

PROTECTION_PAYLOAD=$(cat << 'EOF'
{
  "required_status_checks": { "strict": true, "contexts": ["check-source-branch"] },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
)

for BRANCH in uat main; do
    echo "Setting branch protection on '$BRANCH' for $REPO..."
    if gh api "repos/$REPO/branches/$BRANCH/protection" \
        --method PUT \
        --input - <<< "$PROTECTION_PAYLOAD" >/dev/null 2>&1; then
        echo "  Protected: $BRANCH"
    else
        echo "  Warning: Failed to protect '$BRANCH'. Does the branch exist?" >&2
        exit 1
    fi
done

echo "Done. Branch protection applied to uat and main for $REPO."
