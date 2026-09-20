# PLAN: Rename v1 frontmatter action names (bash/task) to v2 (shell/subagent)

**Branch**: feat/482
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/482
**Base**: main
**Revision**: 2 — architecture review + Mode R rulings applied (probe matrix, README doc sites, `--check` gate)

## Acceptance Criteria

- [ ] Probe result recorded for `bash`/`task` aliases on the current opencode version — BOTH cells: v1-alias (done pre-plan, inert) and v2-name enforcement in BOTH session shapes (top-level and child-spawn)
- [ ] Rename applied across `agents/*.md`, installer consumers (`build-registry.mjs`, `init.mjs` kimi/claude/kilo translators), test literal, skill doc, and the two README teaching sites; registry gate passes via `--check`
- [ ] Sync-rule sweep per AGENTS.md (agent counts/listings unchanged — verified, no listing edits needed)
- [ ] LEARNINGS entry with probe method and results; any "rename restores subagent deny enforcement" wording gated on the child-spawn ENFORCED verdict specifically

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `agents/*.md` frontmatter action names (34 files) | — | opencode runtime (deployed copies), `installer/build-registry.mjs` (delegatesTo), `installer/init.mjs` (kimi/claude/kilo translators), `tests/test_autoresearch_skills.bats:127`, `deploy/setup.sh` (copies verbatim) | med — mechanical rename but 3 code consumers key on the names |
| `installer/build-registry.mjs:182` (`ruleRes("task")`) | 2.1 | `installer/registry.json` delegatesTo/requiredBy edges, `npx add` dependency resolution | med — wrong lookup silently empties delegate edges |
| `installer/init.mjs` KIMI_TOOL_MAP / CLAUDE_TOOL_MAP / KILO_PERMISSION_TYPES | 2.1 | kimi/claude/kilo target installs (`npx add --target …`) | med — unmapped actions are dropped-with-warning |
| `tests/test_autoresearch_skills.bats:127` | 2.1 | CI bats gate | low |
| `skills/agent-introspection-debugging-skill/SKILL.md:42` | — | skill readers | low |
| `README.md:263` + `opencode_app/README.md:183` (teach `action:"task"`) | — | readers configuring subagent allowlists | med — stale teaching re-propagates the inert spelling (LEARNINGS frontmatter-shape-change-blast-radius class 5) |
| `installer/registry.json` | 3.1 (lookup renamed) | registry consumers | low — content-neutral when lookup matches (generatedAt excluded via `--check`) |

## Implementation Phases

### Phase 1: Evidence

- [x] **1.1** Run the v2-name enforcement probe as TWO cells in one throwaway project (`/tmp/opencode/probe-v2/`): (a) top-level — temp agent `probe-shell-v2.md` (mode: primary, `action: shell, resource: '*', effect: deny`), `timeout 120 opencode run --agent probe-shell-v2` instructed to `echo probe-ok`; (b) child-spawn — a top-level run whose parent prompt instructs it to spawn a second probe agent (mode: subagent, same v2 deny rule) that runs `echo probe-ok`; record BOTH verdict lines (top-level ENFORCED/NOT_ENFORCED, child-spawn ENFORCED/NOT_ENFORCED); delete the temp project after
    — **Why:** the incident and every deny rule's deployed purpose are child-spawn-shaped; a top-level ENFORCED verdict alone cannot distinguish "alias fixed" from "child-session rules wholesale broken upstream" (#50149 family) — the child cell is the only one that licenses the restoration claim
    — **Done when:** both verdict lines recorded under Technical Notes → Probe Evidence
    — **Consumers affected:** LEARNINGS entry (4.2), ticket close-out, #481 decision context
    — **Done:** Cell B (top-level `opencode run`): NOT APPLICABLE — the CLI session shape is Code Mode with no shell tool at all (`Unknown tool 'shell'`); denial unmeasurable there. Cell C (child-spawn, agent harness): **ENFORCED** — v2-named `shell` deny removed the tool from the child session's toolset entirely (tool-list filtering; probe could not execute). Temp project + probe agent deleted; main checkout verified clean. files: /tmp only (removed); fixes: none

- [x] **1.2** Confirm the complete consumer inventory with a widened sweep: form-insensitive pattern `action:?\s*["']?\s*(bash|task)` across `agents/ skills/ installer/ deploy/ tests/` PLUS repo-root `*.md` and `opencode_app/`, and string-key `["']task["']` / `["']bash["']` across `installer/ deploy/ tests/`; exclusions: bash-binary detection (`deploy/setup.sh:271-284`, `deploy/setup.ps1:1341`) and migration-narrative mentions (`agents/opencode-v2-migration-subagent.md:117-118` documents the v1→v2 translation itself — keep verbatim)
    — **Why:** value-level references (`ruleRes("task")`) evade literal greps, and directory-scoped sweeps miss repo-root docs that teach the spelling (README.md:263, opencode_app/README.md:183) — both misses already happened in pre-plan scoping
    — **Done when:** inventory equals the Technical Notes list and the sweep surfaces no additional file
    — **Consumers affected:** scope of every Phase 2/3 step
    — **Done:** form-insensitive sweep run — 34 agent files (incl. body examples in opencode-tooling/pr-workflow/discovery/code-review), README.md + opencode_app/README.md (1 each), skills/agent-introspection-debugging-skill (1), plus string-key refs (build-registry.mjs:182, init.mjs maps) from the pre-plan grep — inventory confirmed, zero new files. Meta-doc carve-outs recorded for 2.4: PLANS/PLAN-482.md and the LEARNINGS entries documenting this change legitimately quote the old names. files: none; fixes: none

### Phase 2: Source rename

- [x] **2.1** Rename in all 34 `agents/*.md`: `action: bash` → `action: shell`; `action: task` → `action: subagent` (includes agent-body fenced examples, e.g. `opencode-tooling-subagent.md:173-185,363-379`)
    — **Why:** opencode v2 exposes the shell tool under action `shell` and delegation under `subagent`; the v1 rules are proven inert (probe, session ses_f419ebf5effeFwc4mEhu0t2cP7: tool `shell` executed despite `action: bash deny`)
    — **Done when:** form-insensitive grep over `agents/` (pattern from 1.2) returns only the excluded migration-narrative file
    — **Consumers affected:** opencode runtime, build-registry.mjs, init.mjs translators, test_autoresearch_skills.bats
    — **Done:** sed rename across 34 agents/*.md (incl. body fenced examples); form-insensitive grep over agents/ returns only the excluded migration-narrative file; files: agents/*.md; fixes: none

- [x] **2.2** Update `tests/test_autoresearch_skills.bats:127` (`has('bash','*','deny')` → `has('shell','*','deny')`) plus any test-name/prose literals in that file referencing the old action
    — **Why:** the suite pins the frontmatter shape; leaving it red-fails the gate immediately after 2.1
    — **Done when:** no assertion-key `bash` references remain in the file
    — **Consumers affected:** CI bats gate
    — **Done:** assertion key bash→shell at tests/test_autoresearch_skills.bats:127; no assertion-key bash refs remain; files: tests/test_autoresearch_skills.bats; fixes: none

- [x] **2.3** Update `skills/agent-introspection-debugging-skill/SKILL.md:42`: `(action: task)` → `(action: subagent)`
    — **Why:** docs must not re-teach the inert v1 name
    — **Done when:** form-insensitive grep over `skills/` returns 0 matches
    — **Consumers affected:** skill readers
    — **Done:** doc mentions updated at SKILL.md:42 (action: subagent) and :46 (shell: deny row); files: skills/agent-introspection-debugging-skill/SKILL.md; fixes: none

- [x] **2.4** Zero-remaining sweep: repo-wide form-insensitive grep `action:?\s*["']?\s*(bash|task)` (excluding `.git`, `node_modules`, and the 1.2 exclusion list) = 0 matches
    — **Why:** rename-completeness proof cited in the gate memo; the form-insensitive pattern is required — the plain `action: task` form never matches the quoted `action:"task"` spelling and would pass vacuously
    — **Done when:** grep output is empty
    — **Consumers affected:** none (verification only)
    — **Done:** form-insensitive sweep excluding carve-outs (migration narrative, PLANS/PLAN-482.md, LEARNINGS/) = 0 matches (grep exit 1); files: none; fixes: none

- [x] **2.5** Update the two README teaching sites: `README.md:263` and `opencode_app/README.md:183`: `action:"task"` → `action:"subagent"`
    — **Why:** both teach readers to write present-tense config with the proven-inert v1 name — the exact bug class AC2's "every in-repo consumer" covers (Mode R ruling 1; LEARNINGS frontmatter-shape-change-blast-radius class 5)
    — **Done when:** form-insensitive grep over both files returns 0 matches (aside from unrelated prose)
    — **Consumers affected:** readers configuring subagent allowlists
    — **Done:** README.md:263 and opencode_app/README.md:183 teach action:"subagent" now; files: README.md, opencode_app/README.md; fixes: none

### Phase 3: Installer consumers

- [x] **3.1** `installer/build-registry.mjs:182`: `ruleRes("task")` → `ruleRes("subagent")` (legacy `perm.task` map fallback at the same line stays — v1 map keys are a different format)
    — **Why:** delegatesTo/requiredBy edges key on the action name; the lookup must match post-rename sources or the registry silently loses every delegate edge
    — **Done when:** `grep -n 'ruleRes(' installer/build-registry.mjs` shows `subagent` and no `task` call
    — **Consumers affected:** registry.json, `npx add` dependency resolution
    — **Done:** ruleRes("subagent") live, legacy perm.task fallback kept; registry --check: agents=34 no drift; files: installer/build-registry.mjs; fixes: none

- [x] **3.2** `installer/init.mjs`: KIMI_TOOL_MAP (line 923) `bash: "Bash"` → `shell: "Bash"`; CLAUDE_TOOL_MAP (line 979) `bash: "Bash"` → `shell: "Bash"` and `task: "Task"` → `subagent: "Task"`; update the stale comment at :977-978 ("`task` gates subagent delegation — corpus-inert today") to the post-rename reality
    — **Why:** both translators drop rules whose action is absent from the map (`dropped.add` path) — post-rename sources would lose their shell/delegation rules on kimi/claude targets; comments that contradict the code rot into traps
    — **Done when:** both maps key on `shell`/`subagent`, zero `bash:`/`task:` keys, comments accurate
    — **Consumers affected:** kimi/claude target installs
    — **Done:** KIMI map keys shell:"Bash"; CLAUDE map shell:"Bash" + subagent:"Task"; :977-978 comment updated to post-rename reality; files: installer/init.mjs; fixes: none

- [x] **3.3** `installer/init.mjs` `kiloAgentContent` (lines 1084-1103): normalize `shell`→`bash` and `subagent`→`task` before `KILO_PERMISSION_TYPES` membership (:1090/:1092), map emission (:1097), and narrowAllows bookkeeping (:1093); update the stale comment at :1055-1056 ("action names match Kilo's `permission` type names 1:1" — no longer true for v2 names)
    — **Why:** Kilo passthrough admits only set members; v2-named rules would all be dropped-with-warning, emptying the emitted `permission:` map
    — **Done when:** a `subagent deny` rule in a fixture emits `task: deny` in the Kilo frontmatter (kilo_target.bats:29/:44 pin emitted keys `task: deny` / `bash: ask` — they stay green only with normalization and double as regression tripwires)
    — **Consumers affected:** kilo target installs
    — **Done:** kiloKey alias (shell→bash, subagent→task) applied at membership/emission/narrowAllows; :1055-1056 comment updated; kilo_target.bats emitted-key pins green; files: installer/init.mjs; fixes: none

- [x] **3.4** Registry gate: `node installer/build-registry.mjs --check` exits 0 (NOT plain-run + empty-diff — a plain rebuild always restamps `generatedAt` at :238/:258, making an empty diff unsatisfiable; #416 recurrence class)
    — **Why:** the `--check` form is the prescribed gate; it verifies the lookup produces identical registry content modulo the timestamp
    — **Done when:** `--check` exits 0; if it reports drift, inspect and either fix the lookup or commit the intentional diff with explanation
    — **Consumers affected:** registry consumers
    — **Done:** node installer/build-registry.mjs --check exits 0 ("registry OK (agents=34, skills=146, no drift)"); files: none; fixes: none

### Phase 4: Gates + LEARNINGS

- [ ] **4.1** Gate: run the affected bats suites — `tests/test_autoresearch_skills.bats tests/test_reviewer_no_writes.bats tests/agents_target.bats tests/kimi_target.bats tests/claude_target.bats tests/kilo_target.bats tests/test_pack_permissions.bats` — plus `node --check installer/init.mjs installer/build-registry.mjs`; record the GATE memo line
    — **Why:** repo verification policy — tests on logic changes (translators), build on installer changes (registry gate)
    — **Done when:** all suites green and both files parse; memo line `GATE <short-sha> …` recorded
    — **Consumers affected:** PR CI

- [ ] **4.2** Write `LEARNINGS/anti-patterns/v1-action-names-inert-under-v2.md` (probe method as a 2×2 matrix — rule-name version × session shape — with both cells' verdicts, alias-vs-inheritance distinction, fix sites, upstream refs anomalyco/opencode#50149 + #33223 family) and append the `_index.md` entry; any claim that the rename restores subagent deny enforcement is gated on the child-spawn ENFORCED verdict specifically (Mode R ruling 2)
    — **Why:** AC4; the failure modes look identical from a single probe cell — the matrix method is the reusable part
    — **Done when:** file + index entry exist, reference issue #482, and the enforcement claim matches the recorded child-spawn verdict
    — **Consumers affected:** future sessions

- [ ] **4.3** Sync-rule sweep per the AGENTS.md Adding Skills/Agents table: agent counts and listings are unchanged by a rename — verify count greps match the pre-rename baseline (34 agents listed; no README/setup.sh/ps1 listing edits required — README edits in 2.5 are teaching-text only, not listing changes); land 2.x + 3.1 atomically (single commit or immediately adjacent commits in one push — an intermediate state with v2 sources against the v1 lookup silently empties delegate edges on rebuild); commit all work with conventional commits and push
    — **Why:** the sync table triggers on listing changes; prove none occurred rather than silently skipping; atomicity prevents a transiently broken registry state
    — **Done when:** counts match baseline; changes committed and pushed on `feat/482`
    — **Consumers affected:** docs readers, registry rebuilders

## Technical Notes

**Probe Evidence (all cells recorded):**
- **Cell A** (v1 `bash` name, child-spawn): **INERT** — pre-plan, session ses_f419ebf5effeFwc4mEhu0t2cP7: `code-review-subagent` (frontmatter `action: bash deny`) had its `shell` tool present and it executed `git status --porcelain` (exit 0).
- **Cell B** (v2 `shell` name, top-level `opencode run --agent`): **NOT APPLICABLE** — the CLI session runs Code Mode with no shell tool in the catalog (`Unknown tool 'shell'`); enforcement unmeasurable in that shape.
- **Cell C** (v2 `shell` name, child-spawn via agent harness): **ENFORCED** — session ses_f41753befffeWYiwlqTFFLIoFk: probe subagent (mode: subagent, `action: shell, resource: '*', effect: deny`) received NO shell/bash tool in its tool list at all (filtered away); command could not be attempted. Enforcement mechanism = tool-list filtering.

**Attribution (per Mode R ruling 2):** child-spawn cell ENFORCED with the v2 name vs INERT with the v1 name, same harness, same shape → the rename restores subagent deny enforcement on opencode v2.0.11. Claim licensed for 4.2 LEARNINGS and ticket close-out. 1.1 verdicts recorded at execution time (above).

**Inventory (from 1.2, pre-confirmed + review-widened):**
- `agents/*.md` — 34 files, `action: bash` + `action: task` occurrences (incl. body fenced examples in `opencode-tooling-subagent.md:173-185,363-379`)
- `installer/build-registry.mjs:182` — `ruleRes("task")` string-key reference
- `installer/init.mjs` — KIMI_TOOL_MAP:923, CLAUDE_TOOL_MAP:979, KILO_PERMISSION_TYPES:1057 + emission at 1090-1097; stale comments :977-978, :1055-1056
- `tests/test_autoresearch_skills.bats:127` — assertion key `bash`
- `skills/agent-introspection-debugging-skill/SKILL.md:42` — doc mention `(action: task)`
- `README.md:263` + `opencode_app/README.md:183` — teach `action:"task"` (Mode R ruling 1)
- EXCLUDED: bash-binary detection (`deploy/setup.sh:271-284`, `deploy/setup.ps1:1341`); migration narrative (`agents/opencode-v2-migration-subagent.md:117-118` — documents the translation itself; MIGRATION.md and deploy/.AGENTS.md verified clean)
- NOT affected: `tests/test_reviewer_no_writes.bats` (pins `edit` — name unchanged in v2); `installer/init.mjs:838/894` already use v2 `subagent`; `parsePermissionRules` (:1040-1053) is action-agnostic

**Redeploy (post-merge, orchestrator-owned — NOT a PLAN step):** run `./deploy/setup.sh` in the main checkout after merge and verify deployed `~/.config/opencode/agents/*.md` frontmatter carries v2 names; note in the ticket close-out.

## Dependencies

- None (`blocked-by:` absent). Related: #481 (same investigation session — its workaround decision is independent), upstream anomalyco/opencode#50149.

## Risks & Mitigation

- **Post-rename enforcement may still be broken upstream** (child-session rule application). Mitigation: 1.1's child-spawn cell records the verdict; LEARNINGS and ticket wording claim only what that cell proved.
- **kilo_target.bats pins emitted permission keys** (:29 `task: deny`, :44 `bash: ask`). Mitigation: they stay green only with 3.3 normalization — they are the regression tripwire; update expectations only if semantics change, in the same commit.
- **Transient v2-sources/v1-lookup state.** Mitigation: 4.3 lands 2.x + 3.1 atomically.

| Gate | Phase 1 (evidence-only: no source modified) |

|------|-------------|

`GATE 5cf1a4e lint=n.a. typecheck=n.a. build=n.a. unit=n.a. e2e=n.a` — evidence phase; no code touched.

`GATE 5cf1a4e+p2 lint=n.a. typecheck=n.a. build=n.a. unit=t(16/16: autoresearch_skills, reviewer_no_writes) e2e=n.a` — frontmatter suites green; translator suites deferred to Phase 3 gate where their fixes land (push deferred with them per atomicity rule).

`GATE 1428225+p3 lint=n.a. typecheck=t(node --check ×2) build=t(registry --check, no drift) unit=t(74/74 across 7 suites) e2e=n.a`
