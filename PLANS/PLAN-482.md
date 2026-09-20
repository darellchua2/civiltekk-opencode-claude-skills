# PLAN: Rename v1 frontmatter action names (bash/task) to v2 (shell/subagent)

**Branch**: feat/482
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/482
**Base**: main

## Acceptance Criteria

- [ ] Probe result recorded for `bash`/`task` aliases on the current opencode version (both probes: v1-name-vs-tool, and v2-name enforcement)
- [ ] Rename applied across `agents/*.md`, installer consumers (`build-registry.mjs`, `init.mjs` kimi/claude/kilo translators), test literal, skill doc; registry rebuilt and committed
- [ ] Sync-rule sweep per AGENTS.md (agent counts/listings unchanged — verified, no doc edits needed)
- [ ] LEARNINGS entry with probe method and results

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `agents/*.md` frontmatter action names (34 files) | — | opencode runtime (deployed copies), `installer/build-registry.mjs` (delegatesTo), `installer/init.mjs` (kimi/claude/kilo translators), `tests/test_autoresearch_skills.bats:127`, `deploy/setup.sh` (copies verbatim) | med — mechanical rename but 3 code consumers key on the names |
| `installer/build-registry.mjs:182` (`ruleRes("task")`) | 2.1 | `installer/registry.json` delegatesTo/requiredBy edges, `npx add` dependency resolution | med — wrong lookup silently empties delegate edges |
| `installer/init.mjs` KIMI_TOOL_MAP / CLAUDE_TOOL_MAP / KILO_PERMISSION_TYPES | 2.1 | kimi/claude/kilo target installs (`npx add --target …`) | med — unmapped actions are dropped-with-warning |
| `tests/test_autoresearch_skills.bats:127` | 2.1 | CI bats gate | low |
| `skills/agent-introspection-debugging-skill/SKILL.md:42` | — | skill readers | low |
| `installer/registry.json` | 3.1 (lookup renamed) | registry consumers | low — expected empty diff |

## Implementation Phases

### Phase 1: Evidence

- [ ] **1.1** Run the v2-name enforcement probe in a throwaway project: temp agent with `action: shell, resource: '*', effect: deny` at `/tmp/opencode/probe-v2/.opencode/agents/probe-shell-v2.md` (mode: primary), then `timeout 120 opencode run --agent probe-shell-v2` instructed to execute `echo probe-ok`; delete the temp dir after
    — **Why:** distinguishes "alias mismatch" (rename restores enforcement) from "child sessions ignore agent rules wholesale" (anomalyco/opencode#50149 family) so the LEARNINGS entry and ticket close-out claim only what is true
    — **Done when:** verdict line `ENFORCED` (permission error) or `NOT_ENFORCED` (echo output) recorded under Technical Notes → Probe Evidence
    — **Consumers affected:** LEARNINGS entry (4.2), ticket close-out comment, #481 decision context

- [ ] **1.2** Confirm the complete consumer inventory with a widened sweep: literal `action: bash|action: task` AND string-key `["']task["']` / `["']bash["']` across `agents/ skills/ installer/ deploy/ tests/`, excluding bash-binary detection sites (`deploy/setup.sh:271-284`, `deploy/setup.ps1:1341`)
    — **Why:** value-level references (`ruleRes("task")`) evade literal greps — the pre-plan sweep already missed exactly one that way
    — **Done when:** inventory equals the Technical Notes list and the sweep surfaces no additional file
    — **Consumers affected:** scope of every Phase 2/3 step

### Phase 2: Source rename

- [ ] **2.1** Rename in all 34 `agents/*.md`: `action: bash` → `action: shell`; `action: task` → `action: subagent`
    — **Why:** opencode v2 exposes the shell tool under action `shell` and delegation under `subagent`; the v1 rules are proven inert (probe, session ses_f419ebf5effeFwc4mEhu0t2cP7: tool `shell` executed despite `action: bash deny`)
    — **Done when:** `grep -rn "action: bash\|action: task" agents/` returns 0 matches
    — **Consumers affected:** opencode runtime, build-registry.mjs, init.mjs translators, test_autoresearch_skills.bats

- [ ] **2.2** Update `tests/test_autoresearch_skills.bats:127` (`has('bash','*','deny')` → `has('shell','*','deny')`) plus any test-name/prose literals in that file referencing the old action
    — **Why:** the suite pins the frontmatter shape; leaving it red-fails the gate immediately after 2.1
    — **Done when:** no assertion-key `bash` references remain in the file
    — **Consumers affected:** CI bats gate

- [ ] **2.3** Update `skills/agent-introspection-debugging-skill/SKILL.md:42`: `(action: task)` → `(action: subagent)`
    — **Why:** docs must not re-teach the inert v1 name
    — **Done when:** `grep -rn "action: task" skills/` returns 0 matches
    — **Consumers affected:** skill readers

- [ ] **2.4** Zero-remaining sweep: repo-wide `grep -rn "action: bash\|action: task"` (excluding `.git`, `node_modules`, `_archived` if present) = 0 matches
    — **Why:** rename-completeness proof cited in the gate memo
    — **Done when:** grep output is empty
    — **Consumers affected:** none (verification only)

### Phase 3: Installer consumers

- [ ] **3.1** `installer/build-registry.mjs:182`: `ruleRes("task")` → `ruleRes("subagent")` (legacy `perm.task` map fallback at the same line stays — v1 map keys are a different format)
    — **Why:** delegatesTo/requiredBy edges key on the action name; the lookup must match post-rename sources or the registry silently loses every delegate edge
    — **Done when:** `grep -n 'ruleRes(' installer/build-registry.mjs` shows `subagent` and no `task` call
    — **Consumers affected:** registry.json, `npx add` dependency resolution

- [ ] **3.2** `installer/init.mjs`: KIMI_TOOL_MAP (line 923) `bash: "Bash"` → `shell: "Bash"`; CLAUDE_TOOL_MAP (line 979) `bash: "Bash"` → `shell: "Bash"` and `task: "Task"` → `subagent: "Task"`
    — **Why:** both translators drop rules whose action is absent from the map (`dropped.add` path) — post-rename sources would lose their shell/delegation rules on kimi/claude targets
    — **Done when:** both maps key on `shell`/`subagent`, zero `bash:`/`task:` keys
    — **Consumers affected:** kimi/claude target installs

- [ ] **3.3** `installer/init.mjs` `kiloAgentContent` (lines 1084-1103): normalize `shell`→`bash` and `subagent`→`task` before `KILO_PERMISSION_TYPES` membership, map emission, and narrowAllows bookkeeping (Kilo's native permission keys are the v1-style names)
    — **Why:** Kilo passthrough admits only set members; v2-named rules would all be dropped-with-warning, emptying the emitted `permission:` map
    — **Done when:** a `subagent deny` rule in a fixture emits `task: deny` in the Kilo frontmatter (verified via kilo_target.bats; update its expectations only if they pin action names)
    — **Consumers affected:** kilo target installs

- [ ] **3.4** Rebuild the registry (`node installer/build-registry.mjs`) and verify `git diff --stat installer/registry.json` is empty
    — **Why:** delegatesTo resources are unchanged by the rename when the lookup is correct — a non-empty diff means the lookup missed (fail signal, not a success artifact)
    — **Done when:** empty diff, or any diff explained and intentional in the commit message
    — **Consumers affected:** registry consumers

### Phase 4: Gates + LEARNINGS

- [ ] **4.1** Gate: run the affected bats suites — `tests/test_autoresearch_skills.bats tests/test_reviewer_no_writes.bats tests/agents_target.bats tests/kimi_target.bats tests/claude_target.bats tests/kilo_target.bats tests/test_pack_permissions.bats` — plus `node --check installer/init.mjs installer/build-registry.mjs`; record the GATE memo line
    — **Why:** repo verification policy — tests on logic changes (translators), build on installer changes (registry rebuild)
    — **Done when:** all suites green and both files parse; memo line `GATE <short-sha> …` recorded
    — **Consumers affected:** PR CI

- [ ] **4.2** Write `LEARNINGS/anti-patterns/v1-action-names-inert-under-v2.md` (probe method, both verdicts, alias-vs-inheritance distinction, fix sites, upstream refs anomalyco/opencode#50149 + #33223 family) and append the `_index.md` entry
    — **Why:** AC4; the two failure modes look identical from a single probe — the method that distinguishes them is the reusable part
    — **Done when:** file + index entry exist and reference issue #482
    — **Consumers affected:** future sessions

- [ ] **4.3** Sync-rule sweep per the AGENTS.md Adding Skills/Agents table: agent counts and listings are unchanged by a rename — verify count greps match the pre-rename baseline (34 agents listed; no README/setup.sh/ps1 listing edits required); commit all work with conventional commits and push
    — **Why:** the sync table triggers on listing changes; prove none occurred rather than silently skipping
    — **Done when:** counts match baseline; changes committed and pushed on `feat/482`
    — **Consumers affected:** docs readers

## Technical Notes

**Probe Evidence (pre-plan, session ses_f419ebf5effeFwc4mEhu0t2cP7):** spawned `code-review-subagent` (frontmatter `action: bash, resource: '*', effect: deny` at `agents/code-review-subagent.md:25-27`) instructed to run `git status --porcelain` — its tool is named `shell` and the command executed (exit 0). VERDICT: v1 `bash` deny inert. The 1.1 probe decides whether v2-named rules enforce at runtime on v2.0.11 or whether child-session rule application is wholesale-broken upstream (tie to anomalyco/opencode#50149).

**Inventory (from 1.2, pre-confirmed):**
- `agents/*.md` — 34 files, `action: bash` + `action: task` occurrences
- `installer/build-registry.mjs:182` — `ruleRes("task")` string-key reference
- `installer/init.mjs` — KIMI_TOOL_MAP:923, CLAUDE_TOOL_MAP:979, KILO_PERMISSION_TYPES:1057 + emission at 1090-1097
- `tests/test_autoresearch_skills.bats:127` — assertion key `bash`
- `skills/agent-introspection-debugging-skill/SKILL.md:42` — doc mention `(action: task)`
- NOT consumers (bash-binary detection): `deploy/setup.sh:271-284`, `deploy/setup.ps1:1341`
- NOT affected: `tests/test_reviewer_no_writes.bats` (pins `edit` — name unchanged in v2); `installer/init.mjs:838/894` already use v2 `subagent`

**Redeploy (post-merge, orchestrator-owned — NOT a PLAN step):** run `./deploy/setup.sh` in the main checkout after merge and verify deployed `~/.config/opencode/agents/*.md` frontmatter carries v2 names; note in the ticket close-out.

## Dependencies

- None (`blocked-by:` absent). Related: #481 (same investigation session — its workaround decision is independent), upstream anomalyco/opencode#50149.

## Risks & Mitigation

- **Post-rename enforcement may still be broken upstream** (child-session rule application). Mitigation: probe 1.1 records the verdict; LEARNINGS and ticket wording claim only what the probe proved.
- **kilo_target.bats may pin emitted permission keys.** Mitigation: run the suite in 4.1; update expectations only where they pin action names, in the same commit as 3.3.
- **Registry diff non-empty after rebuild.** Mitigation: 3.4 treats non-empty diff as a fail signal — inspect before committing.
