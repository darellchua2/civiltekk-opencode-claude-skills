# Anti-pattern: merge-resolved JSON duplicate keys pass every lenient gate

Resolving a merge conflict by deleting one side's line can duplicate the
neighbor line; JSON parsers last-win, so bats + `--check` stay green while a
future single-copy edit gets silently shadowed.

**Rule:** after conflict resolution, structurally verify resolved hunks
against the non-conflicted side (duplicate-key check per object), not just by
gate status. Found live in #372's `installer/agent-tiers.json` (2026-09-19).
