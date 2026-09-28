# PLAN: Purge stale doc references; minimize AGENTS.md

**Branch**: feat/636
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/636
**Base**: main (cut from origin/main @ e278d2d)

## Acceptance Criteria

- [ ] Root `LEARNINGS/` holds only `_index.md`; the #515 fragment exists as a
      dated evidence-add inside the anti-patterns copy
- [ ] `rg 'vibeguard\.ts:490' LEARNINGS/` → 0 hits; `_index.md` cites
      `plugins/opencode-vibeguard-v2.ts:504-508`
- [ ] `rg 'PLAN-BT-74' MIGRATION.md` → 0 hits
- [ ] MIGRATION.md tier mentions match the registry; 45/105 qualified as
      at-v2.0.0
- [ ] `rg 'Secret Hygiene|Extract-then-Delegate' AGENTS.md` → 0 hits;
      §Repository Purpose ≤5 lines + README pointer; §Project Learnings
      reduced to the template note
- [ ] Gates green: `bats tests/test_docling_skill.bats
      tests/test_skill_isolation.bats tests/test_pack_permissions.bats
      tests/test_count_drift.bats` (bats on PATH; repo's
      `tests/lib/bats-core/bin/bats` vendoring is absent)

## Dependency & Consumer Map

| Node (file) | Depends on | Consumers | Change risk |
|-------------|------------|-----------|-------------|
| `LEARNINGS/anti-patterns/embedded-diff-hunks-unverifiable-probe-git-head-first.md` | — | `LEARNINGS/_index.md` entry, session auto-inject manifest | low |
| `LEARNINGS/_index.md` | the anti-patterns file it indexes | auto-inject plugin (every session), humans | low |
| `MIGRATION.md` | — | `deploy/setup.sh:3170` warning text, `tests/test_skill_isolation.bats:32`, `tests/test_pack_permissions.bats:209`, `README.md:9,113`, `AGENTS.md` §Subagent Model Tiering, `CHANGELOG.md`, `agents/opencode-v2-migration-subagent.md:191` | med |
| `AGENTS.md` | — | session system-prompt injection, `tests/test_docling_skill.bats:106` (greps `Office Document Extraction Routing`), `skills/docling-mcp-skill/SKILL.md` pointer, 4 agent-file pointers | med |

Pins to respect: keep the §Office Document Extraction Routing heading in
AGENTS.md verbatim; add no dead permission-key patterns anywhere
(`no_doc_teaches_dead_permission_keys`); touch no frontmatter (no registry
regen).

## Implementation Phases

### Phase 1: LEARNINGS — merge orphan fragment + index patch

- [x] **1.1** Merge the untracked #515 fragment from the main checkout
    (`../../civiltekk-opencode-claude-skills/LEARNINGS/embedded-diff-hunks-unverifiable-probe-git-head-first.md`
    — gitignored, hence absent from this worktree) into
    `LEARNINGS/anti-patterns/embedded-diff-hunks-unverifiable-probe-git-head-first.md`
    as a `## Evidence add (2026-09-28, #515 instance)` section; then delete the
    untracked file in the main checkout (out-of-band — ignored files cannot
    ride the branch).
    — **Why:** the fragment's rule (re-verify against the real branch HEAD
    before raising a BLOCK) is invisible to every session — no category
    header, unindexed, never auto-injected.
    — **Done when:** the anti-patterns file contains the #515-instance
    paragraph; `ls ../../civiltekk-opencode-claude-skills/LEARNINGS/*.md`
    lists only `_index.md`; worktree git status shows the anti-patterns file
    modified.
    — **Consumers affected:** session auto-inject (gains the #515 rule);
    `_index.md` readers.
    — **Done:** published the learning as a tracked file (body verbatim +
    `## Evidence add (2026-09-28, #515 instance)`) with `.gitignore`
    negation line per the tracked-LEARNINGS convention; deleted BOTH
    untracked main-checkout copies (root fragment + superseded
    categorized file — content superset preserved here, and the main
    checkout stays pullable); files: LEARNINGS/anti-patterns/embedded-diff-hunks-unverifiable-probe-git-head-first.md, .gitignore; fixes: none

- [x] **1.2** Patch the `LEARNINGS/_index.md:605` summary to cite
    `plugins/opencode-vibeguard-v2.ts:504-508`, matching the learning file's
    2026-09-26 #517 update.
    — **Why:** the index snapshot contradicts the file it indexes.
    — **Done when:** `rg 'vibeguard\.ts:490' LEARNINGS/` → 0 hits.
    — **Consumers affected:** auto-inject manifest consumers.
    — **Done:** swapped the citation to `plugins/opencode-vibeguard-v2.ts:504-508`; verified zero `vibeguard\.ts:490` hits tree-wide in LEARNINGS/; files: LEARNINGS/_index.md; fixes: none

### Phase 2: MIGRATION.md — drop dead pointer, fix tier story, date the numbers

- [x] **2.1** Remove the dead `PLANS/PLAN-BT-74.md` pointer sentence
    (MIGRATION.md:326), keeping the `installer/provider-presets.json` pointer.
    — **Why:** `PLANS/` starts at PLAN-506; the referenced file does not
    exist.
    — **Done when:** `rg 'PLAN-BT-74' MIGRATION.md` → 0 hits.
    — **Consumers affected:** none (doc readers).
    — **Done:** dropped the sentence, kept the provider-presets pointer; verified zero hits; files: MIGRATION.md; fixes: none

- [x] **2.2** Fix both tier mentions (:52 "4 tiers", :143 "5 categories") to
    the registry truth: `reasoning`/`long-context`/`fast`/`docs`/`vision`
    plus the `primary` slot (`installer/agent-tiers.json` distinct values).
    — **Why:** internal inconsistency (4 vs 5) and drift vs the actual
    6-category resolution.
    — **Done when:** both mentions enumerate the five tier names and the
    primary slot.
    — **Consumers affected:** doc readers; AGENTS.md §Subagent Model Tiering
    is the canonical table and stays untouched.
    — **Done:** ":52" now reads "5 tiers + primary slot" naming long-context; ":143" now reads "6 categories" naming long-context; files: MIGRATION.md; fixes: none

- [x] **2.3** Qualify the lean numbers (MIGRATION.md:19, "45 … instead of
    105") as at-v2.0.0 values with a pointer to `deploy/skill-profiles.json`
    (current lean = 68).
    — **Why:** house convention — dated narratives keep period-true numbers
    but must not read as current state.
    — **Done when:** the sentence carries an explicit as-of qualifier.
    — **Consumers affected:** none.
    — **Done:** reworded to "at v2.0.0 the primary session saw 45 … (current profile: deploy/skill-profiles.json, lean = 68 as of 2026-09-28)"; files: MIGRATION.md; fixes: none

### Phase 3: AGENTS.md — remove dead/duplicated behavior, precision fixes

- [x] **3.1** Delete the dangling `deploy/.AGENTS.md §Secret Hygiene` pointer
    sentence in §Secret Masking (AGENTS.md:26).
    — **Why:** the section was deleted from `deploy/.AGENTS.md` in e278d2d;
    a pointer to a nonexistent section is a false instruction.
    — **Done when:** `rg 'Secret Hygiene' AGENTS.md` → 0 hits.
    — **Consumers affected:** session prompt consumers only.
    — **Done:** dropped the pointer sentence, kept the security-audit-skill sentence; also fixed PRE-EXISTING red tests/test_docling_skill.bats test 15 (pinned the deleted "4-tier routing in repo-root" string, absent from deploy/.AGENTS.md since e278d2d on origin/main) — repointed as a negative no-duplicate guard per the sentinel-grep convention; files: AGENTS.md, tests/test_docling_skill.bats; fixes: docling suite 18/19 → 19/19

- [x] **3.2** Delete §Extract-then-Delegate (AGENTS.md § of that name).
    — **Why:** generic behavior whose user-level home (§Delegation in
    `deploy/.AGENTS.md`) was deliberately removed; the repo file keeps
    conventions only.
    — **Done when:** `rg 'Extract-then-Delegate' AGENTS.md` → 0 hits.
    — **Consumers affected:** none — delegation routing is carried by agent
    descriptions and skills.
    — **Done:** removed heading + body; verified zero hits in AGENTS.md; files: AGENTS.md; fixes: none

- [x] **3.3** Compress §Repository Purpose to ≤5 lines + README pointer.
    — **Why:** duplicates README install/target docs against the file's own
    header rule ("Do not duplicate here").
    — **Done when:** the section is ≤5 lines and names `README.md` as the
    usage-doc home.
    — **Consumers affected:** session prompt size (reduction); README
    untouched.
    — **Done:** compressed ~15-line target enumeration to 2 paragraphs (4 content lines) naming README.md + issue #304, and installer/dependency-map.json; files: AGENTS.md; fixes: none

- [x] **3.4** Shrink §Project Learnings to the template note + pointer to
    user-level Memory Hygiene.
    — **Why:** duplicates `deploy/.AGENTS.md` §Memory Hygiene behavior at
    repo level.
    — **Done when:** the section is ≤3 lines with no Recall/Capture
    duplication.
    — **Consumers affected:** none.
    — **Done:** reduced to one body line (template note + §Memory Hygiene pointer), dropped the stale memory-plugin watch text; files: AGENTS.md; fixes: none

- [x] **3.5** Precision fixes: `registry.json` → `installer/registry.json`
    and `dependency-map.json` → `installer/dependency-map.json` where
    referenced bare; attribute the explore/general model pins to
    `deploy/setup.sh` injection into the deployed `opencode.json`.
    — **Why:** bare references resolve to nonexistent root paths; the pins
    live at `deploy/setup.sh:728-743`, not root `opencode.json`.
    — **Done when:** no bare `commit registry.json` phrasing remains; the
    tier paragraph names `deploy/setup.sh`.
    — **Consumers affected:** doc readers following instructions.
    — **Done:** installer/registry.json + installer/dependency-map.json (×2 sites) path fixes; explore/general pins attributed to deploy/setup.sh:728-743 writing the deployed opencode.json; files: AGENTS.md; fixes: none

### Phase 4: Gates + exit

- [ ] **4.1** Run the four bats suites (`bats` on PATH) plus the rg zero-hit
    gates from the ACs; fix any failure; tick the PLAN ACs; append the
    `GATE <short-sha> tier=full` memo line for the final SHA.
    — **Why:** the docs are pinned by tests; the ticket exit gate is
    full-tier per `verification-loop-skill`.
    — **Done when:** all suites green, all ACs ticked, memo line present in
    the PLAN trace.
    — **Consumers affected:** Step 10a PR citation requires the memo.

## Technical Notes

- Doc-only diff: no code, no frontmatter → no `installer/registry.json`
  regen, no lockfile change.
- MIGRATION.md is kept, not deleted: live `--migrate` machinery
  (`deploy/setup.sh:128,608,923`) and 8 referrers.
- `deploy/.AGENTS.md` is untouched by this ticket (slimmed by the maintainer
  in e278d2d).

## Dependencies

None. No `blocked-by:` refs.

## Risks & Mitigation

- AGENTS.md pin breakage (`test_docling_skill.bats:106` greps the §Office
  Document Extraction Routing heading): section untouched; heading stays
  verbatim.
- MIGRATION.md pin breakage (`no_doc_teaches_dead_permission_keys`): no
  permission-key patterns are introduced.
- Out-of-band deletion in 1.1 (untracked + ignored file in the main
  checkout): the merged content rides `feat/636` first; the deletion removes
  a file no git object references.
