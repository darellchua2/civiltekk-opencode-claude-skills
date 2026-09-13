# opencode_app — Docker Standalone Mode

This directory contains everything needed to run OpenCode as a standalone Docker container accessible via web browser.

## Quick Start

```bash
# From the repository root:
cp .env.example .env
# Edit .env — set ZAI_API_KEY=your-key-here
docker compose up -d
# Access at http://localhost:4097
```

## Directory Structure

```
opencode_app/
├── Dockerfile             # Multi-stage: node:24 + opencode-ai + python3
├── docker-entrypoint.sh   # Injects API keys, starts opencode serve
├── opencode.json          # Container-specific config (providers, agents)
├── AGENTS.md              # Agent instructions for container mode
├── .dockerignore          # Excludes _archived, .env, node_modules
└── .opencode/
    ├── agents/            # 33 agent .md files (single source of truth)
    └── skills/            # 148 skill directories + _common/ shared + _archived/ legacy
```

## How It Works

1. **Build**: `docker compose build` uses the **repo root** as build context (the Dockerfile lives in `opencode_app/`). It copies `opencode_app/` → `/app/` and `deploy/` → `/app/deploy/` (model-resolver assets). Agent models are **resolved at build time** from the tier registry (`deploy/agent-tiers.json` + `deploy/models.default.json`) — Z.AI by default. Swap provider at build: `docker compose build --build-arg OPENCODE_PROVIDER=anthropic`. See root `MIGRATION.md`.
2. **Runtime**: `docker-entrypoint.sh` reads API keys from environment variables, writes them to `auth.json`, then runs `opencode serve --port 4096 --hostname 0.0.0.0`.
3. **Access**: Port 4096 inside the container maps to 4097 on the host (configurable via `OPENCODE_PORT` in `.env`).

## Environment Variables

Set these in the root `.env` file (copied from `.env.example`):

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ZAI_API_KEY` | Yes | — | Z.AI API key (primary LLM provider; also auths web-reader + web-search MCP) |
| `GEMINI_API_KEY` | No | — | Gemini API key (secondary provider) |
| `OPENCODE_PORT` | No | `4097` | External host port |

## Docker Commands

```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down

# Rebuild after changes to agents/skills/config
docker compose build --no-cache

# Verify container contents
docker run --rm --entrypoint ls opencode_app-opencode /app/.opencode/agents/
docker run --rm --entrypoint ls opencode_app-opencode /app/.opencode/skills/
docker run --rm --entrypoint whoami opencode_app-opencode
```

## Provider Packs — Docker build-time MCP toggle (#268)

The opt-in MCP servers (`atlassian`, `next-devtools`, `markitdown`, `docling`, `chrome-devtools`) can be enabled as **groups** at image build time via the `OPENCODE_PACKS` build-arg, instead of editing `opencode.json` by hand. The `autodesk` pack is special: those 4 servers are not shipped in the base config, so the pack carries their full definitions. Packs are JSON partials in `deploy/packs/`; `deploy/merge-packs.mjs` deep-merges them into `/app/opencode.json` right after the model-resolver step.

```bash
# Enable one or more packs (comma-separated)
docker compose build --build-arg OPENCODE_PACKS=autodesk
docker compose up -d

# Available packs: autodesk, markitdown, nextjs, docling, chrome-devtools
# Empty/omitted = no-op (default OFF; existing images unaffected)
```

| Pack | Servers | Build-arg example |
|------|---------|-------------------|
| `autodesk` | adds autodesk-revit, -model-data, -fusion, -help (4; not in base config) | `--build-arg OPENCODE_PACKS=autodesk` |
| `markitdown` | markitdown (1) | `--build-arg OPENCODE_PACKS=markitdown` |
| `docling` | docling (1) | `--build-arg OPENCODE_PACKS=docling` (**heavy ~3-4 GB**; not baked by default — requires custom build) |
| `nextjs` | next-devtools (1) | `--build-arg OPENCODE_PACKS=nextjs` |
| `chrome-devtools` | chrome-devtools (1) | `--build-arg OPENCODE_PACKS=chrome-devtools` (privacy-hardened: telemetry + CrUX OFF; needs Chrome in image) |

The merge runs **after** `resolve-models.mjs` and only merges each pack's `mcp` + `permissions` keys (setting `mcp.servers.<name>.disabled: false` and appending `permissions`-array allow rules `{ "action": "<ns>*", "resource": "*", "effect": "allow" }`; the autodesk pack also carries the full server definitions since they are not in the base config) — it never turns an already-on server off, never touches the `plugins` array or `agents` block. Verify post-build:

```bash
docker compose run --rm opencode node -e "const c=require('/app/opencode.json');console.log(c.mcp['autodesk-revit'].enabled)"
# Expected: true
```

User-space equivalent: `./deploy/setup.sh --enable-pack <csv>` (see root `README.md` § Provider Packs).

> **Telemetry hardening — opt-in MCP servers ship with analytics pre-disabled.** `chrome-devtools` (`--no-usage-statistics`, `--no-performance-crux`, `--redact-network-headers`, `CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=1`) and `next-devtools` (`NEXT_TELEMETRY_DISABLED=1`) are hardened in `opencode.json` so `enabled: true` is safe without further edits. See root `README.md` § MCP Servers for the full rationale.

## Security

- Container runs as non-root `opencode` user
- No secrets baked into the image — API keys injected at runtime via entrypoint
- `.dockerignore` excludes `.env`, `_archived/`, and dev files
- Health check: `GET /global/health` every 30s

### Secret Masking (vibeguard)

The image ships with `vibeguard.config.json` baked into `.opencode/` — secret masking is **active by default**. Vibeguard masks secrets in provider-bound traffic (LLM requests) using regex patterns and restores real values at tool-execution time.

**Per-project overlay:** mount a `./vibeguard.config.json` to override the global config (first match wins, no merge — re-include regex patterns if you need both global + project keywords).

**Residual risks:**
- `/share` exports plaintext tool I/O — never share sessions that processed `.env` secrets.
- If vibeguard fails to load, masking silently disappears (bash/grep/MCP exposed).
- Session DB stores plaintext locally.
- MCP structured output bypasses redaction (narrow — most tools serialize to string).

## Updating Agents and Skills

Agents and skills live in `.opencode/agents/` and `.opencode/skills/`. These are the **single source of truth** shared with the user-space deployment (`setup.sh` copies from these same directories).

After modifying agents or skills (note: user-space uses `deploy/setup.sh`):

```bash
docker compose build --no-cache
docker compose up -d
```

## Iteration Protocol (opt-in)

The container ships the **autoresearch iteration protocol** — a 5-stage loop (Understand → Hypothesize → Experiment → Evaluate → Log & Iterate) that 30 retrofitted skills can opt into. The protocol is **off by default**.

To enable inside the container:
- Set `AUTORESEARCH_PROTOCOL=1` as an environment variable (e.g., add to `.env` and rebuild, or pass via `docker run -e AUTORESEARCH_PROTOCOL=1`)
- 3 new autonomous-research subagents (`autoresearch-ml-subagent`, `autoresearch-code-subagent`, `autoresearch-research-subagent`) are always-on; the env var only affects the 30 retrofitted skills.

See the main `README.md` § Iteration Protocol (opt-in) for the full skill list and the user-space equivalent (`ar-enable` / `ar-disable` shell helpers).

## CodeGraph

CodeGraph is a pre-indexed code knowledge graph MCP server enabled by default. It provides instant symbol search, call graph tracing, and impact analysis — reducing exploration tool calls by ~94%.

- **No API keys** — 100% local SQLite
- **Auto-sync** — file watcher keeps the index fresh
- **Per-project setup** required: `codegraph init -i` in each project directory

See the main `README.md` for full details on MCP tools, supported languages, and subagent integration.

## markitdown MCP (PLAN-GIT-262)

The privacy-hardened `markitdown` MCP launcher is **baked into the Docker image at build time** via `/opt/python-env/bin/pip install /app/mcp-servers/markitdown-local-mcp` (Dockerfile line 71). The `markitdown-local-mcp` binary lands in `/opt/python-env/bin`, which is already on `PATH` via the `ENV PATH="/opt/python-env/bin:${PATH}"` directive (Dockerfile line 33) — no entrypoint changes needed.

The server ships as `enabled: false` (opt-in). To enable inside the container, edit `opencode_app/opencode.json` and flip `markitdown.enabled` to `true`, then rebuild.

**Privacy guarantees** (see [`opencode_app/mcp-servers/markitdown-local-mcp/README.md`](mcp-servers/markitdown-local-mcp/README.md) for the full trust-boundary analysis):
- Structural dep exclusion — no `markitdown[all]`, no `azure-*`, no `SpeechRecognition`, no `youtube-transcript-api` installed
- `enable_plugins=False` hard-coded in launcher
- Local file conversions make zero TCP calls (verifiable via `ss -tnp`)
- User-supplied `http:`/`https:` URIs trigger a single `requests.get()` — equivalent to built-in `webfetch`, no Microsoft endpoints

## PPTX Workflow (BT-142)

The PPTX stack is **pure Python** (`python-pptx` + `lxml`) — no Node.js, Playwright, or Sharp required in the container for slide generation. The `pptx-specialist-subagent` orchestrates 3 skills:

- `pptx-generate-template-skill` — extracts a Slide Master template into a normalized JSON schema embedded at `ppt/template_schema.json` inside the PPTX zip
- `pptx-generate-slide-skill` — fills the template using `add_slide(layout)` (never builds from scratch); includes interactive overflow detection + `image-analyzer-subagent` visual verification
- `pptx-template-modifier-skill` — extends a template's slide master with borrowed layouts when a slide type is missing

**No bundled default template.** Users must supply a `.pptx` path; the engine does not ship or fall back to a `default.pptx`. When a masterless template is supplied, the engine synthesizes a minimal valid PPTX in-memory via `master_repairer._build_minimal_pptx_bytes()`.

**LibreOffice** (`soffice`) is required only for:
- `office-thumbnail-skill` (slide → PDF → PNG for visual analysis)
- OOXML validators in `ooxml-editing-skill` (post-decomposition, Phase 7)

The Dockerfile already installs LibreOffice; no additional setup needed.


## Subagent Chaining

OpenCode supports subagent-to-subagent delegation via the Task tool, controlled by the subagent-spawn permission in each agent `.md` frontmatter (legacy `permission.task` spelling — v2 auto-translates). Key points:

- **Task tool** (subagent spawning) and **Skill tool** (skill loading) are separate systems with separate permissions
- Agent name = filename minus `.md` (e.g., `code-review-subagent.md` -> `code-review-subagent`)
- Each spawned subagent gets its own session, context window, and step budget
- Hub-and-spoke (primary agent -> subagent) remains the recommended pattern
- 22 of 33 agents have explicit `task` permissions; the remaining 11 default to full access

## Ponytail Plugin (scoped wrapper)

[Ponytail](https://github.com/DietrichGebert/ponytail) (MIT, vendored at v4.8.4) makes coding agents write minimal necessary code via a 7-rung "lazy senior dev" ladder. This container ships a **scoped wrapper plugin** (`opencode_app/.opencode/plugins/ponytail-scoped.ts`) — not the stock npm adapter — because the stock adapter injects into ALL agents unconditionally and its `PONYTAIL_SUBAGENT_MATCHER` is non-functional on OpenCode. The wrapper scopes injection by agent type.

### Commands

| Command | What it does |
|---------|--------------|
| `/ponytail [lite\|full\|ultra\|off]` | Set intensity, or report current mode with no argument |
| `/ponytail-help` | Quick command reference |
| `/ponytail-lite` | Switch to lite (name the lazier alternative, user picks) |
| `/ponytail-full` | Switch to full (the ladder enforced — default) |
| `/ponytail-ultra` | Switch to ultra (YAGNI extremist, deletion before addition) |
| `/ponytail-off` | Turn off for this session |

### Environment Variables

Set in `.env` (see `.env.example`):

| Variable | Default | Description |
|----------|---------|-------------|
| `PONYTAIL_DEFAULT_MODE` | `full` | Global intensity: `lite` \| `full` \| `ultra` \| `off` |
| `PONYTAIL_SUBAGENT_OFF` | (built-in 7-agent list) | Regex of agent names that skip injection. Empty = use the default off-set |
| `PONYTAIL_AGENT_MODE_MAP` | unset | JSON per-agent overrides, e.g. `{"build":"full","code-review-subagent":"lite"}` |

### Agent Off-Set (default)

These read-only / research agents do NOT receive ponytail injection (they shouldn't be pushed toward minimal code):

- `explore`, `general`, `autoresearch-research-subagent`, `explorer-subagent`, `requirements-specialist-subagent`, `discovery-specialist-subagent`, `technical-design-specialist-subagent`

Override by setting `PONYTAIL_SUBAGENT_OFF` to a custom regex.

### How It Works

1. `chat.message` hook caches `sessionID → agent` (the agent type arrives here).
2. `experimental.chat.system.transform` hook resolves the agent (cache, or `client.session.get()` fallback), checks the off-set regex, resolves the mode, and appends the mode-filtered ruleset to the system prompt — once per turn (idempotent).
3. `command.execute.before` hook persists `/ponytail <level>` switches per session.

The vendored ruleset + adapted instruction builder live in `opencode_app/.opencode/plugins/ponytail/`. MIT attribution: `opencode_app/.opencode/plugins/ATTRIBUTION.md`. The stock `@dietrichgebert/ponytail` npm package is deliberately NOT in `opencode.json` `plugin` array (double-injection guard).

## Learnings Auto-Inject Plugin

`opencode_app/.opencode/plugins/learnings-autoinject.ts` auto-injects a **compact manifest** of a project's `LEARNINGS/*.md` files into the system prompt at session start, so the model knows what learned knowledge exists without a `glob`+`read` round-trip. It injects only titles + paths + a one-line summary (~200-400 tokens); the model `read()`s full file bodies on demand. This closes the gap documented in `continuous-learning-skill` (*"OpenCode does NOT auto-scan LEARNINGS/ directories"*). Architecture mirrors `ponytail-scoped.ts` (same 4 hooks, same toggle pattern, same off-set).

### Commands

| Command | What it does |
|---------|--------------|
| `/learnings` | Report on/off state + file count for this session |
| `/learnings-on` | Enable manifest injection for this session |
| `/learnings-off` | Disable manifest injection for this session |
| `/learnings-refresh` | Re-scan `LEARNINGS/` and rebuild the manifest on the next turn |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LEARNINGS_AUTOINJECT_DEFAULT` | `on` | Global on/off |
| `LEARNINGS_AUTOINJECT_USER` | `off` | Also scan `~/.config/opencode/learnings/` (user-level) |
| `LEARNINGS_AUTOINJECT_OFF` | (built-in read-only agent set) | Regex of agent names that skip injection (mirrors ponytail) |
| `LEARNINGS_AUTOINJECT_MAX` | `30` | Cap on files included in the manifest |

### How It Works

1. `chat.message` hook caches `sessionID → agent`.
2. `experimental.chat.system.transform` hook resolves the agent, checks the toggle + off-set, and appends the cached manifest to the system prompt — once per turn (idempotent). The manifest is globbed once per session and cached (rebuilt on `/learnings-refresh`).
3. `command.execute.before` hook persists `/learnings-on|off|refresh` per session.

No `opencode.json` change required — local plugins are glob-discovered. No conflict with `opencode-superlocalmemory` (different store: markdown vs vectors; different hook: `experimental.chat.system.transform` vs `tui.prompt.append`). Reference: `opencode_app/.opencode/plugins/learnings-autoinject.README.md`.

## Scheduler Plugin (cron jobs)

[`opencode-scheduler@1.3.0`](https://github.com/different-ai/opencode-scheduler) (in `opencode.json` `plugin[]`) runs recurring agent jobs via the **OS-native scheduler** — launchd (macOS), systemd (Linux), Task Scheduler (Windows), with cron fallback. Jobs are workdir-scoped, supervised (no overlap, optional `timeoutSeconds` SIGTERM→SIGKILL), and forced non-interactive (`OPENCODE_PERMISSION` denies question prompts so headless runs never hang). Manage in natural language: *"Schedule a daily job at 9am to…"*, list/update/run-now/logs/delete.

**Docker caveat:** the standalone container has no systemd/launchd (and usually no cron), so scheduled jobs do not fire in-container. For the Docker deployment, schedule on the host instead (host cron/systemd timer calling `docker compose exec` / `opencode run`). User-space deploys via `setup.sh` work natively.
