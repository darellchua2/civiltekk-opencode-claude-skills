# OpenCode v1 — harness profile

> **Load rule:** the router's Step 3 table reads this file when detection
> resolved OpenCode v1. Same skeleton as `opencode-v2.md`; values carry
> citations or *verify locally* notes. For v1→v2 conversion prefer the
> `opencode-v2-migration-skill` when installed — its triage covers config,
> plugin, and agent-shape mapping; otherwise use the markers below plus
> version-pinned docs.

## Skills dirs

| Scope | Path | Note |
|-------|------|------|
| Project | `.opencode/skills/` (also documented as `.opencode/skill/` in early v1) | *verify locally: singular vs plural on the installed version* |
| Compat | `.claude/skills/`, `.agents/skills/` | compat reads present in current v1 docs |
| Global | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | |

Citation: https://opencode.ai/docs/skills (v1 docs path). *verify locally:
the exact dir list on the installed version — early v1 builds predate the
compat dirs.*

## Config (`opencode.json`)

- MCP server map semantics match v2 (full entries; project layer opt-in).
  *verify locally: v1 docs — config page — for any key differences before
  writing.* https://opencode.ai/docs/config
- v1 agents predate `permissions` rule arrays; per-agent shape is simpler.
  *verify locally: https://opencode.ai/docs/agents*

## Version detection markers

- `opencode --version` below the v2 boundary → v1 (*verify locally: boundary
  value per release docs*).
- Config-shape fallback: an `opencode.json` with MCP config but agent
  entries lacking `permissions` arrays suggests v1.

## Setup writes for this harness

- Skills: nothing — `.agents/skills/` compat read (when present on the
  installed version).
- MCP delta: full-entry merge into project `opencode.json` (router Step 5).
- Verify: `opencode --version` exits 0.

## Doc URLs (freshness gate)

- https://opencode.ai/docs/skills
- https://opencode.ai/docs/config
- https://opencode.ai/docs/agents
