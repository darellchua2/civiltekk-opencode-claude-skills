#!/usr/bin/env bash
# PR conflict labeler (#446): flag open PRs whose base has drifted into
# conflict — label `conflicted` + one comment with the update-branch hint.
# Self-healing: the label is removed when the conflict is resolved.
# Transient `mergeable: UNKNOWN` states are skipped, never failed.
#
# DRY_RUN=1 prints planned actions without mutating anything.

set -euo pipefail

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"
DRY_RUN="${DRY_RUN:-0}"
LABEL="conflicted"
LABEL_DESC="Base branch has drifted into conflict"
LABEL_COLOR="d93f0b"
MARKER='<!-- pr-conflict-labeler -->'

act() {
  # act <description> <command...> — run unless DRY_RUN
  if [ "$DRY_RUN" = "1" ]; then
    echo "DRY-RUN: $1"
  else
    echo ">> $1"
    "${@:2}"
  fi
}

# Label must exist before it can be applied (idempotent, best-effort)
if ! gh api "repos/$REPO/labels/$LABEL" >/dev/null 2>&1; then
  act "create label '$LABEL'" gh label create "$LABEL" \
    --repo "$REPO" --color "$LABEL_COLOR" --description "$LABEL_DESC" \
    || echo "WARN: label create failed (race?) — continuing"
fi

gh pr list --repo "$REPO" --state open --limit 200 \
  --json number,mergeable,mergeStateStatus,labels \
  --jq '.[] | [.number, .mergeable, .mergeStateStatus, ([.labels[].name] | index("conflicted")) // false] | @tsv' |
while IFS=$'\t' read -r num _mergeable ms has_label; do
  case "$ms" in
    DIRTY | CONFLICTING)
      if [ "$has_label" = "false" ]; then
        act "PR #$num: $ms → add '$LABEL' label" \
          gh pr edit "$num" --repo "$REPO" --add-label "$LABEL"
      else
        echo "PR #$num: $ms (already labeled)"
      fi
      # Comment once per PR lifetime (marker-scoped, not per episode)
      marker_count=$(gh api "repos/$REPO/issues/$num/comments" \
        --jq '[.[] | select(.body | contains("'"$MARKER"'"))] | length')
      if [ "${marker_count:-0}" -eq 0 ]; then
        act "PR #$num: post conflict comment" \
          gh pr comment "$num" --repo "$REPO" --body \
"$MARKER
This PR's base has drifted into conflict (merge state: \`$ms\`).
Restore mergeability with \`gh pr update-branch $num\` or the branch-update button, then resolve any conflicts."
      fi
      ;;
    UNKNOWN)
      echo "PR #$num: UNKNOWN (transient) — skipped"
      ;;
    *)
      if [ "$has_label" != "false" ]; then
        act "PR #$num: $ms → conflict resolved, remove '$LABEL' label" \
          gh pr edit "$num" --repo "$REPO" --remove-label "$LABEL"
      fi
      ;;
  esac
done

echo "done."
