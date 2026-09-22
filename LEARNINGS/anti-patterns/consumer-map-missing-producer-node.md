# Consumer map missing producer node

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #510

## Symptom

#510's Dependency & Consumer Map listed only its direct edit targets
(AGENTS.md, SKILL.md, registry.json) and omitted `installer/build-registry.mjs`
— the only component that parses SKILL.md frontmatter into registry.json
(extracting just `audience`/`workflow` at build-registry.mjs:222-223), while
`installer/init.mjs` reads registry.json exclusively (init.mjs:45,146). The
contract prose promised "#514 adds the installer/init.mjs warning", but that
warning is unimplementable without extending the omitted producer — a
mid-pipeline rescope discovered only by code review.

## Fix / Rule

Before committing a consumer map, walk the full data path — **producer →
carrier → consumer** — not just the diff's files. Any node that must change for
a downstream ticket's acceptance criterion to pass belongs in the map (even
marked "not edited here"), and the downstream ticket's scope must name it.
