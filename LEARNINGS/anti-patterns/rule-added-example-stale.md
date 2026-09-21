# Anti-pattern: normative rule added, in-file example left stale

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Added**: 2026-09-19 (#417 re-review)

Adding a normative rule to a skill (e.g. title-prefix parity at `ticket-creation-skill/SKILL.md:148`) without updating the same file's Example Usage that illustrates the flow leaves the example teaching the deprecated behavior — examples are the strongest prompt signal agents copy. Genus of `heading-rename-syncs-quoted-pointers`: when a commit adds or changes a rule, sweep the file's own examples of that flow in the same commit.

**Evidence (2026-09-21, #506, two hits in one PR):** PLAN-506 step 2.8 instructed dropping `Invoke-SkillProfile` text from a file that no longer contained it (the real target was `new-skill-count-literal-gates.md:10`) — re-grep the plan's target text at plan-freeze time; and the regenerated `_index.md` carried pre-repoint summaries for files the same PR repointed — when a learning's facts change, its index entry (heading + summary) changes in the same write (now codified in continuous-learning-skill step 5).
#510 instance: skills/agent-introspection-debugging-skill/SKILL.md:98 still
asserts "the v2 frontmatter contract reserves metadata sub-keys
`protocol`/`pattern` only" in present tense after #510 extended the contract to
four sub-keys — the strongest remaining teacher of the superseded rule. Scope
historical claims ("at the time, pre-#510") when a rule change lands; fold the
fix into #515 docs-sync.
