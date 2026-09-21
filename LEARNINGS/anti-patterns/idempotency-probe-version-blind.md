# Anti-pattern: idempotency probe version-blindness defeats the pin-bump ritual

`pip show <pkg>` + import probes skip the install for ANY installed version,
so pin bumps never propagate to working installs — the probe only heals
broken installs. The retired `--force-reinstall` flow converged to the pin;
the probe does not.

markitdown-mcp's installer probe (`install_markitdown_mcp` in setup.sh)
originally passed for any version while the docs promised
`markitdown-mcp==0.0.1a7` — a future 0.0.1a8 fix would silently never reach
deployed machines. Fix: include the version in the probe
(`pip show markitdown-mcp | grep -qF "Version: 0.0.1a7"`).

**Rule:** when a docs-or-ritual promises a pinned version, the idempotency
probe must assert the pinned version, not mere presence.

- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
