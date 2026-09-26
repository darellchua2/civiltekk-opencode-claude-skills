# PLAN: Sweep residual stale pointers surfaced by the #506 review

**Branch**: feat/517
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/517
**Base**: main

## Acceptance Criteria
- [ ] Items 1-4 either cite live paths or carry dated historical notes
- [ ] Item 5 References match the file's own header numbers
- [ ] Item 6 comment no longer names a removed function
- [ ] `grep -rn "plan-automation-loop" LEARNINGS/ opencode_app/opencode.json` returns only dated historical mentions
- [ ] Full `bats tests/` + `node installer/build-registry.mjs --check` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` (skill description prose, :629) | — | opencode runtime skill listing (user-visible), tests snapshotting config | low |
| `deploy/packs/pack-markitdown.json` ($comment) | — | docs readers; merge-packs ignores $comment (reader strips `$comment` lines) | low |
| `LEARNINGS/_index.md` (:1012 entry) | — | auto-inject manifest readers; tracked in git | low |
| `LEARNINGS/*.md` bodies (items 1, 2, 4-body, 5) — **gitignored**, live only in the main checkout | — | session memory recall (auto-inject); cannot ride a PR | low |
| Issue #517 resolution comment | all fixes | issue readers | low |

## Implementation Phases

### Phase 1: Tracked-file fixes (PR-carried)
- [x] **1.1** `opencode_app/opencode.json:629` — drop the stale "; Docker awaits #387" clause from the plan-execution skill description (#387 shipped: v2 binary + authenticated healthcheck); keep the /goal recommendation itself
    — **Why:** User-visible config prose asserting a pending fix for a resolved issue misinforms harness-choice decisions
    — **Done when:** `grep -n "Docker awaits" opencode_app/opencode.json` returns nothing; the /goal path wording remains
    — **Consumers affected:** opencode runtime skill descriptions; CI config-parsing tests
    — **Done:** Docker-await #387 clause deleted from plan-execution description; /goal wording kept; files: opencode_app/opencode.json; fixes: none
- [x] **1.2** `deploy/packs/pack-markitdown.json` $comment — remove the removed PowerShell fn name `Install-MarkitdownMcp`, keep `install_markitdown_mcp` (the live bash/npm install fn)
    — **Why:** The comment names a function deleted from setup.ps1 — a stale pointer genus #506 was sweep-killing
    — **Done when:** `grep -c "Install-MarkitdownMcp" deploy/packs/pack-markitdown.json` = 0
    — **Consumers affected:** docs readers only (merge-packs strips `$comment`)
    — **Done:** Install-MarkitdownMcp removed from $comment (live fn name kept); files: deploy/packs/pack-markitdown.json; fixes: none
- [x] **1.3** `LEARNINGS/_index.md:1012` — reword the phase-commit-ci-gate-ordering summary to name `plan-execution-skill` with the dated rename note "(then plan-automation-loop-skill, renamed #408)"
    — **Why:** The tracked index entry is the PR-visible half of item 4; the index is the auto-inject surface other sessions read
    — **Done when:** `_index.md` carries the dated rename note; summary still describes the same learning
    — **Consumers affected:** session memory recall via the manifest
    — **Done:** index entry reworded to plan-execution-skill with dated rename note; files: LEARNINGS/_index.md; fixes: none

### Phase 2: LEARNINGS body fixes (gitignored — applied in the main checkout, documented here)
- [x] **2.1** In `/home/silentx/VSCODE/civiltekk-opencode-claude-skills/LEARNINGS/` (bodies are per-checkout, gitignored — the PR cannot carry them; this step edits the only live copy): item 1 — `anti-patterns/concurrent-execute-before-writers-event-input.md:12` add dated repoint note (v1 `plugins/vibeguard.ts:490-496` → v2 `plugins/opencode-vibeguard-v2.ts:504-508`); item 2 — `decisions/adaptive-review-requirements-relay.md:17` hard-deps name → `plan-execution-skill` with "(then plan-automation-loop-skill, merged #408)"; item 4-body — `patterns/phase-commit-ci-gate-ordering.md:3` same rename treatment as 1.3; item 5 — `decisions/skill-permission-allowlist.md:20-21` References aligned to the file's own numbers (106 allows = 105 deployable + 1 app-scoped; lean 70 post-#481)
    — **Why:** These four are the issue's items 1/2/4/5; gitignored bodies live only here, so the local checkout IS the canonical copy
    — **Done when:** All four edits applied; each carries a dated note or a live path per the #506 `Update <date> (#<ref>)` pattern
    — **Consumers affected:** session memory recall; issue #517 resolution completeness
    — **Done:** 4 body edits applied in main checkout: vibeguard anchor dated-repointed to v2 :504-508, relay hard-deps renamed with #408 note, phase-commit context renamed, allowlist References aligned (106/70); files: 4 LEARNINGS bodies (gitignored, local-only); fixes: none
- [x] **2.2** Item 7 decision — the `_index.md` generator is plugin-side (no `_index` generator exists in `plugins/` in-repo; grep verified): DEFER the ellipsis-marker idea to the plugin, record the decision in the resolution comment
    — **Why:** The issue asks for a decision, not necessarily a code change; the generator is not repo code, so an in-repo fix is impossible
    — **Done when:** Decision + rationale recorded in the issue resolution comment
    — **Consumers affected:** issue #517 readers; future plugin work
    — **Done:** decision: DEFER to plugin — no _index generator exists in-repo (grep verified); rationale recorded in resolution comment; files: none (decision); fixes: none

### Phase 3: Verification + resolution
- [x] **3.1** Census: `grep -rn "plan-automation-loop" LEARNINGS/ opencode_app/opencode.json` (LEARNINGS against the main checkout where bodies live, opencode.json in the worktree) — every remaining match must be a dated historical mention
    — **Why:** The AC's definition of done for items 1-4
    — **Done when:** Zero live-tense matches; all remaining matches carry a date or issue-ref qualifying them as historical
    — **Consumers affected:** ticket AC 4
    — **Done:** census clean: opencode.json 0 matches, Install-MarkitdownMcp 0, LEARNINGS census only dated-historical (caught + fixed a diverged local _index.md the tracked fix alone missed); files: main-checkout LEARNINGS/_index.md; fixes: none
- [x] **3.2** `node installer/build-registry.mjs --check` + full `bats tests/` in the worktree (ticket exit gate, tier=full)
    — **Why:** AC 5; the opencode.json prose edit is config content the suite parses
    — **Done when:** --check exits 0; bats fully green
    — **Consumers affected:** CI; ticket AC 5
    — **Done:** build-registry --check green (no drift); full bats 612/612 exit 0; files: none (verification); fixes: none
- [x] **3.3** Resolution comment on issue #517: what the PR fixed (tracked files), what was fixed locally and why (gitignored bodies + the gitignore design), item 7 deferral
    — **Why:** The split between PR-carried and local-only fixes is non-obvious; the issue must explain where each fix landed
    — **Done when:** Comment posted; PR `Closes #517` auto-closes on merge
    — **Consumers affected:** issue readers; future archaeologists of the LEARNINGS layout
    — **Done:** resolution comment posted (PR/local split, item-7 deferral, census catch); files: none; fixes: none

## Gate trace

GATE b3ca203 tier=full lint=n.a. typecheck=t build=t unit=t e2e=n.a. — ticket exit gate: build-registry --check green (no drift); full bats 612/612 exit 0

## Technical Notes
- `LEARNINGS/**/*.md` is gitignored (.gitignore:37) by design — per-checkout session memory; `_index.md` is the tracked surface. This split is why item 4 has two halves (body 2.1, index 1.3).
- The census intentionally leaves already-dated historical mentions in `heading-rename-syncs-quoted-pointers.md:7` (Evidence 2026-09-17, #383), `doc-claims-match-plugin-defaults.md:3,:11` (#382; path updated 2026-09-21 #506), `profile-membership-breaks-count-arithmetic.md:5` (#408 planned) — they satisfy "dated historical" as-is.
- The `Docker awaits #387` clause is deleted, not replaced — no new Docker-claim is invented; the /goal recommendation stands on its own.

## Dependencies
- None external; single ticket.

## Risks & Mitigation
- **Editing the user's main checkout** (2.1): file edits only, no git operations — the pipeline's main-checkout protections (no branch ops, fetch-only) are untouched.
- **Config prose regression**: 1.1 is deletion-only inside a description string; full bats re-parses the config (3.2).
- **Index/local drift**: the plugin may locally regenerate `_index.md`; the committed version is authoritative for git — body fixes (2.1) are where the durable memory lives.
