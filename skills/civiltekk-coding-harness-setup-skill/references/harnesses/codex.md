# Codex CLI — harness profile

> **Load rule:** the router's Step 3 table reads this file when detection
> resolved Codex. Values carry citations (verified 2026-10-01) or *verify
> locally* notes; the freshness gate live-fetches the Doc URLs.

## Skills dirs

| Scope | Path | Note |
|-------|------|------|
| Project | `.codex/skills/` | personal-to-checkout dir |
| REPO scope | `.agents/skills` | cwd and one parent above cwd inside a git repository — the neutral dir is read natively |
| Global | `~/.codex/skills/` | |
| Per-skill extra | `openai.yaml` inside a skill folder | Codex-only metadata (display name, icon, `mcp_tools`); other harnesses ignore it — skip for cross-harness skills |

Citation: https://learn.chatgpt.com/docs/build-skills (skill scope table:
REPO = `$CWD/.agents/skills` and `$CWD/../.agents/skills`).

## Instructions files

`AGENTS.md` layering: `~/.codex/AGENTS.md` (global) → repo root →
subdirectory-scoped files. Project overrides global. The canonical root
`AGENTS.md` is Codex's project instructions as-is — **no shim needed**.

## MCP

- `config.toml` (global `~/.codex/config.toml`; *verify locally: whether a
  project-level config path is supported on the installed version*):
  `[mcp_servers.<name>]` TOML tables with `command`/`args` keys.
  *verify locally: exact TOML keys per the Codex config docs before
  writing — TOML requires a TOML-aware merge, never a JSON merge tool.*

## Setup writes for this harness

- Skills: **nothing to write** — `.agents/skills` REPO scope is native.
- Instructions: **nothing to write** — AGENTS.md native.
- MCP: TOML delta into `config.toml` (backup-then-merge, TOML-aware).
- Verify: `codex --version` exits 0. *verify locally: skill listing per
  docs.*

## Doc URLs (freshness gate)

- https://learn.chatgpt.com/docs/build-skills
- https://agents.md (instructions-file standard)
