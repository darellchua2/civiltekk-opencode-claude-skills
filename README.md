# CivilTekk OpenCode & Claude Skills

A personal software-development skills collection — the agents, skills, and pipeline tooling I use daily — shared so you can take **a single skill** or adopt **the whole stack**.

- **146 ready-to-load skills + 34 specialist subagents**, natively targeting **OpenCode v2**
- **Same skills install to other harnesses**: Claude Code, Kimi Code, Kilo Code, and the cross-tool `~/.agents/` standard (Agent Skills open format)
- A **robust application-development pipeline**: ticket → PLAN → gated execution → review → merged PR, driven by a handful of slash commands

> **v2.0.0 upgrade?** See [`MIGRATION.md`](./MIGRATION.md) for breaking changes (stale agent cleanup, zip backup format, new `--rollback` / `--no-zip-backup` flags) and rollback instructions.

## Daily-driver commands

These four commands carry most of my day-to-day flow. **Slash commands ship with a full deploy** — a single-skill `npx add` install gives you the skills (invoked by natural language), not the command bindings.

| Command | What it does |
|---------|--------------|
| `/create-ticket` | Structured GitHub issue or JIRA ticket — platform detection, intake validation, labels. Ticket only: no branch, no PLAN, no execution. |
| `/run-worktree-pipeline` | Tracker-ticket-to-merged-PR pipeline via git worktrees — sync, PLAN authoring, adaptive review, gated execution, code review, PR merge. Usage: `/run-worktree-pipeline [--dry-run] [base-branch] <ticket-refs...>` |
| `/run-plan` | Fully-automated per-phase PLAN execution with a tiered verification gate (scoped lint + typecheck + affected tests per phase; full gate on anchors and at exit), per-step traceability → commit → push. |
| `/goal` | Session goal tracking with budgets and auto-continue (server-side, from the goal plugin). |

The first two compose: `/create-ticket` makes the ticket, `/run-worktree-pipeline #NNN` takes it to a merged PR.

## Installation

Three ways in, pick by appetite. All commands below work from any clone of this repo.

### 1. Take one skill (or agent) — the shadcn model

No clone needed; `npx` copies the skill directory into your config. See [issue #304](https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/304).

```bash
npx github:darellchua2/civiltekk-opencode-claude-skills add solid-principles-skill   # one skill
npx github:darellchua2/civiltekk-opencode-claude-skills add tdd-subagent             # agent + its required skills
npx github:darellchua2/civiltekk-opencode-claude-skills                              # bare = interactive TUI catalog
npx github:darellchua2/civiltekk-opencode-claude-skills remove solid-principles-skill
```

**Other harnesses** — skills follow the [Agent Skills](https://agentskills.io) open standard; `--target` controls the destination:

| Target | Destination | Notes |
|--------|-------------|-------|
| `opencode` (default) | `~/.config/opencode/{skills,agents}/` | Full opencode compat (model injection, strict-allowlist detection) |
| `claude` | `~/.claude/skills/` · agents `~/.claude/agents/` | Skills verbatim (`model:` stripped); agents get additive `tools:`/`disallowedTools:` translation |
| `agents` | `~/.agents/{skills,agents}/` | Cross-tool shared dir — read by Kimi Code and pi; verbatim copies |
| `kimi` | `~/.kimi-code/{skills,agents}/` (user) · `.kimi-code/` (project) | Kimi Code native dirs; additive frontmatter translation |
| `kilo` | `~/.config/kilo/agent/` + `~/.kilo/skills/` (user) · `.kilo/` (project) | Kilo Code native dirs; additive `permission:`-map translation |
| `both` | opencode + Claude Code paths | Agents install to opencode only |

`--project` installs into `./.opencode/` (full-service config generation) instead of user scope. `--no-deps` skips declared skill prerequisites.

### 2. Full deploy — the whole stack

Copies config + agents + skills to `~/.config/opencode/` and installs two PATH commands (`opencode-setup` to re-run the deploy from anywhere, `opencode-init` for project-scoped installs).

```bash
./deploy/setup.sh                 # interactive
./deploy/setup.sh --quick --yes   # non-interactive: config + skills, skip dependency checks
# Windows: powershell -ExecutionPolicy Bypass -File .\deploy\setup.ps1 -Quick -Yes
# No clone? npx -p github:darellchua2/civiltekk-opencode-claude-skills opencode-setup --quick --yes
```

Provider swap (Z.AI default): `./deploy/setup.sh --provider anthropic|openai|openrouter|zai` — agent models are tier-based and provider-agnostic (details in the collapsed reference below). Full flag table: `./deploy/setup.sh --help`, or the [collapsed reference](#full-setup-reference) at the end.

### 3. Per-project subset — presets

Not every project needs 34 agents + 146 skills. `opencode-init` installs a curated preset into `./.opencode/` (clean-slate isolation; additive over a global deploy — it warns):

```bash
opencode-init --list categories                              # introspect (JSON)
opencode-init --expand review                                # preview the resolved set
opencode-init --project . --preset review --yes              # install
npx github:darellchua2/civiltekk-opencode-claude-skills --project . --preset review --yes   # no prior deploy needed
```

| Preset | Use for |
|--------|---------|
| `core` | Minimal baseline (explorer + git-semantic-commits, continuous-learning, codegraph) |
| `review` | Code quality gates (code/architecture/language reviewers + 31 skills) |
| `frontend` | Web frontend (Next.js/React/a11y + uiux-reviewer, responsive-audit) |
| `backend` | Server / devops-lite (Python/DB/API/security + language-reviewer) |
| `docs` | Document generation (documentation + coverage + office docs) |
| `devops` | Git / infra / release (repo-ops + opentofu-explorer) |
| `business` | BD / founder workflows (discovery → requirements → technical-design) |
| `research` | Autonomous loops (autoresearch ml/code/research; ml needs GPU) |
| `cad` | CAD / robotics / hardware (cad-specialist + 15 CAD skills) |

### Docker — the whole setup as a browser endpoint

```bash
cp .env.example .env   # set ZAI_API_KEY=…
docker compose up -d   # → http://localhost:4097
```

See [Docker: run the whole setup in a browser](#docker-run-the-whole-setup-in-a-browser).

## Directory structure

```
civiltekk-opencode-claude-skills/
├── skills/                      # 146 skill directories (source of truth)
├── agents/                      # 34 subagent .md files (source of truth)
├── plugins/                     # Local OpenCode plugins (vibeguard, ponytail, learnings, auto-continue, question-repair)
│   └── vibeguard.config.json    # Secret-masking regex patterns
├── deploy/                      # User-space deployment (setup.sh = bin: opencode-setup)
├── installer/                   # npx installer (init.mjs = bin: opencode-skill; registry, tiers, presets)
├── opencode_app/                # Docker standalone mode (see Docker section)
├── tests/                       # bats test suite (guards counts, isolation, portability)
├── PLANS/                       # Execution plans per ticket (git-committed history)
├── LEARNINGS/                   # Knowledge-persistence skeleton (auto-provisioned in target projects)
├── docker-compose.yml           # Docker Compose service definition
├── restart-opencode-docker.sh   # Pull main + redeploy the container (compose up -d --build)
├── .env.example                 # Environment variable template
├── MIGRATION.md                 # v1.x → v2.0 migration guide
├── THIRD_PARTY_LICENSES.md      # Vendored-skill attributions (MIT/Apache-2.0)
└── .env                         # Local environment (git-ignored)
```

`skills/` and `agents/` are the single source of truth — edit there, then redeploy. Never edit deployed `~/.config/opencode/` copies. Every skill directory is fully self-contained (the `npx add` copy model — enforced by `tests/test_skill_isolation.bats`).

## Docker: run the whole setup in a browser

`opencode_app/` exists for one purpose: **run this entire repository as a self-hosted OpenCode web endpoint** — a browser UI over the full stack (all agents, skills, plugins) with zero local install. The container builds the repo content into `/app/.opencode/`, injects your API key from `.env`, serves `opencode serve` on port 4097, and health-checks itself.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ZAI_API_KEY` | Yes | — | Z.AI API key (primary LLM provider) |
| `GEMINI_API_KEY` | No | — | Gemini API key (secondary provider) |
| `OPENCODE_PORT` | No | `4097` | External port mapping |

```bash
docker compose up -d            # start
docker compose logs -f          # logs
docker compose build --no-cache # rebuild after changes
./restart-opencode-docker.sh    # pull main + redeploy + health-check (maintainer convenience)
```

Full details: [`opencode_app/README.md`](./opencode_app/README.md).

## Support & reporting issues

Both issue forms enforce a search-first attestation and structured fields — a complete report gets fixed faster:

- **[🐞 Bug report](https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/new?template=bug_report.yml)** — unexpected behavior or a broken feature
- **[🚀 Feature request](https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/new?template=feature_request.yml)** — new capability or enhancement

Blank issues are disabled; pick a template. Include your environment (OS, Node, opencode version, install method) for bugs.

Want to contribute a skill or agent? See [`CONTRIBUTING.md`](./CONTRIBUTING.md).

## Prerequisites

- **Node.js v20+** and npm (setup scripts can install Node for you; nvm recommended)
- An API key for your provider (Z.AI default; Anthropic/OpenAI/OpenRouter via `--provider`)
- **GitHub CLI** (`gh`) — recommended for ticket/PR flows (`gh auth login`)
- **ripgrep** (`rg`) — recommended, faster search; falls back to `grep`

---

# Deep reference

Everything below is detail you rarely need at first install — expanded on demand.

<details>
<summary><strong>Model resolution (v2.0) — tier-based, provider-agnostic</strong></summary>

Agent models are **tier-based and provider-agnostic**. Source agent files contain no hardcoded model — each agent is categorized into a tier (`reasoning` / `fast` / `docs` / `vision` / `long-context`) in `installer/agent-tiers.json`, and the concrete model is resolved at deploy time:

```bash
./deploy/setup.sh --provider anthropic      # or: openai, openrouter, zai (default)
./deploy/setup.sh --mix                     # mix providers per tier
./deploy/setup.sh --models-only             # re-resolve models only
```

Override precedence (highest first):

| File | Scope |
|------|-------|
| `<project>/.opencode/agent-overrides.json` | per-agent pin, project-local |
| `~/.config/opencode/agent-overrides.json` | per-agent pin, global |
| `<project>/.opencode/models.json` | tier map, project-local |
| `~/.config/opencode/models.json` | tier map, global (written by `--provider`) |
| `installer/models.default.json` | Z.AI defaults |

> **Vision tier (Z.AI):** `image-analyzer-subagent` + `error-resolver-subagent` + `uiux-reviewer-subagent` + `zai-media-subagent` run on `zai-coding-plan/glm-5.3-flash` (native multimodal — image/video/pdf input, 1M ctx). When native perception is unavailable, they fall back to the inline recipe embedded in `image-analyzer-subagent`, calling the same model via direct API. Requires `opencode auth login` (Z.AI) or `ZAI_API_KEY` (auto-injected in Docker).

| Tier | Use for |
|------|---------|
| `reasoning` | Correctness-critical: reviewers, repo-ops, tdd, migration, pptx, technical-design, discovery, requirements |
| `fast` | Exploratory/low-impact: explorer, testing, nextjs/cad/office specialists, document creators, pr-workflow, startup agents |
| `docs` | documentation, linting, coverage |
| `long-context` | Large-context research/code loops: autoresearch-ml/code/research |
| `vision` | Native multimodal: image-analyzer, error-resolver, uiux-reviewer, zai-media |

See `AGENTS.md` § Subagent Model Tiering for the full table.
</details>

<details>
<summary><strong>MCP servers, provider packs, and skill profiles</strong></summary>

The configuration ships 8 MCP server entries. **3 are enabled by default:**

| Server | Type | Purpose |
|--------|------|---------|
| `codegraph` | local (npx) | Pre-indexed code knowledge graph |
| `zai-web-reader` | remote | Web page content extraction |
| `zai-web-search` | remote | Web search with cited results |

The remaining 5 ship `disabled: true` and are opt-in: `atlassian` (JIRA/Confluence OAuth), `next-devtools` (Next.js DevTools), `markitdown` (document-to-Markdown, plugins off), `docling` (layout-aware extraction, ~3-4 GB), `chrome-devtools` (live Chrome automation, telemetry pre-disabled).

To enable one for a single project, add it to the project's `opencode.json` as a **full entry** (v2 replaces `mcp.servers.<name>` atomically — a bare `{"disabled": false}` stub is inert):

```json
{ "mcp": { "servers": { "atlassian": { "type": "local", "command": ["npx", "-y", "mcp-remote", "https://mcp.atlassian.com/v1/mcp"], "disabled": false } } } }
```

Globally: set `"disabled": false` in `~/.config/opencode/opencode.json`, or use a provider pack. The `opencode-repo-setup-skill` automates per-project enablement interactively.

**Provider packs** — one flag flips a logical group ON at deploy time (packs are JSON partials in `deploy/packs/`):

| Pack | Servers enabled | Requires |
|------|----------------|----------|
| `autodesk` | adds autodesk-revit, autodesk-model-data, autodesk-fusion, autodesk-help | `AUTODESK_API_KEY` |
| `markitdown` | markitdown | Python server (auto-installed by setup.sh) |
| `docling` | docling | Python + `docling-mcp[local]` (~3-4 GB) |
| `nextjs` | next-devtools | A running Next.js dev server |
| `chrome-devtools` | chrome-devtools | Chrome stable (telemetry + CrUX pre-disabled) |

```bash
./deploy/setup.sh --enable-pack autodesk,markitdown   # multiple packs, comma-separated
docker compose build --build-arg OPENCODE_PACKS=autodesk,markitdown   # Docker build-time
```

Default state of every pack is **OFF**. Design history: [issue #268](https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/268).

**Skill profiles** — deploy-time primary visibility (#333). Every allowed skill's `description` loads into the primary session at startup (~90 tokens each). Default deploy is **lean** (70 primary-visible skills + deny-all, ~3.2k tokens saved); subagents are profile-immune and all 146 skills stay on disk:

```bash
./deploy/setup.sh                     # default: lean
./deploy/setup.sh --skill-profile full  # shipped allowlist verbatim
./deploy/setup.ps1 -SkillProfile full   # Windows parity
```

> **Interim workaround (#481):** the 4 reviewer agents' 26-skill union is temporarily primary-visible in lean because opencode v2.0.11 ignores agent-frontmatter `skill` allows in child sessions ([upstream anomalyco/opencode#50149](https://github.com/anomalyco/opencode/issues/50149)). This note is the deferral record.

**Notes:**
- `filesystem` MCP is **permanently removed** — built-in `read`/`write`/`edit`/`glob`/`grep`/`bash` cover it; a filesystem MCP caused tool-selection ambiguity.
- Opt-in servers ship **telemetry pre-disabled**: chrome-devtools (`--no-usage-statistics`, `--no-performance-crux`, `--redact-network-headers`, update-check off) and next-devtools (`NEXT_TELEMETRY_DISABLED=1`). The enabled `zai-*` servers send data by design (that is their function); `codegraph` is purely local.
- `markitdown` runs the official PyPI server pinned `==0.0.1a7` with `MARKITDOWN_ENABLE_PLUGINS=false` — cloud extras present-but-dormant; residual: audio input uploads to Google Speech, YouTube URLs contact YouTube. Local file conversions make no network calls.
- `docling` is pinned to local conversion (`DOCLING_CONVERSION_MODE=local`).
- Every `npx -y <pkg>` first run hits the npm registry to download — not telemetry, but it is a phone-home; pre-install globally to avoid.
</details>

<details>
<summary><strong>Plugins — vibeguard, ponytail, learnings auto-inject, auto-continue, question repair</strong></summary>

Five local plugins ship in `plugins/` — zero runtime npm dependencies, air-gap safe, active on OpenCode v2.

**Vibeguard (secret masking).** Masks `.env` secrets in provider-bound traffic via regex patterns (`vibeguard.config.json`); the LLM provider never sees plaintext values, tools receive real values at execution time. Verify with `OPENCODE_VIBEGUARD_DEBUG=1 opencode` (replace-counts > 0). Per-project keywords: uncommitted `./vibeguard.config.json` at project root (first config wins — re-include the global patterns). Residual risks (documented honestly): `/share` exports plaintext (never share sessions that processed secrets); no fail-closed if config is missing; session DB stores plaintext locally; MCP structured (non-string) output bypasses redaction. Prefer `$ENV_VAR` references over inline literals in everything you generate.

**Ponytail (minimal-code enforcement).** [Ponytail](https://github.com/DietrichGebert/ponytail) v4.10.0 (MIT, vendored) — the 7-rung "lazy senior dev" ladder (YAGNI → reuse → stdlib → native → installed dep → one-liner → minimum-that-works), injected into coding agents via a **scoped wrapper** (`plugins/opencode-ponytail-scoped.ts`): read-only/research agents skip injection; per-agent mode overrides via `PONYTAIL_AGENT_MODE_MAP`; `/ponytail lite|full|ultra|off` per session, `/ponytail default <mode>` persists under the opencode data dir. Skill-only installs ship the wrapper plugin alongside the ponytail skills (#533); non-opencode targets get a notice.

**Learnings auto-inject.** Injects a compact manifest (~200-400 tokens) of `LEARNINGS/*.md` titles + paths into the system prompt at session start; the model `read()`s bodies on demand. Same off-set as ponytail (read-only agents). `/learnings`, `/learnings-on|off`, `/learnings-refresh`. Env: `LEARNINGS_AUTOINJECT_DEFAULT` (on), `LEARNINGS_AUTOINJECT_USER` (off), `LEARNINGS_AUTOINJECT_MAX` (30).

**Auto-continue v2.** Self-heals long-running sessions on transient provider errors (SSE timeouts, ECONNRESET, context overflow, tool-protocol failures) by sending "continue" with exponential backoff at idle boundaries — never aborts a live runner, never resumes a user-cancelled session (ESC latch). Hard cap 5 consecutive (reset by a real user message). Env prefix: `OPENCODE_AUTO_CONTINUE_*`.

**Question repair.** Normalizes malformed `question` tool payloads before the schema validator hard-fails (fills missing `label`/`description`/`question`/`header` from their counterparts, defaults `multiple`, drops beyond-repair items). Valid payloads pass through as the same reference. Debug: `OPENCODE_QUESTION_REPAIR_DEBUG=1` at server start.

Attribution: `plugins/ATTRIBUTION.md`; skill-level attributions in `THIRD_PARTY_LICENSES.md`.
</details>

<details>
<summary><strong>Skill catalog — 146 skills by category</strong></summary>

Current count: **146** (history: 123 after the BT-142 pptx migration → consolidations and vendoring brought it to 146; 6 superseded skills archived under `skills/_archived/`).

| Category | Skills | Purpose |
|-----------|---------|---------|
| **Framework** (19) | test-generator-framework, linting-workflow, pr-creation-workflow, pr-merge-workflow, error-resolver-workflow, tdd-workflow, docx-creation, xlsx-specialist, pdf-specialist, frontend-design, uiux-review-skill, api-design-skill, openapi-contract-adherence-skill, performance-optimization-skill, srs-creation-skill, brd-creation-skill, technical-design-creation-skill, vision-creation-skill, interactive-document-rendering-skill | Generic workflows, testing patterns, document creation, UI design + review, API design, contract adherence, performance, and the document ladder (BRD/SRS/vision + technical design documents) |
| **Presentation** (3) | pptx-generate-slide-skill, pptx-generate-template-skill, pptx-template-modifier-skill | Template-driven PowerPoint generation — extract, fill, extend |
| **Office Utilities** (2) | ooxml-editing-skill, office-thumbnail-skill | Generic Office OOXML surgical edits and visual thumbnail/conversion |
| **Language-Specific** (6) | python-pytest-creator, language-linting, changelog-python-cliff, python-backend-skill, python-packaging-skill, fastapi-pydantic-orm-patterns-skill | Language-specific test, linting (Ruff/ESLint/Checkstyle/dotnet format), project scaffolding, packaging, and backend patterns |
| **Framework-Specific** (10) | nextjs-unit-test-creator, nextjs-standard-setup, nextjs-image-usage, nextjs-devtools-mcp, amplify-nextjs-deployment, typescript-dry-principle, accessibility-a11y-skill, react-hooks-antipatterns-skill, react-render-antipatterns-skill, threejs-nextjs-skill | Next.js 16, React 19, TypeScript, accessibility, Three.js integration, and AWS Amplify deployment |
| **Frontend Animation** (8) | gsap-core, gsap-timeline, gsap-scrolltrigger, gsap-plugins, gsap-utils, gsap-react, gsap-frameworks, gsap-performance | GSAP web-animation guidance — tweens/easing/stagger, timeline sequencing, ScrollTrigger, plugins, utils helpers, React (`useGSAP`) and Vue/Svelte integration, performance. Vendored from official greensock/gsap-skills (MIT) |
| **OpenCode Meta** (6) | opencode-agent-creation, opencode-skill-creation, opencode-skills-maintainer, opencode-repo-setup, documentation-consistency-skill, opencode-v2-migration | Agent and skill creation/maintenance, documentation consistency auditing, per-repo MCP/project-config setup, v1→v2 migration detect/triage |
| **OpenTofu** (7) | opentofu-aws-explorer, opentofu-keycloak-explorer, opentofu-kubernetes-explorer, opentofu-neon-explorer, opentofu-provider-setup, opentofu-provisioning-workflow, opentofu-ecr-provision | Infrastructure as Code |
| **Git/Workflow** (14) | ascii-diagram-creator, mermaid-diagram-creator, ticket-creation-skill, plan-execution-skill, worktree-pipeline-skill, wayfinder-skill, git-issue-labeler, gh-cli-setup-skill, git-issue-updater, git-semantic-commits, semantic-release-convention, git-compact-commits, version-bump-standard, git-branch-workflow-setup-skill | Diagrams, git operations, release conventions, version bumping, compact commits, branch workflow orchestration, structured ticket creation via `/create-ticket`, fully-automated per-phase plan execution via `/run-plan`, the tracker-ticket-to-merged-PR worktree pipeline via `/run-worktree-pipeline`, and oversized-work planning as decision-ticket maps |
| **Documentation** (5) | coverage-readme-workflow, docstring-generator, documentation-sync-workflow, unslop-skill, technical-writing-skill | Documentation generation |
| **Communication** (1) | email-drafter-skill | Business-email drafting — process, tone frames, slop checklist |
| **Academic & Research Writing** (2) | horseshoe-paper-writing-skill, research-paper-generation-skill | Academic & research paper writing (Horseshoe Diagram Method, journal-submission formats; codebase→paper generation) |
| **JIRA** (3) | jira-status-updater, jira-git-integration, jira-ticket-labeler | JIRA integration via MCP server |
| **Code Quality** (14) | solid-principles, clean-code, clean-architecture, design-patterns, object-design, code-smells, complexity-management, deprecated-code-cleanup-skill, blast-radius-skill, ponytail-audit-skill, ponytail-review-skill, ponytail-debt-skill, language-review-checklists-skill, reviewer-baseline-skill | Code quality analysis, patterns, and @deprecated code cleanup |
| **Agent Optimization** (7) | continuous-learning, eval-harness, strategic-compact, verification-loop, search-first, context-budget, agent-introspection-debugging | AI agent session optimization, research-first workflow, context auditing, and agent debugging |
| **Autoresearch** (4) | autoresearch-core-skill, autoresearch-ml-skill, autoresearch-code-skill, autoresearch-research-skill | Autonomous research loops: 5-stage Understand→Hypothesize→Experiment→Evaluate→Log methodology. ML training (GPU), code optimization, literature review. Mechanical `{"pass":bool,"score":N}` evaluators — no LLM self-judgment |
| **Startup/Business** (3) | startup-pitch-deck-skill, startup-business-docs-skill, construction-bd-skill | Startup pitch decks, business documentation, construction proposals |
| **Configuration** (2) | markitdown-mcp-skill, docling-mcp-skill | markitdown and docling MCP setup |
| **Security** (2) | security-audit-skill, authentication-authorization-skill | Security auditing, vulnerability scanning, and auth implementation |
| **DevOps** (5) | docker-containerization-skill, monorepo-management-skill, database-migration-skill, logging-observability-skill, aws-iac-safety-skill | Containerization, monorepos, database migrations, observability, and IaC safety |
| **Planning & Alignment** (2) | grilling-skill, domain-modeling-skill | Relentless interview/grilling sessions and the canonical domain-model capture engine |
| **Responsive & Visual Testing** (2) | wireframer-skill, playwright-responsive-audit-skill | Low-fidelity wireframes and Playwright-driven responsive UI audit + fix |
| **CAD & Hardware Design** (15) | cad-generation-skill, cad-viewer-skill, cad-step-parts-skill, cad-dxf-skill, cad-urdf-skill, cad-srdf-skill, cad-sdf-skill, cad-sendcutsend-skill, cad-gcode-skill, cad-bambu-labs-skill, cad-implicit-skill, autodesk-aps-skill, civil-3d-skill, open3d-skill, cad-redraw-skill | Parametric CAD (STEP/STL/3MF/GLB), CAD Viewer previews, off-the-shelf parts, DXF drawings, evidence-aware drawing redraw, robot descriptions (URDF/SRDF/SDF), G-code slicing, 3D printing, SendCutSend validation, implicit CAD, Autodesk APS, Civil 3D, Open3D |
| **Media Generation** (4) | zai-image-generation-skill, zai-video-skill, zai-asr-skill, zai-ocr-skill | Z.AI PAYG media endpoints: text-to-image (GLM-Image), text/image-to-video (CogVideoX-3), audio transcription (GLM-ASR), layout-aware OCR (GLM-OCR) — artifacts saved to local files |

Browse live: the [GitHub Pages catalog](https://darellchua2.github.io/civiltekk-opencode-claude-skills/) (deployed on every `main` push), or `opencode-init --list skills`.
</details>

<details>
<summary><strong>Agents — 34 subagents + 4 config-builtins</strong></summary>

34 agent `.md` files (plus 4 config-builtin agents defined in `opencode.json`: `build`, `plan`, `explore`, `general`). Highlights:

| Subagent | Purpose |
|----------|---------|
| **code-review-subagent** | Comprehensive code review (Code Quality skills, blast-radius evidence grading, ponytail lean lens) |
| **architecture-review-subagent** | Architecture and design patterns, call-graph analysis |
| **language-reviewer-subagent** | Multi-language review — Python, TS/JS, Go, Rust, Java |
| **pr-workflow-subagent** / **repo-ops-specialist-subagent** | PR creation / git + release operations |
| **tdd-subagent** / **testing-subagent** / **linting-subagent** | TDD workflow / test generation / lint execution |
| **nextjs-specialist-subagent** | Next.js 16 scaffolding + runtime diagnosis + audit |
| **docx/pptx/xlsx specialist subagents** | Office document pipelines (Word, PowerPoint, Excel) |
| **image-analyzer / zai-media / uiux-reviewer** | Vision tier — native multimodal analysis, media generation, 13-axis UI/UX review |
| **cad-specialist-subagent** | CAD/engineering/robotics — orchestrates 15 CAD skills |
| **discovery / requirements / technical-design specialists** | Discovery sessions → Vision docs; BRD/SRS drafting; technical design + ADRs |
| **autoresearch-ml/code/research subagents** | Autonomous loops (GPU training, code optimization, literature review) |
| **loop-operator-subagent** | Autonomous loop execution with self-correction |
| **opencode-tooling / opencode-v2-migration subagents** | Skills/agents/rules creation + doc sync; v1→v2 migration execution |
| **startup-founder / startup-ceo / office-document routers** | Business operations routing hubs |

Some subagents recognize natural-language triggers (e.g. "create pr", "pitch deck", "design review", "PowerPoint") — the trigger surface is each agent's `description` frontmatter in `agents/*.md`; per-class model assignments and delegation guidance: `AGENTS.md` § Subagent Model Tiering.

**Subagent nesting:** `opencode_app/opencode.json` sets `subagent_depth: 3` (opencode default is 1) — required for the autoresearch delegation chains. Each level multiplies token cost; lower to 2 for tighter runs.

**Iteration protocol (opt-in):** a 5-stage autoresearch loop (Understand → Hypothesize → Experiment → Evaluate → Log) that 29 skills can opt into — off by default; enable via `AUTORESEARCH_PROTOCOL=1` or `ar-enable`. Retrofitted skills emit mechanical `{"pass":bool,"score":N}` output and auto-revert failed experiments. Safety: `skills/autoresearch-core-skill/references/iteration-safety.md`.
</details>

<details>
<summary><strong>Knowledge persistence — LEARNINGS + auto-inject</strong></summary>

Skills like `continuous-learning` persist knowledge across sessions:

| Storage | Scope | Purpose |
|---------|-------|---------|
| `LEARNINGS/` in target projects | Curated, git-committed | Patterns, ADRs, anti-patterns, solutions, conventions |
| `~/.config/opencode/learnings/` | User-level, cross-project | Personal preferences and patterns |

The `memory` tool's V1 plugin has no v2 release — `LEARNINGS/*.md` + the auto-inject plugin + `AGENTS.md` discovery is the memory layer (watch-list for v2-compatible re-adds in `AGENTS.md` § Project Learnings).

**How it works:** `setup.sh` creates `~/.config/opencode/learnings/` at user level; `continuous-learning` auto-provisions `LEARNINGS/` in target projects; review agents save findings as report content; agents discover learnings via the auto-injected manifest + explicit file reads. In this repo, `LEARNINGS/` ships as an empty skeleton — locally-written entries are gitignored (maintainer memory stays local).
</details>

<details>
<summary><strong>CodeGraph — pre-indexed code knowledge graph</strong></summary>

[CodeGraph](https://github.com/colbymchenry/codegraph) is a local SQLite knowledge-graph MCP server: symbol relationships, call graphs, and code structure instantly instead of grep/glob/Read chains.

| Metric | Without | With |
|--------|---------|------|
| Tool calls per exploration | 30-50+ | 1-6 |
| Exploration time | 1-2 min | 15-35 s |
| API key required | — | No (100% local) |

Per-project init (required before tools work): `codegraph init -i` → creates `.codegraph/` (gitignore it); a watcher auto-syncs. 19+ languages. Beneficiaries: `explore` (built-in), code-review (`codegraph_impact`), architecture-review (call graphs), testing (affected tests).
</details>

<details>
<summary><strong>Language Server Protocol (LSP)</strong></summary>

OpenCode v1 shipped native LSP (~30 servers) feeding diagnostics into the agent loop. **OpenCode v2 accepts `lsp` config but does not run language servers or produce diagnostics** — the block is inert; rely on the project's lint/typecheck/compiler commands (this repo's verification gates already work that way).

LSP is deliberately NOT enabled in the distributed config — this repository is a configuration distributor with no application code to diagnose. To enable in a target project: `"lsp": true` or selective (`{"lsp": {"typescript": {"disabled": false}}}`) in the project's `opencode.json`. Built-ins include tsserver, pyright, rust-analyzer, gopls, clangd, jdtls, terraform-ls. Set `OPENCODE_DISABLE_LSP_DOWNLOAD=true` to prevent auto-downloads (V1-era).
</details>

<details>
<summary><strong>Skill portability contract</strong></summary>

Skills ship to multiple harness targets and operating systems. Three conventions (rules 1–2 enforced by `tests/test_portability.bats`):

1. **Capability-binding blocks** — harness-specific mechanisms (background shells, interactive prompts, subagent delegation) are written with per-harness rows plus a portable fallback; agents self-select their row.
2. **Portability metadata** — `metadata.os: "linux, macos"` and `metadata.harness: "opencode"` in skill frontmatter; the installer warns when target or platform doesn't match.
3. **Bash rule** — shell snippets state `Requires bash (git-bash/WSL on Windows)` or use a `node -e` one-liner.

Full contract: `AGENTS.md` § Portability contract.
</details>

<details>
<summary><strong>Testing &amp; development recipes</strong></summary>

Test installer changes without touching your real `~/.config/opencode/`:

```bash
git clone https://github.com/darellchua2/civiltekk-opencode-claude-skills
node installer/init.mjs add tdd-subagent --dry-run     # 1. preview, write nothing
npm link && opencode-skill add solid-principles-skill --dry-run && npm unlink -g   # 2. real bin
npx github:darellchua2/civiltekk-opencode-claude-skills#feat/my-branch add X --dry-run   # 3. branch via npx
HOME="$(mktemp -d)" node installer/init.mjs add tdd-workflow-skill --yes             # 4. sandboxed HOME
bats tests/update.bats                                # 5. CI safety (--yes/--dry-run only)
```

**Downstream template:** [installer/templates/api-quality/](./installer/templates/api-quality/) — a Redocly lint ruleset + pre-commit hook enforcing OpenAPI authoring quality for repos this config's API skills work against (see its README for adoption).

Update installed content without a full setup rerun:

```bash
npx github:darellchua2/civiltekk-opencode-claude-skills update          # re-copy changed entries
npx github:darellchua2/civiltekk-opencode-claude-skills update --prune  # also remove registry-removed entries
```

**Redeploy contract:** `setup.sh --yes` force-copies content; existing skills/agents snapshot to the backup dir's `content-backup/` first — restore via the rollback flow.

Environment variable persistence: macOS/Linux writes shell rc; Windows uses `setx` / `$PROFILE` (Git Bash / PowerShell respectively).
</details>

#### Full setup reference

<details>
<summary><strong>Full setup reference — every flag</strong></summary>

Two setup scripts: `setup.sh` (macOS/Linux/WSL/Git Bash — full feature set) and `setup.ps1` (Windows — thin launcher forwarding to setup.sh via Git-Bash/WSL).

| Option (bash) | Option (PowerShell) | Description |
|----------------|----------------------|-------------|
| `--quick` | `-Quick` | Copy config + skills only (skip dependency checks) |
| `--skills-only` | `-SkillsOnly` | Deploy skills only (requires @opencode/cli installed) |
| `--update` | `-Update` | Update OpenCode CLI to latest |
| `--check-catalog` | — (bash only) | Warn if `installer/provider-models.json` drifted from models.dev; regenerate: `node deploy/regen-provider-models.mjs` |
| `--dry-run` | `-DryRun` | Preview all actions without changes |
| `--yes` | `-Yes` | Auto-accept all prompts |
| `--rollback [TARGET]` | `-RollbackTarget <T>` | Restore from a previous backup: `list`, `latest`, `TIMESTAMP`, or `VERSION`. Pre-rollback safety backup first |
| `--no-zip-backup` | `-NoZipBackup` | Skip zip archive creation |
| `--keep-backups <N>` | `-KeepBackups <N>` | Keep N most recent backups (default 5; 0 = all deleted; negative = keep all) |
| `--provider <p>` | `-Provider <p>` | Swap provider (zai\|anthropic\|openai\|openrouter) |
| `--mix` | — | Mix providers per tier |
| `--models-only` | `-ModelsOnly` | Re-resolve models only |
| `--migrate` | — | Run v1.x → v2.0 migration |
| `--force` | — | Re-resolve, ignoring preserved hand-edits |
| `--enable-pack <p>` | `-EnablePack <p>` | Provider packs (see MCP section) |
| `--skill-profile <p>` | `-SkillProfile <p>` | lean (default) \| full |
| `--help` | `-Help` | Detailed help + examples |

**What setup does:** copies `deploy/.AGENTS.md` → `~/.config/opencode/AGENTS.md`; copies `skills/` and agents; copies `opencode_app/opencode.json` → `~/.config/opencode/opencode.json` (single source of truth — v2 reads only `opencode.json`/`opencode.jsonc`; a coexisting `opencode.jsonc` is parked as `.legacy-ignored`, never deleted); backs up before overwriting. Installed `opencode-setup` symlinks back to the clone it deployed from — edit files there, re-run here.
</details>

## License

Apache-2.0 — see [`LICENSE`](./LICENSE). Vendored skills carry their own attributions in [`THIRD_PARTY_LICENSES.md`](./THIRD_PARTY_LICENSES.md).
