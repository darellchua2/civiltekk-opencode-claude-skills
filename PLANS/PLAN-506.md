# PLAN: Prune stale LEARNINGS entries and rebuild _index.md

**Branch**: feat/506
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/506
**Base**: main

## Acceptance Criteria

- [ ] The 4 listed learning files are removed; their live residuals survive verbatim in `decisions/goal-plugin-v2-readoption.md`
- [ ] Zero references to the 4 removed slugs remain outside CHANGELOG/`installer/registry.json`
- [ ] The 9 repointed learnings cite only paths/functions that exist on this branch (dated citations explicitly marked as historical evidence are exempt — see 2.5)
- [ ] `LEARNINGS/_index.md` has exactly one auto-append marker, footer at file end, and one entry per learning file on disk (count == count)
- [ ] The allowlist index summary matches disk-derived counts (146 shipped / 106 full allows / 70 lean / 36 hidden vs full; derivation in 3.1)
- [ ] `LEARNINGS-ASSESSMENT.html` removed; `.gitignore` covers `.pytest_cache/`
- [ ] Full `bats tests/` green; `node installer/build-registry.mjs --check` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `LEARNINGS/decisions/goal-plugin-v2-readoption.md` | residual folds (1.1) before deletions (1.3) | session recall (autoinject plugin reads disk), future Docker/plugin work | low |
| `LEARNINGS/solutions/plugin-needs-command-block.md` (delete) | residual fold committed (1.1) + cross-ref sweep (1.2) | goal-plugin-v2-readoption References list (repointed in 1.1) | low |
| `LEARNINGS/solutions/docker-v1-binary-ignores-v2-plugins-key.md` (delete) | same as above | goal-plugin-v2-readoption References list (repointed in 1.1) | low |
| `LEARNINGS/anti-patterns/ps51-audit-whitelists-pscore-only-automatics.md` (delete) | cross-ref sweep (1.2) | `guard-error-branches-need-negative-fixtures.md:19` (repointed in 1.2) | low |
| `LEARNINGS/patterns/pin-every-clause-when-runtime-unexecutable.md` (delete) | cross-ref sweep (1.2) | none found beyond _index.md (audit 2026-09-21) | low |
| 9 repointed learnings (Phase 2) | repoint targets verified on this branch (audit) | session recall, human readers | low |
| `LEARNINGS/_index.md` (Phase 3) | Phase 1 + 2 complete (entries must reflect the final corpus) | `continuous-learning-skill` recall fallback, plan-execution skill, human search | med |
| `skills/continuous-learning-skill/SKILL.md` (Phase 4) | final `_index.md` shape exists (4.1 wording must match it) | skill users (primary sessions); deployed copies pick up on redeploy; frontmatter untouched → no registry rebuild | med |
| `.gitignore` (5.2) | — | git, CI | low |
| `LEARNINGS-ASSESSMENT.html` (delete, 5.1) | zero-ref verification (audit: no references repo-wide) | none — that is why it is removed | low |
| `opencode_app/Dockerfile:63` (repoint, 1.2) | deleted docker-v1 solution's residual home (1.1) | Docker image builders reading the goal-presence comment | low |
| `opencode_app/docker-entrypoint.sh:132-133` (repoint, 1.2) | same as above | healthcheck maintainers | low |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Superseded-pair removal

- [x] **1.1** Fold the two live residuals into `LEARNINGS/decisions/goal-plugin-v2-readoption.md`: (a) the v2 "never add a `commands.goal` block — the package self-registers `/goal`, `/pause_goal`, `/resume_goal`" warning, (b) the "v2 enforces HTTP auth on every route; the Docker healthcheck must authenticate via the entrypoint-materialized password file" note; update its References list to drop the two doomed files
    — **Why:** each deleted solution carries exactly one still-true fact; the decision file is their surviving home and already references them
    — **Done when:** both facts appear in the decision file body and its References list names neither doomed file
    — **Consumers affected:** future sessions recalling Docker healthcheck or goal-plugin config facts
    — **Done:** Both residuals folded verbatim into decisions/goal-plugin-v2-readoption.md (Pattern parenthetical + new Docker note paragraph); References list now names Dockerfile/entrypoint instead of the doomed files; provenance kept ticket-scoped so the 6.1 slug grep stays clean; files: LEARNINGS/decisions/goal-plugin-v2-readoption.md; fixes: none
- [x] **1.2** Sweep repo-wide for the 4 doomed slugs and repoint every surviving reference. Known hits: `LEARNINGS/anti-patterns/guard-error-branches-need-negative-fixtures.md:19` (cites `pin-every-clause-when-runtime-unexecutable` — replace with same-genus phrasing without the pointer); `opencode_app/Dockerfile:63` ("see LEARNINGS/solutions/docker-v1-binary-ignores-v2-plugins-key.md" — repoint to `LEARNINGS/decisions/goal-plugin-v2-readoption.md`, the 1.1 residual home); `opencode_app/docker-entrypoint.sh:132-133` ("(LEARNINGS: docker-v1-binary-ignores-v2-plugins-key)" wrapped parenthetical — repoint to the same decision file). CHANGELOG and `installer/registry.json` exempt
    — **Why:** dangling pointers into deleted files contradict the repo's own `dangling-cross-reference-in-ac` learning
    — **Done when:** the 6.1 command (all file types, same excludes) returns zero hits
    — **Consumers affected:** every document that cited a removed learning
    — **Done:** All 3 known hits repointed — guard-error-branches:19 (genus phrasing, no pointer), opencode_app/Dockerfile:63, opencode_app/docker-entrypoint.sh:132-133 (both → decisions/goal-plugin-v2-readoption.md, Docker note); files: LEARNINGS/anti-patterns/guard-error-branches-need-negative-fixtures.md, opencode_app/Dockerfile, opencode_app/docker-entrypoint.sh; fixes: none
- [x] **1.3** `git rm` the four files: `LEARNINGS/solutions/plugin-needs-command-block.md`, `LEARNINGS/solutions/docker-v1-binary-ignores-v2-plugins-key.md`, `LEARNINGS/anti-patterns/ps51-audit-whitelists-pscore-only-automatics.md`, `LEARNINGS/patterns/pin-every-clause-when-runtime-unexecutable.md`
    — **Why:** 1.1 and 1.2 complete means nothing references them; the files' rules are superseded or their enforcement target (native setup.ps1) no longer exists (#474 thin launcher)
    — **Done when:** all four absent from disk and index; `git status` shows the deletions staged
    — **Consumers affected:** none (post 1.1/1.2)
    — **Done:** git rm of all 4 superseded files, staged and verified absent; files: LEARNINGS/solutions/plugin-needs-command-block.md, LEARNINGS/solutions/docker-v1-binary-ignores-v2-plugins-key.md, LEARNINGS/anti-patterns/ps51-audit-whitelists-pscore-only-automatics.md, LEARNINGS/patterns/pin-every-clause-when-runtime-unexecutable.md; fixes: none

### Phase 2: Repoint stale evidence in 9 learnings

- [ ] **2.1** `LEARNINGS/solutions/path-move-ci-gate-anchoring.md`: append a dated update note covering ALL dead/stale anchors — `plugins/vibeguard.ts` gone (replaced by `plugins/opencode-vibeguard-v2.ts` + `plugins/vibeguard.config.json`); the `setup.ps1:133` must-stay list reference (no such line — 109-line thin launcher); the "setup.sh/ps1 deploy it to `~/.config/opencode/`" phrasing (only `deploy/setup.sh:2710-2713,4086-4087` deploys; ps1 forwards to bash); `Dockerfile:56` → `:82` for the vibeguard COPY
    — **Why:** the cited evidence file and three sibling anchors no longer exist as cited; the search-path-consumer rule remains load-bearing
    — **Done when:** the file's evidence section names only paths that exist on this branch at the cited lines, or carries the dated historical note
    — **Consumers affected:** readers applying the path-move checklist
- [ ] **2.2** `LEARNINGS/solutions/credential-regex-host-port-false-positive.md`: repoint evidence from `opencode_app/.opencode/vibeguard.config.json` to `plugins/vibeguard.config.json:16` and record that the `[^@\s/]+` fix shipped (current pattern no longer matches `host:port/@path`)
    — **Why:** the cited config path moved with the v2 port; the shipped fix is the pattern's justification
    — **Done when:** the evidence section cites the live path and notes the shipped fix
    — **Consumers affected:** vibeguard config maintainers
- [ ] **2.3** `LEARNINGS/patterns/gate-success-log-with-the-dry-branch.md`: repoint the canonical shape from the removed `register_zai_auth` to `run_cmd`'s own gate (`deploy/setup.sh:1117`) with `cleanup_old_backups` (`:1236`) and the credential writer (`:3099`) as live exemplars
    — **Why:** the named exemplar function no longer exists; the early-return shape is alive in run_cmd and its callers
    — **Done when:** the file names only functions that exist in `deploy/setup.sh` on this branch
    — **Consumers affected:** new run_cmd-style gate authors
- [ ] **2.4** `LEARNINGS/solutions/markitdown-mcp-alpha-pin-upstream-facts.md`: change the bump-ritual surface count from three files to two (`deploy/setup.sh` + `opencode_app/Dockerfile`; setup.ps1 is a thin launcher with no pins)
    — **Why:** #474 replaced the native ps1; the third ritual surface no longer exists and would send a bumper editing a file with no pin
    — **Done when:** the ritual sentence lists exactly the two live files
    — **Consumers affected:** future markitdown pin bumps
- [ ] **2.5** `LEARNINGS/anti-patterns/bare-mv-beside-run-cmd-breaks-dry-run.md`: append a dated resolution note — the bash migrate block is now `run_cmd`-wrapped (`deploy/setup.sh:2605-2653`) and the ps1 `Move-Item` sites are gone with the thin launcher
    — **Why:** the named defect no longer exists anywhere; the forward-looking rule (route mutations through run_cmd) stays
    — **Done when:** the file carries the dated note and its rule section is unchanged
    — **Consumers affected:** dry-run contract auditors
- [ ] **2.6** `LEARNINGS/conventions/doc-claims-match-plugin-defaults.md`: update the evidence reference from `plan-automation-loop-skill` to `plan-execution-skill` (#408 merged the two skills; `worktree-pipeline-skill` already names the new one)
    — **Why:** the cited SKILL.md path is dead; a reader following the pointer would 404
    — **Done when:** the evidence cites `plan-execution-skill` with the #408 merge note
    — **Consumers affected:** doc authors citing plugin-default claims
- [ ] **2.7** `LEARNINGS/conventions/task-delegate-permission-sync.md`: update pre-#378 paths — `deploy/build-registry.mjs` → `installer/build-registry.mjs`, `deploy/registry.json` → `installer/registry.json` (keep the `--check` drift-gate guidance)
    — **Why:** build-registry moved to `installer/` in #378; the cited paths are dead
    — **Done when:** no `deploy/build-registry` or `deploy/registry.json` strings remain in the file
    — **Consumers affected:** permission.task editors running the sync checklist
- [ ] **2.8** `LEARNINGS/patterns/new-skill-count-literal-gates.md`: line 10 — drop the ps1 half of consumer class 6 (`deploy/setup.ps1` search-anchor `Invoke-SkillProfile`; function gone since #474), keep the bash anchor (`run_skill_profile` header comments in `deploy/setup.sh`, function at :3536); line 12 — drop `deploy/setup.ps1` from the verification grep target so the sweep names only the live surface
    — **Why:** the dead ps1 citation lives in this file; skill-add-count-sync-blast-radius.md carries no deploy-script citation on this branch (audit 2026-09-21, Mode R round 1)
    — **Done when:** the file contains no `Invoke-SkillProfile`/`setup.ps1` reference; `run_skill_profile` is the sole search-anchor
    — **Consumers affected:** skill add/remove authors sweeping count literals
- [ ] **2.9** `LEARNINGS/anti-patterns/idempotency-probe-version-blind.md`: drop the ps1-mirror sentence (`Install-MarkitdownMcp`); keep the bash probe rule (`pip show` + version grep)
    — **Why:** the ps1 mirror function no longer exists
    — **Done when:** the file contains no `Install-MarkitdownMcp` / `setup.ps1` reference
    — **Consumers affected:** pin-bump authors writing idempotency probes

### Phase 3: Rebuild `LEARNINGS/_index.md`

- [ ] **3.1** Regenerate `_index.md` from the final corpus: one entry per learning file on disk (expect 118 after Phase 1), a single `<!-- Entries are appended here automatically -->` marker at the top of the Entries section, the storage-locations footer moved to file end, the allowlist entry summary re-derived from disk (see the Derivation line below)
    — **Why:** the index is the fallback discovery surface; 26 orphaned files, 7 duplicated markers, a mid-file footer, and a stale summary (148/46 vs actual 146/70) make it lie in four ways
    — **Done when:** entry count == file count == 118; exactly one marker; footer after the last entry; the allowlist summary states disk-derived numbers (146 shipped / 106 full allows / 70 lean / 36 hidden vs full) and notes that one of the 106 allows (`github-runners-setup-skill`) is app-scoped — shipped under `opencode_app/.opencode/skills/`, outside root `skills/` (see `decisions/app-scoped-skill-surface.md`)
    — **Consumers affected:** continuous-learning-skill recall fallback, plan-execution skill, human search
    — Derivation: `find LEARNINGS -name '*.md' ! -name '_index.md' | wc -l`; `grep -A3 '"action": "skill"' opencode_app/opencode.json | grep -c '"effect": "allow"'` (= 106 — a raw `"action": "skill"` count returns 107 because it includes the deny-all rule at opencode.json:29-31); `python3 -c` over `deploy/skill-profiles.json` lean keys (= 70)

### Phase 4: Fix the writer ritual

- [ ] **4.1** Edit `skills/continuous-learning-skill/SKILL.md` step 5 to say: append the new entry **below the single existing marker** (never re-add the marker) and add the entry in the same write as the learning file — body-only edit, frontmatter untouched
    — **Why:** the current "update with a one-line link" wording produced 26 unindexed files and 7 duplicated markers — the index drift is caused by the ritual, not a tool
    — **Done when:** step 5 states the single-marker + same-write rule; `node installer/build-registry.mjs --check` stays green (no frontmatter change → no rebuild)
    — **Consumers affected:** every future learning write; deployed copies pick the fix up on redeploy

### Phase 5: Repo hygiene

- [ ] **5.1** `git rm LEARNINGS-ASSESSMENT.html`
    — **Why:** 82KB tracked artifact from 2026-08-04, zero references repo-wide (audit-verified), superseded by the restructured `LEARNINGS/` tree it assessed
    — **Done when:** file absent from disk and index
    — **Consumers affected:** none
- [ ] **5.2** Append `.pytest_cache/` to `.gitignore`
    — **Why:** the untracked local debris shows in `git status` noise on every pytest run
    — **Done when:** `git check-ignore .pytest_cache/` exits 0
    — **Consumers affected:** local developer workflows

### Phase 6: Verification gates (ticket exit — tier=full)

- [ ] **6.1** Zero-reference gate: `grep -rn "plugin-needs-command-block\|docker-v1-binary-ignores\|ps51-audit-whitelists\|pin-every-clause-when-runtime" . --exclude-dir=.git --exclude-dir=node_modules | grep -v "CHANGELOG" | grep -v "installer/registry.json" | grep -v "PLANS/"` returns nothing
    — **Why:** AC 2 is unqualified ("zero references… outside CHANGELOG/installer/registry.json") — the drafted include-filter would have missed the Docker surface (Dockerfile is extensionless, entrypoint is *.sh) and self-hit on this PLAN's own slug mentions
    — **Done when:** command exits with no output
    — **Consumers affected:** none
- [ ] **6.2** Index integrity gate: entry count == `find LEARNINGS -name '*.md' ! -name '_index.md' | wc -l`; exactly one occurrence of the auto-append marker; the storage footer appears after the last entry
    — **Why:** AC 4
    — **Done when:** all three assertions pass
    — **Consumers affected:** index consumers
- [ ] **6.3** Repoint existence gate: for each path/function cited by the 9 Phase-2 files, assert existence (`test -e` for paths; `grep -E "^(function )?<fn>\(\)" deploy/setup.sh` for functions); additionally assert `skill-add-count-sync-blast-radius.md`'s citations resolve (verify-only — no edit expected, Mode R round 1)
    — **Why:** AC 3
    — **Done when:** every cited target resolves
    — **Consumers affected:** none
- [ ] **6.4** Registry drift gate: `node installer/build-registry.mjs --check` exits 0
    — **Why:** SKILL.md edit must be body-only; proves it
    — **Done when:** exit 0
    — **Consumers affected:** CI
- [ ] **6.5** Full unit gate: `bats tests/` — every suite green
    — **Why:** AC 7; the LEARNINGS-citing tests carry comment-only references (verified in audit), so no assertion should move
    — **Done when:** all bats suites exit 0
    — **Consumers affected:** CI
- [ ] **6.6** Append the `GATE <short-sha> tier=full` memo line — scoped to the SHA of the commit that ran this gate — to this PLAN's trace block; the worktree-pipeline's Step 10 (PR creation) cites this memo line as its gate evidence
    — **Why:** the pipeline's PR step requires a green tier=full memo for the final pushed tree
    — **Done when:** memo line present, naming the SHA of the gate-run commit
    — **Consumers affected:** pr-workflow-subagent

## Technical Notes

- Mode R round 1 (2026-09-21), allowlist-count delta vs ticket AC: the ticket's AC said "107 full allows"; canonical derivation = allow-effect skill rules = **106** (106−70=36 restores the AC's own "36 hidden vs full"); 107 was the raw skill-rule count including the deny-all at `opencode_app/opencode.json:29-31`. Recorded as a #506 ticket comment, not an AC edit. The spawning audit recorded 106 in one place and 107 in another — the ticket's Problem-section intent ("matches disk-derived counts") governs.
- Review fixes applied to this PLAN (arch review round 1, approved-with-changes): gate 6.1 widened to all file types + PLANS/ self-exclusion (BLOCK-1); AC5/3.1 tuple corrected to 106 (BLOCK-2); step 2.8 retargeted to `new-skill-count-literal-gates.md` (BLOCK-3); 2.1 anchor list completed (WARN-1); 6.6 dangling "Step 10" fixed + memo SHA-scoped (WARN-2); AC3 historical-evidence exemption added (WARN-3).

- Audit evidence (2026-09-21 Plan-mode session): 26 unindexed files; 96 `- **File**:` entries vs 122 disk files; markers at 7 locations; footer at `_index.md:625-631`; allowlist index summary `_index.md:401-407` says 148/46 vs file-truth 146/70; doomed-slug cross-refs at `goal-plugin-v2-readoption.md:4,17,18` and `guard-error-branches-need-negative-fixtures.md:19`.
- `setup_zai_api_key` does NOT carry the dry-branch shape (verified 2026-09-21) — 2.3 repoints to `run_cmd`'s own gate instead.
- CI bats tests cite LEARNINGS in comments only (`test_jsonc_sibling.bats:8`, `test_plan_executor.bats:158,198`, `test_reviewer_no_writes.bats:5,8`, `test_tiered_gating.bats:6`) — none of the deleted slugs are among them, so no assertion moves.
- Registry entries are frontmatter-derived (build-registry.mjs:27-31) — the SKILL.md edit is body-only; `--check` at 6.4 proves no accidental frontmatter touch.
- `package.json` scripts is `{}` — gates are named explicitly above (PLAN-381 precedent).

## Dependencies

None external. Ticket #506 is standalone (no `blocked-by:`).

## Risks & Mitigation

- **Index rebuild loses hand-written context** — the header above the auto-generated comment is preserved verbatim during regeneration; only the listing below the marker is rebuilt.
- **Deleting learnings loses recoverable knowledge** — user-approved (Build-mode decisions 2026-09-21); git history preserves the files; residuals folded verbatim into the decision record first.
- **Count drift between index write and gate** — 6.2 derives counts from disk at gate time, same tree, so drift is impossible within a phase commit.
- **bats suite has pre-existing failures** — none known at PLAN time (main green at 9bd649b5); any red gate is investigated, not waived.
