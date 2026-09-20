// Unit tests for plugins/question-repair.ts — pure repair rules plus the hook
// wiring (tool guard, reference-swap, no-mutation). Run:
//   node --test tests/test_question_repair_plugin.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import plugin, { normalizeQuestionInput } from '../plugins/question-repair.ts';

// ── pure helpers ───────────────────────────────────────────────────────────────

test('AC1: missing option description is filled from label', () => {
  const input = {
    questions: [{ question: 'Q?', header: 'H', multiple: false, options: [{ label: 'Yes' }] }],
  };
  const out: any = normalizeQuestionInput(input);
  assert.notEqual(out, input); // repaired → new reference
  assert.equal(out.questions[0].options[0].description, 'Yes');
});

test('missing option label is filled from first 5 words of description', () => {
  const input = {
    questions: [
      {
        question: 'Q?',
        header: 'H',
        options: [{ description: 'one two three four five six seven' }],
      },
    ],
  };
  const out: any = normalizeQuestionInput(input);
  assert.equal(out.questions[0].options[0].label, 'one two three four five');
});

test('missing question text is filled from header (real audited fixture)', () => {
  // Trimmed from the 2026-08-16 "Storage design" call: questions[1] missing `question`.
  const input = {
    questions: [
      {
        question: 'Where should rule_metadata live?',
        header: 'Storage design',
        multiple: false,
        options: [
          { label: 'Keep embedded (current plan)', description: 'rule_metadata inside spec JSONB' },
        ],
      },
      {
        header: 'Storage design',
        options: [
          { label: 'Satellite table', description: '1:1 satellite table keyed by rule id' },
        ],
      },
    ],
  };
  const out: any = normalizeQuestionInput(input);
  assert.equal(out.questions[1].question, 'Storage design');
  assert.equal(out.questions[1].multiple, false);
  assert.equal(out.questions.length, 2); // nothing dropped
});

test('missing header is filled from first 30 chars of question', () => {
  const q = 'x'.repeat(40);
  const input = { questions: [{ question: q, options: [{ label: 'A' }] }] };
  const out: any = normalizeQuestionInput(input);
  assert.equal(out.questions[0].header.length, 30);
});

test('truncating fills never split a vibeguard placeholder', () => {
  const q = 'prefix __VG_TOKEN_abc123456789__ suffix text beyond thirty chars';
  const input = { questions: [{ question: q, options: [{ description: '__VG_TOK_def4567890123__ rest' }] }] };
  const out: any = normalizeQuestionInput(input);
  assert.ok(out.questions[0].header.includes('__VG_TOKEN_abc123456789__'));
  assert.ok(out.questions[0].options[0].label.includes('__VG_TOK_def4567890123__'));
});

test('AC2: option entries missing both fields are dropped', () => {
  const input = {
    questions: [
      { question: 'Q?', header: 'H', options: [{ label: 'A' }, {}, 'garbage', { description: 'B desc' }] },
    ],
  };
  const out: any = normalizeQuestionInput(input);
  assert.equal(out.questions[0].options.length, 2);
  assert.deepEqual(out.questions[0].options.map((o: any) => o.label ?? o.description).sort(), ['A', 'B desc']);
});

test('options-less items are KEPT with options: [] (safe under both schema readings)', () => {
  const input = {
    questions: [{ question: 'Q?', header: 'H', options: [{ label: 'A' }] }, null, { question: 'Q2', header: 'H2' }, { question: 'Q3', header: 'H3', options: [{}, 'garbage'] }],
  };
  const out: any = normalizeQuestionInput(input);
  assert.equal(out.questions.length, 3); // null dropped; both question/header-valid items kept
  assert.deepEqual(out.questions.map((q: any) => q.question), ['Q?', 'Q2', 'Q3']);
  assert.deepEqual(out.questions[1].options, []); // absent → normalized to []
  assert.deepEqual(out.questions[2].options, []); // emptied after option repair → []
});

test('items with neither question nor header are dropped', () => {
  const input = { questions: [{ options: [{ label: 'A' }] }, { multiple: true, options: [] }] };
  const out = normalizeQuestionInput(input);
  assert.strictEqual(out, input); // everything dropped → beyond repair → original
});

test('AC3: valid payloads pass through as the same reference (no mutation)', () => {
  const input = {
    questions: [
      {
        question: 'Q?',
        header: 'H',
        multiple: true,
        options: [{ label: 'A', description: 'a' }],
      },
    ],
  };
  const before = JSON.stringify(input);
  const out = normalizeQuestionInput(input);
  assert.strictEqual(out, input); // same reference
  assert.equal(JSON.stringify(input), before); // zero mutation
});

test('beyond-repair inputs return the original reference', () => {
  for (const bad of [null, undefined, 'str', 42, [], { questions: 'nope' }, { questions: [null, {}] }]) {
    const out = normalizeQuestionInput(bad);
    assert.strictEqual(out, bad, JSON.stringify(bad));
  }
});

test('multiple defaults to false when absent or non-boolean', () => {
  const input = { questions: [{ question: 'Q?', header: 'H', options: [{ label: 'A' }] }] };
  const out: any = normalizeQuestionInput(input);
  assert.equal(out.questions[0].multiple, false);
  const input2 = { questions: [{ question: 'Q?', header: 'H', multiple: 'yes', options: [{ label: 'A' }] }] };
  const out2: any = normalizeQuestionInput(input2);
  assert.equal(out2.questions[0].multiple, false);
});

// ── hook wiring ────────────────────────────────────────────────────────────────

function fakeCtx() {
  const hooks: Record<string, (event: any) => void> = {};
  return {
    hooks,
    ctx: { tool: { hook: async (name: string, cb: (event: any) => void) => { hooks[name] = cb; } } },
  };
}

test('hook: replaces event.input only for the question tool, only when repaired', async () => {
  const { hooks, ctx } = fakeCtx();
  await plugin.setup(ctx as any);
  const before = hooks['execute.before'];
  assert.ok(before, 'execute.before hook registered');

  const malformed = { questions: [{ header: 'H', options: [{ label: 'A' }] }] };
  const evt: any = { tool: 'question', input: malformed };
  before(evt);
  assert.notEqual(evt.input, malformed);
  assert.equal((evt.input as any).questions[0].question, 'H');

  const valid = { questions: [{ question: 'Q?', header: 'H', multiple: false, options: [{ label: 'A', description: 'a' }] }] };
  const evt2: any = { tool: 'question', input: valid };
  before(evt2);
  assert.strictEqual(evt2.input, valid); // untouched

  const otherTool: any = { tool: 'read', input: { questions: [{ header: 'H' }] } };
  before(otherTool);
  assert.equal(otherTool.input.questions[0].question, undefined); // other tools untouched
});
