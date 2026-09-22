# Anti-pattern: shipped side artifacts need a full lifecycle

Wiring a new artifact class into the install paths but not the maintenance
commands leaves it stale or orphaned on the documented refresh path.

#533 shipped plugin artifacts (shipsPlugins) in `add` (both scopes) but
initially skipped `cmdUpdate` — `npx update` refreshed skill bodies while
`~/.config/opencode/plugins/` kept injecting the old vendored ruleset, the
ticket's exact "docs, not enforcement" problem, silently. Related gaps in
the same review: project-scope manifest rewrites orphaned the plugin record
(doPrune could never remove them), and `remove` had no interplay.

**Rule:** every new installable artifact class enumerates add / update /
remove / prune up front — or ships an explicit stay-put note in each
maintenance command's output. Refresh source = manifest record ∪ current
edge map (edges get renamed; the manifest is the system of record), filtered
to the targets that actually receive the artifact class.

- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-22
