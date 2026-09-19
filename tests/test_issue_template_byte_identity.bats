#!/usr/bin/env bats

# Byte-identity pin for the issue-template forms (PLAN-417, AC #3).
# .github/ISSUE_TEMPLATE/*.yml are deployed instances of
# skills/ticket-creation-skill/templates/*.yml — a one-time cmp at authoring
# time decays silently; this pins the pairs (extends the bats-structure-pin
# idiom to file pairs). Also pins the SKILL.md field-spec tables to the form
# labels verbatim (AC #1) so agent-created and human-created tickets stay
# structurally identical.

FORMS_DIR=".github/ISSUE_TEMPLATE"
TEMPLATES_DIR="skills/ticket-creation-skill/templates"
SKILL_MD="skills/ticket-creation-skill/SKILL.md"

@test "issue_template_forms_byte_identical_to_skill_templates" {
  for f in bug_report.yml feature_request.yml config.yml; do
    cmp -s "$FORMS_DIR/$f" "$TEMPLATES_DIR/$f"
  done
}

@test "bug_form_labels_match_skill_field_spec" {
  # Labels are matched as BRE substrings — safe for the current set (only
  # literal '/'). Keep new labels free of . ( [ * or switch to grep -F and
  # drop the '$' anchor.
  for label in "Problem description" "Steps to reproduce" "Expected vs Actual" "Environment" "Logs / screenshots" "References"; do
    grep -q "label: $label$" "$TEMPLATES_DIR/bug_report.yml"
    grep -q "$label" "$SKILL_MD"
  done
}

@test "feature_form_labels_match_skill_field_spec" {
  for label in "Problem / use case" "Proposed solution" "Alternatives considered" "Acceptance criteria" "References"; do
    grep -q "label: $label$" "$TEMPLATES_DIR/feature_request.yml"
    grep -q "$label" "$SKILL_MD"
  done
}
