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
# NOTE: sweep covers the first 200 open PRs (--limit below) — fine for this
# repo's scale; raise the limit if the open-PR count grows past it.
# NOTE: draft PRs are intentionally out of scope — they report
# mergeStateStatus DRAFT regardless of file conflicts, and flagging drafts
# is noise (#446 review gap, descope confirmed).
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
      # Comment once per PR lifetime (marker-scoped, not per episode).
      # Pagination: --paginate + stream bodies + grep OUTSIDE jq — a bare
      # unpaginated api call sees only page 1 (30 comments), and tacking
      # --paginate onto an aggregating --jq emits one number per page
      # (LEARNINGS: gh-api-paginate-jq-per-page-aggregation, #361).
      marker_count=$(gh api "repos/$REPO/issues/$num/comments" \
        --paginate --jq '.[].body' | grep -cF "$MARKER" || true)
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
        # Reset the comment-once invariant: delete stale marker comments so
        # a future re-conflict episode gets a fresh hint comment
        gh api "repos/$REPO/issues/$num/comments" \
          --jq '.[] | select(.body | contains("'"$MARKER"'")) | .id' |
        while read -r cid; do
          act "PR #$num: delete stale marker comment $cid" \
            gh api -X DELETE "repos/$REPO/issues/$num/comments/$cid"
        done
      fi
      ;;
  esac
done

echo "done."
