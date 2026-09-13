## Decision: Skill permission allowlist — shipped 148, lean profile 46, deploy default lean

**Context**: Primary session loads every skill's `description` into `<available_skills>` at startup (~148 skills = significant per-session token tax). GIT-333 added a deploy-time profile so downstream users choose visibility without hand-editing.
**Pattern**: Ship a `permissions` array in `opencode_app/opencode.json` with the deny-all skill rule first (`{"action":"skill","resource":"*","effect":"deny"}`) followed by **105 allows** (`{"action":"skill","resource":"<skill>","effect":"allow"}`; last matching rule wins = the `full` profile, single source of truth). `deploy/skill-profiles.json` defines `lean` (**46 allows**, incl. `opencode-repo-setup-skill` added in GIT-333 Phase 7). `./deploy/setup.sh --skill-profile lean|full` (default **lean**) rewrites ONLY the `action:"skill"` rules in the deployed copy's `permissions` array via `deploy/apply-skill-profile.mjs` — the shipped file is never modified by deploys. (Updated for opencode v2 2026-09-14: was v1 `"permission.skill"` map.)
**Rationale**: 105 allows hides 43 subagent-only skills from the primary; the lean profile hides 59 more (102 total, ~3.9k tokens/session, measured 2026-08-14). Subagents are profile-immune: every skill has either a frontmatter `permission.skill: allow` consumer (41 self-scoped pre-GIT-333 + 17 added in GIT-333 Phase 1) or stays primary-visible in lean (pdf-specialist, opencode-repo-setup). New skills default to hidden until explicitly added. Counts verified against registry + profiles 2026-09-09 — they drift per skill-add; re-derive as `total − allows` before citing.
**Alternatives Considered**: Denylist (rejected — hides fewer skills, poor scaling). Hardcoding lean into opencode.json (rejected — this repo is an agnostic configurator; defaults belong to deploy-time selection, symmetric with `--provider`).
**Trade-offs**:
- Pro: ~3.9k tokens/session saved on default deploys (measured); one-line `deploy/skill-profiles.json` edit re-exposes any skill; `full` is always available
- Con: lean-hidden skills cannot be @-loaded by the primary until re-exposed (documented in README profile section)
- Con: new skills need a frontmatter consumer (or a profiles entry) to be visible anywhere
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-08-14

**Superseded constraint (former "13 must-keep")**: pre-GIT-333, 13 skills had NO consumer subagent override and had to stay primary-visible. As of GIT-333 Phase 1 every skill has a frontmatter consumer or a lean slot — the constraint is lifted. Full 58-skill classification (41 self-scoped, 17 new allows, 0 intentionally-hidden): recorded in the GIT-333 plan appendix (plan since purged per repo lifecycle).

**References**:
- `opencode_app/opencode.json` — `permissions` array: deny-all skill rule first + 105 skill allows (= full profile)
- `deploy/skill-profiles.json` — lean profile (46 keys)
- `deploy/apply-skill-profile.mjs` — deploy-time rewriter (edits only `action:"skill"` rules; typo-guarded, fail-closed)
- `deploy/.AGENTS.md` — "Skill Allowlist" documentation section
- Issue #270, PR #271; Issue #333
