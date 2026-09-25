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
| `deploy/skill-profiles.json` lean array | skill dir exists (guard) | `deploy/apply-skill-profile.mjs`, `tests/skill_profiles.bats` | low |
| `opencode_app/opencode.json` permissions array | skill dir exists | full-profile deploys, `merge-packs` change detection | low |
| `README.md` Configuration category + L217 MCP paragraph | skill exists | docs readers; count conventions (no hard test on category counts) | low |
| `opencode_app/README.md` skill count prose | registry total 148→149 | docs readers (#546 precedent: stale count shipped once) | low |

Cross-module note: skill dir has consumers beyond itself (registry scan, profile guards, README) → architecture review selected; no frontend signal → uiux not selected.

## Implementation Phases

### Phase 1: Author the skill
- [ ] **1.1** Write `skills/mcp-install-assistant-skill/SKILL.md`: frontmatter per contract; body = 4-step assistant flow (inventory → precheck → enable → verify), the portability capability-binding block (OpenCode `question` tool / Claude Code AskUserQuestion / plain-reply fallback), global-vs-per-project decision rule, cross-reference to `opencode-repo-setup-skill` (plumbing) and the AGENTS.md stub-inert warning
    — **Why:** the SKILL.md is the deliverable's contract; every later step (registry, profiles, tests) scans or guards it.
    — **Done when:** frontmatter passes the house contract checks (name match, ≤50-word description with triggers, license, compatibility, metadata) and the body covers all 4 steps + bindings.
    — **Consumers affected:** registry scan (2.1), profile guards (2.2), tests.
- [ ] **1.2** Write `skills/mcp-install-assistant-skill/scripts/inventory.mjs` (Node, zero deps): reads global config (`$OPENCODE_CONFIG` or `~/.config/opencode/opencode.json`) + optional project `opencode.json` arg; prints per-server table: name, enabled, type, command/url, env keys referenced (`{env:X}` extraction), owning pack; exit 0; `--json` flag
    — **Why:** the inventory step must work on any machine from the deployed config alone (packs are configurator-repo concepts; the deployed config is the universal truth).
    — **Done when:** `node --check` passes and a run against a 3-server fixture config prints correct states + extracted env keys.
    — **Consumers affected:** SKILL.md inventory step; gate smoke test.
- [ ] **1.3** Add a minimal fixture + self-check in the skill dir: `scripts/__main__` style self-demo or documented one-liner running inventory against an inline fixture config
    — **Why:** the isolation contract requires the skill to carry its own fixtures; ponytail rule: non-trivial script ships one runnable check.
    — **Done when:** the documented check command runs green from inside the skill dir with no external paths.
    — **Consumers affected:** future maintainers; isolation test (no `_common` refs).

### Phase 2: Registry + enablement sync
- [ ] **2.1** Run `node installer/build-registry.mjs`; commit the regenerated `installer/registry.json` (expect 148→149 skills)
    — **Why:** registry.json is the single generated index consumed by the `npx add` picker; a missing entry makes the skill invisible to individual installs.
    — **Done when:** registry contains `mcp-install-assistant-skill` with description + metadata; second run produces zero diff (idempotent).
    — **Consumers affected:** installer/init.mjs picker.
- [ ] **2.2** Add `mcp-install-assistant-skill` to `deploy/skill-profiles.json` `lean` array (71→72)
    — **Why:** user wants the assistant primary-visible by default; lean guards require every key to match a disk skill dir.
    — **Done when:** `tests/skill_profiles.bats` passes with the new entry.
    — **Consumers affected:** lean-profile deploys.
- [ ] **2.3** Add `{"action":"skill","resource":"mcp-install-assistant-skill","effect":"allow"}` to the `permissions` array in `opencode_app/opencode.json` (full-profile source of truth)
    — **Why:** profiles `_comment`: full = the permissions array; without the rule the skill ships deny-all hidden in full deploys.
    — **Done when:** config parses; rule present exactly once.
    — **Consumers affected:** full-profile deploys; `test_pack_permissions` change-detection untouched (different action namespace).

### Phase 3: Docs sync
- [ ] **3.1** `README.md`: add the skill to the **Configuration** category row (2→3: markitdown-mcp-skill, docling-mcp-skill, mcp-install-assistant-skill); extend the L217 MCP-enablement paragraph to mention the assistant as the guided front-door (per-project + global)
    — **Why:** the categories table is the skill discovery surface; L217 is where MCP enablement guidance lives.
    — **Done when:** row reads (3) with the skill listed; L217 names it.
    — **Consumers affected:** docs readers.
- [ ] **3.2** Catalog-name sweep across sibling docs (convention: sweep by name, not counts): `git grep -nE "mcp-install-assistant|148|ships [0-9]+ skill" README.md opencode_app/ deploy/ docs/ -- ':!PLANS' ':!LEARNINGS'` — update any stale skill-total prose (expect `opencode_app/README.md` count → 149)
    — **Why:** #546 shipped a stale skill count in opencode_app/README.md because the sweep missed it; the registry total changes 148→149 here.
    — **Done when:** every hit reconciled or explicitly keep-listed (MIGRATION/CHANGELOG history untouched).
    — **Consumers affected:** docs readers.

### Phase 4: Verification gate (ticket exit)
- [ ] **4.1** Run gates: `node --check skills/mcp-install-assistant-skill/scripts/inventory.mjs`; inventory fixture self-check (1.3's command); `bats tests/test_skill_isolation.bats tests/skill_profiles.bats tests/test_count_drift.bats`; registry regen idempotency (second run, zero diff); `git grep -c mcp-install-assistant` across the 5 sync surfaces ≥ 5
    — **Why:** ACs #1/#3/#6/#7 — isolation, inventory correctness, sync completeness, and the mechanical gates; this is the ticket exit gate (full tier).
    — **Done when:** node --check silent, fixture check green, 3 bats files green, regen idempotent, sync-count ≥ 5.
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
