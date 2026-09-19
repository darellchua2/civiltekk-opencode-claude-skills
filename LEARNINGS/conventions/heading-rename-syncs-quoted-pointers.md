# Convention: Heading renames must sync quoted § pointers

**Context**: Commit renamed a MIGRATION.md heading to add a ticket ref ("(#385)") and missed the verbatim quoted-title pointer in an agent file.
**Pattern**: When renaming any doc heading, `grep -rn` the old quoted title repo-wide — prose pointers (quoted § titles inside agent/skill files) are invisible to link checkers.
**Rationale**: Subagents locate sections by quoted title; a prefix mismatch makes them skip the referenced reasoning silently.
**Alternatives Considered**: Rely on link checkers — wrong, they only catch markdown links, not quoted prose titles.
**Evidence (2026-09-17, #383 trim)**: section *deletion* strands numeric anchors too — plan-automation-loop SKILL.md kept headings `E2E rule (6a)` / `Traceability (8)` / `Commit + push (9)` / `Final validation (10)` after its numbered step list was cut to 4 steps; sweep `(\(\d+[a-z]?\))` heading anchors whenever numbered sections die.
**Confidence**: 0.87
**Scope**: project
**Date**: 2026-09-15
