// opencode-auto-continue-v2.ts — thin OpenCode v2 plugin: idle-boundary auto-continue + busy-stall watchdog.
//
// Two recovery paths for long-running tasks that would otherwise die midway:
//
// 1. Error-boundary: listens for session errors classified as transient (bad
//    request, SSE timeouts, connection resets, context overflow, tool-protocol
//    failures) and, once the session goes idle, sends a "continue" prompt with
//    exponential backoff.
// 2. Busy-stall watchdog: silent hangs that never emit session.error (upstream
//    #46310/#24900) are caught by a sweep — event silence for
//    OPENCODE_AUTO_CONTINUE_STALL_MS while the session is still busy aborts the
//    run and hands recovery to path 1's sender.
//
// v2 port of the v1 plugins' core idea (v1 packages depend on @opencode-ai/plugin
// and do not load on v2). API mapping:
//   error-pattern retry loop ... ctx.event.subscribe("session.error") + idle send
//   ESC safety latch ........... session.interrupted event + ctx.session.hook("prompt") reset
//   send ....................... ctx.session.prompt({ sessionID, text })
//   logging .................... ctx.client.app.log() (debug-gated; zero console.log)
//
// Pattern list adapted as data from MIT-licensed developing-today/opencode-auto-continue.
// Mte90/opencode-auto-resume is GPL-3.0 — design reference only, no code copied.
//
// Busy-stall watchdog (upstream #46310 / #24900): some hangs NEVER emit
// session.error — the runner just freezes busy on a silent event stream, so the
// error classifier above cannot see them. A sweep timer finds tracked sessions
// whose events went quiet for OPENCODE_AUTO_CONTINUE_STALL_MS while the session
// is still busy/running, aborts them, and hands recovery to the idle-boundary
// sender below. Guards: ESC latch, consecutive cap, fresh-activity re-check
// after every await, and a probe-confirmed busy status — a session that is
// merely idle or finishing is never aborted.
//   ponytail: stall detection is time-only — a silent 15-minute bash build is
//   indistinguishable from a hang; in-flight tool-type tracking is the upgrade
//   path if that bites.
//
// Deliberately OUT OF SCOPE (upgrade path if real bugs demand them):
//   - tool-call loop fingerprinting — deferred
//   - tool-call-as-raw-text scanning — deferred
//
// Uses a plain default export `{ id, setup }` (validated shape per the v2
// plugin loader) to avoid a runtime dependency on @opencode/plugin — same
// convention as plugins/opencode-vibeguard-v2.ts. Named exports are test-only helpers the
// loader ignores.

// ── config ─────────────────────────────────────────────────────────────────────

export interface AutoContinueConfig {
  enabled: boolean;
  message: string;
  maxConsecutive: number;
  throttleMs: number;
  baseBackoffMs: number;
  maxBackoffMs: number;
  stallMs: number;
  sweepMs: number;
  debug: boolean;
}

const DEFAULTS: AutoContinueConfig = {
  enabled: true,
  message: 'continue',
  maxConsecutive: 5,
  throttleMs: 10_000,
  baseBackoffMs: 1_000,
  maxBackoffMs: 8_000,
  stallMs: 900_000, // busy-stall watchdog: 15 min of event silence while busy; 0 disables
  sweepMs: 30_000,
  debug: false,
};

function envBool(value: string | undefined, fallback: boolean): boolean {
  if (value === undefined || value.trim() === '') return fallback;
  const v = value.trim().toLowerCase();
  if (['1', 'true', 'yes', 'on'].includes(v)) return true;
  if (['0', 'false', 'no', 'off'].includes(v)) return false;
  return fallback;
}

function envInt(value: string | undefined, fallback: number, min = 0): number {
  const raw = String(value ?? '').trim();
  if (raw === '') return fallback;
  const n = Number(raw);
  if (!Number.isFinite(n) || n < min) return fallback;
  return Math.floor(n);
}

export function normalizeConfig(env: Record<string, string | undefined>): AutoContinueConfig {
  return {
    enabled: envBool(env.OPENCODE_AUTO_CONTINUE_ENABLED, DEFAULTS.enabled),
    message: env.OPENCODE_AUTO_CONTINUE_MESSAGE?.trim() || DEFAULTS.message,
    maxConsecutive: envInt(env.OPENCODE_AUTO_CONTINUE_MAX_CONSECUTIVE, DEFAULTS.maxConsecutive, 1),
    throttleMs: envInt(env.OPENCODE_AUTO_CONTINUE_THROTTLE_MS, DEFAULTS.throttleMs, 0),
    baseBackoffMs: envInt(env.OPENCODE_AUTO_CONTINUE_BASE_BACKOFF_MS, DEFAULTS.baseBackoffMs, 1),
    maxBackoffMs: envInt(env.OPENCODE_AUTO_CONTINUE_MAX_BACKOFF_MS, DEFAULTS.maxBackoffMs, 1),
    stallMs: envInt(env.OPENCODE_AUTO_CONTINUE_STALL_MS, DEFAULTS.stallMs, 0),
    sweepMs: envInt(env.OPENCODE_AUTO_CONTINUE_SWEEP_MS, DEFAULTS.sweepMs, 1),
    debug: envBool(env.OPENCODE_AUTO_CONTINUE_DEBUG, DEFAULTS.debug),
  };
}

// ── error classification ───────────────────────────────────────────────────────

// Matched as case-insensitive substrings against `"<name>: <message>"`.
// Adapted as data from developing-today/opencode-auto-continue (MIT).
export const MATCH_PATTERNS: readonly string[] = [
  'bad request',
  'reasoning_opaque',
  'sse read timed out',
  'contextoverflowerror',
  'too large to compact',
  'json parsing failed',
  'invalid input for tool',
  'tried to call unavailable tool',
  'tool_use ids were found without tool_result',
  'econnrefused',
  'econnreset',
  'idle timeout',
  'no data received',
  'expected string, received undefined',
];

// Checked FIRST — user-initiated aborts are never retried, even when a match
// pattern would also hit.
export const EXCLUDE_PATTERNS: readonly string[] = [
  'messageabortederror',
  'operation was aborted',
];

export interface ErrorClassification {
  retryable: boolean;
  reason: string;
}

export function classifyError(raw: string): ErrorClassification {
  const msg = String(raw ?? '').toLowerCase();
  for (const p of EXCLUDE_PATTERNS) {
    if (msg.includes(p)) return { retryable: false, reason: p };
  }
  for (const p of MATCH_PATTERNS) {
    if (msg.includes(p)) return { retryable: true, reason: p };
  }
  return { retryable: false, reason: 'no-match' };
}

// attempt 0 → base, doubling, capped. 1s → 2s → 4s → 8s → 8s with defaults.
export function backoffDelay(attempt: number, baseMs = DEFAULTS.baseBackoffMs, maxMs = DEFAULTS.maxBackoffMs): number {
  const delay = baseMs * 2 ** Math.max(0, attempt);
  return Math.min(delay, maxMs);
}

// ── plugin ─────────────────────────────────────────────────────────────────────

interface SessionState {
  pending?: { reason: string; at: number };
  attempts: number;
  lastSentAt: number;
  esc: boolean;
  timer?: ReturnType<typeof setTimeout>;
  updatedAt: number;
  lastActivityAt: number;
}

const MAX_TRACKED_SESSIONS = 200;

const plugin = {
  id: 'opencode-auto-continue-v2',
  async setup(ctx: any) {
    const cfg = normalizeConfig(typeof process !== 'undefined' ? (process.env as Record<string, string | undefined>) : {});

    const log = (msg: string) => {
      if (!cfg.debug) return;
      logAlways(msg, 'info');
    };
    // unconditional logging for abnormal events only (never debug-gated), so a
    // broken event stream is visible even in silent operation
    const logAlways = (msg: string, level: 'info' | 'error' = 'info') => {
      try {
        Promise.resolve(
          ctx.client?.app?.log?.({
            body: {
              level,
              message: `[opencode-auto-continue-v2] ${msg}`,
              service: 'opencode-auto-continue-v2',
            },
          }),
        ).catch(() => {
          // logging must never break recovery
        });
      } catch {
        // ditto for synchronous throws
      }
    };

    if (!cfg.enabled) {
      log('disabled by config — no-op');
      return;
    }

    const state = new Map<string, SessionState>();

    const clearTimer = (st: SessionState) => {
      if (st.timer) {
        clearTimeout(st.timer);
        st.timer = undefined;
      }
    };

    const ensure = (sessionID: string): SessionState => {
      let st = state.get(sessionID);
      if (!st) {
        st = { attempts: 0, lastSentAt: 0, esc: false, timer: undefined, updatedAt: Date.now(), lastActivityAt: Date.now() };
        state.set(sessionID, st);
        if (state.size > MAX_TRACKED_SESSIONS) {
          // evict the least-recently-updated session to bound memory
          let oldestKey: string | undefined;
          let oldestAt = Infinity;
          for (const [key, val] of state) {
            if (val.updatedAt < oldestAt) {
              oldestAt = val.updatedAt;
              oldestKey = key;
            }
          }
          if (oldestKey && oldestKey !== sessionID) {
            const oldest = state.get(oldestKey);
            if (oldest) clearTimer(oldest);
            state.delete(oldestKey);
          }
        }
      }
      st.updatedAt = Date.now();
      return st;
    };

    // depth guard for plugin-initiated sends currently in flight, scoped PER
    // SESSION: the prompt hook ignores echoes of our own sends so the cap and
    // ESC latch can only be reset by a real user message — and a send in flight
    // for session A must never swallow a real user message in session B.
    // Cleared on NEXT TICK because a prompt hook may fire after the awaited
    // prompt resolves.
    const ownSendSessions = new Set<string>();

    // Sessions we aborted ourselves: the runner echoes the kill back as
    // `session.interrupted` and often a MessageAbortedError — both must NOT
    // trip the ESC latch or clear our recovery pending. Consumed by the first
    // post-abort event; a time-boxed fallback deletion covers the no-echo case.
    const ABORT_ECHO_WINDOW_MS = 2000;
    const ownAbortSessions = new Set<string>();

    const markOwnAbort = (sessionID: string) => {
      ownAbortSessions.add(sessionID);
      const t = setTimeout(() => ownAbortSessions.delete(sessionID), ABORT_ECHO_WINDOW_MS);
      t.unref?.(); // never hold the process open for a cleanup timer
    };

    const send = async (sessionID: string): Promise<void> => {
      const st = state.get(sessionID);
      if (!st?.pending) return;
      if (st.esc || st.attempts >= cfg.maxConsecutive) {
        log(`session ${sessionID}: ${st.esc ? 'ESC-latched' : 'consecutive cap reached'} — dropping pending retry`);
        st.pending = undefined;
        return;
      }
      // race guard: if the session left idle before the timer fired, re-arm
      try {
        const info = await ctx.session?.get?.({ sessionID });
        const status = info?.status ?? info?.data?.status;
        if (typeof status === 'string' && status !== 'idle') {
          log(`session ${sessionID}: no longer idle (${status}) — re-arming`);
          const wait = backoffDelay(st.attempts, cfg.baseBackoffMs, cfg.maxBackoffMs);
          clearTimer(st);
          st.timer = setTimeout(() => void send(sessionID), wait);
          return;
        }
      } catch {
        // status probe unavailable — proceed (prompt to an active session is harmless)
      }
      // re-validate after the await: ESC latch, user message, or a cap change
      // may have landed while the status probe was in flight
      if (!st.pending || st.esc || st.attempts >= cfg.maxConsecutive) return;
      const { reason } = st.pending;
      st.pending = undefined;
      st.attempts += 1;
      st.lastSentAt = Date.now();
      ownSendSessions.add(sessionID);
      try {
        await ctx.session?.prompt?.({ sessionID, text: cfg.message });
        log(`sent ${JSON.stringify(cfg.message)} to ${sessionID} (attempt ${st.attempts}/${cfg.maxConsecutive}, reason=${reason})`);
      } catch (err) {
        log(`prompt send failed for ${sessionID}: ${err instanceof Error ? err.message : String(err)}`);
      } finally {
        setImmediate(() => {
          ownSendSessions.delete(sessionID);
        });
      }
    };

    const onIdle = (sessionID: string) => {
      const st = ensure(sessionID);
      clearTimer(st);
      if (!st.pending || st.esc) return;
      if (st.attempts >= cfg.maxConsecutive) {
        log(`session ${sessionID}: cap ${cfg.maxConsecutive} reached — giving up`);
        st.pending = undefined;
        return;
      }
      const backoff = backoffDelay(st.attempts, cfg.baseBackoffMs, cfg.maxBackoffMs);
      const cooldownRemaining = st.lastSentAt + cfg.throttleMs - Date.now();
      const wait = Math.max(backoff, cooldownRemaining, 0);
      log(`session ${sessionID}: idle with pending retry (reason=${st.pending.reason}) — sending in ${wait}ms`);
      st.timer = setTimeout(() => void send(sessionID), wait);
    };

    // ── busy-stall watchdog ──────────────────────────────────────────────────────
    // #46310/#24900-style hangs keep the session busy with a silent event
    // stream — no session.error ever fires, so the idle-boundary path above
    // never triggers. Abort such sessions and hand recovery to onIdle/send.
    const canAbort = typeof ctx.session?.abort === 'function';
    if (cfg.stallMs > 0 && !canAbort) {
      logAlways('session.abort API unavailable — busy-stall watchdog disabled', 'error');
    }
    let sweepTimer: ReturnType<typeof setTimeout> | undefined;

    const sweep = async (): Promise<void> => {
      const now = Date.now();
      const candidates: string[] = [];
      for (const [sid, st] of state) {
        if (st.esc || st.pending || st.timer) continue;
        if (ownSendSessions.has(sid) || ownAbortSessions.has(sid)) continue;
        if (st.attempts >= cfg.maxConsecutive) continue;
        if (now - st.lastActivityAt >= cfg.stallMs) candidates.push(sid);
      }
      for (const sid of candidates) {
        const st = state.get(sid);
        if (!st || st.esc || st.pending || st.attempts >= cfg.maxConsecutive) continue;
        if (Date.now() - st.lastActivityAt < cfg.stallMs) continue; // activity landed meanwhile
        let status = '';
        try {
          const info = await ctx.session?.get?.({ sessionID: sid });
          status = String(info?.status ?? info?.data?.status ?? '');
        } catch {
          continue; // probe unavailable — never abort blind
        }
        if (status !== 'busy' && status !== 'running') continue;
        if (st.esc || st.pending || st.timer) continue; // re-validate after the await
        log(`session ${sid}: busy-stall (${Math.round((Date.now() - st.lastActivityAt) / 1000)}s silent while ${status}) — aborting for recovery`);
        markOwnAbort(sid);
        try {
          await ctx.session?.abort?.({ sessionID: sid });
        } catch (err) {
          ownAbortSessions.delete(sid);
          log(`session ${sid}: stall abort failed: ${err instanceof Error ? err.message : String(err)}`);
          continue;
        }
        const post = state.get(sid);
        if (!post || post.esc) continue;
        if (post.attempts >= cfg.maxConsecutive) {
          log(`session ${sid}: cap ${cfg.maxConsecutive} reached — stall recovery dropped`);
          continue;
        }
        // hand off to the idle-boundary sender; send() re-validates the status
        post.pending = { reason: 'busy-stall', at: Date.now() };
        onIdle(sid);
      }
    };

    const scheduleSweep = (): void => {
      if (cfg.stallMs <= 0 || !canAbort) return;
      sweepTimer = setTimeout(() => {
        sweep().catch((err) => {
          logAlways(`watchdog sweep error: ${err instanceof Error ? err.message : String(err)}`, 'error');
        });
        scheduleSweep(); // recursive: sweeps never overlap
      }, cfg.sweepMs);
      sweepTimer.unref?.();
    };
    scheduleSweep();

    const extractErrorText = (p: any): string => {
      const e = p?.error ?? p?.message ?? p;
      if (typeof e === 'string') return e;
      if (e?.name || e?.message) return `${e.name ?? 'Error'}: ${e.message ?? ''}`;
      try {
        return JSON.stringify(p);
      } catch {
        return String(p);
      }
    };

    const handleEvent = (ev: any) => {
      const type = String(ev?.type ?? '');
      const p = ev?.properties ?? ev ?? {};
      const sessionID: string | undefined = p.sessionID ?? p.info?.sessionID;
      if (!sessionID) return;

      // every event is activity — the watchdog judges staleness from this
      ensure(sessionID).lastActivityAt = Date.now();

      if (type === 'session.error') {
        if (ownAbortSessions.has(sessionID)) {
          ownAbortSessions.delete(sessionID);
          log(`session ${sessionID}: ignoring own-abort error echo`);
          return;
        }
        const st = ensure(sessionID);
        const cls = classifyError(extractErrorText(p));
        log(`session ${sessionID}: error classified retryable=${cls.retryable} (${cls.reason})`);
        if (st.esc) {
          st.pending = undefined;
        } else if (cls.retryable) {
          st.pending = { reason: cls.reason, at: Date.now() };
        } else {
          st.pending = undefined;
        }
        return;
      }
      if (type === 'session.interrupted') {
        if (ownAbortSessions.has(sessionID)) {
          ownAbortSessions.delete(sessionID);
          log(`session ${sessionID}: ignoring own-abort interrupted echo`);
          return;
        }
        const st = ensure(sessionID);
        log(`session ${sessionID}: interrupted — ESC latch on`);
        st.esc = true;
        st.pending = undefined;
        clearTimer(st);
        return;
      }
      if (type === 'session.idle' || (type === 'session.status' && (p.status === 'idle' || p.state === 'idle'))) {
        onIdle(sessionID);
        return;
      }
      if (type === 'session.deleted' || type === 'session.removed') {
        const st = state.get(sessionID);
        if (st) {
          clearTimer(st);
          state.delete(sessionID);
        }
        return;
      }
    };

    const controller = new AbortController();
    const pump = async () => {
      try {
        for await (const ev of ctx.event.subscribe({ signal: controller.signal })) {
          try {
            handleEvent(ev);
          } catch (err) {
            log(`event handler error: ${err instanceof Error ? err.message : String(err)}`);
          }
        }
      } catch (err) {
        if (!controller.signal.aborted) {
          // abnormal: the self-healing loop itself died — say so unconditionally
          logAlways(`event stream error: ${err instanceof Error ? err.message : String(err)}`, 'error');
        }
      }
    };
    void pump();

    // A real user message resets the consecutive counter and lifts the ESC latch.
    // Echoes of the plugin's own sends are ignored (ownSends guard) so the cap
    // and latch cannot be defeated by the recovery prompts themselves.
    let disposeHook: (() => void) | undefined;
    try {
      const registration = await ctx.session.hook('prompt', (event: any) => {
        const sid = event?.sessionID;
        if (!sid) return;
        if (ownSendSessions.has(sid)) {
          log(`session ${sid}: ignoring own-send echo`);
          return;
        }
        const st = state.get(sid);
        if (st) {
          st.attempts = 0;
          st.esc = false;
          st.pending = undefined;
          log(`session ${sid}: user prompt — counter reset, ESC latch cleared`);
        }
      });
      disposeHook = () => {
        try {
          Promise.resolve(registration?.dispose?.()).catch(() => {
            // already disposed
          });
        } catch {
          // already disposed
        }
      };
    } catch (err) {
      log(`prompt hook unavailable: ${err instanceof Error ? err.message : String(err)}`);
    }

    log(`loaded (enabled, max=${cfg.maxConsecutive}, throttle=${cfg.throttleMs}ms, backoff=${cfg.baseBackoffMs}-${cfg.maxBackoffMs}ms${cfg.stallMs > 0 ? `, watchdog=${cfg.stallMs}ms/sweep=${cfg.sweepMs}ms` : ', watchdog=off'})`);

    return () => {
      controller.abort();
      if (sweepTimer) clearTimeout(sweepTimer);
      for (const st of state.values()) clearTimer(st);
      ownSendSessions.clear();
      ownAbortSessions.clear();
      disposeHook?.();
    };
  },
};

export default plugin;
