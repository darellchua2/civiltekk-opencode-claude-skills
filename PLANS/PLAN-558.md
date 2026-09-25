# PLAN: --enable-pack creates inert MCP stubs on stale configs

**Branch**: feat/558
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/558
**Base**: main

## Acceptance Criteria
- [x] `merge-packs.mjs` exits nonzero with an actionable message when a pack enables a server whose target entry lacks `command`/`url` (and no write occurs)
- [x] Normal path unaffected: flipping a server with a full definition still works (existing tests green)
- [x] Fresh-deploy ordering unaffected: config copy precedes the pack merge, so new deploys have full definitions and never trip the check
- [x] bats coverage for both cases (stub → fail; full → pass); full suite green
- [x] README troubleshooting note (one line)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/merge-packs.mjs` merge loop (L174-198) | — | `deploy/setup.sh` hard-fail rc path (`deploy_agents` critical → exit 1), `deploy/setup.sh:4067` `--select` soft-fail call site (warns + returns 0 by #473 contract — exit-0-with-stderr accepted there), `--dry-run` preview merge (setup.sh:3317-3331 — now exits 1 on stale configs, accepted), `opencode_app/Dockerfile` RUN (fresh config never trips), `tests/test_pack_permissions.bats`, `tests/test_docling_skill.bats` | med |
| `tests/test_pack_permissions.bats` (hosts merge-packs behavior tests) | 1.1 | CI | low |
| `README.md` troubleshooting | 1.1 behavior final | docs readers | low |

Cross-module note: architecture review completed (2026-09-25) — rc chain verified end-to-end (die → run_pack_merger → deploy_agents critical → exit 1), Tier-4 probe proved all 7 packs flip-only and every shipped target has a full definition; 1 Major applied (fixture :94-118 amendment owned by 1.2c), 5 minors applied (consumer-map rows, predicate pin, shape hardening, gate widening). Relay round 1: message string pinned, dry-run exit-1 accepted, gate widened. No frontend → uiux not selected. `die()` before the end-of-run write = no partial-write risk (write is a single final call).

## Implementation Phases

### Phase 1: Fail-loud stub detection
- [x] **1.1** In `deploy/merge-packs.mjs` per-pack loop, before merging the pack's `mcp`: for each `servers` entry with `disabled === false`, verify the TARGET config already defines the server fully (`config.mcp.servers[name]` exists and has a non-empty `command` or `url`); otherwise `die()` with the PINNED message (relay round 1; test 1.2(a) greps /no full definition/ against it): `ERROR: pack '<pack>' enables '<server>', but the target config has no full definition for it (missing command/url). The deployed config predates this pack. Re-run setup.sh and answer 'y' to refresh the config, or re-copy opencode_app/opencode.json.` Predicate pinned: a missing or non-object entry fails; `command` must be an array with length > 0, `url` a non-blank string
    — **Why:** the flip-only contract presumes the base definition exists; flipping into a definition-less config creates an inert v2 stub that silently does nothing (the #558 live failure) — fail-closed beats silent success.
    — **Done when:** merging a flip-only pack into a config lacking the server definition exits nonzero with the message and the target file is byte-unchanged; merging into a config WITH the definition exits 0.
    — **Consumers affected:** setup.sh CLI (error propagates), Docker builds (unaffected — fresh config), both bats files.
    — **Done:** guard inserted in the per-pack loop before the mcp deepMerge; pinned message verbatim; predicate: missing/non-object entry or empty command+url fails; die before the single final write (merge-packs.mjs:238); files: deploy/merge-packs.mjs; fixes: none
- [x] **1.2** `tests/test_pack_permissions.bats`: (a) NEW test — flip-only pack + target lacking the server → nonzero exit, message matches /no full definition/, target file byte-unchanged; (b) NEW test — same pack + target WITH the full definition → exit 0, disabled flipped; (c) AMEND `pack_merge_preserves_unrelated_permission_rules` (:94-118) — give its minimal fixture a full markitdown definition (mirroring :74) or the new guard kills it; (d) one-line hardening in the shape test: pack server fragments' key set ⊆ {disabled} (keeps the predicate's flip-only assumption enforced) — 1.1 + 1.2 land in ONE commit (guard + its fixture mirror are coupled: fail-closed-guard-couples-cross-file-edits)
    — **Why:** AC #1/#4 — the mechanical enforcement of both branches.
    — **Done when:** both tests pass in the Phase 2 gate.
    — **Consumers affected:** CI.
    — **Done:** 2 new tests (definition-less → nonzero + /no full definition/ + byte-unchanged; full definition → flip works) + fixture :94-118 amended with full markitdown definition + shape test hardening (fragment keys ⊆ {disabled}); files: tests/test_pack_permissions.bats; fixes: 1 (first apply attempt leaked bash through the heredoc — caught before any write, redone with distinct delimiters)
- [x] **1.3** Fresh-deploy ordering proof: confirm via existing suite that the normal path is untouched (all current pack tests green on the new build) and assert the check only fires on the missing-definition branch
    — **Why:** AC #2/#3 — no regression for fresh deploys where the config copy precedes the merge.
    — **Done when:** `bats tests/test_pack_permissions.bats tests/test_docling_skill.bats` green with the amended fixture (1.2c) — the plan's original 'all current tests green' premise was false for exactly one fixture (plan-review Major).
    — **Consumers affected:** CI.
    — **Done:** test_pack_permissions + test_docling_skill green with the amended fixture; files: gate run; fixes: none

### Phase 2: Docs
- [x] **2.1** README: one troubleshooting line near the packs table — pack enable fails with "no full definition" ⇒ the deployed config predates the pack; re-run setup.sh and answer 'y' (or re-copy `opencode_app/opencode.json`), then re-run `--enable-pack`
    — **Why:** AC #5 — the remedy must be findable where pack users look.
    — **Done when:** the line exists, names both remedies, and notes the check applies to `--dry-run` previews too (relay round 1: a preview showing a successful stub merge is the silent failure in preview form).
    — **Consumers affected:** docs readers.
    — **Done:** troubleshooting line at README.md:231 with both remedies + dry-run clause; files: README.md; fixes: none

### Phase 3: Verification gate (ticket exit)
- [x] **3.1** Run gates: `node --check deploy/merge-packs.mjs`; `bats tests/` (full local suite, 43 files — relay round 1); stub-fail behavioral proof (exit code + byte-unchanged target + message grep); README line present
    — **Why:** ACs #1/#2/#4/#5 — the exit gate (full tier) proving both branches and no regressions.
    — **Done when:** node --check silent, full `bats tests/` green, behavioral proof recorded, README line present.
    — **Consumers affected:** CI, PR merge decision.
    — **Done:** node --check silent; full bats tests/ = 565 ok / 0 failed, exit 0; stub behavioral proof: exit 1, pinned message, byte-unchanged target; README line verified; files: gate run; fixes: none

## Technical Notes
- Accepted behavior change (relay round 1): `--dry-run --enable-pack` on a stale config now exits 1 at the preview merge (was: exit 0 with a stub-bearing preview) — consistent with the dry-run contract that the preview reflects the would-be-merged result (setup.sh:3326-3331).
- Landing: 1.1 + 1.2 in one commit (guard + fixture mirror coupled); the rest may follow in the same atomic commit.
- The check reads only the TARGET config's existing entry — pack partials stay flip-only (no reference-config input needed; the self-heal alternative stays rejected per ticket).
- setup.sh non-interactive default ("n" at the overwrite prompt) is correct behavior for protecting user customizations — this fix makes the failure mode visible instead of changing that default.
- Message wording should match the ticket's Expected block for consistency with the assistant skill's guidance (#556).

## Dependencies
None (no blocked-by tickets).

## Risks & Mitigation
- *False positive on a legitimately hand-stubbed config* → mitigation: the error message is the remedy; a user intentionally managing stubs gets told exactly what the tool needs. No known legitimate stub use (AGENTS.md documents stubs as inert traps).
- *Docker build regression* → mitigation: Docker's config is freshly copied in-image before the RUN merge; existing pack tests cover the pass branch.


## Gate Trace

- node --check deploy/merge-packs.mjs: silent
- Full suite `bats tests/`: 565 ok / 0 failed, exit 0 (43 files)
- AC #1 behavioral proof: flip into definition-less target → exit 1, pinned message verbatim, target byte-unchanged (cmp)
- AC #2/#3: flip with full definition → exit 0 + flip applied (both the new test and the amended fixture prove the pass branch)
- README troubleshooting line present at README.md:231 with dry-run clause

- Code review: APPROVE, 0 Critical / 0 Major / 3 cosmetic NOTEs (double error: prefix, strict-direction shape-test note, this anchor). Gate stands.

GATE 236a533 tier=full lint=t typecheck=n.a. build=n.a. unit=t e2e=n.a.
