## Solution: opencode plugins need BOTH plugin array entry AND command config block

**Context**: When a plugin's slash command (e.g., `/goal`) stops working after config changes.
**Pattern**: Plugins like `opencode-goal-plugin` require TWO config entries (v2 key names):
1. `"plugins": ["opencode-goal-plugin"]` — loads the plugin code (hooks, tools, state management)
2. `"commands": { "goal": { "template": "$ARGUMENTS", "agent": "build" } }` — defines the `/goal` slash command entry point

**Rationale**: The plugin provides BEHAVIOR (auto-continuation, state persistence, evidence-gated completion). The `command` block provides the ENTRY POINT (`/goal` slash command). Removing the command block removes the command — the plugin code loads but has nothing to trigger it.
**Alternatives Considered**: Assume plugin self-registers its command. Wrong — confirmed by the plugin README which explicitly shows both entries are needed.
**Trade-offs**: None — both entries are required per the plugin's install instructions.
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-07-26

**Evidence** (v1-era; key names above updated to v2):
- Provider Packs #268 removed `command.goal` block assuming the plugin provides it
- `/goal` disappeared after the merge
- Plugin README Install section explicitly shows both `plugin` array + `command` block
- Restoring `command.goal` + full opencode restart fixed it

**Diagnostic steps** (if a plugin command stops working):
1. Check `opencode debug config | grep -A4 '"commands"'` — is the commands block present?
2. Check the plugin README — does it require a `command` block?
3. Check the plugin cache: `~/.cache/opencode/packages/<plugin>@latest/` — is it installed?
4. If all present: **fully restart opencode** (config is read at startup only, no hot-reload)
