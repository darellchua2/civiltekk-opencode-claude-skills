---
name: civiltekk-python-backend-skill
description: >-
  Python backend engineering — scaffold FastAPI/Django/Flask projects (layout,
  dependency injection, config, virtual environments, pyproject.toml), package
  apps and libraries (Poetry, uv, setuptools, hatch, dependency management,
  PyPI publishing), and apply backend patterns (Pydantic v2 conventions,
  layered FastAPI architecture, ORM pitfalls N+1/migration syntax, defensive
  coding, multi-tenant isolation).
license: Apache-2.0
compatibility: opencode
category: Language-Specific
---

Consolidates python-backend-skill + python-packaging-skill + fastapi-pydantic-orm-patterns-skill (#603).

## What I do

Python backend work across three routes:

1. **Detect the route** (§Routes) — explicit > inferred > ask-once.
   Explicit: the request names the activity ("scaffold a FastAPI project",
   "new Django backend", "set up pyproject/venv" → `scaffold`; "package
   this library", "publish to PyPI", "choose uv/Poetry/setuptools/hatch" →
   `packaging`; "review these endpoints", "Pydantic v2 config", "N+1
   queries", "multi-tenant audit" → `patterns`). Inferred: the artifact
   shape (a new project or its layout/config → `scaffold`; packaging and
   publishing config → `packaging`; existing runtime code being written or
   reviewed → `patterns`). Ambiguous ("make this backend production-ready")
   → ask once — one ask per run, then proceed on the answer.
2. **Load the route's values file** (`references/scaffold.md` /
   `references/packaging.md` / `references/fastapi-orm.md`) and apply its
   contract.
3. The routes chain naturally — a backend pass starts from `scaffold`
   (layout + pinned pyproject baseline), picks its build tool through
   `packaging`, and implements against `patterns`; load per phase, not all
   three up front.

## Side files (load rules)

| Read | When | Use |
|------|------|-----|
| `references/scaffold.md` | route `scaffold` | Framework choice, project layout, pinned pyproject standard, env config (pydantic-settings), DI, SQLAlchemy session discipline, OpenCode LSP wiring, four incident rules (detached ORM, Pydantic-on-JSONB, bulk_insert JSONB, SSE queue store), three codified learnings |
| `references/packaging.md` | route `packaging` | App-vs-library decision matrix, tool choice (uv/Poetry/setuptools/hatch), dependency strategy, entry points, PyPI publishing, common traps |
| `references/fastapi-orm.md` | route `patterns` | Pydantic v2 conventions checklist, layered FastAPI architecture, ORM/migration pitfalls (migration compile tests, N+1, two-step lookup), defensive coding, multi-tenant security, concurrency/caching, operational patterns |

Side files carry VALUES only; this file carries the METHOD. A Python
concern outside backend engineering (test authoring, lint configuration,
migration workflows) is not this skill's space —
`civiltekk-test-generation-skill` (route `python`) owns tests, `python-ruff-linter-skill` /
`language-linting-skill` own lint, `database-migration-skill` owns full
migration workflows (the `scaffold` and `patterns` routes keep only
gotchas and asyncpg-specific pitfalls).

## Routes

| Situation | Route |
|-----------|-------|
| "scaffold a Python backend", "new FastAPI/Django/Flask project", project layout, pyproject app baseline, env-based config, DI, SQLAlchemy session discipline, migration gotchas, detached-instance or SSE bugs | `scaffold` |
| "package this app/library", choosing a build tool, writing/restructuring pyproject packaging sections, app-vs-library dependency strategy, console entry points, PyPI publishing, Python monorepo packages | `packaging` |
| Writing/reviewing FastAPI endpoints (especially async sessions), Pydantic v2 models/validators/serializers, Alembic migrations (especially asyncpg + JSONB), multi-tenant isolation audits, race conditions in state transitions, service-to-service error handling | `patterns` |
| Ambiguous ("make it production-ready") | ask once (§What I do step 1), then route |

## Boundaries

- The three routes were formerly peer skills (scaffold referenced the
  patterns, packaging pinned against the scaffold baseline) — those
  boundaries are internal now; the route table above is the boundary
  logic.
- Full migration workflows (rollback, zero-downtime, seeding, migration
  testing) belong to `database-migration-skill`, not here.
- JS/TS project-setup equivalent: `civiltekk-nextjs-skill` (route `scaffold`);
  monorepo package management across languages: `monorepo-management-skill`.

## Agent behavior rules

- One ask per run maximum (route detection); headless/CI: no asks —
  infer from the request shape, defaulting to `scaffold` (project shape
  first; packaging and patterns apply once code exists).
- The hard rules in `references/scaffold.md` were each a production
  incident — never trade them away for convenience; the `patterns` values
  are incident-derived with concrete fixes, cite the pattern ID when
  applying one in review.
- Packaging choices follow the house decision rules (uv default,
  app-vs-library deltas) — don't re-litigate tool choice per project
  without a stated constraint.
