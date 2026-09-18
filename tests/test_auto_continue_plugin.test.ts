// Unit tests for plugins/opencode-auto-continue-v2.ts — pure helpers plus the
// runtime safety properties (ESC latch, consecutive cap, user-message reset)
// exercised through a fake v2 plugin context. Run: node --test tests/test_auto_continue_plugin.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import plugin, {
  backoffDelay,
  classifyError,
  normalizeConfig,
  EXCLUDE_PATTERNS,
  MATCH_PATTERNS,
} from '../plugins/opencode-auto-continue-v2.ts';

// ── pure helpers ───────────────────────────────────────────────────────────────

test('classifyError: exclusion patterns win over match patterns', () => {
  assert.deepEqual(classifyError('MessageAbortedError: request interrupted'), { retryable: false, reason: 'messageabortederror' });
  // "bad request" is a match pattern, but the abort exclude must win
  assert.equal(classifyError('Error: operation was aborted during bad request').retryable, false);
});

test('classifyError: transient errors are retryable', () => {
  const retryableSamples = [
    'APIError: 400 bad request',
    'StreamError: SSE read timed out',
    'Error: read ECONNRESET',
    'ContextOverflowError: session too large',
    'Error: tool_use ids were found without tool_result',
  ];
  for (const sample of retryableSamples) {
    assert.equal(classifyError(sample).retryable, true, sample);
  }
});

test('classifyError: unknown errors are never retried', () => {
  assert.equal(classifyError('Error: something totally unexpected happened').retryable, false);
  assert.equal(classifyError('').retryable, false);
});

test('backoffDelay: 1s doubling capped at 8s', () => {
  assert.deepEqual([0, 1, 2, 3, 4].map((a) => backoffDelay(a)), [1000, 2000, 4000, 8000, 8000]);
});

test('backoffDelay: custom base and cap', () => {
  assert.deepEqual([0, 1, 2, 3].map((a) => backoffDelay(a, 10, 30)), [10, 20, 30, 30]);
});

test('normalizeConfig: defaults', () => {
  assert.deepEqual(normalizeConfig({}), {
    enabled: true,
    message: 'continue',
    maxConsecutive: 5,
    throttleMs: 10000,
    baseBackoffMs: 1000,
    maxBackoffMs: 8000,
    debug: false,
  });
});

test('normalizeConfig: env overrides and invalid-value fallbacks', () => {
  const cfg = normalizeConfig({
    OPENCODE_AUTO_CONTINUE_ENABLED: '0',
    OPENCODE_AUTO_CONTINUE_MESSAGE: 'resume',
    OPENCODE_AUTO_CONTINUE_MAX_CONSECUTIVE: '3',
    OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '500',
    OPENCODE_AUTO_CONTINUE_DEBUG: '1',
  });
  assert.equal(cfg.enabled, false);
  assert.equal(cfg.message, 'resume');
  assert.equal(cfg.maxConsecutive, 3);
  assert.equal(cfg.throttleMs, 500);
  assert.equal(cfg.debug, true);
  // invalid values fall back, never crash
  assert.equal(normalizeConfig({ OPENCODE_AUTO_CONTINUE_MAX_CONSECUTIVE: 'abc' }).maxConsecutive, 5);
  assert.equal(normalizeConfig({ OPENCODE_AUTO_CONTINUE_MAX_CONSECUTIVE: '-2' }).maxConsecutive, 5);
});

test('pattern lists ship the documented defaults', () => {
  assert.ok(MATCH_PATTERNS.length >= 14);
  assert.deepEqual([...EXCLUDE_PATTERNS], ['messageabortederror', 'operation was aborted']);
});

// ── runtime behavior through a fake v2 plugin context ─────────────────────────

const SID = 'ses_test_1';
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function waitFor(fn: () => boolean, what: string, timeoutMs = 2000): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (fn()) return;
    await sleep(10);
  }
  assert.fail(`timeout waiting for: ${what}`);
}

class FakeBus {
  queue: any[] = [];
  resolvers: Array<(r: IteratorResult<any>) => void> = [];
  closed = false;
  push(ev: any) {
    const r = this.resolvers.shift();
    if (r) r({ value: ev, done: false });
    else this.queue.push(ev);
  }
  async *subscribe(options: any) {
    while (!this.closed && !options?.signal?.aborted) {
      if (this.queue.length) {
        yield this.queue.shift();
      } else {
        const res = await new Promise<any>((resolve) => this.resolvers.push(resolve));
        if (res.done) return;
        yield res.value;
      }
    }
  }
  close() {
    this.closed = true;
    for (const r of this.resolvers.splice(0)) r({ done: true, value: undefined });
  }
}

async function makePlugin(
  env: Record<string, string>,
  opts: { hostile?: boolean; getStatus?: () => string; hostileEchoDelayMs?: number } = {},
) {
  const saved = { ...process.env };
  for (const k of Object.keys(env)) delete process.env[k]; // no inherited leakage
  for (const [k, v] of Object.entries(env)) process.env[k] = v;
  delete process.env.OPENCODE_AUTO_CONTINUE_DEBUG; // silence spy needs this guaranteed
  const bus = new FakeBus();
  const prompts: Array<{ sessionID: string; text: string; at: number }> = [];
  let logCalls = 0;
  let promptHook: ((event: any) => void) | undefined;
  const ctx = {
    event: { subscribe: (o: any) => bus.subscribe(o) },
    session: {
      get: async () => ({ status: opts.getStatus ? opts.getStatus() : 'idle' }),
      prompt: async (input: any) => {
        if (opts.hostileEchoDelayMs) await sleep(opts.hostileEchoDelayMs);
        // hostile fake: a real server may fire the prompt hook for our own send
        if (opts.hostile) promptHook?.({ sessionID: input.sessionID, prompt: { text: input.text } });
        prompts.push({ sessionID: input.sessionID, text: input.text, at: Date.now() });
      },
      hook: async (_name: string, fn: (event: any) => void) => {
        promptHook = fn;
        return { dispose: async () => {} };
      },
    },
    client: {
      app: {
        log: async () => {
          logCalls += 1;
        },
      },
    },
  };
  const cleanup = (await plugin.setup(ctx as any)) as (() => void) | undefined;
  const teardown = async () => {
    cleanup?.();
    bus.close();
    for (const k of Object.keys(env)) delete process.env[k];
    Object.assign(process.env, saved);
  };
  const error = (text: string, sid: string = SID) => bus.push({ type: 'session.error', properties: { sessionID: sid, error: { name: 'APIError', message: text } } });
  const idle = (sid: string = SID) => bus.push({ type: 'session.idle', properties: { sessionID: sid } });
  const interrupted = (sid: string = SID) => bus.push({ type: 'session.interrupted', properties: { sessionID: sid } });
  return {
    ctx,
    bus,
    prompts,
    logCalls: () => logCalls,
    teardown,
    error,
    idle,
    interrupted,
    userPrompt: (sid: string = SID) => promptHook?.({ sessionID: sid, prompt: { text: 'go' } }),
  };
}

test('runtime: retryable error + idle sends one continue', async () => {
  const h = await makePlugin({
    OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '10',
    OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '10',
  });
  try {
    h.error('400 bad request');
    h.idle();
    await waitFor(() => h.prompts.length === 1, 'one continue sent');
    assert.equal(h.prompts[0].sessionID, SID);
    assert.equal(h.prompts[0].text, 'continue');
  } finally {
    await h.teardown();
  }
});

test('runtime: ESC latch blocks retries until a real user message', async () => {
  const h = await makePlugin({
    OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '10',
    OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '10',
  });
  try {
    h.interrupted();
    h.error('SSE read timed out'); // matches, but ESC-latched
    h.idle();
    await sleep(120);
    assert.equal(h.prompts.length, 0, 'ESC latch must suppress the retry');
    h.userPrompt(); // lifts the latch
    h.error('400 bad request');
    h.idle();
    await waitFor(() => h.prompts.length === 1, 'retry after latch cleared');
  } finally {
    await h.teardown();
  }
});

test('runtime: consecutive cap stops sends; user message resets the counter', async () => {
  const h = await makePlugin({
    OPENCODE_AUTO_CONTINUE_MAX_CONSECUTIVE: '2',
    OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '10',
    OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '10',
  });
  try {
    h.error('400 bad request');
    h.idle();
    await waitFor(() => h.prompts.length === 1, 'attempt 1');
    h.error('read ECONNRESET');
    h.idle();
    await waitFor(() => h.prompts.length === 2, 'attempt 2');
    h.error('no data received');
    h.idle();
    await sleep(120);
    assert.equal(h.prompts.length, 2, 'cap must block the third send');
    h.userPrompt(); // reset
    h.error('idle timeout');
    h.idle();
    await waitFor(() => h.prompts.length === 3, 'sends resume after user message');
  } finally {
    await h.teardown();
  }
});

test('runtime: non-retryable errors never send', async () => {
  const h = await makePlugin({
    OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '10',
    OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '10',
  });
  try {
    h.error('Error: something totally unexpected');
    h.idle();
    await sleep(120);
    assert.equal(h.prompts.length, 0);
  } finally {
    await h.teardown();
  }
});

test('runtime: silent in normal operation (zero log calls without debug)', async () => {
  const h = await makePlugin({
    OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '10',
    OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '10',
  });
  try {
    assert.equal(process.env.OPENCODE_AUTO_CONTINUE_DEBUG, undefined, 'debug must be unset for this test');
    h.error('400 bad request');
    h.idle();
    await waitFor(() => h.prompts.length === 1, 'send');
    await sleep(30);
    assert.equal(h.logCalls(), 0, 'ctx.client.app.log must not be called when debug is unset');
  } finally {
    await h.teardown();
  }
});

test('runtime: own sends do not defeat the consecutive cap (hostile hook echo)', async () => {
  const h = await makePlugin(
    {
      OPENCODE_AUTO_CONTINUE_MAX_CONSECUTIVE: '2',
      OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '10',
      OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '10',
    },
    { hostile: true },
  );
  try {
    h.error('400 bad request');
    h.idle();
    await waitFor(() => h.prompts.length === 1, 'attempt 1');
    h.error('read ECONNRESET');
    h.idle();
    await waitFor(() => h.prompts.length === 2, 'attempt 2');
    h.error('no data received');
    h.idle();
    await sleep(120);
    assert.equal(h.prompts.length, 2, 'cap must hold even when our own sends echo the prompt hook');
  } finally {
    await h.teardown();
  }
});

test('runtime: throttle delays the second consecutive send beyond the window', async () => {
  const h = await makePlugin({
    OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '60',
    OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '1',
    OPENCODE_AUTO_CONTINUE_MAX_BACKOFF_MS: '8',
  });
  try {
    h.error('400 bad request');
    h.idle();
    await waitFor(() => h.prompts.length === 1, 'first send');
    h.error('read ECONNRESET');
    h.idle();
    await sleep(20);
    assert.equal(h.prompts.length, 1, 'second send must not land inside the throttle window');
    await waitFor(() => h.prompts.length === 2, 'second send after the window');
    const delta = h.prompts[1].at - h.prompts[0].at;
    assert.ok(delta >= 45, `send delta ${delta}ms should honor the 60ms throttle (>= ~45ms)`);
  } finally {
    await h.teardown();
  }
});

test('runtime: busy session re-arms and sends once idle again', async () => {
  let busy = true;
  const h = await makePlugin(
    {
      OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '10',
      OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '10',
    },
    { getStatus: () => (busy ? 'busy' : 'idle') },
  );
  try {
    h.error('400 bad request');
    h.idle();
    await sleep(80);
    assert.equal(h.prompts.length, 0, 'must not send while the session is busy');
    busy = false;
    await waitFor(() => h.prompts.length === 1, 'send after the session goes idle again');
  } finally {
    await h.teardown();
  }
});

test('runtime: session deletion clears pending retries (and the armed timer)', async () => {
  const h = await makePlugin({
    OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '500', // long enough to observe the armed timer
    OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '10',
  });
  try {
    h.error('400 bad request');
    h.idle();
    await sleep(40); // the retry timer is now armed ~500ms out
    h.bus.push({ type: 'session.deleted', properties: { sessionID: SID } });
    await sleep(120);
    assert.equal(h.prompts.length, 0, 'no retry may fire for a deleted session (timer must be cleared)');
  } finally {
    await h.teardown();
  }
});

test('runtime: own-send guard does not swallow a real user message in another session', async () => {
  const SID_B = 'ses_test_B';
  const h = await makePlugin(
    {
      OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS: '10',
      OPENCODE_AUTO_CONTINUE_THROTTLE_MS: '10',
    },
    { hostile: true, hostileEchoDelayMs: 40 }, // session A's send stays in flight ~40ms
  );
  try {
    h.interrupted(SID_B); // latch session B
    h.error('400 bad request'); // session A arms and schedules a send
    h.idle();
    await sleep(10); // A's prompt is now in flight (guard active for A only)
    h.userPrompt(SID_B); // a REAL user message lands in B mid-flight
    await waitFor(() => h.prompts.some((p) => p.sessionID === SID), 'A send completes');
    // B's user message must have lifted B's latch despite A's in-flight send
    h.error('read ECONNRESET', SID_B);
    h.idle(SID_B);
    await waitFor(() => h.prompts.some((p) => p.sessionID === SID_B), 'B sends after its real user message');
  } finally {
    await h.teardown();
  }
});
