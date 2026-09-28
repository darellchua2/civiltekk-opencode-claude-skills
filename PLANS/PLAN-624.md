# PLAN: Location keepalive plugin — protect busy sessions from the 60-min location TTL

**Branch**: feat/624
**Issue:** https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/624
**Base**: main

## Acceptance Criteria

- [x] `plugins/opencode-location-keepalive-v2.ts` deploys via the existing `PLUGINS_SRC_DIR` mirror (no setup.sh change)
- [x] `tests/test_location_keepalive_plugin.test.ts` (node --test) passes: config defaults/clamp, busy-gate, stale-guard, no-touch-when-idle
- [x] `plugins/README.md` entry added
- [ ] Live check: silent >60-min run survives with keepalive on; idle locations still evict with it off/idle — **deferred to post-merge by design** (needs `opencode service restart` + >60 min wall clock; restarting the service mid-pipeline would kill the executing session — see Technical Notes). Procedure recorded in the PR body.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `plugins/opencode-location-keepalive-v2.ts` (new) | — | OpenCode plugin loader (glob), `deploy_plugins()` in `deploy/setup.sh` (glob loop — no edit needed), test file, `tests/test_select_items.bats` count pins (5→6), `plugins/README.md`, root `README.md` plugin section | low (new leaf file; nothing in-repo imports it) |
| `tests/test_location_keepalive_plugin.test.ts` (new) | plugin file | none (leaf) | low |
| `plugins/README.md` (edit) | plugin file exists | humans, `civiltekk-documentation-sync-skill` conventions | low |

No cross-module consumers → architecture review not selected (Step 7 thin-map rule); Step 9 code review backstops.

## Implementation Phases

### Phase 1: Plugin + tests

- [x] **1.1** Create `plugins/opencode-location-keepalive-v2.ts` — plain default export `{ id, setup }` (house convention, no `@opencode/plugin` dep): exported `DEFAULTS`/`normalizeConfig` (mirror `opencode-auto-continue-v2.ts` `envBool`/`envInt` helpers), `TTL_MS = 3_600_000`; busy-candidate `Map<sessionID, lastSeenAt>` fed by `ctx.event.subscribe({signal})` (any event carrying a `sessionID`, extraction `ev.properties ?? ev`); recursive `.unref()`-ed `setTimeout` sweep at `OPENCODE_LOCATION_KEEPALIVE_INTERVAL_MS` (default `1_800_000`): for each candidate — drop if stale (> 2× interval since lastSeen), else probe `ctx.session.get({sessionID})`, drop unless `info.status === 'busy' || info.status === 'running'`, skip if `info.title` is not a non-empty string (empty title would hit the handler's title-regeneration branch — `handlers/session.ts:261-266` at v2.0.18), then `ctx.session.update({sessionID, title: info.title})` (same-title PATCH → durable `session.renamed` → location TTL touch). Per-session try/catch, debug-gated `ctx.client.app.log` logging, unconditional error logging for sweep failures, `setup` returns cleanup (clear timer + `AbortController.abort()`). `OPENCODE_LOCATION_KEEPALIVE_ENABLED` (default true) and `_DEBUG` (default false). Startup: interval ≥ 90% of `TTL_MS` → log + clamp to default. Header comment: mechanism with upstream file:line refs + the coordination constraint (`OPENCODE_AUTO_CONTINUE_STALL_MS` must stay below the keepalive interval; defaults 15 min < 30 min already ordered).
    — **Why:** this is the entire fix; everything else documents or verifies it.
    — **Done when:** file exists, `node --check` passes, default export is `{ id: 'opencode-location-keepalive-v2', setup }`.
    — **Consumers affected:** OpenCode plugin loader + deploy glob (additive); none in-repo.
    — **Done:** plugin written + hardened with a `disposed` flag after a gate-flake exposed a real race (cleanup during an in-flight sweep re-armed a leaked timer via `.finally(schedule)`); module-load smoke OK; files: plugins/opencode-location-keepalive-v2.ts; fixes: disposed-flag race fix.

- [x] **1.2** Create `tests/test_location_keepalive_plugin.test.ts` (`node --test`, fake-ctx pattern from `tests/test_auto_continue_plugin.test.ts`): (a) `normalizeConfig` defaults, env overrides, invalid-value fallbacks; (b) interval clamp at ≥90% TTL; (c) `enabled: false` → setup no-ops, no timer, no update; (d) sweep probes a busy candidate (`status: 'busy'`, title `T`) → `update` called once with `{sessionID, title: T}` unchanged; (e) probe idle (`status: 'idle'`) → no `update`, candidate dropped (second sweep doesn't probe it); (f) empty/missing title → no `update` but candidate retained if still busy; (g) stale candidate (no events for > 2× interval) dropped without probe; (h) `update` rejection → logged, sweep continues with remaining candidates; (i) cleanup clears the timer and aborts the event subscription. Timer-driven paths driven with small injected interval + `await new Promise(r => setImmediate(r))` ticks, no real sleeps beyond ms.
    — **Why:** the ticket's gate-checkable AC; also the busy-gate safety property (idle locations must still evict).
    — **Done when:** `node --test tests/test_location_keepalive_plugin.test.ts` exits 0.
    — **Consumers affected:** none (leaf test).
    — **Done:** 14 tests, 15/15 consecutive green runs after hardening two timing-knife-edge assertions (empty-title retention vs staleness conflation; stale-probe bound); files: tests/test_location_keepalive_plugin.test.ts; fixes: timing-robustness rewrite of 2 tests.

- [x] **1.3** Run the verification gate scoped to this change: `node --test tests/test_location_keepalive_plugin.test.ts tests/test_auto_continue_plugin.test.ts` (both green — proves no interference with the sibling plugin's helpers) and `node --check plugins/opencode-location-keepalive-v2.ts`.
    — **Why:** the exit gate for Phase 1; catches regressions in the mirrored conventions.
    — **Done when:** both test files pass, zero failures.
    — **Consumers affected:** none.
    — **Done:** node --test 39/39 (14 keepalive + 25 auto-continue), module-load substitute for the unavailable `node --check` on TS; full bats suite also run (Phase 1 escalated to full tier — new file enters the global plugin-loader glob): 618/618 exit 0 after count-sync fix; files: tests/test_select_items.bats (5→6 plugin count pins, 3 assertions); fixes: plugin-count sync + disposed-race + 2 flaky tests.

### Phase 2: Documentation

- [x] **2.1** Add a `plugins/README.md` section for the keepalive plugin: purpose (one paragraph, location-TTL mechanism), env vars table (`OPENCODE_LOCATION_KEEPALIVE_ENABLED` / `_INTERVAL_MS` / `_DEBUG` with defaults), and the auto-continue coordination constraint (`stallMs` < keepalive interval).
    — **Why:** ticket AC-3; plugins/README.md is the plugin inventory per repo convention.
    — **Done when:** README lists the plugin with env vars and the constraint.
    — **Consumers affected:** humans reading `plugins/README.md`.
    — **Done:** `## Plugin notes` section added with mechanism paragraph, env table, coordination constraint; root README.md plugin section also updated (summary list + "Six local plugins" + per-plugin paragraph) — the grep sweep found it as an explicit per-plugin listing; files: plugins/README.md, README.md; fixes: none.

- [x] **2.2** Sweep for plugin-count/list drift: `rg -n "plugin" README.md AGENTS.md deploy/setup.sh deploy/setup.ps1` limited to inventory/count listings; add the new plugin only where an explicit per-plugin list exists (glob-based deployments need nothing). `plugins/` count appears in setup.sh success prose only (dynamic `count`) — expected no edits.
    — **Why:** repo §Adding Skills or Subagents sync rules; guards doc drift flagged by `civiltekk-documentation-sync-skill`.
    — **Done when:** every explicit per-plugin listing includes the new plugin, or confirmed absent by the grep evidence in the phase commit.
    — **Consumers affected:** none (docs only).
    — **Done:** sweep found exactly one explicit listing (README.md:241 "Five local plugins" + summary + paragraphs — fixed in 2.1); setup.sh/AGENTS.md carry no static plugin inventory (dynamic counts only); bats count pins (`test_select_items.bats`, 3 assertions) were the machine-checked registry — synced in Phase 1; files: none beyond 2.1's; fixes: none.

### Phase 3: Deploy-path verification (file-level, non-destructive)

- [x] **3.1** Prove AC-1 without touching the live service: assert the new file matches the deploy glob (`case` excludes only dotfiles/`node_modules`; `cp -r plugins/opencode-location-keepalive-v2.ts` path resolves). Document the live soak in the PR body instead of running it: the >60-min silent-run survival check and the idle-eviction regression check, with exact commands (`OPENCODE_LOCATION_KEEPALIVE_DEBUG=1`, grep `location services evicted` in `~/.local/share/opencode/log/opencode.log`). **Never run `opencode service restart` during the pipeline — it would kill this executing session.**
    — **Why:** AC-1 is "deploys via existing mirror"; AC-4's live soak needs a service restart + 60+ min wall clock, both out of bounds mid-pipeline.
    — **Done when:** glob assertion passes and the PR body carries the soak commands.
    — **Consumers affected:** none.
    — **Done:** deploy-glob assertion passed (DEPLOY-GLOB-OK — the new file is selected by the same `case` filter `deploy_plugins()` uses); soak procedure written into the PR body; files: none; fixes: none.

## Technical Notes

- Verified against opencode tag v2.0.18 (`cd9a14a`): TTL default 60 min (`packages/core/src/location-activity.ts:25`), refresh on durable events only (streaming deltas and `session.tool.progress` are ephemeral — `packages/schema/src/session-event.ts:523`), expiry interrupts running sessions (`location-activity.ts:62-71`, test-verified upstream), touch path `ctx.session.update` → `PATCH /api/session/{id}` → `Session.rename` unconditional durable publish (`handlers/session.ts:256-279`, `session/session.ts:72-75`) → bus attaches location (`bus.ts:209-249,523`) → `touch()`.
- `ctx.session.rename` does NOT exist at 2.0.18 — use `ctx.session.update`. `ctx.session.active` does NOT exist — busy detection is probe-based via `ctx.session.get` (`.status` ∈ `busy`/`running`), proven pattern from `opencode-auto-continue-v2.ts:337-345`.
- The touch's own `session.renamed` event re-feeds the candidate map — a silent-tool session stays self-sustaining between its boundary events.
- Coordination: `OPENCODE_AUTO_CONTINUE_STALL_MS` (default 900_000) must stay strictly below the keepalive interval (default 1_800_000) so the watchdog still wins races for true silent hangs.
- Live soak deferred to post-merge: needs `opencode service restart` (kills the executing session mid-pipeline — demonstrated twice mid-run by location restarts) and >60 min wall clock.

## Dependencies

None. Upstream issue to `anomalyco/opencode` (make `tool.progress` durable / exempt active executions / expose `timeToLive`) is parallel work, explicitly out of scope (#624 body).

## Risks & Mitigation

- **Plugin API drift on opencode upgrades**: all ctx calls optional-chained with one-time disable+warn on absence (mirror auto-continue's `canAbort` pattern) — degradation is a logged no-op, never a crash.
- **Touching a session that finished between probe and update**: worst case one harmless same-title rename on an idle session; eviction still proceeds after its own 60-min quiet.
- **DB growth**: one durable event per busy session per interval — trivial.
- **Watchdog blinding** (interval < stallMs misconfiguration): startup warning + README constraint; defaults already ordered.

## Trace

```
GATE 6d85123 tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a (node --test 39/39 + bats 618/618 exit 0; lint substituted with module-load smoke — no linter configured; escalated full: new file enters the global plugin-loader glob)
GATE 87061d0 tier=light lint=t typecheck=n.a build=- unit=t e2e=n.a (select-items + ships-plugins bats green, node --test 14/14 post-hardening; docs phase)
GATE 87061d0 tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a (ticket exit gate: bats 618/618 exit 0, node --test 39/39, module-load OK)
GATE 24e3d04 tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a (review-fix re-gate after rebase onto origin/main a8b95be, final tree: bats 621/621 exit 0, node --test 40/40, module-load OK)
```
