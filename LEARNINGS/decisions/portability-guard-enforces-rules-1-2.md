# Portability guard: what it enforces and what it exempts

- **Category**: decisions
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #515

## Decision

`tests/test_portability.bats` enforces rules 1–2 of the portability contract
(#510); rule 3 (bash declarations) stays review-enforced — a grep cannot judge
whether a declaration is present for the *right* snippet, only whether one
exists somewhere. Four checks, all census-derived from the delivered tree:

1. No `.opencode/skills` literals in `skills/**/SKILL.md` (paths resolve via
   `SKILL_DIR`-style env vars, per #511).
2. Every `background: true` mention carries an `Other/none` fallback row
   (token per the #512 Mode R ruling).
3. Unix idioms (`xvfb|pkill|$DISPLAY`) require a frontmatter `os: "linux…"`
   declaration.
4. `os:`/`harness:` frontmatter values must match the canonical authoring form
   `"[a-z0-9]+(, [a-z0-9]+)*"` — quoted lowercase comma strings, never
   brackets.

`PORTABILITY_ROOT` overrides the tree so seeded-violation fixtures can prove
the guard fails (verified: 4 seeded violations → 4 failures).

## Exemptions

`.opencode/skills/` references OUTSIDE `skills/**/SKILL.md` are legitimate —
installer code, README, tests, `opencode_app/`, and THIRD_PARTY_LICENSES cite
real install destinations (census classified in #511). The guard scopes to
skill bodies, where such a literal is always a bug. Known follow-up:
`/tmp` snippet idioms in cad-gcode/cad-implicit/uiux-review are
declaration-class debt, deliberately not policed here.

CI fix (#515 first run): guard rewritten rg → POSIX grep after `rg: command
not found` on ubuntu runners; canary test catches vacuous sweeps. Also:
canonical-form check is rg -v regex inversion over a shared awk frontmatter
slicer (case-globs can't express character classes), `_archived/` excluded
(frozen artifacts), 5 checks total (4 rule checks + non-vacuous canary).
