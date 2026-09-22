# Pattern: re-vendor version-string census

A re-vendor PLAN must own the old-version-string census, not just the pin
files it happens to touch.

PLAN-533 bumped 2 of 18 files carrying `v4.8.4` (verified
`rg -l 'v4\.8\.4'`: 8 agent provenance markers, plugin wrapper header,
instructions.cjs header, two README sections, 3 derived-skill vendored
headers, plus the pin files themselves) — and two of its steps actively
forbade touching theirs ("keep each lens's provenance marker intact",
"no edits to derived skills").

**Rule:** a re-vendor's exit gate is `rg -l '<old-version>' --glob '!PLANS/**'`
→ zero (or an explicit allowlist). A stale pin in 13 files means the next
maintainer trusts a lying version — the exact failure ATTRIBUTION.md warns
about.

- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-22

Found by architecture review of PLAN-533 (#533): the census undercount was
itself caught twice (16 → 17 → 18 files across two review passes) — run the
grep, never trust the enumeration.
