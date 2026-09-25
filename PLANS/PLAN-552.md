# PLAN: Self-install MCP packs: playwright, alphavantage, nanobanana

**Branch**: feat/552
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/552
**Base**: main

## Acceptance Criteria
- [ ] `--enable-pack playwright` / `alpha-vantage` / `nanobanana` each merges its pack into the deployed config: server flips enabled + permissions allow rule present
- [ ] All three servers ship `disabled: true` by default — plain deploys enable nothing
- [ ] Each local server entry sets `timeout: 30000`
- [ ] `--enable-pack` validation, help text, and banners list all 7 packs (4 existing + 3 new)
- [ ] `bash -n deploy/setup.sh` passes; test_pack_permissions, test_mcp_count_consistency, test_select_items, test_subcommands, test_setup_ps1_vars green
- [ ] README packs table documents the 3 new packs incl. required env vars (`ALPHA_VANTAGE_API_KEY`, `GEMINI_API_KEY`); README MCP-entry count updated (8 → 11)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` mcp.servers (+3) | — | opencode runtime, `tests/test_mcp_count_consistency.bats` (total-count vs README), README count line | med |
| `deploy/packs/pack-{playwright,alpha-vantage,nanobanana}.json` | config entries exist (pack flips a real key) | `deploy/merge-packs.mjs` (dir scan), `validate_enable_pack` (ls), `scanPackNames` (picker/tests) | low |
| `deploy/setup.sh` pack strings (L364, 620-621, 937, 2727, banner ~748-756, print_summary ~4660s, 4760) | packs on disk (list must match) | CLI users, `tests/test_select_items.bats` | med |
| `README.md` packs table + count line | config total | `mcp_count_opencode_json_is_consistent_across_docs` (hard pin) | med |
| `opencode_app/README.md` packs table | pack files | Docker deployers | low |
| `tests/test_pack_permissions.bats`, `tests/test_select_items.bats` | everything above | CI | low |

Consumer-map note: pack files have cross-module consumers (setup.sh validation, merge-packs, picker scan) → architecture review selected; no frontend signal → uiux not selected. All three upstreams self-install (npx -y / remote URL) — no setup.sh install hooks needed (audit: #553-adjacent, 10/12 surfaces already self-install).

## Implementation Phases

### Phase 1: Config entries + pack partials
- [ ] **1.1** Add 3 `mcp.servers` entries to `opencode_app/opencode.json`: `playwright` (local, `npx -y @playwright/mcp@latest`, timeout 30000), `alpha-vantage` (remote `https://mcp.alphavantage.co/mcp`, `oauth: false`, header `Authorization: Bearer {env:ALPHA_VANTAGE_API_KEY}`), `nanobanana` (local, `npx -y nanobanana-mcp-server@latest`, environment `GEMINI_API_KEY: {env:GEMINI_API_KEY}`, timeout 30000) — all `disabled: true`
    — **Why:** the servers must exist in the base config before any pack can flip them; disabled-by-default keeps plain deploys unchanged (AC #2).
    — **Done when:** `python3 -c` count of mcp.servers = 11 and each new entry has `disabled: true` (+ timeout on locals).
    — **Consumers affected:** opencode runtime (zero change — disabled), mcp-count test, README count.
- [ ] **1.2** Create `deploy/packs/pack-playwright.json` on the pack-chrome-devtools shape: `$comment` + `mcp.servers.playwright.disabled: false` + `permissions [{action: "playwright*", resource: "*", effect: "allow"}]`
    — **Why:** the pack is the only enablement path (#268 model); merge-packs deep-merges exactly this shape.
    — **Done when:** `node merge-packs.mjs --config <tmp> --packs playwright` exits 0 and the temp config shows playwright enabled with the allow rule.
    — **Consumers affected:** validate_enable_pack available-list, picker catalog, tests (Phase 3).
- [ ] **1.3** Create `deploy/packs/pack-alpha-vantage.json` (same shape, `alpha-vantage*` allow rule)
    — **Why:** same enablement path; remote server so the pack only flips + allows.
    — **Done when:** merge-packs merge of the pack exits 0 with alpha-vantage enabled.
    — **Consumers affected:** same as 1.2.
- [ ] **1.4** Create `deploy/packs/pack-nanobanana.json` (same shape, `nanobanana*` allow rule)
    — **Why:** same enablement path.
    — **Done when:** merge-packs merge of the pack exits 0 with nanobanana enabled.
    — **Consumers affected:** same as 1.2.

### Phase 2: Deploy script + docs sync
- [ ] **2.1** Extend every pack-name string in `deploy/setup.sh` with the 3 new names: L364 comment, L620-621 help CSV, L937 error CSV, L2727 summary echo, banner "Available but disabled" block (~L748-756, add 3 server lines incl. env-var notes), `print_summary` opt-in block (~L4660s), L4760 next-steps line
    — **Why:** help/validation text must match the packs dir or `--enable-pack` UX lies; the error CSV feeds the fail-fast message (AC #4).
    — **Done when:** `grep -c playwright deploy/setup.sh` ≥ 7 sites touched; every CSV reads `markitdown, nextjs, docling, chrome-devtools, playwright, alpha-vantage, nanobanana` in some stable order used consistently.
    — **Consumers affected:** CLI users; test_select_items (Phase 3).
- [ ] **2.2** `README.md`: add 3 packs-table rows (env vars in Requires column); update L201 "ships 8 MCP server entries" → 11
    — **Why:** the count line is hard-pinned by `mcp_count_opencode_json_is_consistent_across_docs`; the table is the user-facing env-var contract (AC #6).
    — **Done when:** README count grep matches 11 and the table has 7 rows.
    — **Consumers affected:** docs readers, mcp-count test.
- [ ] **2.3** `opencode_app/README.md`: add 3 rows to the Docker packs table (`(1)` server each; alpha-vantage/nanobanana note their env var)
    — **Why:** Docker deployers enable packs via build-arg and need the same key documentation.
    — **Done when:** table shows 7 packs, `grep playwright opencode_app/README.md` matches.
    — **Consumers affected:** Docker deploy path.

### Phase 3: Test pins
- [ ] **3.1** `tests/test_pack_permissions.bats`: extend `PACK_SERVERS` with `playwright:playwright alpha-vantage:alpha-vantage nanobanana:nanobanana`
    — **Why:** the pack-permission iteration source must cover the new packs or their permissions rules go unverified.
    — **Done when:** PACK_SERVERS lists 7 entries matching `deploy/packs/` contents.
    — **Consumers affected:** CI.
- [ ] **3.2** `tests/test_select_items.bats`: catalog count pin `4/5` → `7/5` (membership pin on docling stays)
    — **Why:** the truthful-catalog guarantee pins real counts; 7 pack files + 5 plugins is the new disk truth.
    — **Done when:** assertion reads `7/5` and the test passes in the Phase 4 gate.
    — **Consumers affected:** CI.

### Phase 4: Verification gate (ticket exit)
- [ ] **4.1** Run gates: `bash -n deploy/setup.sh`; `bats tests/test_pack_permissions.bats tests/test_mcp_count_consistency.bats tests/test_select_items.bats tests/test_subcommands.bats tests/test_setup_ps1_vars.bats`; merge-packs behavioral proof per new pack (temp config, exit 0, enabled + allow rule); fail-fast available-list shows 7 packs
    — **Why:** ACs #1/#4/#5 — the touched suites plus the merge behavior are the mechanical enforcement; this is the ticket exit gate (full tier).
    — **Done when:** bash -n silent, 5 suites green, 3 merge proofs exit 0, available-list = 7 packs.
    — **Consumers affected:** CI, PR merge decision.

## Technical Notes
- From ticket: nothing enabled by default; sec-edgar excluded (PyPI → pip hook pattern, not self-installing; track separately if wanted); Remotion/browser-use stay README-pilot material, not shipped.
- alpha-vantage header shape: `Authorization: Bearer {env:ALPHA_VANTAGE_API_KEY}` mirrors the house remote-keyed pattern (zai servers, #554's removed autodesk entries). Alpha Vantage documents OAuth as primary; verify header behavior at first pilot and adjust if their gateway rejects Bearer keys.
- nanobanana npm package name assumed `nanobanana-mcp-server` (per research doc [21]); verify `npm view` during 1.1 and correct the exact name if the registry differs — do not guess variants.
- timeout: 30000 rationale: OpenCode default 5000 ms tool-fetch can lose the race against a cold npx download on first enable.

## Dependencies
None (no blocked-by tickets). Builds on #553's cleaned pack surface (merged a5b864a).

## Risks & Mitigation
- *Upstream package name/flag drift* (`@playwright/mcp`, `nanobanana-mcp-server`) → mitigation: `npm view <name> version` during Phase 1; if a name misses, correct the entry before the gate rather than shipping a dead command.
- *mcp-count hidden pins* beyond README (other docs stating a server total) → mitigation: `grep -rn "MCP server" README.md opencode_app/ | grep -E "[0-9]+"` sweep before the gate.
- *Remote MCP OAuth handshake* on alpha-vantage may ignore static headers → mitigation: documented as pilot-verify note in README row; pack still ships disabled so a wrong header costs nothing until opted in.
