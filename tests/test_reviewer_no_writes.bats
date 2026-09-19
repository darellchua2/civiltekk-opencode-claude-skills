#!/usr/bin/env bats

# Guard for #445: reviewer agents must never hold an `edit` allow on
# LEARNINGS/**. A reviewer subagent's cwd is the session checkout (base
# branch), so any such write lands on the wrong branch — reviewers return
# LEARNINGS candidates as report content and the pipeline commits them.
# Both quote shapes guarded (LEARNINGS: guard-regex-quote-shape-mismatch).

REVIEWERS="agents/code-review-subagent.md agents/uiux-reviewer-subagent.md agents/architecture-review-subagent.md agents/language-reviewer-subagent.md"

@test "all_four_reviewer_agents_exist" {
  for f in $REVIEWERS; do
    [ -f "$f" ]
  done
}

@test "no_reviewer_agent_allows_edit_on_learnings" {
  bad=""
  for f in $REVIEWERS; do
    if grep -A1 -E "resource: ['\"]LEARNINGS" "$f" | grep -q "effect: allow"; then
      bad="$bad $f"
    fi
  done
  [ -z "$bad" ]
}
