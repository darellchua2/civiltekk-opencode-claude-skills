# PLAN: Re-add goal mode via @prevalentware/opencode-goal-plugin (OpenCode v2)

**Branch**: feat/382
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/382
**Base**: main

## Acceptance Criteria

- [x] `plugins` array carries `@prevalentware/opencode-goal-plugin` pinned `@^0.1.48` (fallback to bare name if v2 constraint resolution fails at boot — see 1.1)
- [x] `opencode` boots with zero plugin boot warnings (host gate 4.2)
- [x] No `commands.goal` block added (v2 plugin self-registers `/goal`, `/pause_goal`, `/resume_goal`)
- [x] Docs consistent: goal-plugin removed from README v2 watch-list; no stale "removed pending v2" references anywhere
- [x] `plan-automation-loop-skill` keeps `[goal:*]` markers AND maps goal close under `/goal` to the plugin's `update_goal` evidence contract
- [x] Stale `.opencode/goals/` ignore removed; LEARNINGS both-entries rule annotated v1-specific
- [x] No `package-lock.json` change (plugin fetched by opencode at boot, not a repo dependency)
- [x] Repo test suite green; `docker compose build` succeeds (build-only — see descope note)
- [x] Docker descope recorded: `/goal` in the web endpoint is **blocked-by #387** (container v1 binary ignores the v2 `plugins` key); recorded in map, risks, and PR body

**Deferred — post-merge manual checks (owner-approved via pipeline report + PR body; headless executor limits):**

- Interactive `/goal` functional behaviors: create + auto-continue until `update_goal complete`/`unmet`; `/goal pause`/`resume`/`clear`; interrupt-blocks-goal and auto-resume-on-next-message; `/goal` from the `plan` agent records a paused goal. Best-effort driven check in 4.2b covers the create→complete path when `opencode run` + provider are available.
- `/run-plan` end-to-end still emitting `[goal:*]` markers (bats suite has no run-plan coverage — text preservation gate 2.4 is the automated proxy).
- Watch for `budgetLimited`/`usageLimited` pauses on the first long `/goal`-wrapped run (`max_auto_turns: 25` default vs 12-phase plans) and tune `max_auto_turns`/`default_token_budget` on evidence.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` (`plugins`, `commands.run-plan` desc) | — | `deploy/setup.sh` + `setup.ps1` (copy to `~/.config/opencode/`, copy-only), `deploy/resolve-models.mjs:462-463` + `deploy/merge-packs.mjs:224` (in-image JSON round-trip — verified full-object, preserves key), `Dockerfile` bake (inert on container v1 binary — see risk R1), every host opencode session boot | med — single-point config, JSON must stay valid |
| `opencode_app/.opencode/skills/plan-automation-loop-skill/SKILL.md` | plugin re-add (1.1) for truthful wording | `/run-plan` command flows, `worktree-pipeline-skill` Step 8, primary sessions loading the skill | low |
| `opencode_app/.opencode/skills/worktree-pipeline-skill/SKILL.md` | — (verify-only) | `/run-worktree-pipeline` | low |
| `README.md` (v2 watch-list) | plugin re-add (1.1) | repo docs readers, future plugin audits | low |
| `AGENTS.md`, `deploy/.AGENTS.md`, `opencode_app/README.md` | — (sweep-only) | doc readers, deploy docs | low |
| `.gitignore` | — | none (dead v1 state path) | low |
| `LEARNINGS/solutions/plugin-needs-command-block.md`, `LEARNINGS/_index.md` | plugin re-add (1.1) | future sessions via auto-inject manifest | low |
| `LEARNINGS/decisions/`, `LEARNINGS/solutions/` (new captures) | plugin re-add (1.1) | future sessions via auto-inject manifest | low |
| `opencode_app/Dockerfile:7` / `docker-compose.yml:8` (v1 binary pins) | — (NOT changed here) | container runtime — causes R1 inertness; fix tracked in #387 | informational |

Cross-module nodes: yes — `opencode_app/opencode.json` is consumed by both deploy paths and runtime; architecture review applied (findings folded in: W1→AC descope + gate 4.4 rewrite, W2→map rows above, W3→step 1.1 pin + rationale fix, N1/N2→risks + deferred list).

## Implementation Phases

### Phase 1: Config restore + README watch-list (commit: `feat(plugins): re-add goal mode via @prevalentware/opencode-goal-plugin (v2)`)

- [x] **1.1** Set `plugins` array (opencode_app/opencode.json:599) to `["@prevalentware/opencode-goal-plugin@^0.1.48"]`, no options object. If gate 4.2 shows the v2 array cannot resolve the `@^` constraint, fall back to the bare name AND record the audited version (`0.1.48`, published 2026-09-07, verified via `npm view`) in the README re-add note (1.3)
    — **Why:** restores goal mode with a reproducible, reviewed version floor; corrected rationale — the v1 breakage (`5f95d9c`) was v1-only plugin versions under a v2 runtime plus pins that never floated to v2 releases, NOT pinning itself; a caret pin to the v2-native line upgrades deliberately within `0.1.x` while boots stay reproducible (repo convention: committed lockfile). Defaults need no options: `restricted_agents: ["plan"]`, `allow_goal_execution_from_plan: false`
    — **Done when:** `jq -r '.plugins[]' opencode_app/opencode.json` prints the pinned entry (or the documented bare-name fallback with the README audit line present)
    — **Consumers affected:** deploy/setup.sh + setup.ps1 copies, Dockerfile bake (inert until #387), every opencode session boot
    — **Done:** plugins array set to the caret-pinned entry; files: opencode_app/opencode.json; fixes: none (boot resolution check deferred to gate 4.2 per plan)
- [x] **1.2** Update `/run-plan` description (opencode_app/opencode.json:612): drop "the /goal runtime-guarded path returns when the goal plugin ships a v2 release"; state `/goal` as the available runtime-guarded path
    — **Why:** the caveat is now false; command descriptions are read by users choosing between `/run-plan` and `/goal`
    — **Done when:** `rg "ships a v2 release" opencode_app/opencode.json` returns nothing and the description mentions the runtime-guarded `/goal` path
    — **Consumers affected:** `/run-plan` and `/goal` invokers (primary sessions)
    — **Done:** description now points long hands-off runs at the runtime-guarded /goal path with the plugin name; files: opencode_app/opencode.json; fixes: none
- [x] **1.3** README.md:475 — remove `opencode-goal-plugin` from the v2 watch-list; record the re-add (scoped name, pin form chosen in 1.1, v2-native since 0.1.30, audited version, re-added 2026-09)
    — **Why:** the watch-list claim is now false; it exists precisely to track this re-add
    — **Done when:** watch-list names only the 3 remaining plugins and a status note records the re-add + audited version (mandatory in the bare-name fallback)
    — **Consumers affected:** repo docs readers, future plugin audits
    — **Done:** watch-list reduced to the 3 remaining plugins; re-add note records scoped name, caret pin, v2-native-since-0.1.30, audited 0.1.48 (2026-09-07), and the #387 Docker caveat; files: README.md; fixes: none
- [x] **1.4** Gate: `jq . opencode_app/opencode.json` parses, no `//` comments, `git status` shows only intended files; commit + push phase
    — **Why:** malformed opencode.json is a known CI breaker (LEARNINGS jsonc anti-pattern); commit-per-phase keeps the change revertible
    — **Done when:** gate passes, phase commit pushed to `feat/382`
    — **Consumers affected:** CI, reviewers
    — **Done:** jq parse OK, plugins entry verified, no // comments, status shows only README.md + opencode.json, bats 13/13 green; files: (gate only); fixes: worktree bats submodule tests/lib/bats-core was uninitialized — `git submodule update --init` (environmental, not a code fix)

### Phase 2: Skill repoint (commit: `docs(skills): repoint goal references to the v2 goal plugin`)

- [x] **2.1** plan-automation-loop-skill/SKILL.md — rewrite the three "removed pending v2" spots (lines ~42–43, ~60–61, ~409) to state the plugin is re-added as `@prevalentware/opencode-goal-plugin` (v2); keep `[goal:*]` markers as the inter-skill protocol; add one line mapping goal close under `/goal` to the plugin's `update_goal` tool (evidence contract)
    — **Why:** the skill currently tells future runs the plugin is absent — actively misleading once it ships again
    — **Done when:** `rg "no OpenCode v2 release|removed pending a v2|re-added after a v2 port" opencode_app/.opencode/skills/plan-automation-loop-skill/SKILL.md` returns nothing; `rg "update_goal"` finds the mapping line; `[goal:evidence|complete|blocked]` marker definitions still present
    — **Consumers affected:** `/run-plan` flows, worktree-pipeline Step 8 executor, primary sessions loading the skill
    — **Done:** four spots repointed (the three planned + the "runtime-enforced guardrails unavailable" note at ~430, same class); markers retained as inter-skill protocol; update_goal mapping added at lines ~42–45, ~59–63, ~408–411; files: opencode_app/.opencode/skills/plan-automation-loop-skill/SKILL.md; fixes: none
- [x] **2.2** worktree-pipeline-skill/SKILL.md (~line 255) — verify the `[goal:blocked]` halt-trigger wording does not reference v1-plugin mechanics; adjust only if it does
    — **Why:** markers are retained as executor terminal output; only v1-plugin-specific wording would be wrong
    — **Done when:** halt-trigger section describes `[goal:blocked]` as the executor's terminal marker with no plugin-mechanics claims
    — **Consumers affected:** `/run-worktree-pipeline` consumers
    — **Done:** verified — wording is "the executor's `[goal:blocked]` terminal marker (Step 8)", no plugin-mechanics claims; no change required; files: none; fixes: none
- [x] **2.3** Sweep `AGENTS.md`, `deploy/.AGENTS.md`, `opencode_app/README.md` with `rg -in "goal"`; update any note still claiming goal mode is removed/awaited (ticket's narrower `goal-plugin` grep already returns empty — wording moved)
    — **Why:** completes the inversion of removal commit `5f95d9c`'s doc sweep across all surfaces it touched
    — **Done when:** no repo doc claims the goal plugin is removed or on a watch-list
    — **Consumers affected:** doc readers
    — **Done:** sweep returned zero stale references (only non-goals/irrelevant matches) — later commits had already reworded these surfaces; files: none; fixes: none
- [x] **2.4** Gate: the 2.1/2.3 rg checks re-run clean; commit + push phase
    — **Why:** text changes drift; the rg patterns are the objective tripwire
    — **Done when:** gates pass, phase commit pushed
    — **Consumers affected:** CI, reviewers
    — **Done:** stale-phrase rg empty, update_goal present (3), markers retained (goal:evidence ×2), bats 13/13 green; files: (gate only); fixes: none

### Phase 3: Hygiene (commit: `chore(hygiene): drop stale v1 goal ignore + annotate LEARNINGS for v2 plugin`)

- [x] **3.1** Remove `.opencode/goals/` entry + its comment line from `.gitignore` (lines ~31–32)
    — **Why:** dead v1 state path; the v2 plugin stores state host-side at `~/.local/share/opencode-goal-plugin/goals.json`
    — **Done when:** `rg "opencode/goals" .gitignore` returns nothing
    — **Consumers affected:** none (dead path)
    — **Done:** comment + entry removed; files: .gitignore; fixes: none
- [x] **3.2** Annotate `LEARNINGS/solutions/plugin-needs-command-block.md` + its `_index.md` summary: the both-entries rule (plugin array + `command.goal` block) is v1-specific; the v2 scoped package self-registers `/goal`, `/pause_goal`, `/resume_goal`
    — **Why:** unannotated, a future session would re-add a `command.goal` block and risk a duplicate-command conflict
    — **Done when:** both files carry the v2 annotation
    — **Consumers affected:** future sessions via auto-inject manifest
    — **Done:** SUPERSEDED-for-v2 block added under the solution title; _index summary rewritten to carry the v2 rule; files: LEARNINGS/solutions/plugin-needs-command-block.md, LEARNINGS/_index.md; fixes: none
- [x] **3.3** Add `LEARNINGS/decisions/goal-plugin-v2-readoption.md` + `_index.md` entry, following the structure of `LEARNINGS/decisions/skill-permission-allowlist.md` (header, Context, Decision, Consequences): scoped name, caret-pin rationale (corrected — see 1.1) with bare-name fallback, self-registering commands, wejick/opencode-goal rejected, Docker descope to #387
    — **Why:** Memory Hygiene requires decision capture for non-trivial architecture decisions
    — **Done when:** file exists, indexed, sections match the reference file's structure
    — **Consumers affected:** future sessions via auto-inject manifest
    — **Done:** decision doc written with Context/Pattern/Rationale/Alternatives/Trade-offs/Confidence/Scope/Date/References mirroring the reference file; indexed; files: LEARNINGS/decisions/goal-plugin-v2-readoption.md, LEARNINGS/_index.md; fixes: none
- [x] **3.4** Add `LEARNINGS/solutions/docker-v1-binary-ignores-v2-plugins-key.md` + `_index.md` entry (surfaced by architecture review): v2 `plugins` array is inert on the Docker path until the binary bump; plugin additions need a runtime-presence gate or explicit descope
    — **Why:** reusable trap — ANY future v2 npm plugin addition hits the same silent inertness; evidence Dockerfile:7,86-88, docker-compose.yml:8, #387
    — **Done when:** file exists, indexed
    — **Consumers affected:** future sessions adding plugins via auto-inject manifest
    — **Done:** solution doc written (Context/Pattern/Rationale/Evidence/Diagnostic steps/Trade-offs) + indexed; files: LEARNINGS/solutions/docker-v1-binary-ignores-v2-plugins-key.md, LEARNINGS/_index.md; fixes: none
- [x] **3.5** Gate: `rg` checks pass; commit + push phase
    — **Why:** same tripwire discipline
    — **Done when:** phase commit pushed
    — **Consumers affected:** CI, reviewers
    — **Done:** gitignore rg clean, SUPERSEDED annotation present, both new LEARNINGS files exist + indexed, bats 13/13 green, status shows only intended files; files: (gate only); fixes: none

### Phase 4: Verification gates (no commit unless a gate forces a fix)

- [x] **4.1** Discover and run the repo test suite (from `package.json` scripts / `tests/`); all green
    — **Why:** AGENTS.md Verification Gates — tests on config changes
    — **Done when:** suite exits 0 (or pre-existing breakage stated explicitly with evidence)
    — **Consumers affected:** CI parity
    — **Done:** no npm scripts; gate = CI's own command (release.yml): vendored bats loop over tests/*.bats — 13/13 green; files: (gate only); fixes: submodule init (recorded at 1.4)
- [x] **4.2** Boot smoke in the worktree: start `opencode serve` briefly (timeout), capture stderr/stdout; assert zero plugin load warnings/errors mentioning goal-plugin and that the `@^0.1.48` pin resolves (else apply the 1.1 bare-name fallback); then stop it
    — **Why:** boot warnings were the exact v1 failure mode; this proves plugin fetch+pin-resolution works on v2 (also the merge gate for the Docker-descoped ticket)
    — **Done when:** captured log contains no plugin error/warning lines and no boot failure; pin decision finalized
    — **Consumers affected:** every future session boot
    — **Done:** isolated OPENCODE_CONFIG_DIR boot (opencode v2.0.3): server healthy, boot logs clean (2 lines); AFFIRMATIVE evidence via /api/command — plugin self-registered `goal`, `pause_goal`, `resume_goal`; /api/config resolved `@prevalentware/opencode-goal-plugin@^0.1.48` — caret pin accepted, no fallback needed; server stopped; files: (gate only); fixes: none
- [x] **4.3** Drift check: `git status` clean of `package-lock.json`/`node_modules` changes; diff touches only the mapped nodes
    — **Why:** the plugin is runtime-fetched by opencode, not a repo dependency; lockfile drift would violate the repo dependency rule
    — **Done when:** `git diff --name-only origin/main...feat/382` lists only mapped files
    — **Consumers affected:** reviewers, `npm ci` users
    — **Done:** diff lists exactly the 9 mapped files; no package.json/package-lock/node_modules changes; files: (gate only); fixes: none
- [x] **4.4** Docker build smoke: `docker compose build` succeeds (build-only gate). RUNTIME `/goal` in the web endpoint is explicitly descoped — blocked-by #387 (container v1 binary ignores the v2 `plugins` key; no `opencode-ai` 2.x exists on npm). If the environment lacks a Docker daemon, record environment-blocked with evidence in the PR body
    — **Why:** AGENTS.md Verification Gates — build on config changes; runtime presence is untestable until #387 and would otherwise fail silently-green
    — **Done when:** image builds (or environment-blocked recorded with evidence); PR body carries the descope note
    — **Consumers affected:** Docker standalone users (via #387)
    — **Done:** daemon present; `docker compose build` succeeded (image 382-opencode built); descope note staged for the PR body; files: (gate only); fixes: none

## Technical Notes

- v2 contract changes vs v1: rescoped package name; no `commands.goal` block needed; state at `$XDG_DATA_HOME/opencode-goal-plugin/goals.json`; completion is evidence-gated via `update_goal` tools (`complete`+evidence / `unmet`+blocker); safety statuses `budgetLimited`/`usageLimited`/`paused`; Plan-mode safety pins continuation to the `build` agent and records `plan`-agent goals as paused.
- Commit-grouping deviation (accepted): ticket suggested bundling the `/run-plan` description with the skills commit; PLAN keeps it in Phase 1 because it is an opencode.json edit — one file, one commit, cleaner revert boundary.
- No manual CHANGELOG edit (release-please); no setup.sh/setup.ps1 count changes (plugins aren't counted).
- Docker goal-state sits beside the `opencode-data` volume (`docker-compose.yml:14`) — goals vanish on container recreation; folded into #387 (not fixable separately from the binary bump).

## Dependencies

- Network access for opencode to fetch the npm plugin at boot (gate 4.2).
- `@prevalentware/opencode-goal-plugin@0.1.48` (or later) on npm — verified published 2026-09-07.
- Blocked-by (runtime only, not this branch's merge): #387 for Docker-endpoint `/goal`.

## Risks & Mitigation

- **R1 — Docker v1 binary ignores the v2 `plugins` key** (not a network concern): plugin silently inert in the container; build-only gate would stay green. Mitigation: explicit descope recorded in AC/map/gate 4.4/PR body; runtime fix + loud presence assertion tracked in #387.
- **R2 — v2 plugin API churn** (plugin pins its v2 dev contract to a preview) → caret pin bounds drift within `0.1.x`; gate 4.2 boot-warning check is the tripwire; deliberate bumps via commit.
- **R3 — `max_auto_turns: 25` default vs 12-phase `/goal`-wrapped plan runs** → deferred manual check watches for `budgetLimited` on first long run; knobs documented (`max_auto_turns`, `default_token_budget`); tune on evidence only.
