# PLAN: mcp-install-assistant-skill: guided MCP pack installer

**Branch**: feat/556
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/556
**Base**: main

## Acceptance Criteria
- [ ] `skills/mcp-install-assistant-skill/` fully self-contained; `tests/test_skill_isolation.bats` green
- [ ] Frontmatter contract: `name` = dir name, description ≤50 words with trigger phrases ("install mcp", "enable mcp", "which mcp"), `license: Apache-2.0`, `compatibility: opencode`, `metadata: harness "opencode"`
- [ ] Inventory covers all shipped MCP servers with correct state/type/env-key/pack mapping (proven against a fixture config)
- [ ] Precheck flags a missing env key and advises BEFORE any enable attempt
- [ ] Enable path for both scopes: global `--enable-pack` (configurator repo cwd) and per-project v2 full entry (stub-inert rule); verify via `opencode mcp list`
- [ ] `registry.json` regenerated; README table + count surfaces synced; skill visible in lean profile AND enabled in full profile
- [ ] Gates: `node --check` on scripts, relevant bats suites green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/mcp-install-assistant-skill/SKILL.md` | — | runtime skill loader, `build-registry.mjs` scan, `tests/test_skill_isolation.bats` | low |
| `skills/mcp-install-assistant-skill/scripts/inventory.mjs` | SKILL.md references it | primary session at runtime (users) | low |
| `installer/registry.json` (regenerated) | SKILL.md exists | `installer/init.mjs` (`npx add` picker), registry-drift checks | med |
| `deploy/skill-profiles.json` lean array | skill dir exists (guard) | `deploy/apply-skill-profile.mjs`, `tests/skill_profiles.bats` (pins lean count at :44/:105 — structure-pinning consumers, must co-bump) | low |
| `opencode_app/opencode.json` permissions array | skill dir exists | full-profile deploys, `merge-packs` change detection | low |
| `README.md` Configuration category + L217 MCP paragraph | skill exists | docs readers; count conventions (no hard test on category counts) | low |
| `opencode_app/README.md` skill count prose | registry total 148→149 | docs readers (#546 precedent: stale count shipped once) | low |

Cross-module note: skill dir has consumers beyond itself (registry scan, profile guards, README) → architecture review completed (2026-09-25): 2 BLOCKs applied — inherited red `skill_profiles.bats` pins (70 vs array 71 at base c6d3a7e) fixed forward to 72 in 2.1; docs sweep re-keyed from `148` (matches nothing — stale totals read `147`) to the convention pattern. Relay round 1 ruled: fix forward, own the 147→149 drift on all surfaces. Landing strategy: ONE atomic commit — tests/init.bats:22-27 requires registry.json in the same commit as SKILL.md (BT-157), and the lean ⊆ allows guard couples 2.1/2.2; per-phase commits would be red mid-branch. No frontend signal → uiux not selected.

## Implementation Phases

### Phase 1: Author the skill
- [ ] **1.1** Write `skills/mcp-install-assistant-skill/SKILL.md`: frontmatter per contract; body = 4-step assistant flow (inventory → precheck → enable → verify), the portability capability-binding block (OpenCode `question` tool / Claude Code AskUserQuestion / plain-reply fallback), global-vs-per-project decision rule, cross-reference to `opencode-repo-setup-skill` (plumbing) and the AGENTS.md stub-inert warning
    — **Why:** the SKILL.md is the deliverable's contract; every later step (registry, profiles, tests) scans or guards it.
    — **Done when:** frontmatter passes the house contract checks (name match, ≤50-word description with triggers, license, compatibility, metadata) and the body covers all 4 steps + bindings.
    — **Consumers affected:** registry scan (2.1), profile guards (2.2), tests.
- [ ] **1.2** Write `skills/mcp-install-assistant-skill/scripts/inventory.mjs` (Node, zero deps): reads global config (`~/.config/opencode/opencode.json`, honoring `$XDG_CONFIG_HOME`) always, overlaid by `$OPENCODE_CONFIG` when set (it layers between global and project per v2 docs), plus optional project `opencode.json` arg; prints per-server table: name, enabled, type, command/url, env keys referenced (`{env:X}` extraction), owning pack; exit 0; `--json` flag
    — **Why:** the inventory step must work on any machine from the deployed config alone (packs are configurator-repo concepts; the deployed config is the universal truth).
    — **Done when:** `node --check` passes and a run against a 3-server fixture config prints correct states + extracted env keys.
    — **Consumers affected:** SKILL.md inventory step; gate smoke test.
- [ ] **1.3** Add a minimal fixture + self-check in the skill dir: a documented one-liner (the `scripts/__main__` convention does not exist in this repo — zero hits) running inventory against an inline 3-server fixture config, including one server whose `{env:MISSING_KEY}` is unset to mechanically prove the missing-env-key precheck path (AC #4)
    — **Why:** the isolation contract requires the skill to carry its own fixtures; ponytail rule: non-trivial script ships one runnable check.
    — **Done when:** the documented check command runs green from inside the skill dir with no external paths and the output flags the missing key as a precheck warning.
    — **Consumers affected:** future maintainers; isolation test (no `_common` refs).

### Phase 2: Enablement sync (lands in the same atomic commit as Phase 1 — coupled guards)
- [ ] **2.1** Add `mcp-install-assistant-skill` to `deploy/skill-profiles.json` `lean` array (71→72) AND fix-forward the inherited-red pins in `tests/skill_profiles.bats`: :44 `[ "$count" -eq 72 ]`, :88 test name `70 allows` → `72 allows`, :105 `"72 deny-ok non-skill-ok"`, header comments :5/:7 → 72 (base c6d3a7e grew lean to 71 without bumping — suite red on main; relay round 1: fix forward here, no hotfix ticket)
    — **Why:** user wants the assistant primary-visible by default; the pin literals assert final state so one bump to 72 heals the inherited red and this ticket's own +1 in a single edit.
    — **Done when:** `tests/skill_profiles.bats` passes with lean = 72 and all four literals consistent.
    — **Consumers affected:** lean-profile deploys; CI on main (heals inherited red).
- [ ] **2.2** Add `{"action":"skill","resource":"mcp-install-assistant-skill","effect":"allow"}` to the `permissions` array in `opencode_app/opencode.json` (full-profile source of truth) — lands with 2.1: the `lean ⊆ shipped allows` guard (skill_profiles.bats:49-58) fails any intermediate commit holding the lean entry without this allow
    — **Why:** profiles `_comment`: full = the permissions array; without the rule the skill ships deny-all hidden in full deploys; guard couples the two edits.
    — **Done when:** config parses; rule present exactly once; skill_profiles guard green.
    — **Consumers affected:** full-profile deploys; `test_pack_permissions` change-detection untouched (different action namespace).
- [ ] **2.3** Run `node installer/build-registry.mjs`; the regenerated `installer/registry.json` (expect 148→149 skills) lands in the SAME atomic commit as the SKILL.md (BT-157: tests/init.bats:22-27 enforces registry-vs-disk same-commit)
    — **Why:** registry.json is the single generated index consumed by the `npx add` picker; a missing entry makes the skill invisible to individual installs.
    — **Done when:** registry contains `mcp-install-assistant-skill` with description + metadata; second run produces zero diff (idempotent).
    — **Consumers affected:** installer/init.mjs picker.

### Phase 3: Docs sync
- [ ] **3.1** `README.md`: add the skill to the **Configuration** category row (2→3: markitdown-mcp-skill, docling-mcp-skill, mcp-install-assistant-skill); extend the L217 MCP-enablement paragraph to mention the assistant as the guided front-door (per-project + global)
    — **Why:** the categories table is the skill discovery surface; L217 is where MCP enablement guidance lives.
    — **Done when:** row reads (3) with the skill listed; L217 names it.
    — **Consumers affected:** docs readers.
- [ ] **3.2** Convention-pattern sweep and correct EVERY hit (relay round 1: #556 owns the inherited drift — all stale totals read `147` today against true 148, NOT `148` as first drafted): `git grep -nE '14[0-9] (ready-to-load )?skill|skills? directori|Skill catalog|primary-visible|Current count' README.md opencode_app/ deploy/ docs/ -- ':!PLANS' ':!LEARNINGS'` — set disk totals → **149** at README.md:5, :67, :101, :240 ("all N skills stay on disk"), :277, :279 ("Current count"), opencode_app/README.md:26; set README.md:240 "70 primary-visible skills" → **72**
    — **Why:** #546 shipped a stale count because the sweep missed surfaces; number-keyed sweeps green-light leaving every stale total untouched (plan-review BLOCK 2) — sweep by pattern class.
    — **Done when:** every pattern hit reconciled to 149/72 or explicitly keep-listed (keep-list: dated research doc `docs/opencode-agent-tooling-research-2026-09-24.md`, CHANGELOG/MIGRATION history).
    — **Consumers affected:** docs readers.

### Phase 4: Verification gate (ticket exit)
- [ ] **4.1** Run gates: `node --check skills/mcp-install-assistant-skill/scripts/inventory.mjs`; inventory fixture self-check incl. missing-key case (1.3's command); `bats tests/test_skill_isolation.bats tests/skill_profiles.bats tests/test_count_drift.bats tests/init.bats`; registry regen idempotency (second run, zero diff); `git grep -c mcp-install-assistant` across the 5 sync surfaces ≥ 5
    — **Why:** ACs #1/#3/#6/#7 — isolation, inventory correctness, sync completeness, and the mechanical gates; this is the ticket exit gate (full tier).
    — **Done when:** node --check silent, fixture check green incl. missing-key warning, 4 bats files green (skill_profiles green proves the inherited-red heal), regen idempotent, sync-count ≥ 5.
    — **Consumers affected:** CI, PR merge decision.

## Technical Notes
- Runtime inventory source is the DEPLOYED global config (portability) — not `deploy/packs/` (configurator-only). Pack attribution comes from a static map in the script (server→pack from the pack files' `mcp.servers` keys at authoring time; 7 packs, 1:1 except nextjs→next-devtools). ponytail: static map with a ceiling note — if packs multiply, derive from the repo at author time, not runtime.
- The enable step delegates to existing mechanics (`setup.sh --enable-pack`, manual v2 entry); the skill NEVER hand-edits the global config directly (deploy script owns it; v2 stub-inert rule for project scope).
- Skill count surfaces: setup.sh/ps1 use dynamic `count_skills` (no literal to change) — verified #474 de-bloat; only prose totals in docs need the sweep.

## Dependencies
None (no blocked-by tickets). Builds on #552's pack catalog and #554's cleaned surface (both merged).

## Risks & Mitigation
- *Registry drift or profile-guard failure surfaces late* → mitigation: run build-registry + skill_profiles bats immediately after 2.1/2.2, not only at the gate.
- *Inventory script scope creep* (pack merging, enable logic in script) → mitigation: script = read-only inventory only; enablement stays in SKILL.md instructions delegating to setup.sh / manual entry (separation per ticket's alternatives ruling).
- *Frontmatter contract nit* (description >50 words, name mismatch) → mitigation: mirror `opencode-repo-setup-skill` frontmatter shape verbatim (verified sample), run build-registry which parses strictly.
