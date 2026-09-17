## Solution: Docker v1 binary silently ignores the v2 `plugins` key

**Context**: Adding a v2 npm plugin (e.g. `@prevalentware/opencode-goal-plugin`, #382) to `opencode_app/opencode.json` has **no effect** in the Docker standalone endpoint.
**Pattern**: The container installs `opencode-ai@1.18.x` (v1 line) while the baked `/app/opencode.json` is v2-native. The v1 binary ignores the v2 `plugins` key **silently** — no boot warning, no error. Any v2 plugin addition therefore needs either a runtime-presence assertion in the Docker verification path or an explicit Docker descope with a tracking issue.
**Rationale**: Build-only gates stay green while the feature is absent; silent inertness is indistinguishable from "not configured" — the repo's own gate would certify a broken deployment.
**Evidence**:
- `opencode_app/Dockerfile:7` — `ARG OPENCODE_VERSION=1.18.20` (v1 line); `Dockerfile:86-88` self-documents the v1 pin
- `docker-compose.yml:8` — defaults `1.18.11`, disagreeing with the Dockerfile ARG (two version surfaces)
- npm has no `opencode-ai` 2.x line (verified 2026-09-14); the v2 binary ships as a separate distribution
- #374 (closed) tracked the v2 bump; successor issue #387 carries it
**Diagnostic steps** (if a v2 plugin "does nothing" in Docker):
1. Check the container binary version — a v1 binary cannot read the `plugins` key at all
2. Do not trust `docker compose build` green as plugin evidence; assert runtime presence (`/goal` in the web endpoint) instead

> **RESOLVED 2026-09-15 (#387):** the image now installs the v2 binary via the scoped
> `@opencode/cli` npm package (the legacy `opencode-ai` stays v1-only — `1.18.31` latest).
> The compose healthcheck now authenticates and asserts goal-command presence in `/api/command`,
> so this class of inertness fails loudly. Related v2 gotcha folded in: v2 enforces HTTP auth
> on EVERY route (localhost included) with an auto-generated password — healthchecks must
> authenticate via the password file the entrypoint materializes.
**Trade-offs**: The fix (v2 binary bump) also needs a goal-state volume mount (`~/.local/share/opencode-goal-plugin/` sits beside the `opencode-data` volume today) — both folded into #387.
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-14

Surfaced by the architecture review of PLAN-382.
