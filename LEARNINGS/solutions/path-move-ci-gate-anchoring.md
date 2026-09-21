# Path-move restructure: anchor CI tarball gates, verify search-path consumers

- **Category**: solution
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-14
- **Summary**: When moving source dirs (ticket #381 pattern), CI `npm pack` gates that grep bare substrings (`skills/`) stay green on nested ghosts — anchor to package-root paths. Also: config files consumed via search-path chains (e.g. `plugins/vibeguard.ts:78-80` checks `<project>/.opencode/vibeguard.config.json`) need a bridge symlink or explicit COPY per runtime to keep resolving.

## Evidence

- Branch `feat/381`: `.github/workflows/release.yml:60` greps unanchored `skills/`/`agents/` — passes even if the root dir is absent but any nested `*/skills/` path ships (false-green → broken npx tarball).
- `plugins/vibeguard.ts:78-80` resolves config by search path, not relative to the plugin file — the move to `plugins/vibeguard.config.json` only works because (a) Dockerfile:56 COPYs it to `/app/.opencode/vibeguard.config.json` and (b) setup.sh/ps1 deploy it to `~/.config/opencode/`. A third leg — the local pm2 runtime reading it through the `opencode_app/.opencode/vibeguard.config.json` typechange symlink — was removed with the pm2 bridge in #428. Dropping either remaining leg silently disables masking in that runtime.
- Rewire discipline that held (keep for Phase 2+): separator-agnostic grep gate `opencode_app[/\]\.opencode` + explicit must-stay list (setup.sh:118 `SOURCE_CONFIG`, :2608 mcp launcher; setup.ps1:133) so sed can't over-reach.

> **Update 2026-09-21 (#506):** several anchors above are historical — `plugins/vibeguard.ts` is gone, replaced by `plugins/opencode-vibeguard-v2.ts` + `plugins/vibeguard.config.json` (the v2 port); the `setup.ps1:133` must-stay list reference is dead (#474 turned setup.ps1 into a 109-line thin launcher with no must-stay list); the "setup.sh/ps1 deploy it to `~/.config/opencode/`" leg is now setup.sh-only (`deploy/setup.sh:2710-2713,4086-4087` — the ps1 forwards to bash); the vibeguard COPY moved from `Dockerfile:56` to `Dockerfile:82`. The search-path-consumer rule stands: enumerate every runtime that resolves a moved config and verify each leg.
