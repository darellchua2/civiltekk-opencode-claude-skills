// opencode-location-keepalive-v2.ts — keep the 60-min location TTL from
// evicting actively-running sessions.
//
// OpenCode v2's LocationActivity sweeper (packages/core/src/location-activity.ts:25,62-71
// at tag v2.0.18) interrupts every RUNNING session in a location that has had
// no *durable* session event for 60 minutes, then evicts the location's cached
// services. Streaming deltas and session.tool.progress are ephemeral
// (packages/schema/src/session-event.ts:523), so a healthy agent grinding on a
// long silent tool or LLM generation looks idle and gets killed mid-run with
// reason "inactivity" — verified locally (bulk same-second "interrupted"
// outcomes matching "location services evicted" log lines to the second).
//
// Fix: every interval, for each candidate session still confirmed busy by
// probe, PATCH it with its OWN unchanged title via ctx.session.update. The
// same-title update publishes a durable session.renamed unconditionally
// (packages/core/src/session/session.ts:72-75 → bus attaches the session's
// location → location-activity.ts touch()), resetting that location's TTL.
// Idle sessions are never touched — idle locations still evict after their
// 60 quiet minutes, so upstream resource reclamation keeps working.
//
// API mapping (v2.0.18 — ctx.session.rename does NOT exist there):
//   busy probe .............. ctx.session.get({ sessionID }) → .status ∈ {busy, running}
//   touch ................... ctx.session.update({ sessionID, title }) (same title)
//   candidate feed .......... ctx.event.subscribe({ signal }) — any event with a sessionID
//   logging .................. ctx.client.app.log() (debug-gated; errors always)
//
// Coordination with opencode-auto-continue-v2 (deployed sibling): keep
// OPENCODE_AUTO_CONTINUE_STALL_MS (default 15 min) strictly BELOW
// OPENCODE_LOCATION_KEEPALIVE_INTERVAL_MS (default 30 min) so the busy-stall
// watchdog always wins the race for true silent hangs — a touch every 30 min
// resets the watchdog's lastActivityAt, and with stallMs < interval the
// abort fires before our first touch could mask it. Defaults are already
// ordered correctly.
//
// Uses a plain default export `{ id, setup }` (validated shape per the v2
// plugin loader) to avoid a runtime dependency on @opencode/plugin — same
// convention as plugins/opencode-auto-continue-v2.ts. Named exports are
// test-only helpers the loader ignores.

// ── config ─────────────────────────────────────────────────────────────────────

export interface KeepaliveConfig {
  enabled: boolean;
  intervalMs: number;
  debug: boolean;
}

export const DEFAULTS: KeepaliveConfig = {
  enabled: true,
  intervalMs: 1_800_000, // 30 min — one in-flight touch attempt before the 60-min TTL; two consecutive failures race eviction
  debug: false,
};

// Upstream location TTL default (location-activity.ts:25). Not configurable
// in v2.0.18 — no opencode.json plumbing — so asserted as a constant here.
export const TTL_MS = 3_600_000;

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

// Interval safety clamp: a touch must land with real margin before the TTL
// expires, so anything at/above 90% of the TTL falls back to the default.
export function clampInterval(ms: number, ttlMs = TTL_MS, fallback = DEFAULTS.intervalMs): number {
  return ms >= ttlMs * 0.9 ? fallback : ms;
}

export function normalizeConfig(env: Record<string, string | undefined>): KeepaliveConfig {
  return {
    enabled: envBool(env.OPENCODE_LOCATION_KEEPALIVE_ENABLED, DEFAULTS.enabled),
    intervalMs: clampInterval(envInt(env.OPENCODE_LOCATION_KEEPALIVE_INTERVAL_MS, DEFAULTS.intervalMs, 1)),
    debug: envBool(env.OPENCODE_LOCATION_KEEPALIVE_DEBUG, DEFAULTS.debug),
  };
}

// ── pure helpers ───────────────────────────────────────────────────────────────

// Probe truthy values (mirrors opencode-auto-continue-v2.ts:343-344).
export function isBusy(status: string): boolean {
  return status === 'busy' || status === 'running';
}

// Session-ID extraction mirrors auto-continue's handleEvent envelope handling.
export function extractSessionID(ev: unknown): string | undefined {
  const e = ev as { properties?: { sessionID?: string; info?: { sessionID?: string } }; sessionID?: string; info?: { sessionID?: string } } | undefined;
  const p = e?.properties ?? e ?? {};
  return p.sessionID ?? p.info?.sessionID;
}

// ── plugin ─────────────────────────────────────────────────────────────────────

const plugin = {
  id: 'opencode-location-keepalive-v2',
  async setup(ctx: any) {
    return _setup(ctx, normalizeConfig(typeof process !== 'undefined' ? (process.env as Record<string, string | undefined>) : {}));
  },
};

// Test seam: setup with an explicit config (named export — the loader only
// consumes the default export).
export async function _setup(ctx: any, cfg: KeepaliveConfig): Promise<() => void> {
  const noop = () => {};
  if (!cfg.enabled) return noop;

  const logAlways = (msg: string, level: 'info' | 'error' = 'info') => {
    try {
      Promise.resolve(
        ctx.client?.app?.log?.({
          body: {
            level,
            message: `[opencode-location-keepalive-v2] ${msg}`,
            service: 'opencode-location-keepalive-v2',
          },
        }),
      ).catch(() => {});
    } catch {
      // logging must never break keepalive
    }
  };
  const log = (msg: string) => {
    if (cfg.debug) logAlways(msg);
  };

  // Required API surface (v2.0.18): degrade to a logged no-op, never crash
  // the loader — same pattern as auto-continue's canAbort guard.
  const canTouch =
    typeof ctx?.event?.subscribe === 'function' &&
    typeof ctx?.session?.get === 'function' &&
    typeof ctx?.session?.update === 'function';
  if (!canTouch) {
    logAlways('required ctx APIs unavailable (event.subscribe / session.get / session.update) — keepalive disabled', 'error');
    return noop;
  }

  if (cfg.intervalMs !== clampInterval(cfg.intervalMs)) {
    logAlways(`interval ${cfg.intervalMs}ms leaves <10% TTL margin — clamped to ${DEFAULTS.intervalMs}ms`);
  }
  const intervalMs = clampInterval(cfg.intervalMs);

  // Candidate map: sessionID → last event seen at. Any event carrying a
  // sessionID marks candidacy (probe decides busy-ness later, so a generous
  // feed is safe). Each touch's own session.renamed event re-feeds the map —
  // a session inside a >interval silent tool stays self-sustaining.
  const candidates = new Map<string, number>();

  const controller = new AbortController();
  void (async () => {
    try {
      for await (const ev of ctx.event.subscribe({ signal: controller.signal })) {
        const sid = extractSessionID(ev);
        if (sid) candidates.set(sid, Date.now());
      }
    } catch (err) {
      // stream errors are non-fatal: existing candidates keep sweeping; but a
      // NON-self-aborted death silently ends protection for every session
      // started after it — that must be visible (mirror auto-continue:453-458)
      if (!controller.signal.aborted) {
        logAlways(`event stream died: ${err instanceof Error ? err.message : String(err)}`, 'error');
      }
    }
  })();

  const touch = async (sessionID: string): Promise<boolean> => {
    const info = await ctx.session.get({ sessionID });
    const status = String(info?.status ?? info?.data?.status ?? '');
    if (!isBusy(status)) {
      candidates.delete(sessionID); // probe verdict is authoritative
      return false;
    }
    const title = info?.title ?? info?.data?.title;
    // Empty/missing title must NOT be sent: the server handler routes falsy
    // titles to title REGENERATION (handlers/session.ts:261-266 at v2.0.18).
    if (typeof title !== 'string' || !title) return false;
    await ctx.session.update({ sessionID, title });
    candidates.set(sessionID, Date.now());
    return true;
  };

  const sweep = async (): Promise<number> => {
    const now = Date.now();
    let touched = 0;
    for (const [sid, seenAt] of Array.from(candidates.entries())) {
      if (now - seenAt > 2 * intervalMs) {
        candidates.delete(sid); // stale: no events for two sweeps — let it go idle
        continue;
      }
      try {
        if (await touch(sid)) touched++;
      } catch (err) {
        // per-session failure must never stop the sweep (e.g. a session
        // deleted between feed and probe)
        logAlways(`touch ${sid} failed: ${err instanceof Error ? err.message : String(err)}`, 'error');
      }
    }
    return touched;
  };

  let timer: ReturnType<typeof setTimeout> | undefined;
  let disposed = false;
  const schedule = (): void => {
    if (disposed) return; // cleanup during an in-flight sweep must not re-arm
    timer = setTimeout(() => {
      void sweep()
        .then((n) => {
          if (n > 0) log(`sweep: touched ${n} busy session(s)`);
        })
        .catch((err) => {
          logAlways(`sweep error: ${err instanceof Error ? err.message : String(err)}`, 'error');
        })
        .finally(schedule); // recursive: sweeps never overlap within one tick chain
    }, intervalMs);
    timer?.unref?.();
  };
  schedule();

  return () => {
    disposed = true;
    controller.abort();
    if (timer) clearTimeout(timer);
  };
}

export default plugin;
