# Pattern: Skill-content trim with verbatim preservation (the #383 recipe)

**Context**: 93% content cut across 51 SKILL.md files (issue #383) under the rule "a skill encodes only what is house-specific: triggers, conventions, version-pinned facts, workflow contracts, codified learnings".
**Pattern**: Freeze frontmatter byte-identical per file; preserve every `Learning:` entry verbatim (rule + detection); keep external anchors (user-AGENTS.md §Authoring Quality Gate) and live workflow contracts (gate order, verdict/marker protocols, budgets, MCP guards) fully intact; delete textbook prose the model already knows; append a dated removal-note blockquote recording exactly what was dropped and what was kept; add a "Compose, don't duplicate" pointer section instead of restating sibling skills.
**Rationale**: Frontmatter and Learning entries are contract surfaces other files quote and diff against; bodies are model-known knowledge that costs context in every session that loads the skill.
**Alternatives Considered**: Tighten learnings' wording while trimming — rejected, breaks byte-identity verification and the original incident phrasing.
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-17
