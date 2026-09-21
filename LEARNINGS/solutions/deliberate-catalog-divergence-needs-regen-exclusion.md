# Solution: Deliberate catalog divergence needs regen exclusion

A deliberate divergence from a generated catalog (`installer/provider-models.json` "MUST track models.dev" vs a purge mandate that removes still-cataloged ids) is unenforced: `deploy/regen-provider-models.mjs` regenerates catalog-derived keys wholesale and its `--check` drift mode is warn-only — so the next routine regen silently reverts the purge. Fix once where all maintainers route through: an exclusion list in the regen script; interim ceiling is a reconciling `$comment` sentence naming the re-add behavior so the maintainer strips rather than keeps. Record the ceiling and the upgrade trigger, don't leave the contradiction undocumented.

**Confidence:** medium
**Scope:** project
**Evidence:** installer/provider-models.json `$comment` + deploy/regen-provider-models.mjs:93 (warn-only) + PLANS/PLAN-516.md Risks, code review 2026-09-21 (WARN-2)
**Date:** 2026-09-21
