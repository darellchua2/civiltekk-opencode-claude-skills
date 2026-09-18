# PLAN: Add opencode-auto-continue-v2 plugin (self-healing session recovery)

**Branch**: feat/418
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/418
**Base**: main

## Acceptance Criteria

- [ ] AC1 — `plugins/opencode-auto-continue-v2.ts` ships as plain `{ id, setup }` default export (no `@opencode/plugin` runtime dep), matching the `vibeguard.ts` convention
- [ ] AC2 — Listens via `ctx.event.subscribe({ signal })`; matches a curated retryable error-pattern list; excludes `MessageAbortedError`/`operation was aborted` + ESC latch via `session.interrupted`
- [ ] AC3 — On idle: `ctx.session.prompt("continue")` with exponential backoff (1s→8s cap), 10s cooldown, max 5 consecutive auto-continues; counter resets on a real user message
- [ ] AC4 — Env-configurable (`OPENCODE_AUTO_CONTINUE_*`), debug via `OPENCODE_AUTO_CONTINUE_DEBUG=1`, logging via `ctx.client.app.log()` only
- [ ] AC5 — Deploys via existing `deploy_plugins()` with zero setup.sh changes; README section with v2 status note
- [ ] AC6 — Out-of-scope recovery paths (busy-stall abort-first, tool-loop detection, tool-as-text scanning) documented as upgrade path in the plugin header

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `plugins/opencode-auto-continue-v2.ts` | — | OpenCode v2 plugin loader (glob-discovers `~/.config/opencode/plugins/`); `deploy_plugins()` in `deploy/setup.sh` copies it verbatim | low — additive new file, no registration edits |
| `tests/test_auto_continue_plugin.test.ts` | plugin exports pure helpers | verification gate (Step 4), CI | low |
| `README.md` (plugins section) | final plugin name/behavior | users; doc-consistency checks | low — prose only, no counted sections |

No in-repo module consumes the plugin's exports besides its test — the sole runtime consumer is the external OpenCode plugin loader.

## Implementation Phases

### Phase 1: Plugin core

- [x] **1.1** Create `plugins/opencode-auto-continue-v2.ts` with a plain `{ id: "opencode-auto-continue-v2", setup(ctx) }` default export, env-config parsing (`OPENCODE_AUTO_CONTINUE_ENABLED/_MESSAGE/_MAX_CONSECUTIVE/_THROTTLE_MS/_BASE_BACKOFF_MS/_MAX_BACKOFF_MS/_DEBUG`), an AbortController-scoped `ctx.event.subscribe` loop, and a cleanup return that aborts it. Header comment documents purpose, v2 mapping, licensing (patterns-as-data from MIT `developing-today/opencode-auto-continue`; GPL `Mte90/opencode-auto-resume` reference-only), and the out-of-scope upgrade path (AC1, AC4, AC6).
    — **Why:** establishes the v2 entrypoint every later step hangs off; the loader rejects anything but the validated `{ id, setup }` shape.
    — **Done when:** file loads under Node type-stripping (`node -e "import(...)"` succeeds) and default export has exactly `id` and `setup` keys.
    — **Consumers affected:** plugin loader (first registration); none in-repo.
    — **Done:** plugin created with plain `{id, setup}` export, env config, subscribe loop, cleanup; files: plugins/opencode-auto-continue-v2.ts; fixes: none
- [x] **1.2** Implement error classification: retryable pattern list (case-insensitive substrings: bad request, reasoning_opaque, SSE read timed out, ContextOverflowError, too large to compact, JSON parsing failed, Invalid input for tool, tried to call unavailable tool, tool_use ids were found without tool_result, ECONNREFUSED, ECONNRESET, idle timeout, no data received, expected string received undefined) and exclusion-first matching (`MessageAbortedError`, `operation was aborted` never retried), plus a per-session ESC latch set by `session.interrupted` and cleared by a subsequent real user message (AC2).
    — **Why:** exclusion-first ordering is the safety property — user-cancelled sessions must never be resumed even if a match pattern also hits.
    — **Done when:** pure `classifyError(msg)` helper returns `{ retryable, reason }` and unit tests prove excludes win over matches and the ESC latch suppresses sends until a user message clears it.
    — **Consumers affected:** retry engine (1.3).
    — **Done:** classifyError with exclusion-first ordering (14 match / 2 exclude patterns) + ESC latch in event handler; user-message clear lands via prompt hook (1.3 wiring); files: plugins/opencode-auto-continue-v2.ts; fixes: none
- [x] **1.3** Implement the idle-boundary retry engine: on matching `session.error`, arm a pending retry; when the session goes idle and backoff has elapsed, send `ctx.session.prompt({ sessionID, text })` (default `continue`); exponential backoff 1s doubling to an 8s cap, 10s cooldown between sends, hard cap of 5 consecutive auto-continues per session, consecutive counter reset when the user sends a real message. Never send while the session is busy; never abort a live runner (AC3).
    — **Why:** idle-boundary-only is the deliberate scope cut — a parked prompt cannot unblock a hung runner in v2, and aborting live work risks killing healthy long builds.
    — **Done when:** unit tests prove backoff arithmetic (1s→2s→4s→8s→8s), cap at 5 blocks further sends, and a user message resets the counter.
    — **Consumers affected:** plugin loader session API (`ctx.session.prompt`).
    — **Done:** onIdle scheduler + send with idle race-guard re-check, backoff/cooldown/cap/reset wired; unit proof lands in 2.1; files: plugins/opencode-auto-continue-v2.ts; fixes: none
- [x] **1.4** Add logging through `ctx.client.app.log()` with an `opencode-auto-continue-v2` prefix, gated so normal operation is silent and `OPENCODE_AUTO_CONTINUE_DEBUG=1` (or `_DEBUG=1`) reports load, matches, sends, and caps (AC4).
    — **Why:** repo convention (vibeguard/auto-resume) — zero `console.log` in normal operation; debug must be verifiable.
    — **Done when:** debug env unset produces no log calls on the classified-error happy path; set produces load/match/send lines.
    — **Consumers affected:** none (observability only).
    — **Done:** debug-gated log() via ctx.client.app.log with load/classify/send/cap coverage, never throws; files: plugins/opencode-auto-continue-v2.ts; fixes: none
- [x] **1.5** Export pure helpers (`classifyError`, backoff/delay computation, config normalization) from the same module alongside the default export, without changing the default-export shape (feeds 2.1).
    — **Why:** the runtime loader consumes only the default export; named exports cost nothing and make the logic testable without mocks.
    — **Done when:** `import plugin, { classifyError, ... } from "plugins/opencode-auto-continue-v2.ts"` works under Node type stripping.
    — **Consumers affected:** tests/test_auto_continue_plugin.test.ts.
    — **Done:** classifyError/backoffDelay/normalizeConfig/pattern arrays exported; verified by load smoke (named exports present); files: plugins/opencode-auto-continue-v2.ts; fixes: none

### Phase 2: Runnable check

- [ ] **2.1** Add `tests/test_auto_continue_plugin.test.ts` using `node:test` + native type stripping, covering: exclusion patterns beat match patterns, ESC latch blocks until user message, backoff sequence and cap, consecutive-cap enforcement and user-message reset, config normalization defaults (AC2, AC3).
    — **Why:** the repo's only non-trivial logic in this change lives in the classifier and retry engine; one test file is the smallest check that fails if it breaks (no bats — no shell paths change).
    — **Done when:** `node --test tests/test_auto_continue_plugin.test.ts` exits 0.
    — **Consumers affected:** verification gate (4.1).

### Phase 3: Docs

- [ ] **3.1** Add a README.md section for the plugin in the existing local-plugins area (vibeguard/ponytail/learnings style): what it does, error classes covered, env knobs, v2 status note, and the explicit upgrade path (AC5, AC6).
    — **Why:** README.md:17 already advertises `plugins/` contents; an undocumented plugin breaks the repo's own documentation contract.
    — **Done when:** README contains the section with the v2 status note; `bats tests/test_count_drift.bats` still passes (plugin counts are not synced, prose-only edit).
    — **Consumers affected:** users; doc-consistency checks.

### Phase 4: Verification gate

- [ ] **4.1** Run the gate: `node --test tests/test_auto_continue_plugin.test.ts`, plugin import smoke (`node -e "await import('./plugins/opencode-auto-continue-v2.ts')"`), and `bats tests/test_count_drift.bats`; fix any failure before commit.
    — **Why:** repo has no tsc/eslint for plugin TS (verified: package.json scripts absent, no typescript in node_modules); CI is the authoritative type gate, the local gate is logic + loadability + count drift.
    — **Done when:** all three commands exit 0 in the worktree.
    — **Consumers affected:** none.

## Technical Notes

- v2 API surface: `ctx.event.subscribe({ signal })` (events: `session.error`, `session.status`, `session.idle`, `session.interrupted`), `ctx.session.prompt({ sessionID, text })`, `ctx.client.app.log()`.
- Plain `{ id, setup }` default export — the validated v2 loader shape (same as `vibeguard.ts:24-25`); named exports are additive and ignored by the loader.
- Idle-boundary only: in v2, `session.prompt()` while a runner is Running joins the existing run (parks in the inbox) — it cannot unblock a genuinely hung stream. Abort-first stall recovery is deliberately deferred (issue documents it as the upgrade path).
- Deployment: `deploy_plugins()` (deploy/setup.sh:3202) copies `plugins/*` wholesale — dotfiles/`_archived`/`node_modules` are the only skips, so a single new file needs no setup.sh change.
- Licensing: pattern list adapted as data from MIT-licensed developing-today/opencode-auto-continue; Mte90/opencode-auto-resume is GPL-3.0 — ideas only, no code.

## Dependencies

None external. No `blocked-by:` tickets.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| False-positive retry loops on permanent errors | Exclusion-first matching, 5-attempt hard cap, backoff cap 8s; caps verified by unit test |
| Resuming a session the user deliberately cancelled | ESC latch from `session.interrupted` + `MessageAbortedError`/abort-message excludes; tested |
| Plugin loader rejects non-standard export shape | Plain `{ id, setup }` exactly as vibeguard.ts (already proven on this loader); import smoke in gate |
| README edit trips repo count-drift checks | Plugins are not in any counted registry; `test_count_drift.bats` run in the gate confirms |
| Runtime-only failures invisible locally (no tsc) | Node type-stripping load smoke + CI as authoritative type gate |

## Plan-review triage record

Consumer Map is thin by design (single new file + prose; sole runtime consumer is the external plugin loader) → **zero plan reviewers selected** (no cross-module nodes, no frontend signal); Step 9 code review backstops unconditionally.
