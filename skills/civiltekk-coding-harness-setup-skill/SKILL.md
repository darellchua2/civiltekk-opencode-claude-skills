---
name: civiltekk-coding-harness-setup-skill
description: >-
  Detect a repo's coding harness(es) — OpenCode v1/v2, pi, Claude Code,
  Codex — and provision parity project-level setup: shared .agents/skills
  dir, canonical AGENTS.md with per-harness shims, harness config files,
  MCP per supported harness. Triggers: set up harness for this repo,
  harness parity, project harness setup, setup pi/opencode/claude/codex.
license: Apache-2.0
compatibility: opencode
metadata:
  harness: "opencode"
category: Harness Setup
---

## What I do

I make one repo work identically across the team's coding-agent harnesses. I detect which harness(es) a repo already carries, then provision the parity surface: skills in the neutral `.agents/skills/` dir, one canonical `AGENTS.md`, per-harness config deltas, and MCP config only where the harness supports it. I run in the primary session of the TARGET repo, never the configurator checkout.

Parity is reported, not assumed: the final matrix shows provisioned / shimmed / unsupported per harness and layer — and pi's "no MCP" row is always stated, never silently blank.

## When to use me

- "set up harness for this repo", "harness parity", "make this repo work with pi and opencode"
- First session in a repo with a foreign harness layout (`.pi/`, `.codex/`, `.claude/` present, nothing provisioned for the team's harness)
- A teammate joins with a different harness and the repo must gain their dirs

## Layer rules (the parity contract)

- **Skills — neutral-first**: one master copy in `.agents/skills/<name>/` (read natively at project level by OpenCode, pi, Codex, Kilo, Kimi — see `docs/harness-landscape-2026-09.md` §Standards layer). Claude Code is the only shim: refreshed copies into `.claude/skills/` on every run. Never edit two masters.
- **Instructions — one source**: canonical root `AGENTS.md` (read natively by all five profiles). Claude Code's `CLAUDE.md` becomes a one-line `@AGENTS.md` import. An existing content-bearing `CLAUDE.md` is a conflict — surface it, ask, never auto-merge.
- **Config — delta-only**: per-harness writes are backup-then-merge, never clobber (procedure below). pi needs zero config for skills (reads `.agents/skills/` natively).
- **MCP — honest asymmetry**: one user-stated server list translated per harness that supports MCP (OpenCode `opencode.json`, Claude Code `.mcp.json`, Codex `config.toml`). pi has no MCP by design — its matrix row always reads "unsupported — extensions path", and the user decides whether to note that in AGENTS.md.
- **Freshness — verify or disclose**: each profile side file lists official doc URLs. Unless the user pinned a version, fetch them before writing config. Fetch fails → use this skill's embedded baseline and disclose that in the report.

## Step 1 — Detect

Read-only scan. Filenames match case-insensitively. A harness-shaped signal not listed below → ask, never guess.

| Signal | Detects |
|--------|---------|
| `opencode.json` or `.opencode/` | OpenCode — version via `opencode --version`; binary absent → config-shape fallback (markers in the profile side files) |
| `.pi/` | pi |
| `.claude/` or `CLAUDE.md` | Claude Code |
| `.codex/` | Codex CLI |
| `AGENTS.md` (any case) | instructions layer present (harness-agnostic) |
| `.agents/skills/` | neutral skills layer present |

Report findings as one table, then branch:

- **0 harnesses** → ask which to provision
- **1 harness** → provision it; offer the team-standard set ("which other harnesses should also work here?")
- **≥2** → parity mode: provision missing dirs per harness, neutral-first

## Step 2 — Ask

> Harness binding (§Portability contract): OpenCode — `question` tool. Claude Code — `AskUserQuestion`. Other/none — print the menu in a plain reply and wait; non-interactive → apply defaults and disclose.

One multi-select: which harness profiles to provision (detected ones pre-checked), plus which MCP servers the repo needs, if any.

## Step 3 — Load the profile

Side-file load table — read ONLY the file for the current profile; never preload:

| Read | When | Use |
|-----|------|-----|
| `references/harnesses/opencode-v2.md` | detection resolved OpenCode v2 | dirs, config keys, version markers, verify commands, doc URLs |
| `references/harnesses/opencode-v1.md` | detection resolved OpenCode v1 | same skeleton for the v1 shape |
| `references/harnesses/pi.md` | detection resolved pi | dirs, settings override, extensions-not-MCP asymmetry |
| `references/harnesses/claude-code.md` | detection resolved Claude Code | dirs, CLAUDE.md shim, `.mcp.json` |
| `references/harnesses/codex.md` | detection resolved Codex | dirs, AGENTS.md layering, config.toml MCP |

A harness with no side file: fetch its official skills/setup docs (Step 4 rules), scaffold from what they say, and offer to contribute `references/harnesses/<name>.md` by copying an existing skeleton.

## Step 4 — Freshness gate

Unless the user pinned a version: fetch the profile's doc URLs and reconcile conflicts — the live doc wins over this skill; fix the side file's stale value in the same run. Fetch fails or offline → proceed on the embedded baseline and disclose that in the report. Version pinned → fetch that version's docs, else baseline with disclosure.

## Step 5 — Write

- **Create-if-absent**: `.agents/skills/`, `.claude/skills/` (Claude shim), per-harness dirs from the profile
- **Refresh copies**: `.agents/skills/` → `.claude/skills/` (Claude Code only, every run)
- **Instructions**: create `AGENTS.md` if absent; else marker-append under `## Harness Setup` (marker `<!-- harness-setup -->`); `CLAUDE.md` shim per profile — content-bearing existing file → surface, ask
- **Config deltas** — backup-then-merge, delta-only. MCP server maps take FULL entries only (a bare `{"disabled":false}` stub can erase a global transport in OpenCode — profile file carries the detail):

Backup first: `cp <config> <config>.bak-$(date +%Y%m%d_%H%M%S)`

Merge delta into existing config (existing base, delta wins). jq:

```bash
# Requires bash (git-bash/WSL on Windows)
jq -s '.[0] * .[1]' <config> <delta.json> > <config>.new && mv <config>.new <config>
```

No jq — Node (guaranteed wherever the installer ran):

```bash
node -e "
const fs=require('fs');
const isObj=(v)=>v&&typeof v==='object'&&!Array.isArray(v);
const merge=(b,d)=>{for(const k of Object.keys(d)){b[k]=(isObj(b[k])&&isObj(d[k]))?merge(b[k],d[k]):d[k];}return b;};
const base=JSON.parse(fs.readFileSync(process.argv[1],'utf8'));
const delta=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
fs.writeFileSync(process.argv[1],JSON.stringify(merge(base,delta),null,2)+'\n');
" <config> <delta.json>
```

Diff-check after every merge: only the intended keys added (`git diff <config>` or diff vs the `.bak`). Invalid JSON in an existing config → STOP, show the user, never guess.

## Step 6 — Verify + report

Run each provisioned profile's verify command (from its side file). Report exactly:

- **Parity matrix**: harness × layer (skills / instructions / config / MCP) → provisioned | shimmed | unsupported (why)
- **Files written** + backup paths (`.bak-<timestamp>`)
- **Doc freshness**: which URLs verified live, which fell back to baseline
- **Revert**: delete created dirs/files, remove appended AGENTS.md blocks, restore `.bak` files

## Gates (hard rules)

- **No preload** — never "read all references first"; load only the current profile's side file
- **Never clobber** — merge, diff-check, report backups; project layer is opt-in only
- **pi's MCP row never blank** — "unsupported — extensions path", every run
- **Offline → disclose; version pin → honor**
- **Every side-file value carries a citation or a verify-locally note**; drift found at runtime → fix the side file in the same run

## Governance

| Aspect | Source of truth |
|--------|-----------------|
| Harness dirs + config syntax | profile side files' cited official docs — live-fetched at the freshness gate |
| Neutral-dir readers, convergence claims | `docs/harness-landscape-2026-09.md` (in-repo research baseline, verified 2026-09-26) |
| OpenCode MCP merge semantics; deep MCP opt-ins | opencode v2 docs; for server catalogs and opt-in flows prefer `opencode-repo-setup-skill` when installed |
| v1→v2 conversion | `opencode-v2-migration-skill` when installed; otherwise profile version markers + pinned docs |

This skill ships no MCP server inventory, no model IDs, and no harness version numbers beyond detection markers — refresh from the cited docs when they drift.
