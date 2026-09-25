#!/usr/bin/env bats
# Portability guard (#515) — enforces rules 1–2 of AGENTS.md §Portability contract.
# Rule 3 (bash requirement declarations) stays review-enforced.
# Set PORTABILITY_ROOT to check a fixture tree instead of the repo (seeded-violation tests).
# Uses POSIX grep (+ -E), NOT rg — CI runners don't ship ripgrep (#515 CI fix).

setup() {
  ROOT="${PORTABILITY_ROOT:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)}"
  GREP_ARGS=(--include='SKILL.md' -r)
}

# frontmatter_lines FILE — print SKILL.md frontmatter body (between the --- fences)
frontmatter_lines() {
  awk 'NR==1 && /^---$/{next} /^---$/{exit} {print}' "$1"
}

@test "portability: sweep is non-vacuous (skills tree enumerated)" {
  local n
  n="$(find "$ROOT/skills" -name 'SKILL.md' | wc -l)"
  if [ "$n" -lt 1 ]; then
    echo "sweep found 0 SKILL.md files under $ROOT/skills — guard would pass vacuously" >&2
    return 1
  fi
}

@test "portability: no .opencode/skills literals in SKILL.md bodies" {
  run grep -rlE '\.opencode/skills' "$ROOT/skills" "${GREP_ARGS[@]}"
  if [ "$status" -eq 0 ]; then
    echo "literal install paths found in: $output" >&2
    return 1
  fi
  [ "$status" -eq 1 ]
}

@test "portability: background-shell mentions carry a portable fallback row" {
  local files
  files="$(grep -rlF 'background: true' "$ROOT/skills" "${GREP_ARGS[@]}" || true)"
  [ -z "$files" ] && skip "no background-shell mentions"
  local failures=""
  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! grep -qi 'Other/none' "$f"; then
      failures="$failures $f"
    fi
  done <<< "$files"
  if [ -n "$failures" ]; then
    echo "background mentions without Other/none fallback row:$failures" >&2
    return 1
  fi
}

@test "portability: unix-only idioms declare metadata.os" {
  local files
  files="$(grep -rlE 'xvfb|pkill|\$DISPLAY' "$ROOT/skills" "${GREP_ARGS[@]}" || true)"
  [ -z "$files" ] && skip "no unix-only idioms"
  local failures=""
  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! frontmatter_lines "$f" | grep -Eq '^  os: "linux'; then
      failures="$failures $f"
    fi
  done <<< "$files"
  if [ -n "$failures" ]; then
    echo "unix-only idioms without metadata.os declaration:$failures" >&2
    return 1
  fi
}

@test "portability: metadata os/harness use the canonical authoring form" {
  local files
  files="$(grep -rlE '^  (os|harness): ' "$ROOT/skills" "${GREP_ARGS[@]}" || true)"
  [ -z "$files" ] && skip "no os/harness metadata"
  local failures=""
  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    local bad
    bad="$(frontmatter_lines "$f" | grep -E '^[[:space:]]*(os|harness): ' | grep -vE '^  (os|harness): "[a-z0-9]+(, [a-z0-9]+)*"$' || true)"
    [ -n "$bad" ] && failures="$failures
  $f: $bad"
  done <<< "$files"
  if [ -n "$failures" ]; then
    echo "non-canonical os/harness values (must match \"[a-z0-9]+(, [a-z0-9]+)*\"):$failures" >&2
    return 1
  fi
}
