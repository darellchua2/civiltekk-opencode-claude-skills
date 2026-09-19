// learnings-autoinject.ts — OpenCode v2 plugin that auto-injects a compact
// manifest of a project's LEARNINGS/*.md files into the system prompt.
//
// Closes the gap documented in continuous-learning-skill/SKILL.md:
//   "OpenCode does NOT auto-scan LEARNINGS/ directories."
// Injects only the titles+paths index (~200-400 tokens); the model `read()`s
// full bodies on demand.
//
// ── v2 port notes ─────────────────────────────────────────────────────────────
// V1 hooks → v2 API:
//   config                                   → ctx.command.transform (editor.add)
//   "chat.message" (agent cache)             → NOT NEEDED: the v2 "context"
//                                             hook event carries `agent` directly
//   "experimental.chat.system.transform"     → ctx.session.hook("context") +
//                                             event.system.push({type:"text",...})
//   "command.execute.before" (toggle state)  → handled inside the command
//                                             execute() implementations
// Plain default export `{ id, setup }` (validated loader shape) — no runtime
// dependency on @opencode/plugin. Local plugins under plugins/*.ts are
// glob-discovered by OpenCode v2, same as v1.
//
// ── Env vars ───────────────────────────────────────────────────────────────────
//   LEARNINGS_AUTOINJECT_DEFAULT  — on|off  (default: on)   global default state
//   LEARNINGS_AUTOINJECT_USER     — on|off  (default: off)  also scan user-level dir
//   LEARNINGS_AUTOINJECT_OFF      — regex of agent names to EXCLUDE (default: read-only/research agents)
//   LEARNINGS_AUTOINJECT_MAX      — number  (default: 30)   cap files in manifest

import fs from 'fs';
import path from 'path';
import os from 'os';

// ── Configuration (read once at load) ──────────────────────────────────────────

function parseBoolEnv(name: string, fallback: boolean): boolean {
  const v = (process.env[name] || '').trim().toLowerCase();
  if (v === 'on' || v === '1' || v === 'true' || v === 'yes') return true;
  if (v === 'off' || v === '0' || v === 'false' || v === 'no') return false;
  return fallback;
}

const DEFAULT_ENABLED = parseBoolEnv('LEARNINGS_AUTOINJECT_DEFAULT', true);
const USER_LEVEL_ENABLED = parseBoolEnv('LEARNINGS_AUTOINJECT_USER', false);
const MAX_FILES = (() => {
  const n = parseInt(process.env.LEARNINGS_AUTOINJECT_MAX || '', 10);
  return Number.isFinite(n) && n > 0 ? Math.min(n, 100) : 30;
})();

// Read-only/research/non-coding agents that do not act on LEARNINGS.
// Kept in sync with ponytail-scoped's off-set by convention.
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
  const pattern = process.env.LEARNINGS_AUTOINJECT_OFF || DEFAULT_OFF_PATTERN;
  try {
    return new RegExp(pattern, 'i');
  } catch (_) {
    return new RegExp(DEFAULT_OFF_PATTERN, 'i');
  }
}
const OFF_REGEX = compileOffRegex();

const LEARNINGS_DIR = 'LEARNINGS';
const USER_LEARNINGS_DIR = path.join(os.homedir(), '.config', 'opencode', 'learnings');
const MARKER = 'LEARNINGS AUTOINJECT';

// ── Per-session state ───────────────────────────────────────────────────────────

const sessionEnabled = new Map();   // sessionID → boolean (overridden via /learnings-on|off)
const sessionManifest = new Map();  // sessionID → string | null (cached; rebuilt on /learnings-refresh)

function isOn(sessionID: string): boolean {
  if (sessionID && sessionEnabled.has(sessionID)) return sessionEnabled.get(sessionID);
  return DEFAULT_ENABLED;
}

function isInOffSet(agent?: string): boolean {
  if (!agent) return false;
  return OFF_REGEX.test(agent);
}

// ── LEARNINGS discovery (filesystem, dependency-free) ───────────────────────────

function walkMd(rootDir: string): string[] {
  const out: string[] = [];
  const stack = [rootDir];
  while (stack.length) {
    const dir = stack.pop()!;
    let entries: fs.Dirent[];
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch (_) {
      continue;
    }
    for (const e of entries) {
      if (e.isDirectory()) {
        if (!e.name.startsWith('.') && e.name !== 'node_modules') stack.push(path.join(dir, e.name));
      } else if (e.isFile() && e.name.endsWith('.md')) {
        out.push(path.join(dir, e.name));
      }
    }
  }
  return out.sort();
}

// Extract a one-line title: first H1/H2, else first non-empty non-frontmatter line.
function extractTitle(absPath: string): string | null {
  let fd: number | undefined;
  try {
    fd = fs.openSync(absPath, 'r');
    const buf = Buffer.alloc(512);
    const bytes = fs.readSync(fd, buf, 0, 512, 0);
    const lines = buf.toString('utf8', 0, bytes).split('\n');
    let inFrontmatter = false;
    let sawFrontmatterOpen = false;
    for (const raw of lines) {
      const line = raw.trim();
      if (!line || line.startsWith('<!--')) continue;
      if (line === '---') {
        if (!sawFrontmatterOpen) { inFrontmatter = true; sawFrontmatterOpen = true; continue; }
        inFrontmatter = false; continue;
      }
      if (inFrontmatter) continue;
      if (line.startsWith('# ')) return line.slice(2).trim().slice(0, 120);
      if (line.startsWith('## ')) return line.slice(3).trim().slice(0, 120);
      return line.replace(/^[-*]\s*/, '').slice(0, 120);
    }
  } catch (_) {
    // unreadable file — fall through
  } finally {
    if (fd !== undefined) { try { fs.closeSync(fd); } catch (_) {} }
  }
  return null;
}

function getProjectName(directory: string): string {
  try {
    const pj = path.join(directory, 'package.json');
    if (fs.existsSync(pj)) {
      const name = JSON.parse(fs.readFileSync(pj, 'utf8')).name;
      if (typeof name === 'string' && name.trim()) return name.trim();
    }
  } catch (_) {}
  return path.basename(directory) || 'project';
}

function buildSection(rootDir: string, rootLabel: string): { lines: string[]; total: number } | null {
  if (!fs.existsSync(rootDir)) return null;
  const files = walkMd(rootDir);
  if (files.length === 0) return null;
  const lines: string[] = [];
  for (const abs of files) {
    if (lines.length >= MAX_FILES) {
      lines.push(`... and ${files.length - MAX_FILES} more in ${rootLabel} (raise LEARNINGS_AUTOINJECT_MAX)`);
      break;
    }
    const rel = path.relative(rootDir, abs).replace(/\\/g, '/');
    const title = extractTitle(abs);
    lines.push(title ? `- ${rel} — ${title}` : `- ${rel}`);
  }
  return { lines, total: files.length };
}

function buildManifest(directory: string): string | null {
  const projectSection = buildSection(path.join(directory, LEARNINGS_DIR), 'project');
  let userSection: { lines: string[]; total: number } | null = null;
  if (USER_LEVEL_ENABLED) {
    userSection = buildSection(USER_LEARNINGS_DIR, 'user-level');
  }
  if (!projectSection && !userSection) return null;

  const out: string[] = [];
  out.push(`<${MARKER} — project: ${getProjectName(directory)}>`);
  out.push('Available learnings (use `read()` on a path for full detail):');
  if (projectSection) out.push(...projectSection.lines);
  if (userSection) {
    out.push(`(user-level @ ~/.config/opencode/learnings/ — ${userSection.total} files)`);
    out.push(...userSection.lines);
  }
  const counts: string[] = [];
  if (projectSection) counts.push(`${projectSection.total} project`);
  if (userSection) counts.push(`${userSection.total} user-level`);
  out.push(`Source: LEARNINGS/ (${counts.join(', ')}). Refresh: /learnings-refresh`);
  out.push(`</${MARKER}>`);
  return out.join('\n');
}

// ── v2 plugin ───────────────────────────────────────────────────────────────────

export default {
  id: 'learnings-autoinject',

  async setup(ctx: any) {
    const cwd: string = ctx?.location?.directory || process.cwd();

    // /learnings, /learnings-on, /learnings-off, /learnings-refresh.
    // v2 commands own their execution; toggles mutate session state here,
    // then submit the same confirmation template the v1 commands used.
    const confirm = (text: string) => async ({ sessionID, prompt, delivery }: any) => {
      await ctx.session.prompt({ ...prompt, sessionID, text, delivery });
    };

    await ctx.command.transform((editor: any) => {
      editor.add({
        name: 'learnings',
        description: 'Learnings-autoinject: report on/off state and file count for this session.',
        execute: confirm(
          'Report the learnings-autoinject state for this session in one line (on or off, and how many ' +
          'LEARNINGS files are indexed). Do not output code.',
        ),
      });
      editor.add({
        name: 'learnings-on',
        description: 'Learnings-autoinject: enable manifest injection for this session.',
        execute: async (inv: any) => {
          if (inv?.sessionID) sessionEnabled.set(inv.sessionID, true);
          await confirm('LEARNINGS auto-inject is now ON for this session. Confirm in one line. Do not output code.')(inv);
        },
      });
      editor.add({
        name: 'learnings-off',
        description: 'Learnings-autoinject: disable manifest injection for this session.',
        execute: async (inv: any) => {
          if (inv?.sessionID) sessionEnabled.set(inv.sessionID, false);
          await confirm('LEARNINGS auto-inject is now OFF for this session. Confirm in one line. Do not output code.')(inv);
        },
      });
      editor.add({
        name: 'learnings-refresh',
        description: 'Learnings-autoinject: re-scan LEARNINGS/ and rebuild the manifest on the next turn.',
        execute: async (inv: any) => {
          if (inv?.sessionID) sessionManifest.delete(inv.sessionID);
          await confirm('LEARNINGS manifest cache invalidated — it will be rebuilt on the next turn. Confirm in one line. Do not output code.')(inv);
        },
      });
    });

    // Core: append the cached manifest to the system prompt, gated by toggle +
    // off-set + idempotency. The v2 event carries agent + sessionID directly.
    await ctx.session.hook('context', (event: any) => {
      const sessionID = event?.sessionID;
      if (sessionID && !isOn(sessionID)) return;

      const agent = event?.agent;
      if (isInOffSet(agent)) return;

      const system = event?.system;
      if (!Array.isArray(system)) return;

      // Idempotency: skip if already injected this turn.
      for (const part of system) {
        if (part && typeof part === 'object' && typeof part.text === 'string' && part.text.includes(MARKER)) return;
      }

      let manifest = sessionID ? sessionManifest.get(sessionID) : undefined;
      if (manifest === undefined) {
        manifest = buildManifest(cwd);
        if (sessionID) sessionManifest.set(sessionID, manifest); // may be null (no LEARNINGS dir)
      }
      if (!manifest) return; // no LEARNINGS/ → skip silently

      system.push({ type: 'text', text: manifest });
    });

    return undefined;
  },
};
