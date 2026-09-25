# process.exit truncates async pipe writes — drain stdout first

**Category**: solutions
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-25

## Pattern

`process.exit(0)` after a large `stdout` write truncates at the pipe-buffer boundary (~8KB observed) when stdout is a PIPE, but not on file redirects (synchronous per Node docs) — producing CI-green/local-red flakes that look like environment noise. #564: `deploy/tui.mjs select-items --print-plan --defaults` (22KB JSON) lost everything past 8192 bytes through `| node -e 'JSON.parse(stdin)'`.

Fix + verification recipe:

```js
if (process.stdout.writableLength > 0) {
  await new Promise((resolve) => process.stdout.write("", resolve));
}
process.exit(0);
```

Gate on `writableLength > 0` (covers in-flight writes); the empty write FIFO-queues behind buffered data — its callback fires only after the earlier bytes flush (empirically +120ms after a 64KB flush). EPIPE consumers (`| head`) still resolve the callback — no hang. Pin with a JSON.parse-through-pipe test; a file-redirect test will false-green. Origin: #564 exit gate.
