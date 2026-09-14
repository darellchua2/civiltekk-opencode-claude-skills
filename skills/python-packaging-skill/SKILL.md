---
name: python-packaging-skill
description: >-
  Python packaging for apps and libraries — pyproject.toml, Poetry, uv,
  setuptools, hatch, dependency management, PyPI publishing.
license: Apache-2.0
compatibility: opencode
category: Language-Specific
---

## What I do

I help you configure Python packaging for both **applications** and **libraries**:

1. **pyproject.toml Standards**: Compliant configuration for all build backends
2. **Project vs Library**: Different strategies for deployable apps vs publishable packages
3. **Poetry**: Full dependency management, lock files, virtual environments, publishing
4. **uv**: Ultra-fast modern alternative for dependency resolution and virtual environments
5. **setuptools**: Traditional build backend for maximum compatibility
6. **Hatch**: Modern build backend with environment management
7. **Dependency Management**: Pinning, version ranges, extras, and groups
8. **Publishing**: PyPI, TestPyPI, and private registry workflows

## When to use me

Use this skill when:
- Creating a new Python project and choosing a build tool
- Writing or restructuring pyproject.toml
- Deciding between Poetry, uv, setuptools, or hatch
- Setting up dependency groups (dev, test, docs)
- Publishing a library to PyPI
- Configuring entry points and CLI scripts
- Setting up a monorepo with shared Python packages
- Managing virtual environments across a team
- Configuring build and publish CI/CD pipelines

## Related Skills

- **python-backend-skill**: Project scaffolding and app structure (FastAPI/Django/Flask). This skill handles the packaging configuration those projects use.
- **python-ruff-linter-skill**: Linting configuration often defined in pyproject.toml
- **python-pytest-creator-skill**: Test configuration often defined in pyproject.toml
- **monorepo-management-skill**: JS/TS monorepos. This skill covers Python monorepo packaging patterns.

---

## Step 1: Project vs Library

### Decision Matrix

| Aspect | Application (Project) | Library (Package) |
|--------|----------------------|-------------------|
| **Purpose** | Deployed service, CLI tool, script | Reusable code published to PyPI |
| **Dependencies** | Pinned exact versions | Version ranges (minimum compatible) |
| **Build** | Optional (wheel for Docker) | Required (sdist + wheel) |
| **Publish** | Internal registry or skip | PyPI or private registry |
| **Entry points** | Scripts/console_scripts | Optional |
| **Version scheme** | Often single `0.1.0` or git-based | Semantic versioning required |
| **`[project]` name** | Internal, doesn't need PyPI name | Must be unique on PyPI |
| **License** | May not need one | Required for PyPI |

---

## Step 2: pyproject.toml — Application

### With uv (Recommended for new projects)

```toml
[project]
name = "my-api"
version = "0.1.0"
description = "My API service"
requires-python = ">=3.12"
dependencies = [
    "fastapi==0.115.0",
    "uvicorn[standard]==0.32.0",
    "sqlalchemy[asyncio]==2.0.36",
    "asyncpg==0.30.0",
    "pydantic-settings==2.6.0",
    "alembic==1.14.0",
    "redis==5.2.0",
]

[project.optional-dependencies]
dev = [
    "pytest==8.3.3",
    "pytest-asyncio==0.24.0",
    "pytest-cov==6.0.0",
    "httpx==0.27.2",
    "ruff==0.7.0",
    "mypy==1.13.0",
]

[tool.uv]
dev-dependencies = [
    "pytest>=8.0",
    "pytest-asyncio>=0.23",
    "pytest-cov>=5.0",
    "httpx>=0.27",
    "ruff>=0.7",
    "mypy>=1.13",
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

### With Poetry (Application)

```toml
[tool.poetry]
name = "my-api"
version = "0.1.0"
description = "My API service"
authors = ["Team <team@example.com>"]
package-mode = false

[tool.poetry.dependencies]
python = "^3.12"
fastapi = "0.115.0"
uvicorn = {extras = ["standard"], version = "0.32.0"}
sqlalchemy = {extras = ["asyncio"], version = "2.0.36"}
asyncpg = "0.30.0"
pydantic-settings = "2.6.0"
alembic = "1.14.0"
redis = "5.2.0"

[tool.poetry.group.dev.dependencies]
pytest = "^8.3"
pytest-asyncio = "^0.24"
pytest-cov = "^6.0"
httpx = "^0.27"
ruff = "^0.7"
mypy = "^1.13"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

---

## Step 3: pyproject.toml — Library

### With Hatch (Modern, PEP 621 native)

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-library"
version = "1.0.0"
description = "A reusable Python library"
readme = "README.md"
license = "MIT"
requires-python = ">=3.10"
authors = [
    { name = "Author Name", email = "author@example.com" },
]
keywords = ["my-library", "utility"]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
    "Programming Language :: Python :: 3.13",
    "Topic :: Software Development :: Libraries",
]
dependencies = [
    "httpx>=0.25.0",
    "pydantic>=2.0",
]

[project.optional-dependencies]
async = ["httpx[http2]>=0.25.0"]
cli = ["click>=8.0"]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "ruff>=0.7",
    "mypy>=1.13",
    "build>=1.0",
]

[project.urls]
Homepage = "https://github.com/org/my-library"
Documentation = "https://my-library.readthedocs.io"
Repository = "https://github.com/org/my-library"
Changelog = "https://github.com/org/my-library/blob/main/CHANGELOG.md"

[project.scripts]
my-cli = "my_library.cli:main"

[tool.hatch.build.targets.wheel]
packages = ["src/my_library"]

[tool.hatch.envs.default]
installer = "uv"
features = ["dev"]

[tool.hatch.envs.hatch-test]
features = ["dev"]

[tool.ruff]
target-version = "py310"
line-length = 120
src = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.mypy]
python_version = "3.10"
strict = true
```

### With setuptools (Maximum compatibility)

```toml
[build-system]
requires = ["setuptools>=75.0", "setuptools-scm>=8.0"]
build-backend = "setuptools.build_meta"

[project]
name = "my-library"
dynamic = ["version"]
description = "A reusable Python library"
readme = "README.md"
license = "MIT"
requires-python = ">=3.10"
authors = [
    { name = "Author Name", email = "author@example.com" },
]
dependencies = [
    "httpx>=0.25.0",
    "pydantic>=2.0",
]

[project.optional-dependencies]
dev = ["pytest>=8.0", "ruff>=0.7", "mypy>=1.13", "build>=1.0"]

[project.scripts]
my-cli = "my_library.cli:main"

[tool.setuptools.packages.find]
where = ["src"]

[tool.setuptools_scm]
fallback_version = "0.0.0"
```

### With Poetry (Library)

```toml
[tool.poetry]
name = "my-library"
version = "1.0.0"
description = "A reusable Python library"
authors = ["Author Name <author@example.com>"]
license = "MIT"
readme = "README.md"
packages = [{include = "my_library", from = "src"}]

[tool.poetry.dependencies]
python = ">=3.10,<4.0"
httpx = ">=0.25.0"
pydantic = ">=2.0"

[tool.poetry.group.dev.dependencies]
pytest = ">=8.0"
pytest-cov = ">=5.0"
ruff = ">=0.7"
mypy = ">=1.13"
build = ">=1.0"

[tool.poetry.scripts]
my-cli = "my_library.cli:main"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

---

## Step 4: Dependency Version Strategy

### Application: Pin Exact Versions

```toml
dependencies = [
    "fastapi==0.115.0",
    "uvicorn[standard]==0.32.0",
    "sqlalchemy[asyncio]==2.0.36",
]
```

**Why**: Reproducible deployments. No surprise breakages.

### Library: Use Minimum Ranges

```toml
dependencies = [
    "httpx>=0.25.0",
    "pydantic>=2.0,<3.0",
]
```

**Why**: Maximize compatibility for consumers. Test against range edges.

### Version Specifier Reference

| Specifier | Meaning | Use For |
|-----------|---------|---------|
| `==1.0.0` | Exact version | Applications |
| `>=1.0.0` | Minimum version, any higher | Libraries (broad) |
| `>=1.0.0,<2.0.0` | Minimum, cap at major | Libraries (conservative) |
| `~=1.0.0` | Compatible release (>=1.0.0, <1.1.0) | Libraries (patch only) |
| `~=1.0` | Compatible release (>=1.0, <2.0) | Libraries (minor only) |

---

## Step 5: Tool Workflows

### uv (Recommended)

```bash
uv init my-project                         # Initialize new project
uv add fastapi uvicorn sqlalchemy          # Add dependencies
uv add --dev pytest ruff mypy              # Add dev dependencies
uv remove flask                            # Remove dependency
uv sync                                    # Install from lockfile
uv lock                                    # Update lockfile only
uv run python -m app.main                  # Run in managed env
uv build                                   # Build wheel + sdist
uv publish --token $PYPI_TOKEN             # Publish to PyPI
uv pip compile -o requirements.txt         # Export to requirements
```

### Poetry

```bash
poetry new my-library                      # Create library project
poetry init                                # Initialize in existing dir
poetry add fastapi                         # Add dependency
poetry add --group dev pytest              # Add dev dependency
poetry add --optional cli click            # Add optional dependency
poetry remove flask                        # Remove dependency
poetry install                             # Install from lockfile
poetry install --without dev               # Install without dev group
poetry install --no-root                   # Skip installing the project itself
poetry lock --no-update                    # Regenerate lock without updating
poetry build                               # Build wheel + sdist
poetry publish                             # Publish to PyPI
poetry publish -r test-pypi                # Publish to TestPyPI
poetry run python -m app.main              # Run in managed env
poetry export -f requirements.txt -o requirements.txt --without-hashes
```

### Hatch

```bash
hatch new my-library                       # Create library project
hatch new --init                           # Initialize in existing dir
hatch env create                           # Create default env
hatch run test                             # Run test command
hatch run lint                             # Run lint command
hatch build                                # Build wheel + sdist
hatch publish                              # Publish to PyPI
```

---

## Step 6: Library Project Structure

### Src Layout (Recommended)

```
my-library/
├── pyproject.toml
├── README.md
├── LICENSE
├── CHANGELOG.md
├── src/
│   └── my_library/
│       ├── __init__.py          # Public API
│       ├── py.typed             # PEP 561 marker
│       ├── core.py
│       └── cli.py
├── tests/
│   ├── conftest.py
│   ├── test_core.py
│   └── test_cli.py
└── .github/
    └── workflows/
        ├── ci.yml
        └── publish.yml
```

### src/my_library/__init__.py

```python
"""My Library - A reusable Python library."""

from my_library.core import MyClass, my_function

__version__ = "1.0.0"
__all__ = ["MyClass", "my_function", "__version__"]
```

### src/my_library/py.typed

```
# Empty file — PEP 561 marker indicating this package supports type checking
```

---

## Step 7: Publishing

### Build & Publish (Universal)

```bash
python -m build                           # Uses build frontend
# Produces: dist/my_library-1.0.0.tar.gz + dist/my_library-1.0.0-py3-none-any.whl

python -m twine check dist/*              # Validate distributions
python -m twine upload --repository testpypi dist/*   # TestPyPI first
python -m twine upload dist/*             # Production PyPI
```

### GitHub Actions (Library)

```yaml
name: Publish
on:
  release:
    types: [published]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install build
      - run: python -m build
      - uses: pypa/gh-action-pypi-publish@release/v1
```

### Version Management

| Approach | Tool | Config |
|----------|------|--------|
| Static in `__init__.py` | All | `__version__ = "1.0.0"` |
| Static in pyproject.toml | All | `version = "1.0.0"` |
| Dynamic from git tags | setuptools-scm | `dynamic = ["version"]` + `[tool.setuptools_scm]` |
| Dynamic from VCS | hatch-vcs | `dynamic = ["version"]` + `[tool.hatch.version]` source = "vcs" |
| Poetry version plugin | poetry-version-plugin | Automatic from git tags |

---

## Step 8: CI/CD Templates

### Application CI

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.12", "3.13"]
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync --frozen
      - run: uv run ruff check .
      - run: uv run ruff format --check .
      - run: uv run mypy src
      - run: uv run pytest --cov --cov-report=xml
      - uses: codecov/codecov-action@v4
```

### Library CI (Multi-version + Publish)

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12", "3.13"]
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync --frozen --python ${{ matrix.python-version }}
      - run: uv run pytest --cov

  publish:
    needs: test
    if: github.event_name == 'release'
    runs-on: ubuntu-latest
    permissions:
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv build
      - uses: pypa/gh-action-pypi-publish@release/v1
```

---

## Step 9: Tool Selection Guide

| Scenario | Recommended Tool | Why |
|----------|-----------------|-----|
| New application | **uv** | Fastest, simple, modern |
| New library | **Hatch** or **uv** | PEP 621 native, clean |
| Existing Poetry project | **Poetry** | Don't migrate unnecessarily |
| Maximum PyPI compatibility | **setuptools** | Oldest, most compatible |
| Monorepo Python packages | **uv** + workspaces | Fast, deterministic |
| Need dependency groups | **Poetry** or **uv** | Both support groups |
| Need build targets | **Hatch** | Custom build targets |
| Need lock file portability | **uv** | exports to requirements.txt |
