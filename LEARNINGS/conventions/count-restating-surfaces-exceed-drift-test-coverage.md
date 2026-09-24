# Skill-count restating surfaces exceed what count-drift tests cover

**Category**: conventions
**Confidence**: 0.7
**Scope**: project
**Date**: 2026-09-24

## Convention

`tests/test_count_drift.bats` pins skill counts in the root README and deploy
scripts, but other docs restate the count outside that coverage —
`opencode_app/README.md` ("146 skill directories") went stale in #546 while
every tested surface was updated and the gate stayed green.

## Rule

On any skill-inventory change, grep ALL sibling docs for the count pattern, not
only the tested surfaces:

```bash
rg -n '14[0-9] skill|skills? directories|Skill catalog' README.md opencode_app/ docs/ *.md
```

Long-term fix: derive the count from `installer/registry.json` (single
generated source) wherever prose must state it.

Related: `directory-scoped-rename-sweep-misses-root-docs` (sibling-doc surface
missed by a scoped sweep).
