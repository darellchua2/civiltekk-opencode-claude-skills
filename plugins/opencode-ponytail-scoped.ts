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
//   PONYTAIL_DEFAULT_MODE   — lite|full|ultra|off  (default: full)
//   PONYTAIL_SUBAGENT_OFF   — regex of agent names to EXCLUDE (default: read-only/research agents)
//   PONYTAIL_AGENT_MODE_MAP — JSON { "<agent>": "<mode>" } per-agent overrides
//
// Vendored from @dietrichgebert/ponytail v4.8.4 (MIT). See ../ATTRIBUTION.md.
// The stock npm plugin MUST NOT be in opencode.json plugins array (double-injection guard).

import { createRequire } from 'module';
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

const PONYTAIL_DEFAULT_MODE = normalizeMode(process.env.PONYTAIL_DEFAULT_MODE) || DEFAULT_MODE;

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
  // 3. Global default
  return PONYTAIL_DEFAULT_MODE;
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

    // /ponytail with no arg = status query; with arg = switch.
    const ponytailCmd = async (inv: any) => {
      const argText = String(inv?.prompt?.text ?? '').trim().toLowerCase();
      const arg = argText.split(/\s+/)[0] || '';
      const mode = arg ? normalizeMode(arg) : null;
      if (mode && inv?.sessionID) sessionMode.set(inv.sessionID, mode);
      await submit(
        'You are running under ponytail. If the user gave a level, confirm the switch in one line. ' +
        'If no level was given, report the current mode in one line and what it means. Do not output code.',
      )(inv);
    };

    const levelCmd = (mode: string, confirmText: string) => async (inv: any) => {
      if (inv?.sessionID) sessionMode.set(inv.sessionID, mode);
      await submit(confirmText)(inv);
    };

    await ctx.command.transform((editor: any) => {
      editor.add({
        name: 'ponytail',
        description: 'Ponytail: report or set lazy-code intensity. Usage: /ponytail [lite|full|ultra|off]',
        execute: ponytailCmd,
      });
      editor.add({
        name: 'ponytail-help',
        description: 'Ponytail: quick command reference.',
        execute: submit(
          'List the ponytail slash commands and one line each on what they do: ' +
          '/ponytail [lite|full|ultra|off], /ponytail-help, /ponytail-lite, /ponytail-full, ' +
          '/ponytail-ultra, /ponytail-off. Format as a short list. Do not output code.',
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
