# PLAN: Restore subagent-only skill loading via interim profile allows (#481)

**Branch**: feat/481
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/481
**Base**: main
**Revision**: 1

## Acceptance Criteria

- [ ] Decision recorded: interim global allows for the reviewer-consumed subagent-only skills (adopted — scope, token cost, revert trigger documented) vs accepting the embedded-baseline fallback
- [ ] If adopted: allows added to `opencode_app/opencode.json` + `deploy/skill-profiles.json`, counts synced per the Adding Skills sync rules (`deploy/setup.sh`, `deploy/setup.ps1`, READMEs), registry gate green
- [ ] Regression probe documented (3-step diagnostic) and re-run condition stated (per opencode upgrade); workaround revert condition stated (upstream anomalyco/opencode#50149 fix)
- [ ] LEARNINGS entry marking the "subagents are profile-immune" claim as unverified for the `skill` action until the upstream fix

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` skill rules (full profile source) | — | `deploy/apply-skill-profile.mjs` (rewrites deployed copy's skill rules), Docker app, primary catalog + child skill gate | med — additive allows only; deny-all stays first |
| `deploy/skill-profiles.json` lean array | — | `deploy/setup.sh --skill-profile lean` (default deploy), `tests/skill_profiles.bats` (pins count at multiple literal sites) | med — count literals across tests/scripts/docs must move together |
| `tests/skill_profiles.bats` literals | 2.2 | CI bats gate | low |
| `deploy/setup.sh` / `setup.ps1` prose comments | 2.2 | maintainers reading deploy output | low |
| `README.md` + `opencode_app/README.md` counts/profile prose | 2.1, 2.2 | docs readers, downstream deployers | low |
| `LEARNINGS/decisions/skill-permission-allowlist.md` | — | future sessions citing the profile-immunity claim | low |

## Implementation Phases

### Phase 1: Evidence & decision record

- [ ] **1.1** Verify the exact delta programmatically: union of the 4 reviewer agents' frontmatter `action: skill` allows (from `agents/{code-review,uiux-reviewer,language-reviewer,architecture-review}-subagent.md`) minus current lean entries → assert the count and record the list in Technical Notes
    — **Why:** the ticket's "~15" estimate was wrong (grep says 26); the shipped delta must be derived, not hand-copied
    — **Done when:** node/awk computation prints the list + count, recorded in Technical Notes
    — **Consumers affected:** every Phase 2 step's scope
- [ ] **1.2** Record the mechanism-probe evidence (DONE pre-plan, session ses_f41646fd7ffe3ZtRmEBAeEBb7n): project-layer allow appended after global deny-all → child subagent's `skill` tool call returned `loaded`; harness also surfaced the skill to the primary catalog (confirming the primary-visibility cost)
    — **Why:** the workaround is only valid because config-level allows provably restore child loading; the evidence must live in the ticket trail, not session memory
    — **Done when:** evidence block present in Technical Notes
    — **Consumers affected:** decision rationale, LEARNINGS entry

### Phase 2: Config changes

- [ ] **2.1** Add the delta skills as `{"action":"skill","resource":"<id>","effect":"allow"}` rules to `opencode_app/opencode.json`, merged into the existing alphabetical allow block after the deny-all (full profile 104 → 104+N)
    — **Why:** full profile is the single source of truth the deploy rewrites from; missing entries here would be dropped from every deploy
    — **Done when:** node count of skill rules equals 104+N; JSON parses; deny-all remains the first skill rule
    — **Consumers affected:** apply-skill-profile.mjs, Docker app, deploys
- [ ] **2.2** Append the same N entries to `deploy/skill-profiles.json` `lean` (44 → 44+N), keeping alphabetical order
    — **Why:** default deploy is lean — the workaround only reaches user machines through this list
    — **Done when:** `lean.length` equals 44+N and every new entry matches a skill directory on disk (the file's own guard)
    — **Consumers affected:** setup.sh lean deploys, skill_profiles.bats
- [ ] **2.3** Registry gate: `node installer/build-registry.mjs --check` exits 0 (registry serializes no skill permissions — no drift expected; non-empty drift = investigate)
    — **Why:** verifies the config edit touched nothing the registry derives
    — **Done when:** `--check` exits 0
    — **Consumers affected:** registry consumers

### Phase 3: Count sync (literal minefield)

- [ ] **3.1** Update every count literal in `tests/skill_profiles.bats` (assertion `-eq 44` → new count, expected-string `"44 deny-ok non-skill-ok"`, header comments, test names)
    — **Why:** the suite pins the lean count at multiple literal sites; a partial bump fails CI or lies green (LEARNINGS new-skill-count-literal-gates)
    — **Done when:** `grep -nE '\-eq [0-9]+|"[0-9]+ deny-ok' tests/skill_profiles.bats` shows only the new count; suite green
    — **Consumers affected:** CI bats gate
- [ ] **3.2** Update prose count literals in `deploy/setup.sh` (e.g. :3356 "lean (default) -> 44 primary-visible skills") and `deploy/setup.ps1` mirror sites
    — **Why:** the comments drift otherwise and mislead maintainers (same LEARNINGS)
    — **Done when:** grep for the old count in deploy/ returns only unrelated hits
    — **Consumers affected:** maintainers
- [ ] **3.3** Update `README.md` + `opencode_app/README.md` skill-count prose AND add one profile-section note: N reviewer-baseline skills temporarily primary-visible as the #481 workaround for upstream anomalyco/opencode#50149; revert = remove from `deploy/skill-profiles.json` lean + redeploy
    — **Why:** doc counts must match reality; the workaround's existence and exit must be documented where deployers read
    — **Done when:** count greps match the new numbers; both READMEs carry the note with the revert line
    — **Consumers affected:** docs readers, downstream deployers
- [ ] **3.4** Run the LEARNINGS verification sweep: `grep -rnE '\-eq [0-9]+|"[0-9]+ deny-ok' tests/` + `grep -rn "skill director" README.md opencode_app/README.md tests/` + `grep -rnE '[0-9]+ (primary-visible|allow)' deploy/setup.sh deploy/setup.ps1` — derive targets from current disk + delta, never from stale doc numbers
    — **Why:** the documented anti-drift gate for exactly this change class
    — **Done when:** sweep shows no stale count anywhere
    — **Consumers affected:** none (verification)

### Phase 4: LEARNINGS + gates

- [ ] **4.1** Update `LEARNINGS/decisions/skill-permission-allowlist.md`: mark the "subagents are profile-immune" claim UNVERIFIED for the `skill` action on opencode v2.0.11 (upstream anomalyco/opencode#50149 — agent frontmatter `skill` allows are ignored in child sessions while `shell`/tool-action rules DO apply, proven by #482's probe matrix); record the adopted workaround (N skills, both profiles, ~66 tok/skill measured basis) + revert trigger
    — **Why:** AC4; future sessions must not cite profile-immunity as fact for skills
    — **Done when:** the decision file carries the unverified-marker + workaround record
    — **Consumers affected:** future sessions
- [ ] **4.2** Add `LEARNINGS/patterns/child-skill-gate-follows-merged-config.md`: the child skill gate resolves against the merged config set (defaults → global → project → agent, last-match-wins), NOT the agent's frontmatter allows — so config-layer allows (project or global) restore loading while frontmatter allows do not; include the 3-step regression probe (spawn reviewer → invoke `skill` id → expect `loaded`) and the re-run condition (per opencode upgrade)
    — **Why:** AC3's probe documentation + the reusable mechanism knowledge
    — **Done when:** file + `_index.md` entry exist, reference #481 + #50149
    — **Consumers affected:** future sessions, upgrade re-checks
- [ ] **4.3** Gate: full bats suite (count-pinning suites at minimum: skill_profiles, count_drift, markitdown, mcp_count_consistency, agents_target) + registry `--check` + `node --check` on any touched scripts; record GATE memo; conventional commits + push
    — **Why:** repo verification policy; count changes fan out across suites
    — **Done when:** all suites green; memo line recorded; work committed and pushed on `feat/481`
    — **Consumers affected:** PR CI

## Technical Notes

**Mechanism probe (pre-plan, session ses_f41646fd7ffe3ZtRmEBAeEBb7n):** temp project `.opencode/opencode.json` with a single `{"action":"skill","resource":"reviewer-baseline-skill","effect":"allow"}` → spawned `code-review-subagent` → `skill` tool returned **loaded** (first successful load; every prior attempt this investigation returned `permission.rejected`). The harness simultaneously surfaced the skill into the primary catalog (system-update) — the primary-visibility token cost is real and immediate. Probe file removed; main checkout clean.

**Decision (recorded per AC1):** ADOPT — restores the documented profile-immunity contract; ~66 tok/skill × N on a 200k–1M context baseline (<1%); one-line revert (`deploy/skill-profiles.json` lean) + redeploy; deferral would leave all four reviewer types degraded indefinitely. Question tool unavailable (3× server-side failures) — decision made on ticket framing; flagged to user for override in the pipeline report.

**Pre-change counts (worktree @ d89c8f4b):** full skill rules = 104; lean = 44; bats pins `-eq 44` / `"44 deny-ok non-skill-ok"`; `deploy/setup.sh:3356` "lean (default) -> 44 primary-visible skills".

**Deploy derivation:** deployed config's skill rules are rewritten by `deploy/apply-skill-profile.mjs` from the shipped `opencode_app/opencode.json` full set intersected with the selected profile — the 26 must land in BOTH files (full source + lean selection). Verify setup.sh's source path during 2.1 (grep for apply-skill-profile invocation).

**Redeploy (post-merge, orchestrator-owned — NOT a PLAN step):** run `./deploy/setup.sh` in the main checkout; verify `~/.config/opencode/opencode.json` carries the new allows; re-run the 3-step probe against the deployed config; note in ticket close-out.

## Dependencies

- None (`blocked-by:` absent). Related: #482 (merged — proved tool-action rules DO apply in child sessions, isolating this bug to the `skill` action), upstream anomalyco/opencode#50149.

## Risks & Mitigation

- **Count-literal drift across tests/scripts/docs.** Mitigation: Phase 3 runs the LEARNINGS verification greps as a gate; targets derived from disk + delta.
- **Primary-context token cost regresses lean's purpose.** Mitigation: documented revert trigger (upstream fix) + per-upgrade probe; the note lands in both READMEs' profile sections.
- **Upstream fix lands and behavior changes shape.** Mitigation: probe is config-agnostic (expects `loaded`); revert procedure documented at the profile file.
