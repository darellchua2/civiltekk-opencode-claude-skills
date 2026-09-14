// installer/tui-primitives.mjs
//
// Zero-dependency interactive terminal UI primitives, EXTRACTED from tui.mjs so
// other tools (installer/init.mjs) can import singleSelect/multiSelect/textInput/
// confirm + the model flows WITHOUT triggering tui.mjs's top-level dispatch
// (which calls process.exit on import). tui.mjs now re-imports from here.
//
// Node built-ins only. Works on macOS / Linux / Windows-GitBash / PowerShell.
// Non-TTY / piped stdin: the select/confirm primitives return { aborted, nonTty }.

import readline from "node:readline";
import { readFile, writeFile, mkdir, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, basename, join } from "node:path";
import { spawnSync } from "node:child_process";

// ─────────────────────────── arg parsing ────────────────────────────────
export function parseArgs(argv) {
  const opts = {};
  const flags = new Set(["yes", "verbose"]);
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith("--")) {
      const key = a.slice(2).replace(/-([a-z])/g, (_, c) => c.toUpperCase());
      if (flags.has(key)) opts[key] = true;
      else opts[key] = argv[++i];
    } else {
      rest.push(a);
    }
  }
  return { opts, rest };
}

export async function readJsonMaybe(p) {
  if (!p) return null;
  try {
    const txt = await readFile(p, "utf8");
    return JSON.parse(txt.replace(/^[ \t]*"\$comment"[ \t]*:.*$(\r?\n)?/gm, ""));
  } catch (e) {
    return null;
  }
}

// ─────────────────────────── TTY primitives ─────────────────────────────
export const isTTY = () => process.stdin.isTTY && process.stdout.isTTY;
const hide = () => process.stdout.write("\x1b[?25l");
const show = () => process.stdout.write("\x1b[?25h");
function clearN(n) {
  for (let i = 0; i < n; i++) process.stdout.write("\x1b[1A\x1b[2K");
}

// Track whether raw mode was entered, so the exit safety-net only restores the
// terminal when a select actually engaged raw mode (prevents ANSI escapes like
// [?25h from leaking onto stdout and corrupting JSON output in non-TUI callers).
let _rawEntered = false;
export function _markRawEntered() { _rawEntered = true; }

// Safety net: ALWAYS restore the terminal on exit, even if a flow throws.
process.on("exit", () => {
  if (!_rawEntered) return; // no select ran — nothing to restore, keep stdout clean
  try { if (process.stdin.setRawMode) process.stdin.setRawMode(false); } catch {}
  process.stdout.write("\x1b[?25h");
});
process.on("SIGINT", () => { if (_rawEntered) { try { process.stdin.setRawMode(false); } catch {} } process.stdout.write("\x1b[?25h\n"); process.exit(130); });

export const B = (s) => `\x1b[1m${s}\x1b[0m`;
export const DIM = (s) => `\x1b[2m${s}\x1b[0m`;
export const CY = (s) => `\x1b[36m${s}\x1b[0m`;

export async function singleSelect(title, options, defaultIdx = 0) {
  // options: [{label, value, hint?}]
  if (!isTTY()) return { aborted: true, nonTty: true };
  _markRawEntered();
  let idx = Math.min(Math.max(defaultIdx, 0), Math.max(options.length - 1, 0));
  let lineCount = 0;
  process.stdin.setRawMode(true);
  process.stdin.resume();
  readline.emitKeypressEvents(process.stdin);
  hide();
  const render = () => {
    if (lineCount) clearN(lineCount + 1);
    const lines = [B(title), ""];
    options.forEach((o, i) => {
      const sel = i === idx;
      const mark = sel ? `${CY("❯")}` : " ";
      const label = sel ? CY(o.label) : DIM(o.label);
      lines.push(`  ${mark} ${label}${o.hint ? "  " + DIM(o.hint) : ""}`);
    });
    lines.push("", DIM("  ↑/↓ navigate · Enter select · Esc cancel"));
    const text = lines.join("\n") + "\n";
    lineCount = text.split("\n").length - 1;
    process.stdout.write("\n" + text);
  };
  return new Promise((resolve) => {
    const cleanup = () => {
      process.stdin.removeListener("keypress", onKey);
      try { process.stdin.setRawMode(false); } catch {}
      show();
      if (lineCount) clearN(lineCount + 1);
      process.stdout.write("\n");
    };
    const onKey = (str, key) => {
      if (key.ctrl && key.name === "c") { cleanup(); process.exit(130); }
      else if (key.name === "up") { idx = (idx - 1 + options.length) % options.length; render(); }
      else if (key.name === "down") { idx = (idx + 1) % options.length; render(); }
      else if (key.name === "return") { cleanup(); resolve({ value: options[idx].value, index: idx }); }
      else if (key.name === "escape") { cleanup(); resolve({ aborted: true }); }
    };
    process.stdin.on("keypress", onKey);
    render();
  });
}

export async function multiSelect(title, options) {
  // options: [{label, value, checked?, locked?}]  — locked items can't be toggled
  if (!isTTY()) return { aborted: true, nonTty: true };
  _markRawEntered();
  let idx = 0;
  const checked = options.map((o) => !!o.checked);
  let lineCount = 0;
  process.stdin.setRawMode(true);
  process.stdin.resume();
  readline.emitKeypressEvents(process.stdin);
  hide();
  const render = () => {
    if (lineCount) clearN(lineCount + 1);
    const lines = [B(title), ""];
    options.forEach((o, i) => {
      const sel = i === idx;
      const mark = sel ? CY("❯") : " ";
      const box = checked[i] ? `${CY(o.locked ? "🔒" : "◉")}` : "◯";
      const label = sel ? CY(o.label) : DIM(o.label);
      lines.push(`  ${mark} ${box} ${label}`);
    });
    lines.push("", DIM("  ↑/↓ navigate · Space toggle · a all · Enter done · Esc cancel"));
    const text = lines.join("\n") + "\n";
    lineCount = text.split("\n").length - 1;
    process.stdout.write("\n" + text);
  };
  return new Promise((resolve) => {
    const cleanup = () => {
      process.stdin.removeListener("keypress", onKey);
      try { process.stdin.setRawMode(false); } catch {}
      show();
      if (lineCount) clearN(lineCount + 1);
      process.stdout.write("\n");
    };
    const onKey = (str, key) => {
      if (key.ctrl && key.name === "c") { cleanup(); process.exit(130); }
      else if (key.name === "up") { idx = (idx - 1 + options.length) % options.length; render(); }
      else if (key.name === "down") { idx = (idx + 1) % options.length; render(); }
      else if (key.name === "space") { if (!options[idx].locked) { checked[idx] = !checked[idx]; render(); } }
      else if (key.sequence === "a") { const all = !checked.every(Boolean); for (let i = 0; i < checked.length; i++) if (!options[i].locked) checked[i] = all; render(); }
      else if (key.name === "return") { cleanup(); resolve({ selected: options.filter((_, i) => checked[i]).map((o) => o.value) }); }
      else if (key.name === "escape") { cleanup(); resolve({ aborted: true }); }
    };
    process.stdin.on("keypress", onKey);
    render();
  });
}

export async function textInput(prompt, defaultValue = "") {
  if (!isTTY()) return { aborted: true, nonTty: true };
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(`${B(prompt)} ${defaultValue ? `[${DIM(defaultValue)}]` : ""}: `, (ans) => {
      rl.close();
      resolve({ value: (ans || defaultValue).trim() });
    });
  });
}

export async function confirm(prompt, defYes = false) {
  if (!isTTY()) return { aborted: true, nonTty: true };
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(`${B(prompt)} (${defYes ? "Y/n" : "y/N"}): `, (ans) => {
      rl.close();
      const y = (ans || "").toLowerCase();
      resolve({ value: y === "y" || y === "yes" || (defYes && y === "") });
    });
  });
}

// ─────────────────────────── frontmatter reader ─────────────────────────
export function readFrontmatterModel(content) {
  const lines = content.split(/\r?\n/);
  if (!lines.length || lines[0].trim() !== "---") return null;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") break;
    const m = lines[i].match(/^model\s*:\s*(.+?)\s*$/);
    if (m) return m[1].trim();
  }
  return null;
}

// ─────────────────────────── model flows (v2.0) ─────────────────────────
export const CATEGORIES = ["primary", "reasoning", "fast", "docs", "vision"];

export async function pickCategoryModel(category, currentModel, presets) {
  const options = [];
  let defaultIdx = 0;
  for (const key of Object.keys(presets)) {
    if (key.startsWith("$")) continue;
    const model = category === "primary" ? presets[key].primary : (presets[key].tiers && presets[key].tiers[category]);
    if (!model || model.includes("<")) continue;
    if (model === currentModel) defaultIdx = options.length;
    options.push({ label: `${presets[key].label || key}: ${model}`, value: model });
  }
  const customIdx = options.length;
  options.push({ label: "Custom (type a model id)", value: "__custom__" });
  const sel = await singleSelect(
    `Model for ${category}` + (currentModel ? `  ${DIM("(current: " + currentModel + ")")}` : ""),
    options, defaultIdx
  );
  if (sel.aborted) return currentModel;
  if (sel.value === "__custom__") {
    const t = await textInput(`Custom model id for ${category} (provider/model-id)`, currentModel);
    return (t.aborted || !t.value) ? currentModel : t.value;
  }
  return sel.value;
}

export async function customizeCategories(baseMap, presets) {
  const out = { primary: baseMap.primary, tiers: { ...baseMap.tiers } };
  for (const cat of CATEGORIES) {
    const cur = cat === "primary" ? out.primary : out.tiers[cat];
    const chosen = await pickCategoryModel(cat, cur, presets);
    if (cat === "primary") out.primary = chosen; else out.tiers[cat] = chosen;
  }
  return out;
}

export async function flowProviderPicker({ opts }) {
  const presets = await readJsonMaybe(opts.presets);
  if (!presets) { console.error("error: --presets file missing/invalid"); process.exit(2); }
  let chosen;
  let interactive = false;
  if (opts.provider && presets[opts.provider] && !opts.customize) {
    chosen = opts.provider;
  } else {
    interactive = true;
    const keys = Object.keys(presets).filter((k) => !k.startsWith("$"));
    const options = keys.map((k) => ({ label: presets[k].label || k, value: k, hint: presets[k].primary }));
    const startIdx = (opts.provider && presets[opts.provider]) ? keys.indexOf(opts.provider) : 0;
    const sel = await singleSelect("Select a base model provider", options, startIdx);
    if (sel.aborted) { console.error("cancelled"); process.exit(1); }
    chosen = sel.value;
  }
  const preset = presets[chosen];
  let out = { primary: preset.primary, tiers: preset.tiers };
  if (interactive && isTTY()) {
    const c = await confirm("Customize individual categories to other providers/models?", false);
    if (!c.aborted && c.value) out = await customizeCategories(out, presets);
  }
  if (opts.out) {
    await mkdir(dirname(opts.out), { recursive: true });
    await writeFile(opts.out, JSON.stringify(out, null, 2) + "\n", "utf8");
    console.log(`Wrote ${opts.out} (${chosen}${out.primary !== preset.primary || JSON.stringify(out.tiers) !== JSON.stringify(preset.tiers) ? " +customized" : ""})`);
  } else {
    console.log(JSON.stringify({ provider: chosen, map: out }));
  }
}

export async function flowMigrationReview({ opts, rest }) {
  const resolverPath = opts.resolver;
  const agentsDest = opts.agentsDest;
  if (!resolverPath || !agentsDest) {
    console.error("error: migration-review requires --resolver <resolve-models.mjs> --agents-dest <dir>");
    process.exit(2);
  }
  const resolverFlags = [
    "agentsSrc", "agentsDest", "tiers", "defaultMap", "userMap", "projectMap",
    "overrides", "projectOverrides", "configSrc", "configDest", "state",
    "provider", "presets", "force",
  ];
  const kebab = (k) => k.replace(/[A-Z]/g, (m) => "-" + m.toLowerCase());
  const resolverArgs = [];
  for (const k of resolverFlags) {
    if (opts[k] === true) resolverArgs.push("--" + kebab(k));
    else if (opts[k]) resolverArgs.push("--" + kebab(k), opts[k]);
  }
  resolverArgs.push("--json", "--dry-run");
  const res = spawnSync(process.execPath, [resolverPath, ...resolverArgs], { encoding: "utf8" });
  if (res.status !== 0 || !res.stdout) { console.error("resolver failed:"); console.error(res.stderr || res.stdout); process.exit(2); }
  let data;
  try { data = JSON.parse(res.stdout); }
  catch { console.error("could not parse resolver output"); process.exit(2); }
  const before = {};
  if (existsSync(agentsDest)) {
    for (const f of (await readdir(agentsDest)).filter((f) => f.endsWith(".md"))) {
      const stem = basename(f, ".md");
      const content = await readFile(join(agentsDest, f), "utf8");
      const m = readFrontmatterModel(content);
      if (m) before[stem] = m;
    }
  }
  const cStem = Math.max(5, ...data.agents.map((a) => a.stem.length));
  const cModel = 30;
  const pad = (s, w) => (s + " ".repeat(w)).slice(0, w);
  const lines = [];
  const _providerName = data.provider || "default";
  lines.push(B("v2.0 migration preview") + DIM("  (provider: " + _providerName + ")"));
  lines.push(`${pad("AGENT", cStem)}  ${pad("CURRENT", cModel)} -> ${pad("RESOLVED", cModel)}  TIER`);
  lines.push("-".repeat(cStem + cModel * 2 + 14));
  for (const a of data.agents) {
    const cur = before[a.stem] ? pad(before[a.stem], cModel) : DIM(pad("(new)", cModel));
    const after = a.model === "(preserved)" ? DIM(pad(a.model, cModel)) : pad(a.model || "-", cModel);
    lines.push(`${pad(a.stem, cStem)}  ${cur} -> ${after}  ${a.tier || "-"}`);
  }
  lines.push("-".repeat(cStem + cModel * 2 + 14));
  lines.push(`Primary: ${data.primary}    ${data.written} write · ${data.preserved} preserve · ${data.skipped} skip`);
  console.log(lines.join("\n"));
  if (opts.yes) { console.log(DIM("--yes set, proceeding")); return; }
  const c = await confirm("Proceed with migration?", false);
  if (c.aborted || !c.value) { console.error("aborted"); process.exit(1); }
}

export async function flowOverrideEditor({ opts }) {
  const tiersDoc = await readJsonMaybe(opts.tiers);
  if (!tiersDoc) { console.error("error: --tiers file missing/invalid"); process.exit(2); }
  const existing = (await readJsonMaybe(opts.out)) || {};
  const stems = Object.keys(tiersDoc.tiers).sort();
  const options = stems.map((s) => ({
    label: `${s}  [${tiersDoc.tiers[s]}]${existing[s] ? `  -> ${existing[s].model}` : ""}`,
    value: s,
  }));
  const sel = await multiSelect("Select agents to pin a custom model (Esc to finish)", options);
  if (sel.aborted) { console.error("cancelled"); process.exit(1); }
  const result = {};
  for (const stem of sel.selected) {
    const t = await textInput(`Model for ${stem} (provider/model-id)`, existing[stem] && existing[stem].model || "");
    if (t.aborted || !t.value) continue;
    result[stem] = { model: t.value };
  }
  if (opts.out) {
    await mkdir(dirname(opts.out), { recursive: true });
    await writeFile(opts.out, JSON.stringify(result, null, 2) + "\n", "utf8");
    console.log(`Wrote ${opts.out} (${Object.keys(result).length} override(s))`);
  } else {
    console.log(JSON.stringify(result));
  }
}

export async function flowTierEditor({ opts }) {
  const presets = await readJsonMaybe(opts.presets);
  if (!presets || !opts.provider || !presets[opts.provider]) {
    console.error("error: --presets and --provider <name> required"); process.exit(2);
  }
  const base = presets[opts.provider];
  const out = { primary: base.primary, tiers: { ...base.tiers } };
  for (const cat of CATEGORIES) {
    const cur = cat === "primary" ? out.primary : out.tiers[cat];
    const chosen = await pickCategoryModel(cat, cur, presets);
    if (cat === "primary") out.primary = chosen; else out.tiers[cat] = chosen;
  }
  if (opts.out) {
    await mkdir(dirname(opts.out), { recursive: true });
    await writeFile(opts.out, JSON.stringify(out, null, 2) + "\n", "utf8");
    console.log(`Wrote ${opts.out}`);
  } else {
    console.log(JSON.stringify(out));
  }
}
