# Decision: two skill surfaces — root deployable + Docker-app project-scoped

**Category**: decision
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-20

## Decision

Keep both skill surfaces and the app-scoped allow as-is (#486, default per
#361's intent):

- **Root `skills/`** — the deployable surface (146 dirs with `SKILL.md`).
  Copied to `~/.config/opencode/skills/` by the deploy path (`deploy_content()`
  via the installer CLI — search-anchor `deploy_content` in `deploy/setup.sh`,
  #379; not the `restore` branch's `cp`); feeds
  `installer/build-registry.mjs` (registry) and the `npx add` flow.
- **`opencode_app/.opencode/skills/`** — the Docker-app project surface
  (exactly 1: `github-runners-setup-skill`, #361). Discovered only by
  sessions rooted at `opencode_app/`; never deployed to user space.

Consequence accepted: `github-runners-setup-skill`'s allow rule in
`opencode_app/opencode.json` is dead weight in user deploys (the skill never
copies there) — the cost of the Docker app sharing the deploy config base.

**Revisit trigger:** if the app grows more project-scoped skills, split the
app config base from the deploy base (or add an app-specific profile)
instead of accumulating dead-in-user-deploy rules.

## Enforcement (this decision's guard)

`tests/skill_profiles.bats` (#486) validates every shipped skill allow
against the UNION of both surfaces (dead rules fail CI) and asserts the
surfaces stay disjoint (a same-named dir on both surfaces collides;
project-vs-global precedence is unverified upstream — the assert is
conservative under any rule). Guards filter by `SKILL.md` presence — raw `skills/`
readdir includes the `_archived` legacy dir.

## Context

#481 code review flagged `github-runners-setup-skill` as a phantom allow
(no root `skills/` dir). Investigation (#486) found it alive on the second
surface — the flag itself was a single-surface derivation error, the second
such miss that session (see `anti-patterns/two-surface-count-conflation.md`).

Related: `decisions/skill-permission-allowlist.md` (its "106 allows" is
105 deployable + this 1 app-scoped), #361, #481, #485.
