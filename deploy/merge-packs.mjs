#!/usr/bin/env node
// deploy/merge-packs.mjs
//
// Provider-pack merger. Deep-merges one or more pack partials
// (deploy/packs/pack-<name>.json) into a target opencode.json (v2 shape),
// flipping `mcp.servers.<server>.disabled` (packs carry `disabled: false`),
// appending `permissions` array rules, and routing client-plugin partials to
// the v2 global client config (cli.json).
//
// Companion to deploy/resolve-models.mjs. Zero external dependencies — Node
// built-ins only (fs, path). Mirrors resolve-models.mjs conventions:
//   - ES modules, async main(), camelCase arg parsing
//   - readJsonMaybe / stripJsonComments helpers
//   - $comment keys tolerated in pack JSON
//
// Semantics (per PLAN-374 Phase 2, v2 shape):
//   - Pack `mcp` fragments are v2-shaped ({ servers: { name: { disabled: false } } })
//     and deep-merge into config.mcp.servers (inversion already applied in the
//     pack data; the merger does not translate).
//   - Pack `permissions` fragments are v2 rule arrays and are APPENDED to
//     config.permissions — never wholesale-replacing the shipped array. A rule
//     with the same action+resource replaces its prior entry in place
//     (idempotent re-runs).
//   - Deep-merge: last-wins on scalars; objects merged recursively; arrays
//     left untouched (except permissions, handled explicitly above).
//   - A pack's optional `cli` key (plugin packs, e.g. pack-voice.json) is
//     stripped from the opencode.json merge and merged into the SEPARATE
//     client config via --client-config (v2 cli.json): `plugins` entries merge
//     BY PACKAGE NAME in v2 object form ({package, options}) — idempotent
//     re-runs replace in place, other plugins are preserved.
//   - --tui-config is the explicit v1-compat fallback: writes the same `cli`
//     partial to a legacy tui.json, converting plugin objects to v1
//     [name, options] tuples. Only for deploys still running a v1 client.
//   - Neither client-config flag set while a pack carries `cli` => warning +
//     skip (Docker build path: containers have no microphone, client config is
//     host-side). Never fatal.
//   - Empty/whitespace --packs => true no-op (exit 0, no read, no write).
//     This is the Docker `ARG OPENCODE_PACKS=""` default path. Implemented
//     via split(",").map(trim).filter(Boolean) so "" never becomes [""].
//   - Unknown pack => exit non-zero, clear error listing available packs,
//     write nothing.
//   - Malformed pack JSON => exit non-zero with file path + parse error
//     (mirrors resolve-models.mjs line 73).
//   - --dry-run => print a summary of what WOULD change; do not write.
//   - Idempotent: running the same pack list twice yields identical output.
//
// Usage:
//   node merge-packs.mjs \
//     --config <opencode.json> \
//     --packs-dir <deploy/packs> \
//     --packs autodesk \
//     [--client-config <cli.json>] \
//     [--tui-config <tui.json>] (legacy) \
//     [--dry-run] [--verbose]
//
// Exit codes: 0 success/no-op, 1 bad args / unknown pack / parse error / IO.

import { readFile, writeFile, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";

// ─────────────────────────── arg parsing ────────────────────────────────
const camel = (s) => s.replace(/-([a-z])/g, (_, c) => c.toUpperCase());

function parseArgsCamel(argv) {
  const out = {
    config: null,
    clientConfig: null,
    tuiConfig: null,
    packsDir: null,
    packs: "",
    dryRun: false,
    verbose: false,
  };
  const boolKeys = new Set(["dryRun", "verbose"]);
  for (let i = 0; i < argv.length; i++) {
    let a = argv[i];
    if (!a.startsWith("--")) continue;
    let key = camel(a.slice(2));
    if (boolKeys.has(key)) {
      out[key] = true;
    } else {
      out[key] = argv[++i];
    }
  }
  return out;
}
const O = parseArgsCamel(process.argv.slice(2));

// ─────────────────────────── helpers ────────────────────────────────────

// tolerate $comment keys + trailing commas minimally (our pack files use $comment)
function stripJsonComments(txt) {
  return txt.replace(/^[ \t]*"\$comment"[ \t]*:.*$(\r?\n)?/gm, "");
}

async function readJsonMaybe(p) {
  if (!p) return null;
  try {
    const txt = await readFile(p, "utf8");
    return JSON.parse(stripJsonComments(txt));
  } catch (e) {
    if (e.code === "ENOENT") return null;
    throw new Error(`Failed to parse JSON ${p}: ${e.message}`);
  }
}

// Deep-merge `src` into `dst` in place. Scalars: last-wins (src overwrites).
// Objects: recurse. Arrays: replaced wholesale (documented limitation —
// permissions arrays are merged explicitly in main(), never via this).
function deepMerge(dst, src) {
  for (const [k, v] of Object.entries(src)) {
    if (
      v !== null &&
      typeof v === "object" &&
      !Array.isArray(v) &&
      dst[k] !== null &&
      typeof dst[k] === "object" &&
      !Array.isArray(dst[k])
    ) {
      deepMerge(dst[k], v);
    } else {
      dst[k] = v;
    }
  }
  return dst;
}

// Plugin identity: v2 object form uses `package`; legacy tuple form uses [0].
function pluginName(entry) {
  if (Array.isArray(entry)) return typeof entry[0] === "string" ? entry[0] : null;
  if (entry && typeof entry === "object" && typeof entry.package === "string") return entry.package;
  return typeof entry === "string" ? entry : null;
}

// Merge plugin lists BY PACKAGE NAME. Existing same-name entry is replaced in
// place; new entries are appended. Idempotent.
function mergePluginList(dstArr, srcArr) {
  for (const entry of srcArr) {
    const name = pluginName(entry);
    const idx = name ? dstArr.findIndex((e) => pluginName(e) === name) : -1;
    if (idx >= 0) dstArr[idx] = entry;
    else dstArr.push(entry);
  }
  return dstArr;
}

// v2 plugin object -> legacy tui.json tuple (only used by --tui-config).
function pluginToTuple(entry) {
  if (entry && !Array.isArray(entry) && typeof entry.package === "string") {
    return [entry.package, entry.options ?? {}];
  }
  return entry;
}

function log(...a)   { console.log(...a); }
function verbose(...a){ if (O.verbose) console.error("[verbose]", ...a); }
function die(msg, code = 1) {
  console.error(`error: ${msg}`);
  process.exit(code);
}

// ─────────────────────────── main ───────────────────────────────────────
async function main() {
  // required args
  if (!O.config)    die("--config <path> is required");
  if (!O.packsDir)  die("--packs-dir <path> is required");
  // --packs is optional (empty = no-op); default "" is handled below.

  // M2: empty/whitespace packs => true no-op. split+trim+filter so "" => [].
  const requested = (O.packs || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);

  if (requested.length === 0) {
    log("No packs requested (--packs empty) — no-op, config untouched.");
    return;
  }

  // discover available packs in packs-dir
  if (!existsSync(O.packsDir)) {
    die(`--packs-dir not found: ${O.packsDir}`);
  }
  const entries = await readdir(O.packsDir);
  const available = entries
    .filter((f) => /^pack-(.+)\.json$/.test(f))
    .map((f) => f.replace(/^pack-/, "").replace(/\.json$/, ""))
    .sort();

  // validate requested against available
  const unknown = requested.filter((n) => !available.includes(n));
  if (unknown.length > 0) {
    die(
      `Unknown pack(s): ${unknown.join(", ")}\n` +
        `Available packs in ${O.packsDir}: ${available.join(", ")}`
    );
  }

  // load target config
  if (!existsSync(O.config)) {
    die(`--config file not found: ${O.config}`);
  }
  const config = await readJsonMaybe(O.config);
  if (!config || typeof config !== "object") {
    die(`Could not parse config as JSON object: ${O.config}`);
  }

  // snapshot for changed-detection (only the keys packs may touch)
  const before = JSON.stringify({
    mcp: config.mcp || {},
    permissions: config.permissions || [],
  });

  // load + merge each requested pack in order. `cli` keys are plugin-pack
  // partials — strip them so they never leak into opencode.json (handled below).
  verbose(`Merging ${requested.length} pack(s) into ${O.config}:`);
  const merged = [];
  for (const name of requested) {
    const file = join(O.packsDir, `pack-${name}.json`);
    verbose(`  - ${name} (${file})`);
    const pack = await readJsonMaybe(file); // throws on malformed JSON (parse error)
    if (!pack || typeof pack !== "object") {
      die(`Pack ${name} is not a JSON object: ${file}`);
    }
    const { cli, mcp, permissions, ...restPack } = pack;
    if (Object.keys(restPack).length > 0) deepMerge(config, restPack);
    if (mcp && typeof mcp === "object") {
      // v2 pack fragments are { servers: { name: {...} } }; merge into config.mcp.
      config.mcp = config.mcp || {};
      deepMerge(config.mcp, mcp);
    }
    if (Array.isArray(permissions)) {
      if (!Array.isArray(config.permissions)) config.permissions = [];
      for (const rule of permissions) {
        const idx = config.permissions.findIndex(
          (r) => r && r.action === rule.action && r.resource === rule.resource
        );
        if (idx >= 0) config.permissions[idx] = rule;
        else config.permissions.push(rule);
      }
    }
    merged.push({ name, cli });
  }

  // Plugin packs: merge `cli` partials into the separate client config. The
  // plugins list merges by package name (idempotent, preserves the user's
  // plugins). Missing both flags is a warning, not an error: the Docker build
  // path has no host client config (no microphone in containers).
  let clientChanged = false;
  let clientTarget = null;
  const cliPacks = merged.filter(({ cli }) => cli && typeof cli === "object");
  if (cliPacks.length > 0) {
    if (!O.clientConfig && !O.tuiConfig) {
      log(
        "warning: pack(s) carry a 'cli' key but neither --client-config nor --tui-config was set — " +
          "skipping plugin merge (client config is host-side; not applicable in Docker)."
      );
    } else {
      const legacy = !O.clientConfig && !!O.tuiConfig;
      clientTarget = legacy ? O.tuiConfig : O.clientConfig;
      const clientConfig =
        (await readJsonMaybe(clientTarget)) ||
        (legacy
          ? { $schema: "https://opencode.ai/tui.json" }
          : { $schema: "https://opencode.ai/v2/cli.json" });
      const clientBefore = JSON.stringify(clientConfig);
      for (const { name, cli } of cliPacks) {
        verbose(`  - ${name} cli -> ${clientTarget}${legacy ? " (legacy tui.json)" : ""}`);
        const { plugins, ...cliRest } = cli;
        deepMerge(clientConfig, cliRest);
        if (Array.isArray(plugins)) {
          // v2 cli.json uses `plugins`; legacy tui.json uses `plugin` (tuples) —
          // write to whichever key the target config format reads.
          const key = legacy ? "plugin" : "plugins";
          if (!Array.isArray(clientConfig[key])) clientConfig[key] = [];
          const incoming = legacy ? plugins.map(pluginToTuple) : plugins;
          mergePluginList(clientConfig[key], incoming);
        }
      }
      clientChanged = JSON.stringify(clientConfig) !== clientBefore;
      if (!O.dryRun) {
        await writeFile(
          clientTarget,
          JSON.stringify(clientConfig, null, 2) + "\n",
          "utf8"
        );
      }
    }
  }

  const after = JSON.stringify({
    mcp: config.mcp || {},
    permissions: config.permissions || [],
  });

  if (O.dryRun) {
    log(`[DRY-RUN] Would merge ${requested.length} pack(s) into ${O.config}:`);
    log(`  packs: ${requested.join(", ")}`);
    log(`  changed: ${before === after ? "nothing (already merged)" : "yes"}`);
    // list the servers that would be enabled (packs carry disabled: false)
    const enabling = [];
    for (const name of requested) {
      const p = await readJsonMaybe(join(O.packsDir, `pack-${name}.json`));
      for (const [srv, def] of Object.entries(p.mcp?.servers ?? {})) {
        if (def && def.disabled === false) enabling.push(srv);
      }
    }
    log(`  servers that would be enabled: ${enabling.join(", ")}`);
    if (cliPacks.length > 0) {
      const plugins = cliPacks.flatMap(({ cli }) =>
        (cli.plugins || []).map((p) => pluginName(p))
      );
      log(
        `  plugins that would be ${clientTarget ? "merged into " + clientTarget : "SKIPPED (no client-config flag)"}: ${plugins.join(", ")}`
      );
    }
    return;
  }

  // write merged config (2-space indent matches opencode.json style)
  await writeFile(O.config, JSON.stringify(config, null, 2) + "\n", "utf8");
  log(`Merged ${requested.length} pack(s) into ${O.config}:`);
  log(`  packs: ${requested.join(", ")}`);
  log(`  changed: ${before === after ? "nothing (already merged)" : "yes"}`);
  if (cliPacks.length > 0 && clientTarget) {
    const plugins = cliPacks.flatMap(({ cli }) =>
      (cli.plugins || []).map((p) => pluginName(p))
    );
    log(`  client plugins merged into ${clientTarget}: ${plugins.join(", ")}`);
    log(`  client config changed: ${clientChanged ? "yes" : "no (already merged)"}`);
  }
}

main().catch((e) => die(e.message || String(e)));
