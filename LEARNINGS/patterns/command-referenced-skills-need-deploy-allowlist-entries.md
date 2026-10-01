# Command-referenced skills need an entry in the deploy skill allowlist

**Date:** 2026-10-01 · **Confidence:** high · **Scope:** `deploy/opencode.json` permissions; any skill named by a shipped command template

## Body

`deploy/opencode.json` gates skills with a catch-all `{"action":"skill","resource":"*","effect":"deny"}`
followed by explicit allows — any skill **named by a shipped command** but lacking an allow entry is
unresolvable at runtime in every deploy-config session. Observed 2026-09-30: the v2 pipeline's Step 7
and `/review-inline` both name `architecture-review-skill`, which was missing from the allowlist; the
in-session load was permission-denied mid-run and the reviewer had to be skipped. The skill's
frontmatter was valid and deployed==source — only the allowlist entry was missing.

Audit one-liner: diff the `action:"skill"/allow` resource set against every backtick-quoted skill name
in the `commands` templates/descriptions. As of the fix, the only command-referenced gap was
`architecture-review-skill`; the ~29 other unallowlisted skills (CAD/pptx/autoresearch/office families)
are referenced by no shipped command — scoped out by design, opt-in per repo.
