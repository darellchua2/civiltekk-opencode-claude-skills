# Guard-regex quote-shape mismatch false-greens on regression spellings

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Ticket**: #437

## Symptom

`tests/test_skill_isolation.bats` test 2 passed its mutation canary yet missed
8/10 realistic regression spellings — including the exact pre-#437 lines
(`parents[2] / "_common"`, `_SKILLS / "_common" / "scripts"`): the pattern
required a segmented `"_"` token, but every historical line used the
single-segment spelling `"_common"` (code-review #437, empirically run).

## Fix / Rule

Write grep guards against the **historical spellings in the codebase**, not a
canonical one (census the old lines before writing the pattern; prefer banning
the escape class outright, e.g. any `parents[N>=2]`). Mutation canaries must
plant the historical spellings plus single-quote variants, not just invented
ones. Companion: AGENTS.md contract bullets that name a guard must enumerate
only what the guard actually checks (see `doc-claims-match-plugin-defaults`).

Round-2 extensions (#437 re-review): (1) fence-scoped scanners must append a
trailing-unclosed-fence span — GitHub renders it to EOF, so the tail is a
runtime carrier, and without it the tail is silently unscanned while other
fences can mispair; (2) a canary pass that doesn't reproduce byte-exactly is
itself a finding — one round-1 "✓" came from grepping `^not ok 3` on a test
that was failing with an AttributeError, so every plant looked caught. Verify
canaries by running the target test alone and reading its failure output.
