# PLAN: Default project-scope skills to .agents/skills/

**Branch**: feat/561
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/561
**Base**: main

## Acceptance Criteria

- [x] `add <skill> --project` (default target) writes `.agents/skills/<name>/`; OpenCode discovers it natively
- [x] `--target agents --project` skills land verbatim in `.agents/skills/` (via the opencode row); agent files still downgrade to `.opencode/agents/`
- [x] `--target kimi --project` still writes `.kimi-code/skills/`
- [ ] Subagent doc names `.agents/skills/` as default, `.opencode/skills/` as explicit override
- [ ] Bats suites pass: init, agents_target, claude_target, kimi_target, test_portability
- [ ] `AGENTS.md` + `README.md` updated; no `.opencode/skills` literals introduced into `skills/**/SKILL.md`
- [x] Help text + installer summary reflect `.agents/skills/`

## Gate Trace


## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` `TARGETS.opencode.projectSkillsDir` (L74) | — | project install/update paths (L417–428, L681–687), downgrade-note check (L773), generated-AGENTS.md summary (L661), 4 bats literals, README/AGENTS prose | medium |
| `installer/init.mjs` help text (L1573, L1591–1604) + header comments (L5, L19) | TARGETS flip | CLI users, docs tests | low |
| `agents/opencode-tooling-subagent.md` (L109, L146–147, L218, L244) | — | primary-agent delegation (spawn-time system prompt), `deploy/setup.sh` copy | low |
| `tests/init.bats:82`, `tests/agents_target.bats:124`, `tests/claude_target.bats:118`, `tests/kimi_target.bats:114` | TARGETS flip | CI | low |
| `README.md:50`, root `AGENTS.md` (Repository Purpose bullet 3) | TARGETS flip | repo consumers, contributors | low |

All TARGETS consumers live inside the installer module (single `init.mjs`) plus its test suite and prose docs — no second source module reads the row.

## Implementation Phases

### Phase 1: Installer flip + pinned test expectations

- [x] **1.1** Flip `TARGETS.opencode.projectSkillsDir` from `".opencode/skills"` to `".agents/skills"` in `installer/init.mjs` (L74), and replace the hardcoded literal in the generated-AGENTS.md summary line (L661, `` `${sel.skills.length} skills (see \`.opencode/skills/\`).` ``) with the resolved `projectSkillsDir` (thread the in-scope config variable; keep the sentence shape). Also update the file-header comments (L5, L19) that describe project writes as `<project>/.opencode/`.
    — **Why:** This single cell is the SINGLE SITE (PLAN-453 gate) driving `add --project`, preset installs, and the claude/agents downgrade path; fixing it once relocates every project-scope skill write. OpenCode v2 natively discovers `.agents/skills/`, so nothing is lost for opencode-only users.
    — **Done when:** `grep -n '"\.agents/skills"' installer/init.mjs` shows the TARGETS row; `grep -n 'opencode/skills' installer/init.mjs` no longer matches L74 or L661; `node --check installer/init.mjs` (or `node -e "import(...)"`) parses clean.
    — **Consumers affected:** project install/update/remove paths, downgrade note (unchanged text — claude/agents rows still lack `projectSkillsDir`), generated project AGENTS.md line.
    — **Done:** TARGETS.opencode.projectSkillsDir → `".agents/skills"`; generated-AGENTS.md summary now interpolates `TARGETS.opencode.projectSkillsDir`; header comments (L5–10, L19) describe the split layout; files: installer/init.mjs; fixes: none
- [ ] **1.2** Update help text (L1573 `install to project .opencode/ (full config)`, L1604 `Project scope (--project): writes .opencode/{agents,skills}/ ...`) to state agents/config stay in `.opencode/` while skills go to `.agents/skills/` (discovered by OpenCode + pi).
    — **Why:** The `--help` SCOPE section is the contract users read; leaving it stale inverts the documented behavior (learned-pattern: command-description parallel restatements drift when only the source is fixed).
    — **Done when:** `node installer/init.mjs --help` prints `.agents/skills` in the Project scope line and no help line claims project skills land in `.opencode/`.
    — **Consumers affected:** CLI users; any doc quoting help output.
    — **Done:** USAGE add-line reads `install to project (agents/config .opencode/, skills .agents/skills/)`; SCOPE Project-scope paragraph rewritten around the split layout; files: installer/init.mjs; fixes: none
- [ ] **1.3** Update the four pinned project-scope test literals to `.agents/skills`: `tests/init.bats:82` (preset skill count dir), `tests/agents_target.bats:124` + `tests/claude_target.bats:118` + `tests/kimi_target.bats:114` (downgrade tests — the `has no project destination` note assertions and `[ ! -e "${HOME}/.agents" ]` / `${HOME}/.claude/agents` negatives stay as-is).
    — **Why:** These tests pin installer behavior; after 1.1 they fail until expectations move. The downgrade tests must keep asserting the note and the user-scope negatives — only the project dir literal changes.
    — **Done when:** `grep -rn 'TMP_PROJ/.opencode/skills\|TMP_PROJ/.opencode/skills' tests/` returns nothing while the four files still reference `$TMP_PROJ/.agents/skills/` in those assertions; user-scope `$HOME/.config/opencode/skills` assertions untouched.
    — **Consumers affected:** CI gate for every later phase.
    — **Done:** four project-scope literals moved to `$TMP_PROJ/.agents/skills/` (init.bats, agents_target.bats, claude_target.bats, kimi_target.bats); `has no project destination` note assertions and user-scope negatives untouched; files: tests/init.bats, tests/agents_target.bats, tests/claude_target.bats, tests/kimi_target.bats; fixes: none
- [ ] **1.4** Run the targeted gate: `bats tests/init.bats tests/agents_target.bats tests/claude_target.bats tests/kimi_target.bats`.
    — **Why:** Proves the flip behaviorally before docs/doc guidance layers on top (verification gate: tests on logic changes).
    — **Done when:** all four suites exit 0.
    — **Consumers affected:** Phases 2–4 gates.
    — **Done:** `bats tests/init.bats tests/agents_target.bats tests/claude_target.bats tests/kimi_target.bats` → 64 ok / 0 not ok, exit 0; files: none; fixes: none

### Phase 2: Agent guidance flip (opencode-tooling-subagent)

- [ ] **2.1** In `agents/opencode-tooling-subagent.md`, change project-level skill guidance to `.agents/skills/<name>/SKILL.md` as the default (Step 0 regular-project bullet L109, File Locations table L147, Proactive Suggestions L218 + L244), keeping `.opencode/skills/` documented as the explicit opencode-only override on user request; agents (subagent files) remain `.opencode/agents/` everywhere.
    — **Why:** The subagent's system prompt is the second "force to opencode" surface — headless creation must land skills where pi + OpenCode both read them unless explicitly told otherwise.
    — **Done when:** `grep -n '.agents/skills' agents/opencode-tooling-subagent.md` shows the default in all four sites; no line instructs `.opencode/skills/` as the unqualified default; frontmatter untouched (no registry rebuild needed).
    — **Consumers affected:** every delegation to opencode-tooling-subagent; `deploy/setup.sh` copy (redeploy picks it up).

### Phase 3: Repo docs sync

- [ ] **3.1** Update root `AGENTS.md` Repository Purpose bullet 3 (L10) and `README.md` L50 (`--project` note) to document: project-scope skills install to `.agents/skills/` (Agent Skills standard dir natively read by OpenCode v2 and pi; pi additionally requires project trust); `.opencode/` keeps agents, `opencode.json`, manifests; `.opencode/skills/` remains a valid explicit location.
    — **Why:** Repo docs are the sync-rule surfaces (Adding Skills/Sync Rules table) — behavior changed, so prose must match or the documentation-consistency guard flags drift.
    — **Done when:** both files mention `.agents/skills/` as the project default; no remaining sentence claims `--project` installs skills into `./.opencode/`.
    — **Consumers affected:** contributors, `npx` users reading README.

### Phase 4: Full verification gate (ticket exit gate)

- [ ] **4.1** Run the full suite: `bats tests/` (includes `test_portability.bats` — must confirm zero `.opencode/skills` literals in `skills/**/SKILL.md` — and `test_skill_isolation.bats`, which scans agent docs).
    — **Why:** Exit gate is full tier per verification-loop-skill; the isolation and portability guards sweep the exact files this ticket edits.
    — **Done when:** full `bats tests/` exits 0; gate memo `GATE <short-sha> tier=full` recorded in the PLAN trace.
    — **Consumers affected:** Step 9 review citation and Step 10 PR gate citation.

## Technical Notes

- Manifest location is unchanged (`.opencode/.opencode-init.manifest.json`, keyed off `dirname(agentsDir)`), so update/remove of pre-flip installs keep working; skills installed before this change stay in `.opencode/skills/` until re-run (`update`) or `--prune`.
- Migration window: a skill present in both `.opencode/skills/` and `.agents/skills/` collides by name (OpenCode requires unique names across locations). Release note advises `update`/`--prune` or a manual `mv`; no migration tooling (ticket scope).
- pi loads project `.agents/skills/` only after project trust — informational for release notes.
- `TARGETS.agents` row intentionally unchanged: it has no project destination, so its downgrade resolves to the opencode row — which now *is* `.agents/skills/`, byte-identical to a native agents project install. Agents (subagent files) still downgrade to `.opencode/agents/` (nothing verified reads project `.agents/agents/`).

## Dependencies

None (no `blocked-by:`).

## Risks & Mitigation

- **Duplicate-name discovery window** (old + new dir both populated): mitigation = release note + `update`/`--prune`; installer manifest remains the removal source of truth.
- **Hidden help-text/doc assertions in bats**: if an unlisted test asserts the old strings, the Phase 1/4 gate catches it — fix forward in the same phase.
- **Portability/isolation guards**: both sweep the edited surfaces; full-gate Phase 4 catches regressions.
