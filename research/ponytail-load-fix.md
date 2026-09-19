# Ponytail Local Plugin — Load-Fix Diagnostic

**Date:** 2026-08-04
**Symptom:** After a machine reload, the Ponytail local plugin was not running — no `PONYTAIL MODE ACTIVE` marker or ruleset in the primary session's system prompt. OpenCode 1.18.11 confirmed installed and running.
**Outcome:** Root cause found and fixed. Plugin now discoverable + verified to load, register its 6 commands, and inject the ruleset through the transform hook.

---

## 1. Root cause (single, definitive)

**The plugin file used the `.mjs` extension, which OpenCode's local-plugin discovery glob does not match.**

OpenCode discovers local plugins by globbing the config directory. The glob (verified identical at git tag `v1.18.11`) is:

```js
// packages/opencode/src/config/plugin.ts  (sst/opencode)
export async function load(dir: string) {
  const plugins: ConfigPluginV1.Spec[] = []
  for (const item of await Glob.scan("{plugin,plugins}/*.{ts,js}", {
    cwd: dir, absolute: true, dot: true, symlink: true,
  })) {
    plugins.push(pathToFileURL(item).href)
  }
  return plugins
}
```

The brace pattern `{plugin,plugins}/*.{ts,js}` matches only **`.ts` and `.js`** files directly in a `plugin/` or `plugins/` directory. **`.mjs` is not in the set.** So `~/.config/opencode/plugins/ponytail-scoped.mjs` was silently never enumerated, never imported, and never loaded — no error, no log line. The hooks and export style of the plugin were irrelevant because the file was invisible to the loader.

Source URLs (canonical repo: **`sst/opencode`** — note: the task brief's "anomalyco/opencode" is incorrect; `opencode.ai` → `sst/opencode`):
- Discovery glob: https://raw.githubusercontent.com/sst/opencode/v1.18.11/packages/opencode/src/config/plugin.ts
- Loader + legacy-plugin extraction: https://raw.githubusercontent.com/sst/opencode/v1.18.11/packages/opencode/src/plugin/index.ts
- `Hooks` interface (valid hook names): https://raw.githubusercontent.com/sst/opencode/v1.18.11/packages/plugin/src/index.ts

---

## 2. Suspects ruled out (with source evidence)

### 2a. Invalid hook names — FALSE
All four hooks the plugin uses are first-class members of the `Hooks` interface at `v1.18.11` (`packages/plugin/src/index.ts`):
- `config?: (input: Config) => Promise<void>` 
- `"chat.message"?: (input: { sessionID, agent?, ... }, output) => Promise<void>` 
- `"experimental.chat.system.transform"?: (input: { sessionID?, model }, output: { system: string[] }) => Promise<void>`   ← the make-or-break system-prompt-mutation hook; it IS real in 1.18.11 (the public docs at opencode.ai/docs/plugins simply omit the `experimental.*` and `config`/`chat.message` hooks — the docs are incomplete, not the API).
- `"command.execute.before"?: (input: { command, sessionID, arguments }, output: { parts }) => Promise<void>` 

So the "OpenCode 1.18.11 has NO system-prompt-transform hook" worst case **did not occur**. `experimental.chat.system.transform` remains the correct, live injection mechanism.

### 2b. Default vs named export — FALSE (and now moot)
OpenCode's loader (`plugin/index.ts` → `applyPlugin` → `readV1Plugin(mod, spec, "server", "detect")` → `getLegacyPlugins(mod)`) extracts plugins by iterating **`Object.values(mod)`**, which includes both named exports and the `default` export. A `default`-exported function passes `readV1Plugin`'s detect gate (a function is not a record) and is picked up by `getLegacyPlugins`. So `export default` was never the blocker. (The plugin was still converted to a **named export** to match the documented pattern and to be maximally version-robust.)

### 2c. `.mjs` extension — **TRUE (the root cause)** — see §1.

### 2d. Load-time exception in `createRequire`/`.cjs` interop — N/A (untestable, file never imported)
Because the file was never imported, no `createRequiredMixin` exception could have occurred. After the fix, the interop was exercised end-to-end in the verification harness (§5) and works.

### 2e. Log evidence
Grep of `~/.local/share/opencode/log/*.log` for `ponytail` returned **zero** matches across all sessions (June–July 2026). No "loading plugin" line, no error — consistent with a file that the loader never enumerated. (The npm plugins in `opencode.json plugin[]` DO produce `service=plugin path=<pkg> loading plugin` lines; the local ponytail plugin never did.)

---

## 3. Why `.ts` and not `.js` for the renamed file

The config root `~/.config/opencode/package.json` has **no `"type"` field**:

```json
{ "dependencies": { "@opencode-ai/plugin": "1.14.20" } }
```

Under Node/Bun module resolution, a `.js` file with no `"type": "module"` in the nearest `package.json` is treated as **CommonJS**, which rejects ESM `export`/`import` syntax. The discovery glob accepts `.js`, but a `.js` plugin here would fail at import with a `SyntaxError`.

**`.ts` is the robust choice:** Bun (OpenCode's runtime) **always** treats `.ts` as ESM regardless of `package.json`, `.ts` is in the glob, and it is the primary example extension in the plugin docs. The `import { createRequire } from 'module'` + `require('./ponytail/instructions.cjs')` interop works unchanged in a `.ts` ESM file.

Rejected alternative: add `"type": "module"` to the config `package.json` and keep `.js`. Rejected because it is less surgical (could affect other `.js` in the config tree) and unnecessary — `.ts` solves both the glob and the ESM resolution in one change.

---

## 4. Plugin signature: before → after

**Before** (`ponytail-scoped.mjs`):
```js
export default async ({ client } = {}) => {
  // ... returns { config, 'chat.message', 'experimental.chat.system.transform', 'command.execute.before' }
};
```

**After** (`ponytail-scoped.ts`):
```ts
export const PonytailScoped = async ({ client }: any = {}) => {
  // identical body; identical 4 hooks; minimal `: any` type annotations
};
```

Changes: (1) file extension `.mjs` → `.ts`; (2) `export default` → `export const PonytailScoped` (named export, documented pattern); (3) trivial inline type annotations for TS validity. **No hook names changed** (all were already valid). **No logic changed** — the env vars, 6 slash commands, off-set regex, per-session/per-agent mode map, idempotency guard, and agent-type scoping are byte-for-byte equivalent.

Files edited:
- `~/.config/opencode/plugins/ponytail-scoped.ts` (new; `.mjs` deleted)
- `opencode_app/.opencode/plugins/ponytail-scoped.ts` (new; `.mjs` deleted) — repo source of truth
- `ATTRIBUTION.md`, `ponytail/instructions.cjs`, `ponytail/SKILL.md` — **untouched** (ruleset data, not the loading mechanism).

---

## 5. Verification performed (2026-08-04)

A harness (`/tmp/ponytail-verify.mjs`, run via Node v24.18.0 native type-stripping, since `bun` is not on PATH — OpenCode bundles its runtime internally) dynamically imported the deployed `.ts`, invoked the plugin, and exercised every hook:

1. `import(ponytail-scoped.ts)` succeeds; named export `PonytailScoped` is a function → **import + createRequire + `instructions.cjs` require all work**.
2. `PonytailScoped({ client })` returns all 4 hooks: `chat.message`, `command.execute.before`, `config`, `experimental.chat.system.transform`.
3. `config(cfg)` registers all 6 slash commands.
4. `chat.message` caches sessionID→agent.
5. `experimental.chat.system.transform` **appends the `PONYTAIL MODE ACTIVE` ruleset** to `output.system` → proves `instructions.cjs` + `SKILL.md` read + mode-filter + append logic all work end-to-end.
6. Idempotency guard: a second transform on already-injected output does not double-inject.
7. Off-set agent (`explore`) is skipped.
8. `command.execute.before` (`/ponytail-off`) disables injection for that session.

→ **ALL CHECKS PASSED** (full plugin logic verified in isolation; the only thing not exercised here is OpenCode's own hook-dispatch wiring, which is confirmed valid by the §2a source check).

**Remaining user-side verification (not automatable in this session):** restart OpenCode (`opencode` then a new session) and confirm:
- A `ponytail-scoped loaded` info line appears in `~/.local/share/opencode/log/<latest>.log`.
- The `/ponytail`, `/ponytail-lite`, … commands appear in the slash menu.
- The primary session's system prompt contains `PONYTAIL MODE ACTIVE` (self-check).

---

## 6. Provenance / cross-refs

- Prior audit conclusion (its research doc has since been purged): the "bake into .md" static-embed path is not needed — the transform hook exists, so static embedding is dead design.
- OpenCode plugin docs (note: docs omit `experimental.*`, `config`, and `chat.message` hooks — rely on the source `Hooks` interface, not the docs, for the full hook list): https://opencode.ai/docs/plugins/
- The `--pure` flag disables all external/local plugins; use it to A/B confirm Ponytail is the injection source.
