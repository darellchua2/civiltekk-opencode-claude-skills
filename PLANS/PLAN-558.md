# PLAN: --enable-pack creates inert MCP stubs on stale configs

**Branch**: feat/558
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/558
**Base**: main

## Acceptance Criteria
- [ ] `merge-packs.mjs` exits nonzero with an actionable message when a pack enables a server whose target entry lacks `command`/`url` (and no write occurs)
- [ ] Normal path unaffected: flipping a server with a full definition still works (existing tests green)
- [ ] Fresh-deploy ordering unaffected: config copy precedes the pack merge, so new deploys have full definitions and never trip the check
- [ ] bats coverage for both cases (stub → fail; full → pass); full suite green
- [ ] README troubleshooting note (one line)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/merge-packs.mjs` merge loop (L174-198) | — | `deploy/setup.sh` (rc propagation, L3339), `opencode_app/Dockerfile` RUN (build fails red on nonzero — fresh config there never trips), `tests/test_pack_permissions.bats`, `tests/test_docling_skill.bats` | med |
| `tests/test_pack_permissions.bats` (hosts merge-packs behavior tests) | 1.1 | CI | low |
| `README.md` troubleshooting | 1.1 behavior final | docs readers | low |

Cross-module note: merge-packs has consumers beyond itself (setup.sh rc path, Docker build, 2 test files) → architecture review selected; no frontend → uiux not selected. `die()` before the end-of-run write = no partial-write risk (write is a single final call).

## Implementation Phases

### Phase 1: Fail-loud stub detection
- [ ] **1.1** In `deploy/merge-packs.mjs` per-pack loop, before merging the pack's `mcp`: for each `servers` entry with `disabled === false`, verify the TARGET config already defines the server fully (`config.mcp.servers[name]` exists and has a non-empty `command` or `url`); otherwise `die()` with an actionable message naming the pack, the server, and both remedies (re-run setup.sh answering 'y' to refresh the config, or re-copy `opencode_app/opencode.json`)
    — **Why:** the flip-only contract presumes the base definition exists; flipping into a definition-less config creates an inert v2 stub that silently does nothing (the #558 live failure) — fail-closed beats silent success.
    — **Done when:** merging a flip-only pack into a config lacking the server definition exits nonzero with the message and the target file is byte-unchanged; merging into a config WITH the definition exits 0.
    — **Consumers affected:** setup.sh CLI (error propagates), Docker builds (unaffected — fresh config), both bats files.
- [ ] **1.2** Add two tests to `tests/test_pack_permissions.bats`: (a) flip-only pack + target lacking the server → nonzero exit, message matches /no full definition/, target file unchanged; (b) same pack + target WITH the full definition → exit 0, disabled flipped
    — **Why:** AC #1/#4 — the mechanical enforcement of both branches.
    — **Done when:** both tests pass in the Phase 2 gate.
    — **Consumers affected:** CI.
- [ ] **1.3** Fresh-deploy ordering proof: confirm via existing suite that the normal path is untouched (all current pack tests green on the new build) and assert the check only fires on the missing-definition branch
    — **Why:** AC #2/#3 — no regression for fresh deploys where the config copy precedes the merge.
    — **Done when:** `bats tests/test_pack_permissions.bats tests/test_docling_skill.bats` green (docling test exercises merge-packs on a full config).
    — **Consumers affected:** CI.

### Phase 2: Docs
- [ ] **2.1** README: one troubleshooting line near the packs table — pack enable fails with "no full definition" ⇒ the deployed config predates the pack; re-run setup.sh and answer 'y' (or re-copy `opencode_app/opencode.json`), then re-run `--enable-pack`
    — **Why:** AC #5 — the remedy must be findable where pack users look.
    — **Done when:** the line exists and names both remedies.
    — **Consumers affected:** docs readers.

### Phase 3: Verification gate (ticket exit)
- [ ] **3.1** Run gates: `node --check deploy/merge-packs.mjs`; `bats tests/test_pack_permissions.bats tests/test_docling_skill.bats tests/test_mcp_count_consistency.bats`; stub-fail behavioral proof (exit code + byte-unchanged target + message grep); README line present
    — **Why:** ACs #1/#2/#4/#5 — the exit gate (full tier) proving both branches and no regressions.
    — **Done when:** node --check silent, 3 suites green, behavioral proof recorded, README line present.
    — **Consumers affected:** CI, PR merge decision.

## Technical Notes
- The check reads only the TARGET config's existing entry — pack partials stay flip-only (no reference-config input needed; the self-heal alternative stays rejected per ticket).
- setup.sh non-interactive default ("n" at the overwrite prompt) is correct behavior for protecting user customizations — this fix makes the failure mode visible instead of changing that default.
- Message wording should match the ticket's Expected block for consistency with the assistant skill's guidance (#556).

## Dependencies
None (no blocked-by tickets).

## Risks & Mitigation
- *False positive on a legitimately hand-stubbed config* → mitigation: the error message is the remedy; a user intentionally managing stubs gets told exactly what the tool needs. No known legitimate stub use (AGENTS.md documents stubs as inert traps).
- *Docker build regression* → mitigation: Docker's config is freshly copied in-image before the RUN merge; existing pack tests cover the pass branch.
