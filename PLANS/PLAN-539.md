# PLAN: Add CONTRIBUTING.md for shared-repo contributors

**Branch**: feat/539
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/539
**Base**: main

## Acceptance Criteria

- [ ] Root `CONTRIBUTING.md` exists with sections: proposing changes, adding a skill/agent checklist, running tests, commit conventions, multi-target/portability note
- [ ] All contract content is by-reference (links to AGENTS.md/README.md sections) — no copied contract paragraphs
- [ ] README Support section links CONTRIBUTING.md (one line)
- [ ] Every internal link resolves (file-level links + section names; no fragile anchors)
- [ ] No catalog impact: skill/agent counts unchanged (146/34), pinned README literals untouched ("146 skill directories", "Configuration (2)", "ships 8 MCP server entries")

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `CONTRIBUTING.md` (new) | — | humans; GitHub auto-surfaces it on new PRs/issues | low — additive root file |
| `README.md` (one-line link in Support section, :140-147) | CONTRIBUTING.md exists | `test_markitdown_skill.bats` (:102 "N skill director(y|ies)" first-match == disk; :110 "Configuration (N)" == registry.json), `test_mcp_count_consistency.bats` (:39 "ships N MCP server entries" == mcp.servers count) — **pinned-literal adjacency**: additive line in a different section cannot rephrase them, but the exit gate must include both bats to prove it | low-med — README is test-consumed; edit is strictly additive |
| `AGENTS.md` (referenced only — NOT edited) | — | CONTRIBUTING.md links its sections | none — read-only reference |
| `skills/`, `agents/` | — | count guards (`test_count_drift.bats`, `test_markitdown_skill.bats`) | none — untouched; counts stay 146/34 |

## Implementation Phases

### Phase 1: Author CONTRIBUTING.md

- [x] **1.1** Write root `CONTRIBUTING.md` with five sections: (1) Proposing changes — link the bug/feature issue templates (`.github/ISSUE_TEMPLATE/`), small vs. structural changes; (2) Adding a skill or agent — checklist pointing at `AGENTS.md` § Adding Skills or Subagents — Sync Rules, § Skill / Agent Frontmatter Contract, and the Skill Isolation Contract (self-containment: `npx add` copies one directory; `tests/test_skill_isolation.bats` enforces); (3) Running the tests — `bats tests/` (bats-core submodule note), the count-drift and literal-pinning guards (never hand-edit counts in README/setup.sh); (4) Commit conventions — Conventional Commits, atomic commits; (5) Multi-target awareness — `--target` installs (claude/kimi/kilo/agents) and the portability contract (bash rule, `metadata.os`/`metadata.harness` vocabulary). Reference style: file-level links + `§ Section Name` prose (house style — no anchors; AGENTS.md headings contain em-dashes whose GitHub slugs are fragile).
    — **Why:** the ticket's entire deliverable — a contributor entry point that orients without duplicating maintainer docs
    — **Done when:** file exists; each of the five sections present; `grep -c "AGENTS.md" CONTRIBUTING.md` ≥ 3 (by-reference discipline is structural, not incidental)
    — **Consumers affected:** humans; GitHub UI (auto-links CONTRIBUTING.md on contribution surfaces)
    — **Done:** CONTRIBUTING.md written (5 sections + license note; §-name refs; no tables); 5 AGENTS.md links; fixes: none
- [x] **1.2** Verify by-reference discipline and link targets: for each section name CONTRIBUTING.md cites, grep the exact heading text in `AGENTS.md`/`README.md` (e.g. "Adding Skills or Subagents", "Skill / Agent Frontmatter Contract", "Portability contract"); confirm no contract table rows copied (sentinels: `| Key | Rule |` and `| Trigger | What to update |` absent from CONTRIBUTING.md, plus zero `^|` table lines anywhere in it — its five sections need no tables); `test -f` every file-level link target (.github/ISSUE_TEMPLATE/bug_report.yml, .github/ISSUE_TEMPLATE/feature_request.yml, tests/test_skill_isolation.bats, AGENTS.md, README.md)
    — **Why:** the AC's no-duplication rule must be mechanically checkable, not eyeballed; a wrong section reference ships a dead pointer
    — **Done when:** every cited section-name grep hits its file; both sentinel greps return zero matches in CONTRIBUTING.md
    — **Consumers affected:** none (verification step)
    — **Done:** heading greps 4/4, sentinels 0 (^| and table-header rows), test -f 6/6, isolation contract cited by name; fixes: none
- [x] **1.3** Commit Phase 1 (`docs(contributing): add contributor guide — by-reference orientation to AGENTS.md contracts`)
    — **Why:** atomic revertable unit; new file isolated from the README edit
    — **Done when:** commit exists; working tree clean
    — **Consumers affected:** none
    — **Done:** Phase 1 committed as 58eed84; fixes: none

### Phase 2: README link + exit gate (full tier)

- [ ] **2.1** Add one line to the README Support section (`## Support & reporting issues`, :140) linking `CONTRIBUTING.md` — placed after the issue-template bullets, phrased for the contributor audience ("Want to contribute a skill or agent? See CONTRIBUTING.md")
    — **Why:** completes the AC's discoverability requirement; the Support section is the natural second stop after reporting issues
    — **Done when:** `git diff origin/main...HEAD -- README.md` shows exactly one added line inside the Support section; pinned literals verified untouched, mirroring the bats regexes byte-for-byte: `grep -oE '[0-9]+ skill director(y|ies)' README.md | head -1` = 146; `grep -oE '\*\*Configuration\*\* \([0-9]+\)' README.md` = `**Configuration** (2)`; `grep -oE 'ships [0-9]+ MCP server entries' README.md` = `ships 8`
    — **Consumers affected:** humans; pinned-literal bats (additive-only edit — proven by gate)
- [ ] **2.2** Exit gate, full tier: (a) `bats tests/test_markitdown_skill.bats tests/test_mcp_count_consistency.bats tests/test_count_drift.bats tests/test_skill_isolation.bats tests/test_pack_permissions.bats` all green (the last is the fourth README-grepping consumer — fixed file list, can't match an additive link line, included so the gate matches the full README consumer set); (b) link-target greps from 1.2 re-run green; (c) `ls skills/ | grep -vc _archived` = 146 and `ls agents/*.md | wc -l` = 34 (untouched proof); (d) README diff is the single additive line
    — **Why:** ticket AC requires mechanical proof; the bats set is the complete consumer set of every touched file
    — **Done when:** all four green; any failure fixed before push
    — **Consumers affected:** pipeline gate memo
- [ ] **2.3** Write the `tier=full` gate memo into the Trace block, tick all AC boxes, commit and push
    — **Why:** Step 10's PR citation requires a green tier=full memo on the final pushed SHA
    — **Done when:** memo line present on the pushed SHA; PLAN fully ticked
    — **Consumers affected:** pr-workflow citation

## Technical Notes

- Section references use file-level links + `§ Name` prose, matching existing house style (README already cites `AGENTS.md` § Subagent Model Tiering this way) — no anchors, so no GitHub slug fragility.
- CONTRIBUTING.md is English-prose only; no frontmatter (it is not a skill — the Frontmatter Contract does not apply to it).
- No skills/agents are added or removed; all count guards must pass without modification. If a gate failure tempts a count edit, that is a bug in this change, not in the guards.

## Dependencies

None — no blocked-by tickets. All hard pipeline deps satisfied (plan-execution-skill, code-review-subagent, pr-workflow-subagent).

## Risks & Mitigation

- **Anchor/link rot** — mitigated by §-name references + the 1.2 mechanical grep of every cited heading.
- **Accidental contract duplication** — mitigated by sentinel greps (table-header rows) + Step 9 code review.
- **Pinned-literal regression via README edit** — mitigated by additive-only diff check (2.1) + the full bats set in 2.2.

## Trace

| Phase | Gate | Result | Notes |
|-------|------|--------|-------|
| 1 | light (1.2 mechanical checks) | green | GATE 58eed84 tier=light lint=- typecheck=- build=- unit=- e2e=n.a |
