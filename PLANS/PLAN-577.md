# PLAN: pi has no agents concept — fix the ~/.agents/agents claim

**Branch**: feat/577
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/577
**Base**: main (aa62a4f)

## Acceptance Criteria

- [ ] Zero remaining unsplit "Kimi Code and pi" claims (census grep clean; the accurate `.agents/skills/` "discovered by OpenCode and pi" claims elsewhere stay untouched)
- [ ] `--help` renders the new wording (template-literal safe — no backticks)
- [ ] Full `bats tests/` green (docs-only change; no behavior)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `AGENTS.md:10` claim parenthetical | — | contributors reading the isolation/install contract | none |
| `README.md:46` target-table row | — | users choosing `--target agents` | none |
| `installer/init.mjs:1718` help text | — | CLI users (template literal — wording must stay backtick-free) | low |
| `tests/agents_target.bats:3` comment | — | suite readers | none |

Docs-only; no code behavior. Census on main found exactly 4 sites; the separate, accurate ".agents/skills/ … discovered by OpenCode and pi" claims (AGENTS.md bullet 3, README) are out of scope and must remain.

## Implementation Phases

### Phase 1: wording split at all 4 sites

- [ ] **1.1** Edit the four claim sites to split skills vs agents: AGENTS.md:10 → "(skills read by Kimi Code and pi, agents read by Kimi Code only — pi has no agents concept; verbatim copies, agents model-unpinned)"; README.md:46 row → "Cross-tool shared dir — skills read by Kimi Code and pi, agents Kimi-only (pi has no agents concept); verbatim copies"; installer/init.mjs:1718 → "(skills scanned by Kimi Code and pi, agents by Kimi Code only — pi has no agents concept; files are verbatim, agents stay model-unpinned)"; tests/agents_target.bats:3 comment → "(skills read by Kimi Code and pi, agents Kimi-only)".
    — **Why:** the agents/ half of the claim overstates pi (docs review 2026-09-26: no agents concept, no `~/.agents/agents/` reading); the skills/ half is doc-verified correct.
    — **Done when:** census `grep -rn 'Kimi Code and pi'` returns only split-wording lines; `node --check` passes; `--help` prints the new text; the accurate `.agents/skills/` claims are untouched.
    — **Consumers affected:** docs/help readers; no runtime behavior.
- [ ] **1.2** Full exit gate `bats tests/`.
    — **Why:** ticket exit gate — full tier; help text changed.
    — **Done when:** exit 0; `GATE <short-sha> tier=full` in the trace.
    — **Consumers affected:** Step 9/10 citations.

## Technical Notes

- Help text lives in a backtick template literal — new wording must avoid backticks (learned in #564: backticks inside printHelp terminate the literal).
- pi facts pinned by this change: skills discovery = Agent Skills locations `~/.agents/skills/` + `.agents/skills/` (project: ancestors to repo root, trust-gated); instructions = AGENTS.md context files; no agents/subagents mechanism (pi.dev/docs/latest: configuration, skills, settings, security, how-pi-works).

## Dependencies

None (no `blocked-by:`).

## Risks & Mitigation

- None material — prose-only; the only executable file touched is help text inside a template literal (guarded by `node --check` + `--help` render check).

## Gate Trace
