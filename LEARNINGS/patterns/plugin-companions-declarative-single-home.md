# Plugin companion artifacts live in dependency-map.json pluginCompanions — never in shell arms

- **Category**: pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-23
- **Ticket**: #537

## Context

Two deploy paths write repo `plugins/` artifacts into the target's plugin
dir: the manifest path (`init.mjs` `shipPluginArtifacts`, driven by the
skill→plugin `shipsPlugins` edges) and the `--select` picker path
(`deploy/setup.sh` `apply_selected_packs_extras`). #537's first draft gave
the picker path a bash `case` with the companions hardcoded — a second home
for what `shipsPlugins` already declared, so the next companion-bearing
plugin would work on one path and arrive broken on the other (arch review
rejected the draft; `plugin-picker-prefix-filter-drops-companions` recurring).

## Rule

`installer/dependency-map.json` `pluginCompanions` is the ONE declarative
home: plugin file name → companion artifacts, trailing slash = whole
directory. The picker path consumes it via the function's existing `node`
idiom (fail-closed lookup — see
`companion-lookup-fail-open-consumes-plan`), with `rm -rf`-first before
directory copies so re-runs never nest. Enforcement is structural:
`apply_selected_packs_extras_hardcodes_no_plugin_names` (grep pin) and
`plugin_companions_cover_ships_plugins_facts` (per-edge cross-surface pin).
Next companion-bearing plugin: edit the map, never setup.sh.
