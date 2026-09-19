# Derive consistency pins from the source-of-truth file at runtime

- **Category**: convention
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Ticket**: #439

## Rule

A test that pins two files to each other must derive its expectation from the
source-of-truth file at runtime (grep HANDOFF_OWNER/HANDOFF_TARGET out of
`tests/test_skill_isolation.bats`, as `tests/test_requires_skills.bats` does)
— not restate the literals in both files (the
`tests/test_docling_skill.bats` impliesMcp style). Derived pins turn drift
into a hard test failure instead of two files aging separately.
