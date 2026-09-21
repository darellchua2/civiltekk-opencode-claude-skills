// opencode-vibeguard-v2.ts — OpenCode v2 local port of opencode-vibeguard (secret masking).
//
// Ported from opencode-vibeguard@0.1.0 (MIT, https://github.com/inkdust2021/opencode-vibeguard)
// because V1 plugin implementations do not run on OpenCode v2. Engine, pattern,
// session, deep-walk and restore logic are ported essentially verbatim from the
// upstream src/{config,engine,session,deep,restore,patterns}.js modules; only the
// plugin entrypoint is rewritten for the v2 API:
//
//   V1 "experimental.chat.messages.transform"  ->  ctx.session.hook("context"|"generate")
//   V1 "tool.execute.before"                   ->  ctx.tool.hook("execute.before")
//
// Behavior contract (unchanged from upstream):
// - Outbound model traffic (system + messages incl. tool call/output parts) has
//   secret values replaced with `__VG_<CATEGORY>_<hash12>__` placeholders.
// - Tool executions receive the real values back (placeholders restored in
//   tool input, deep-walked).
// - Config lookup order: $OPENCODE_VIBEGUARD_CONFIG (relative to project),
//   <project>/vibeguard.config.json, <project>/.opencode/vibeguard.config.json,
//   ~/.config/opencode/vibeguard.config.json — FIRST match wins (no merge).
// - Missing config / enabled:false => no-op (fail-open; the AGENTS.md Secret
//   Hygiene rules are the compensating behavioral layer).
// - OPENCODE_VIBEGUARD_DEBUG=1 (or "debug": true) logs load + replace counts.
//
// Uses a plain default export `{ id, setup }` (validated shape per the v2
// plugin loader) to avoid a runtime dependency on @opencode/plugin.

import { createHmac, randomBytes } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// ── config ─────────────────────────────────────────────────────────────────────

function parseDurationMs(input: unknown): number {
  const raw = String(input ?? '').trim();
  if (!raw) return 60 * 60 * 1000;
  const m = raw.match(/^(\d+(?:\.\d+)?)(ms|s|m|h|d)$/);
  if (!m) return 60 * 60 * 1000;
  const value = Number(m[1]);
  if (!Number.isFinite(value) || value < 0) return 60 * 60 * 1000;
  const unit = m[2];
  if (unit === 'ms') return value;
  if (unit === 's') return value * 1000;
  if (unit === 'm') return value * 60 * 1000;
  if (unit === 'h') return value * 60 * 60 * 1000;
  if (unit === 'd') return value * 24 * 60 * 60 * 1000;
  return 60 * 60 * 1000;
}

interface VGConfig {
  enabled: boolean;
  debug: boolean;
  prefix: string;
  ttlMs: number;
  maxMappings: number;
  patterns: any;
  loadedFrom: string;
}

function normalizeConfig(raw: any): Omit<VGConfig, 'loadedFrom'> {
  const cfg = raw && typeof raw === 'object' ? raw : {};
  const session = cfg.session && typeof cfg.session === 'object' ? cfg.session : {};
  const maxMappings = Number(session.max_mappings);
  return {
    enabled: Boolean(cfg.enabled),
    debug: Boolean(cfg.debug),
    prefix: typeof cfg.placeholder_prefix === 'string' && cfg.placeholder_prefix ? cfg.placeholder_prefix : '__VG_',
    ttlMs: parseDurationMs(session.ttl ?? '1h'),
    maxMappings: Number.isFinite(maxMappings) && maxMappings > 0 ? maxMappings : 100000,
    patterns: cfg.patterns && typeof cfg.patterns === 'object' ? cfg.patterns : {},
  };
}

function loadConfig(directory: string): VGConfig {
  const dir = String(directory ?? process.cwd());
  const candidates = [
    process.env.OPENCODE_VIBEGUARD_CONFIG ? path.resolve(dir, process.env.OPENCODE_VIBEGUARD_CONFIG) : null,
    path.join(dir, 'vibeguard.config.json'),
    path.join(dir, '.opencode', 'vibeguard.config.json'),
    path.join(os.homedir(), '.config', 'opencode', 'vibeguard.config.json'),
  ];
  for (const file of candidates) {
    if (!file || !existsSync(file)) continue;
    try {
      const cfg = normalizeConfig(JSON.parse(readFileSync(file, 'utf8')));
      return { ...cfg, loadedFrom: file };
    } catch (_) {
      // unparseable — try next candidate
    }
  }
  return { ...normalizeConfig({ enabled: false }), loadedFrom: '' };
}

// ── patterns ───────────────────────────────────────────────────────────────────

function sanitizeCategory(input: unknown): string {
  const raw = String(input ?? '').trim();
  if (!raw) return 'TEXT';
  const safe = raw.toUpperCase().replace(/[^A-Z0-9_]/g, '_').replace(/_+/g, '_');
  return safe || 'TEXT';
}

function peelInlineFlags(pattern: string, flags: string): { pattern: string; flags: string } {
  let p = String(pattern ?? '');
  let f = String(flags ?? '');
  for (;;) {
    if (p.startsWith('(?i)')) {
      p = p.slice(4);
      if (!f.includes('i')) f += 'i';
      continue;
    }
    if (p.startsWith('(?m)')) {
      p = p.slice(4);
      if (!f.includes('m')) f += 'm';
      continue;
    }
    break;
  }
  return { pattern: p, flags: f };
}

const BUILTIN = new Map<string, { pattern: string; flags: string; category: string }>([
  ['email', { pattern: String.raw`[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}`, flags: 'i', category: 'EMAIL' }],
  ['china_phone', { pattern: String.raw`(?<!\d)1[3-9]\d{9}(?!\d)`, flags: '', category: 'CHINA_PHONE' }],
  ['china_id', { pattern: String.raw`(?<!\d)\d{17}[\dXx](?!\d)`, flags: '', category: 'CHINA_ID' }],
  ['uuid', { pattern: String.raw`[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}`, flags: '', category: 'UUID' }],
  ['ipv4', { pattern: String.raw`(?:\d{1,3}\.){3}\d{1,3}`, flags: '', category: 'IPV4' }],
  ['mac', { pattern: String.raw`(?:[0-9a-f]{2}:){5}[0-9a-f]{2}`, flags: 'i', category: 'MAC' }],
]);

interface PatternSet {
  keywords: { value: string; category: string }[];
  regex: { pattern: string; flags: string; category: string }[];
  exclude: Set<string>;
}

function buildPatternSet(patterns: any): PatternSet {
  const raw = patterns && typeof patterns === 'object' ? patterns : {};
  const keywords = (Array.isArray(raw.keywords) ? raw.keywords : [])
    .map((x: any) => {
      if (!x || typeof x !== 'object') return null;
      const value = String(x.value ?? '').trim();
      if (!value) return null;
      return { value, category: sanitizeCategory(x.category) };
    })
    .filter(Boolean) as { value: string; category: string }[];

  const regex: { pattern: string; flags: string; category: string }[] = [];
  for (const x of Array.isArray(raw.regex) ? raw.regex : []) {
    if (!x || typeof x !== 'object') continue;
    const pattern = String(x.pattern ?? '').trim();
    if (!pattern) continue;
    const peeled = peelInlineFlags(pattern, typeof x.flags === 'string' ? x.flags : '');
    regex.push({ pattern: peeled.pattern, flags: peeled.flags, category: sanitizeCategory(x.category) });
  }
  for (const name of Array.isArray(raw.builtin) ? raw.builtin : []) {
    const rule = BUILTIN.get(String(name ?? '').trim());
    if (rule) regex.push({ ...rule });
  }
  return { keywords, regex, exclude: new Set((Array.isArray(raw.exclude) ? raw.exclude : []).map((x: any) => String(x ?? ''))) };
}

// ── placeholder session ────────────────────────────────────────────────────────

class PlaceholderSession {
  prefix: string;
  ttlMs: number;
  maxMappings: number;
  secret: Uint8Array;
  forward = new Map<string, string>();
  reverse = new Map<string, string>();
  created = new Map<string, number>();

  constructor(options: { prefix?: string; ttlMs?: number; maxMappings?: number; secret?: Uint8Array }) {
    this.prefix = String(options.prefix ?? '__VG_');
    this.ttlMs = Number.isFinite(options.ttlMs as number) ? Number(options.ttlMs) : 60 * 60 * 1000;
    this.maxMappings = Number.isFinite(options.maxMappings as number) ? Number(options.maxMappings) : 100000;
    this.secret = options.secret ? Uint8Array.from(options.secret) : randomBytes(32);
  }

  cleanup(now = Date.now()) {
    if (!Number.isFinite(this.ttlMs) || this.ttlMs <= 0) return;
    for (const [placeholder, createdAt] of this.created.entries()) {
      if (now - createdAt <= this.ttlMs) continue;
      const original = this.forward.get(placeholder);
      this.forward.delete(placeholder);
      this.created.delete(placeholder);
      if (original !== undefined) this.reverse.delete(original);
    }
  }

  evictOldest() {
    let oldestPlaceholder = '';
    let oldestTime = Infinity;
    for (const [placeholder, createdAt] of this.created.entries()) {
      if (createdAt >= oldestTime) continue;
      oldestTime = createdAt;
      oldestPlaceholder = placeholder;
    }
    if (!oldestPlaceholder) return;
    const original = this.forward.get(oldestPlaceholder);
    this.forward.delete(oldestPlaceholder);
    this.created.delete(oldestPlaceholder);
    if (original !== undefined) this.reverse.delete(original);
  }

  lookup(placeholder: string): string | undefined {
    return this.forward.get(placeholder);
  }

  lookupReverse(original: string): string | undefined {
    return this.reverse.get(original);
  }

  generatePlaceholder(original: string, category: string): string {
    const cat = sanitizeCategory(category);
    const h = createHmac('sha256', this.secret as any);
    h.update(String(original));
    const hash12 = Buffer.from(h.digest()).toString('hex').slice(0, 12);
    return `${this.prefix}${cat}_${hash12}__`;
  }

  getOrCreatePlaceholder(original: string, category: string): string {
    const existing = this.lookupReverse(original);
    if (existing) return existing;
    const now = Date.now();
    this.cleanup(now);
    if (Number.isFinite(this.maxMappings) && this.maxMappings > 0) {
      while (this.forward.size >= this.maxMappings) this.evictOldest();
    }
    const base = this.generatePlaceholder(original, category);
    const current = this.forward.get(base);
    if (current === undefined) {
      this.forward.set(base, original);
      this.reverse.set(original, base);
      this.created.set(base, now);
      return base;
    }
    if (current === original) {
      this.reverse.set(original, base);
      this.created.set(base, now);
      return base;
    }
    // rare hash12 collision — disambiguate with a numeric suffix
    const withoutSuffix = base.slice(0, -2);
    for (let i = 2; ; i++) {
      const candidate = `${withoutSuffix}_${i}__`;
      const prev = this.forward.get(candidate);
      if (prev === undefined) {
        this.forward.set(candidate, original);
        this.reverse.set(original, candidate);
        this.created.set(candidate, now);
        return candidate;
      }
      if (prev === original) {
        this.reverse.set(original, candidate);
        this.created.set(candidate, now);
        return candidate;
      }
    }
  }
}

function getPlaceholderRegex(prefix: string): RegExp {
  const escaped = String(prefix).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`${escaped}[A-Za-z0-9_]+_[a-f0-9A-F]{12}(?:_\\d+)?__`, 'g');
}

// ── redact / restore engines ───────────────────────────────────────────────────

function subtractCovered(start: number, end: number, covered: { start: number; end: number }[]) {
  if (start >= end) return [];
  const out: { start: number; end: number }[] = [];
  let cur = start;
  for (const c of covered) {
    if (c.end <= cur) continue;
    if (c.start >= end) break;
    if (c.start > cur) out.push({ start: cur, end: Math.min(c.start, end) });
    if (c.end >= end) {
      cur = end;
      break;
    }
    cur = Math.max(cur, c.end);
  }
  if (cur < end) out.push({ start: cur, end });
  return out;
}

function insertCovered(covered: { start: number; end: number }[], span: { start: number; end: number }) {
  if (span.start >= span.end) return covered;
  let i = 0;
  for (; i < covered.length; i++) {
    if (covered[i].start > span.start) break;
  }
  covered.splice(i, 0, span);
  if (covered.length <= 1) return covered;
  const merged: { start: number; end: number }[] = [];
  for (const c of covered) {
    const last = merged[merged.length - 1];
    if (!last) {
      merged.push(c);
      continue;
    }
    if (c.start <= last.end) {
      if (c.end > last.end) last.end = c.end;
      continue;
    }
    merged.push(c);
  }
  return merged;
}

function redactText(input: string, patterns: PatternSet, session: PlaceholderSession): string {
  const text = String(input ?? '');
  if (!text) return text;
  const found: { start: number; end: number; original: string; category: string }[] = [];
  for (const rule of patterns.keywords) {
    if (!rule.value) continue;
    let idx = 0;
    for (;;) {
      const pos = text.indexOf(rule.value, idx);
      if (pos === -1) break;
      const start = pos;
      const end = pos + rule.value.length;
      const original = text.slice(start, end);
      idx = end;
      if (patterns.exclude.has(original)) continue;
      found.push({ start, end, original, category: rule.category });
    }
  }
  for (const rule of patterns.regex) {
    const baseFlags = String(rule.flags ?? '');
    const flags = baseFlags.includes('g') ? baseFlags : `${baseFlags}g`;
    let re: RegExp;
    try {
      re = new RegExp(rule.pattern, flags);
    } catch (_) {
      continue; // invalid user pattern — skip rather than break masking
    }
    for (const m of text.matchAll(re)) {
      if (!m[0]) continue;
      const start = m.index ?? -1;
      if (start < 0) continue;
      const end = start + m[0].length;
      const original = text.slice(start, end);
      if (patterns.exclude.has(original)) continue;
      found.push({ start, end, original, category: rule.category });
    }
  }
  if (found.length === 0) return text;
  found.sort((a, b) => (a.start !== b.start ? b.start - a.start : b.end - a.end));
  const planned: { start: number; end: number }[] = [];
  let covered: { start: number; end: number }[] = [];
  for (const m of found) {
    const segments = subtractCovered(m.start, m.end, covered);
    for (const seg of segments) {
      if (seg.start < 0 || seg.end > text.length || seg.start >= seg.end) continue;
      planned.push(seg);
      covered = insertCovered(covered, seg);
    }
  }
  planned.sort((a, b) => b.start - a.start);
  let out = text;
  for (const seg of planned) {
    const placeholder = session.getOrCreatePlaceholder(text.slice(seg.start, seg.end), 'TEXT');
    out = out.slice(0, seg.start) + placeholder + out.slice(seg.end);
  }
  return out;
}

function restoreText(input: string, session: PlaceholderSession): string {
  const text = String(input ?? '');
  if (!text) return text;
  const re = getPlaceholderRegex(session.prefix);
  return text.replace(re, (ph) => session.lookup(ph) ?? ph);
}

function isPlainObject(value: any): boolean {
  if (!value || typeof value !== 'object') return false;
  if (Array.isArray(value)) return false;
  const proto = Object.getPrototypeOf(value);
  return proto === Object.prototype || proto === null;
}

// Write-back contract: assign ONLY when the leaf actually changed, and never
// into a frozen node. opencode 2.0.11 passes the question tool's input (and
// possibly other UI-interactive tools') as a frozen object to execute.before —
// an unconditional no-op write ("node[key] = leaf(v)" with leaf identity)
// throws Bun's "Attempted to assign to readonly property" and hard-fails the
// tool call. Degradation when a frozen payload DOES contain a placeholder: the
// value stays masked in the UI instead of crashing the call.
export function walkDeep(node: any, seen: WeakSet<object>, leaf: (s: string) => string) {
  if (!node || typeof node !== 'object') return;
  if (seen.has(node)) return;
  seen.add(node);
  const frozen = Object.isFrozen(node);
  if (Array.isArray(node)) {
    for (let i = 0; i < node.length; i++) {
      const v = node[i];
      if (typeof v === 'string') {
        const next = leaf(v);
        if (next !== v && !frozen) node[i] = next;
      }
      if (v && typeof v === 'object') walkDeep(v, seen, leaf);
    }
    return;
  }
  if (!isPlainObject(node)) return;
  for (const key of Object.keys(node)) {
    const v = node[key];
    if (typeof v === 'string') {
      const next = leaf(v);
      if (next !== v && !frozen) node[key] = next;
    }
    if (v && typeof v === 'object') walkDeep(v, seen, leaf);
  }
}

function redactDeep(value: any, patterns: PatternSet, session: PlaceholderSession) {
  walkDeep(value, new WeakSet(), (s) => redactText(s, patterns, session));
}

function restoreDeep(value: any, session: PlaceholderSession) {
  walkDeep(value, new WeakSet(), (s) => restoreText(s, session));
}

// ── v2 plugin entrypoint ───────────────────────────────────────────────────────

export default {
  id: 'vibeguard',

  async setup(ctx: any) {
    const config = loadConfig(ctx?.location?.directory);
    const debug = Boolean(process.env.OPENCODE_VIBEGUARD_DEBUG) || config.debug;
    if (debug) {
      console.log(`[vibeguard] config: ${config.loadedFrom || 'not found (no-op)'} enabled=${config.enabled}`);
    }
    if (!config.enabled) return undefined; // no-op (fail-open, same as upstream)

    const patterns = buildPatternSet(config.patterns);
    const sessions = new Map<string, PlaceholderSession>();

    const getSession = (sessionID: unknown): PlaceholderSession | null => {
      const key = String(sessionID ?? '');
      if (!key) return null;
      let s = sessions.get(key);
      if (!s) {
        s = new PlaceholderSession({ prefix: config.prefix, ttlMs: config.ttlMs, maxMappings: config.maxMappings });
        sessions.set(key, s);
      }
      return s;
    };

    // Redact every outbound model request: system prompt + all message parts
    // (text, reasoning, tool call input/output — tool output is the most common
    // leak path, e.g. a `read` of .env).
    const redactRequest = (event: any) => {
      const session = getSession(event?.sessionID);
      if (!session) return;
      session.cleanup();
      let changed = 0;

      const redactStr = (s: string) => {
        const after = redactText(s, patterns, session);
        if (after !== s) changed++;
        return after;
      };

      if (Array.isArray(event?.system)) {
        for (const part of event.system) {
          if (part && typeof part === 'object' && typeof part.text === 'string') part.text = redactStr(part.text);
        }
      }

      for (const msg of Array.isArray(event?.messages) ? event.messages : []) {
        const parts = Array.isArray(msg?.parts) ? msg.parts : [];
        for (const part of parts) {
          if (!part) continue;
          if ((part.type === 'text' || part.type === 'reasoning') && typeof part.text === 'string') {
            if (part.ignored) continue;
            part.text = redactStr(part.text);
          } else if (part.type === 'tool') {
            const state = part.state;
            if (!state || typeof state !== 'object') continue;
            if (state.input && typeof state.input === 'object') {
              const before = JSON.stringify(state.input);
              redactDeep(state.input, patterns, session);
              if (JSON.stringify(state.input) !== before) changed++;
            }
            if (state.status === 'completed' && typeof state.output === 'string') state.output = redactStr(state.output);
            else if (state.status === 'error' && typeof state.error === 'string') state.error = redactStr(state.error);
            else if (state.status === 'pending' && typeof state.raw === 'string') state.raw = redactStr(state.raw);
          }
        }
      }

      if (debug && changed > 0) console.log(`[vibeguard] redacted ${changed} text segment(s) before model request`);
    };

    await ctx.session.hook('context', redactRequest);   // agent loop
    await ctx.session.hook('generate', redactRequest);  // transient generate calls

    // Restore real values in tool input right before local execution.
    await ctx.tool.hook('execute.before', (event: any) => {
      const session = getSession(event?.sessionID);
      if (!session) return;
      session.cleanup();
      if (event?.input && typeof event.input === 'object') restoreDeep(event.input, session);
      else if (typeof event?.input === 'string') event.input = restoreText(event.input, session);
    });

    if (debug) {
      console.log(
        `[vibeguard] active — ${patterns.regex.length} regex rule(s), ${patterns.keywords.length} keyword(s), prefix ${config.prefix}`,
      );
    }
    return undefined;
  },
};
