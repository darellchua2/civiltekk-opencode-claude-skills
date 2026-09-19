# Anti-pattern: normative rule added, in-file example left stale

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Added**: 2026-09-19 (#417 re-review)

Adding a normative rule to a skill (e.g. title-prefix parity at `ticket-creation-skill/SKILL.md:148`) without updating the same file's Example Usage that illustrates the flow leaves the example teaching the deprecated behavior — examples are the strongest prompt signal agents copy. Genus of `heading-rename-syncs-quoted-pointers`: when a commit adds or changes a rule, sweep the file's own examples of that flow in the same commit.
