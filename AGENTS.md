# Repository-Specific Agent Instructions

Repo conventions only. Usage docs (install, deploy commands, file tree, chaining syntax) live in `README.md` and user-level `deploy/.AGENTS.md` (deploys to `~/.config/opencode/AGENTS.md`). Do not duplicate here.

## Repository Purpose

Multi-mode OpenCode configurator:
1. **User-space deploy** — `./deploy/setup.sh` copies config, agents, skills to `~/.config/opencode/`.
2. **Docker standalone** — `docker compose up -d` launches a web endpoint via `opencode_app/`.
3. **Individual install** — `npx github:darellchua2/opencode-config-template add <name>` pulls a single skill/agent (shadcn-style copy model). Default target `~/.config/opencode/` (auto-discovered, no config touch); `--project` opts into `./.opencode/`; `--target claude|both` writes `~/.claude/skills/` (Agent Skills open standard; `--format` is a deprecated alias). See [issue #304](https://github.com/darellchua2/opencode-config-template/issues/304).

## Source of Truth

The root `skills/` and `agents/` dirs are the **single source** for skills and agents. Never edit deployed `~/.config/opencode/` copies — edit source, then redeploy.

## Secret Masking

Vibeguard masks `.env` secrets in provider-bound traffic via regex patterns (`plugins/vibeguard.config.json`). **OpenCode v2: shipped as a local v2 port (`plugins/vibeguard.ts`, npm pin removed) — masking is active; the `permissions` deny rules for `*.env` are the second layer.** Behavioral rules: `deploy/.AGENTS.md` §Secret Hygiene. Verification + per-project overlay: `security-audit-skill` (also documents residual risks: `/share` plaintext, no fail-closed, plaintext session DB).

## Dependency Management

`package-lock.json` is committed. Dependency changes MUST run `npm install` and commit the regenerated lockfile — `npm ci` hard-fails on drift.

## Subagent Locations

| Location | Scope | Deployed? |
|----------|-------|-----------|
| `agents/*.md` | Global (all projects) | Yes — copied by `deploy/setup.sh` |
| `.opencode/agents/*.md` | Project-only | No — stays in repo |

Project-level agents must NOT be counted in setup scripts or README.

## Subagent Model Tiering (v2.0)

Tiers live in `installer/agent-tiers.json`; models are resolved at deploy time from `installer/models.default.json` (Z.AI defaults) and are provider-agnostic — swap via `installer/provider-presets.json` without editing agent files. See `MIGRATION.md`.

| Tier | Default (Z.AI) | Use for |
|------|----------------|---------|
| `primary` | `glm-5.3` (1M ctx) | Primary session only — never for subagents. |
| `reasoning` | `glm-5.3` (200k) | Correctness-critical: reviewers (code/architecture/language), repo-ops-specialist, tdd, opentofu-explorer, loop-operator, opencode-tooling, opencode-v2-migration, pptx-specialist, responsive-audit, technical-design-specialist, discovery-specialist, requirements-specialist |
| `fast` | `glm-5.3-flash` (1M) | Exploratory/low-impact: explorer, testing, nextjs/cad/office-docs specialists, document creators (docx/xlsx), pr-workflow, startup agents (ceo/founder) |
| `docs` | `glm-5.3-flash` (1M) | documentation, linting, coverage |
| `long-context` | `glm-5.3` (1M ctx) | Large-context research/code loops: autoresearch-ml, autoresearch-code, autoresearch-research — designated subagent tier; subagents never use `primary` directly |
| `vision` | `glm-5.3-flash` (1M) | Native multimodal (image/video/pdf): `image-analyzer-subagent` + `error-resolver-subagent` + `uiux-reviewer-subagent` + `zai-media-subagent` (see fallback below) |

Pick by purpose: correctness-critical → `reasoning`; exploratory → `fast`; docs/lint → `docs`; research/code loops → `long-context`; image perception → `vision`.

**Vision fallback:** when native perception is unavailable ("model does not support image input", text-only session), image-analyzer, error-resolver, and uiux-reviewer fall back to the inline bash recipe embedded in `image-analyzer-subagent`, calling the Z.AI vision API directly at `glm-5v-turbo` — a different model from the native `glm-5.3-flash` (coding-plan endpoint preferred, PAAS fallback; requires `ZAI_API_KEY`). Free `glm-4.6v-flash` is a cost-constrained option, not the default.

**Resolution precedence (highest wins):** project `.opencode/agent-overrides.json` > global `~/.config/opencode/agent-overrides.json` > project `.opencode/models.json` > global `~/.config/opencode/models.json` > `installer/models.default.json`. Swap provider: `setup.sh --provider <p>`; mix per tier: `setup.sh --mix` (stored in `models.json`, re-resolve with `--models-only`); per-agent pin: global `agent-overrides.json`. Built-ins `explore`→`fast` and `general`→`reasoning` are patched in `opencode.json`, not the tier registry.

## Adding Skills or Subagents — Sync Rules

| Trigger | What to update |
|---------|---------------|
| New/removed MCP server | MCP count, auto-start listing, help text |
| New/removed skill | Skill count, category listing, banner |
| New/removed agent | Agent count, help text listing |
| `opencode.json` config change | MCP server entries if added/removed |

Files: `deploy/setup.sh`, `deploy/setup.ps1` (Windows mirror), `README.md` (Skill Categories + Subagents tables), `opencode_app/README.md` (if Docker-relevant). Then invoke `documentation-sync-workflow` skill or delegate to `opencode-tooling-subagent`.

## Skill / Agent Frontmatter Contract

Verified against opencode.ai v2 docs 2026-09-14. All new/edited SKILL.md and agent files MUST conform.

**Skills — runtime-read keys** (all else ignored):
| Key | Rule |
|-----|------|
| `name` | Required. MUST equal directory name (`^[a-z0-9]+(-[a-z0-9]+)*$`, ≤64 chars) |
| `description` | Required, 1–1024 chars. House style: ≤50 words, preserve trigger phrases |
| `license` | `Apache-2.0` (house default; existing MIT exceptions grandfathered) |
| `compatibility` | `opencode` |
| `metadata` | Opaque string map, zero runtime behavior. House sub-keys: `protocol`, `pattern` only |
| `category` | Installer-registry-only (build-registry.mjs, init.mjs, setup.sh counts) — invisible to OpenCode, never delete |

Skill gating does NOT belong in SKILL.md — it lives in the `permissions` array (`action:"skill"` rules) of `opencode.json` or agent frontmatter only.

**Agents — runtime-read keys:** `description` (required), `steps`, `disabled`, `system` (JSON prompt key; legacy `prompt` auto-translated), `model` (string or `model#variant`), `permissions` (NOT deprecated `tools`; array of `{action,resource,effect}` rules), `mode`, `hidden`, `color`, `request.body.temperature`, `request.body.top_p`. Source files ship no `model:` — tiers inject it at deploy time. `category` is installer-registry-only. Source agent `.md` files ship native v2 frontmatter: `permissions:` rules arrays (order matters — last matching rule wins), no `model:` (tier-injected at deploy); the markdown body is the system prompt.

After ANY frontmatter change: run `node installer/build-registry.mjs` and commit `registry.json`.

## Return Contract

All subagents return (additive signal fields allowed beyond, never replacing):
**Status:** success | partial | failed
**Output:** file path(s) / key result, one line
**Summary:** 2–3 sentences max
**Issues:** blockers, warnings, or "None"

**Reviewer additions** (architecture, code, language, uiux) — required on every review: `Patterns applied/violated: [{id: <LEARNINGS-slug>, status: applied|violated, evidence: <file:line>}]`; emit `[]` if none, never omit.

## Project Learnings

`LEARNINGS/` is a template in this repo; in target projects, check it before reviewing/planning. Storage: `LEARNINGS/*.md` (the `memory` tool's plugin has no v2 release — pin removed; watch for a v2-compatible `opencode-superlocalmemory`). The manifest is auto-injected per session by the local plugin (ported to the v2 plugin API — active) — see user-level Memory Hygiene.

## Extract-then-Delegate

When a subagent needs domain knowledge, the primary loads the skill, extracts relevant parameters, and passes ONLY those params to the subagent — heavy knowledge stays in the compactable primary context.

## Office Document Extraction Routing

**Single source of truth** — skills/subagents reference this section instead of duplicating the tree. Binary office docs (`.docx`, `.pptx`, `.xlsx`, born-digital `.pdf`) need an extraction engine — `Read` cannot parse them. Escalate only when the cheaper tier is insufficient:

| Tier | Engine | Best for | Enable |
|------|--------|----------|--------|
| 1 | markitdown (MCP) | Fast text dumps of born-digital docs (~1s/50 pages, no cloud) | `--enable-pack markitdown` |
| 2 | docling (CLI or MCP) | Layout-aware: complex tables, multi-column, scanned PDFs | CLI `pip install --user docling` (ask consent, ~3-4 GB); MCP `--enable-pack docling` |
| 3 | image-analyzer-subagent | Visual understanding: charts, diagrams, screenshots | always available (native multimodal) |
| 4 | pdf-specialist-skill | Structured PDF data: forms, fillable fields, OCR-as-purpose | load skill |

markitdown and docling are both opt-in (disabled by default). When markitdown is disabled, tell the user to `--enable-pack markitdown`. When its output is insufficient, escalate to docling — if absent, ask consent via `question` (never auto-install 3-4 GB). Headless/CI: soft-fail to markitdown best-effort.
