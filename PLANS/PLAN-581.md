# PLAN: Portability phase 2 — zcode/copilot + kimi/kilo targets

**Branch**: feat/581
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/581
**Base**: main

## Acceptance Criteria
- [ ] `--target zcode` installs a translated code-review-subagent to `~/.zcode/agents/` (synthesized `name:`, camelCase `maxTurns` from `steps`, no `model:` pin, `tools:`/`disallowedTools:` translated) and composes the zcode overlay
- [ ] `--target copilot --project` writes `.github/agents/` with claude-format frontmatter
- [ ] kimi/kilo composed output for the 3 pilots carries target-appropriate delegation bindings
- [ ] Orphan guard accepts the new suffixes; contract/landscape docs move zcode/copilot to composable
- [ ] New target test suites green; full bats green; registry `--check` clean; README/AGENTS target docs updated

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` (ZCODE map, `zcodeAgentContent`, TARGETS rows zcode/copilot, probes, help text) | — | CLI (`--target zcode|copilot`), `tests/zcode_target.bats`, `tests/copilot_target.bats`, update/remove paths (generic over TARGETS), `deploy/setup.sh` RESOLVER_CONFIG_ONLY routing | high |
| `installer/overlay.mjs` (`COMPOSABLE_TARGETS` + zcode/copilot) | TARGETS rows exist (1.2) | all four write sites, bats guards | medium |
| `agents/overlays/*.{kimi,kilo}.md` (6 new) | contract doc update (3.1) | composition for kimi/kilo targets, orphan guard | low |
| `tests/agent_lcd_pilot.bats` (orphan list + kimi/kilo binding assertions) | overlays (3.1), helper (1.3) | CI | low |
| `tests/zcode_target.bats`, `tests/copilot_target.bats` (new) | 1.x/2.x | CI | low |
| `docs/subagent-portability-contract.md` + `docs/harness-landscape-2026-09.md` (matrix + planned-targets) | 1.x/2.x shipped | future authoring; issue #581 AC 4 | low |
| `README.md` + `AGENTS.md` (target docs) | 1.2/2.1 | repo readers; documentation-sync rules | low |

## Implementation Phases

### Phase 1: zcode target
- [ ] **1.1** Add `ZCODE_TOOL_MAP` (opencode action → ZCode tool name; identical values to `CLAUDE_TOOL_MAP` — ZCode's built-ins are Read/Grep/Glob/Bash/Edit/Write/WebFetch/WebSearch/Task) and `zcodeAgentContent(content, stem, warn)` mirroring `claudeAgentContent`: synthesize `name: <stem>`, translate `*`-resource allow/deny rules into `tools:`/`disallowedTools:` (deny wins, drop ask/globbed/skill/question with warning), and rewrite the `steps:` frontmatter key to ZCode's `maxTurns:`; never emit `model:` (ZCode default = inherit); leave `mode`/`permissions`/`category` in place (ZCode ignores unknown fields)
    — **Why:** The zcode target's core translation; mirroring the claude fn keeps one reviewable pattern and reuses `parsePermissionRules`
    — **Done when:** Function in `installer/init.mjs` beside the sibling translators; `node --check` clean; unit-verified in 5.1
    — **Consumers affected:** writeUserScopeInstall + writeInstall zcode rows (1.2), tests 5.1
- [ ] **1.2** Add consts (`USER_ZCODE_AGENTS`/`USER_ZCODE_SKILLS` = `~/.zcode/{agents,skills}`), TARGETS row `zcode: { agentsDir, skillsDir, projectAgentsDir: ".zcode/agents", projectSkillsDir: ".zcode/skills", agentMode: "zcode-translate", skillMode: "verbatim" }`, wire `"zcode-translate"` into all three agentMode chains (user add loop, project install, update would-content), add the `~/.zcode` auto-probe, and extend `--help`/`printHelp` target list
    — **Why:** A target row without chain wiring silently writes untranslated bytes (the #576 exit-gate bug class — all three chains get it on day one)
    — **Done when:** `--target zcode --yes` add of code-review-subagent writes `~/.zcode/agents/code-review-subagent.md` containing `name:`, `maxTurns:`, `tools:` and no `model:` line
    — **Consumers affected:** CLI users; tests 5.1; update/remove (generic over TARGETS)
- [ ] **1.3** Add `"zcode"` to `COMPOSABLE_TARGETS` in `installer/overlay.mjs` and to the orphan-guard case list in `tests/agent_lcd_pilot.bats`
    — **Why:** An unwired COMPOSABLE_TARGETS omits zcode from composition (LCD-only installs); an unguarded suffix flips the orphan test to red the moment a zcode overlay lands (3.1)
    — **Done when:** Helper composes `code-review-subagent.opencode.md`… and `.zcode.md` once 3.1 lands; orphan test green with zcode suffixes present
    — **Consumers affected:** all write sites; bats guards
- [ ] **1.4** Write 3 zcode overlays (`agents/overlays/{code-review,image-analyzer,requirements-specialist}-subagent.zcode.md`): nesting ban ("ZCode forbids subagents spawning subagents — do delegation work inline"), no memory tool (LEARNINGS glob fallback), `$skill-name` invocation hint, MCP-only-at-session-start caveat where relevant
    — **Why:** ZCode-specific ergonomics the cores must not carry (contract §Overlay convention); without them zcode installs are LCD-only despite being composable
    — **Done when:** 3 files exist; helper composes them (manual `tests/fixtures/compose_agent.mjs` spot check)
    — **Consumers affected:** zcode installs; guard suite

### Phase 2: copilot target
- [ ] **2.1** Add consts (`USER_COPILOT_AGENTS` = `~/.copilot/agents`), TARGETS row `copilot: { agentsDir, skillsDir: null, projectAgentsDir: ".github/agents", projectSkillsDir: ".github/skills", agentMode: "claude-translate", skillMode: "verbatim" }`, `~/.copilot` auto-probe, help-text entry; extend Phase-1 chain wiring to cover the copilot row (the chains key off `cfg.agentMode`, so `"claude-translate"` reuse must be verified in all three sites, not assumed)
    — **Why:** Fills the project-scope Copilot gap (user scope already covered via `~/.claude/agents` by the claude target); null `skillsDir` must be proven safe in the user-add loop's `if (cfg.skillsDir)` guard
    — **Done when:** `--target copilot --project --yes` writes `.github/agents/code-review-subagent.md` (claude-format frontmatter) and `.github/skills/` for skills; user-scope add writes `~/.copilot/agents/` and no skills dir
    — **Consumers affected:** CLI users; tests 5.2

### Phase 3: kimi/kilo overlays + guard updates
- [ ] **3.1** Write 6 kimi/kilo overlays (`agents/overlays/{3 pilots}.{kimi,kilo}.md`): Kilo — task-tool/`@mention` delegation, `permission.task` grant note; Kimi — delegate by agent name via the Task tool, agents installed at `~/.kimi-code/agents`; both — no memory tool (LEARNINGS glob fallback), no mid-run clarification channel
    — **Why:** AC 3 — kimi/kilo currently install LCD-only; the overlays are the last leg of "3 pilots fully bound" and the orphan list from 1.3 expects these suffixes
    — **Done when:** 6 files exist; `tests/agent_lcd_pilot.bats` kimi/kilo composition tests flip from "untouched core" to "core + binding present" (5.3)
    — **Consumers affected:** kimi/kilo installs; guard suite
- [ ] **3.2** Update `tests/agent_lcd_pilot.bats`: orphan-guard case list (+`zcode|copilot`), kimi/kilo test reworded from byte-identical-core to binding-present assertions
    — **Why:** The kimi/kilo test asserts the ABSENCE of overlays — it must flip in the same commit as 3.1 or the suite goes red
    — **Done when:** Full guard file green
    — **Consumers affected:** CI

### Phase 4: docs
- [ ] **4.1** `docs/subagent-portability-contract.md`: binding matrix — zcode/copilot move to Composable (zcode with "no nested subagents" caveat retained; copilot notes claude-translate reuse); documented-only shrinks to codex/pi/M365; pilot-coverage table rows updated; `.zcode.md`/`.copilot.md` overlay validity stated
    — **Why:** The matrix is the contract's normative core — it must match shipped reality or the orphan guard and docs disagree
    — **Done when:** Matrix, documented-only list, and pilot table all reflect 6 composable targets
    — **Consumers affected:** issue #581 AC 4; future authoring
- [ ] **4.2** `docs/harness-landscape-2026-09.md`: "Planned targets — not composable" section rewritten as shipped (zcode/copilot rows landed; pi/codex/M365 remain documented-only with reasons)
    — **Why:** The landscape doc explicitly promises this flip ("Portability phase 2 follow-up")
    — **Done when:** Section states zcode/copilot are composable targets as of #581
    — **Consumers affected:** docs readers; contract doc cross-ref
- [ ] **4.3** `README.md` target table + `AGENTS.md` §Repository Purpose bullet: add `--target zcode` (`~/.zcode/{agents,skills}/` user, `.zcode/{agents,skills}/` project, zcode-translate: camelCase keys, `maxTurns`←`steps`, nesting-ban caveat) and `--target copilot` (`~/.copilot/agents/` user + `.github/{agents,skills}/` project, claude-translate reuse)
    — **Why:** documentation-sync rules — new user-facing targets must appear in both surfaces; #579 just taught the AGENTS.md bullet to be precise about target readers
    — **Done when:** Both surfaces name the new targets with accurate paths and translation notes
    — **Consumers affected:** repo readers; documentation-consistency checks

### Phase 5: tests + verification gate
- [ ] **5.1** `tests/zcode_target.bats` (mirror `kimi_target.bats` structure): help lists zcode; user-scope add writes `~/.zcode/agents/` with `name:`/`maxTurns:`/`tools:` and zero `model:` lines; zcode overlay composed (binding heading present); project add writes `.zcode/agents/` + `.zcode/skills/`; remove wipes
    — **Why:** AC 1 — per-target contract enforcement, same discipline as kimi/kilo suites
    — **Done when:** Suite green
    — **Consumers affected:** CI; ticket AC 1
- [ ] **5.2** `tests/copilot_target.bats`: help lists copilot; user-scope add writes `~/.copilot/agents/` and NO skills dir; project add writes `.github/agents/` + `.github/skills/`; claude-format frontmatter assertions (`name:`, `tools:`)
    — **Why:** AC 2 — proves the null-skillsDir guard and the project gap closure
    — **Done when:** Suite green
    — **Consumers affected:** CI; ticket AC 2
- [ ] **5.3** Guard + suite run: `tests/agent_lcd_pilot.bats` green (new suffixes, kimi/kilo bindings); then full `bats tests/` + `node installer/build-registry.mjs --check` (ticket exit gate, tier=full)
    — **Why:** AC 5 — the whole-suite proof including every pre-existing target suite (claude/kimi/kilo/agents must stay green with two new rows present)
    — **Done when:** --check no drift; bats fully green
    — **Consumers affected:** CI; ticket AC 5

## Technical Notes
- ZCode frontmatter reference (zcode.z.ai/en/docs/subagents): `name`/`description` required (missing → file ignored with diagnostic), `model` specific-or-inherit, `thoughtLevel` only with explicit model, `color`, `tools`/`disallowedTools`, `maxTurns`, `injectAgentsMd` (default on), `mcpServers` exact-match. Subagents cannot spawn subagents — overlays must route delegation inline.
- Copilot custom agents: markdown + YAML frontmatter in `.github/agents/` (workspace) or `~/.copilot/agents`/`~/.claude/agents` (user profile); VS Code also reads `.claude/agents` — the claude target remains the user-scope path; copilot row exists for project scope + explicit user dir.
- `agentMode` chains key off `cfg.agentMode` strings — `"claude-translate"` reuse for copilot must be verified in user loop, project loop, AND update path (1.2/2.1 done-when covers all three; the #576 exit-gate caught exactly this class).
- `--target both` = opencode+claude alias — untouched. `activeTargets()` derivation means no changes for the new rows.
- Registry: no frontmatter changes to agents/skills → `--check` must show no drift; if it does, halt (same anti-phantom discipline as #576 4.1).

## Dependencies
- None external; single ticket.

## Risks & Mitigation
- **Unwired chain silent-regression** (the #576 lesson): 1.2/2.1 done-whens require all three chains verified per target; 5.x suites assert written bytes.
- **Invented ZCode/Copilot syntax in overlays**: overlay prose states only what the fetched docs support (nesting ban, dirs, tool names); capability-level phrasing elsewhere.
- **kimi/kilo test flip ordering**: 3.1 and 3.2 land in one commit — the suite cannot be red between them.
- **Guard weakening**: orphan-list extension is additive; no assertion deletions.
