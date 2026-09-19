# PLAN: Purge stale docs (PLANS/audits/research) + refresh allowlist LEARNING

**Branch**: feat/GIT-365
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/365
**Base**: main

## Acceptance Criteria

- [x] All 6 fully-executed plans deleted from `PLANS/` (zero unchecked boxes verified at 3fb5a29); `git ls-files PLANS/` afterward retains only `.gitkeep`, `.gitignore`, `PLAN-GIT-365.md`
- [x] `docs/audits/skill-yaml-compliance-audit.md` deleted (dir holds exactly this file); `docs/prd/` untouched
- [x] 4 superseded/unreferenced research files deleted; `research/ponytail-load-fix.md` kept
- [x] `research/ponytail-load-fix.md` dangling pointer to `ponytail-agent-integration-audit.md` removed
- [x] `LEARNINGS/decisions/skill-permission-allowlist.md` refreshed to registry truth (148 skills / 46 lean, verified 2026-09-09) including derived figures ("hides 44 subagent-only", "43 subagent-only"); dangling `PLANS/PLAN-GIT-270.md` / `PLAN-GIT-333.md` path refs dropped
- [x] `LEARNINGS/_index.md` summary lines mirror the refresh; provenance citation in `LEARNINGS/conventions/task-delegate-permission-sync.md` no longer names a purged plan slug
- [x] Bats comment citations to purged plans (`test_mcp_count_consistency.bats`, `test_voice_pack.bats`) reworded — comment-only, test behavior unchanged
- [x] Identifier sweep (basename slugs, not paths) across tracked files: zero dangling refs outside `CHANGELOG.md` historical citations (accepted repo precedent)
- [x] `node deploy/build-registry.mjs --check` passes; full `bats tests/` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `PLANS/*.md` (6 files) | — | `tests/test_mcp_count_consistency.bats` comments (step 2.4); `tests/test_voice_pack.bats:3` comment (step 2.4); `LEARNINGS/conventions/task-delegate-permission-sync.md:43` (step 3.3); CHANGELOG citations (historical text, accepted) | low |
| `docs/audits/skill-yaml-compliance-audit.md` | — | none (grep-verified) | low |
| 4 `research/*.md` files | — | `research/ponytail-load-fix.md:126` (step 2.3); LEARNINGS tier-swap exemption note (directory-level, dir persists) | low |
| `research/ponytail-load-fix.md:126` | 2.2 | shipped plugins cite ponytail-load-fix.md itself, not the audit | low |
| `LEARNINGS/decisions/skill-permission-allowlist.md` | — | `LEARNINGS/_index.md` summaries (step 3.2) | low |
| `LEARNINGS/_index.md` | 3.1 | session autoinject manifest (read-only consumer) | low |
| `LEARNINGS/conventions/task-delegate-permission-sync.md:43` | — | sweep gate 4.1 | low |
| bats comment citations | — | sweep gate 4.1 | low |
| Verification gate | 1.1–3.3 | CI (registry drift check, bats suites) | low |

## Implementation Phases

### Phase 1: Purge consumed plans
- [x] **1.1** `git rm` the six executed plans: `PLANS/PLAN-356.md`, `PLANS/PLAN-DRAFT-skill-stack-simplification.md`, `PLANS/PLAN-GIT-349.md`, `PLANS/PLAN-GIT-350.md`, `PLANS/PLAN-GIT-351.md`, `PLANS/PLAN-GIT-357.md`
    — **Why:** all executed (zero unchecked boxes) and 1–2+ weeks old; repo lifecycle purges consumed plans in batches (31 already deleted, last purge 2026-08-27)
    — **Done when:** `git ls-files PLANS/` lists only `.gitkeep`, `.gitignore`, `PLAN-GIT-365.md` — the six purged slugs are absent (dir persists via tracked `.gitkeep`, by design since 414dcaa)
    — **Consumers affected:** three comment-level citations and one LEARNINGS provenance line are repaired in 2.4 / 3.3; CHANGELOG plan-id citations are historical text, unaffected (accepted precedent); `PLANS/` dir persists so `plan-updater-skill` (`find PLANS`) and `worktree-pipeline-skill` (`mkdir -p`) keep working unchanged
    — **Done:** removed the six plan files via git rm; `git ls-files PLANS/` = `.gitignore .gitkeep PLAN-GIT-365.md` exactly; files: the six PLANS/*.md; fixes: none (gate first-try: registry OK 33/148 no-drift, bats 318/318 — after initializing the bats-core submodule in this worktree)

### Phase 2: Purge point-in-time audits + superseded research
- [x] **2.1** `git rm docs/audits/skill-yaml-compliance-audit.md`
    — **Why:** point-in-time compliance audit against long-purged PLAN-GIT-254; referenced by zero tracked files
    — **Done when:** file gone; the dir held exactly this one file so `docs/audits/` disappears; `docs/prd/` persists
    — **Consumers affected:** none (grep-verified: `skill-yaml-compliance` and `docs/audits` appear in no other tracked file)
    — **Done:** git rm audit doc; docs/ now holds only prd/; files: docs/audits/skill-yaml-compliance-audit.md; fixes: none (zero tracked refs verified)
- [x] **2.2** `git rm` four research files: `research/mcp-11811-implementation-audit.md`, `research/research-opencode-11811-stateless-mcp.md`, `research/ponytail-agent-integration-audit.md`, `research/research-zai-glm-5v-turbo-opencode-access.md`
    — **Why:** upstream-opencode investigation notes and a superseded prior audit, referenced by name nowhere; the glm-5v-turbo vision rationale is already shipped in `zai-vision-analysis-skill` + root `AGENTS.md` (user-approved deletion)
    — **Done when:** `research/` contains exactly `ponytail-load-fix.md`
    — **Consumers affected:** `research/ponytail-load-fix.md:126` cites one of them (fixed in 2.3); `LEARNINGS/patterns/tier-model-swap-blast-radius.md` exemption note says "research/" directory-level — dir persists, note stays valid
    — **Done:** git rm four research docs; research/ = ponytail-load-fix.md only; files: the four research/*.md; fixes: none
- [x] **2.3** Edit `research/ponytail-load-fix.md` (~line 126) to drop the dangling pointer to `research/ponytail-agent-integration-audit.md`
    — **Why:** the cited file is deleted in 2.2; the one live research doc must stay self-consistent (3 shipped plugin files cite it)
    — **Done when:** `rg ponytail-agent-integration-audit` over tracked files returns zero matches
    — **Consumers affected:** `ponytail-scoped.ts`, `learnings-autoinject.ts/.README.md` cite `ponytail-load-fix.md` itself — prose-only edit, citation intact
    — **Done:** reworded line 126 to keep the conclusion, drop the deleted doc pointer; files: research/ponytail-load-fix.md; fixes: none (rg ponytail-agent-integration-audit = only PLAN self-enumeration)
- [x] **2.4** Reword purged-plan citations in bats comments: `tests/test_mcp_count_consistency.bats` lines 21, 59, 83 (PLAN-GIT-357) and `tests/test_voice_pack.bats` line 3 (PLAN-356)
    — **Why:** sweep gate 4.1 and the ticket AC require zero slug matches outside CHANGELOG; these are comment-only lines whose informational content (opt-in shipping, test subject) is preserved without the stale plan ids
    — **Done when:** `rg 'PLAN-GIT-357|PLAN-356' tests/` returns zero matches; `bats tests/` still green (behavior unchanged)
    — **Consumers affected:** none at runtime — comment-only edits, no assertion touched
    — **Done:** reworded 4 comment lines to issue-ref form (GIT-357 / #356), matching in-file precedent; files: tests/test_mcp_count_consistency.bats, tests/test_voice_pack.bats; fixes: none (rg slugs in tests/ = zero; bats 318/318 unchanged)

### Phase 3: Refresh stale LEARNINGS
- [x] **3.1** Update `LEARNINGS/decisions/skill-permission-allowlist.md`: volatile counts 88 shipped / 30 lean → 148 skills / 46 lean (deploy/registry.json + deploy/skill-profiles.json, verified 2026-09-09); recompute/verify derived figures ("hides 44 subagent-only skills" line 5-adjacent, "43 subagent-only" line 5) against current registry; drop `PLANS/PLAN-GIT-270.md` / `PLANS/PLAN-GIT-333.md` path references
    — **Why:** the stored numbers are factually wrong for the current repo (148/46) and internally inconsistent (44 vs 43); the mechanism decision itself still governs
    — **Done when:** file states 148/46 as current counts, derived figures are consistent with the registry, and no path refs to the two purged plans remain
    — **Consumers affected:** `_index.md` summary (3.2)
    — **Done:** refreshed title/context/pattern/rationale to 148 shipped / 105 full allows / 46 lean; recomputed derived figures (43 hidden under full, 59 more under lean, 102 total); dropped both purged-plan path refs; added re-derive note; files: LEARNINGS/decisions/skill-permission-allowlist.md; fixes: none (counts computed live from registry + opencode.json before edit)
- [x] **3.2** Mirror the count refresh in the auto-generated `LEARNINGS/_index.md` entry title + summary for the allowlist decision (including the "hides 44" derived figure at line 35)
    — **Why:** `_index` is the per-session autoinjected manifest; stale numbers propagate to every session until next learning write
    — **Done when:** `rg 'shipped 88|lean profile 30|88 allows|30 allows|hides 44|hides 58|PLAN-GIT-350|PLAN-GIT-270|PLAN-GIT-333' LEARNINGS/` returns zero matches — the *current* derived figure "43 subagent-only" (148−105, verified 2026-09-09) is legitimate and must remain
    — **Consumers affected:** session autoinject (read-only consumer of `_index`); durability of the manual edit across regenerations depends on the external learnings-autoinject plugin (see Risks)
    — **Done:** mirrored entry title + summary (hides 102, 148-46); files: LEARNINGS/_index.md; fixes: tightened the gate regex in this PLAN — original pattern flagged the legitimate current figure "43 subagent-only" (gate-spec bug, not staleness); re-run clean
- [x] **3.3** Reword the provenance citation in `LEARNINGS/conventions/task-delegate-permission-sync.md:43` ("PLAN-GIT-350 §1.3") to reference the deferral without the purged plan slug
    — **Why:** sweep gate 4.1 requires zero purged-slug matches outside CHANGELOG; the provenance fact (deliberate deferral) is preserved
    — **Done when:** `rg 'PLAN-GIT-350' LEARNINGS/` returns zero matches
    — **Consumers affected:** none — prose-only edit inside a convention note
    — **Done:** reworded provenance citation to issue form (GIT-350 §1.3), matching line-42 precedent; files: LEARNINGS/conventions/task-delegate-permission-sync.md; fixes: none

### Phase 4: Verification gate
- [x] **4.1** Identifier sweep: `rg` each deleted file's basename slug (e.g. `skill-yaml-compliance-audit`, `mcp-11811-implementation-audit`, `research-opencode-11811-stateless-mcp`, `ponytail-agent-integration-audit`, `research-zai-glm-5v-turbo-opencode-access`, `PLAN-GIT-349`, `PLAN-GIT-350`, `PLAN-GIT-351`, `PLAN-GIT-357`, `PLAN-356`, `PLAN-DRAFT-skill-stack-simplification`) across tracked files
    — **Why:** repo learning: sweep by identifier, not filename/path — path greps miss namesakes and identifier greps catch prose citations
    — **Done when:** zero matches outside `CHANGELOG.md` (historical citations, accepted precedent) — enabled by repair steps 2.3, 2.4, 3.3
    — **Consumers affected:** all future doc readers
    — **Done:** swept 11 slugs over git-tracked files excluding CHANGELOG.md + PLAN self-enumeration: zero matches; files: none (read-only gate); fixes: none
- [x] **4.2** Run `node deploy/build-registry.mjs --check`
    — **Why:** frontmatter untouched, so the committed registry must show zero drift
    — **Done when:** exit 0
    — **Consumers affected:** CI (fails on drift)
    — **Done:** registry OK (agents=33, skills=148, no drift); fixes: none
- [x] **4.3** Run full `bats tests/`
    — **Why:** count-drift and MCP-consistency suites guard the surfaces this purge could indirectly touch; also proves 2.4's comment-only claim
    — **Done when:** all suites green
    — **Consumers affected:** CI, release-please
    — **Done:** bats 318/318 green, exit 0; fixes: none (bats-core submodule initialized in this worktree before first run)

## Technical Notes

- Documentation-only change; zero shipped code touched (2.4 edits bats comments only, verified by the unchanged-suite gate 4.3).
- Keep: `research/ponytail-load-fix.md` (cited by 3 shipped plugin files), tsoa/redocly LEARNINGS (baked into `api-design-skill:286` + `openapi-contract-adherence-skill:148`), `MIGRATION.md`, `CHANGELOG.md` (release-please generated), vendored `tests/lib/bats-core/` docs (user decision: vendor dir pristine).
- `PLANS/.gitkeep` + `.gitignore` are tracked by design (414dcaa) — the dir persists after the purge; README tree row stays accurate, no README edit needed.
- Historical citations to long-purged plans in README prose (lines 245, 564, 393) predate this purge and are out of scope (noted as follow-up observation on the PR).

## Dependencies

None — standalone docs purge.

## Risks & Mitigation

- **A live namesake survives a filename-level check** → mitigated by identifier-level sweep (4.1), per repo learning.
- **Stale-count edit introduces new wrong numbers** → counts verified against `deploy/registry.json` + `deploy/skill-profiles.json` immediately before the edit; derived figures recomputed in 3.1.
- **`_index.md` manual edit may be overwritten by a future auto-regeneration** → `deploy/setup.sh` only templates the file when missing; whether regeneration derives summaries from the refreshed 3.1 content is decided by the external learnings-autoinject plugin — accepted residual risk, flagged on the PR.