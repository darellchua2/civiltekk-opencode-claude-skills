// opencode-ponytail-scoped.ts — OpenCode v2 wrapper plugin for ponytail with
// agent-type-aware scoping.
//
// Wraps the vendored ponytail ruleset (./ponytail/) and adds what the stock
// @dietrichgebert/ponytail OpenCode adapter cannot do:
//   1. Agent-type scoping — read-only/research agents skip injection entirely.
//   2. Per-agent default modes via PONYTAIL_AGENT_MODE_MAP (JSON env var).
//
// ── v2 port notes ─────────────────────────────────────────────────────────────
// V1 hooks → v2 API:
//   config                                   → ctx.command.transform (editor.add)
//   "chat.message" (agent cache)             → NOT NEEDED: the v2 "context"
//                                             hook event carries `agent` directly
//   "experimental.chat.system.transform"     → ctx.session.hook("context") +
//                                             event.system.push({type:"text",...})
//   "command.execute.before" (mode switches) → handled inside the command
//                                             execute() implementations
// Plain default export `{ id, setup }` (validated loader shape) — no runtime
// dependency on @opencode/plugin.
//
// Env vars:
//   PONYTAIL_DEFAULT_MODE   — lite|full|ultra|off  (default: full; wins over the config file)
//   PONYTAIL_SUBAGENT_OFF   — regex of agent names to EXCLUDE (default: read-only/research agents)
//   PONYTAIL_AGENT_MODE_MAP — JSON { "<agent>": "<mode>" } per-agent overrides
//
// Persisted default (v4.9.0 upstream feature): `/ponytail default <mode>` writes
// { "defaultMode": "<mode>" } to ~/.local/share/opencode/ponytail-config.json
// (XDG data dir — the only path volume-mounted in the docker setup, so the
// default survives container recreation). Resolution: env var → config file → full.
// Bare `/ponytail` reports the active level; it never resets.
//
// Vendored from @dietrichgebert/ponytail v4.10.0 (MIT). See ../ATTRIBUTION.md.
// The stock npm plugin MUST NOT be in opencode.json plugins array (double-injection guard).

import { createRequire } from 'module';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const {
  getPonytailInstructions,
  normalizeMode,
  DEFAULT_MODE,
} = require('./ponytail/instructions.cjs');

// ── Configuration (read once at load) ──────────────────────────────────────────

// Persisted-default config: under the opencode data dir, NOT ~/.config — the
// docker compose setup volume-mounts only ~/.local/share/opencode, so a config
// anywhere else dies on container recreation (goal-plugin precedent).
const CONFIG_PATH = path.join(os.homedir(), '.local', 'share', 'opencode', 'ponytail-config.json');

// Strip a UTF-8 BOM before JSON.parse (upstream #378: a BOM'd config must not
// read as corrupt).
function parseConfigJson(raw: string): Record<string, unknown> {
  const parsed = JSON.parse(String(raw).replace(/^\uFEFF/, ''));
  return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : {};
}

function readPersistedDefault(): string | null {
  try {
    const cfg = parseConfigJson(fs.readFileSync(CONFIG_PATH, 'utf8'));
    return normalizeMode(String(cfg.defaultMode ?? '')) || null;
  } catch (_) {
    // missing/unreadable/malformed → fall through to the built-in default
    return null;
  }
}

// Mutable shadow of the persisted default: `/ponytail default` must take
// effect for new sessions in the SAME process, not only after a restart —
// a load-time const would freeze the value and contradict the command's
// own confirmation text (code-review #533 Major 1).
let persistedDefault = readPersistedDefault();

// Resolution order: env var → persisted config file → built-in default.
function globalDefault(): string {
  return normalizeMode(process.env.PONYTAIL_DEFAULT_MODE) || persistedDefault || DEFAULT_MODE;
}

function persistDefaultMode(mode: string): boolean {
  try {
    let cfg: Record<string, unknown> = {};
    let raw: string | null = null;
    try {
      raw = fs.readFileSync(CONFIG_PATH, 'utf8');
    } catch (_) {
      // absent → first write, nothing to preserve
    }
    if (raw !== null) {
      try {
        cfg = parseConfigJson(raw);
      } catch (_) {
        // present but unparseable — back it up before rewriting; never
        // silently destroy sibling settings we could not read
        try { fs.copyFileSync(CONFIG_PATH, `${CONFIG_PATH}.corrupt-${Date.now()}`); } catch (_) {}
        cfg = {};
      }
    }
    cfg.defaultMode = mode;
    fs.mkdirSync(path.dirname(CONFIG_PATH), { recursive: true });
    // atomic write (tmp + rename): a crash never leaves a truncated config
    const tmp = `${CONFIG_PATH}.tmp-${process.pid}`;
    fs.writeFileSync(tmp, JSON.stringify(cfg, null, 2) + '\n');
    fs.renameSync(tmp, CONFIG_PATH);
    persistedDefault = mode; // shadow update — same-process sessions see it
    return true;
  } catch (_) {
    return false;
  }
}

// Default off-set: agents that should NOT receive runtime Ponytail injection —
// read-only/research agents (Ponytail N/A), non-coding agents (docs, business,
// integrations, vision), and the 8 high-value coding agents that carry a baked-in
// role-tuned lens (see each agent's "Ponytail <X> lens" section + provenance tag).
const DEFAULT_OFF_PATTERN =
  '^(explore|general|autoresearch-research-subagent|explorer-subagent|' +
  'requirements-specialist-subagent|discovery-specialist-subagent|' +
  'technical-design-specialist-subagent|' +
  'coverage-subagent|documentation-subagent|docx-creation-subagent|' +
  'pptx-specialist-subagent|xlsx-specialist-subagent|office-document-router-subagent|' +
  'startup-ceo-subagent|startup-founder-subagent|' +
  'image-analyzer-subagent|' +
  'code-review-subagent|architecture-review-subagent|error-resolver-subagent|' +
  'nextjs-specialist-subagent|autoresearch-code-subagent|loop-operator-subagent|' +
  'tdd-subagent|testing-subagent)$';

function compileOffRegex() {
  const pattern = process.env.PONYTAIL_SUBAGENT_OFF || DEFAULT_OFF_PATTERN;
  try {
    return new RegExp(pattern, 'i');
  } catch (_) {
    return new RegExp(DEFAULT_OFF_PATTERN, 'i');
  }
}
const OFF_REGEX = compileOffRegex();

// Per-agent mode overrides: { "build": "full", "code-review-subagent": "lite" }
let AGENT_MODE_MAP: Record<string, string> = {};
if (process.env.PONYTAIL_AGENT_MODE_MAP) {
  try {
    const parsed = JSON.parse(process.env.PONYTAIL_AGENT_MODE_MAP);
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      AGENT_MODE_MAP = parsed;
    }
  } catch (_) {
    // invalid JSON → silently fall back to empty map (default mode governs)
  }
}

// ── Per-session state ───────────────────────────────────────────────────────────

const sessionMode = new Map(); // sessionID → mode (overridden via /ponytail commands)

function resolveMode(sessionID: any, agent?: string): string {
  // 1. Per-session override (from /ponytail <level> command) — highest priority
  if (sessionID && sessionMode.has(sessionID)) return sessionMode.get(sessionID);
  // 2. Per-agent map
  if (agent && AGENT_MODE_MAP[agent]) {
    const m = normalizeMode(AGENT_MODE_MAP[agent]);
    if (m) return m;
  }
  // 3. Global default (env var → persisted config → built-in)
  return globalDefault();
}

function isInOffSet(agent?: string): boolean {
  if (!agent) return false;
  return OFF_REGEX.test(agent);
}

const PONYTAIL_MARKER = 'PONYTAIL MODE ACTIVE';

// ── v2 plugin ───────────────────────────────────────────────────────────────────

export default {
  id: 'ponytail-scoped',

  async setup(ctx: any) {
    // /ponytail [lite|full|ultra|off], /ponytail-help, /ponytail-<level>.
    // v2 commands own their execution; mode switches mutate session state here.
    const submit = (text: string) => async (inv: any) => {
      await ctx.session.prompt({ ...inv.prompt, sessionID: inv.sessionID, text, delivery: inv.delivery });
    };

    // /ponytail with no arg = status query (reports the active level, never resets);
    // `/ponytail default <mode>` = persist the default across restarts.
    const ponytailCmd = async (inv: any) => {
      const argText = String(inv?.prompt?.text ?? '').trim().toLowerCase();
      const tokens = argText.split(/\s+/).filter(Boolean);
      const first = tokens[0] || '';

      if (first === 'default') {
        const requested = normalizeMode(tokens[1] || '');
        if (requested && persistDefaultMode(requested)) {
          await submit(
            `Ponytail default mode set to "${requested}" and persisted (new sessions pick it up; ` +
            'an explicit PONYTAIL_DEFAULT_MODE env var still overrides it). Confirm in one line. Do not output code.',
          )(inv);
        } else {
          await submit(
            'Ponytail: could not set the default (invalid mode or config write failed). ' +
            'Usage: /ponytail default lite|full|ultra|off. Do not output code.',
          )(inv);
        }
        return;
      }

      const mode = first ? normalizeMode(first) : null;
      if (mode && inv?.sessionID) sessionMode.set(inv.sessionID, mode);
      const current = (inv?.sessionID && sessionMode.get(inv.sessionID)) || globalDefault();
      await submit(
        `You are running under ponytail at level "${current}". ` +
        'If the user gave a level, confirm the switch in one line. ' +
        'Otherwise report the current mode in one line and what it means. Do not output code.',
      )(inv);
    };

    const levelCmd = (mode: string, confirmText: string) => async (inv: any) => {
      if (inv?.sessionID) sessionMode.set(inv.sessionID, mode);
      await submit(confirmText)(inv);
    };

    await ctx.command.transform((editor: any) => {
      editor.add({
        name: 'ponytail',
        description: 'Ponytail: report or set lazy-code intensity. Usage: /ponytail [lite|full|ultra|off|default <mode>]',
        execute: ponytailCmd,
      });
      editor.add({
        name: 'ponytail-help',
        description: 'Ponytail: quick command reference.',
        execute: submit(
          'List the ponytail slash commands and one line each on what they do: ' +
          '/ponytail [lite|full|ultra|off] (no arg reports the active level), ' +
          '/ponytail default <mode> (persist the default across restarts), /ponytail-help, ' +
          '/ponytail-lite, /ponytail-full, /ponytail-ultra, /ponytail-off. ' +
          'Format as a short list. Do not output code.',
        ),
      });
      editor.add({
        name: 'ponytail-lite',
        description: 'Ponytail: switch to lite intensity (name the lazier alternative, user picks).',
        execute: levelCmd('lite', 'Ponytail mode is now lite. Confirm in one line. Do not output code.'),
      });
      editor.add({
        name: 'ponytail-full',
        description: 'Ponytail: switch to full intensity (the ladder enforced, default).',
        execute: levelCmd('full', 'Ponytail mode is now full. Confirm in one line. Do not output code.'),
      });
      editor.add({
        name: 'ponytail-ultra',
        description: 'Ponytail: switch to ultra intensity (YAGNI extremist, deletion before addition).',
        execute: levelCmd('ultra', 'Ponytail mode is now ultra. Confirm in one line. Do not output code.'),
      });
      editor.add({
        name: 'ponytail-off',
        description: 'Ponytail: turn off lazy-code injection for this session.',
        execute: levelCmd('off', 'Ponytail is now off for this session. Confirm in one line. Do not output code.'),
      });
    });

    // Core: append the mode-filtered ruleset to the system prompt, scoped by
    // agent type. The v2 event carries agent + sessionID directly.
    await ctx.session.hook('context', (event: any) => {
      const sessionID = event?.sessionID;
      const agent = event?.agent;

      const mode = resolveMode(sessionID, agent);
      if (mode === 'off') return;
      if (isInOffSet(agent)) return;

      const instructions = getPonytailInstructions(mode);
      if (!instructions) return;

      const system = event?.system;
      if (!Array.isArray(system)) return;

      // Idempotency / double-injection guard: skip if already injected this turn.
      for (const part of system) {
        if (part && typeof part === 'object' && typeof part.text === 'string' && part.text.includes(PONYTAIL_MARKER)) return;
      }

      system.push({ type: 'text', text: instructions });
    });

    return undefined;
  },
};
