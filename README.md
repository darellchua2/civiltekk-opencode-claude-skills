# OpenCode Configuration Template

A multi-mode OpenCode configurator repository:

1. **User-Space Deploy** — Run `./deploy/setup.sh` to copy config, agents, and skills to `~/.config/opencode/` for global use
2. **Docker Standalone** — Run `docker compose up -d` to launch OpenCode as a web endpoint
3. **Individual Install (npx)** — Run `npx github:darellchua2/opencode-config-template add <name>` to pull a single skill or agent (shadcn-style copy model)

> **v2.0.0 upgrade?** See [`MIGRATION.md`](./MIGRATION.md) for breaking changes (stale agent cleanup, zip backup format, new `--rollback` / `--no-zip-backup` flags) and rollback instructions.

## Repository Structure

```
opencode-config-template/
├── deploy/                      # User-space deployment files
│   ├── .AGENTS.md               # User-space subagent routing (deployed)
│   ├── setup.sh / setup.ps1     # User-space deployment scripts
├── opencode_app/                # Docker standalone mode
│   ├── Dockerfile               # Container image
│   ├── docker-entrypoint.sh     # API key injection + opencode serve
│   ├── opencode.json            # Container-specific config
│   ├── AGENTS.md                # Container-specific instructions
│   ├── .dockerignore
│   ├── .opencode/
│   │       ├── agents/              # 33 subagent .md files
│   │       └── skills/              # 149 skill directories
│   └── README.md                # Docker usage guide
├── docker-compose.yml           # Docker Compose service definition
├── .env.example                 # Environment variable template
├── PLANS/                       # Execution plans (git-committed)
├── LEARNINGS/                   # Knowledge persistence template (auto-provisioned in target projects)
│   ├── _index.md                # Auto-generated index
│   ├── patterns/                # Reusable code/architecture patterns
│   ├── decisions/               # Architectural decisions (ADR-lite)
│   ├── anti-patterns/           # Things to avoid
│   ├── solutions/               # Non-obvious fixes
│   └── conventions/             # Team coding standards
└── .env                         # Local environment (git-ignored)
```

## Installation

Two setup scripts are provided for different platforms:

| Script | Platform | Features |
|--------|----------|----------|
| `setup.sh` | macOS, Linux, WSL, Git Bash | Full feature set including nvm, PeonPing |
| `setup.ps1` | Windows (PowerShell) | Full feature set, env vars persist to `$PROFILE` |

### macOS / Linux / WSL / Git Bash

```bash
# Interactive setup (recommended for first-time)
./deploy/setup.sh

# Quick setup - config + skills only (skip dependency checks)
./deploy/setup.sh --quick

# Skills-only deployment (requires opencode-ai installed)
./deploy/setup.sh --skills-only

# Non-interactive mode
./deploy/setup.sh --yes

# Preview actions without making changes
./deploy/setup.sh --dry-run

# Update OpenCode CLI only
./deploy/setup.sh --update

# v2.0 model resolution
./deploy/setup.sh --provider anthropic      # swap provider (zai|anthropic|openai|openrouter)
./deploy/setup.sh --mix                     # mix providers per category (e.g. vision on OpenAI, rest on Z.AI)
./deploy/setup.sh --models-only             # re-resolve models only
./deploy/setup.sh --migrate                 # run v1.x -> v2.0 migration
./deploy/setup.sh --force                   # re-resolve, ignoring preserved hand-edits
```

### Model Resolution (v2.0)

Agent models are **tier-based and provider-agnostic**. Source agent files contain
no hardcoded model — instead each agent is categorized into a tier
(`reasoning` / `fast` / `docs` / `vision`) in `deploy/agent-tiers.json`, and the
concrete model is resolved at deploy time. Swap providers without editing agent
files:

```bash
./deploy/setup.sh --provider anthropic      # or: openai, openrouter, zai (default)
```

Override files (precedence highest-first; see `MIGRATION.md`):

| File | Scope |
|------|-------|
| `<project>/.opencode/agent-overrides.json` | per-agent pin, project-local |
| `~/.config/opencode/agent-overrides.json` | per-agent pin, global |
| `<project>/.opencode/models.json` | tier map, project-local |
| `~/.config/opencode/models.json` | tier map, global (written by `--provider`) |
| `deploy/models.default.json` | Z.AI defaults |

> **Vision tier (Z.AI):** `image-analyzer-subagent` + `error-resolver-subagent` + `zai-media-subagent` run on
> `zai-coding-plan/glm-5.3-flash` (native multimodal — image/video/pdf input, 1M ctx), natively
> mapped by models.dev under the `zai-coding-plan` subscription. They see images/screenshots
> directly (no external vision API). When native perception is unavailable, the agents'
> embedded inline fallback recipe calls `glm-5v-turbo` (pay-as-you-go `zai` provider — a
> different model) via direct API. Requires `opencode auth login` (Z.AI) or `ZAI_API_KEY`
> (auto-injected in Docker via `docker-entrypoint.sh`). See `AGENTS.md` § Subagent Model Tiering.

### Windows (PowerShell)

```powershell
# Interactive setup
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1

# Quick setup
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -Quick

# Non-interactive
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -Quick -Yes

# v2.0 model resolution
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -Provider anthropic
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -ModelsOnly

# Show help with all options
powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -Help
```

### Common Options

| Option (bash) | Option (PowerShell) | Description |
|----------------|----------------------|-------------|
| `--quick` | `-Quick` | Copy config + skills only (skip dependency checks) |
| `--skills-only` | `-SkillsOnly` | Deploy skills only (requires opencode-ai installed) |
| `--update` | `-Update` | Update OpenCode CLI to latest version |
| `--dry-run` | `-DryRun` | Preview all actions without making changes |
| `--yes` | `-Yes` | Auto-accept all prompts (non-interactive) |
| `--rollback [TARGET]` | `-Rollback [-RollbackTarget\|-RollbackArg <T>]` | Restore `~/.config/opencode/` from a previous backup. `TARGET`: `list`, `latest`, `TIMESTAMP` (e.g. `20260719_070926`), or `VERSION` (e.g. `1.76.0`). Always creates a pre-rollback safety backup first. |
| `--no-zip-backup` | `-NoZipBackup` | Skip zip archive creation (zip is created by default alongside the flat-file backup for portability) |
| `--keep-backups <N>` | `-KeepBackups <N>` | Keep only N most recent backups (default: 5; 0 = delete all; negative = keep all) |
| `--help` | `-Help` | Show detailed help with all options and examples |

### Docker Standalone

Run OpenCode as a standalone web endpoint accessible through the browser:

```bash
# 1. Copy environment template and add your API keys
cp .env.example .env
# Edit .env and set ZAI_API_KEY=your-key-here

# 2. Start the container
docker compose up -d

# 3. Access OpenCode at http://localhost:4097
```

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ZAI_API_KEY` | Yes | — | Z.AI API key (primary LLM provider) |
| `GEMINI_API_KEY` | No | — | Gemini API key (secondary provider) |
| `OPENCODE_PORT` | No | `4097` | External port mapping |

```bash
# View logs
docker compose logs -f

# Stop
docker compose down

# Rebuild after changes
docker compose build --no-cache
```

## Individual Skill/Agent Install (npx)

Install a single skill or agent without cloning the repo — the shadcn/ui model (copy source into your config). See [issue #304](https://github.com/darellchua2/opencode-config-template/issues/304).

```bash
npx github:darellchua2/opencode-config-template add solid-principles-skill
```

### Scope & config strategy

| Scope | Flag | Destination | Config touch |
|-------|------|-------------|--------------|
| **User** (default) | *(none)* | `~/.config/opencode/{skills,agents}/` | None — opencode auto-discovers. `--permit` opts into backup+merge of `permissions`-array rules: skill allows (`action:"skill"`) plus build's subagent rules (deny-all-first seed incl. explore/general). |
| **Project** | `--project [dir]` | `./.opencode/{skills,agents}/` | Full generation: `opencode.json` + `models.json` + `AGENTS.md` (existing `opencode-init` behavior). |

MCPs are **never auto-merged** at user scope — the installer prints the snippet for manual paste (or use `--project` for full-service generation).

### UX flows

```bash
# A. Clean-slate user — zero config touch
npx github:darellchua2/opencode-config-template add solid-principles-skill

# B. Subagent (pulls required skills by default; --no-deps for just the file)
npx github:darellchua2/opencode-config-template add tdd-subagent
npx github:darellchua2/opencode-config-template add tdd-subagent --no-deps

# C. Strict-allowlist detected (setup.sh was run) — warns about hidden items
npx github:darellchua2/opencode-config-template add my-custom-skill

# D. --permit — backup opencode.json + merge permission entries only
npx github:darellchua2/opencode-config-template add my-custom-skill --permit

# E. Skill needs an MCP — prints snippet, never auto-merges
npx github:darellchua2/opencode-config-template add markitdown-mcp-skill

# F. Project scope (full-service)
npx github:darellchua2/opencode-config-template add nextjs-specialist-subagent --project

# Remove (user scope only; manifest-scoped — safe no-op after setup.sh)
npx github:darellchua2/opencode-config-template remove solid-principles-skill
```

### Claude Code compatibility (`--format`)

Skills follow the [Agent Skills](https://agentskills.io) open standard — the same `SKILL.md` format works in both opencode and Claude Code. Use `--format` to control the install target:

```bash
# G. Install to Claude Code (~/.claude/skills/<name>/SKILL.md)
npx github:darellchua2/opencode-config-template add solid-principles-skill --format claude

# Install to both opencode and Claude Code
npx github:darellchua2/opencode-config-template add tdd-subagent --format both
```

| Format | Destination | Notes |
|--------|-------------|-------|
| `opencode` (default) | `~/.config/opencode/{skills,agents}/` | Full opencode compat (model injection, strict-allowlist detection) |
| `claude` | `~/.claude/skills/<name>/` | Claude Code auto-discovers; `model:` lines stripped (Claude uses its own model selection) |
| `both` | Both paths above | Cross-tool install in one command |

### Browsing the catalog

Run `opencode-init --list agents` or `--list skills` to browse in JSON, or visit the [GitHub Pages catalog](https://darellchua2.github.io/opencode-config-template/) (deployed on every `main` push).

## Project-Scoped Install (`opencode-init`)

Not every project needs all 34 agents + 149 skills. <!-- count: hand-maintained — sync on skill/agent add (BT-157) --> `opencode-init` installs a **curated subset** into a target project's `.opencode/` and writes a project `opencode.json` configuring just that subset — chosen interactively (TUI) or via flags (LLM/CI). It is the project-scoped companion to the global `setup.sh` deploy, and is symlinked onto PATH as `opencode-init` by `setup.sh`.

> **Mutually exclusive with global deploy for isolation.** OpenCode **merges** config and **unions** agents/skills across `~/.config/opencode` and `<project>/.opencode`. A project subset only yields an *isolated* curated experience on a **clean slate** (no global deploy). If `~/.config/opencode/agents/` is non-empty, the project install is **additive** — `opencode-init` detects this and warns. The subagent-spawn allowlist (frontmatter `permission.task`, legacy spelling — v2 auto-translates) still restricts auto-spawning even with a global deploy; `@`-mention still bypasses it. See [issue #286](https://github.com/darellchua2/opencode-config-template/issues/286) and `PLANS/PLAN-GIT-286.md`.

### Presets

| Preset | Agents | Skills | MCPs | Use for |
|--------|--------|--------|------|---------|
| `core` | explorer | git-semantic-commits, continuous-learning | codegraph | Minimal baseline |
| `review` | code-review + architecture + language-reviewer | 31 (Code Quality incl. checklists+baseline, auth/perf/logging/eval) | codegraph | Code quality gates |
| `frontend` | nextjs-specialist + uiux-reviewer + responsive-audit | 19 (Next.js/React/Three.js/a11y) | next-devtools, chrome-devtools, codegraph | Web frontend |
| `backend` | language-reviewer | 25 (Python/DB/API/security/docker + review checklists/baseline) | codegraph | Server / devops-lite |
| `docs` | documentation + coverage + docx/pptx/xlsx + office-doc | 23 (document ladder) | — (inline mermaid blocks need no MCP) | Document generation |
| `devops` | repo-ops + opentofu-explorer | 32 (release/IaC/JIRA) | codegraph | Git / infra / release |
| `business` | startup-founder + ceo + discovery + requirements + technical-design | 36 (BD/pitch/planning) | — | BD / founder workflows |
| `research` | autoresearch-{ml,code,research} + loop-operator | 12 (autoresearch + papers) | codegraph | Autonomous loops (ml needs GPU) |
| `cad` | cad-specialist | 14 (CAD & Hardware Design) | — | CAD / robotics / hardware |

Member counts include transitive deps auto-pulled by the resolver (a preset's agent frontmatter subagent-delegate + skill-require rules — legacy `permission.task`/`permission.skill`, auto-translated). Run `opencode-init --expand <preset>` to see the exact resolved set.

### Usage

```bash
# Introspect (LLM/CI-friendly JSON — do this before installing)
opencode-init --list categories
opencode-init --list agents --category review
opencode-init --describe code-review-subagent      # skills + delegates + model availability
opencode-init --expand review                      # full resolved set, writes nothing

# Install (flag path — primary)
opencode-init --project . --preset review --yes            # install a preset
opencode-init --project . --agents code-review-subagent --yes   # specific agents (deps auto-pulled)
opencode-init --project . --preset review --provider anthropic --yes   # pick the model provider
opencode-init --project . --preset review --dry-run        # preview the manifest, write nothing
opencode-init --project . --preset docs --yes --prune      # switch preset, remove the old subset

# Install (interactive TUI — humans)
opencode-init                                        # walks a menu (arrow keys), then installs

opencode-init --help
```

What lands in the target project: `<project>/.opencode/opencode.json` (scoped `permissions` skill/subagent rules, `agents.build/plan/explore/general`, selected MCPs under `mcp.servers`), `<project>/.opencode/agents/*.md` (model injected per tier), `<project>/.opencode/skills/<name>/`, `<project>/.opencode/models.json`, a slim `<project>/AGENTS.md`, and a `.opencode-init.manifest.json` (enables safe `--prune`).

## Prerequisites

- **Node.js v20+** and **npm** (required for MCP servers)
  - Setup scripts can install Node.js for you on all platforms
  - On macOS/Linux, nvm is recommended for version management
- **Z.AI API Key** (required for Z.AI MCP services)
- **GitHub CLI** (recommended for GitHub MCP authentication)
- **ripgrep (`rg`)** (recommended for faster content search; falls back to `grep` if absent)

### Install GitHub CLI

```bash
# macOS
brew install gh

# Windows
winget install GitHub.cli
# or: choco install gh

# Linux - see https://cli.github.com/

# After installing, authenticate:
gh auth login
```

### Install Node.js

```bash
# macOS / Linux - using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install 24

# Windows - options:
# 1. nvm-windows (recommended): https://github.com/coreybutler/nvm-windows/releases
#    Then: nvm install 24 && nvm use 24
# 2. winget: winget install OpenJS.NodeJS.LTS
# 3. chocolatey: choco install nodejs
# 4. Direct download: https://nodejs.org/
```

## MCP Servers

The configuration ships 8 MCP server entries. **3 are enabled by default:**

| Server | Type | Purpose |
|--------|------|---------|
| `codegraph` | local (npx) | Pre-indexed code knowledge graph |
| `zai-web-reader` | remote | Web page content extraction |
| `zai-web-search` | remote | Web search with cited results (GIT-336) |

The remaining 5 ship `disabled: true` and are opt-in:

| Server | Type | Purpose |
|--------|------|---------|
| `atlassian` | local (npx mcp-remote) | JIRA and Confluence (first use opens browser OAuth) |
| `next-devtools` | local (npx) | Next.js DevTools integration |
| `markitdown` | local | Document-to-Markdown (local-only) |
| `docling` | local | Layout-aware document extraction (~3-4 GB) |
| `chrome-devtools` | local | Live Chrome automation |

The 4 Autodesk servers are **not shipped in the base config** — the `autodesk` provider pack below adds their full definitions at deploy time (needs `AUTODESK_API_KEY`).

To enable one **for a single project**, add it to `opencode.json` in the repo root as a **full entry** (v2 replaces `mcp.servers.<name>` atomically across config layers — a bare `{"disabled": false}` stub yields an inert server):

```json
{ "mcp": { "servers": { "atlassian": { "type": "local", "command": ["npx", "-y", "mcp-remote", "https://mcp.atlassian.com/v1/mcp"], "disabled": false } } } }
```

To enable one **globally**, set `"disabled": false` under `mcp.servers` in `~/.config/opencode/opencode.json`, or use a provider pack below. The `opencode-repo-setup-skill` automates per-project enablement interactively.

#### Provider Packs — deploy-time MCP toggle (#268)

Instead of editing 4–9 JSON entries to enable a logical group of MCP servers, use a **provider pack** — a single flag that flips all servers in the group ON at deploy time. Packs are JSON partials in `deploy/packs/`; `deploy/merge-packs.mjs` deep-merges the selected ones into your config.

| Pack | Servers enabled | Requires |
|------|----------------|----------|
| `autodesk` | **adds** autodesk-revit, autodesk-model-data, autodesk-fusion, autodesk-help (not in base config) | `AUTODESK_API_KEY` |
| `markitdown` | markitdown | Python launcher (auto-installed by `setup.sh`; baked into Docker image) |
| `docling` | docling | Python + `docling-mcp[local]` (~3-4 GB; first convert downloads models from huggingface.co) |
| `nextjs` | next-devtools | A running Next.js dev server |
| `chrome-devtools` | chrome-devtools | Chrome stable installed locally (privacy-hardened: telemetry + CrUX OFF by default) |

The cli.json `plugins` array merges **by package name** — re-runs replace in place and never touch your other plugins. On Docker, the cli.json merge is skipped with a warning (containers have no microphone).

```bash
# User-space deploy (setup.sh)
./deploy/setup.sh --enable-pack autodesk              # one pack
./deploy/setup.sh --enable-pack autodesk,markitdown   # multiple
./deploy/setup.sh --enable-pack markitdown --dry-run  # preview without writing
./deploy/setup.sh --quick --enable-pack markitdown    # combine with other modes

# Windows (setup.ps1)
./deploy/setup.ps1 -EnablePack autodesk,markitdown

# Docker (build-time)
docker compose build --build-arg OPENCODE_PACKS=autodesk,markitdown
```

Default state of every pack is **OFF** — existing deployments are unaffected unless a pack is explicitly requested. Empty/omitted `--enable-pack` is a no-op. Unknown pack names exit non-zero with a clear error. See [`PLAN.md`](PLAN.md) (issue #268) for the full design and the opencode-tooling review that shaped it.

#### Skill Profiles — deploy-time primary visibility (#333)

Every allowed skill's `description` is injected into the primary session's context at startup (~90 tokens each). The shipped `opencode_app/opencode.json` allowlist (105 allows) is the **full** profile. For a context-lean primary, deploy with a **lean** profile: only 46 primary-visible skills + `"*": "deny"` (~5.4k tokens saved per session at ~90 tokens/description).

```bash
./deploy/setup.sh                                # default: lean (46 primary-visible skills)
./deploy/setup.sh --skill-profile full           # opt back in: shipped allowlist verbatim
./deploy/setup.sh --skill-profile lean --dry-run # preview the deployed skill rules
./deploy/setup.ps1 -SkillProfile full            # Windows parity
```

Key properties:

- Only the **deployed** copy's skill rules in the `permissions` array (`action:"skill"` entries) are rewritten (`deploy/apply-skill-profile.mjs`); the shipped `opencode.json` is never modified — `full` is a verified no-op.
- **Subagents are profile-immune.** All 149 skills stay on disk and every skill has either a frontmatter skill-allow consumer (legacy `permission.skill` spelling, auto-translated by v2) or a lean slot — nothing is orphaned under lean.
- Lean-hidden skills cannot be `@`-loaded by the primary until re-exposed; re-exposing any skill is a one-line edit to `deploy/skill-profiles.json`.
- Typo-guarded: a lean key that doesn't match a real skill directory or the shipped allowlist fails the deploy closed.


> **Note — `markitdown` MCP server (PLAN-GIT-262).** Privacy-hardened document-to-Markdown converter (PDF/DOCX/PPTX/XLSX/XLS/Outlook MSG + image EXIF). Vendored launcher at `opencode_app/mcp-servers/markitdown-local-mcp/` depends **only** on local converter extras — no `markitdown[all]`, no Azure SDKs, no Google Speech, no YouTube API. `enable_plugins=False` is hard-coded. User-supplied `http:`/`https:` URIs are fetched via a single `requests.get()` (no telemetry headers, no Microsoft endpoints — equivalent to built-in `webfetch`). See [`opencode_app/mcp-servers/markitdown-local-mcp/README.md`](opencode_app/mcp-servers/markitdown-local-mcp/README.md) for the full trust-boundary analysis.

> **Note — `filesystem` MCP server has been permanently removed.** OpenCode's built-in `read`/`write`/`edit`/`glob`/`grep`/`bash` tools already provide full file I/O, so `@modelcontextprotocol/server-filesystem` was redundant and caused tool-selection ambiguity (the model would call `read_mcp_resource` instead of the built-in `Read` tool). Do not re-add it to project `opencode.json` files.

> **Note — opt-in MCP servers ship with telemetry pre-disabled.** Two of the disabled-by-default servers phone home analytics when naively enabled; both are hardened in `opencode.json` so setting `disabled: false` is safe without further edits:
>
> - **`chrome-devtools`** — Google's `chrome-devtools-mcp` sends usage statistics and Chrome UX Report (CrUX) trace URLs to Google **by default**, plus polls the npm registry for updates. Hardened with `--no-usage-statistics`, `--no-performance-crux`, `--redact-network-headers` (strips sensitive request headers before they reach the LLM), and `CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=1` (kills the update poll).
> - **`next-devtools`** — Vercel's `next-devtools-mcp` collects anonymous telemetry (tool names, error events, session metadata) by default, storing a local client ID in `~/.next-devtools-mcp/`. Hardened with `NEXT_TELEMETRY_DISABLED=1`.
>
> The enabled remote/`zai-*` servers send data **by design** (that is their function, not telemetry); `codegraph` is purely local with no telemetry layer. Mermaid diagrams ship as inline fenced code blocks (rendered client-side by GitHub/VS Code — no MCP server); `markitdown` and `docling` are already pinned to local-only conversion (`MARKITDOWN_ENABLE_PLUGINS=false`, `DOCLING_CONVERSION_MODE=local`). One unavoidable residual: every `npx -y <pkg>` first run hits the npm registry to download — not telemetry, but it is a phone-home; pre-install packages globally (`npm i -g`) and drop `npx` to avoid it.

## Language Server Protocol (LSP)

OpenCode v1 ships **native LSP support** (~30 built-in language servers) that feeds real-time diagnostics back into the agent loop so the agent can fix type/lint errors as it edits.

> **OpenCode v2 status:** V2 accepts and preserves `lsp` configuration but **does not run language servers, expose LSP tools, or produce diagnostics** — the block is inert (see [Supported fields without direct native equivalents](https://opencode.ai/v2/docs/migrate-v1/#supported-fields-without-direct-native-equivalents)). Until V2 reintroduces LSP, rely on the project's lint/typecheck/compiler commands — the verification gates in this repo's `AGENTS.md` already work that way.

**LSP is deliberately NOT enabled in the distributed config.** This repository is a configuration distributor (Markdown + JSON + shell + one vendored Python MCP server) — there is no application code here for an LSP to diagnose. Forcing LSP on every downstream project would hurt more than help (memory cost, version drift, slower agent workflows).

### Enabling LSP in a target project

In the target project's `opencode.json`, add an `"lsp"` field:

```jsonc
{
  // Enable all built-in servers (auto-installs the matching server per file extension)
  "lsp": true
}
```

Or enable selectively with overrides:

```jsonc
{
  "lsp": {
    "typescript": { "disabled": false },              // tsserver
    "python":    { "disabled": false },               // pyright
    "rust":      { "command": ["rust-analyzer"] }     // custom command
  }
}
```

### Built-in servers (subset)

| Language | Server | Language | Server |
|----------|--------|----------|--------|
| TypeScript/JS | tsserver | Python | pyright |
| Rust | rust-analyzer | Go | gopls |
| C/C++ | clangd | Java | jdtls |
| Ruby | ruby-lsp | Lua | lua-ls |
| Svelte/Vue/Astro | respective LS | Elixir | elixir-ls |
| Terraform | terraform-ls | Prisma | prisma |

Set `OPENCODE_DISABLE_LSP_DOWNLOAD=true` to prevent auto-downloads. (Both behaviors are V1-era; V2 performs no LSP downloads or server runs at all.)

### When to prefer a CLI check instead

For one-off validation the docs recommend running the compiler/linter directly (e.g. `tsc --noEmit`, `pyright`, `ruff`) — no persistent server, lower overhead. This repo's `language-linting-skill` already takes that approach. Use LSP when you want **continuous** feedback during agent editing sessions.

## Knowledge Persistence

Skills like `continuous-learning` persist knowledge across sessions using a dual strategy:

| Storage | Scope | Purpose |
|---------|-------|---------|
| `memory` tool | Primary, searchable by relevance | Quick facts, decisions, anti-patterns |
| `LEARNINGS/` in target projects | Curated, git-committed | Detailed patterns, ADRs, team conventions |
| `~/.config/opencode/learnings/` | User-level, cross-project | Personal preferences and patterns |

> **OpenCode v2 status:** the `memory` tool was provided by `opencode-superlocalmemory`, a V1-API plugin with no v2 release — **removed from the config** (it only produced boot warnings). `LEARNINGS/*.md` + auto-inject + `AGENTS.md` discovery is the memory layer. Watch-list to re-add when v2-compatible: `opencode-superlocalmemory`, `opencode-goal-plugin`, `@nick-vi/opencode-type-inject`, `opencode-scheduler` (check with `npm view <pkg> version` and the plugin's v2 compatibility notes).

**How it works:**
- `deploy/setup.sh` / `deploy/setup.ps1` creates `~/.config/opencode/learnings/` with 5 subfolders at user level
- When `continuous-learning` skill runs in a target project, it auto-provisions a `LEARNINGS/` directory in that project root
- Review agents (architecture-review, code-review) save findings to both memory tool and markdown files
- Agents discover learnings via AGENTS.md instructions (auto-loaded) + explicit file reads

## Secret Masking (vibeguard)

> **OpenCode v2 status:** shipped as a local V2 port (`opencode_app/.opencode/plugins/vibeguard.ts` — engine ported from `opencode-vibeguard@0.1.0`, MIT; see `plugins/ATTRIBUTION.md`). Masking is **active** on v2; the npm pin was removed from the `plugins` array (double-registration guard). Verify with `OPENCODE_VIBEGUARD_DEBUG=1 opencode`. The `permissions` deny rules for `*.env` remain the second layer.

Vibeguard (`opencode-vibeguard@0.1.0`) masks `.env` secrets in provider-bound traffic — the LLM provider never sees plaintext secret values, but tools (bash, write, etc.) receive real values at execution time. It is the **universal masking layer** covering all agents (primary + subagents), regardless of individual `read` deny rules in their `permissions` arrays.

**How it works:** regex patterns in `vibeguard.config.json` match known secret shapes (API keys, tokens, passwords, connection strings, PEM blocks, JWTs). Matched values are replaced with `__VG_…__` placeholders in LLM requests and restored at tool-execution time via a per-session map.

**Per-project keywords:** to catch exact-match secrets the regex misses, create an **uncommitted** `./vibeguard.config.json` at the project root with literal `keywords`. Note: first config found wins (no merge) — re-include the regex patterns from the global config if you need both.

**`$VAR` best practice:** always prefer `$ENV_VAR` references over inlining secret literals in scripts and configs. This is defense-in-depth: even if masking fails, the literal never enters the code.

**Residual risks (documented honestly):**
- **`/share` exports plaintext** — vibeguard has no `/share` hook. Never `/share` sessions that processed `.env` secrets.
- **No fail-closed** — if vibeguard is no-op (config missing/malformed), masking silently disappears. Run `OPENCODE_VIBEGUARD_DEBUG=1 opencode` to verify replace-counts > 0.
- **Session DB stores plaintext locally** — acceptable for "never expose to provider"; don't assume DB dumps are safe.
- **MCP structured output** — vibeguard redacts tool output only when it's a string; structured JSON objects bypass redaction (narrow risk — most MCP tools serialize to string).

For verification steps and detailed procedure, load `security-audit-skill` (now covers runtime secret masking).

## CodeGraph

[CodeGraph](https://github.com/colbymchenry/codegraph) is a pre-indexed code knowledge graph MCP server that enables agents to query symbol relationships, call graphs, and code structure instantly instead of scanning files with grep/glob/Read.

### Performance

| Metric | Without CodeGraph | With CodeGraph |
|--------|-------------------|----------------|
| Tool calls per exploration | 30-50+ | 1-6 |
| Exploration time | 1-2 minutes | 15-35 seconds |
| File reads | 10-20 | 0 |
| API key required | — | No (100% local) |

### Setup

CodeGraph is enabled by default in `opencode_app/opencode.json`. No API keys needed — it uses a local SQLite database.

**Per-project initialization** (required before tools work):

```bash
cd your-project
codegraph init -i
```

This creates a `.codegraph/` directory with an indexed SQLite database. Add `.codegraph/` to `.gitignore`. A file watcher auto-syncs changes as you code.

### MCP Tools

| Tool | Purpose |
|------|---------|
| `codegraph_search` | Find symbols by name across the codebase |
| `codegraph_explore` | Full exploration with source code sections (explore agents only) |
| `codegraph_context` | Build relevant code context for a task (explore agents only) |
| `codegraph_callers` | Find what calls a function |
| `codegraph_callees` | Find what a function calls |
| `codegraph_impact` | Analyze what code is affected by changing a symbol |
| `codegraph_node` | Get details about a specific symbol |
| `codegraph_files` | Get indexed file structure |
| `codegraph_status` | Check index health and statistics |

### Supported Languages

TypeScript, JavaScript, Python, Go, Rust, Java, C#, PHP, Ruby, C, C++, Swift, Kotlin, Dart, Svelte, Liquid, Pascal/Delphi, Scala, Vue (19+ languages).

### Subagent Benefits

| Subagent | CodeGraph Benefit |
|----------|-------------------|
| `explore` (built-in) | `codegraph_explore` replaces grep/glob chains |
| `code-review-subagent` | `codegraph_impact` assesses change radius before review |
| `architecture-review-subagent` | Call graph analysis for design evaluation |
| `testing-subagent` | `codegraph_affected` finds impacted tests by changed files |

## Skill Modularization

This repository implements **skill modularization** with 149 skills organized across 24 categories. <!-- count: hand-maintained — sync on skill add (BT-157) --> Skills are designed with clear separation of concerns and explicit dependencies.

> **Registry-derived (PLAN-GIT-286):** every skill + agent now carries a `category:` frontmatter field, which `deploy/build-registry.mjs` reads to emit `deploy/registry.json` — the single source of truth consumed by the `opencode-init` project-scoped installer and (regenerable into) this category table. To refresh after editing frontmatter: `node deploy/build-registry.mjs` (CI fails on drift via `--check`).

> **Migration Complete (BT-142):** The `pptx-specialist-*` stack has been migrated to chenyu's JSON-in-PPTX architecture. Final skill count is **123** (−1 `pptx-specialist-skill` decomposed, +3 chenyu skills, +2 new decomposition skills, +2 Academic & Research Writing skills added post-migration). See `PLANS/PLAN-BT-142.md` for the full plan. The legacy `pptx-specialist-skill` has been removed; all PPTX operations now route through `pptx-specialist-subagent` → `pptx-generate-slide-skill` / `pptx-generate-template-skill` / `pptx-template-modifier-skill`. Post-#283: +1 `zai-vision-analysis-skill` (Z.AI direct-API vision, free `glm-4.6v-flash`) → **125**; later **126** after `plan-automation-loop-skill` was added (Git/Workflow — `/run-plan` full-automation loop). Subsequent additions brought the total to **130**, including `zai-image-generation-skill` (Media Generation — Z.AI GLM-Image text-to-image, saves a PNG file). Post-#333: +1 `opencode-repo-setup-skill` (OpenCode Meta — per-repo MCP/project-config setup frontend) → **131**. Post-GIT-333: −1 `codegraph-setup-skill` (merged into `opencode-repo-setup-skill` §Step 4) → **130**. Post-GIT-338: −4 per-language linter skills (`python-ruff-linter`, `javascript-eslint-linter`, `java-linter`, `csharp-linter` merged into `language-linting-skill`) → **127**. Post-GIT-341: +6 vendored verbatim (pstack `unslop`/`technical-writing`/`blast-radius` @60c641e; ponytail `audit`/`review`/`debt` satellites v4.8.4) → **133**. Post-GIT-351: +1 `worktree-pipeline-skill` (Git/Workflow — `/run-worktree-pipeline` tracker-to-merged-PR pipeline via git worktrees) → **134**. Post-GIT-357: +3 media skills (`zai-video-skill`, `zai-asr-skill`, `zai-ocr-skill` — Media Generation, consumer-scoped to `zai-media-subagent`) → **137**. Post-skill-stack-simplification: +3 (`wayfinder-skill` vendored+adapted from mattpocock/skills MIT; `language-review-checklists-skill` extracted from language-reviewer; `reviewer-baseline-skill` shared reviewer boilerplate) and `ticket-plan-workflow-skill` renamed → `ticket-creation-skill` (creation-only; PLAN authoring absorbed into `worktree-pipeline-skill` §PLAN Authoring; new `/create-ticket` command) → **148**. Post-GIT-364: −1 `zai-vision-analysis-skill` (removed; native multimodal vision agents + their inline direct-API fallback recipe are the only path) → **147**. Post-#370: +1 `email-drafter-skill` (Communication — new category; business-email drafting) → **148**. Post-v2-audit: +1 `opencode-v2-migration-skill` (OpenCode Meta — v1→v2 detect/triage frontend; pairs with `opencode-v2-migration-subagent`, 34th agent, `reasoning` tier) → **149**.

### Skill Categories

| Category | Skills | Purpose |
|-----------|---------|---------|
| **Framework** (19) | test-generator-framework, linting-workflow, pr-creation-workflow, pr-merge-workflow, error-resolver-workflow, tdd-workflow, docx-creation, xlsx-specialist, pdf-specialist, frontend-design, uiux-review-skill, api-design-skill, openapi-contract-adherence-skill, performance-optimization-skill, srs-creation-skill, brd-creation-skill, technical-design-creation-skill, vision-creation-skill, interactive-document-rendering-skill | Generic workflows, testing patterns, document creation, UI design + review, API design, contract adherence, performance, and the document ladder (BRD/SRS/vision + technical design documents) |
| **Presentation** (3) | pptx-generate-slide-skill, pptx-generate-template-skill, pptx-template-modifier-skill | Template-driven PowerPoint generation — extract, fill, extend |
| **Office Utilities** (2) | ooxml-editing-skill, office-thumbnail-skill | Generic Office OOXML surgical edits and visual thumbnail/conversion |
| **Language-Specific** (6) | python-pytest-creator, language-linting, changelog-python-cliff, python-backend-skill, python-packaging-skill, fastapi-pydantic-orm-patterns-skill | Language-specific test, linting (Ruff/ESLint/Checkstyle/dotnet format), project scaffolding, packaging, and backend patterns |
| **Framework-Specific** (11) | nextjs-pr-workflow, nextjs-unit-test-creator, nextjs-standard-setup, nextjs-image-usage, nextjs-devtools-mcp, amplify-nextjs-deployment, typescript-dry-principle, accessibility-a11y-skill, react-hooks-antipatterns-skill, react-render-antipatterns-skill, threejs-nextjs-skill | Next.js 16, React 19, TypeScript, accessibility, Three.js integration, and AWS Amplify deployment |
| **Frontend Animation** (8) | gsap-core, gsap-timeline, gsap-scrolltrigger, gsap-plugins, gsap-utils, gsap-react, gsap-frameworks, gsap-performance | GSAP web-animation guidance — tweens/easing/stagger, timeline sequencing, ScrollTrigger scroll-linked animation + pinning, plugins (Flip, Draggable, SplitText…), utils helpers, React (`useGSAP`) and Vue/Svelte integration, performance optimization. Vendored from official greensock/gsap-skills (MIT — see THIRD_PARTY_LICENSES.md §5) |
| **OpenCode Meta** (6) | opencode-agent-creation, opencode-skill-creation, opencode-skills-maintainer, opencode-repo-setup, documentation-consistency-skill, opencode-v2-migration | Agent and skill creation/maintenance, documentation consistency auditing, per-repo MCP/project-config setup, v1→v2 migration detect/triage |
| **OpenTofu** (7) | opentofu-aws-explorer, opentofu-keycloak-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-provider-setup, opentofu-provisioning-workflow, opentofu-ecr-provision | Infrastructure as Code |
| **Git/Workflow** (15) | ascii-diagram-creator, mermaid-diagram-creator, ticket-creation-skill, plan-execution-skill, plan-automation-loop-skill, worktree-pipeline-skill, wayfinder-skill, git-issue-labeler, git-issue-updater, git-semantic-commits, semantic-release-convention, git-compact-commits, plan-updater, version-bump-standard, git-branch-workflow-setup-skill | Diagrams, git operations, release conventions, version bumping, compact commits, branch workflow orchestration, structured ticket creation via `/create-ticket` (creation-only; branch+PLAN+execution live in the pipeline), fully-automated per-phase plan execution (lint+build+test+e2e gate → per-step traceability → commit → push) via `/run-plan`, the tracker-ticket-to-merged-PR worktree pipeline via `/run-worktree-pipeline`, and oversized-work planning as decision-ticket maps (`wayfinder-skill`) |
| **Documentation** (5) | coverage-readme-workflow, docstring-generator, documentation-sync-workflow, unslop-skill, technical-writing-skill | Documentation generation |
| **Communication** (1) | email-drafter-skill | Business-email drafting — process, tone frames, slop checklist |
| **Academic & Research Writing** (2) | horseshoe-paper-writing-skill, research-paper-generation-skill | Academic & research paper writing (Horseshoe Diagram Method, journal-submission formats; codebase→paper generation) |
| **JIRA** (3) | jira-status-updater, jira-git-integration, jira-ticket-labeler | JIRA integration via MCP server |
| **Code Quality** (14) | solid-principles, clean-code, clean-architecture, design-patterns, object-design, code-smells, complexity-management, deprecated-code-cleanup-skill, blast-radius-skill, ponytail-audit-skill, ponytail-review-skill, ponytail-debt-skill, language-review-checklists-skill, reviewer-baseline-skill | Code quality analysis, patterns, and @deprecated code cleanup |
| **Agent Optimization** (7) | continuous-learning, eval-harness, strategic-compact, verification-loop, search-first, context-budget, agent-introspection-debugging | AI agent session optimization, research-first workflow, context auditing, and agent debugging |
| **Autoresearch** (4) | autoresearch-core-skill, autoresearch-ml-skill, autoresearch-code-skill, autoresearch-research-skill | Autonomous research loops: 5-stage Understand→Hypothesize→Experiment→Evaluate→Log methodology. ML training (GPU), code optimization, literature review. Evaluated by mechanical `{"pass":bool,"score":N}` — no LLM self-judgment. Ported from uditgoenka/autoresearch + karpathy/autoresearch (MIT). |
| **Startup/Business** (3) | startup-pitch-deck-skill, startup-business-docs-skill, construction-bd-skill | Startup pitch decks, business documentation, construction proposals |
| **Configuration** (2) | markitdown-mcp-skill, docling-mcp-skill | markitdown and docling MCP setup (CodeGraph init lives in `opencode-repo-setup-skill`) |
| **Security** (2) | security-audit-skill, authentication-authorization-skill | Security auditing, vulnerability scanning, and auth implementation |
| **DevOps** (5) | docker-containerization-skill, monorepo-management-skill, database-migration-skill, logging-observability-skill, aws-iac-safety-skill | Containerization, monorepos, database migrations, observability, and IaC safety |
| **Planning & Alignment** (4) | grilling-skill, domain-modeling-skill, grill-with-docs-skill, grill-me-skill | Relentless interview/grilling sessions and domain model (CONTEXT.md glossary + ADR) capture |
| **Responsive & Visual Testing** (2) | wireframer-skill, playwright-responsive-audit-skill | Low-fidelity wireframe/prototype generation and Playwright-driven responsive UI audit + fix (persistent PTY watch loop); screenshot analysis routes through `image-analyzer-subagent` (native vision tier) |
| **CAD & Hardware Design** (14) | cad-generation-skill, cad-viewer-skill, cad-step-parts-skill, cad-dxf-skill, cad-urdf-skill, cad-srdf-skill, cad-sdf-skill, cad-sendcutsend-skill, cad-gcode-skill, cad-bambu-labs-skill, cad-implicit-skill, autodesk-aps-skill, civil-3d-skill, open3d-skill | Parametric CAD generation (STEP/STL/3MF/GLB), CAD Viewer previews, off-the-shelf parts, DXF drawings, robot descriptions (URDF/SRDF/SDF), G-code slicing, 3D printing (Bambu Labs), SendCutSend validation, implicit CAD, Autodesk APS API integration, Civil 3D workflows, Open3D 3D data processing |
| **Media Generation** (4) | zai-image-generation-skill, zai-video-skill, zai-asr-skill, zai-ocr-skill | Z.AI PAYG media endpoints: text-to-image (GLM-Image, saves PNG), text/image-to-video (CogVideoX-3, async submit + PTY poll, saves MP4), audio transcription (GLM-ASR, wav/mp3 ≤25 MB ≤30 s), and layout-aware OCR (GLM-OCR, image/PDF) — all save artifacts to local files (OpenCode's chat-only providers cannot reach these endpoints) |

> **Note**: 6 redundant skills archived to `skills/_archived/`: `nextjs-complete-setup`, `python-docstring-generator`, `nextjs-tsdoc-documentor`, `git-pr-creator`, `git-issue-plan-workflow`, `jira-ticket-plan-workflow`. Use `docstring-generator` for all language docstrings (Python PEP 257, TypeScript TSDoc, Java Javadoc, C# XML docs). Use `ticket-creation-skill` for structured GitHub/JIRA ticket creation; branch/PLAN/execution are handled by `/run-worktree-pipeline`. 

### Agents

33→34 agent `.md` files (plus 4 config-builtin agents defined directly in `opencode.json`: `build`, `plan`, `explore`, `general`) provide specialized task handling. Note: the 2 `*-primary-agent` files (`startup-founder`, `office-document`) are routing hubs but are declared with `mode: subagent`.

#### Primary Agents

| Agent | Purpose | Permissions |
|-------|---------|-------------|
| **build** | Default agent for general tasks | Full access to all tools and subagents |
| **plan** | Read-only planning and analysis | `task`, `read`, `glob`, `grep` only (no write/execute) |
| **startup-founder-primary-agent** | Business docs - reports, quotations, spreadsheets, presentations | Full access (`read`, `edit`, `bash`, `webfetch`, `task`) |
| **office-document-primary-agent** | Office document specialist: Word, PowerPoint, Excel | Full access (`read`, `edit`, `bash`, `webfetch`, `task`) |

#### Subagents

| Subagent | Purpose | Skills | Built-in Delegation |
|----------|---------|--------|---------------------|
| **linting-subagent** | Code quality and style (Python, JS/TS, Java Spring Boot, C# .NET) | linting-workflow, language-linting | `explore` |
| **testing-subagent** | Test generation and execution | test-generator-framework, python-pytest-creator, nextjs-unit-test-creator | `explore` |
| **tdd-subagent** | Test-driven development workflow | tdd-workflow, test-generator-framework | — |
| **pr-workflow-subagent** | Pull request creation | pr-creation-workflow, nextjs-pr-workflow | `documentation-subagent`, `explore`, `general`, `image-analyzer-subagent` |
| **discovery-specialist-subagent** | Customer-facing discovery: Vision docs + wireframes | vision-creation-skill | `explore`, `image-analyzer-subagent`, `xlsx-specialist-subagent` |
| **requirements-specialist-subagent** | BRD + SRS drafting (BABOK/IIBA + IEEE 830) | brd-creation-skill, srs-creation-skill | `explore`, `image-analyzer-subagent`, `xlsx-specialist-subagent` |
| **technical-design-specialist-subagent** | Technical design + ADRs (engineering 'how' stage) | technical-design-creation-skill | `explore`, `image-analyzer-subagent`, `architecture-review-subagent` |
| **documentation-subagent** | Documentation generation | docstring-generator, coverage-readme-workflow | — |
| **coverage-subagent** | Coverage reporting | coverage-readme-workflow | — |
| **opentofu-explorer-subagent** | Infrastructure as code | 7 OpenTofu skills (AWS, K8s, Keycloak, Neon, ECR) | — |
| **architecture-review-subagent** | Architecture and design patterns | clean-architecture, design-patterns, complexity-management, continuous-learning, verification-loop | `explore` |
| **code-review-subagent** | Comprehensive code review | 9 Code Quality skills (incl. blast-radius evidence grading, ponytail lean lens) + continuous-learning, complexity-management | `explore`, `general` |
| **repo-ops-specialist-subagent** | Git repository operations | version-bump-standard, semantic-release-convention, pr-creation-workflow, pr-merge-workflow, git-issue-labeler | `explore`, `general` |
| **error-resolver-subagent** | Error diagnosis and resolution | error-resolver-workflow | — |
| **nextjs-specialist-subagent** | Next.js scaffolding + runtime MCP diagnosis + project audit | nextjs-standard-setup, nextjs-devtools-mcp, docstring-generator, nextjs-image-usage, react-hooks-antipatterns, react-render-antipatterns, amplify-nextjs-deployment | — |
| **opencode-tooling-subagent** | Skills, agents, and rules creation + doc sync | opencode-skill-creation, opencode-agent-creation, opencode-skills-maintainer, documentation-sync-workflow | — |
| **opencode-v2-migration-subagent** | OpenCode v1→v2 migration execution — config mapping, frontmatter conversion, plugin triage/ports, verification | opencode-v2-migration-skill | `explore` |
| **docx-creation-subagent** | Word document creation | docx-creation, unslop-skill, horseshoe-paper-writing-skill | — |
| **image-analyzer-subagent** | Image analysis (native multimodal `zai-coding-plan/glm-5.3-flash`) | (built-in vision) | — |
| **zai-media-subagent** | Media production: image/video generation, audio transcription, OCR via Z.AI PAYG skills; artifacts saved to disk, file paths returned | zai-image-generation, zai-video, zai-asr, zai-ocr | — |
| **responsive-audit-subagent** | Responsive UI audit and fix | playwright-responsive-audit-skill | `explore`, `general`, `image-analyzer-subagent` |
| **cad-specialist-subagent** | CAD, robotics, hardware design — orchestrates 14 CAD/engineering skills | cad-generation, cad-viewer, cad-step-parts, cad-dxf, cad-urdf, cad-srdf, cad-sdf, cad-sendcutsend, cad-gcode, cad-bambu-labs, cad-implicit, autodesk-aps-skill, civil-3d-skill, open3d-skill | — |
| **explorer-subagent** | Fast codebase exploration and analysis | (built-in search capabilities) | — |
| **pptx-specialist-subagent** | PowerPoint presentations (read, create, edit, analyze) | pptx-generate-slide, pptx-generate-template, pptx-template-modifier | — |
| **xlsx-specialist-subagent** | Spreadsheets (read, create, edit, analyze) | xlsx-specialist | — |
| **startup-ceo-subagent** | Startup presentations (pitch decks, investor slides, board updates) | pptx-specialist-subagent | — |
| **loop-operator-subagent** | Autonomous loop execution with self-correction | verification-loop, continuous-learning, strategic-compact | `explore`, `general` |
| **autoresearch-ml-subagent** | Autonomous ML training loop (Karpathy-style). Requires NVIDIA GPU. | autoresearch-core, autoresearch-ml, strategic-compact | `explore`, `general` |
| **autoresearch-code-subagent** | Autonomous code optimization (test coverage, bundle size, runtime) | autoresearch-core, autoresearch-code, continuous-learning, strategic-compact | `explore`, `general` |
| **autoresearch-research-subagent** | Literature review / paper synthesis (Tier 2 web-only, no Bash) | autoresearch-core, autoresearch-research, search-first, strategic-compact | `explore`, `general` |
| **language-reviewer-subagent** | Multi-language code review — Python, TypeScript/JS, Go, Rust, Java (idioms, type safety, concurrency, framework checks); thin orchestrator over `language-review-checklists-skill` | language-review-checklists, reviewer-baseline, solid-principles, clean-code, code-smells, design-patterns, python-backend, fastapi-pydantic-orm-patterns, database-migration, python-packaging, react-hooks/render-antipatterns, typescript-dry-principle, language-linting, deprecated-code-cleanup, continuous-learning, search-first | `explore`, `general` |
| **uiux-reviewer-subagent** | UI/UX design review (13-axis rubric: 6 AslanMazhidov + 5 RNT56 + Nielsen's 10 + anti-default AI cluster detection) | uiux-review-skill, frontend-design-skill, accessibility-a11y-skill, wireframer-skill | `explore`, `general`, `image-analyzer-subagent` |

> **Built-in Delegation**: Subagents with `explore` can delegate codebase scanning to the built-in `explore` subagent. Subagents with `general` can delegate parallelizable multi-step work to the built-in `general` subagent. Access is controlled via `task` permissions in each agent's frontmatter (`"*": deny` by default, explicit allowlist).

##### Subagent Nesting Depth

`opencode_app/opencode.json` sets `subagent_depth: 3` (opencode's default is `1`). This is required for nested delegation chains used by the autoresearch subagents and other deep workflows:

| Depth | Chain | Example |
|-------|-------|---------|
| `1` (opencode default) | primary → subagent | Blocks nesting entirely — autoresearch loops fail with "Subagent depth limit reached" |
| `2` | primary → subagent → 1 nested | Minimum for autoresearch to delegate research/exploration |
| `3` (set here) | primary → subagent → nested → one more | Comfortable headroom for autoresearch-code/ml/research loops |

Each extra level multiplies token cost (every nested subagent runs its own full context). Lower it to `2` for tighter runs; raise it only if a deeper chain hits the wall again. See the [OpenCode v2 config docs](https://opencode.ai/v2/docs/config/).

#### Trigger Phrases

Some subagents recognize natural language triggers:

| Subagent | Trigger Phrases |
|----------|-----------------|
| **pr-workflow-subagent** | "create pr", "pr merge to [branch]", "merge to main", "pull request" |
| **pptx-specialist-subagent** | "PowerPoint", ".pptx", "presentation", "slides", "deck", "html to pptx" |
| **startup-ceo-subagent** | "pitch deck", "investor deck", "board update", "fundraising", "demo day" |
| **uiux-reviewer-subagent** | "design review", "UI audit", "UX review", "visual review", "review UI design" |

### Iteration Protocol (opt-in)

The repository ships an **autoresearch iteration protocol** — a 5-stage loop (Understand → Hypothesize → Experiment → Evaluate → Log & Iterate) that 29 existing skills can opt into. The protocol is **off by default**; enable it via:

| Method | How |
|--------|-----|
| Environment variable | `export AUTORESEARCH_PROTOCOL=1` |
| Shell helper (after `setup.sh`) | `ar-enable` / `ar-disable` |
| Per-invocation | Set the env var inline before invoking the skill |

When enabled, retrofitted skills emit mechanical evaluator output `{"pass":bool,"score":N}` (no LLM self-judgment), append to `<skill>-results.tsv` audit trails, and auto-revert failed experiments via Git-as-memory. See `opencode_app/.opencode/skills/autoresearch-core-skill/references/iteration-safety.md` for safety blocks and prompt-injection boundaries.

**Retrofitted skills (29 total):**
- **Tier 1 (full loop, 7)**: verification-loop, tdd-workflow, eval-harness, continuous-learning, deprecated-code-cleanup, linting-workflow, coverage-readme-workflow
- **Tier 2 (partial, 7)**: documentation-consistency, error-resolver-workflow, opencode-skills-maintainer, plan-execution, pr-creation-workflow, pr-merge-workflow, playwright-responsive-audit
- **Tier 3 (light safety, 15)**: search-first, api-design, security-audit, code-smells, performance-optimization, typescript-dry-principle, solid-principles, clean-code, test-generator-framework, python-pytest-creator, nextjs-unit-test-creator, nextjs-pr-workflow, mermaid-diagram-creator, wireframer, frontend-design

**Maintenance:** `opencode-skills-maintainer-skill` includes a Citation drift audit rule that flags skills with iteration-keyword mentions lacking proper `autoresearch-core-skill/references/` citations.

### Ponytail (scoped wrapper plugin)

> **OpenCode v2 status:** ported to the V2 plugin API (`session.hook("context")` injection, `command.transform` for the `/ponytail*` commands) — active on v2. Env-var controls are unchanged.

[Ponytail](https://github.com/DietrichGebert/ponytail) (MIT, vendored at v4.8.4) makes coding agents write minimal necessary code via a 7-rung "lazy senior dev" ladder (YAGNI → reuse → stdlib → native → installed dep → one-liner → minimum-that-works). This repo ships a **scoped wrapper plugin** (`opencode_app/.opencode/plugins/ponytail-scoped.ts`) instead of the stock npm adapter — it adds agent-type-aware scoping the upstream OpenCode adapter lacks:

- **Read-only/research agents skip injection** (`explore`, `general`, `autoresearch-research-subagent`, `explorer-subagent`, `requirements-specialist-subagent`, `discovery-specialist-subagent`, `technical-design-specialist-subagent`) — they aren't pushed toward minimal code.
- **Per-agent mode overrides** via `PONYTAIL_AGENT_MODE_MAP` (JSON).
- **Zero runtime npm dependency** — vendored, works air-gapped. The stock `@dietrichgebert/ponytail` is deliberately NOT in the `plugin` array (double-injection guard).

| Env var | Default | Purpose |
|---------|---------|---------|
| `PONYTAIL_DEFAULT_MODE` | `full` | Global intensity: `lite` \| `full` \| `ultra` \| `off` |
| `PONYTAIL_SUBAGENT_OFF` | (7 read-only agents) | Regex of agent names to exclude from injection |
| `PONYTAIL_AGENT_MODE_MAP` | unset | JSON per-agent overrides, e.g. `{"build":"full","code-review-subagent":"lite"}` |

Switch mode per session: `/ponytail lite|full|ultra|off`, `/ponytail-help`. See `opencode_app/README.md` § Ponytail Plugin and `opencode_app/.opencode/plugins/ATTRIBUTION.md` for the MIT attribution.

### Learnings Auto-Inject (local plugin)

> **OpenCode v2 status:** ported to the V2 plugin API — the LEARNINGS manifest is auto-injected on v2.

`opencode_app/.opencode/plugins/learnings-autoinject.ts` closes the gap documented in `continuous-learning-skill`: *"OpenCode does NOT auto-scan LEARNINGS/ directories."* The `opencode-superlocalmemory` plugin auto-injects its **vector store**, but the git-committed `LEARNINGS/*.md` markdown files were never surfaced automatically — agents had to manually `glob`+`read`. This plugin injects a **compact manifest** (titles + paths + one-line summaries, ~200-400 tokens) into the system prompt at session start; the model `read()`s full bodies on demand.

- **Same architecture as ponytail-scoped** — 4 hooks (`config`, `chat.message`, `experimental.chat.system.transform`, `command.execute.before`), same toggle pattern.
- **Same off-set** — read-only/research agents skip injection (reuses ponytail's regex).
- **No `opencode.json` change** — local plugins are glob-discovered. `opencode-superlocalmemory` (removed pending a v2 release) injected a vector store via a different hook; no conflict — markdown manifest vs vectors.

| Env var | Default | Purpose |
|---------|---------|---------|
| `LEARNINGS_AUTOINJECT_DEFAULT` | `on` | Global on/off |
| `LEARNINGS_AUTOINJECT_USER` | `off` | Also scan `~/.config/opencode/learnings/` (user-level) |
| `LEARNINGS_AUTOINJECT_OFF` | (read-only agents) | Regex of agent names to exclude |
| `LEARNINGS_AUTOINJECT_MAX` | `30` | Cap on files in the manifest |

Toggle per session: `/learnings`, `/learnings-on`, `/learnings-off`, `/learnings-refresh`. See `opencode_app/.opencode/plugins/learnings-autoinject.README.md`.

### Skill Architecture

Skills follow a modular architecture:

```
┌─────────────────────────────────────────────────────┐
│              Framework Skills (Base)               │
│  test-generator-framework, linting-workflow, etc. │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│          Specialized Skills (Extension)            │
│  python-pytest-creator, language-linting, etc. │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│           Composite Skills (Workflow)               │
│  ticket-creation-skill + worktree-pipeline compose     │
└─────────────────────────────────────────────────────┘
```

### Configuration Files

The setup scripts automatically:
- Copies `deploy/.AGENTS.md` to `~/.config/opencode/AGENTS.md` (renaming it)
- Copies `opencode_app/.opencode/skills/` folder to `~/.config/opencode/skills/`
- Copies `opencode_app/opencode.json` to `~/.config/opencode/opencode.json` (single source of truth — model resolver patches primary/explore/general in-place during deploy; OpenCode v2 only reads `opencode.json`/`opencode.jsonc`, never `config.json`)
- Backs up existing files before overwriting

### Environment Variable Persistence

| Platform | Method | Location |
|----------|--------|----------|
| macOS / Linux / WSL | Shell rc file | `~/.bashrc` or `~/.zshrc` |
| Windows (Git Bash) | `setx` (registry) | Available in new sessions |
| Windows PowerShell | `$PROFILE` | `~\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |

### Template Files

This repository includes inline default configurations in all setup scripts. No external template files are required.

