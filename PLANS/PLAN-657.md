# PLAN: Add civiltekk-install-assistant catalog install skill

**Branch**: feat/657
**Issue**: https://github.com/darellchua2/civiltekk-skills/issues/657
**Base**: main

## Acceptance Criteria

- [x] `skills/civiltekk-install-assistant/` — router SKILL.md + `references/{find,install,maintain}.md`, frontmatter house-contract conformant, all files inside the skill dir
- [x] find route resolves catalog via installer read modes (`--list agents|skills|categories`, `--describe`, `--expand`, in-repo `node installer/init.mjs` shortcut), ranks matches by intent
- [x] install route: dry-run before every write, `--no-deps` explicit-only, consent before global, post-install file verification
- [x] maintain route: `update`, `update --prune`, `remove` with honest state reporting
- [x] AGENTS.md wire-up is append-only with conflict detection; `deploy/.AGENTS.md` gains exactly one additive section
- [x] `installer/registry.json` regenerated (skills 123→124) and staged; README counts + category row updated consistently (all six surfaces + changelog chain)
- [x] `tests/test_skill_isolation.bats` passes (plus registry-vs-disk suites green)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/civiltekk-install-assistant/SKILL.md` + `references/*` | installer read-mode CLI surface (init.mjs `--list/--describe/--expand/add/update/remove` flags — verified against `installer/init.mjs:11-26`); frontmatter contract (`civiltekk-opencode-creation-skill`) | `installer/build-registry.mjs` indexer → `registry.json`; dynamic setup banner counts; README catalog; end-user skill loaders; `deploy/.AGENTS.md` router block (points here) | low (purely additive) |
| `installer/registry.json` | new skill frontmatter (regen) | `installer/init.mjs` (`--list/--describe/resolver/TUI`); `tests/init.bats` + `tests/deploy_delegate.bats` (registry-vs-disk per commit, BT-157) | med (generated artifact — must be regenerated AND staged in the same commit as frontmatter; never hand-edited) |
| `README.md` count surfaces (:5, :76, :102, :220, :259, :261, :283 — :220 caught by the 4.2 sweep at execution) | skill dir on disk; registry regen | docs readers; `tests/test_count_drift.bats` (disk-vs-disk, dynamic-safe) | low (number-keyed literals — the class name-grep sweeps miss; verified by number+verb-keyed sweep) |
| `deploy/.AGENTS.md` | skill existing (block points at it) | `deploy/setup.sh` → `~/.config/opencode/AGENTS.md`; every deployed session | low (append-only section; existing content untouched) |
| `deploy/setup.sh` / `deploy/setup.ps1` | — | none changed — banner uses dynamic `count_skills` (`setup.sh:431,753,3404`); `setup.ps1` has zero skill enumerations (verified by grep) | none (no edit; proven by sweep greps in 4.2) |
| `installer/dependency-map.json`, `installer/presets/pack-*.json` | — | none changed — dependency-map is edges-only (0 standalone-skill hits); new skill joins no preset | none (no edit; noted for review) |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Skill scaffold + registry (one commit — registry rides frontmatter per BT-157)

- [x] **1.1** Create `skills/civiltekk-install-assistant/SKILL.md` router: frontmatter (`name: civiltekk-install-assistant` = dir name; description ≤50 words carrying all three route triggers + `@civiltekk-install-assistant` / `/civiltekk-install-assistant` handles; `license: Apache-2.0`; `compatibility: opencode`; `metadata.harness: "opencode"`; `category: Configuration`); body = route detection (explicit > inferred > ask-once, headless default find), load-rules table for the three references, cross-branch invariants stated once (mandatory `--dry-run` before every write; `--no-deps` explicit-ask-only; consent before global installs; never hand-edit installed copies — fix at source + `update`; report exact installer errors, no blind retries), direct-invocation fast path, capability-binding block (OpenCode `question` / Claude `AskUserQuestion` / numbered plain reply), bash rule (`Requires bash (git-bash/WSL on Windows)` for npx steps), boundaries (MCP → `mcp-install-assistant-skill`; authoring → `civiltekk-opencode-creation-skill`; harness setup → `civiltekk-coding-harness-setup-skill`; skill-not-subagent honesty note)
    — **Why:** router is the load-time entry every other file hangs off; frontmatter must be contract-exact or build-registry indexes it wrong
    — **Done when:** file exists; `name` == dir name; description word count ≤50 and mentions all three routes + both handles; capability-binding block present; boundaries section names the three sibling skills
    — **Consumers affected:** build-registry indexer, setup banner counts, README catalog
    — **Done:** Router written: name=dir, 48-word description with 3 route triggers + both handles, Apache-2.0, harness "opencode", category Configuration; capability-bindings + boundaries blocks present; files: SKILL.md; fixes: none
- [x] **1.2** Create `references/find.md` — catalog discovery: `--list categories` → `--list skills` / `--list agents` (JSON, grep by intent) → `--describe <name>` (entry + deps) → `--expand <preset>` (bundles); in-repo shortcut `node installer/init.mjs --list skills` (no network); rank top 2–3 matches with one-line fit rationale; hand off to install route
    — **Why:** find is the entry most invocations start from; it must teach real verified flags, not invented ones
    — **Done when:** every command in the file appears in `installer/init.mjs` usage docs (:11-26) or flag parsing; ranking + offer step present
    — **Consumers affected:** install route (handoff target)
    — **Done:** find.md written; every command verified against installer/init.mjs:11-26 usage + BOOL_FLAGS:127; ranking + offer + headless-stop present; files: references/find.md; fixes: none
- [x] **1.3** Create `references/install.md` — `--describe` → `add <name> --project . --dry-run` (mandatory, shown to user) → scope choice table (project default; global = bare `add`, consent-gated; `--target claude|agents|kimi|kilo|zcode|copilot` for other harnesses) → `add` → verify files landed (`<project>/.agents/skills/<name>/SKILL.md` or target dir; plugins auto-ship noted); optional AGENTS.md wire-up step carrying the exact ≤6-line append-only block text with consent + existing-rule conflict detection (skip if an install-routing rule already exists)
    — **Why:** install is the only mutating route — the dry-run gate, consent rules, and append-only AGENTS.md contract are the ticket's safety core
    — **Done when:** file contains the mandatory dry-run step, scope table, verification step, and the verbatim wire-up block with its conflict-detection rule
    — **Consumers affected:** project AGENTS.md files (append-only edits), user-scope manifest (`add` without `--project`)
    — **Done:** install.md written: mandatory dry-run, scope table (project default / global consent / --target incl. zcode user-only + copilot .github/skills from TARGETS init.mjs:82-96), verify step, verbatim AGENTS.md wire-up block with append-only + conflict-detect rules; files: references/install.md; fixes: none
- [x] **1.4** Create `references/maintain.md` — inventory (list project `.agents/skills/` or target dirs; user-scope manifest), `update` (re-sync), `update --prune`, `remove <name>`; honest state reporting (failed/held states are never masked)
    — **Why:** installs rot — the route must exist so the skill covers the full lifecycle, not just day one
    — **Done when:** file covers all four operations with their installer commands
    — **Consumers affected:** user-scope manifest, installed skill copies
    — **Done:** maintain.md written: inventory (project .agents/skills, per-target user dirs, .skill-manifest.json), update/--prune/--no-deps, user-scope remove + preset --prune project-removal note (init.mjs:1410); files: references/maintain.md; fixes: none
- [x] **1.5** Regenerate `installer/registry.json` (`node installer/build-registry.mjs`) and `git add installer/registry.json` in the same phase commit as 1.1–1.4
    — **Why:** BT-157 — registry rides the SAME commit as frontmatter (`tests/init.bats`/`deploy_delegate.bats` enforce registry-vs-disk per commit); leaving it unstaged ships main's stale registry while local gates read disk (`generated-artifact-unstaged-regen` anti-pattern, #408/#422 evidence)
    — **Done when:** `registry.json` contains the `civiltekk-install-assistant` entry with `category: "Configuration"` and `counts.skills == 124`; `git status --porcelain -- installer/registry.json` empty post-commit
    — **Consumers affected:** installer `--list/--describe/TUI`, registry-vs-disk test suites
    — **Done:** build-registry regen green: skills=124, entry {category Configuration, harness opencode}; staged with scaffold in this commit; files: installer/registry.json; fixes: none

### Phase 2: README count sync (six surfaces + changelog chain)

- [x] **2.1** Bump the four bare totals: `README.md:5` ("123 ready-to-load skills" → 124), `README.md:76` ("34 agents + 123 skills" → 124), `README.md:102` ("123 skill directories" → 124), `README.md:259` ("Skill catalog — 123 skills by category" → 124)
    — **Why:** number-keyed literals are the class name-keyed sweeps miss (`skill-add-count-sync-blast-radius` pattern, #402 evidence) — each is a hand-maintained total
    — **Done when:** `grep -n "123" README.md` returns no count-bearing line (changelog history lines excepted — they narrate past states)
    — **Consumers affected:** docs readers; catalog table summary
    — **Done:** Four totals bumped (:5 :76 :102 :259) plus fifth surface :220 caught by the 4.2 sweep (PLAN-time grep noise-filter dropped the line); pulled forward from Phase 2 as gate-fix round 1 (count-drift tests enforce disk-vs-docs per commit); files: README.md; fixes: count-drift red
- [x] **2.2** Update the migration changelog chain at `README.md:261`: `Current count: **123**` → `**124**` and append the #657 entry to the history chain matching the #654 precedent phrasing ("one cross-harness setup skill added in #654" → append "; one catalog install-assistant skill added in #657")
    — **Why:** house precedent appends one entry per addition; the chain is the audit trail for count changes
    — **Done when:** chain shows `**124**` and ends with the #657 entry
    — **Consumers affected:** count-change audit trail
    — **Done:** Current count 123→124 + chain entry appended per #654 precedent; pulled forward with 2.1; files: README.md; fixes: none
- [x] **2.3** Update the Configuration category row `README.md:283`: `(3)` → `(4)`, add `civiltekk-install-assistant` to the member list, extend the description cell to cover skills/subagent catalog install assistance (parallel-restatement surface — update, don't duplicate; #648 rule)
    — **Why:** the category table is the catalog's front door; a listed count of 3 with 4 members fails the same drift class as a bare total
    — **Done when:** row reads `(4)`, names the new skill, and `grep -c "civiltekk-install-assistant" README.md` ≥ 1
    — **Consumers affected:** catalog discoverability
    — **Done:** Configuration row (3)→(4), member added, description cell extended; fixes: configuration_category_count_is_three red

### Phase 3: Global AGENTS.md enforcement (additive only)

- [x] **3.1** Append one `## Skill & Agent Installation` section to `deploy/.AGENTS.md` — 3-line router (user-scope installs and updates route through `civiltekk-install-assistant` when present; search the catalog before authoring; never hand-edit installed copies), procedure stays in the skill (pointer-only, drift-proof)
    — **Why:** global enforcement surface for user-scope installs; ticket scope requires exactly one additive section with zero modification of existing content
    — **Done when:** `git diff main...HEAD -- deploy/.AGENTS.md` shows only appended lines at end-of-file (no context-line rewrites); section is ≤4 lines of prose
    — **Consumers affected:** `~/.config/opencode/AGENTS.md` on next deploy; all deployed sessions
    — **Done:** Section appended after Memory Hygiene: 3 pointer-only prose lines + heading; diff proves append-only (zero removed lines), no existing content touched; files: deploy/.AGENTS.md; fixes: none

### Phase 4: Verification gates (no product edits — evidence only)

- [x] **4.1** Run `tests/test_skill_isolation.bats` (isolation contract: no `_common` refs, no path escapes, vendored-copy drift) and the registry-vs-disk suites (`tests/init.bats`, `tests/deploy_delegate.bats`) — all green
    — **Why:** mechanical enforcement of the two contracts this ticket touches (skill isolation; registry-sync-per-commit)
    — **Done when:** all three bats files exit 0
    — **Consumers affected:** CI parity
    — **Done:** test_skill_isolation.bats + init.bats + deploy_delegate.bats green (56 named tests ok, 0 fail) inside the full suite 642/642; fixes: none
- [x] **4.2** Number+verb sweep proving surface completeness: `grep -rnE "123 (ready-to-load|skills?|skill director|by category)|Current count: \*\*123\*\*" README.md deploy/setup.sh deploy/setup.ps1 opencode_app/README.md` → empty; `grep -c "civiltekk-install-assistant" README.md deploy/.AGENTS.md installer/registry.json` → ≥1 each; confirm `git diff main...HEAD --stat` touches only mapped files
    — **Why:** the blast-radius pattern's verification form — proves both failure classes (name-keyed and number-keyed) are clean and the diff matches the consumer map
    — **Done when:** sweep greps return expected results; diff file list == consumer-map first column minus the no-edit rows
    — **Consumers affected:** reviewers (Step 9 diff scope)
    — **Done:** Number+verb sweep clean across README.md/deploy/setup.sh/deploy/setup.ps1/opencode_app/README.md (surfaced the 5th surface README:220 at Phase 1, fixed there); name-grep >=1 in README.md + deploy/.AGENTS.md + registry.json; diff file list == consumer map (7 tracked files, no-edit rows proven); fixes: none

## Technical Notes

- Pattern precedents: `mcp-install-assistant-skill` (4-step assistant shape), `civiltekk-ponytail-audit-skill` (router + load-rules side files, METHOD-vs-VALUES split).
- Learned rules applied: `generated-artifact-unstaged-regen` (registry staged in Phase 1 commit), `skill-add-count-sync-blast-radius` (number-keyed sweep in 4.2), `command-description-parallel-restatement-drift` (README:261 chain + :283 description cell owned, not duplicated), `done-when-gate-escapes-its-phase` (every Done-when verifiable within its own phase).
- Docs note: md-only change — no docstrings to fill (documentation-inline skip), no coverage badges (README must not change after Step 9 review).
- No `dependency-map.json` entry (edges-only file — 0 standalone-skill hits); new skill joins no preset (`pack-*.json` untouched).

## Dependencies

None — standalone ticket (no `blocked-by:`).

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Registry stale vs disk (BT-157) | Regen + stage in the same Phase 1 commit (1.5); `tests/init.bats` + `deploy_delegate.bats` gate |
| Missed number-keyed count surface | 4.2 number+verb sweep across all four docs files; blast-radius pattern's 8-surface checklist mapped at authoring time |
| Frontmatter contract violation breaking the indexer | build-registry regen (1.5) fails loudly on malformed frontmatter — treated as a Phase 1 gate, not an afterthought |
| AGENTS.md edit leaking beyond append | 3.1 Done-when requires append-only diff; install route's wire-up block (1.3) carries the same rule for runtime use |
| Skill name/flag drift vs installer reality | 1.2 Done-when requires every command verified against `installer/init.mjs:11-26` |

## Trace

GATE a1e8011 tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a (Phase 1 evidence: full suite 642/642 after 1 gate-fix round — Phase 2 doc edits pulled in; registry regen skills=124; full tier: cross-module Consumer Map node registry.json + count anchors)
GATE ba95831 tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a (ticket exit gate, run on the phase-3 tree before its commit; bats 642/642 exit 0; registry skills=124 idempotent; sweep clean incl. 5th count surface README:220; AC1-AC7 PASS)
GATE 2e42b94 tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a (review-fix re-gate on the fixed tree; bats 642/642 exit 0; build-registry --check: no drift, skills=124; fixes: install.md target-destination table)
