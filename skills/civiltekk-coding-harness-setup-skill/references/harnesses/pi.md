# pi — harness profile

> **Load rule:** the router's Step 3 table reads this file when detection
> resolved pi. Values carry citations (verified 2026-10-01) or *verify
> locally* notes; the freshness gate live-fetches the Doc URLs.

## Skills dirs

| Scope | Path | Note |
|-------|------|------|
| Project | `.pi/skills/` and `.agents/skills/` | cwd + ancestor directories, up to the git repo root |
| Global | `~/.pi/agent/skills/` and `~/.agents/skills/` | global config root is `~/.pi/agent/` (override: `PI_CODING_AGENT_DIR`) |
| Packages | `skills/` dirs in pi packages; `pi.skills` entries in `package.json` | out of scope for repo setup |
| Settings | `skills` array (files or dirs) in settings | explicit override, rarely needed |

Citation: pi skills docs (https://pi.dev/docs/latest, badlogic/pi-mono
coding-agent skills page).

## Instructions files

`AGENTS.md` and `CLAUDE.md` are read natively (global dir, parent
directories, cwd). **No shim needed** — the canonical root `AGENTS.md`
is pi's project instructions as-is.

## MCP — none, by design

pi has no MCP layer. Capabilities beyond the built-in tools arrive as
**TypeScript extensions** (full lifecycle hooks, loaded from
`~/.pi/agent/extensions/` or project `.pi/extensions/`) or npm/git
packages. The parity matrix row for pi + MCP always reads:
**"unsupported — extensions path"**. On request, note in `AGENTS.md`
which MCP-backed workflows need an extension alternative.

## Setup writes for this harness

- Skills: **nothing to write** — `.agents/skills/` is read natively.
- MCP: **nothing to write** (see above).
- Verify: `pi --version` exits 0. *verify locally: the CLI's skill-listing
  command name per pi.dev/docs/latest.*

## Doc URLs (freshness gate)

- https://pi.dev/docs/latest (skills, extensions)
- https://github.com/badlogic/pi-skills (compatible skill examples)
