# Guard test literals are plan consumers

- **Category**: anti-patterns
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-26
- **Summary**: Pinned literals inside guard tests are consumers of every artifact the PLAN touches — traverse `tests/*.bats` for the artifact's name before writing a done-when. #582's plan missed three in one step-set: `test_requires_skills.bats:76` (exact-map equality on requiresSkills), `skill_profiles.bats:44,105` (72-count literals), `init.bats:58` (preset count 9). Generalizes #408's `profile-membership-breaks-count-arithmetic` from counts to any guard-pinned invariant. **Rule:** for each planned artifact, grep the test suite for its name/count and add the literal update to the same commit as the artifact change.
