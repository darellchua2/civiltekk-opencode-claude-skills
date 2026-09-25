# PLAN: Self-install MCP packs: playwright, alphavantage, nanobanana

**Branch**: feat/552
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/552
**Base**: main

## Acceptance Criteria
- [x] `--enable-pack playwright` / `alpha-vantage` / `nanobanana` each merges its pack into the deployed config: server flips enabled + permissions allow rule present
- [x] All three servers ship `disabled: true` by default — plain deploys enable nothing
- [x] Each local server entry sets `timeout: {"catalog": 30000}` (v2 object form; no `execution` key)
- [x] `--enable-pack` validation, help text, and banners list all 7 packs (4 existing + 3 new)
- [x] `bash -n deploy/setup.sh` passes; test_pack_permissions, test_mcp_count_consistency, test_select_items, test_subcommands, test_setup_ps1_vars green
- [x] README packs table documents the 3 new packs incl. required env vars (`ALPHA_VANTAGE_API_KEY`, `GEMINI_API_KEY`); README MCP-entry count updated (8 → 11)

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
- [x] **1.1** Add 3 `mcp.servers` entries to `opencode_app/opencode.json`: `playwright` (local, `npx -y @playwright/mcp@latest`, timeout 30000), `alpha-vantage` (remote `https://mcp.alphavantage.co/mcp`, headers `Authorization: Bearer {env:ALPHA_VANTAGE_API_KEY}`, no `oauth` key — matches the shipped zai remote shape), `nanobanana` (local, `npx -y nanobanana-mcp-server@latest`, environment `GEMINI_API_KEY: {env:GEMINI_API_KEY}`) — all `disabled: true`; the two locals carry `"timeout": {"catalog": 30000}` (v2 object; scalar is v1 — plan-review Major 1, relay round 1 ruling; no `execution` key so tool calls keep the 12h default)
    — **Why:** the servers must exist in the base config before any pack can flip them; disabled-by-default keeps plain deploys unchanged (AC #2).
    — **Done when:** `python3 -c` count of mcp.servers = 11; each new entry `disabled: true`; `timeout.catalog == 30000` on both locals; confirmatory probe: temp-enable playwright in a scratch config copy, `opencode mcp list` connects with no config diagnostic, then revert.
    — **Consumers affected:** opencode runtime (zero change — disabled), mcp-count test, README count.
    — **Done:** 3 servers added (11 total), disabled:true, object timeout {catalog:30000} on locals, zai-shape Bearer header on alpha-vantage, no oauth key; files: opencode_app/opencode.json; fixes: 1 (insertion-point bug aborted on JSON validation before write — redone with anchored close)
- [x] **1.2** Create `deploy/packs/pack-playwright.json` on the pack-chrome-devtools shape: `$comment` + `mcp.servers.playwright.disabled: false` + `permissions [{action: "playwright*", resource: "*", effect: "allow"}]`
    — **Why:** the pack is the only enablement path (#268 model); merge-packs deep-merges exactly this shape.
    — **Done when:** `node merge-packs.mjs --config <tmp> --packs playwright` exits 0 and the temp config shows playwright enabled with the allow rule.
    — **Consumers affected:** validate_enable_pack available-list, picker catalog, tests (Phase 3).
    — **Done:** pack-playwright.json created; merge proof exit 0, enabled + allow rule; files: deploy/packs/pack-playwright.json; fixes: none
- [x] **1.3** Create `deploy/packs/pack-alpha-vantage.json` (same shape, `alpha-vantage*` allow rule)
    — **Why:** same enablement path; remote server so the pack only flips + allows.
    — **Done when:** merge-packs merge of the pack exits 0 with alpha-vantage enabled.
    — **Consumers affected:** same as 1.2.
    — **Done:** pack-alpha-vantage.json created; merge proof exit 0, enabled + allow rule; files: deploy/packs/pack-alpha-vantage.json; fixes: none
- [x] **1.4** Create `deploy/packs/pack-nanobanana.json` (same shape, `nanobanana*` allow rule)
    — **Why:** same enablement path.
    — **Done when:** merge-packs merge of the pack exits 0 with nanobanana enabled.
    — **Consumers affected:** same as 1.2.
    — **Done:** pack-nanobanana.json created; merge proof exit 0, enabled + allow rule; files: deploy/packs/pack-nanobanana.json; fixes: none

### Phase 2: Deploy script + docs sync
- [x] **2.1** Extend every pack-name string in `deploy/setup.sh` with the 3 new names: L364 comment, L620-621 help CSV, L937 error CSV, L2726-2727 summary echo lines (both carry the catalog — plan-review Minor), banner "Available but disabled" block (~L748-756, add 3 server lines incl. env-var notes), `print_summary` opt-in block (~L4660s), L4760 next-steps line
    — **Why:** help/validation text must match the packs dir or `--enable-pack` UX lies; the error CSV feeds the fail-fast message (AC #4).
    — **Done when:** `grep -c playwright deploy/setup.sh` ≥ 7 sites touched; every CSV reads `markitdown, nextjs, docling, chrome-devtools, playwright, alpha-vantage, nanobanana` in some stable order used consistently.
    — **Consumers affected:** CLI users; test_select_items (Phase 3).
    — **Done:** all 8 setup.sh sites extended (CSV x3, banner block +3 lines, L2726-2727 echoes, print_summary +3 lines, next-steps); files: deploy/setup.sh; fixes: none
- [x] **2.2** `README.md`: add 3 packs-table rows (env vars in Requires column); update L201 "ships 8 MCP server entries" → 11; update the L209 prose catalog ("The remaining 5 ship disabled..." + enumeration) to 8 with the 3 new names
    — **Why:** the count line is hard-pinned by `mcp_count_opencode_json_is_consistent_across_docs`; the table is the user-facing env-var contract (AC #6).
    — **Done when:** README count grep matches 11 and the table has 7 rows.
    — **Consumers affected:** docs readers, mcp-count test.
    — **Done:** count 8→11, remaining-5 prose catalog → 8, packs table +3 rows with env vars; files: README.md; fixes: none
- [x] **2.3** `opencode_app/README.md`: add 3 rows to the Docker packs table (`(1)` server each; alpha-vantage/nanobanana note their env var); update the L70 opt-in server enumeration and the L77 `# Available packs:` compose comment
    — **Why:** Docker deployers enable packs via build-arg and need the same key documentation; L70/L77 are catalog restatements the review caught outside the digit sweep (plan-review Major 2).
    — **Done when:** table shows 7 packs; L70 and L77 name all 7/8 surfaces they enumerate; `grep -c playwright opencode_app/README.md` ≥ 3.
    — **Consumers affected:** Docker deploy path.
    — **Done:** app README prose + Available-packs comment + Docker table +3 rows; files: opencode_app/README.md; fixes: none
- [x] **2.4** `skills/opencode-repo-setup-skill/SKILL.md` L59-63: extend the interactive MCP-opt-in list with the 3 new servers
    — **Why:** the repo-setup skill is the per-project enablement UX; leaving it at 5 servers makes the new packs invisible to the users most likely to want them (plan-review Major 2).
    — **Done when:** the option list enumerates all 8 opt-in servers; `grep -c playwright skills/opencode-repo-setup-skill/SKILL.md` ≥ 1.
    — **Consumers affected:** repo-setup skill users (LLM + human).
    — **Done:** repo-setup SKILL.md MCP-enables list extended to 7 packs with env-var notes; files: skills/opencode-repo-setup-skill/SKILL.md; fixes: none
    — **Consumers affected:** Docker deploy path.

### Phase 3: Test pins
- [x] **3.1** `tests/test_pack_permissions.bats`: extend `PACK_SERVERS` with `playwright:playwright alpha-vantage:alpha-vantage nanobanana:nanobanana`
    — **Why:** the pack-permission iteration source must cover the new packs or their permissions rules go unverified.
    — **Done when:** PACK_SERVERS lists 7 entries matching `deploy/packs/` contents.
    — **Consumers affected:** CI.
    — **Done:** PACK_SERVERS extended to 7 entries; files: tests/test_pack_permissions.bats; fixes: none
- [x] **3.2** `tests/test_select_items.bats`: catalog count pin `4/5` → `7/5` (membership pin on docling stays)
    — **Why:** the truthful-catalog guarantee pins real counts; 7 pack files + 5 plugins is the new disk truth.
    — **Done when:** assertion reads `7/5` and the test passes in the Phase 4 gate.
    — **Consumers affected:** CI.
    — **Done:** catalog pin 4/5 → 7/5; files: tests/test_select_items.bats; fixes: none

### Phase 4: Verification gate (ticket exit)
- [x] **4.1** Run gates: `bash -n deploy/setup.sh`; `bats tests/test_pack_permissions.bats tests/test_mcp_count_consistency.bats tests/test_select_items.bats tests/test_subcommands.bats tests/test_setup_ps1_vars.bats`; merge-packs behavioral proof per new pack (temp config, exit 0, enabled + allow rule); fail-fast available-list shows 7 packs
    — **Why:** ACs #1/#4/#5 — the touched suites plus the merge behavior are the mechanical enforcement; this is the ticket exit gate (full tier).
    — **Done when:** bash -n silent, 5 suites green, 3 merge proofs exit 0, available-list = 7 packs.
    — **Consumers affected:** CI, PR merge decision.
    — **Done:** bash -n silent; 5 suites 51 ok / 0 failed (exit 0); per-pack merge proofs exit 0 with enabled+allow rule; fail-fast available-list = 7 packs; catalog-name sweep clean; files: gate run; fixes: none

## Technical Notes
- From ticket: nothing enabled by default; sec-edgar excluded (PyPI → pip hook pattern, not self-installing; track separately if wanted); Remotion/browser-use stay README-pilot material, not shipped.
- alpha-vantage header shape: `Authorization: Bearer {env:ALPHA_VANTAGE_API_KEY}` mirrors the house remote-keyed pattern (zai servers, #554's removed autodesk entries). Alpha Vantage documents OAuth as primary; verify header behavior at first pilot and adjust if their gateway rejects Bearer keys.
- nanobanana npm package name assumed `nanobanana-mcp-server` (per research doc [21]); verify `npm view` during 1.1 and correct the exact name if the registry differs — do not guess variants.
- timeout: 30000 rationale: OpenCode default 5000 ms tool-fetch can lose the race against a cold npx download on first enable.

## Dependencies
None (no blocked-by tickets). Builds on #554's cleaned pack surface (merged as a5b864a; PLAN previously misattributed this to #553 — corrected per plan review). Landing strategy: the implementation lands as ONE atomic commit (config + packs + docs + test pins together) — per-phase commits would leave count pins red mid-branch (plan-review Minor).

## Risks & Mitigation
- *Upstream package name/flag drift* (`@playwright/mcp`, `nanobanana-mcp-server`) → mitigation: `npm view <name> version` during Phase 1; if a name misses, correct the entry before the gate rather than shipping a dead command.
- *catalog restatements beyond digit-countable pins* → mitigation: sweep by catalog NAME, not counts — `git grep -nE "markitdown.*docling|Available packs|opt-in" README.md opencode_app/ skills/ MIGRATION.md` — and reconcile every hit against the 7-pack/11-server truth (count-restating-surfaces convention, review-bumped). Accepted residual: MIGRATION.md:305 autodesk example is pre-existing staleness from #554, not #552's blast radius — noted on that ticket.
- *Remote MCP OAuth handshake* on alpha-vantage may ignore static headers → mitigation: documented as pilot-verify note in README row; pack still ships disabled so a wrong header costs nothing until opted in.


## Gate Trace

- bash -n deploy/setup.sh: silent
- bats (pack_permissions + mcp_count_consistency + select_items + subcommands + setup_ps1_vars): 51 ok / 0 failed, exit 0
- AC #1 per-pack merge proofs: playwright / alpha-vantage / nanobanana each exit 0 — enabled + permissions allow rule present
- AC #4 fail-fast: `--enable-pack bogus` → "Available packs: alpha-vantage chrome-devtools docling markitdown nanobanana nextjs playwright"
- Catalog-name sweep: residuals only in MIGRATION.md history (accepted) and valid examples
