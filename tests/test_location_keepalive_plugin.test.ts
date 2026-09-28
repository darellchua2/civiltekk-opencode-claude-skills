// Unit tests for plugins/opencode-location-keepalive-v2.ts — pure helpers plus
// the runtime safety properties (busy-gate, stale-guard, idle-never-touched,
// cleanup) exercised through a fake v2 plugin context.
// Run: node --test tests/test_location_keepalive_plugin.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import plugin, {
  DEFAULTS,
  TTL_MS,
  clampInterval,
  normalizeConfig,
  isBusy,
  extractSessionID,
  _setup,
} from '../plugins/opencode-location-keepalive-v2.ts';

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// Fake ctx: queue-fed event stream + recording session API.
function makeFakeCtx(opts: { sessions?: Record<string, { status?: string; title?: string }>; updateRejects?: string[] } = {}) {
  const state = {
    getCalls: [] as string[],
    updateCalls: [] as { sessionID: string; title?: string }[],
    logCalls: [] as { level: string; message: string }[],
    subscribeCalled: false,
    signal: undefined as AbortSignal | undefined,
  };
  const queue: unknown[] = [];
  const wake: ((v?: unknown) => void)[] = [];
  const sessions = opts.sessions ?? {};
  const ctx = {
    event: {
      subscribe: async function* ({ signal }: { signal?: AbortSignal }) {
        state.subscribeCalled = true;
        state.signal = signal;
        while (true) {
          while (queue.length) yield queue.shift();
          await new Promise((resolve) => {
            wake.push(resolve as (v?: unknown) => void);
            signal?.addEventListener('abort', () => resolve(undefined));
          });
        }
      },
    },
    session: {
      get: async ({ sessionID }: { sessionID: string }) => {
        state.getCalls.push(sessionID);
        return sessions[sessionID] ?? { status: 'idle', title: 't' };
      },
      update: async (input: { sessionID: string; title?: string }) => {
        if (opts.updateRejects?.includes(input.sessionID)) throw new Error('boom');
        state.updateCalls.push(input);
      },
    },
    client: {
      app: {
        log: async ({ body }: { body: { level: string; message: string } }) => {
          state.logCalls.push(body);
        },
      },
    },
  };
  return { ctx, state, feed: (ev: unknown) => { queue.push(ev); wake.splice(0).forEach((r) => r()); } };
}

// ── pure helpers ───────────────────────────────────────────────────────────────

test('plugin default export has the loader shape { id, setup }', () => {
  assert.equal(typeof plugin, 'object');
  assert.equal(plugin.id, 'opencode-location-keepalive-v2');
  assert.equal(typeof plugin.setup, 'function');
});

test('normalizeConfig: defaults', () => {
  const cfg = normalizeConfig({});
  assert.deepEqual(cfg, { enabled: true, intervalMs: DEFAULTS.intervalMs, debug: false });
  assert.equal(DEFAULTS.intervalMs, 1_800_000);
  assert.equal(TTL_MS, 3_600_000);
});

test('normalizeConfig: env overrides and invalid-value fallbacks', () => {
  assert.equal(normalizeConfig({ OPENCODE_LOCATION_KEEPALIVE_ENABLED: '0' }).enabled, false);
  assert.equal(normalizeConfig({ OPENCODE_LOCATION_KEEPALIVE_DEBUG: 'yes' }).debug, true);
  assert.equal(normalizeConfig({ OPENCODE_LOCATION_KEEPALIVE_INTERVAL_MS: '600000' }).intervalMs, 600_000);
  // invalid values fall back, never NaN
  assert.equal(normalizeConfig({ OPENCODE_LOCATION_KEEPALIVE_INTERVAL_MS: 'abc' }).intervalMs, DEFAULTS.intervalMs);
  assert.equal(normalizeConfig({ OPENCODE_LOCATION_KEEPALIVE_ENABLED: 'garbage' }).enabled, true);
});

test('clampInterval: ≥90% of TTL falls back to default (touch must land with margin)', () => {
  assert.equal(clampInterval(600_000), 600_000); // 10 min — fine
  assert.equal(clampInterval(3_240_000), DEFAULTS.intervalMs); // 54 min = 90% → clamp
  assert.equal(clampInterval(TTL_MS), DEFAULTS.intervalMs);
  assert.equal(clampInterval(3_000_000), 3_000_000); // 83% of TTL — under the clamp line, kept
});

test('isBusy: only busy/running count', () => {
  assert.equal(isBusy('busy'), true);
  assert.equal(isBusy('running'), true);
  assert.equal(isBusy('idle'), false);
  assert.equal(isBusy(''), false);
});

test('extractSessionID: envelope and bare shapes, mirrors auto-continue', () => {
  assert.equal(extractSessionID({ properties: { sessionID: 's1' } }), 's1');
  assert.equal(extractSessionID({ sessionID: 's2' }), 's2');
  assert.equal(extractSessionID({ properties: { info: { sessionID: 's3' } } }), 's3');
  assert.equal(extractSessionID({ type: 'app.x' }), undefined);
  assert.equal(extractSessionID(undefined), undefined);
});

// ── runtime behavior (fake ctx, real short timers) ─────────────────────────────

test('disabled config: setup no-ops — no subscription, no timer', async () => {
  const { ctx, state } = makeFakeCtx();
  const cleanup = await _setup(ctx, { enabled: false, intervalMs: 20, debug: false });
  await sleep(50);
  assert.equal(state.subscribeCalled, false);
  assert.equal(state.updateCalls.length, 0);
  assert.equal(state.logCalls.length, 0);
  cleanup();
});

test('missing ctx APIs: logged no-op, never a crash', async () => {
  const logCalls: { level: string; message: string }[] = [];
  const brokenCtx = { event: {}, session: {}, client: { app: { log: async ({ body }: never) => { logCalls.push(body); } } } };
  const cleanup = await _setup(brokenCtx as never, { enabled: true, intervalMs: 20, debug: false });
  assert.equal(logCalls.length, 1);
  assert.match(logCalls[0].message, /keepalive disabled/);
  cleanup();
});

test('busy candidate: probed, then touched with its OWN unchanged title', async () => {
  const { ctx, state, feed } = makeFakeCtx({ sessions: { s1: { status: 'busy', title: 'Long build review' } } });
  const cleanup = await _setup(ctx, { enabled: true, intervalMs: 20, debug: false });
  feed({ properties: { sessionID: 's1' } });
  await sleep(70);
  assert.ok(state.getCalls.includes('s1'), 'probe ran');
  const touch = state.updateCalls.find((c) => c.sessionID === 's1');
  assert.ok(touch, 'update ran');
  assert.equal(touch.title, 'Long build review');
  cleanup();
});

test('idle probe: no update, candidate dropped (idle locations still evict)', async () => {
  const { ctx, state, feed } = makeFakeCtx({ sessions: { s1: { status: 'idle', title: 'T' } } });
  const cleanup = await _setup(ctx, { enabled: true, intervalMs: 20, debug: false });
  feed({ properties: { sessionID: 's1' } });
  await sleep(70);
  assert.equal(state.updateCalls.length, 0, 'idle session never touched');
  const probes = state.getCalls.filter((s) => s === 's1').length;
  await sleep(70); // further sweeps must not re-probe the dropped candidate
  assert.equal(state.getCalls.filter((s) => s === 's1').length, probes);
  cleanup();
});

test('empty title: busy session probed but never sent (falsy title triggers regeneration server-side)', async () => {
  // interval 60ms → staleness threshold 120ms: the first sweep (≥60ms, age
  // <120ms even with scheduler jitter) always probes; the point under test is
  // the title gate, not retention over time (staleness covers that below).
  const { ctx, state, feed } = makeFakeCtx({ sessions: { s1: { status: 'busy', title: '' } } });
  const cleanup = await _setup(ctx, { enabled: true, intervalMs: 60, debug: false });
  feed({ properties: { sessionID: 's1' } });
  await sleep(100);
  assert.equal(state.updateCalls.length, 0, 'empty title never sent');
  assert.ok(state.getCalls.filter((s) => s === 's1').length >= 1, 'probed while busy (not dropped by the idle rule)');
  cleanup();
});

test('stale candidate: no events for >2 intervals (and no touch possible) → probing stops', async () => {
  // busy + empty title = candidate that can never self-feed via its own touch
  const { ctx, state, feed } = makeFakeCtx({ sessions: { s1: { status: 'busy', title: '' } } });
  const cleanup = await _setup(ctx, { enabled: true, intervalMs: 25, debug: false });
  feed({ properties: { sessionID: 's1' } });
  await sleep(200); // 8 sweeps; staleness (age > 50ms) reaps it early
  const probes = state.getCalls.filter((s) => s === 's1').length;
  await sleep(100);
  assert.equal(state.getCalls.filter((s) => s === 's1').length, probes, 'probing stopped after staleness');
  assert.ok(probes <= 5, `probed a bounded number of times, got ${probes}`);
  cleanup();
});

test('update rejection: logged, sweep continues to remaining candidates', async () => {
  const { ctx, state, feed } = makeFakeCtx({
    sessions: { bad: { status: 'busy', title: 'A' }, good: { status: 'busy', title: 'B' } },
    updateRejects: ['bad'],
  });
  const cleanup = await _setup(ctx, { enabled: true, intervalMs: 20, debug: false });
  feed({ properties: { sessionID: 'bad' } });
  feed({ properties: { sessionID: 'good' } });
  await sleep(70);
  assert.ok(state.updateCalls.some((c) => c.sessionID === 'good'), 'sibling still touched');
  assert.ok(state.logCalls.some((l) => l.level === 'error' && l.message.includes('bad')), 'failure logged');
  cleanup();
});

test('cleanup: aborts the event subscription and stops sweeping', async () => {
  const { ctx, state, feed } = makeFakeCtx({ sessions: { s1: { status: 'busy', title: 'T' } } });
  const cleanup = await _setup(ctx, { enabled: true, intervalMs: 20, debug: false });
  feed({ properties: { sessionID: 's1' } });
  await sleep(70);
  const probes = state.getCalls.length;
  cleanup();
  assert.equal(state.signal?.aborted, true, 'subscription aborted');
  await sleep(70);
  assert.equal(state.getCalls.length, probes, 'no probes after cleanup');
});
