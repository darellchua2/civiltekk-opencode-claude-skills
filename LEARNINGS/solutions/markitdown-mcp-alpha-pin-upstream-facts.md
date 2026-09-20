# Solution: markitdown-mcp upstream facts (alpha pin, co-install, residual)

Upstream `markitdown-mcp` (PyPI, microsoft/markitdown), verified 2026-09-20:

- Publishes **only alphas** — latest `0.0.1a7` (2026-09-14). Plain
  `pip install markitdown-mcp` FAILS ("no matching distribution") because pip
  skips pre-releases; an exact pin `==0.0.1a7` installs without `--pre` and
  keeps pre-releases out of transitive resolution.
- `requires_dist`: `markitdown[all]>=0.1.1,<0.2.0`, `mcp>=2.1.1,<3.0.0`,
  `requests` — the `[all]` extra is why audio→Google Speech /
  YouTube→YouTube is a documented residual (Azure stays kwargs-gated).
- stdio is the default transport (`--http` opt-in, never passed);
  `MARKITDOWN_ENABLE_PLUGINS` is read by `check_plugins_enabled()`, default
  `"false"`.
- Import probe: `from markitdown_mcp.__main__ import main` (source at
  `packages/markitdown-mcp/src/markitdown_mcp/__main__.py`).
- Coexists with `docling-mcp 3.x` on one shared `mcp` 2.x
  (`mcp[cli]>=2.0,<3.0` ∩ `>=2.1.1,<3.0` non-empty) — the retired vendored
  pin `mcp<2.0` was the sole conflict cause.
- Bump ritual: the pin appears in `deploy/setup.sh`, `deploy/setup.ps1`,
  `opencode_app/Dockerfile` — bump all three together.

- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-21
