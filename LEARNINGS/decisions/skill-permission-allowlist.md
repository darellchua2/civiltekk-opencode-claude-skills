## Decision: Skill permission allowlist — shipped 146, lean profile 70 (post-#481), deploy default lean

> **Update 2026-09-20 (#481):** the "Subagents are profile-immune" claim below is **UNVERIFIED for the `skill` action on opencode v2.0.11** — agent-frontmatter skill allows are ignored in child sessions (upstream [anomalyco/opencode#50149](https://github.com/anomalyco/opencode/issues/50149)), while tool-action rules (`shell`, proven by #482's probe matrix) DO apply. Interim workaround adopted: the 4 reviewer agents' skill union is config-allowed (full +3 → 106 allows; lean +26 → 70 — reviewer-only scope; the all-agent union would push lean to 145/146 and abolish the profile; the other 28 agents' frontmatter allows stay deferred to the upstream fix). Revert = remove the 26 from `deploy/skill-profiles.json` lean **and** the 3 added allows from `opencode_app/opencode.json`, then redeploy; re-check per opencode upgrade with the 3-step probe (spawn reviewer → invoke skill id → expect `loaded`). Revised lean savings ~3.2k tok/session (36 hidden × ~90 tok).

**Context**: Primary session loads every skill's `description` into `<available_skills>` at startup (~146 skills on disk = significant per-session token tax). GIT-333 added a deploy-time profile so downstream users choose visibility without hand-editing.
**Pattern**: Ship a `permissions` array in `opencode_app/opencode.json` with the deny-all skill rule first (`{"action":"skill","resource":"*","effect":"deny"}`) followed by **106 allows** (`{"action":"skill","resource":"<skill>","effect":"allow"}`; last matching rule wins = the `full` profile, single source of truth; "shipped 146" in the header = skill-dir count, not allow count). `deploy/skill-profiles.json` defines `lean` (**70 allows** post-#481). `./deploy/setup.sh --skill-profile lean|full` (default **lean**) rewrites ONLY the `action:"skill"` rules in the deployed copy's `permissions` array via `deploy/apply-skill-profile.mjs` — the shipped file is never modified by deploys. (Updated for opencode v2 2026-09-14: was v1 `"permission.skill"` map.)
**Rationale**: full allows hide subagent-only skills from the primary; lean (post-#481) hides 36 (≈3.2k tokens/session at ~90 tok/description; pre-#481 lean hid 59 ≈ 5.4k). Subagents are profile-immune — **unverified for the `skill` action on v2.0.11, see the update block above**: every skill has either a frontmatter skill-allow consumer or a lean slot, but frontmatter allows do not load in child sessions until upstream #50149 fixes it. New skills default to hidden until explicitly added. Counts re-derived 2026-09-20 — they drift per skill-add; re-derive as `total − allows` before citing.
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
- `opencode_app/opencode.json` — `permissions` array: deny-all skill rule first + 107 skill allows (= full profile)
- `deploy/skill-profiles.json` — lean profile (48 keys)
- `deploy/apply-skill-profile.mjs` — deploy-time rewriter (edits only `action:"skill"` rules; typo-guarded, fail-closed)
- `deploy/.AGENTS.md` — "Skill Allowlist" documentation section
- Issue #270, PR #271; Issue #333
