#!/usr/bin/env bats

# Guard for #445: reviewer agents hold NO write access at all. A reviewer
# subagent's cwd is the session checkout (base branch), so any write lands on
# the wrong tree — reviewers return LEARNINGS candidates as report content
# and the pipeline commits them. The check is block-scoped (each
# `- action:` block bounded to its `effect:`), so reordered keys, unquoted
# resources, and broad-glob allows all fail (LEARNINGS:
# guard-regex-quote-shape-mismatch, yaml-guard-adjacency-grep).

REVIEWERS="agents/code-review-subagent.md agents/uiux-reviewer-subagent.md agents/architecture-review-subagent.md agents/language-reviewer-subagent.md"

@test "all_four_reviewer_agents_exist" {
  for f in $REVIEWERS; do
    [ -f "$f" ]
  done
}

@test "no_reviewer_agent_grants_any_edit_allow" {
  bad=""
  for f in $REVIEWERS; do
    # frontmatter only (line 2 through the closing ---); any block pairing
    # action:edit with effect:allow — in either key order, any quoting — fails
    if sed -n '2,/^---$/p' "$f" | awk '
      /^permissions:/          { p = 1; next }
      p && /^[A-Za-z_][A-Za-z0-9_-]*:/ { p = 0 }
      p && /^[[:space:]]*-[[:space:]]*action:/ { if (e && a) exit 1; e = ($0 ~ /action:[[:space:]]*edit/); a = ($0 ~ /effect:.*allow/); inb = 1; next }
      inb && /action:[[:space:]]*edit/ { e = 1 }
      inb && /effect:.*allow/  { a = 1 }
      END { if (e && a) exit 1 }
    '; then
      :
    else
      bad="$bad $f"
    fi
  done
  [ -z "$bad" ]
}
