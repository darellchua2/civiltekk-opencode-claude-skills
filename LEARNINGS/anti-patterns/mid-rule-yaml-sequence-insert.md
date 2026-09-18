## Anti-pattern: Inserting a YAML sequence item between an existing item's lines

**Context**: Adding a value-only rule to an agent frontmatter `permissions` array (PLAN-404, gh-cli-setup-skill allow rule).
**Pattern**: NEVER insert the new `- action:` lines directly after an existing item's `resource:` line. A YAML sequence item is 3 lines (`- action` / `resource` / `effect`); inserting between lines 2 and 3 orphans the trailing `effect:` key onto the NEW item, silently stripping it from the OLD rule. Always insert a COMPLETE new item after the previous item's last key.
**Rationale**: Every existing gate passes on this defect: `build-registry.mjs --check` (reads `resource` names only — unchanged), a "+N lines" frontmatter shape check (line count is correct), and bats (no test parses these agents' frontmatter). Only a per-rule key-completeness parse catches it.
**Verification**: after any frontmatter array insertion, yaml-parse each rule and assert every `{action, resource, effect}` triple is complete: `python3 -c "import yaml,sys; fm=yaml.safe_load(open('agents/X.md').read().split('---')[1]); assert all(set(r)=={'action','resource','effect'} for r in fm['permissions'])"`.
**Fix command** (if already shipped): move the 2 inserted lines below the `effect:` line they orphaned; registry needs no rebuild (resources unchanged).
**Confidence**: 0.95
**Scope**: project
**Date**: 2026-09-19

**Evidence**: PLAN-404 code review — `agents/pr-workflow-subagent.md:50-54` and `agents/repo-ops-specialist-subagent.md:49-53` both ended with `resource: pr-creation-workflow-skill` immediately followed by the new `- action: skill` item; the diff's own context line `effect: allow` proved the orphaned key belonged to the pr-creation rule on main. Review gates (registry --check, +2-line awk shape diff, bats 6/6) all green on the broken state.
