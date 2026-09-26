#!/usr/bin/env bats

# Agent LCD + overlay composition guards (#576) — docs/subagent-portability-contract.md.
# Token gate per REQ-PARITY: moved tokens absent from the LCD core, present in the
# composed output of the owning target (helper-invoked, hermetic). Matching is
# case-INSENSITIVE (learning: case-sensitive-grep-gates-false-green). Tokens ban
# invocation-shaped content, never legitimate negative mentions.

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
COMPOSE="node $REPO/tests/fixtures/compose_agent.mjs"

# assert_absent <file> <fixed-string> — case-insensitive, fails if found
assert_absent() {
  if grep -qiF -- "$2" "$1"; then
    echo "banned token present in $1: '$2'" >&3
    return 1
  fi
}

# assert_composed_absent <stem> <target> <fixed-string>
assert_composed_absent() {
  if $COMPOSE "$1" "$2" 2>/dev/null | grep -qiF -- "$3"; then
    echo "banned token present in composed $1/$2: '$3'" >&3
    return 1
  fi
}

# assert_composed_present <stem> <target> <fixed-string>
assert_composed_present() {
  if ! $COMPOSE "$1" "$2" 2>/dev/null | grep -qiF -- "$3"; then
    echo "required token missing from composed $1/$2: '$3'" >&3
    return 1
  fi
}

@test "token gate: code-review core carries no opencode invocation snippets" {
  assert_absent "$REPO/agents/code-review-subagent.md" 'subagent_type='
  assert_absent "$REPO/agents/code-review-subagent.md" 'via Task tool'
  assert_absent "$REPO/agents/code-review-subagent.md" 'the `memory` tool'
}

@test "token gate: image-analyzer core carries no deploy pin or v1 task syntax" {
  assert_absent "$REPO/agents/image-analyzer-subagent.md" 'zai-coding-plan/glm-5.3-flash'
  assert_absent "$REPO/agents/image-analyzer-subagent.md" 'permission.task'
}

@test "token gate: requirements-specialist core carries no opencode invocation snippets" {
  assert_absent "$REPO/agents/requirements-specialist-subagent.md" 'subagent_type='
  assert_absent "$REPO/agents/requirements-specialist-subagent.md" 'question` tool is NOT available'
}

@test "composed opencode output carries the moved tokens" {
  assert_composed_present code-review-subagent opencode 'subagent_type='
  assert_composed_present code-review-subagent opencode 'language-reviewer-subagent'
  assert_composed_present code-review-subagent opencode 'memory` tool'
  assert_composed_present image-analyzer-subagent opencode 'zai-coding-plan/glm-5.3-flash'
  assert_composed_present requirements-specialist-subagent opencode 'subagent_type='
}

@test "every pilot core contains the Other/none fallback row" {
  for stem in code-review-subagent image-analyzer-subagent requirements-specialist-subagent; do
    if ! grep -q 'Other/none:' "$REPO/agents/$stem.md"; then
      echo "missing Other/none: fallback row in $stem" >&3
      return 1
    fi
  done
}

@test "composed opencode output stays within the Other/none fallback coverage" {
  # The fallback row must survive composition (overlay appends after it).
  assert_composed_present code-review-subagent opencode 'Other/none:'
  assert_composed_present image-analyzer-subagent opencode 'Other/none:'
  assert_composed_present requirements-specialist-subagent opencode 'Other/none:'
}

@test "claude composed output carries the Task-tool binding" {
  assert_composed_present code-review-subagent claude 'Task tool'
  assert_composed_present image-analyzer-subagent claude 'Task tool'
  assert_composed_present requirements-specialist-subagent claude 'Task tool'
}

@test "kimi/kilo targets compose to the untouched core (LCD-only, by contract)" {
  for stem in code-review-subagent image-analyzer-subagent requirements-specialist-subagent; do
    for target in kimi kilo; do
      if ! diff -q <(cat "$REPO/agents/$stem.md") <($COMPOSE "$stem" "$target" 2>/dev/null) >/dev/null; then
        echo "unexpected composition for $stem/$target (no overlay should exist)" >&3
        return 1
      fi
    done
  done
}

@test "verbatim agentMode never composes, even when a matching overlay exists" {
  # opencode overlays exist for the pilots; verbatim mode must still return the core.
  for stem in code-review-subagent image-analyzer-subagent requirements-specialist-subagent; do
    if ! diff -q <(cat "$REPO/agents/$stem.md") <($COMPOSE "$stem" opencode verbatim 2>/dev/null) >/dev/null; then
      echo "verbatim mode composed for $stem — must never compose" >&3
      return 1
    fi
  done
}

@test "composition is deterministic and follows the core + blank-line + overlay formula" {
  stem="code-review-subagent"
  a=$($COMPOSE "$stem" opencode 2>/dev/null)
  b=$($COMPOSE "$stem" opencode 2>/dev/null)
  [ "$a" = "$b" ]
  core=$(cat "$REPO/agents/$stem.md")
  overlay=$(cat "$REPO/agents/overlays/$stem.opencode.md")
  # Formula: core (newline-terminated) + blank line + overlay (trimmed end) + newline.
  expected="$(printf '%s\n\n%s\n' "$core" "$overlay")"
  [ "$a" = "$expected" ]
  # Core is a prefix of the composed body (append-only, never reordered).
  case "$a" in "$core"*) ;; *) echo "composed body does not start with the core" >&3; return 1 ;; esac
}

@test "orphan-overlay guard: overlay suffixes only for targets with a TARGETS row" {
  # Composable targets (installer/init.mjs TARGETS) minus the verbatim `agents` row.
  while IFS= read -r f; do
    name=$(basename "$f")
    tmp="${name%.md}"
    suffix="${tmp##*.}"  # e.g. code-review-subagent.opencode.md -> opencode
    case "$suffix" in
      opencode|claude|kimi|kilo) ;;
      *) echo "orphan overlay (no composition path for target '$suffix'): $f" >&3; return 1 ;;
    esac
  done < <(find "$REPO/agents/overlays" -name '*.md' 2>/dev/null)
}

@test "no .agents.md overlay files exist (verbatim target is invalid as an overlay target)" {
  [ -z "$(find "$REPO/agents/overlays" -name '*.agents.md' 2>/dev/null)" ]
}
