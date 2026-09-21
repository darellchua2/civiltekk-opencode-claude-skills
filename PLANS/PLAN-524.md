# PLAN: Dedup pipeline gate ownership + scoped bash for code review

**Branch**: feat/524
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/524
**Base**: main

## Acceptance Criteria
- [ ] code-review-subagent frontmatter: shell `*` deny precedes read-only git allows; edit permission unchanged (deny)
- [ ] pr-workflow-subagent closing gates line scoped to standalone path
- [ ] /run-plan gate claim names tiered gating accurately in BOTH `opencode_app/opencode.json` (command description) and `README.md` Git/Workflow cell
- [ ] registry.json regenerated after the 1.1 frontmatter edit; `node installer/build-registry.mjs --check` exits 0 (expected diff: `generatedAt` only — bash rules don't feed registry content; commit-or-skip)
- [ ] Gate green per verification-loop-skill contract (tiered)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `agents/code-review-subagent.md` | — | `deploy/setup.sh` (copies to `~/.config/opencode`), `installer/build-registry.mjs` → `registry.json`, `opencode_app` Docker image, `tests/agents_target.bats` (fixture), `tests/test_reviewer_no_writes.bats` (structure-pinning guard), skill prose in `plan-execution-skill`/`worktree-pipeline-skill` | low-med (deployed reviewer permission behavior) |
| `agents/pr-workflow-subagent.md` | — | same deploy/install/docker chain + registry | low (prose scoping; supersession already governs) |
| `opencode_app/opencode.json` | — | `docker-compose` build (standalone web endpoint UX); `docker-compose.yml:29-31` healthcheck comment anchors to its `/goal` mention | low (description string) |
| `README.md` (Git/Workflow cell :624) | — | repo front-door docs — restates the `/run-plan` gate claim | low (prose) |
| `skills/plan-execution-skill/SKILL.md`, `skills/worktree-pipeline-skill/SKILL.md` | 1.1 | skill runtime prompts (orchestrator behavior) | low (prose truthfulness) |
| `installer/registry.json` | 1.1, 2.1 | `installer/init.mjs` (`npx add`), docs counts | low (generated — regenerate, never hand-edit) |

## Implementation Phases

### Phase 1: Scoped bash for the reviewer
- [ ] **1.1** Add scoped shell allowlist to `agents/code-review-subagent.md` frontmatter — the existing `shell: '*': deny` rule stays, and allow rules for `git diff*`, `git log*`, `git show*`, `git blame*`, `git status*` are appended after it (last matching rule wins); add one body line noting the agent may verify findings with read-only git forensics; `edit: deny` untouched.
    — **Why:** the reviewer currently delegates trivial verification to `general`; scoped bash removes that hop without opening mutation — edit stays denied.
    — **Done when:** frontmatter shows the shell deny-* rule preceding exactly the five read-only git allows; edit rule unchanged; body notes the allowlist as read-intent forensics (not a security boundary — prefix allows can match chained commands; `edit: deny` is the boundary).
    — **Consumers affected:** `deploy/setup.sh`, registry builder, Docker image, `tests/agents_target.bats` fixture — all re-verify via the gate.
- [ ] **1.2** Fix stale `bash: deny` claims in `skills/plan-execution-skill/SKILL.md` (delegate matrix row) and `skills/worktree-pipeline-skill/SKILL.md` (Step 9 opening).
    — **Why:** prose asserting blanket `bash: deny` becomes factually wrong after 1.1 — the same drift-bait class this ticket removes; Step 9's precomputed-diff mandate stays (it is a guarantee, not a permission consequence).
    — **Done when:** no skill prose claims the reviewer has blanket bash deny; Step 9 still requires orchestrator-computed diffs.
    — **Consumers affected:** skill runtime prompts.

### Phase 2: Standalone-scoped gates line
- [ ] **2.1** Scope `agents/pr-workflow-subagent.md`'s closing "Always ensure all quality gates pass before creating PR" to the standalone path.
    — **Why:** the closing line conflicts with pipeline mode's skip of steps 2/2.5/3/4; the supersession note resolves it, but the restatement is drift bait.
    — **Done when:** the line names the standalone path and points pipeline mode at the Pipeline mode section / CI merge gate.
    — **Consumers affected:** deploy/install/docker chain (prose only).

### Phase 3: Command description + registry regen
- [ ] **3.1** Fix the `/run-plan` description in `opencode_app/opencode.json` to name tiered gating (light per phase — scoped lint + typecheck + affected tests; full on anchors and the exit gate), preserving the `/goal` sentence (docker-compose.yml:29-31's healthcheck comment anchors to it), and update the matching restatement in `README.md`'s Git/Workflow category cell (README.md:624) to the same tiered phrasing.
    — **Why:** current text promises lint+build+test+e2e per phase — an over-promise against verification-loop-skill §Tiered gating; README.md:624 restates the identical claim, so one source fixed and not the other leaves AC3 half-true — same drift-bait class.
    — **Done when:** description names light/full tiers, keeps the `/goal` sentence, file still parses as valid JSON; README Git/Workflow cell names light/full tiers for `/run-plan` (no lint+build+test+e2e-per-phase claim remains in either file).
    — **Consumers affected:** Docker endpoint command UX; repo front-door docs; docker-compose healthcheck comment anchor.
- [ ] **3.2** Regenerate `installer/registry.json` via `node installer/build-registry.mjs` (frontmatter-contract mandate — 1.1 touched agent frontmatter). Expect a `generatedAt`-only diff: bash-action rules and body prose feed no registry edges or entries (build-registry.mjs:180-182, :236-242). Commit or exclude the churn line — CI-neutral (release.yml drift guard normalizes `generatedAt`).
    — **Why:** AGENTS.md §Skill / Agent Frontmatter Contract mandates regen after any frontmatter change (1.1); per LEARNINGS/solutions/build-registry-plain-run-churns-generatedat.md the gate is the `--check` form, not a diff-content expectation.
    — **Done when:** `node installer/build-registry.mjs --check` exits 0; no hand-edits; any diff vs HEAD is the `generatedAt` line only.
    — **Consumers affected:** installer `npx add`, docs counts.
- [ ] **3.3** Verify the final pushed SHA carries a green `tier=full` GATE memo line in this PLAN's trace block.
    — **Why:** AC5 evidence — and the citation Step 10 hands to pr-workflow-subagent (a light-tier line never satisfies it).
    — **Done when:** `grep "GATE .* tier=full"` in this file's trace block shows HEAD's short SHA.
    — **Consumers affected:** Step 10 PR handoff.

## Technical Notes
- Gate discovery (formal at execution): no `package.json` scripts, no Makefile, no pyproject → contract substitutes: JSON validity check for `opencode_app/opencode.json` (`node -e require`), `node installer/build-registry.mjs` (repo's build artifact), bats for unit (`tests/agents_target.bats` affected; full `bats tests/` at exit gate). E2E: no Playwright → n.a.
- Tiering: every phase touches a Consumer-Map node with cross-module consumers → full tier per §Tiered gating; exit gate full unconditionally.
- Permission semantics: opencode v2 last-matching-rule-wins — deny `*` first, allows after; verified against docs (their example review agent uses `edit: deny`).
- kimi/claude install targets drop the five scoped shell rules with a documented "no equivalent — dropped" warning (`init.mjs:959-963`); Bash stays denied there via the `*` deny — expected, not a failure.
- `.codegraph/` not ignored on this branch → no worktree index; rg/grep fallback throughout.

## Dependencies
None.

## Risks & Mitigation
- Permission rule order inverted → allows shadowed by deny-*: mitigated by appending allows after the deny rule and re-reading the file post-edit.
- Hand-edited registry.json drift → never hand-edit; regen via `build-registry.mjs` only.
- bats absent on executor → verified present (`command -v bats`).

## Trace

_(gate memos appended here by /run-plan --gate)_
