# Frontmatter key rewrites scope to the frontmatter slice

- **Category**: solutions
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-26
- **Summary**: **Frontmatter-key regex rewrites in translators must scope to the frontmatter slice, never the whole document.** Agent bodies carry fenced examples of frontmatter shapes — `agents/opencode-tooling-subagent.md:167` teaches `steps: 5` inside a ```yaml block while its own frontmatter has no `steps:` — so `zcodeAgentContent`'s whole-doc `/^steps:/m` replace (installer/init.mjs, #581) silently rewrote the body example to `maxTurns: 5`, breaking the translator's verbatim-body contract. Cross-ref `frontmatter-shape-change-blast-radius`, whose evidence already flags this exact file's fenced examples (post-#380). **Rule:** detect and rename keys within `lines.slice(1, closeIdx)` during insert assembly, and grep the corpus for `^<key>:` outside frontmatter before adding any new rename. Companion: account for rename side effects in a translator's no-op early-return predicate (an agent needing no translation but carrying the key must not early-return past the rename).
