# PLAN: Re-add goal mode via @prevalentware/opencode-goal-plugin (OpenCode v2)

**Branch**: feat/382
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/382
**Base**: main

## Acceptance Criteria

- [ ] `opencode` boots with zero plugin boot warnings
- [ ] `plugins` array carries `@prevalentware/opencode-goal-plugin` (bare name, no exact pin)
- [ ] No `commands.goal` block added (v2 plugin self-registers `/goal`, `/pause_goal`, `/resume_goal`)
- [ ] Docs consistent: goal-plugin removed from README v2 watch-list; no stale "removed pending v2" references anywhere
- [ ] `plan-automation-loop-skill` keeps `[goal:*]` markers AND maps goal close under `/goal` to the plugin's `update_goal` evidence contract
- [ ] Stale `.opencode/goals/` ignore removed; LEARNINGS both-entries rule annotated v1-specific
- [ ] No `package-lock.json` change (plugin fetched by opencode at boot, not a repo dependency)
- [ ] Docker image builds; repo test suite green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` (`plugins`, `commands.run-plan` desc) | — | `deploy/setup.sh` + `setup.ps1` (copy to `~/.config/opencode/`), `Dockerfile` (bakes `/app/opencode.json`), every opencode session boot | med — single-point config, JSON must stay valid |
| `opencode_app/.opencode/skills/plan-automation-loop-skill/SKILL.md` | plugin re-add (1.1) for truthful wording | `/run-plan` command flows, `worktree-pipeline-skill` Step 8, primary sessions loading the skill | low |
| `opencode_app/.opencode/skills/worktree-pipeline-skill/SKILL.md` | — (verify-only) | `/run-worktree-pipeline` | low |
| `README.md` (v2 watch-list) | plugin re-add (1.1) | repo docs readers, future plugin audits | low |
| `AGENTS.md`, `deploy/.AGENTS.md`, `opencode_app/README.md` | — (sweep-only) | doc readers, deploy docs | low |
| `.gitignore` | — | none (dead v1 state path) | low |
| `LEARNINGS/solutions/plugin-needs-command-block.md`, `LEARNINGS/_index.md` | plugin re-add (1.1) | future sessions via auto-inject manifest | low |
| `LEARNINGS/decisions/` (new capture) | plugin re-add (1.1) | future sessions via auto-inject manifest | low |

Cross-module nodes: yes — `opencode_app/opencode.json` is consumed by both deploy paths and runtime; architecture review applies.

## Implementation Phases

### Phase 1: Config restore + README watch-list (commit: `feat(plugins): re-add goal mode via @prevalentware/opencode-goal-plugin (v2)`)

- [ ] **1.1** Set `plugins` array (opencode_app/opencode.json:599) to `["@prevalentware/opencode-goal-plugin"]` — bare name, no exact pin, no options object
    — **Why:** restores goal mode; bare pin because exact pins caused the v1 boot-warning breakage (commit `5f95d9c`), and defaults are already secure (`restricted_agents: ["plan"]`, `allow_goal_execution_from_plan: false`)
    — **Done when:** `jq '.plugins' opencode_app/opencode.json` prints exactly the one entry with no version suffix
    — **Consumers affected:** deploy/setup.sh + setup.ps1 copies, Dockerfile bake, every opencode session boot
- [ ] **1.2** Update `/run-plan` description (opencode_app/opencode.json:612): drop "the /goal runtime-guarded path returns when the goal plugin ships a v2 release"; state `/goal` as the available runtime-guarded path
    — **Why:** the caveat is now false; command descriptions are read by users choosing between `/run-plan` and `/goal`
    — **Done when:** `rg "ships a v2 release" opencode_app/opencode.json` returns nothing and the description mentions the runtime-guarded `/goal` path
    — **Consumers affected:** `/run-plan` and `/goal` invokers (primary sessions)
- [ ] **1.3** README.md:475 — remove `opencode-goal-plugin` from the v2 watch-list; record the re-add (scoped name, v2-native since 0.1.30, re-added 2026-09)
    — **Why:** the watch-list claim is now false; it exists precisely to track this re-add
    — **Done when:** watch-list names only the 3 remaining plugins and a status note records the re-add
    — **Consumers affected:** repo docs readers, future plugin audits
- [ ] **1.4** Gate: `jq . opencode_app/opencode.json` parses, no `//` comments, `git status` shows only intended files; commit + push phase
    — **Why:** malformed opencode.json is a known CI breaker (LEARNINGS jsonc anti-pattern); commit-per-phase keeps the change revertible
    — **Done when:** gate passes, phase commit pushed to `feat/382`
    — **Consumers affected:** CI, reviewers

### Phase 2: Skill repoint (commit: `docs(skills): repoint goal references to the v2 goal plugin`)

- [ ] **2.1** plan-automation-loop-skill/SKILL.md — rewrite the three "removed pending v2" spots (lines ~42–43, ~60–61, ~409) to state the plugin is re-added as `@prevalentware/opencode-goal-plugin` (v2); keep `[goal:*]` markers as the inter-skill protocol; add one line mapping goal close under `/goal` to the plugin's `update_goal` tool (evidence contract)
    — **Why:** the skill currently tells future runs the plugin is absent — actively misleading once it ships again
    — **Done when:** `rg "no OpenCode v2 release|removed pending a v2|re-added after a v2 port" opencode_app/.opencode/skills/plan-automation-loop-skill/SKILL.md` returns nothing; `rg "update_goal"` finds the mapping line; `[goal:evidence|complete|blocked]` marker definitions still present
    — **Consumers affected:** `/run-plan` flows, worktree-pipeline Step 8 executor, primary sessions loading the skill
- [ ] **2.2** worktree-pipeline-skill/SKILL.md (~line 255) — verify the `[goal:blocked]` halt-trigger wording does not reference v1-plugin mechanics; adjust only if it does
    — **Why:** markers are retained as executor terminal output; only v1-plugin-specific wording would be wrong
    — **Done when:** halt-trigger section describes `[goal:blocked]` as the executor's terminal marker with no plugin-mechanics claims
    — **Consumers affected:** `/run-worktree-pipeline` consumers
- [ ] **2.3** Sweep `AGENTS.md`, `deploy/.AGENTS.md`, `opencode_app/README.md` with `rg -in "goal"`; update any note still claiming goal mode is removed/awaited (ticket's narrower `goal-plugin` grep already returns empty — wording moved)
    — **Why:** completes the inversion of removal commit `5f95d9c`'s doc sweep across all surfaces it touched
    — **Done when:** no repo doc claims the goal plugin is removed or on a watch-list
    — **Consumers affected:** doc readers
- [ ] **2.4** Gate: the 2.1/2.3 rg checks re-run clean; commit + push phase
    — **Why:** text changes drift; the rg patterns are the objective tripwire
    — **Done when:** gates pass, phase commit pushed
    — **Consumers affected:** CI, reviewers

### Phase 3: Hygiene (commit: `chore(hygiene): drop stale v1 goal ignore + annotate LEARNINGS for v2 plugin`)

- [ ] **3.1** Remove `.opencode/goals/` entry + its comment line from `.gitignore` (lines ~31–32)
    — **Why:** dead v1 state path; the v2 plugin stores state host-side at `~/.local/share/opencode-goal-plugin/goals.json`
    — **Done when:** `rg "opencode/goals" .gitignore` returns nothing
    — **Consumers affected:** none (dead path)
- [ ] **3.2** Annotate `LEARNINGS/solutions/plugin-needs-command-block.md` + its `_index.md` summary: the both-entries rule (plugin array + `command.goal` block) is v1-specific; the v2 scoped package self-registers `/goal`, `/pause_goal`, `/resume_goal`
    — **Why:** unannotated, a future session would re-add a `command.goal` block and risk a duplicate-command conflict
    — **Done when:** both files carry the v2 annotation
    — **Consumers affected:** future sessions via auto-inject manifest
- [ ] **3.3** Add `LEARNINGS/decisions/goal-plugin-v2-readoption.md` (scoped name, bare pin rationale, self-registering commands, wejick rejected) + `_index.md` entry, following the existing `decisions/` house format
    — **Why:** Memory Hygiene requires one decision capture for non-trivial architecture decisions
    — **Done when:** file exists, indexed, ≤ the house format's length
    — **Consumers affected:** future sessions via auto-inject manifest
- [ ] **3.4** Gate: `rg` checks pass; commit + push phase
    — **Why:** same tripwire discipline
    — **Done when:** phase commit pushed
    — **Consumers affected:** CI, reviewers

### Phase 4: Verification gates (no commit unless a gate forces a fix)

- [ ] **4.1** Discover and run the repo test suite (from `package.json` scripts / `tests/`); all green
    — **Why:** AGENTS.md Verification Gates — tests on config changes
    — **Done when:** suite exits 0 (or pre-existing breakage stated explicitly with evidence)
    — **Consumers affected:** CI parity
- [ ] **4.2** Boot smoke in the worktree: start `opencode serve` briefly (timeout), capture stderr/stdout; assert zero plugin load warnings/errors mentioning goal-plugin; then stop it
    — **Why:** boot warnings were the exact v1 failure mode; this also proves the plugin fetch+load works on v2
    — **Done when:** captured log contains no plugin error/warning lines and no boot failure
    — **Consumers affected:** every future session boot
- [ ] **4.3** Drift check: `git status` clean of `package-lock.json`/`node_modules` changes; diff touches only the mapped nodes
    — **Why:** the plugin is runtime-fetched by opencode, not a repo dependency; lockfile drift would violate the repo dependency rule
    — **Done when:** `git diff --name-only origin/main...feat/382` lists only mapped files
    — **Consumers affected:** reviewers, `npm ci` users
- [ ] **4.4** Docker build smoke: `docker compose build` succeeds (config-change build gate); if the environment lacks a Docker daemon, record it explicitly as environment-blocked and surface in the PR body
    — **Why:** AGENTS.md Verification Gates — build on config changes; Dockerfile bakes this opencode.json
    — **Done when:** image builds (or environment-blocked is recorded with evidence)
    — **Consumers affected:** Docker standalone users

## Technical Notes

- v2 contract changes vs v1: rescoped package name; no `commands.goal` block needed; state at `$XDG_DATA_HOME/opencode-goal-plugin/goals.json`; completion is evidence-gated via `update_goal` tools (`complete`+evidence / `unmet`+blocker); safety statuses `budgetLimited`/`usageLimited`/`paused`; Plan-mode safety pins continuation to the `build` agent and records `plan`-agent goals as paused.
- Functional `/goal` smoke (pause/resume/clear, plan-mode pause) needs an interactive/driven session — document as a post-merge manual check in the PR body; the headless gate is boot-warning-free load (4.2).
- No manual CHANGELOG edit (release-please); no setup.sh/setup.ps1 count changes (plugins aren't counted).

## Dependencies

- Network access for opencode to fetch the npm plugin at boot (gate 4.2).
- `@prevalentware/opencode-goal-plugin@0.1.48` (or later) on npm — verified published 2026-09-07.

## Risks & Mitigation

- **v2 plugin API churn** (plugin pins its v2 dev contract to a preview) → bare pin floats latest; gate 4.2 boot-warning check is the tripwire.
- **Docker first-boot plugin fetch requires network** → acceptable for this repo's hosted usage; bake-into-image is a follow-up if offline builds matter.
- **`max_auto_turns: 25` default may pause long `/goal`-wrapped plan runs** → documented knob (`max_auto_turns`, `default_token_budget`); tune on evidence only.
