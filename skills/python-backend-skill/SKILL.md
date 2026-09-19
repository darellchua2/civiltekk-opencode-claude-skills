---
name: python-backend-skill
description: >-
  Scaffold Python backend projects — FastAPI/Django/Flask layout, dependency
  injection, config, virtual environments, pyproject.toml.
license: Apache-2.0
compatibility: opencode
category: Language-Specific
---

## What I do

Scaffold Python backends: framework choice (FastAPI/Django/Flask), project layout, pyproject.toml standard, env-based config (pydantic-settings), DI, SQLAlchemy session discipline, migration gotchas, SSE durability, OpenCode LSP wiring.

## When to use me

New/restructured Python backend; production patterns for FastAPI/Django/Flask; detached-instance or SSE bugs.

**Related:** `python-pytest-creator-skill` (tests) · `python-ruff-linter-skill` (lint) · `database-migration-skill` (full migration workflows — this file keeps only gotchas) · `nextjs-standard-setup-skill` (JS equivalent).

## House standards

**pyproject.toml** (FastAPI baseline): `requires-python = ">=3.12"`; deps `fastapi>=0.110.0`, `uvicorn[standard]>=0.27.0`, `sqlalchemy[asyncio]>=2.0.0`, `asyncpg>=0.29.0`, `pydantic-settings>=2.1.0`, `alembic>=1.13.0`; dev extras `pytest>=8`, `pytest-asyncio>=0.23`, `pytest-cov`, `httpx`, `ruff>=0.2`, `mypy>=1.8`. Ruff: `target-version py312`, `line-length 120`, select `E,F,I,N,UP,B,SIM,C4`; pytest `asyncio_mode = "auto"`; mypy `strict = true` + `pydantic.mypy` plugin.

**OpenCode LSP (project-level)**: root `opencode.json` with `"lsp": {"pyright": {}}` — ambient cross-module type diagnostics during edits (pyright in dev deps, `>=1.1.350`); ruff/mypy remain the CI gate, pyright is the ambient feed. Project-level only for code repos; check into git.

**Hard rules (each was a production incident):**
- **Detached ORM across sessions** — never fetch in one session and commit in another; one session per read-modify-write (`async with session.begin()`). Mocks mask this bug.
- **Pydantic on JSONB** — never assign a `BaseModel` to a JSONB column; `model_dump()` first (a miss here took out all 47 node registrations).
- **Alembic `bulk_insert` + asyncpg JSONB** — pass native dicts, never `json.dumps()` strings.
- **`asyncio.Queue` as sole SSE event store** — events vanish on reconnect/multi-worker; DB (or Redis) is the store, queue is delivery, replay via `Last-Event-ID`.

## House Learnings

### Learning: `inline-http-header-parsing-in-handlers`
Same 3-line `Location`-header resource-ID extraction repeated across 2+ handlers drifts (each variant handles missing headers differently) — extract one module-level `extract_resource_id(headers)` helper.
Detection: `rg 'headers\.get\(["\']Location' --type py -c | rg '[2-9]|[1-9][0-9]+'`

### Learning: `duplicated-response-parsing-in-llm-nodes`
Identical LLM response-parsing (JSON-in-text + regex fallback + error wrappers) copied across LangChain/LangGraph nodes: a fix lands in one node and misses the rest. Extract a mixin/base parser when 2+ nodes need it.
Detection: `rg 'json\.loads.*result|re\.search.*text' --type py -c | rg '[2-9]|[1-9][0-9]+'`

### Learning: `duplicate-service-account-check`
Any method crossing a process boundary (network/DB/file/subprocess) is called at most ONCE per function — bind to a local on first call, reuse thereafter.
Detection: `rg '(\w+\.\w+\([^)]*\))' --type py | sort | uniq -c | sort -rn | head -20`

> Removed 2026-09: full FastAPI/Django/Flask directory trees, scaffolding step-by-steps, venv management walkthroughs, DI/factory code examples, extended SSE code listings — framework conventions the model knows; kept the pinned pyproject standard, the LSP wiring, the four incident rules, and the three codified learnings.
