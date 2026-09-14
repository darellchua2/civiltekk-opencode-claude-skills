#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << 'EOF'
onboard-repo.sh — Onboard a repository to the version-bump standard

Usage:
    onboard-repo.sh <org>/<repo> [--skip-protection]

Description:
    Interactive onboarding runner that sets up a repository for the CanvasTekk
    release standard (dev -> uat -> main flow with PR-label-driven versioning).

Steps performed:
    1. Verify gh authentication and repo access
    2. Ensure dev and uat branches exist (creates from main if missing)
    3. Copy workflow templates to .github/workflows/ (via PR or direct push)
    4. Create semantic-versioning labels (patch, minor, major)
    5. Set branch protection on uat and main
    6. Print verification instructions

Options:
    --skip-protection    Skip branch protection setup (set up manually later)
    --help               Show this help message

Example:
    onboard-repo.sh myorg/myrepo
    onboard-repo.sh myorg/myrepo --skip-protection
EOF
}

SKIP_PROTECTION=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --skip-protection)
            SKIP_PROTECTION=true
            shift
            ;;
        *)
            if [[ -z "${REPO:-}" ]]; then
                REPO="$1"
            else
                echo "Error: Unexpected argument: $1" >&2
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "${REPO:-}" ]]; then
    echo "Error: <org>/<repo> argument required" >&2
    usage
    exit 1
fi

if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
    echo "Error: Invalid repo format. Expected <org>/<repo>, got: $REPO" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

echo "=== Onboarding $REPO to the version-bump standard ==="
echo ""

# Step 1: Verify gh auth and repo access
echo "[1/6] Verifying gh authentication and repo access..."
if ! gh auth status >/dev/null 2>&1; then
    echo "  Error: gh is not authenticated. Run 'gh auth login' first." >&2
    exit 1
fi
if ! gh repo view "$REPO" >/dev/null 2>&1; then
    echo "  Error: Cannot access $REPO. Check permissions." >&2
    exit 1
fi
echo "  OK"
echo ""

# Step 2: Ensure dev and uat branches exist
echo "[2/6] Ensuring dev and uat branches exist..."
for BRANCH in dev uat; do
    if gh api "repos/$REPO/branches/$BRANCH" >/dev/null 2>&1; then
        echo "  Branch '$BRANCH' exists"
    else
        echo "  Creating '$BRANCH' from main..."
        gh api "repos/$REPO/git/refs" \
            --method POST \
            -f ref="refs/heads/$BRANCH" \
            -f sha="$(gh api "repos/$REPO/branches/main" --jq '.commit.sha')" \
            >/dev/null 2>&1 && echo "  Created: $BRANCH" || echo "  Warning: Could not create '$BRANCH'" >&2
    fi
done
echo ""

# Step 3: Workflow templates (informational — requires local clone or API upload)
echo "[3/6] Workflow templates..."
echo "  Templates are available at: $TEMPLATES_DIR"
echo "  To install, copy these files to .github/workflows/ in $REPO:"
echo "    - bump-version-and-push-tag.yml"
echo "    - enforce-dev-to-uat.yml"
echo "    - enforce-uat-to-main.yml"
echo "  (Use a PR for proper review, or push directly to dev)"
echo ""

# Step 4: Create labels
echo "[4/6] Creating semantic-versioning labels..."
bash "$SCRIPT_DIR/create-labels.sh" "$REPO"
echo ""

# Step 5: Set branch protection
if [[ "$SKIP_PROTECTION" == "true" ]]; then
    echo "[5/6] Branch protection: SKIPPED (--skip-protection)"
else
    echo "[5/6] Setting branch protection..."
    bash "$SCRIPT_DIR/setup-branch-protection.sh" "$REPO"
fi
echo ""

# Step 6: Verification instructions
echo "[6/6] Verification checklist:"
echo "  1. Push to dev -> verify vX.Y.Z-dev.1 tag created"
echo "  2. PR dev -> uat -> merge -> verify vX.Y.Z-uat.1 tag created"
echo "  3. PR uat -> main (label: patch) -> merge -> verify vX.Y.Z tag + Release"
echo ""
echo "  Run audit-repo.sh $REPO to verify compliance."
echo ""
echo "=== Onboarding complete for $REPO ==="
