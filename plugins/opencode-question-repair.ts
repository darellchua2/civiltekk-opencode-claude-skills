// question-repair.ts — normalizes malformed `question` tool payloads before
// OpenCode's schema validator hard-fails them.
//
// Why this exists: session-audit evidence (opencode.db, Jun–Sep 2026, 1158
// question calls) showed 7 schema-validation failures — model-emitted payloads
// missing required fields (`question` text, option `label`/`description`),
// split evenly across glm-5.2 and glm-5.3. Each failure hard-fails the call and
// only recovers on a retry round-trip, surfacing as an error in the session.
// The prompt-hygiene rule (deploy/.AGENTS.md §Question Tool Payloads, PR #447)
// reduces frequency; this plugin eliminates the residue.
//
// v2 API (mirrors the proven production usage in plugins/opencode-vibeguard.ts:490):
//   ctx.tool.hook('execute.before', (event) => { ... event.input ... })
// guarded on `event.tool === 'question'` (documented v2 plugins-guide shape).
// Plain default export `{ id, setup }` — no runtime dependency on
// @opencode/plugin, same as the other local plugins here.
//
// Behavior contract:
// - Repair fills (per question item, in order):
//     description ← label                (verbatim copy)
//     label       ← first 5 words of description
//     question    ← header               (verbatim copy)
//     header      ← first 30 chars of question
//     multiple    ← false                (when absent or non-boolean)
// - Placeholder safety (vibeguard coexistence): both TRUNCATING fills
//   (`label ←`, `header ←`) copy the source verbatim when it contains `__VG` —
//   splitting a `__VG_<CATEGORY>_<hash>__` placeholder would leave fragments
//   vibeguard's restoreDeep cannot restore. vibeguard also hooks
//   execute.before on the same event; hook order between the two plugins is
//   glob-order and must not matter: this plugin only ever writes whole strings
//   or verbatim copies into input fields.
// - Drop rules: option entries missing BOTH `label` and `description`;
//   question items that are not objects, or have no usable `question` AND
//   `header`. Items whose options array is absent or empties after option
//   repair are KEPT with `options: []` — the schema reading is ambiguous
//   (Mode R relay round 2: served schema shows no item-level required, but
//   strictness can't be excluded), and `[]` is safe under both: present-but-
//   empty passes a required-check, and the tool's render path auto-appends a
//   "Type your own answer" free-text option regardless of option count. Drop
//   would risk silently losing a real question under the lenient reading.
// - Bounded repair: if input is not an object, has no `questions` array, or
//   every item is dropped, the ORIGINAL input reference is returned unchanged —
//   the schema validator then produces its error. This plugin never invents a
//   question and never mutates its input.
// - No-mutation contract: `normalizeQuestionInput` returns the same reference
//   when nothing needs repair; the hook swaps `event.input` only when a
//   different reference comes back. Valid payloads pass through untouched.
// - Debug knob: OPENCODE_QUESTION_REPAIR_DEBUG=1 logs a one-time
//   `[question-repair] loaded` marker at setup and one line per repair fired.

// ── pure helpers ───────────────────────────────────────────────────────────────

const VG_PLACEHOLDER = '__VG';

function isStr(v: unknown): v is string {
  return typeof v === 'string' && v.trim().length > 0;
}

// Truncate to n chars — but never split a vibeguard placeholder: verbatim copy
// (possibly over-length) beats a mask fragment that can never restore.
function truncPlaceholderSafe(s: string, n: number): string {
  if (s.includes(VG_PLACEHOLDER)) return s;
  return s.length <= n ? s : s.slice(0, n);
}

function firstWords(s: string, count: number): string {
  if (s.includes(VG_PLACEHOLDER)) return s;
  return s.trim().split(/\s+/).slice(0, count).join(' ');
}

function repairOption(raw: unknown): { opt: Record<string, unknown> | null; changed: boolean } {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return { opt: null, changed: true };
  const o = raw as Record<string, unknown>;
  const out = { ...o };
  let changed = false;

  if (!isStr(out.description) && isStr(out.label)) {
    out.description = out.label; // verbatim — no placeholder risk
    changed = true;
  }
  if (!isStr(out.label) && isStr(out.description)) {
    out.label = firstWords(out.description, 5);
    changed = true;
  }
  // Still nothing usable in either field → drop.
  if (!isStr(out.label) && !isStr(out.description)) return { opt: null, changed: true };

  return { opt: changed ? out : o, changed };
}

function repairItem(raw: unknown): { item: Record<string, unknown> | null; changed: boolean } {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return { item: null, changed: true };
  const q = raw as Record<string, unknown>;
  const out = { ...q };
  let changed = false;

  if (!isStr(out.question) && isStr(out.header)) {
    out.question = out.header; // verbatim — no placeholder risk
    changed = true;
  }
  if (!isStr(out.header) && isStr(out.question)) {
    out.header = truncPlaceholderSafe(out.question, 30);
    changed = true;
  }
  if (typeof out.multiple !== 'boolean') {
    out.multiple = false;
    changed = true;
  }

  // Nothing usable to render (no question AND no header) → drop.
  if (!isStr(out.question) && !isStr(out.header)) return { item: null, changed: true };

  // Options absent or emptied after option repair → keep with [] (safe under
  // both schema readings; the tool auto-appends a free-text option). Drop
  // would risk silently losing a real question.
  if (!Array.isArray(out.options)) {
    out.options = [];
    changed = true;
  } else {
    const opts: Record<string, unknown>[] = [];
    let optsChanged = false;
    for (const rawOpt of out.options) {
      const { opt, changed: c } = repairOption(rawOpt);
      optsChanged = optsChanged || c;
      if (opt) opts.push(opt);
    }
    if (optsChanged) {
      out.options = opts;
      changed = true;
    }
  }

  return { item: changed ? out : q, changed };
}

/**
 * Normalize a `question` tool input. Returns the SAME reference when nothing
 * needs repair (valid payloads are never touched); a repaired clone when fixes
 * were applied; the ORIGINAL reference when the payload is beyond repair
 * (non-object, no `questions` array, or every item dropped).
 */
export function normalizeQuestionInput(input: unknown): unknown {
  if (!input || typeof input !== 'object' || Array.isArray(input)) return input;
  const obj = input as Record<string, unknown>;
  if (!Array.isArray(obj.questions)) return input;

  const items: Record<string, unknown>[] = [];
  let changed = false;
  for (const rawItem of obj.questions) {
    const { item, changed: c } = repairItem(rawItem);
    changed = changed || c;
    if (item) items.push(item);
  }
  if (items.length === 0) return input; // beyond repair — let the validator error
  if (!changed) return input; // already valid — same reference, zero mutation
  return { ...obj, questions: items };
}

// ── v2 plugin entrypoint ───────────────────────────────────────────────────────

export default {
  id: 'question-repair',
  async setup(ctx: { tool: { hook: (name: string, cb: (event: any) => void) => Promise<void> } }) {
    const debug = process.env.OPENCODE_QUESTION_REPAIR_DEBUG === '1';
    if (debug) console.error('[question-repair] loaded');
    await ctx.tool.hook('execute.before', (event: { tool?: string; input?: unknown }) => {
      if (event?.tool !== 'question') return;
      const repaired = normalizeQuestionInput(event.input);
      if (repaired !== event.input) {
        if (debug) console.error('[question-repair] repaired malformed payload');
        event.input = repaired;
      }
    });
  },
};
