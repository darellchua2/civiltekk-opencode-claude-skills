# PLAN: Promotion PRs must use merge commits, never squash

**Branch**: feat/519
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/519
**Base**: main

> Rev 2 — amended after architecture review (BLOCK 1: governance skill
> contradiction; WARN 1: head-class detection; WARN 2: `--check` registry gate;
> WARN 3: positive pins) and requirements relay (4/4 confirmed, 2 amended).
> Deviations from the ticket's original wording are recorded in the ticket body
> and mirrored here: head-class detection; scope expansion to
> `semantic-release-convention-skill`.

## Acceptance Criteria
- [x] Phase 1 branches on head-branch class: long-lived head ⇒ `--merge`; all other heads ⇒ `--squash`, regardless of base
- [x] Step 3b invokes the same head-class classifier (`fix/ci-*` head ⇒ squash) — the hardcoded `--squash` is removed
- [x] One-line rationale documented in SKILL.md
- [x] `semantic-release-convention-skill` squash-all mandates (:18, :126, :196-214, :388, :401) aligned to the two-tier doctrine; settings recommendation flipped to "Allow merge commits: Yes"
- [x] Explicit-user-instruction escape hatch documented: bidirectional, SHA-divergence warning required for forced squash on promotions, never applied autonomously
- [x] `node installer/build-registry.mjs --check` exits 0 (no drift); commit `installer/registry.json` only if drift is detected
- [x] Scoped bats green (`test_default_behavior`, `test_skill_isolation`, `test_autoresearch_protocol`); full `bats tests/` green at the exit gate
- [x] Redeployed via `./deploy/setup.sh`; deployed copies carry the head-class rule

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/pr-merge-workflow-skill/SKILL.md` (body) | — | primary sessions ("merge the PR"), `pr-workflow-subagent` (merge phase), `worktree-pipeline-skill` Step 10 (merge decision routed through pr-workflow-subagent) | med — behavioral prose; wrong merge method on promotion merges recreates the betekk-keycloak incident |
| `skills/semantic-release-convention-skill/SKILL.md` (body) | 1.1's head-class definition + long-lived list (copied verbatim — single source, then copied) | repos following its governance doctrine; semantic-release changelog flow (feature/fix squash preserved, so conventional-commit-per-PR guarantee holds) | med — five squash-all locations must move together or the file self-contradicts |
| `tests/test_default_behavior.bats`, `tests/test_autoresearch_protocol.bats` | pin `pr-merge-workflow-skill` structure (Iteration Protocol preamble only — grep-verified, no merge-command assertions) | CI | low — body edits away from the preamble cannot break them |
| `installer/registry.json` (generated) | both SKILL.md frontmatters final | installer (`init.mjs` / `npx … add`) | low — body-only edits ⇒ zero drift expected; `--check` proves it |

## Implementation Phases

### Phase 1: Head-class merge-method policy
- [x] **1.1** Rewrite Phase 1 step 3 of `skills/pr-merge-workflow-skill/SKILL.md`: classify by HEAD branch before merging — long-lived heads (`main`, `master`, `dev`, `develop`, `production`, `prod`, `uat`, `staging`, `stage`, `preprod`, `pre-dev`, `qa`, `test`, `integration`, `release/*`) merge with `gh pr merge <number> --merge --delete-branch=false` only; all other heads (feature/*, fix/*, hotfix/*, chore/*) keep `gh pr merge <number> --squash --delete-branch=false` regardless of base; add the one-line rationale (squash duplicates content under new SHAs when the head branch survives the merge, so promotion branches never converge — betekk-keycloak PRs #55/#72) and the escape hatch (explicit user instruction for that specific PR overrides in either direction; forced squash on a promotion requires a prior SHA-divergence warning; the autonomous loop in Step 3b never uses it)
    — **Why:** root cause of the verified incident: the unconditional squash default flattened dev→uat promotions (head=dev), leaving uat 9 commits ahead with orphan artifacts; head-class is the true discriminator because the harm requires the head branch to survive the merge
    — **Done when:** `grep -c 'long-lived' skills/pr-merge-workflow-skill/SKILL.md` ≥ 2 (classifier + rationale), `grep -c 'merge using squash (default)'` = 0, and `grep -c 'SHA diverg'` ≥ 1 (hatch warning present — positive pin, deletion test fails)
    — **Consumers affected:** pr-workflow-subagent merge phase; primary sessions running PR merges; worktree-pipeline Step 10
    — **Done:** Phase 1 step 3 rewritten to head-class classifier + rationale + escape hatch; files: skills/pr-merge-workflow-skill/SKILL.md; fixes: none
- [x] **1.2** Replace the Step 3b hardcoded merge command (`gh pr merge <number> --squash --delete-branch`) with the same head-class classifier — `fix/ci-*` heads resolve to squash, so autonomous CI-fix behavior is unchanged; add a line that the escape hatch never applies inside this autonomous loop
    — **Why:** the auto-fix path would otherwise reintroduce the squash default through the back door on promotion merges, and the classifier must be single-sourced
    — **Done when:** the Step 3b block contains a `--merge` reference via the classifier (positive pin: `grep -c 'head-class\|head branch' ` over the Step 3b section ≥ 1) and no bare unconditional `--squash --delete-branch` remains outside the feature-head branch of the rule
    — **Consumers affected:** same as 1.1
    — **Done:** Step 3b merge command replaced with head-class classifier reference + no-autonomous-hatch line; files: skills/pr-merge-workflow-skill/SKILL.md; fixes: none
- [x] **1.3** Align `skills/semantic-release-convention-skill/SKILL.md` to the same two-tier doctrine at all five squash-all locations (:18 merge-strategy line, :126, :196-214 §4 including flipping the repo-settings recommendation to "Allow merge commits: **Yes** (required for promotions)", :388, :401), reusing 1.1's head-class definition and long-lived list verbatim; feature/fix squash-merge stays the doctrine for conventional-commit-per-PR changelog integrity
    — **Why:** BLOCK 1 — it is a self-declared governance skill ("other skills and agents MUST follow"); left as-is it contradicts the new rule and its "Allow merge commits: No" recommendation would defeat the fix at the GitHub-settings level
    — **Done when:** `grep -n 'All PRs are merged using' skills/semantic-release-convention-skill/SKILL.md` returns 0 matches and `grep -c 'long-lived' skills/semantic-release-convention-skill/SKILL.md` ≥ 1 and `grep -c 'Allow merge commits' skills/semantic-release-convention-skill/SKILL.md` ≥ 1
    — **Consumers affected:** repos applying the governance skill's settings checklist; semantic-release changelog flow (unchanged for feature/fix heads)
    — **Done:** all five squash-all locations aligned to two-tier doctrine + settings flipped to "Allow merge commits: Yes"; files: skills/semantic-release-convention-skill/SKILL.md; fixes: none

### Phase 2: Registry drift check + verification gates + redeploy
- [x] **2.1** Run `node installer/build-registry.mjs --check`; on non-zero exit, inspect the drift, fix the frontmatter regression, and commit `installer/registry.json`
    — **Why:** `--check` normalizes `generatedAt` while a plain run churns it (documented anti-pattern, recurrence #4); body-only edits must yield zero drift, which doubles as proof both frontmatters are untouched
    — **Done when:** `node installer/build-registry.mjs --check` exits 0 and `git status --porcelain installer/registry.json` is empty
    — **Consumers affected:** installer `init.mjs` / `npx … add` flow
    — **Done:** `--check` exit 0 "registry OK (agents=34, skills=146, no drift)", porcelain clean; files: none changed; fixes: none
- [x] **2.2** Run scoped gate: `bats tests/test_default_behavior.bats tests/test_skill_isolation.bats tests/test_autoresearch_protocol.bats`
    — **Why:** these three suites pin this skill's Iteration Protocol preamble, vendored-copy fidelity, and opt-in metadata — the guards closest to the edited files
    — **Done when:** exit 0
    — **Consumers affected:** CI
    — **Done:** scoped suites exit 0 (174 ok, re-run post-Phase-1); files: none; fixes: none
- [x] **2.3** Run full exit gate: `bats tests/`
    — **Why:** the ticket exit gate must be tier=full per verification-loop-skill; the final pushed SHA must carry a green full-tier memo
    — **Done when:** exit 0 across all 39 suites
    — **Consumers affected:** CI; Step 9/10 citations
- [x] **2.4** Redeploy: `./deploy/setup.sh` and verify both deployed copies carry the new doctrine
    — **Why:** deployed `~/.config/opencode/` copies are what sessions actually load; AC is not met until they carry the fix
    — **Done when:** `grep -c 'long-lived' ~/.config/opencode/skills/pr-merge-workflow-skill/SKILL.md` ≥ 1 and `grep -c 'Allow merge commits' ~/.config/opencode/skills/semantic-release-convention-skill/SKILL.md` ≥ 1
    — **Consumers affected:** all future sessions using either skill
    — **Done:** `./deploy/setup.sh -y` completed (backup ~/.opencode-backup-20260921_224126); deployed greps: pr-merge long-lived=3, semrel Allow merge commits=1; files: ~/.config/opencode/skills/{pr-merge-workflow,semantic-release-convention}-skill/SKILL.md; fixes: none

## Technical Notes
- Incident evidence (verified 2026-09-21): betekk-keycloak dev→uat PRs #55 and #72 squash-merged (head=dev); `compare/dev...uat` shows uat 9 commits ahead, ~5 orphan artifacts; workarounds: surgical promotion (PLAN-DA-2457), reconciliation PR #69, promotion train (PR #72/#76).
- Head-class rationale (requirements relay GAP 1, confirmed): SHA divergence requires the head branch to survive the merge; a feature head dies post-merge, so squash is safe even into main.
- Companion ticket: JIRA DA-2830 (betekk-keycloak repo-side AGENTS.md policy + uat→dev backflow; separate repo/pipeline run).
- `worktree-pipeline-skill` and `agents/pr-workflow-subagent.md` own no merge-method default (verified); `repo-ops-specialist-subagent` merges generically — no edit.

## Gate Trace

GATE 8ed004b tier=light lint=- typecheck=- build=- unit=t e2e=-
<!-- scoped: test_default_behavior + test_skill_isolation + test_autoresearch_protocol = 174 ok, exit 0; lint/typecheck/build n.a. (markdown-only phase, none configured); done-when greps verified for 1.1/1.2/1.3 -->
GATE bb3e7c1 tier=full lint=- typecheck=- build=- unit=t e2e=- (code tree = 8ed004b; full bats tests/ = 529 ok exit 0; build-registry --check no drift; deployed-copy greps green)

## Dependencies
None external. Companion DA-2830 runs in a separate repo and does not block this change.

## Risks & Mitigation
- Two skills drifting apart again → 1.3 copies 1.1's definition verbatim; both done-whens grep the same `long-lived` marker.
- Governance rewrite breaking semantic-release changelog expectations → 1.3 preserves feature/fix squash-merge explicitly; scoped gate 2.2 + full gate 2.3 confirm no pinned structure breaks.
- Redeploy overwriting unrelated user-space state → `./deploy/setup.sh` is the sanctioned idempotent path (house rule: never edit deployed copies).
- Escape hatch re-opening the incident if loosely worded → explicit per-PR instruction only, mandatory SHA-divergence warning, never autonomous (1.1/1.2 wording).
GATE cbca081 tier=full lint=- typecheck=- build=- unit=t e2e=- (review-fix tree; full bats 529 ok exit 0; --check no drift)
