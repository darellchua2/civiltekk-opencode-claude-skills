#!/usr/bin/env bats

# v2 pipeline contract guard (#613 review NOTE-5, implemented in #617).
# The /run-worktree-pipeline-v2 command entry has been reshaped 3 times
# (#585 -> #591 -> #613) with no drift guard; the inline-workers preset
# gained 7 members with no membership guard. These tests pin both.

SETUP_ROOT="."
V2_KEY="run-worktree-pipeline-v2"
PRESET="installer/presets/pack-inline-workers.json"

v2_template() {
  node -e "const c=require('./deploy/opencode.json').commands['${V2_KEY}'];console.log(c.template)"
}

@test "v2_pipeline: command entry pins subagent:false" {
  run node -e "const c=require('./deploy/opencode.json').commands['${V2_KEY}'];process.exit(c.subagent === false ? 0 : 1)"
  [ "$status" -eq 0 ]
}

@test "v2_pipeline: template carries the zero-subagent directive" {
  run v2_template
  [ "$status" -eq 0 ]
  [[ "$output" == *"spawn NO subagents anywhere in the run"* ]]
}

@test "v2_pipeline: template carries in-session checklist mechanics for steps 7/9/10" {
  run v2_template
  [[ "$output" == *"code-review-inline-skill"* ]]
  [[ "$output" == *"agents/pr-workflow-subagent.md as your in-session checklist"* ]]
  [[ "$output" == *"reviewer-baseline-skill"* ]]
}

@test "v2_pipeline: no Docker dead-letter agent paths in any command template" {
  run grep -c "app/.opencode/agents" deploy/opencode.json
  [ "$status" -eq 1 ]
  [ "$output" = "0" ]
}

@test "v2_pipeline: preset description carries no preflight caveat" {
  run grep -c "lack the pipeline skill" "$PRESET"
  [ "$status" -eq 1 ]
  [ "$output" = "0" ]
}

@test "v2_pipeline: every inline-workers preset skill resolves on disk" {
  run node -e "
    const fs = require('fs');
    const skills = require('./$PRESET').skills;
    const missing = skills.filter(s => !fs.existsSync('skills/' + s + '/SKILL.md'));
    if (missing.length) { console.error('missing: ' + missing.join(', ')); process.exit(1); }
  "
  [ "$status" -eq 0 ]
}

@test "v2_pipeline: preflight is arm-aware (both executor skills named)" {
  run grep -c "plan-execution-inline-skill" skills/worktree-pipeline-skill/SKILL.md
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
  run grep -c "resolved per arm" skills/worktree-pipeline-skill/SKILL.md
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}
