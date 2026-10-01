# Backtick phrase pins inside bats `[[ ]]` assertions trigger command substitution

**Date:** 2026-09-30 · **Confidence:** high · **Scope:** any bats test pinning prose that contains backticks

## Body

A test pin like `[[ "$output" == *"`skill-name` (create route)"* ]]` inside double quotes lets bash
execute the backtick content as command substitution — the assertion tests the output of a command
named `skill-name`, not the literal phrase, and fails or passes for the wrong reason. When a contract
test must pin template prose that quotes skill names in backticks (the house SKILL.md/template style),
pin the backtick-free substrings instead — one assertion per fragment:

```bash
[[ "$output" == *"civiltekk-pr-workflow-skill"* ]]
[[ "$output" == *"create route"* ]]
```

Seen while replacing the Step 10 pin in `tests/test_v2_pipeline_contract.bats` (#652): the old pin
(`agents/pr-workflow-subagent.md as your in-session checklist`) was backtick-free, so the hazard only
appears when the new phrase quotes a skill name. Related: case-sensitive pin matching
(`anti-patterns/case-sensitive-grep-gates-false-green.md`) — fragments must match the template's exact case.
