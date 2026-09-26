# Preset closure over new requiresSkills handoffs

- **Category**: decisions
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-26
- **Summary**: When an opt-in experiment needs skill groupings, express the dependency closure in the preset member list, not as new `dependency-map.json` `requiresSkills` edges — the isolation contract (#437) enforces a single declared handoff (`test_requires_skills.bats:74-76` exact-match against HANDOFF_OWNER/HANDOFF_TARGET), and each new edge is a guard redesign (~a ticket of its own). Preset membership carries no such invariant. Adopted for #582's inline family (8-skill closure in pack-experiment.json).
