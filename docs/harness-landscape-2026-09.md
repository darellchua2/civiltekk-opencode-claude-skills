# Coding-Agent Harness Landscape — September 2026

Research baseline for the subagent portability work (#576). Sources verified 2026-09-26: opencode.ai/docs, code.claude.com/docs, learn.chatgpt.com (Codex), code.visualstudio.com + learn.microsoft.com (Copilot), zcode.z.ai/docs, kilo.ai/docs, pi.dev/docs/latest, badlogic/pi-mono, learn.microsoft.com (M365 Copilot), zed.dev/docs.

## The convergence

Nearly every serious coding harness converged on the same three-part extension model Claude Code popularized:

1. **Skills** — markdown instruction packages (`SKILL.md` folder), now the open Agent Skills standard, loaded on demand with progressive disclosure.
2. **Subagents** — markdown-defined specialist contexts (frontmatter + system-prompt body), spawned into isolated sessions via a task/delegate tool.
3. **Plugins** — bundles packaging skills + agents/subagents + hooks + MCP servers behind one install surface.

The surviving differences are mechanical: delegation triggering (explicit `@mention` vs agent-discretion vs fully automatic), skill trust/gating models, whether plugins are runtime code or declarative bundles, and how tightly each harness binds to its own models.

## Comparison

| Harness | Primary agent | Subagents | Skills | Plugins / extensions | MCP |
|---|---|---|---|---|---|
| OpenCode | Switchable primaries (`@mention`), plan mode | Yes — agent `.md` files, task tool, v2 `permissions` rule arrays, model/temperature/steps per agent | Yes — SKILL.md, native `skill` tool, per-agent allow/deny/ask gating | TS/JS runtime plugins hooking events (code, not manifests) | Yes (config) |
| Claude Code | One main agent + plan mode | Yes — `~/.claude/agents/*.md`; plus Agent Teams (Feb 2026): peer agents, shared task list, worktrees | Yes — originated the format; commands merged into skills | Marketplace plugins (skills/agents/hooks/commands/MCP), namespaced | Yes — invented MCP |
| OpenAI Codex | Codex agent (CLI, IDE ext, cloud, ChatGPT surfaces) | Yes — thread-level delegation (Jun 2026), `~/.codex/agents/*.toml` profiles, model-tier delegation | Yes — `~/.codex/skills/`, `.agents/skills/` | Plugins + WebMCP site tools + hooks | Yes |
| GitHub Copilot | Agent mode (VS Code), Copilot CLI, cloud agent (GitHub Actions) | Yes — custom agents as subagents (Jan 2026), CLI auto-delegation | Yes — `.github/skills/`, VS 2026 skills panel; also reads `.claude/agents` | VS Code extensions + agent plugins | Yes |
| ZCode (Z.ai) | Single first-party agent tuned to GLM-5.3; Goal Mode | Yes — built-in general-purpose + Explore; custom `~/.zcode/agents/*.md` (beta); **no nested subagents** | Yes — `~/.zcode/skills/`, `$skill` invocation, imports from Claude/Codex dirs | Claude-format-compatible plugin store (`.claude-plugin` fallback, Claude marketplaces preloaded) | Yes |
| Kilo Code | Built-in code/plan/debug/ask agents (Tab-switched) | Yes — `.kilo/agent/*.md`, `mode: primary|subagent|all`, `permission.task` scoping; orchestrator deprecated | Yes — Agent Skills standard + `.agents/`/`.claude/` compat dirs; trusted-vs-untrusted execution | No plugin bundles yet (config + remote `skills.urls`) | Yes |
| pi | One minimal agent (read/write/edit/bash) | **None natively** — build via extensions or embed via RPC/SDK; docs (pi.dev/docs/latest) position pi as a general extensible agent with print/JSON-stream/RPC/SDK automation modes | Yes — Agent Skills standard dirs (`~/.pi/agent/skills/`, `.agents/skills/`…) | TypeScript extensions (full lifecycle access) + npm/git packages | No, by design (extension can add it) |
| M365 Copilot | Copilot orchestrator (not a coding harness) | No subagents — routes to **declarative agents** | No SKILL.md concept | Plugins = MCP-server or OpenAPI actions on declarative agents; MCP Apps UI widgets | Yes |

## Standards layer

Four de facto standards span these tools; most "compatibility" is adoption of them:

1. **Agent Skills / `SKILL.md`** (Anthropic-originated, open at agentskills.io) — read natively by Claude Code, OpenCode, Codex, Copilot, Kilo, pi, ZCode. Vercel's skills.sh indexes ~600k.
2. **`AGENTS.md`** (Codex-originated) — universal repo-instructions file.
3. **MCP** (Anthropic) — universal tool protocol, everywhere including M365 Copilot.
4. **Shared directories as a directory-level truce** — `~/.agents/{skills,agents}/` and project `.agents/skills/` (read by pi, Kilo, Codex, Kimi; OpenCode for project skills); `.claude/` compat reads in Kilo, Copilot, ZCode. Zed's **ACP** standardizes the opposite direction: editors hosting external agents (Claude Code, Codex, OpenCode, Copilot, pi all plug into Zed).

## Where they genuinely differ

- **Delegation mechanics**: explicit (`@mention` in OpenCode/Kilo, `$skill` in ZCode) vs agent-discretion (description matching in Claude/Kilo) vs fully automatic (Copilot CLI specialists, Codex model-tier delegation). Only Claude's Agent Teams are peer-to-peer; the rest are strictly hierarchical.
- **Skills trust and gating**: OpenCode permission-gates skill loading per agent; Kilo refuses command execution from untrusted (project/remote) skill locations; ZCode budgets skill metadata per turn and drops descriptions when over budget; Claude relies on location precedence (enterprise > user > project > plugin).
- **Plugins**: runtime code (OpenCode TS plugins, pi extensions) vs declarative bundles (Claude/ZCode manifests, no code required) vs protocol-only (M365 — a "plugin" is a wired MCP/OpenAPI endpoint).
- **Model openness**: OpenCode, pi, Kilo, Zed are provider-agnostic; Claude Code, Codex, ZCode, Copilot bind increasingly tightly to their own models.

## Standardization strategy for this repo

Three strategies considered for shipping `agents/` (and skills) across harnesses:

| Strategy | Verdict |
|---|---|
| **Duplicated per-harness authoring** | Rejected — drift; already disproven by the installer's `claude` skillMode `model-strip` divergence (identical bytes cannot serve all targets). |
| **Shared config-folder single-write** | Partially viable for skills only — `.agents/skills/` is natively read (project-level) by OpenCode, pi, Kilo, Codex; but no shared reader exists for agents, and per-target transforms (model-strip, frontmatter translation) break byte sharing. |
| **LCD core + install-time composition** (chosen) | Canonical source stays harness-neutral; the installer composes per-target artifacts at write time; runtime fallbacks cover what only the runtime can know. |

The chosen strategy's three layers, and the rule that makes them coherent:

> **If the installer can know it at write time, the installer writes it. If only the runtime can know it, the LCD body carries the fallback.**

1. **LCD core** — source `.md` bodies with harness-neutral phrasing, the universal return contract, and `Other/none:` fallback rows; must work verbatim in any harness, including ones this repo has never heard of.
2. **Install-time composition** — per-target overlay fragments appended by a single shared helper at write time, on both agent write paths (npx `installer/init.mjs` and `deploy/setup.sh` → `installer/resolve-models.mjs`). Spec: `docs/subagent-portability-contract.md`.
3. **Runtime fallbacks** — one-line degrade paths in the LCD for model availability, granted permissions, and MCP state.

### Planned targets — not composable

**ZCode and Copilot are documented-only.** The installer's `TARGETS` table (installer/init.mjs) has no rows for them; overlay files for targets without a composition path would be silently-uncomposed dead files (guard-blocked). Porting them (zcode/copilot `TARGETS` rows + composition paths, kimi/kilo overlays) is the "Portability phase 2" follow-up. Until then:

- **ZCode**: import skills via its Claude-compatible importer; agents have no install path — the LCD core's `Other/none:` fallback is the contract surface. Note ZCode forbids nested subagents entirely.
- **Copilot**: reads `~/.claude/agents/` natively, so the existing `claude` target's output already covers VS Code — zero new code, by design.
- **pi**: documented-only by philosophy — no native subagents; the LCD core + fallback row is its entire surface; delegation routes through extensions or RPC/SDK embedding (pi.dev/docs/latest).

## Per-harness sources

OpenCode: opencode.ai/docs/agents, /docs/skills · Claude Code: code.claude.com/docs/en/skills, platform.claude.com Agent Skills · Codex: learn.chatgpt.com (Build skills / Subagents), community.openai.com multi-agent threads · Copilot: code.visualstudio.com/docs/agent-customization/custom-agents, learn.microsoft.com visualstudio copilot-agent-skills, VS Code Jan-2026 update · ZCode: zcode.z.ai/en/docs (subagents, skill, plugin) · Kilo: kilo.ai/docs/customize (custom-subagents, skills, custom-modes) · pi: pi.dev/docs/latest, github.com/badlogic/pi-mono · M365: learn.microsoft.com/microsoft-365/copilot/extensibility · Cross-tool surveys: blog.arcbjorn.com/state-of-cli-coding-agents-2026.
