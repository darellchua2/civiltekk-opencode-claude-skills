#!/usr/bin/env bats

# Per-item deploy picker pins (#473): one pure module (deploy-plan-items)
# behind three drivers with identical plan output; DAG auto-include with
# provenance; setup wiring (provisioning, consume-once, per-mode matrix).

SETUP_SH="deploy/setup.sh"
SETUP_PS1="deploy/setup.ps1"
REGEN_MODULE="installer/deploy-plan-items.mjs"

@test "opentui_core_pinned_exact_with_lockfile" {
  grep -q '"@opentui/core": "0.5.11"' package.json
  grep -q '"@opentui/core": ' package-lock.json
}

@test "nvm_bumped_to_26_in_both_scripts_no_stale_24" {
  grep -q 'nvm install 26' "$SETUP_SH"
  grep -q 'nvm install 26' "$SETUP_PS1"
  ! grep -q 'nvm install 24' "$SETUP_SH"
  ! grep -q 'nvm install 24' "$SETUP_PS1"
}

@test "plan_items_auto_includes_agent_requires_skills_with_provenance" {
  # architecture-review-subagent requiresSkills: reviewer-baseline-skill (registry)
  node -e '
    import("./installer/deploy-plan-items.mjs").then(async (m) => {
      const { resolveSelection } = await import("./installer/init.mjs");
      const registry = JSON.parse(require("fs").readFileSync("installer/registry.json", "utf8"));
      const depMap = JSON.parse(require("fs").readFileSync("installer/dependency-map.json", "utf8"));
      const agent = registry.agents.find((a) => (a.requiresSkills || []).length > 0);
      if (!agent) { console.log("no requiresSkills agent in registry — pin vacuous"); return; }
      const plan = m.buildSelectionPlan({ choices: { agents: [agent.stem] }, registry, depMap });
      const pulled = plan.skills.find((s) => s.name === agent.requiresSkills[0]);
      if (!pulled) throw new Error(agent.requiresSkills[0] + " not auto-included");
      if (!pulled.source.startsWith("locked-by:")) throw new Error("no locked-by provenance on " + pulled.name);
      const directAgent = plan.agents.find((a) => a.name === agent.stem);
      if (directAgent.source !== "direct") throw new Error("direct agent misannotated");
    });
  '
}

@test "print_plan_is_deterministic" {
  run node deploy/tui.mjs select-items --print-plan --skills git-semantic-commits-skill --agents code-review-subagent
  [ "$status" -eq 0 ]
  local first="$output"
  run node deploy/tui.mjs select-items --print-plan --skills git-semantic-commits-skill --agents code-review-subagent
  [ "$output" = "$first" ]
}

@test "print_plan_auto_includes_locked_dependency" {
  run node deploy/tui.mjs select-items --print-plan --agents code-review-subagent
  [ "$status" -eq 0 ]
  [[ "$output" == *"reviewer-baseline-skill"* ]]
  [[ "$output" == *"locked-by:"* ]]
}

@test "print_plan_runs_headless_zero_tty" {
  run bash -c "node deploy/tui.mjs select-items --print-plan --skills git-semantic-commits-skill" </dev/null
  [ "$status" -eq 0 ]
}

@test "linear_empty_selection_matches_empty_print_plan" {
  run bash -c "printf 's\\ns\\ns\\ns\\ns\\n' | node deploy/tui.mjs select-items --driver linear 2>/dev/null | node -e 'let d=\"\"; process.stdin.on(\"data\",(c)=>d+=c).on(\"end\",()=>{const p=JSON.parse(d); console.log(JSON.stringify([p.skills.length,p.agents.length,p.packs.length]))})'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[0,0,0]"* ]]
  run node deploy/tui.mjs select-items --print-plan
  local empty
  empty=$(echo "$output" | node -e 'let d=""; process.stdin.on("data",(c)=>d+=c).on("end",()=>{const p=JSON.parse(d); console.log(JSON.stringify([p.skills.length,p.agents.length,p.packs.length]))})')
  [[ "$empty" == *"[0,0,0]"* ]]
}

@test "setup_select_mode_wiring_and_consumption_gates" {
  grep -q -- '--select)' "$SETUP_SH"
  grep -q 'SELECT_ITEMS" = true' "$SETUP_SH"
  grep -q 'provision_picker_deps()' "$SETUP_SH"
  grep -q 'npm ci --omit=dev' "$SETUP_SH"
  # consume-once: unlink only outside dry-run
  grep -q 'rm -f "$SELECT_PLAN_FILE"' "$SETUP_SH"
  grep -q '"$DRY_RUN" != true ]; then' "$SETUP_SH"
}

@test "select_steps_absent_from_skills_only_plan" {
  local d; d="$(mktemp -d)"
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; SKILLS_ONLY=true; SELECT_ITEMS=true; build_plan; printf '%s\n' \"\${PLAN_STEPS[@]}\""
  rm -rf "$d"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "select-items"
}

@test "select_mode_plan_has_picker_steps_and_no_blanket_agents" {
  local d; d="$(mktemp -d)"
  run bash -c "export HOME='$d'; source '$SETUP_SH' >/dev/null 2>&1; SELECT_ITEMS=true; build_plan; printf '%s\n' \"\${PLAN_STEPS[@]}\""
  rm -rf "$d"
  echo "$output" | grep -q 'select-items'
  echo "$output" | grep -q 'deploy-selected-skills'
  echo "$output" | grep -q 'deploy-selected-agents'
  echo "$output" | grep -q 'provision-tui'
}
