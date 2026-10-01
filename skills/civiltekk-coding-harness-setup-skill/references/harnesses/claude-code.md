# Claude Code — harness profile

> **Load rule:** the router's Step 3 table reads this file when detection
> resolved Claude Code. Values carry citations (verified 2026-10-01) or
> *verify locally* notes; the freshness gate live-fetches the Doc URLs.

## Skills dirs

| Scope | Path | Note |
|-------|------|------|
| Project | `.claude/skills/<name>/SKILL.md` | discovered automatically |
| Personal | `~/.claude/skills/` | plus plugin caches/marketplaces |

Claude Code's docs list `.claude/skills/` and `~/.claude/skills/` — no
`.agents/skills/` compat read is documented. This is why the router
**refreshes copies** from the neutral master into `.claude/skills/` on
every run. *verify locally: current docs may have added compat reads —
re-check at the freshness gate before relying on the shim.*

Citation: https://code.claude.com/docs/en/skills; Agent Skills overview at
https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview.

## Instructions shim

- Canonical `AGENTS.md` stays the master (never edit two instruction
  sources).
- `CLAUDE.md` becomes a one-line memory import: `@AGENTS.md`.
  *verify locally: `@`-import syntax per the Claude Code memory docs —
  https://code.claude.com/docs/en/memory.*
- **Conflict rule:** an existing content-bearing `CLAUDE.md` is surfaced to
  the user, never auto-merged. Options: merge its content into `AGENTS.md`
  manually first, or decline the shim and leave `CLAUDE.md` as-is (report
  the resulting asymmetry).

## MCP

- Project scope: `.mcp.json` at the repo root —
  `{ "mcpServers": { "<name>": { "command": "...", "args": [...],
  "env": {...} } } }`. *verify locally: exact schema and field names per
  the Claude Code MCP docs before writing.*
- Claude Code originated MCP; local (`command`) and remote (`url`/SSE)
  transports exist. Translate only the servers the user listed.

## Setup writes for this harness

- Skills: refresh copy `.agents/skills/` → `.claude/skills/` (every run).
- Instructions: `CLAUDE.md` shim (conflict rule above).
- MCP: `.mcp.json` create-or-merge (router Step 5 procedure).
- Verify: `claude --version` exits 0. *verify locally: skill visibility
  check inside a session per the skills docs.*

## Doc URLs (freshness gate)

- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/mcp
