# Plugin pickers filtering by filename prefix drop companion files the plugin needs

- **Category**: anti-pattern
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #473 (review round 2)

## Symptom

The #473 picker offered `plugins/opencode-*` items; selecting
opencode-vibeguard.ts copied the plugin but not `plugins/vibeguard.config.json`
— which the plugin documents as fail-open (missing config ⇒ no masking). The
picker path shipped an inert security plugin while the blanket deploy_plugins
path (whole-dir copy) shipped it correctly.

## Rule

Selectable plugin filters must model companion files: restrict items to the
plugin's real entry files (.ts) and copy documented companions alongside at
consumption. A prefix filter over a directory listing silently excludes every
file that is not itself an item.

## Evidence

- #537 (implemented): `scanPluginNames` (.ts-only) is now the single filter;
  companions copy at consumption from `dependency-map.json` `pluginCompanions`
  — see `patterns/plugin-companions-declarative-single-home`. Resolved.
