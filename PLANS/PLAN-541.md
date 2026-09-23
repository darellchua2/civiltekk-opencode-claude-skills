# PLAN: Fix two dead AGENTS.md § references in README

**Branch**: feat/541
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/541
**Base**: main

## Acceptance Criteria

- [x] Both dead references fixed (§ Subagents at :329; §Knowledge Persistence at :346); no new dead references introduced
- [x] Mechanical sweep: grep every `AGENTS.md §` ref in README; each cited name matches a real AGENTS.md heading
- [x] Pinned literals untouched ("146 skill directories", "**Configuration** (2)", "ships 8 MCP server entries"); skill/agent counts 146/34 unchanged
- [x] README-consumer bats set green (test_markitdown_skill, test_mcp_count_consistency, test_count_drift, test_pack_permissions)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `README.md` (:329 one sentence rewritten; :346 § name retargeted) | — | `test_markitdown_skill.bats` (:102 skill-dir literal, :110 Configuration literal), `test_mcp_count_consistency.bats` (:39 ships-N literal), `test_pack_permissions.bats` (:174 greps README), `test_skill_isolation.bats` (:24 greps README for `skills/_common`) — set derived by grep census (`grep -rln README tests/`), not audit list; `test_count_drift.bats` is a count gate, not a README consumer. Edits are prose in the Agents `<details>` block and the memory section, far from every pinned literal; additive-replacement of two sentences cannot alter counts | low — 2 sentences in a test-consumed file, mechanically verified |
| `AGENTS.md` (referenced only — NOT edited) | — | README :329/:346 will point at its real headings | none — read-only |

## Implementation Phases

### Phase 1: Fix both references + full exit gate

- [x] **1.1** Rewrite the two sentences in the worktree README:
  - `:329` — replace `Full table with per-agent skills and delegation: `AGENTS.md` § Subagents.` with a truthful pointer: the trigger surface is each agent's `description` frontmatter in `agents/*.md`; per-class model assignments and delegation guidance: `AGENTS.md` § Subagent Model Tiering. (Heading exists: AGENTS.md:42 "Subagent Model Tiering (v2.0)".)
  - `:346` — replace `` `AGENTS.md` §Knowledge Persistence `` with `` `AGENTS.md` § Project Learnings `` (heading exists: AGENTS.md:120; its body carries exactly the v2 watch-list sentence).
    — **Why:** the ticket's entire deliverable — two dead pointers become truthful, resolving references
    — **Done when:** both lines edited; `grep -c '§ Subagents\b\|§Knowledge Persistence' README.md` = 0; new refs read `§ Subagent Model Tiering` and `§ Project Learnings`
    — **Consumers affected:** humans following the pointers
    — **Done:** both sentences rewritten; dead forms 0; new refs § Subagent Model Tiering + § Project Learnings; committed f61f368
- [x] **1.2** Mechanical sweep + full exit gate: (a) every `AGENTS.md § <name>` ref in README — extract each § name and require EXACTLY ONE AGENTS.md heading starting with it (uniqueness matters: "Subagent" alone would prefix-match two headings; 4 refs expected, all content-matched, line numbers not asserted); (b) pinned literals via bats-mirrored regexes = `146 skill directories` / `**Configuration** (2)` / `ships 8 MCP server entries`; (c) counts: `ls skills/ | grep -vc _archived` = 146, `ls agents/*.md | wc -l` = 34; (d) `bats tests/test_markitdown_skill.bats tests/test_mcp_count_consistency.bats tests/test_count_drift.bats tests/test_pack_permissions.bats tests/test_skill_isolation.bats` green (grep-census README consumers = markitdown, mcp_count, pack_permissions, skill_isolation; count_drift rides as the count gate); (e) `git diff origin/main -- README.md` touches exactly the two sentences
    — **Why:** AC requires mechanical proof; the bats set is the grep-census-complete README consumer set plus the count gate
    — **Done when:** all green; any failure fixed before push
    — **Consumers affected:** pipeline gate memo
    — **Done:** gate green: unique-prefix sweep 3/3 names (4 occurrences), literals 146/**Configuration** (2)/ships 8, counts 146/34, bats 5 files 37 tests exit 0, diff -2/+2
- [x] **1.3** Commit (`docs(readme): retarget two dead AGENTS.md section references`), write the `tier=full` gate memo into the Trace block, tick ACs, push
    — **Why:** PR citation requires a green tier=full memo on the pushed SHA
    — **Done when:** memo on pushed SHA; PLAN fully ticked
    — **Consumers affected:** pr-workflow citation
    — **Done:** tier=full memo on f61f368; all AC ticked

## Technical Notes

- `§ Subagent Model Tiering` resolves against heading "Subagent Model Tiering (v2.0)" — § name matching is heading-prefix WITH a uniqueness assertion (count of headings starting with the § name == 1), so an ambiguous short § name cannot first-match-green.
- No anchors used — house style is `§ Name` prose, immune to GitHub slug rules.

## Dependencies

None. Hard pipeline deps satisfied (plan-execution-skill, code-review-subagent, pr-workflow-subagent).

## Risks & Mitigation

- **Retarget semantics wrong** (§ Subagent Model Tiering doesn't answer the sentence's promise) — mitigated by plan review + sweep evidence.
- **Pinned-literal regression** — mitigated by regex-mirrored literal checks + full bats consumer set.

## Trace

| Phase | Gate | Result | Notes |
|-------|------|--------|-------|
| 1 | full (bats 5 files/37 tests + unique-prefix sweep + literals + counts + diff shape) | green | GATE f61f368 tier=full lint=t(bats) typecheck=- build=- unit=t(37/37) e2e=n.a |
