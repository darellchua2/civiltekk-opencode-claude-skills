# PLAN: Remove dead Autodesk MCP pack (official-only policy)

**Branch**: feat/553
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/553
**Base**: main

## Acceptance Criteria
- [ ] `deploy/packs/pack-autodesk.json` deleted; zero live `autodesk` pack references in `deploy/`, `README.md`, `opencode_app/`
- [ ] `./deploy/setup.sh --enable-pack autodesk` fails fast as an unknown pack with the updated available-list message
- [ ] `--enable-pack` help/banner text, README, and `opencode_app/README.md` list the remaining packs only
- [ ] Touched bats files green; `bash -n deploy/setup.sh` passes
- [ ] README documents the official-only policy and the re-admission bar for Autodesk MCP

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/packs/pack-autodesk.json` | — | `merge-packs.mjs` (dir scan — auto-adapts, no code change), `tests/test_pack_permissions.bats`, `tests/test_select_items.bats` (catalog scan) | low |
| `deploy/setup.sh` pack strings (L364, 620-621, 659-660, 673, 755-757, 941, 2731) | pack removal (list must match disk) | CLI users (help text), `tests/test_select_items.bats` count pins | med |
| `README.md` packs table + examples (L223, 230-231) | pack removal | docs readers | low |
| `opencode_app/README.md` (L70, 74, 77, 83) + `opencode_app/Dockerfile` comment example | pack removal | Docker deployers | low |
| `tests/test_mcp_count_consistency.bats` (`mcp_count_autodesk_not_shipped`) | pack removal | CI | low |

Cross-module note: pack file has consumers beyond itself (setup.sh docs strings, 2 test scanners) → architecture review selected. `deploy/setup.ps1` verified zero autodesk references at `origin/main` — no mirror changes (ticket over-scoped; delta recorded on ticket). `tests/test_subcommands.bats` no longer pins the Autodesk string upstream — out of scope. `README.md:301` `autodesk-aps-skill` is a knowledge skill, not an MCP — untouched by design.

## Implementation Phases

### Phase 1: Remove pack + sync deploy script and docs
- [ ] **1.1** Delete `deploy/packs/pack-autodesk.json`
    — **Why:** its 4 servers point at the non-responding `mcp.autodesk.com` domain — the core removal the ticket mandates; every doc/test step depends on the pack being gone.
    — **Done when:** file absent from `deploy/packs/` and `git status` shows the deletion staged-able.
    — **Consumers affected:** merge-packs.mjs (auto-adapts via `scanPackNames` — no code change), test scanners updated in Phase 2.
- [ ] **1.2** Remove all `autodesk` strings from `deploy/setup.sh` (7 sites: L364 comment, L620-621 + L941 pack CSVs, L659-660 + L673 examples, L755-757 Autodesk banner block, L2731 summary echo), keeping the remaining pack list `markitdown, nextjs, docling, chrome-devtools` accurate everywhere
    — **Why:** help text and validation messages must match the packs dir or `--enable-pack` UX lies; L941's CSV feeds the fail-fast error message covered by AC #2.
    — **Done when:** `grep -in autodesk deploy/setup.sh` returns zero matches.
    — **Consumers affected:** CLI users; `tests/test_select_items.bats` count pins (Phase 2).
- [ ] **1.3** Update `README.md`: drop the `autodesk` packs-table row (L223) and rewrite the two examples (L230-231) without it; add an official-only policy note with the re-admission bar (official Autodesk product MCP servers only, once verifiable from Autodesk's own docs; archived `aps-mcp-server-nodejs` sample does not qualify)
    — **Why:** AC #5 — the policy must be documented where pack users look.
    — **Done when:** `grep -in autodesk README.md` matches only the policy paragraph and the unrelated `autodesk-aps-skill` category listing (L301, untouched by design).
    — **Consumers affected:** docs readers.
- [ ] **1.4** Update `opencode_app/README.md` (L70 prose, L74 + L92 examples, L77 pack list, L83 table row) and the `opencode_app/Dockerfile` build-arg comment example to the remaining pack set
    — **Why:** Docker deployers follow these verbatim commands; a dead pack name breaks copy-paste onboarding.
    — **Done when:** `grep -in autodesk opencode_app/` returns zero matches.
    — **Consumers affected:** Docker deploy path.

### Phase 2: Update test pins
- [ ] **2.1** Remove the `autodesk:autodesk-revit,...` entry from `PACK_SERVERS` in `tests/test_pack_permissions.bats`
    — **Why:** the iteration source for pack-permission tests must match the packs dir or the suite fails on a missing file.
    — **Done when:** grep confirms no `autodesk` in the file and the remaining PACK_SERVERS entries match `deploy/packs/` contents.
    — **Consumers affected:** CI.
- [ ] **2.2** Delete the `mcp_count_autodesk_not_shipped` test from `tests/test_mcp_count_consistency.bats`
    — **Why:** it asserts the 4 servers live only in the pack — with the pack gone the assertion subject no longer exists; keeping it would test nothing.
    — **Done when:** test absent, file parses, remaining tests untouched.
    — **Consumers affected:** CI.
- [ ] **2.3** Update `tests/test_select_items.bats` catalog pins (autodesk inclusion + count assertions) to pin an existing pack instead
    — **Why:** the catalog is dir-scanned, so pins must reference real packs; keeps the truthful-catalog guarantee from #537 intact.
    — **Done when:** the two assertions reference a surviving pack (e.g. markitdown) and the count reflects 4 packs.
    — **Consumers affected:** CI.

### Phase 3: Verification gate
- [ ] **3.1** Run gates: `bash -n deploy/setup.sh`, then `bats tests/test_pack_permissions.bats tests/test_mcp_count_consistency.bats tests/test_select_items.bats tests/test_setup_ps1_vars.bats`
    — **Why:** AC #4 — the touched suites are the mechanical enforcement of every textual claim above; this is the ticket exit gate.
    — **Done when:** bash -n silent + all four bats files green (or pre-existing failures documented as such).
    — **Consumers affected:** CI, PR merge decision.

## Technical Notes
- From ticket: MIGRATION.md / CHANGELOG.md history untouched. `setup.ps1` needs no changes (verified at origin/main). re-admission bar: verify official endpoints in a browser session (autodesk.com AI page 403s automated fetches) before any future PR.
- The fail-fast path (`validate_enable_pack`) is data-driven from `deploy/packs/` — AC #2 needs no code change, only the message CSV accuracy from 1.2.

## Dependencies
None (no blocked-by tickets).

## Risks & Mitigation
- *Hidden pack-count pins surface late* → mitigation: worktree-wide `grep -rin "autodesk" deploy/ tests/ README.md opencode_app/` after Phase 2 before the gate.
- *Bats suite has pre-existing failures* → mitigation: run each file on `origin/main` baseline first if a failure appears; document pre-existing breakage rather than fixing off-ticket.
