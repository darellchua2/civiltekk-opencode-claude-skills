# Packaging route (values)

Configure Python packaging for applications and libraries. The host SKILL.md carries the METHOD (detect → route → load); this file carries the VALUES for the `packaging` route.

**Scope:** choosing a build tool; writing/restructuring pyproject.toml; app-vs-library dependency strategy; PyPI publishing; entry points; Python monorepo packages. The app scaffolding baseline (pinned FastAPI pyproject standard) lives in `references/scaffold.md` in this skill.

**Related:** `python-ruff-linter-skill` / `civiltekk-test-generation-skill` route `python` (tool config sections) · `monorepo-management-skill` (JS/TS side).

## House decision rules

**App vs library (the deltas that change config):** apps pin exact dependency versions (lockfile discipline), build optional (wheel for Docker), version informal, no PyPI name constraints; libraries use minimum-compatible ranges, require sdist+wheel builds, semver, unique PyPI name, license, and published metadata completeness.

**Tool choice:** **uv** for new projects (house default — fastest resolution, lockfile, drop-in pip interface); **Poetry** where the team already standardizes on it (full-featured, lock file); **setuptools** for maximum compatibility/legacy; **hatch** when you want build + env management in one. All four configure via `[project]` in pyproject.toml (PEP 621) — backend sections differ, project metadata doesn't.

**Common traps:** dev/test deps go in dependency-groups or optional-extras (never install_requires); console entry points via `[project.scripts]` (`cli = "pkg.module:main"`); pin build-backend + its version; TestPyPI dry-run before a real PyPI release; trust publishing creds via OIDC (trusted publishing) over long-lived tokens.

> Removed 2026-09: per-backend pyproject.toml full listings (uv/Poetry/setuptools/hatch variants), venv walkthroughs, publishing step-by-steps, monorepo package example trees — backend-specific config the model regenerates on demand; kept the app-vs-library decision matrix, tool-choice rules, and the traps.
