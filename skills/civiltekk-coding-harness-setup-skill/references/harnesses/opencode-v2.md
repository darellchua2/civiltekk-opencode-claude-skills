# OpenCode v2 — harness profile

> **Load rule:** the router's Step 3 table reads this file when detection
> resolved OpenCode v2. Values carry citations (verified 2026-10-01 unless
> noted) or *verify locally* notes; the router's freshness gate live-fetches
> the Doc URLs before any write. New profiles copy this skeleton.

## Skills dirs

| Scope | Path | Note |
|-------|------|------|
| Project native | `.opencode/skills/<name>/SKILL.md` | walked from cwd to the git worktree root |
| Project compat | `.claude/skills/`, `.agents/skills/` | read alongside the native dir |
| Global | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | compat reads documented |

Citation: https://opencode.ai/v2/docs/skills (Place files + Discovery tables).
*verify locally: precedence when the same skill id exists in project and
global — the v2 Discovery section orders compat dirs global-first, ancestors
toward cwd; native project dir loads root toward cwd. Avoid duplicate ids
unless overriding is intended.*

## Config (`opencode.json`)

- **MCP** — `mcp.servers.<name>` is a FULL entry: `{ "type": "local"|"remote",
  "command": [...]|"url": "...", "environment"?: {...}, "disabled": bool }`.
  **Atomic replace across config layers**: writing a bare `{"disabled":false}`
  stub erases the global transport and yields an inert server — copy
  `type`/`command`/`environment` from the global definition and set
  `disabled: false`. Citation: https://opencode.ai/v2/docs/plus config
  layering semantics (project wins); cross-checked against the configurator
  repo's deploy experience, 2026-09.
- **Agents** — `agents.<id>.model` scalar pins merge safely across layers
  (scalars replace, permission rules append). Never pin `build`/`plan`
  (session-selected). Citation: https://opencode.ai/v2/docs/agents.
- **Permissions** — v2 agent definitions use `permissions` rule arrays;
  order matters (last matching rule wins).

## Version detection markers

- Primary: `opencode --version` — *verify locally: output format and the
  major-version boundary for v2 per the v2 release docs; treat major ≥ 2 as
  v2 once confirmed.*
- Config-shape fallback (binary absent/ambiguous): v2 agent definitions
  support `permissions` rule arrays and per-agent `steps`/`temperature`;
  their presence suggests v2. Absent → consult `opencode-v1.md`.

## Setup writes for this harness

- Skills: **nothing to write** — `.agents/skills/` is read natively (compat).
- MCP delta: merge chosen servers as FULL entries into the project
  `opencode.json` (router Step 5 merge procedure).
- Verify: `opencode --version` exits 0; after restart the enabled servers
  appear in the session's tool list (config is read at startup, no lazy
  start mid-session).

## Doc URLs (freshness gate)

- https://opencode.ai/v2/docs/skills
- https://opencode.ai/v2/docs/agents
- https://opencode.ai/v2/docs/plugins (per-agent skill gating)
