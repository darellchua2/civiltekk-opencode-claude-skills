# PLAN: Restore subagent-only skill loading via interim profile allows (#481)

**Branch**: feat/481
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/481
**Base**: main
**Revision**: 2 — architecture review + Mode R rulings applied (per-surface deltas 3/26, single-commit restructure, "107-allow" literal sites, reviewer-only scope record)

## Acceptance Criteria

- [ ] Decision recorded: interim global allows for the reviewer-consumed subagent-only skills (adopted — reviewer-only scope: exactly the union of the 4 reviewer agents' frontmatter skill allows; the remaining 28 non-reviewer agents' frontmatter skill allows are explicitly deferred to the upstream anomalyco/opencode#50149 fix; scope, token cost, revert trigger documented) vs accepting the embedded-baseline fallback
- [ ] If adopted: allows added to `opencode_app/opencode.json` (delta **3**: 104→107 rules / 103→106 allows) + `deploy/skill-profiles.json` lean (delta **26**: 44→70), counts synced per the Adding Skills sync rules (`deploy/setup.sh`, `deploy/setup.ps1`, READMEs), registry gate green — all in ONE commit with the test mirrors (per-push CI otherwise red by construction)
- [ ] Regression probe documented (3-step diagnostic) and re-run condition stated (per opencode upgrade); workaround revert condition stated (upstream anomalyco/opencode#50149 fix)
- [ ] LEARNINGS entry marking the "subagents are profile-immune" claim as unverified for the `skill` action until the upstream fix

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` skill rules (full profile source) | — | `deploy/apply-skill-profile.mjs` (rewrites deployed copy's skill rules; copies from setup.sh:119/2564), Docker app, primary catalog + child skill gate | med — additive allows only; deny-all stays first; NO duplicates (23 of the union already ship here) |
| `deploy/skill-profiles.json` lean array | 2.1 (fail-closed typo guard apply-skill-profile.mjs:74-81 exits 1 if a lean key lacks a shipped allow) | `deploy/setup.sh --skill-profile lean` (default deploy), `tests/skill_profiles.bats` (pins count at multiple literal sites) | med — count literals across tests/scripts/docs must move in the SAME commit |
| `tests/skill_profiles.bats` literals | 2.2 | CI bats gate | low |
| `deploy/setup.sh` / `setup.ps1` prose comments | 2.2 | maintainers reading deploy output | low |
| `README.md` + `opencode_app/README.md` counts/profile prose | 2.1, 2.2 | docs readers, downstream deployers | med — includes the profile-immunity caveat + residual-broken-set record + revised savings arithmetic |
| `LEARNINGS/decisions/skill-permission-allowlist.md` | — | future sessions citing the profile-immunity claim | low |

## Implementation Phases

### Phase 1: Evidence & decision record

- [x] **1.1** Verify BOTH deltas programmatically: union of the 4 reviewer agents' frontmatter `action: skill` allows minus lean (=26: code-review 17, uiux 6, language 18, architecture 11, union 33) AND minus full (=3: `reviewer-baseline-skill`, `uiux-review-skill`, `language-review-checklists-skill`); assert both counts and record the lists in Technical Notes
    — **Why:** the two arrays hold different memberships — a single union−X derivation silently duplicates entries in the other array while Set-based guards pass green (review finding B1)
    — **Done when:** computation prints union−lean=26 and union−full=3 with the exact lists, recorded in Technical Notes
    — **Consumers affected:** scope of every Phase 2 step
    — **Done:** node computation: union=33 | union-lean=26 | union-full=3 (language-review-checklists-skill, reviewer-baseline-skill, uiux-review-skill); existing full dupes: none — recorded in Delta arithmetic; files: none; fixes: none
- [x] **1.2** Record the mechanism-probe evidence (DONE pre-plan, session ses_f41646fd7ffe3ZtRmEBAeEBb7n): project-layer allow appended after global deny-all → child subagent's `skill` tool call returned `loaded`; harness simultaneously surfaced the skill to the primary catalog (confirming the primary-visibility cost)
    — **Why:** the workaround is only valid because config-level allows provably restore child loading; the evidence must live in the ticket trail, not session memory
    — **Done when:** evidence block present in Technical Notes
    — **Consumers affected:** decision rationale, LEARNINGS entry
    — **Done:** mechanism-probe evidence block already in Technical Notes (pre-plan); files: none; fixes: none

### Phase 2: Config + mirror sync (ONE atomic commit)

- [x] **2.1** Add exactly the union−full skills (3) as `{"action":"skill","resource":"<id>","effect":"allow"}` rules to `opencode_app/opencode.json`, merged into the existing alphabetical allow block after the deny-all (104→107 rules, 103→106 allows)
    — **Why:** full profile is the deploy source; the fail-closed guard requires every lean key to ship here; adding already-present entries would duplicate rules silently
    — **Done when:** node count of skill rules = 107 with zero duplicate resources; JSON parses (no comments — JSONC anti-pattern); deny-all remains the first skill rule
    — **Consumers affected:** apply-skill-profile.mjs, Docker app, deploys
    — **Done:** 3 rules inserted after gsap-frameworks block; full allows=106, dupes=none, deny-all first, JSON parses; files: opencode_app/opencode.json (+15); fixes: none
- [x] **2.2** Append the union−lean skills (26) to `deploy/skill-profiles.json` `lean` (44→70), alphabetical
    — **Why:** default deploy is lean — the workaround only reaches user machines through this list
    — **Done when:** `lean.length` = 70, every entry matches a skill directory on disk, lean ⊆ full allows
    — **Consumers affected:** setup.sh lean deploys, skill_profiles.bats
    — **Done:** lean rebuilt 44→70 sorted, every entry matches a skill dir (suite green), lean⊆full=true; files: deploy/skill-profiles.json (+28/−1); fixes: none
- [x] **2.3** Update `tests/skill_profiles.bats` literals: `-eq 44` → `-eq 70`, expected string `"44 deny-ok non-skill-ok"` → `"70 deny-ok non-skill-ok"`, header comments, test names — same commit as 2.1/2.2
    — **Why:** per-push CI runs the suite; a Phase-2 push with new counts against old pins is red by construction (review finding B2)
    — **Done when:** grep shows only 70-based literals; suite green
    — **Consumers affected:** CI bats gate
    — **Done:** bats literals 44→70 at all six sites (header ×2, test names ×2, -eq, expected-string); suite green; files: tests/skill_profiles.bats; fixes: none
- [x] **2.4** Update deploy prose literals: `deploy/setup.sh:3356` "lean (default) -> 44 primary-visible skills" → 70; `deploy/setup.sh:3359` + `deploy/setup.ps1:71,945` "107-allow allowlist" → "106-allow allowlist" (already stale vs disk 103; re-derive, never hand-copy) — same commit
    — **Why:** hyphenated "107-allow" evades the plain sweep pattern; these sites were stale before this change (review finding M1)
    — **Done when:** grep `[0-9]+[- ](allow|primary-visible)` over deploy/ shows only derived numbers
    — **Consumers affected:** maintainers
    — **Done:** setup.sh:3356 44→70 + 107-allow→106-allow; setup.ps1:70 46→70 (pre-existing drift) + :71,:945 107→106; files: deploy/setup.sh, deploy/setup.ps1; fixes: none
- [x] **2.5** Update `README.md` + `opencode_app/README.md` in the same commit: (a) `README.md:408` region — "103 allows" → "106 allows", "only 44 primary-visible skills" → "only 70 primary-visible skills", "~5.4k tokens saved per session" → "~3.2k tokens saved per session (~36 fewer descriptions × ~90 tokens/description)" derived as (full allows 106 − lean 70) × basis; (b) profile-section note: 26 reviewer-baseline skills temporarily primary-visible as the #481 workaround for upstream anomalyco/opencode#50149; the 28 non-reviewer agents' frontmatter skill allows remain non-functional under lean until the upstream fix (this note is the deferral record); revert = remove from `deploy/skill-profiles.json` lean + redeploy; (c) `README.md:420` "Subagents are profile-immune" gains the unverified-for-skill-action caveat + workaround pointer
    — **Why:** stale savings/token claims ship false at merge; the residual broken set needs a durable deferral record; the profile-immunity claim needs the same caveat users get in LEARNINGS (review M1 + m1, Mode R rulings 1+2)
    — **Done when:** all three README edits present; numbers re-derive from disk
    — **Consumers affected:** docs readers, downstream deployers
    — **Done:** README.md: counts 103→106 / 44→70 ×2, savings restated ~3.2k with derivation, interim-workaround note + deferral record added, :420 profile-immunity caveat added; opencode_app/README.md has no profile section (verified — no counts there); files: README.md; fixes: none
- [x] **2.6** Registry gate: `node installer/build-registry.mjs --check` exits 0 (registry serializes no skill permissions — no drift expected; drift = investigate before committing)
    — **Why:** verifies the config edit touched nothing the registry derives
    — **Done when:** `--check` exits 0
    — **Consumers affected:** registry consumers
    — **Done:** node installer/build-registry.mjs --check exits 0 ("registry OK (agents=34, skills=146, no drift)"); files: none; fixes: none

### Phase 3: Verification sweep

- [ ] **3.1** LEARNINGS verification sweep with the corrected pattern: `grep -rnE '[0-9]+[- ](allow|primary-visible)' tests/ deploy/ README.md opencode_app/README.md` + `grep -rnE '\-eq [0-9]+|"[0-9]+ deny-ok' tests/` + `grep -rn "skill director" README.md opencode_app/README.md tests/` — every hit either matches the new derived numbers or is unrelated
    — **Why:** the plan's own anti-drift gate, with the regex shape fixed to catch hyphenated forms (review M1)
    — **Done when:** sweep shows no stale count anywhere
    — **Consumers affected:** none (verification)

### Phase 4: LEARNINGS + gates

- [ ] **4.1** Update `LEARNINGS/decisions/skill-permission-allowlist.md`: mark the "subagents are profile-immune" claim UNVERIFIED for the `skill` action on opencode v2.0.11 (agent frontmatter `skill` allows ignored in child sessions while `shell`/tool-action rules DO apply — #482's probe matrix; upstream #50149); record the adopted workaround (reviewer-only scope + rationale: all-agent union = 127 skills → lean 145/146 = abolishes the profile; 3/26 deltas; ~3.2k→savings restatement basis; revert trigger); refresh the file's own stale counts (107/48/150) inline by re-derivation
    — **Why:** AC4 + m2; future sessions must not cite profile-immunity as fact for skills
    — **Done when:** unverified-marker + workaround record + refreshed counts present
    — **Consumers affected:** future sessions
- [ ] **4.2** Add `LEARNINGS/patterns/child-skill-gate-follows-merged-config.md` (+ `_index.md` entry): the child skill gate resolves against the merged config set (defaults → global → project → agent, last-match-wins), NOT the agent's frontmatter allows — config-layer allows restore loading while frontmatter allows do not; include the 3-step regression probe (spawn reviewer → invoke `skill` id → expect `loaded`) + re-run condition (per opencode upgrade)
    — **Why:** AC3's probe documentation + the reusable mechanism knowledge
    — **Done when:** file + index entry exist, reference #481 + #50149
    — **Consumers affected:** future sessions, upgrade re-checks
- [ ] **4.3** Gate: full bats suite (count-pinning suites at minimum: skill_profiles, count_drift, markitdown, mcp_count_consistency, agents_target) + registry `--check`; record GATE memo; conventional commits + push (Phase 2 steps share their atomic commit; Phase 4 rides its own)
    — **Why:** repo verification policy; count changes fan out across suites
    — **Done when:** all suites green; memo line recorded; work committed and pushed on `feat/481`
    — **Consumers affected:** PR CI

## Technical Notes

**Mechanism probe (pre-plan, session ses_f41646fd7ffe3ZtRmEBAeEBb7n):** temp project `.opencode/opencode.json` with a single `{"action":"skill","resource":"reviewer-baseline-skill","effect":"allow"}` → spawned `code-review-subagent` → `skill` tool returned **loaded** (first successful load; every prior attempt this investigation returned `permission.rejected`). The harness simultaneously surfaced the skill into the primary catalog — the primary-visibility token cost is real and immediate. Probe file removed; main checkout clean.

**Decision (recorded per AC1):** ADOPT — restores the documented profile-immunity contract for reviewers; ~3.2k→ revised lean savings (~36 hidden × ~90 tok), ≤1.6% of the 200k floor; one-line revert (`deploy/skill-profiles.json` lean) + redeploy; deferral would leave all four reviewer types degraded indefinitely. Question tool unavailable (3× server-side failures) — decision made on ticket framing + Mode R rulings; flagged to user for override in the pipeline report.

**Scope boundary (Mode R ruling 1):** the interim allow set covers reviewers only (union 33: code-review 17, uiux 6, language 18, architecture 11). The 28 other agents carrying frontmatter skill allows stay broken under lean until upstream fixes #50149 — honoring the all-agent union (127 skills) would push lean 44→145 of 146 and abolish the profile; those skills remain reachable via full profile or per-need lean edits. Residual broken set is documented in both READMEs (step 2.5) as the deferral record.

**Delta arithmetic (review-verified at 7bcb492):** full = 104 skill rules (deny-all + 103 allows); lean = 44, lean ⊆ full; reviewer union = 33; union−lean = 26; union−full = 3 (`reviewer-baseline-skill`, `uiux-review-skill`, `language-review-checklists-skill` — 23 of the 26 already ship in full). Post-change: full 107 rules / 106 allows; lean 70.

**Deploy derivation:** setup.sh:119/2564 copies `opencode_app/opencode.json` as the deploy base; `deploy/apply-skill-profile.mjs` patches the DEPLOYED copy only (JSON.parse → filter → deny-first + sorted rebuild), fail-closed at :74-81 when a lean key lacks a shipped allow — hence 2.1 must land with (or before) 2.2, and both with their test mirrors.

**Redeploy (post-merge, orchestrator-owned — NOT a PLAN step):** run `./deploy/setup.sh` in the main checkout; verify `~/.config/opencode/opencode.json` carries the new allows; re-run the 3-step probe against the deployed config; note in ticket close-out.

## Dependencies

- None (`blocked-by:` absent). Related: #482 (merged — proved tool-action rules DO apply in child sessions, isolating this bug to the `skill` action), upstream anomalyco/opencode#50149.

## Risks & Mitigation

- **Count-literal drift across tests/scripts/docs.** Mitigation: Phase 3's corrected-pattern sweep as a gate; targets derived from disk + delta, never hand-copied.
- **Primary-context token cost regresses lean's purpose.** Mitigation: README restates revised savings with derivation; documented revert trigger (upstream fix) + per-upgrade probe.
- **Duplicate full-profile rules via wrong-delta copy.** Mitigation: 1.1 asserts both deltas; 2.1's done-when includes a duplicate-resource check.
- **Upstream fix lands and behavior changes shape.** Mitigation: probe is config-agnostic (expects `loaded`); revert procedure documented at the profile file.

`GATE 9e20799+p2 lint=n.a. typecheck=n.a. build=t(registry --check no drift) unit=t(27/27: skill_profiles, count_drift, markitdown, mcp_count) e2e=n.a`
