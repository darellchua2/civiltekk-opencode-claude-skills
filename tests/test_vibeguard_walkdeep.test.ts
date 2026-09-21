// Regression tests for the opencode-vibeguard-v2.ts walkDeep write-back contract:
// assign only on real change, never into frozen nodes. opencode 2.0.11 passes
// the question tool's input to execute.before frozen — an unconditional no-op
// write threw "Attempted to assign to readonly property" and hard-failed every
// question call. Run:
//   node --test tests/test_vibeguard_walkdeep.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { walkDeep } from '../plugins/opencode-vibeguard-v2.ts';

const ID = (s: string) => s;
const BANG = (s: string) => s + '!';

test('frozen nested input with identity leaf does not throw (the 2.0.11 question regression)', () => {
  const input = Object.freeze({
    questions: [
      Object.freeze({
        question: 'Pick one',
        header: 'Test',
        options: Object.freeze([
          Object.freeze({ label: 'A', description: 'Alpha' }),
          Object.freeze({ label: 'B', description: 'Beta' }),
        ]),
      }),
    ],
  });
  assert.doesNotThrow(() => walkDeep(input, new WeakSet(), ID));
});

test('frozen nodes are left untouched even when the leaf would change them', () => {
  const node = Object.freeze({ command: 'echo hi' });
  walkDeep(node, new WeakSet(), BANG);
  assert.equal(node.command, 'echo hi'); // masked-restore degradation, not a crash
});

test('mutable nodes still get rewritten when the leaf changes the value', () => {
  const node = { cmd: 'echo __VG_ENV_abc123__', nested: { path: '/tmp/x' } };
  walkDeep(node, new WeakSet(), BANG);
  assert.equal(node.cmd, 'echo __VG_ENV_abc123__!');
  assert.equal(node.nested.path, '/tmp/x!');
});

test('identity leaf performs zero writes on mutable nodes (values unchanged)', () => {
  const node = { a: 'one', arr: ['two', { b: 'three' }] };
  walkDeep(node, new WeakSet(), ID);
  assert.deepEqual(node, { a: 'one', arr: ['two', { b: 'three' }] });
});

test('cycles are tolerated (seen WeakSet)', () => {
  const node: any = { name: 'x' };
  node.self = node;
  assert.doesNotThrow(() => walkDeep(node, new WeakSet(), BANG));
  assert.equal(node.name, 'x!');
});
