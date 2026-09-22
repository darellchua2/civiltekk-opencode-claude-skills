#!/usr/bin/env bats
# Portability guard (#515) — enforces rules 1–2 of AGENTS.md §Portability contract.
# Rule 3 (bash requirement declarations) stays review-enforced.
# Set PORTABILITY_ROOT to check a fixture tree instead of the repo (seeded-violation tests).

setup() {
  ROOT="${PORTABILITY_ROOT:-$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)}"
}

@test "portability: no .opencode/skills literals in SKILL.md bodies" {
  run rg -l '\.opencode/skills' "$ROOT/skills" --glob 'SKILL.md'
  if [ "$status" -eq 0 ]; then
    echo "literal install paths found in: $output" >&2
    return 1
  fi
  [ "$status" -eq 1 ]
}

@test "portability: background-shell mentions carry a portable fallback row" {
  local files
  files="$(rg -l 'background: true' "$ROOT/skills" --glob 'SKILL.md' || true)"
  [ -z "$files" ] && skip "no background-shell mentions"
  local failures=""
  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! rg -qi 'Other/none' "$f"; then
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
  files="$(rg -l 'xvfb|pkill|\$DISPLAY' "$ROOT/skills" --glob 'SKILL.md' || true)"
  [ -z "$files" ] && skip "no unix-only idioms"
  local failures=""
  local f
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! head -n 15 "$f" | rg -q 'os: "linux'; then
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
  files="$(rg -l '^  (os|harness): ' "$ROOT/skills" --glob 'SKILL.md' || true)"
  [ -z "$files" ] && skip "no os/harness metadata"
  local failures=""
  local f line
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      case "$line" in
        '  os: "'*'"'|'  harness: "'*'"') : ;;
        '  os: '*|'  harness: '*)
          failures="$failures
  $f: $line"
          ;;
      esac
    done < <(awk 'NR==1 && /^---$/{next} /^---$/{exit} {print}' "$f")
  done <<< "$files"
  if [ -n "$failures" ]; then
    echo "non-canonical os/harness values (quoted lowercase comma strings only):$failures" >&2
    return 1
  fi
}
