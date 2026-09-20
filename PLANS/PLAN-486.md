# PLAN: Surface-explicit skill allows — union guard + count honesty (#486)

**Branch**: feat/486
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/486
**Base**: main

## Acceptance Criteria

- [ ] Guard added: full-profile allow resources validated against root `skills/` ∪ `opencode_app/.opencode/skills/` (extend `tests/skill_profiles.bats`) — genuinely dead rules fail CI
- [ ] Decision recorded: keep the app-scoped skill + allow as a documented second surface (default, per #361's intent) vs relocate to root `skills/`
- [ ] Count prose made surface-explicit where cited (README "106 allows", `LEARNINGS/decisions/skill-permission-allowlist.md`, setup.sh/ps1 "106-allow" comments) — savings derivation adjusted or annotated
- [ ] LEARNINGS entry: two-skill-surfaces count conflation (extends the `delta-derived-from-single-surface` family)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `tests/skill_profiles.bats` — new `dead_allows()` helper + positive/negative tests | — | CI bats gate; guards `opencode_app/opencode.json` skill allows against BOTH surfaces + surface disjointness | low — mirrors existing `lean_keys()` / scratch-config patterns |
| `README.md` profile section (:408 region) | — | docs readers, downstream deployers | low — prose only |
| `deploy/setup.sh` (:599, :3357) + `deploy/setup.ps1` (:71, :945) comments | — | maintainers (comment-only edits; no logic change) | low |
| `LEARNINGS/decisions/app-scoped-skill-surface.md` (new) | — | future sessions; cited from `skill-permission-allowlist.md:6` | low |
| `LEARNINGS/decisions/skill-permission-allowlist.md:6` (current-state Pattern) | 3.1 (the file it cites) | future sessions re-deriving counts | low |
| `LEARNINGS/anti-patterns/two-surface-count-conflation.md` (new) | — | future sessions | low |

**Triage note (Step 7):** zero plan reviewers selected — no production code changes (test + prose + LEARNINGS only); the map has no cross-module production edges (the guard test's only consumer is CI). Step 9 code review backstops.

## Implementation Phases

### Phase 1: Evidence (recorded pre-plan)

- [x] **1.1** Verify surfaces and deploy-copy behavior: full allows (106) ⊆ root(146 SKILL.md dirs) ∪ app(1: `github-runners-setup-skill`); dead = none; root∩app = ∅; `deploy/setup.sh:1519` copies root `skills/` only (app skill never reaches user deploys); raw root readdir = 147 because `skills/_archived` exists — guards MUST filter by `SKILL.md` presence
    — **Why:** every later step's correctness (guard semantics, prose claims) hangs on these derived facts living in the ticket trail, not session memory
    — **Done when:** the facts above are recorded under Technical Notes → Surface Evidence
    — **Consumers affected:** guard design (2.1), prose wording (3.2)
    — **Done:** verified in worktree @ 35dd2543: allows=106 ⊆ root(146 SKILL.md dirs)∪app(1); dead=none; root∩app=none; raw root readdir=147 incl. skills/_archived (filter by SKILL.md); deploy/setup.sh:1519 copies root surface only — all recorded under Technical Notes → Surface Evidence; files: none; fixes: none
- [x] **1.2** Enumerate every 106-citing surface: `README.md:408`, `deploy/setup.sh:599` + `:3357`, `deploy/setup.ps1:71` + `:945`, `LEARNINGS/decisions/skill-permission-allowlist.md:6` (current-state) — with `:3` of the same file EXEMPT as a dated #481 narrative ("full +3 → 106 allows" was true then; dated narratives stay, current-state claims go surface-explicit)
    — **Why:** the sweep scope must be complete before editing; the dated-vs-current distinction prevents the partial-record-refresh anti-pattern in reverse (falsifying history)
    — **Done when:** the list is recorded under Technical Notes and 3.3's re-sweep uses it as the expected-hit set
    — **Consumers affected:** scope of 3.2
    — **Done:** expected-hit set recorded under Technical Notes → 106-cite sites; dated-narrative exemption (decisions :3) noted; files: PLANS/PLAN-486.md (Technical Notes append); fixes: none

### Phase 2: Union guard (AC1)

- [ ] **2.1** Add a `dead_allows()` helper (node one-liner, `lean_keys()` style: takes a config path, prints skill-allow resources that match no `SKILL.md` dir on either surface) + positive test `"skill-profiles: every shipped skill allow resolves on a skill surface (root ∪ app)"` asserting BOTH dead = ∅ AND root∩app = ∅ (name collision would shadow ambiguously in the Docker app); update the file header coverage comment
    — **Why:** AC1 — this is the guard that would have caught a genuinely dead rule shipping silently; the disjointness half prevents the inverse failure (same-named skill on both surfaces)
    — **Done when:** test green against the real files; header comment lists the new coverage
    — **Consumers affected:** CI bats gate
- [ ] **2.2** Add negative fixture `"skill-profiles: dead-allow guard fails on a phantom rule"` — scratch config (mktemp copy + injected `not-a-real-skill` allow, mirroring the typo-guard pattern at the bottom of the file) → `dead_allows()` must report exactly the phantom
    — **Why:** an error branch with no negative fixture false-greens on regressions (LEARNINGS guard-error-branches-need-negative-fixtures)
    — **Done when:** the negative test green (phantom reported exactly)
    — **Consumers affected:** CI bats gate
- [ ] **2.3** Run `bats tests/skill_profiles.bats` — all tests green (now 8)
    — **Why:** phase gate before prose work rides the same PR
    — **Done when:** suite passes 8/8
    — **Consumers affected:** PR CI

### Phase 3: Decision + surface-explicit prose (AC2 + AC3)

- [ ] **3.1** Write `LEARNINGS/decisions/app-scoped-skill-surface.md` + `_index.md` entry: two surfaces (root `skills/` = deployable, 146; `opencode_app/.opencode/skills/` = Docker-app project surface, 1: `github-runners-setup-skill` from #361); decision — KEEP the app-scoped skill + its allow (default per #361's gated-setup intent), accept the dead-in-user-deploys rule as the cost of the app sharing the deploy config base; revisit trigger — if the app grows more project skills, split the app config base or add an app-specific profile
    — **Why:** AC2 — the recorded decision the ticket demands, with its trade-off and exit condition
    — **Done when:** file + index entry exist and reference #486 + #361
    — **Consumers affected:** future sessions; `skill-permission-allowlist.md:6` cites it
- [ ] **3.2** Make every current-state count cite surface-explicit: `README.md:408` — "(106 allows)" → "(106 rules: 105 deployable + 1 app-scoped — `github-runners-setup-skill`, live only in the Docker app)" AND savings "36 hidden descriptions" → "36 hidden descriptions (1 app-scoped, never loaded in user deploys)"; `deploy/setup.sh:599` + `:3357` and `deploy/setup.ps1:71` + `:945` — "106-allow allowlist" → "106-allow allowlist (incl. 1 app-scoped skill)"; `LEARNINGS/decisions/skill-permission-allowlist.md:6` — "**106 allows**" → "**106 allows** (105 deployable + 1 app-scoped — see `app-scoped-skill-surface.md`)"
    — **Why:** AC3 — counts that mix surfaces ship false arithmetic ("106−70=36 hidden" overcounts by one for user deploys) and re-teach the conflation this ticket fixes
    — **Done when:** every 1.2-listed current-state site carries the qualifier; dated narrative at `:3` untouched
    — **Consumers affected:** docs readers, downstream deployers
- [ ] **3.3** Re-sweep: `grep -rnE '106[- ](allow|rules|allows)' README.md deploy/ LEARNINGS/ opencode_app/README.md` — every hit either carries the surface qualifier or is the exempt dated narrative
    — **Why:** the plan's own anti-drift gate (docs-of-record included per the count-sweeps learning)
    — **Done when:** sweep output matches the expected-hit set from 1.2, all qualified
    — **Consumers affected:** none (verification)

### Phase 4: LEARNINGS + gates (AC4)

- [ ] **4.1** Write `LEARNINGS/anti-patterns/two-surface-count-conflation.md` + `_index.md` entry: when a repo ships two surfaces of the same artifact kind, every count/guard/derivation must name its surface; single-surface derivations mint phantoms (this saga: the #481-review "phantom" call AND the #481-plan duplicate-delta miss were both single-surface errors); fix = union guard + disjointness assert + surface-explicit prose; convention: dated narratives keep their period-true counts, current-state claims go surface-explicit
    — **Why:** AC4 — the reusable half of this ticket; extends `delta-derived-from-single-surface`
    — **Done when:** file + index entry exist and reference #486
    — **Consumers affected:** future sessions
- [ ] **4.2** Gate: full `bats tests/` + `node installer/build-registry.mjs --check` (registry scans root only by design — the app skill is intentionally absent from it; note in memo, not a change); record GATE memo; conventional commits + push
    — **Why:** repo verification policy; count/prose/test changes fan out across suites
    — **Done when:** full suite green; memo line recorded; work committed and pushed on `feat/486`
    — **Consumers affected:** PR CI

## Technical Notes

**Surface Evidence (pre-plan, worktree @ 35dd2543):** allows = 106 (plus deny-all); root `skills/` readdir = 147, of which 146 have `SKILL.md` (`_archived` is the legacy exception — filters must test `SKILL.md` presence, not bare readdir); app surface = `opencode_app/.opencode/skills/` = exactly `github-runners-setup-skill` (#361); allows − (root∪app) = ∅; root∩app = ∅; `deploy/setup.sh:1519` `cp -r "${src_dir}/skills"` copies the root surface only → the app-scoped allow is dead weight in user deploys, live in the Docker app (which serves `opencode_app/` as project root and discovers `.opencode/skills/` there).

**Origin:** flagged as "phantom allow" in #481 code review; corrected on investigation — not a dead rule, a second surface. Both misses in this saga (the phantom call, the #481-plan 26-vs-3 duplicate delta) were single-surface derivations.

**106-cite sites (1.2 expected-hit set):** `README.md:408` (allows parenthetical + savings derivation), `deploy/setup.sh:599` + `:3357`, `deploy/setup.ps1:71` + `:945`, `LEARNINGS/decisions/skill-permission-allowlist.md:6` (current-state Pattern). EXEMPT: `decisions/skill-permission-allowlist.md:3` — dated #481 narrative ("full +3 → 106 allows"), period-true, stays.

**Registry scope (no change):** `installer/build-registry.mjs` scans root `skills/` only; the app skill is intentionally absent from `registry.json` (npx add serves the deployable surface). The union guard reads directories directly, independent of the registry.

## Dependencies

- None (`blocked-by:` absent). Related: #361 (skill origin), #481/#485 (count prose being annotated), #484 (same session's rename work).

## Risks & Mitigation

- **Guard false-greens via `_archived`.** Mitigation: helper filters by `SKILL.md` presence (1.1 evidence baked into the implementation).
- **Negative fixture drift (phantom name already exists someday).** Mitigation: `not-a-real-skill` mirrors the existing typo-guard fixture name; overlap assert also guards the inverse.
- **Prose qualifiers rot as counts drift.** Mitigation: sites carry the qualifier inline next to the number, and the count-sweeps learning's re-derive rule covers them.

`GATE 2ffcf6b+p1 lint=n.a. typecheck=n.a. build=n.a. unit=n.a. e2e=n.a` — evidence-only phase, no source changes.
