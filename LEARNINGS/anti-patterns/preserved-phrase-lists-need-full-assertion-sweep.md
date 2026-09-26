# Anti-pattern: preserved-phrase lists need a full assertion sweep

When a restructure must preserve grep-asserted phrases (bats guards that hold
a contract's wording in place), enumerating the preserved list by reading only
the section being edited misses assertions that target OTHER sections in the
edit region.

PLAN-560 step 4.1 preserved the four Step-10 phrases it knew about, but
`tests/test_tiered_gating.bats` also asserts `Step 9 code review` and
`(unconditional) backstops` — phrases living in Step 7's prose, inside the
region the same PLAN phase edits. The omission was caught in review, not by
the author.

**Rule:** before restructuring a file with phrase assertions, derive the
preserve-list from the assertion file — grep the test for every literal it
checks against the target file — not from the section you plan to touch.

- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-25
