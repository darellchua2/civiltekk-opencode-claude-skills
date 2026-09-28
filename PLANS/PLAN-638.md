# PLAN: Plan-mode-safe /worktree-pipeline-preview command

**Branch**: feat/638
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/638
**Base**: main

## Acceptance Criteria

- [ ] `deploy/opencode.json` gains exactly one new `commands` key (`worktree-pipeline-preview`) with `agent: "plan"`, `subagent: false`, no `model:` key; all 7 existing entries byte-unchanged
- [ ] New template carries the zero-subagent directive and no `app/.opencode/agents` Docker path
- [ ] `bats tests/test_v2_pipeline_contract.bats` passes
- [ ] README.md documents `/worktree-pipeline-preview` next to the two-flavors note
- [ ] Live `~/.config/opencode/opencode.json` gets the surgical single-key insert; live entry equals the template; command surfaces in a new Plan-mode session

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/opencode.json` → `commands.worktree-pipeline-preview` | — | `deploy/setup.sh` (copies config to user space), `tests/test_v2_pipeline_contract.bats` (template greps: Docker-path absence), opencode runtime (command invocation in Plan sessions) | med |
| `README.md` two-flavors note (~line 24) | 1.1 (the command must exist before it is documented) | human readers, docs-sync audits (`civiltekk-documentation-sync-skill`) | low |
| live `~/.config/opencode/opencode.json` (user-space) | 1.1 merged to main | every future session's command picker (Plan mode) | low |

Cross-module signal: `deploy/opencode.json` has consumers beyond itself (deploy script, contract test, runtime) → architecture review selected at Step 7. No frontend files → uiux review skipped.

## Implementation Phases

### Phase 1: Command entry in the deploy template
- [x] **1.1** Add the `worktree-pipeline-preview` key to the `commands` block of `deploy/opencode.json` — description (read-only preview contract + usage), template (load `worktree-pipeline-skill` in preview mode for `$ARGUMENTS`: inspect-only via `git status/log/diff` + `gh issue view`; no fetch/pull/push, no worktree, no branches, no commits, no PRs, no file writes; would-be PLAN content in-chat, never writing `PLANS/`; stop before Step 8 execution; spawn NO subagents; **if the skill does not resolve/load, report unavailable and stop with the install hint `npx github:darellchua2/civiltekk-opencode-claude-skills add worktree-pipeline-skill`** — preset-only installs lack the skill), `agent: "plan"`, `subagent: false`, and NO `model:` key
    — **Why:** the deploy template is the single source for shipped commands; the contract test, deploy flow, and live insert all key off this entry, so every downstream artifact derives from it
    — **Done when:** `node -e "require('./deploy/opencode.json')"` parses; the commands block has exactly 8 keys; the 7 sibling entries deep-equal their `origin/main` versions; the new entry has no `model:` key
    — **Consumers affected:** `deploy/setup.sh` (copies the file), `tests/test_v2_pipeline_contract.bats` (greps all templates), opencode runtime (new Plan-mode command)
    — **Done:** added the key with `agent: "plan"`, `subagent: false`, skill-resolution guard, no `model:`; gate verified 8 keys / zero sibling drift / zero Docker-path strings; files: deploy/opencode.json; fixes: none

### Phase 2: README documentation
- [x] **2.1** Extend the two-flavors note at `README.md` ~line 24 with one sentence: Plan-mode sessions get read-only `/worktree-pipeline-preview`; real execution stays on the Build-pinned `/run-worktree-pipeline` + `-v2`
    — **Why:** repo sync rules require shipped commands to be documented where command flavors are taught; undocumented commands drift
    — **Done when:** README mentions `/worktree-pipeline-preview` with its read-only contract; `git diff` shows exactly one modified line-block in README.md
    — **Consumers affected:** README readers; docs-sync audits
    — **Done:** one sentence appended to the two-flavors note documenting the read-only preview command; diff scoped to README.md; files: README.md; fixes: none

### Phase 3: Verification gate
- [ ] **3.1** Run the verification gate scoped to this diff: `bats tests/test_v2_pipeline_contract.bats`; JSON sibling byte-equality vs `origin/main`; grep proves the new template contains the zero-subagent directive and zero `app/.opencode/agents` occurrences
    — **Why:** the contract test pins commands-block invariants (Docker dead-letter absence, subagent directives) — catching drift here is cheaper than CI catching it
    — **Done when:** bats exits 0 and every scoped check exits 0; gate memo appended to this PLAN's trace
    — **Consumers affected:** CI (runs the same suite)

### Phase 4: Post-merge user-space deploy (no repo commit)
- [ ] **4.1** After merge: surgically insert the single `worktree-pipeline-preview` key into live `~/.config/opencode/opencode.json` (python3 json read-modify-write preserving the local `permissions` customization), then deep-compare live entry vs template entry and confirm `permissions` byte-equal before/after
    — **Why:** `setup.sh`'s config copy is prompt-guarded and will not overwrite the live file (PLAN-613/617 precedent); the live config is what the running harness reads
    — **Done when:** live commands block gains exactly the new key; deep-equal with template; local permissions rules untouched; a new Plan-mode session lists the command
    — **Consumers affected:** every future Plan-mode session's command picker

## Technical Notes

- Shipped command entries stay model-free (LEARNINGS `solutions/commands-model-pins-bypass-tier-resolver`) — no `model:` key.
- Template wording keeps the inline-arm marker phrase "spawn NO subagents" (consistency with the v2 entry the contract test pins).
- The preview command must genuinely honor Plan-mode read-only restrictions — the template's inspect-only list is the enforcement surface (the plan agent has no write permissions anyway; the template prevents confusing half-runs).
- Commit shapes (Conventional Commits): Phase 1 `feat(commands): add plan-mode-safe /worktree-pipeline-preview`; Phase 2 `docs(readme): document /worktree-pipeline-preview`; Phase 3 folds into the phase it verifies (no standalone commit).
- Phase 4 is a user-space deploy action executed by the orchestrator after the PR merges — it intentionally produces no repo commit (the live config is outside the repository).

## Dependencies

- None. No `blocked-by:` tickets. Soft tooling deps only: `bats` for the contract test.

## Risks & Mitigation

- **Live-config clobber risk**: the live `~/.config/opencode/opencode.json` carries local `permissions` customization — mitigated by single-key surgical insert + before/after byte-compare of the `permissions` block (Phase 4.1 Done-when).
- **Contract-test trip**: the new template must not contain the Docker `app/.opencode/agents` path — checked at Phase 3.1 before push.
- **Sibling drift**: any accidental edit to the 7 existing command entries would change deployed behavior — byte-equality vs `origin/main` gates Phase 1.1.

## Trace

_Gate memo lines appended by the executor (verification-loop-skill format)._

GATE dad93f4 tier=light lint=t(json-parse) typecheck=n.a build=n.a unit=t(scoped equality+invariants) e2e=n.a
GATE 731760b tier=light lint=t(docs grep) typecheck=n.a build=n.a unit=t(diff-scope) e2e=n.a
