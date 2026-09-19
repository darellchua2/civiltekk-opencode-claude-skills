#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << 'EOF'
audit-repo.sh — Audit a repository for version-bump standard compliance

Usage:
    audit-repo.sh <org>/<repo>

Description:
    Read-only audit that checks a repository against the CanvasTekk release
    standard. Prints a pass/fail report and exits non-zero on any failure.

Checks performed:
    1. bump-version-and-push-tag.yml workflow exists
    2. Release workflow triggers on dev, uat, main
    3. Pre-release tags for dev/uat, clean tags for main
    4. PR-label version bump on main
    5. enforce-dev-to-uat.yml workflow exists
    6. enforce-uat-to-main.yml workflow exists
    7. Branch protection on uat
    8. Branch protection on main
    9. patch/minor/major labels exist
    10. Audit bundles on main releases (informational)

Options:
    --help    Show this help message

Example:
    audit-repo.sh myorg/myrepo
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
PASS=0
FAIL=0
WARN=0

check() {
    local description="$1"
    local result="$2"
    if [[ "$result" == "pass" ]]; then
        echo "  [PASS] $description"
        PASS=$((PASS + 1))
    elif [[ "$result" == "warn" ]]; then
        echo "  [WARN] $description"
        WARN=$((WARN + 1))
    else
        echo "  [FAIL] $description"
        FAIL=$((FAIL + 1))
    fi
}

echo "Auditing $REPO for version-bump standard compliance..."
echo ""

# 1. bump-version-and-push-tag.yml exists
WORKFLOWS=$(gh api "repos/$REPO/contents/.github/workflows" --jq '.[].name' 2>/dev/null || echo "")
if echo "$WORKFLOWS" | grep -qi "bump-version"; then
    check "bump-version workflow exists" "pass"
else
    check "bump-version workflow exists" "fail"
fi

# 2. Triggers on dev, uat, main
BUMP_CONTENT=$(gh api "repos/$REPO/contents/.github/workflows/bump-version-and-push-tag.yml" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || echo "")
if echo "$BUMP_CONTENT" | grep -q "dev" && echo "$BUMP_CONTENT" | grep -q "uat" && echo "$BUMP_CONTENT" | grep -q "main"; then
    check "Release workflow triggers on dev, uat, main" "pass"
elif [[ -n "$BUMP_CONTENT" ]]; then
    check "Release workflow triggers on dev, uat, main" "fail"
fi

# 3. Pre-release suffixes for dev/uat
if echo "$BUMP_CONTENT" | grep -q "pre_release_suffix"; then
    check "Pre-release tags for dev/uat" "pass"
elif [[ -n "$BUMP_CONTENT" ]]; then
    check "Pre-release tags for dev/uat" "warn"
fi

# 4. PR-label bump on main
if echo "$BUMP_CONTENT" | grep -q "bump_type" && echo "$BUMP_CONTENT" | grep -qi "label"; then
    check "PR-label version bump on main" "pass"
elif [[ -n "$BUMP_CONTENT" ]]; then
    check "PR-label version bump on main" "warn"
fi

# 5. enforce-dev-to-uat.yml
if echo "$WORKFLOWS" | grep -qi "enforce-dev"; then
    check "enforce-dev-to-uat workflow exists" "pass"
else
    check "enforce-dev-to-uat workflow exists" "fail"
fi

# 6. enforce-uat-to-main.yml
if echo "$WORKFLOWS" | grep -qi "enforce-uat"; then
    check "enforce-uat-to-main workflow exists" "pass"
else
    check "enforce-uat-to-main workflow exists" "fail"
fi

# 7. Branch protection on uat
UAT_PROTECTION=$(gh api "repos/$REPO/branches/uat/protection" 2>/dev/null || echo "")
if [[ -n "$UAT_PROTECTION" && "$UAT_PROTECTION" != *"Not Found"* ]]; then
    check "Branch protection on uat" "pass"
else
    check "Branch protection on uat" "fail"
fi

# 8. Branch protection on main
MAIN_PROTECTION=$(gh api "repos/$REPO/branches/main/protection" 2>/dev/null || echo "")
if [[ -n "$MAIN_PROTECTION" && "$MAIN_PROTECTION" != *"Not Found"* ]]; then
    check "Branch protection on main" "pass"
else
    check "Branch protection on main" "fail"
fi

# 9. Labels exist
LABELS=$(gh label list --repo "$REPO" --json name --jq '.[].name' 2>/dev/null || echo "")
for LABEL in patch minor major; do
    if echo "$LABELS" | grep -qx "$LABEL"; then
        check "Label '$LABEL' exists" "pass"
    else
        check "Label '$LABEL' exists" "fail"
    fi
done

# 10. Audit bundles (informational)
LATEST_RELEASE=$(gh release list --repo "$REPO" --limit 1 --json tagName 2>/dev/null | jq -r '.[0].tagName' 2>/dev/null || echo "")
if [[ -n "$LATEST_RELEASE" && "$LATEST_RELEASE" != "null" ]]; then
    check "Latest release exists: $LATEST_RELEASE" "warn"
else
    check "No releases found (informational)" "warn"
fi

echo ""
echo "=== Audit Summary for $REPO ==="
echo "  Passed:     $PASS"
echo "  Warnings:   $WARN"
echo "  Failed:     $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo "RESULT: NON-COMPLIANT ($FAIL failures)"
    exit 1
fi

echo "RESULT: COMPLIANT"
exit 0
