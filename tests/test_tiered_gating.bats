#!/usr/bin/env bats

# Tiered verification gating (#488) — pins the light/full gate contract across
# the canonical contract and the deferring surfaces.
# Assertions use case-insensitive or fixed-string greps over the spellings
# actually written (LEARNINGS: case-sensitive-grep-gates-false-green,
# guard-regex-quote-shape-mismatch); format tokens containing `|` use grep -F
# so BRE alternation cannot false-match a partial token.

SKILLS_DIR="skills"

# Helper: extract a ### subsection's line range from a file.
# Outputs "<start> <end>" (inclusive of header, exclusive of the next ##/###
# header). Outputs "0 0" when absent.
extract_subsection_range() {
  local file="$1" header="$2" start end
  start=$(grep -n "^### $header" "$file" | head -1 | cut -d: -f1)
  if [ -z "$start" ]; then
    echo "0 0"
    return
  fi
  end=$(awk -v s="$start" 'NR>s && /^###? / {print NR-1; exit}' "$file")
  if [ -z "$end" ]; then
    end=$(wc -l < "$file")
  fi
  echo "$start $end"
}

VL="$SKILLS_DIR/verification-loop-skill/SKILL.md"

# =============================================================================
# Phase 1 — canonical contract (verification-loop-skill)
# =============================================================================

@test "tier1_gating_verification-loop_has_tiered_gating_subsection" {
  [ -f "$VL" ]
  grep -q '^### Tiered gating' "$VL"
}

@test "tier1_gating_verification-loop_light_gate_default" {
  read -r s e <<< "$(extract_subsection_range "$VL" 'Tiered gating')"
  [ "$s" -gt 0 ]
  sed -n "${s},${e}p" "$VL" | grep -qi 'light gate'
  sed -n "${s},${e}p" "$VL" | grep -qi 'affected tests only'
  sed -n "${s},${e}p" "$VL" | grep -qi 'needs no justification'
}

@test "tier1_gating_verification-loop_escalation_anchors" {
  read -r s e <<< "$(extract_subsection_range "$VL" 'Tiered gating')"
  [ "$s" -gt 0 ]
  sed -n "${s},${e}p" "$VL" | grep -qi 'critical-area anchor'
  sed -n "${s},${e}p" "$VL" | grep -q 'Dependency & Consumer Map'
  sed -n "${s},${e}p" "$VL" | grep -qF 'unsure always escalates to full'
}

@test "tier1_gating_verification-loop_exit_gate_unconditional" {
  read -r s e <<< "$(extract_subsection_range "$VL" 'Tiered gating')"
  [ "$s" -gt 0 ]
  sed -n "${s},${e}p" "$VL" | grep -qi 'ticket exit gate'
  sed -n "${s},${e}p" "$VL" | grep -qi 'unconditionally'
}

@test "tier1_gating_verification-loop_one_directional_escalation" {
  read -r s e <<< "$(extract_subsection_range "$VL" 'Tiered gating')"
  [ "$s" -gt 0 ]
  sed -n "${s},${e}p" "$VL" | grep -qi 'one-directional'
}

@test "tier1_gating_verification-loop_memo_tier_token" {
  grep -qF 'tier=light|full' "$VL"
  grep -qF 'unit=t|-|n.a' "$VL"
}

@test "tier1_gating_verification-loop_na_gloss_light_only" {
  grep -qF 'unit=n.a' "$VL"
  grep -qiF 'never INCONCLUSIVE' "$VL"
  grep -qiF 'valid only on `tier=light` memos' "$VL"
}

@test "tier1_gating_verification-loop_push_invariant" {
  grep -qi 'push invariant' "$VL"
  grep -qiF 'tier=full` memo' "$VL"
}

@test "tier1_gating_verification-loop_ci_only_unconditional_rerun_unchanged" {
  grep -qF 'only unconditional re-run' "$VL"
}

PE="$SKILLS_DIR/plan-execution-skill/SKILL.md"

# =============================================================================
# Phase 2 — executor integration (plan-execution-skill)
# =============================================================================

@test "tier2_gating_plan-execution_light_gate_default" {
  [ -f "$PE" ]
  grep -qF 'is the per-phase default' "$PE"
}

@test "tier2_gating_plan-execution_exit_gate_full" {
  grep -qiF 'ticket exit gate' "$PE"
  grep -qiF 'runs full unconditionally' "$PE"
}

@test "tier2_gating_plan-execution_memo_tier_token" {
  grep -qF 'tier=light|full' "$PE"
}

@test "tier2_gating_plan-execution_escalation_logging" {
  grep -qiF 'WORK LOG line naming the anchor' "$PE"
}

@test "tier2_gating_plan-execution_never_push_red_unchanged" {
  grep -qF 'Never push red code' "$PE"
}
