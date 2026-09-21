# PLAN: Collapse flash-class models onto glm-5.3-flash in catalog

**Branch**: feat/522
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/522
**Base**: main

## Acceptance Criteria
- [ ] `grep -rniE "glm-4\.5-flash|glm-4\.7-flash|glm-5\.3-flashx" . --exclude-dir=.git --exclude-dir=PLANS --exclude-dir=LEARNINGS --exclude=CHANGELOG.md` returns zero hits
- [ ] `zai` array retains `glm-5.3` and `glm-5.3-flash`; `zai-coding-plan` and `zai-custom` byte-identical
- [ ] `$comment` documents the flash-class standardization + regen re-add caveat without naming purged ids
- [ ] Full bats suite green; build-registry run, `registry.json` committed if content-differs

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/provider-models.json` | — | `installer/resolve-models.mjs` (`--provider-models` fail-fast guard), `deploy/regen-provider-models.mjs`, `deploy/setup.sh` (`--check-catalog` pass-through, warn-only), `opencode_app/Dockerfile` (flag pass-through), `installer/init.mjs` (advisory `modelAvailabilityNote` only), `tests/test_provider_pins.bats`, `tests/test_provider_regen.bats` | med — array removals only |

Cross-module consumers exist → architecture review selected, scoped to re-verifying #520's proven consumer facts against the new id set (guard validates resolved pins only — nothing pins these ids per #520 review; arrays must stay non-empty — 10 entries remain; regen is fixture-driven and does not run in CI).

## Implementation Phases

### Phase 1: Catalog purge
- [x] **1.1** Remove `glm-4.5-flash`, `glm-4.7-flash`, `glm-4.7-flashx`, and `glm-5.3-flashx` from the `zai` array in `installer/provider-models.json` (10 entries remain, incl. `glm-5.3` + `glm-5.3-flash`). `glm-4.7-flashx` included by class extension of the maintainer directive (same flash class as the three named) — flagged for review confirmation.
    — **Why:** maintainer directive (#522) — the flash class collapses onto `glm-5.3-flash`; listing legacy flash ids as selectable implies maintained options. (`glm-5.3` alone remains the reasoning/frontier pin; non-flash sub-frontier ids are this ticket's out of scope.)
    — **Done when:** `python3 -c` array check shows none of the 4 ids present, `glm-5.3` + `glm-5.3-flash` retained, `zai-coding-plan`/`zai-custom` untouched, and JSON parses.
    — **Consumers affected:** `resolve-models.mjs` guard (no tier/preset pins these ids — proven in #520 review, re-verified in Step 7); `deploy/regen-provider-models.mjs` (see Risks).
    — **Done:** 4 ids removed, 10 remain, glm-5.3/glm-5.3-flash retained, zai-coding-plan/zai-custom untouched; files: installer/provider-models.json; fixes: none
- [x] **1.2** Extend the `$comment` standardization sentence: after the #516 vision sentence, add that sub-frontier non-vision flash-class models are likewise standardized onto `glm-5.3-flash` (#522) and `glm-5.3` stays the sole reasoning/frontier pin — token-free, regen re-add caveat shared.
    — **Why:** the comment is the maintainer contract; without the extension it under-describes the deliberate divergence and the next regen partially reverts it.
    — **Done when:** comment contains "flash-class" + "#522" + the regen caveat, and names none of the 4 purged ids.
    — **Consumers affected:** maintainers; none mechanical.
    — **Done:** #522 flash-class sentence appended token-free with shared regen caveat; files: installer/provider-models.json; fixes: none

### Phase 2: Verification + registry sync
- [ ] **2.1** Repo-wide purge proof: `grep -rniE "glm-4\.5-flash|glm-4\.7-flash|glm-5\.3-flashx" . --exclude-dir=.git --exclude-dir=PLANS --exclude-dir=LEARNINGS --exclude=CHANGELOG.md`.
    — **Why:** ticket AC — total purge outside historical records (inventory already showed catalog-only presence).
    — **Done when:** zero matches.
    — **Consumers affected:** none.
- [ ] **2.2** Run gates: full bats suite `bats tests/` (ticket exit gate — provider_pins + provider_regen cover the catalog consumers).
    — **Why:** provider-models.json is guard- and regen-consumed.
    — **Done when:** `bats tests/` exits 0.
    — **Consumers affected:** deploy guard users (confidence).
- [ ] **2.3** Run `node installer/build-registry.mjs`; commit `registry.json` if content-differs (timestamp-only churn is still committed per house rule).
    — **Why:** house sync rule after registry-adjacent changes.
    — **Done when:** command exits 0; `git status` clean after commit.
    — **Consumers affected:** installer registry consumers.

## Technical Notes
- Inventory (post-#520, repo grep excluding .git/PLANS/LEARNINGS/CHANGELOG): the 4 ids appear ONLY in `installer/provider-models.json` — no docs, presets, tier maps, agent/skill files, or `opencode_app` config reference them, so removal needs no remapping.
- Tier reality is already two-model: `models.default.json` and all 8 provider presets pin only `glm-5.3` / `glm-5.3-flash` (#520 architecture review).

## Dependencies
None — single ticket, no `blocked-by`.

## Risks & Mitigation
- **Regen re-adds purged ids**: same known ceiling as #516 — models.dev still lists them; the `$comment` documents strip-after-regen until `deploy/regen-provider-models.mjs` gains a purge exclusion list.
- **Guard warning churn**: only if something pins the removed ids — nothing does (proven #520, re-verified Step 7).

## Gate Trace
GATE c0e1e62 tier=light lint=n.a typecheck=n.a build=n.a unit=t(scoped: provider_pins+provider_regen) e2e=n.a
