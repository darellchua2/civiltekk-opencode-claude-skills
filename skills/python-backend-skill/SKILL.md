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

I help you scaffold and structure Python backend projects following industry best practices:

1. **Project Scaffolding**: Create well-organized project structures for FastAPI, Django, or Flask
2. **Dependency Management**: Configure pyproject.toml, requirements files, and virtual environments
3. **Configuration Management**: Environment-based config with pydantic-settings
4. **Dependency Injection**: Wire up DI containers for testability
5. **Application Factory**: Implement the factory pattern for app initialization
6. **Project Standards**: Linting, formatting, type checking, and CI configuration
7. **OpenCode LSP Integration**: Generate project-level `opencode.json` enabling pyright LSP for real-time type diagnostics fed to the agent

## When to use me

Use this skill when:
- Starting a new Python backend project
- Restructuring an existing Python project for better organization
- Setting up FastAPI, Django, or Flask with production-ready patterns
- Configuring pyproject.toml and dependency management
- Implementing environment-based configuration
- Setting up Python project standards (ruff, mypy, pytest)
- Migrating between Python frameworks
- Debugging SQLAlchemy session errors (detached instances, cross-session mutations)
- Implementing SSE/streaming endpoints with proper backpressure

## Related Skills

- **python-pytest-creator-skill**: Generate tests for Python projects using these structures
- **python-ruff-linter-skill**: Lint and format Python code following these standards
- **nextjs-standard-setup-skill**: The Next.js equivalent of this Python scaffolding skill
- **database-migration-skill**: Alembic/Django migration workflows for Python backends

---

## Step 1: Choose Your Framework

| Framework | Best For | Async | ORM Agnostic | Admin UI |
|-----------|----------|-------|-------------|----------|
| **FastAPI** | APIs, microservices, async | Native | Yes | No |
| **Django** | Full-stack web apps, CMS | ASGI support | Django ORM | Yes |
| **Flask** | Simple APIs, microservices | Via extensions | Yes | No |

---

## Step 2: FastAPI Project Structure

```
project/
├── pyproject.toml
├── README.md
├── .env.example
├── .gitignore
├── Dockerfile
├── docker-compose.yml
├── alembic/
│   ├── env.py
│   └── versions/
├── src/
│   └── app/
│       ├── __init__.py
│       ├── main.py              # FastAPI app factory
│       ├── config.py            # Settings with pydantic
│       ├── dependencies.py      # Shared FastAPI dependencies
│       ├── models/              # SQLAlchemy models
│       │   ├── __init__.py
│       │   └── user.py
│       ├── schemas/             # Pydantic schemas
│       │   ├── __init__.py
│       │   └── user.py
│       ├── routers/             # API route modules
│       │   ├── __init__.py
│       │   └── users.py
│       ├── services/            # Business logic
│       │   ├── __init__.py
│       │   └── user_service.py
│       ├── repositories/        # Data access
│       │   ├── __init__.py
│       │   └── user_repository.py
│       └── middleware/           # Custom middleware
│           ├── __init__.py
│           └── logging.py
└── tests/
    ├── conftest.py
    ├── unit/
    └── integration/
```

### Application Factory

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routers import users, health

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.VERSION,
        docs_url="/docs" if settings.DEBUG else None,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router)
    app.include_router(users.router, prefix="/api/v1")

    @app.on_event("startup")
    async def startup():
        from app.database import engine
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    return app

app = create_app()
```

### Configuration with pydantic-settings

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    APP_NAME: str = "My API"
    VERSION: str = "1.0.0"
    DEBUG: bool = False

    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 5
    DATABASE_MAX_OVERFLOW: int = 10

    REDIS_URL: str = "redis://localhost:6379/0"

    SECRET_KEY: str
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000"]

    LOG_LEVEL: str = "INFO"

settings = Settings()
```

### Centralize Config in a Single Settings Class

**Learning**: `centralized-single-source-config`

ALL environment variables MUST be read in exactly one `pydantic-settings` `Settings` class. Derived values (a full URL assembled from host/port/scheme, a Redis URL from host/port/db) are computed by `@field_validator` or `@model_validator` on that class, never re-derived in feature code via `os.getenv()`. When the same derived value is recomputed in 3+ files, the next environment override leaves one of them stale and silently routes to the wrong service.

```python
# WRONG — each module rebuilds the same derived URL from raw env vars
# services/cache.py
import os
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = os.getenv("REDIS_PORT", "6379")
REDIS_URL = f"redis://{REDIS_HOST}:{REDIS_PORT}/0"   # drifts from config.py

# services/queue.py
REDIS_URL = f"redis://{os.getenv('REDIS_HOST')}:{os.getenv('REDIS_PORT')}/1"  # different db!

# CORRECT — one Settings class, validators derive values, one import surface
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env")

    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0

    @field_validator("REDIS_PORT", mode="after")
    @classmethod
    def _port_range(cls, v: int) -> int:
        if not 1 <= v <= 65535:
            raise ValueError("REDIS_PORT out of range")
        return v

    @property
    def REDIS_URL(self) -> str:
        return f"redis://{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"

settings = Settings()
# services/cache.py and services/queue.py both import settings.REDIS_URL
```

**Detection:**

```bash
# find env reads OUTSIDE the Settings module
rg "os\.getenv|os\.environ" --type py
```

**Rule:** The `Settings` class is the single source of truth for every environment-derived value. Derived values are properties or validators on that class — never recomputed via `os.getenv()` in feature code.

### Repository Pattern

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User

class UserRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, user_id: str) -> User | None:
        result = await self.session.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self.session.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def create(self, user: User) -> User:
        self.session.add(user)
        await self.session.flush()
        return user
```

### Dependency Injection

```python
from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import async_session_factory
from app.repositories.user_repository import UserRepository
from app.services.user_service import UserService

async def get_db():
    async with async_session_factory() as session:
        async with session.begin():
            yield session

async def get_user_repository(db: Annotated[AsyncSession, Depends(get_db)]) -> UserRepository:
    return UserRepository(db)

async def get_user_service(repo: Annotated[UserRepository, Depends(get_user_repository)]) -> UserService:
    return UserService(repo)

UserServiceDep = Annotated[UserService, Depends(get_user_service)]
```

### Prefer DI Over Global Singletons

**Learning**: `module-singleton-global-mutation`

Module-level singletons via `global _service` hide coupling, resist testing, and have no lifecycle management. The `httpx.AsyncClient` inside never gets closed, connections leak, and tests must null globals between runs.

```python
# WRONG — hidden coupling, no lifecycle, tests must mutate global state
_service: Optional[MyService] = None

def get_service() -> MyService:
    global _service
    if _service is None:
        _service = MyService(client=httpx.AsyncClient())  # Never closed!
    return _service

# CORRECT — FastAPI Depends() with app.state lifecycle
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.client = httpx.AsyncClient()
    yield
    await app.state.client.aclose()  # Clean shutdown

app = FastAPI(lifespan=lifespan)

async def get_service(client: httpx.AsyncClient = Depends(lambda r: r.app.state.client)):
    return MyService(client=client)
```

**Rule:** Use `FastAPI Depends()` with `app.state` for lifecycle-managed singletons. Never use `global _x` patterns — they hide dependencies from type checkers and prevent test overrides.

---

## Step 3: Django Project Structure

```
project/
├── pyproject.toml
├── manage.py
├── config/
│   ├── __init__.py
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py
│   └── wsgi.py
├── apps/
│   ├── __init__.py
│   ├── users/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── admin.py
│   │   └── tests/
│   └── orders/
│       └── ...
├── templates/
├── static/
└── requirements/
    ├── base.txt
    ├── development.txt
    └── production.txt
```

### Django Settings Split

```python
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent.parent

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "apps.users",
    "apps.orders",
]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("DB_NAME", "app_db"),
        "USER": os.environ.get("DB_USER", "postgres"),
        "PASSWORD": os.environ.get("DB_PASSWORD", ""),
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": os.environ.get("DB_PORT", "5432"),
    }
}
```

---

## Step 4: Flask Project Structure

```
project/
├── pyproject.toml
├── src/
│   └── app/
│       ├── __init__.py         # Factory
│       ├── config.py
│       ├── extensions.py       # db, migrate, cors
│       ├── blueprints/
│       │   ├── __init__.py
│       │   └── users.py
│       ├── models/
│       │   ├── __init__.py
│       │   └── user.py
│       └── services/
│           ├── __init__.py
│           └── user_service.py
└── tests/
```

### Flask Factory

```python
from flask import Flask
from app.extensions import db, migrate, cors
from app.config import config

def create_app(config_name="default"):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    db.init_app(app)
    migrate.init_app(app, db)
    cors.init_app(app)

    from app.blueprints.users import users_bp
    app.register_blueprint(users_bp, url_prefix="/api/v1/users")

    return app
```

---

## Step 5: pyproject.toml Standard

```toml
[project]
name = "my-api"
version = "1.0.0"
description = "My API service"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    "sqlalchemy[asyncio]>=2.0.0",
    "asyncpg>=0.29.0",
    "pydantic-settings>=2.1.0",
    "alembic>=1.13.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "httpx>=0.27.0",
    "ruff>=0.2.0",
    "mypy>=1.8.0",
]

[tool.ruff]
target-version = "py312"
line-length = 120
src = ["src"]

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "SIM", "C4"]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"

[tool.mypy]
python_version = "3.12"
strict = true
plugins = ["pydantic.mypy"]
```

### OpenCode LSP Integration (project-level config)

Create a project-level `opencode.json` in the project root to feed real-time `pyright` type diagnostics to the agent during edits. This gives ambient type-error awareness across the cross-module import graph without the agent needing to run `mypy`/`pyright` manually.

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {
    "pyright": {}
  }
}
```

**Why pyright:** handles `.py` and `.pyi`; surfaces type errors across modules (highest-value signal during refactors of repository/service layers). Complements `ruff` (CLI linter via `python-ruff-linter-skill`) and `mypy` (already in dev deps) — pyright LSP is the ambient feed; ruff/mypy remain the CI gate.

**Requirement:** pyright must be installed. Add to dev dependencies in `pyproject.toml`:

```toml
[project.optional-dependencies]
dev = [
    # ...existing deps...
    "pyright>=1.1.350",
]
```

**Why project-level:** config merges with the user's global `~/.config/opencode/opencode.json`, so only the `lsp` key needs declaring here. Scoped to code projects; non-code repos stay LSP-free. Check into git so teammates inherit it.

**Token cost:** diagnostics are injected into model context. Worth it for Python backends (cross-module type errors are common); monitor usage and set `"lsp": false` to temporarily disable.

Refs: [LSP](https://opencode.ai/docs/lsp/) · [Config](https://opencode.ai/docs/config/)

---

## Step 6: Virtual Environment Management

### uv (Recommended)

```bash
uv venv --python 3.12
source .venv/bin/activate
uv pip install -e ".[dev]"
```

### Standard venv

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

### .env.example

```
APP_NAME=My API
VERSION=1.0.0
DEBUG=true
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/app_dev
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=change-me-in-production
LOG_LEVEL=DEBUG
ALLOWED_ORIGINS=["http://localhost:3000"]
```

---

## Step 7: SQLAlchemy Session Management

### Detached ORM Across Sessions

**Learning**: `detached-orm-across-sessions`

Never fetch an ORM object in one session, mutate it, then commit in another. Use a single session for the entire read-modify-write lifecycle. Mock-only tests mask this bug because mocks don't enforce session boundaries.

```python
# WRONG — object fetched in session A, committed in session B (detached)
async def update_user_bad(user_id: str, new_name: str):
    async with async_session() as s1:
        user = await s1.get(User, user_id)  # loaded in s1
    # s1 closes — user is now DETACHED
    async with async_session() as s2:
        user.name = new_name  # modifies detached object — changes NOT tracked
        await s2.commit()     # no-op, nothing flushed

# CORRECT — single session for read-modify-write
async def update_user_good(user_id: str, new_name: str):
    async with async_session() as session:
        async with session.begin():
            user = await session.get(User, user_id)
            user.name = new_name
        # commit happens here — flush is automatic
```

### Pydantic on JSONB Columns

**Learning**: `pydantic-on-jsonb-columns`

Never assign a Pydantic `BaseModel` instance directly to a JSONB column. SQLAlchemy expects a dict-compatible type. Use `model_dump()` before assignment. This caused ALL 47 node registrations to fail in production.

```python
from pydantic import BaseModel

class NodeConfig(BaseModel):
    api_url: str
    timeout: int = 30

# WRONG — Pydantic object assigned to JSONB column
config = NodeConfig(api_url="https://api.example.com")
node.config = config  # Type: NodeConfig, NOT dict — asyncpg rejects this

# CORRECT — serialize to dict first
node.config = config.model_dump()  # Type: dict — asyncpg handles this
```

### Instance Check Over Field Lists

**Learning**: `instance-check-over-field-lists`

Use `isinstance(value, BaseModel)` instead of hardcoded field-name frozensets to detect Pydantic instances. Simpler, future-proof, and handles arbitrary model schemas.

```python
# WRONG — fragile, must list every possible Pydantic field name
PYDANTIC_FIELDS = frozenset(["config", "metadata", "settings", "options"])
if column_name in PYDANTIC_FIELDS:
    value = value.model_dump()

# CORRECT — detects any Pydantic BaseModel instance automatically
if isinstance(value, BaseModel):
    value = value.model_dump()
```

### json.dumps default=str Masks Numpy Types

**Learning**: `json-default-str-numpy-masking`

`json.dump(..., default=str)` is a silent type-masking trap. It converts any object the JSON encoder cannot serialize — including numpy scalars (`np.int64`, `np.float64`), datetimes, and sets — into their string representation. The JSON type contract is silently broken: a downstream consumer expecting `{"count": 42}` receives `{"count": "42"}`. Cast every numpy value to a Python native type BEFORE building the output dict, so the JSON encoder never needs the `default` fallback.

```python
# WRONG — default=str turns np.int64 into "42" silently
import json
import numpy as np

def serialize_bad(row):
    return json.dumps({"count": np.int64(42)}, default=str)
    # → '{"count": "42"}' — type contract broken, downstream parse fails

# CORRECT — cast at the source so default=str never fires
def _to_native(value):
    if isinstance(value, np.integer):
        return int(value)
    if isinstance(value, np.floating):
        return float(value)
    if isinstance(value, np.ndarray):
        return value.tolist()
    raise TypeError(f"Unsupported type: {type(value)}")

def serialize_good(row):
    payload = {
        "count": _to_native(row["count"]),
        "mean": _to_native(row["mean"]),
    }
    return json.dumps(payload)
    # → '{"count": 42, "mean": 3.14}' — contract preserved
```

**Detection:**

```bash
rg "default=str" --type py
```

**Rule:** `default=str` is a debugging escape hatch, never a production strategy. Convert numpy/scientific types to Python natives at the source so the JSON encoder never reaches the fallback.

---

## Step 8: Database Migration Gotchas

> See **database-migration-skill** for full migration workflows, rollback strategies, and CI patterns.

### `bulk_insert` JSONB with asyncpg

**Learning**: `migration-jsonb-dicts`

When using Alembic `bulk_insert` with asyncpg, JSONB columns require Python dicts — not JSON strings. asyncpg does not auto-serialize `json.dumps()` output; it expects native Python types.

```python
import json

# WRONG — JSON string passed to asyncpg JSONB column
op.bulk_insert(
    sa.table("nodes"),
    [{"id": "n1", "config": json.dumps({"key": "val"})}],
)
# asyncpg error: expected dict, got str

# CORRECT — native Python dict
op.bulk_insert(
    sa.table("nodes"),
    [{"id": "n1", "config": {"key": "val"}}],
)
```

---

## Step 9: Async Streaming & SSE Durability

### asyncio.Queue as Sole Event Store

**Learning**: `asyncio-queue-sole-event-store-sse`

Never use `asyncio.Queue` as the ONLY event store for SSE endpoints. Queue events are lost on client reconnect or across multiple worker processes. Always pair with a persistent store (database, Redis pub/sub).

```python
# WRONG — queue-only, events lost on reconnect
queue: asyncio.Queue = asyncio.Queue()
@app.post("/events")
async def post_event(event: Event):
    await queue.put(event)  # if no SSE client connected, silently dropped

@app.get("/stream")
async def stream():
    async def generate():
        while True:
            event = await queue.get()  # missed events after reconnect
            yield f"data: {event.json()}\n\n"
    return StreamingResponse(generate(), media_type="text/event-stream")

# CORRECT — DB-backed with queue as delivery layer
@app.post("/events")
async def post_event(event: Event, db: AsyncSession):
    await db.execute(insert(EventLog).values(data=event.model_dump()))
    await db.commit()
    await queue.put(event)  # deliver to active connections

@app.get("/stream")
async def stream(db: AsyncSession):
    last_id = int(request.headers.get("Last-Event-ID", 0))
    async def generate():
        async for event in await get_events_since(db, last_id):  # replay missed
            yield f"id: {event.id}\ndata: {event.data}\n\n"
        while True:
            event = await queue.get()
            yield f"id: {event.id}\ndata: {event.json()}\n\n"
    return StreamingResponse(generate(), media_type="text/event-stream")
```

### SSE Backpressure with LLM Chunks

**Learning**: `sse-backpressure-llm-chunks`

On SSE queue overflow, close the connection instead of dropping oldest events. LLM streaming chunks are cumulative — dropping one corrupts the rest of the response.

```python
# WRONG — drops middle of LLM response
try:
    event = await asyncio.wait_for(queue.get(), timeout=1.0)
except asyncio.TimeoutError:
    queue.get_nowait()  # drop oldest — corrupts partial JSON/Markdown
    continue

# CORRECT — close connection, client can reconnect with Last-Event-ID
try:
    event = await asyncio.wait_for(queue.get(), timeout=5.0)
except asyncio.TimeoutError:
    break  # exit generator — closes the SSE connection cleanly
```

---

## Step 10: Async API Patterns

### Blocking Poll Pattern

**Learning**: `async-api-blocking-poll-pattern`

Model external async APIs as blocking nodes with a submit → poll → download lifecycle. This decouples the async wait from the HTTP request, avoids long-lived connections, and provides resumability.

```python
import asyncio

class ExternalAPIClient:
    async def submit(self, job: JobPayload) -> str:
        resp = await http_client.post("https://api.example.com/jobs", json=job)
        return resp.json()["job_id"]

    async def poll(self, job_id: str) -> JobStatus:
        resp = await http_client.get(f"https://api.example.com/jobs/{job_id}")
        return JobStatus(**resp.json())

    async def download(self, job_id: str) -> bytes:
        resp = await http_client.get(f"https://api.example.com/jobs/{job_id}/result")
        return resp.content

# Usage in endpoint — non-blocking submit, separate poll/download
@app.post("/generate")
async def submit_job(payload: JobPayload):
    job_id = await client.submit(payload)
    return {"job_id": job_id, "status": "pending"}

@app.get("/generate/{job_id}/status")
async def get_status(job_id: str):
    status = await client.poll(job_id)
    return status.model_dump()

@app.get("/generate/{job_id}/result")
async def get_result(job_id: str):
    if (await client.poll(job_id)).status != "completed":
        raise HTTPException(425, "Job not yet complete")
    return StreamingResponse(
        BytesIO(await client.download(job_id)),
        media_type="application/octet-stream",
    )
```

### Enum Strategy Resolution

**Learning**: `enum-strategy-resolution`

Use `str` with `Enum` and a default member for backward-compatible strategy dispatch. This lets you accept both enum members and string values while maintaining a single source of truth.

```python
from enum import Enum

class ProcessingStrategy(str, Enum):
    FAST = "fast"
    THOROUGH = "thorough"
    DEFAULT = "default"  # backward-compat fallback

def process(data: dict, strategy: str | ProcessingStrategy = ProcessingStrategy.DEFAULT):
    strategy = ProcessingStrategy(strategy) if isinstance(strategy, str) else strategy
    match strategy:
        case ProcessingStrategy.FAST:
            return fast_process(data)
        case ProcessingStrategy.THOROUGH:
            return thorough_process(data)
        case ProcessingStrategy.DEFAULT:
            return standard_process(data)

# All of these work:
process({"k": "v"})                            # default
process({"k": "v"}, "fast")                   # string
process({"k": "v"}, ProcessingStrategy.THOROUGH)  # enum member
```

### Defensive Enum Mapping From DB Strings

**Learning**: `defensive-enum-mapping-from-db-strings`

Database columns that store enum keys as strings usually lack `CHECK` constraints — the DB will happily accept `"PENDINGG"`, `"pending_v2"`, or `""`. When such a value is read back and passed to `ProcessingStrategy(row.status)`, the resulting `ValueError` crashes the request or kills the stream. Wrap every enum-from-DB lookup in a private helper that catches `ValueError`/`KeyError` and returns `None`, then filter `None` out of the stream. This gives graceful degradation for stale, corrupt, or forward-incompatible values rather than a hard crash.

```python
# WRONG — one corrupt row kills the whole list endpoint
from enum import Enum

class ProcessingStrategy(str, Enum):
    FAST = "fast"
    THOROUGH = "thorough"

async def list_workflows_bad(db: AsyncSession):
    rows = await db.execute(select(Workflow))
    return [
        {"id": r.id, "strategy": ProcessingStrategy(r.strategy)}  # ValueError on stale row
        for r in rows.scalars()
    ]

# CORRECT — private helper degrades gracefully; corrupt rows are skipped
def _safe_strategy(raw: str | None) -> ProcessingStrategy | None:
    if not raw:
        return None
    try:
        return ProcessingStrategy(raw)
    except (ValueError, KeyError):
        logger.warning("Unknown strategy value in DB", extra={"raw": raw})
        return None

async def list_workflows(db: AsyncSession):
    rows = await db.execute(select(Workflow))
    mapped = [
        {"id": r.id, "strategy": strategy}
        for r in rows.scalars()
        if (strategy := _safe_strategy(r.strategy)) is not None
    ]
    return mapped
```

**Detection:**

```bash
rg 'SomeEnum\(' --type py -A 1 | rg -v 'except|try|return None'
```

**Rule:** Never call an enum constructor directly on a DB-sourced string. Always wrap it in a helper that catches `ValueError`/`KeyError` and returns `None`, so stale or corrupt rows degrade instead of crashing.

### Learning: `inline-http-header-parsing-in-handlers`

**Symptom:** Parsing `Location` response headers inline across 5+ handler methods — the same 3-line extraction repeated everywhere, drifting over time.

```python
# SMELL: repeated in every handler
def create_report(self, data):
    response = self.client.post("/reports", json=data)
    location = response.headers.get("Location", "")
    report_id = location.split("/")[-1] if location else None
    return report_id

def create_schedule(self, data):
    response = self.client.post("/schedules", json=data)
    location = response.headers.get("Location", "")
    schedule_id = location.split("/")[-1] if location else None
    return schedule_id
```

```python
# REFACTORED: shared helper
def extract_resource_id(headers: dict) -> str | None:
    location = headers.get("Location", "")
    return location.rstrip("/").split("/")[-1] if location else None

def create_report(self, data):
    response = self.client.post("/reports", json=data)
    return extract_resource_id(response.headers)
```

**Detection:**

```bash
rg 'headers\.get\(["\']Location' --type py -c | rg '[2-9]|[1-9][0-9]+'
```

**Rule:** When the same header-parsing logic appears in 2+ handlers, extract a module-level helper. Resource-ID extraction from `Location` headers is particularly drift-prone because each handler handles missing/malformed headers slightly differently.

### Learning: `duplicated-response-parsing-in-llm-nodes`

**Symptom:** Identical 25-line response-parsing logic copied into multiple LangChain/LangGraph node functions. A bug fix applied to one node misses the others.

```python
# SMELL: same 25 lines in parse_agent_output, parse_tool_result, etc.
def parse_agent_output(result):
    if not result:
        return None
    try:
        data = json.loads(result)
        if "error" in data:
            raise ValueError(data["error"])
        return data.get("output", {}).get("text")
    except json.JSONDecodeError:
        match = re.search(r'"text":\s*"([^"]*)"', result)
        return match.group(1) if match else None
```

```python
# REFACTORED: mixin method
class OutputParserMixin:
    def parse_response(self, result: str | dict) -> str | None:
        if not result:
            return None
        data = result if isinstance(result, dict) else self._try_parse_json(result)
        if isinstance(data, dict) and "error" in data:
            raise ValueError(data["error"])
        return data.get("output", {}).get("text") if isinstance(data, dict) else self._fallback_extract(result)

    def _try_parse_json(self, raw: str) -> dict | str:
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return raw

    def _fallback_extract(self, raw: str) -> str | None:
        match = re.search(r'"text":\s*"([^"]*)"', raw)
        return match.group(1) if match else None
```

**Detection:**

```bash
rg 'json\.loads.*result|re\.search.*text' --type py -c | rg '[2-9]|[1-9][0-9]+'
```

**Rule:** LLM response parsing is inherently fragile (JSON-in-text, fallback regex, error wrappers). When 2+ nodes need it, extract a mixin or base class — a single fix propagates to all consumers.

### Learning: `duplicate-service-account-check`

**Symptom:** Same expensive method (network call, DB query, file I/O) called twice in a single function body — once for a check, once for use.

```python
# SMELL: two calls, two network round-trips
def process_payment(self, order):
    if self.auth_service.get_service_account() is None:
        raise NoServiceAccount()
    account = self.auth_service.get_service_account()
    self.charge(account, order.total)
```

```python
# REFACTORED: single call, local variable
def process_payment(self, order):
    account = self.auth_service.get_service_account()
    if account is None:
        raise NoServiceAccount()
    self.charge(account, order.total)
```

**Detection:**

```bash
# Find methods called twice in the same function body
rg '(\w+\.\w+\([^)]*\))' --type py | sort | uniq -c | sort -rn | head -20
```

**Rule:** Any method that crosses a process boundary (network, DB, file, subprocess) must be called at most once per function. Bind to a local variable on first call, reuse thereafter.
