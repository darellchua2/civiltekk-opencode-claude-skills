# PLAN: Promotion PRs must use merge commits, never squash

**Branch**: feat/519
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/519
**Base**: main

## Acceptance Criteria
- [ ] Phase 1 merge step branches on base-branch class; promotion bases use `--merge`, never `--squash`
- [ ] CI-fix path (Step 3b) follows the same base-branch rule
- [ ] One-line rationale documented in SKILL.md
- [ ] `node installer/build-registry.mjs` run and `registry.json` committed with the change
- [ ] Redeployed via `./deploy/setup.sh` so `~/.config/opencode/` receives the fix

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/pr-merge-workflow-skill/SKILL.md` (body) | — | primary sessions ("merge the PR" / "pr merge to [branch]"), `pr-workflow-subagent` (merge phase), `worktree-pipeline-skill` Step 10 (merge decision routed through pr-workflow-subagent) | med — behavioral prose; wrong merge method on promotion branches recreates the betekk-keycloak incident |
| `registry.json` (generated) | SKILL.md frontmatter must be final | installer (`init.mjs` / `npx … add`) reads it | low — body-only edits should produce no diff; a diff means accidental frontmatter damage |

## Implementation Phases

### Phase 1: Base-branch merge-method policy in SKILL.md
- [ ] **1.1** Rewrite Phase 1 step 3 of `skills/pr-merge-workflow-skill/SKILL.md`: classify the PR base before merging — promotion/long-lived bases (`uat`, `main`/`master`, `prod`, `staging`, `release/*`) merge with `gh pr merge <number> --merge --delete-branch=false` only and squash is forbidden; feature/dev bases keep `--squash` as default; include the one-line rationale (squash duplicates content under new SHAs so promotion branches never converge — betekk-keycloak PRs #55/#72)
    — **Why:** root cause of the verified incident: the unconditional squash default flattened dev→uat promotions, leaving uat 9 commits ahead with orphan artifacts
    — **Done when:** `grep -n 'merge using squash (default)' skills/pr-merge-workflow-skill/SKILL.md` finds nothing and `grep -n 'release/\*' skills/pr-merge-workflow-skill/SKILL.md` finds the base-class rule
    — **Consumers affected:** pr-workflow-subagent merge phase; primary sessions running PR merges; worktree-pipeline Step 10
- [ ] **1.2** Rewrite the Step 3b CI-fix merge command (currently unconditional `--squash --delete-branch`) to apply the same base-branch rule (promotion base → `--merge`; feature/dev base → `--squash`)
    — **Why:** the auto-fix path would otherwise reintroduce the squash default through the back door on promotion branches
    — **Done when:** `grep -n 'squash --delete-branch$' skills/pr-merge-workflow-skill/SKILL.md` returns no unconditional match outside the feature/dev branch of the rule
    — **Consumers affected:** same as 1.1

### Phase 2: Registry sync + verification gates
- [ ] **2.1** Run `node installer/build-registry.mjs`; commit `registry.json` only if it changed
    — **Why:** frontmatter contract requires registry sync; body-only edits should yield zero diff, which doubles as proof the frontmatter was not touched
    — **Done when:** command exits 0 and `git status --porcelain registry.json` is empty after (committed or unchanged)
    — **Consumers affected:** installer `init.mjs` / `npx … add` flow
- [ ] **2.2** Run scoped gate: `bats tests/test_default_behavior.bats tests/test_skill_isolation.bats`
    — **Why:** these suites assert this skill's Iteration Protocol preamble and copy fidelity — the two guards closest to the edited file
    — **Done when:** exit 0
    — **Consumers affected:** CI
- [ ] **2.3** Run full exit gate: `bats tests/`
    — **Why:** ticket exit gate must be tier=full per verification-loop-skill; the final pushed SHA must carry a green full-tier memo
    — **Done when:** exit 0 across all 39 suites
    — **Consumers affected:** CI; Step 9/10 citations
- [ ] **2.4** Redeploy: `./deploy/setup.sh` and verify the new rule landed in the deployed copy
    — **Why:** deployed `~/.config/opencode/` copies are what sessions actually load; AC is not met until they carry the fix
    — **Done when:** `grep -c 'release/\*' ~/.config/opencode/skills/pr-merge-workflow-skill/SKILL.md` ≥ 1
    — **Consumers affected:** all future sessions using the merge skill

## Technical Notes
- Incident evidence (verified 2026-09-21): betekk-keycloak dev→uat PRs #55 and #72 squash-merged; `compare/dev...uat` shows uat 9 commits ahead, ~5 orphan artifacts; workarounds: surgical promotion (PLAN-DA-2457), reconciliation PR #69, promotion train (PR #72/#76).
- Companion ticket: JIRA DA-2830 (repo-side policy + uat→dev backflow in betekk-keycloak, separate repo/pipeline run).
- `worktree-pipeline-skill` and `agents/pr-workflow-subagent.md` contain no merge-method defaults of their own (grep-verified) — no edits there.

## Dependencies
None external. Companion DA-2830 runs in a separate repo and does not block this change.

## Risks & Mitigation
- Skill prose drift breaking bats guards → scoped gate 2.2 catches immediately; guards assert only the Iteration Protocol preamble, not merge commands (grep-verified before authoring).
- Redeploy overwrites unrelated user-space state → `./deploy/setup.sh` is the sanctioned idempotent path (house rule: never edit deployed copies).
- Registry accidentally embedding body text → 2.1's zero-diff expectation surfaces it at once.
