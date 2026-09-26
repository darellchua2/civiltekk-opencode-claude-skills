# PLAN: Portability phase 2 — zcode/copilot + kimi/kilo targets

**Branch**: feat/581
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/581
**Base**: main
**Rev**: 2 — applies architecture review (Majors 1-4, Minors 1-4; RG answers adopted from the reviewer's recommended_answer entries: zcode user-scope only; tools-omission decision; copilot project dirs = `.claude/{agents,skills}`)

## Acceptance Criteria
- [ ] `--target zcode` installs a translated code-review-subagent to `~/.zcode/agents/` (synthesized `name:`, `maxTurns` from `steps`, no `model:` pin, deny rules carried by `disallowedTools:`, skill-allow sources omit `tools:` with a loud warning) and composes the zcode overlay
- [ ] `--target copilot --project` writes `.claude/agents/` + `.claude/skills/` (documented Claude-format workspace dirs) with claude-format frontmatter; user scope writes `~/.copilot/agents/`
- [ ] kimi/kilo composed output for the 3 pilots carries target-appropriate delegation bindings; copilot composed output carries the Task-tool binding
- [ ] Orphan guard derives from the exported `COMPOSABLE_TARGETS` (single source); contract/landscape docs move zcode/copilot to composable (zcode: user-scope + nesting ban; copilot: `.claude`-format workspace dirs)
- [ ] New target test suites green; full bats green; registry `--check` clean; README/AGENTS target docs updated

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` (ZCODE map, `zcodeAgentContent`, TARGETS rows, probes, help text, dry-run destination fix) | — | CLI (`--target zcode|copilot`), new bats suites, update/remove paths (generic), `deploy/setup.sh` routing | high |
| `installer/overlay.mjs` (`COMPOSABLE_TARGETS` + zcode/copilot, **exported**) | TARGETS rows (1.2/2.1) | all four write sites; bats guard derives its allowlist from the export (3.2) | medium |
| `agents/overlays/*.{zcode,kimi,kilo,copilot}.md` (12 new) | helper target support (1.3); contract update (4.1) for normative wording | composition for the new targets; guard suite (3.2) | low |
| `tests/agent_lcd_pilot.bats` (derived orphan list, kimi/kilo flip, copilot/zcode binding assertions) | overlays (3.1), export (1.3) | CI | low |
| `tests/zcode_target.bats`, `tests/copilot_target.bats` (new) | 1.x/2.x | CI | low |
| `docs/subagent-portability-contract.md` + `docs/harness-landscape-2026-09.md` | 1.x/2.x shipped | future authoring; issue #581 AC 4 | low |
| `README.md` + `AGENTS.md` | 1.2/2.1 | repo readers; documentation-sync rules | low |

## Implementation Phases

### Phase 1: zcode target (user-scope only)
- [ ] **1.1** Add `ZCODE_TOOL_MAP` — the 8 shared actions (read→Read, write→Write, edit→Edit, shell→Bash, glob→Glob, grep→Grep, webfetch→WebFetch, websearch→WebSearch) — and `zcodeAgentContent(content, stem, warn)` mirroring `claudeAgentContent` with three ZCode-specific deviations: (a) `subagent` rules are DROPPED with warning "ZCode subagents cannot spawn subagents" (no Task analog — ZCode launches subagents via its primary-side Agent tool; nesting is banned), (b) skill-allow rules trigger omission of `tools:` entirely with a loud warning ("ZCode tools: allowlists are exhaustive; emitting one without the skill tool would lock skills out — denies still carried by disallowedTools:"), while `disallowedTools:` is always emitted for deny rules, (c) the `steps:` frontmatter key is rewritten to `maxTurns:`; synthesized `name: <stem>`; never emit `model:` (ZCode default = inherit); `mode`/`permissions`/`category` left in place (unknown keys silently ignored)
    — **Why:** Docs-verified deviations (review Majors 2-3): nearest-analog tool mapping would advertise a delegation capability ZCode forbids, and an exhaustive allowlist without the skill tool silently strips skill invocation
    — **Done when:** Function beside the sibling translators in `installer/init.mjs`; `node --check` clean; the three deviations each covered by a 5.1 assertion
    — **Consumers affected:** zcode TARGETS row (1.2), tests 5.1
- [ ] **1.2** Add consts (`USER_ZCODE_AGENTS`/`USER_ZCODE_SKILLS` = `~/.zcode/{agents,skills}`), TARGETS row `zcode: { agentsDir, skillsDir, agentMode: "zcode-translate", skillMode: "verbatim" }` — **user-scope columns only** (ZCode subagents Beta is documented user-level-only; project installs degrade via the existing no-project-destination note, claude-target precedent) — wire `"zcode-translate"` into all three agentMode chains (user add :~905, update :~1428; no project branch needed), add the `~/.zcode` auto-probe, extend help text, and fix the legacy dry-run `destination` ternary (:~876) to `dirname(TARGETS[target].agentsDir)` for single targets (stops misreporting `~/.kimi-code` for new targets)
    — **Why:** Per-target contract enforcement; the three-chain + dry-run sites are the exact silent-regression class the #576 exit gate caught
    — **Done when:** `--target zcode --yes` add of code-review-subagent writes `~/.zcode/agents/code-review-subagent.md` with `name:`/`maxTurns:`/`disallowedTools:`, NO `tools:` (skill-allow source) and NO `model:`; `--dry-run` JSON `destination` reports `~/.zcode`
    — **Consumers affected:** CLI users; tests 5.1; update/remove paths
- [ ] **1.3** In `installer/overlay.mjs`: add `"zcode"` and `"copilot"` to `COMPOSABLE_TARGETS` and **export the set** (single source for the guard)
    — **Why:** Review Major 1 — copilot was documented composable without a composition path (dead-file class); Minor 3 — the twin hardcoded allowlists are the structural cause, mechanized by export + derivation
    — **Done when:** Set exported with 6 members; helper composes `.zcode.md`/`.copilot.md` overlays once 1.4/3.1 land
    — **Consumers affected:** all write sites; guard derivation (3.2)
- [ ] **1.4** Write 3 zcode overlays (`agents/overlays/{code-review,image-analyzer,requirements-specialist}-subagent.zcode.md`): nesting ban (delegation work runs inline), no memory tool (LEARNINGS glob fallback), `$skill-name` invocation hint, MCP-only-at-session-start caveat where relevant
    — **Why:** ZCode-specific ergonomics per the contract's overlay convention
    — **Done when:** 3 files exist; `tests/fixtures/compose_agent.mjs <stem> zcode` composes them
    — **Consumers affected:** zcode installs; guard suite

### Phase 2: copilot target
- [ ] **2.1** Add const (`USER_COPILOT_AGENTS` = `~/.copilot/agents`), TARGETS row `copilot: { agentsDir, skillsDir: null, projectAgentsDir: ".claude/agents", projectSkillsDir: ".claude/skills", agentMode: "claude-translate", skillMode: "verbatim" }`, `~/.copilot` auto-probe, help-text entry; ADD a `claude-translate` branch to the project install chain (:~553-557 — it has no claude branch today because claude has no project columns; "add", not "verify"); user loop and update path already key off `cfg.agentMode` — verify copilot flows through the existing `"claude-translate"` branches there
    — **Why:** Fills the project-scope gap using the Claude-format workspace dirs VS Code documents (`.github/agents` is VS Code-native format with string-typed tools — out of scope until a translator exists; RG3 adopted answer)
    — **Done when:** `--target copilot --project --yes` writes `.claude/agents/code-review-subagent.md` + `.claude/skills/`; user-scope add writes `~/.copilot/agents/` and no skills dir; `--dry-run` destination reports `~/.copilot`
    — **Consumers affected:** CLI users; tests 5.2

### Phase 3: overlays for kimi/kilo/copilot + guard updates
- [ ] **3.1** Write 9 overlays: 3 kimi (`{3 pilots}.kimi.md` — delegate by agent name via the Task tool, agents at `~/.kimi-code/agents`, no memory tool, no mid-run clarification), 3 kilo (`{3 pilots}.kilo.md` — task-tool/`@mention` delegation, `permission.task` grant note, same memory/clarification fallbacks), 3 copilot (`{3 pilots}.copilot.md` — Task-tool binding + capability rows, near-twins of the claude overlays)
    — **Why:** AC 3 + review Major-5-class prevention — without `.copilot.md` overlays, copilot installs regress to LCD-only (the exact regression #576's plan review rejected for claude)
    — **Done when:** 9 files exist; helper composes each for its target
    — **Consumers affected:** kimi/kilo/copilot installs; guard suite (3.2)
- [ ] **3.2** Update `tests/agent_lcd_pilot.bats`: orphan-guard allowlist DERIVED from the exported `COMPOSABLE_TARGETS` (node -e import + print members — no second hardcoded list); kimi/kilo test flips from byte-identical-core to binding-present; NEW assertions: copilot composed output carries the Task-tool binding, zcode composed output carries the inline-delegation/nesting-ban binding
    — **Why:** Review Minor 3 + Major 1 — mechanized allowlists prevent the dead-file class structurally; the flips must land in the same commit as 3.1
    — **Done when:** Full guard file green with 12 new overlays present
    — **Consumers affected:** CI

### Phase 4: docs
- [ ] **4.1** `docs/subagent-portability-contract.md`: binding matrix — Composable = opencode/claude/kimi/kilo/zcode/copilot (zcode: user-scope only + nesting ban + tools-omission rule; copilot: claude-translate reuse, `.claude`-format workspace dirs); documented-only shrinks to codex/pi/M365; pilot-coverage rows updated; `.zcode.md`/`.copilot.md` overlay validity stated
    — **Why:** The matrix is normative — it must match shipped reality (review Major 1's docs half)
    — **Done when:** Matrix, documented-only list, pilot table reflect 6 composable targets with the two caveats
    — **Consumers affected:** issue #581 AC 4; future authoring
- [ ] **4.2** `docs/harness-landscape-2026-09.md`: "Planned targets — not composable" rewritten as shipped (zcode/copilot landed via #581; pi/codex/M365 remain documented-only with reasons)
    — **Why:** The section explicitly promises this flip
    — **Done when:** Section reflects shipped state
    — **Consumers affected:** docs readers; contract cross-ref
- [ ] **4.3** `README.md` target table + `AGENTS.md` §Repository Purpose bullet: add `--target zcode` (user-scope only `~/.zcode/{agents,skills}/`, zcode-translate: camelCase `maxTurns`←`steps`, subagent rules dropped, tools-omission rule, nesting ban) and `--target copilot` (`~/.copilot/agents/` user; project `.claude/{agents,skills}/` — Claude-format workspace dirs VS Code documents; `.github/agents` native format out of scope)
    — **Why:** documentation-sync rules; #579 just made the AGENTS.md bullet reader-precise — keep it that way
    — **Done when:** Both surfaces name the new targets with accurate paths, scopes, and caveats
    — **Consumers affected:** repo readers; documentation-consistency checks

### Phase 5: tests + verification gate
- [ ] **5.1** `tests/zcode_target.bats` (mirror `kimi_target.bats`): help lists zcode; user-scope add writes `~/.zcode/agents/` with `name:`/`maxTurns:` and zero `model:` lines; skill-allow source (code-review-subagent) omits `tools:` and carries `disallowedTools:`; zcode overlay composed; project add prints the no-project-destination note; remove wipes
    — **Why:** AC 1 per-target enforcement incl. the three translator deviations
    — **Done when:** Suite green
    — **Consumers affected:** CI; ticket AC 1
- [ ] **5.2** `tests/copilot_target.bats`: help lists copilot; user-scope add writes `~/.copilot/agents/` and no skills dir; project add writes `.claude/agents/` + `.claude/skills/` with `name:`/`tools:` frontmatter; remove wipes
    — **Why:** AC 2 — proves the null-skillsDir guard, the new project chain branch, and the `.claude`-format dir choice
    — **Done when:** Suite green
    — **Consumers affected:** CI; ticket AC 2
- [ ] **5.3** Full gate: `tests/agent_lcd_pilot.bats` green (derived allowlist, kimi/kilo + copilot + zcode binding assertions); then full `bats tests/` + `node installer/build-registry.mjs --check` (ticket exit gate, tier=full)
    — **Why:** AC 5 — every pre-existing target suite must stay green with two new rows; the composition assertions close the plan-exit-gate-narrower violation from review
    — **Done when:** --check no drift; bats fully green
    — **Consumers affected:** CI; ticket AC 5

## Technical Notes
- ZCode frontmatter (zcode.z.ai/en/docs/subagents, docs-verified this session): `name`/`description` required, `model` omit=inherit, `thoughtLevel` gated on explicit model, `tools`/`disallowedTools`, `maxTurns`, `injectAgentsMd` default-on, `mcpServers` exact-match; subagents cannot spawn subagents; custom `tools:` lists are EXHAUSTIVE ("nothing outside it is available") and gate skill invocation — the basis for 1.1(b).
- Copilot/VS Code (code.visualstudio.com custom-agents, docs-verified): workspace `.github/agents` (VS Code-native format) AND `.claude/agents` (Claude format); user `~/.copilot/agents` or `~/.claude/agents`; skills at `.github/skills` default. Claude-format support is why `.claude/{agents,skills}` are the copilot project columns.
- `--target both` = opencode+claude alias — untouched; `TARGET_VALUES`/`activeTargets` derive from the table.
- Registry: no agents/skills frontmatter changes → `--check` must show no drift; drift = halt (anti-phantom discipline).

## Dependencies
- None external; single ticket.

## Risks & Mitigation
- **Unwired chain silent-regression** (#576 lesson): 1.2/2.1 enumerate all chain sites; 5.x suites assert written bytes per target.
- **Invented harness syntax**: overlay prose states only docs-verified facts; capability-level phrasing elsewhere (review-verified against live docs).
- **Skill lockout** (review Major 3): the tools-omission rule trades allow-enforcement for capability preservation on skill-allow agents; denies always enforced via `disallowedTools:`; documented in contract + README.
- **Test-flip ordering**: 3.1 and 3.2 land in one commit.
- **Guard weakening**: orphan list becomes derived — strictly stronger; no assertion deletions.
