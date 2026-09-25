#!/usr/bin/env node
// deploy/tui.mjs
//
// Zero-dependency interactive terminal UI dispatcher for the v2.0 model system.
// The primitives + flows live in installer/tui-primitives.mjs (extracted so other
// tools like installer/init.mjs can import them WITHOUT triggering this dispatch,
// which calls process.exit on run).
//
// Flows (first positional arg):
//   provider-picker   Arrow-key select a provider preset; write models.json
//   migration-review  Show before/after table (via resolver --json), confirm
//   override-editor   Pick agents to pin with a custom model
//   tier-editor       Edit the model of each tier for a chosen provider
//
// Non-TTY / piped stdin: flows exit non-zero (except migration-review with --yes).

import {
  parseArgs, flowProviderPicker, flowMigrationReview, flowOverrideEditor, flowTierEditor,
} from "../installer/tui-primitives.mjs";

const flow = process.argv[2];
const parsed = parseArgs(process.argv.slice(3));
(async () => {
  switch (flow) {
    case "provider-picker": await flowProviderPicker(parsed); break;
    case "select-items": await flowSelectItems(parsed); break;
    case "migration-review": await flowMigrationReview(parsed); break;
    case "override-editor": await flowOverrideEditor(parsed); break;
    case "tier-editor": await flowTierEditor(parsed); break;
    default:
      console.error("usage: tui.mjs <provider-picker|migration-review|override-editor|tier-editor|select-items> [opts]");
      process.exit(2);
  }
  // Explicit exit — singleSelect/multiSelect resume stdin for keypress capture,
  // and a resumed stdin handle would keep node alive (hanging the caller's `&&`).
  // Drain stdout first: a pending async pipe write (e.g. --print-plan's 20KB+
  // JSON) is truncated at the pipe-buffer boundary by process.exit (#564 —
  // file redirects flush synchronously, which is why this only bit pipes).
  if (process.stdout.writableLength > 0) {
    await new Promise((resolve) => process.stdout.write("", resolve));
  }
  process.exit(0);
})().catch((e) => { console.error(`tui error: ${e.message}`); process.exit(1); });

// ───────────────────────── select-items (#473) ─────────────────────────
// Per-item deploy picker. Three drivers over installer/deploy-plan-items.mjs:
//   dashboard (opentui, interactive TTY, node >= 26.4)
//   linear    (readline prompts — fallback; --driver linear forces it)
//   print-plan (--print-plan + item flags: headless, zero TTY reads)
// All three emit the SAME selection-plan JSON (equivalence is test-pinned).

import { buildInventory, buildSelectionPlan, EXTRA_ITEMS, scanPackNames, scanPluginNames } from "../installer/deploy-plan-items.mjs";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

function loadPickerData() {
  const INIT_DIR = join(dirname(fileURLToPath(import.meta.url)), "..", "installer");
  const registry = JSON.parse(readFileSync(join(INIT_DIR, "registry.json"), "utf8"));
  const depMap = JSON.parse(readFileSync(join(INIT_DIR, "dependency-map.json"), "utf8"));
  const packsDir = join(dirname(fileURLToPath(import.meta.url)), "packs");
  const packNames = scanPackNames(packsDir);
  const pluginsDir = join(dirname(fileURLToPath(import.meta.url)), "..", "plugins");
  const pluginNames = scanPluginNames(pluginsDir);
  const inventory = buildInventory({ registry, packNames, pluginNames });
  return { registry, depMap, inventory, packNames, pluginNames };
}

function planFromFlags(parsed) {
  const list = (v) => (v ? String(v).split(",").map((x) => x.trim()).filter(Boolean) : []);
  if (parsed.defaults) {
    // First-run defaults (#473): lean-profile skills + all agents + core
    // plugins pre-checked; packs mirror the main deploy default (none).
    // Lean list comes from the shipped skill profile.
    let lean = [];
    try {
      const profiles = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "skill-profiles.json"), "utf8"));
      lean = profiles.lean || profiles.leanSkills || [];
    } catch { /* no profile file — empty lean list */ }
    // Scanners come from loadPickerData (shared scanPackNames/scanPluginNames)
    // — defaults and the interactive inventory can never drift again (#537).
    const { registry, depMap, packNames, pluginNames } = loadPickerData();
    const allAgents = registry.agents.map((a) => a.stem);
    const plan = buildSelectionPlan({ choices: { skills: lean, agents: allAgents, packs: packNames, plugins: pluginNames, extras: [] }, registry, depMap });
    return { skills: plan.skills.map((s) => s.name), agents: plan.agents.map((a) => a.name), packs: plan.packs, plugins: plan.plugins, extras: [] };
  }
  return {
    skills: list(parsed.skills),
    agents: list(parsed.agents),
    packs: list(parsed.packs),
    plugins: list(parsed.plugins),
    extras: list(parsed.extras),
  };
}

async function flowSelectItems(_parsed) {

  // Local arg parsing: the shared parseArgs has a fixed bool-flag set, and
  // --print-plan/--defaults are booleans while --driver/--out/--skills… take
  // values — getting that wrong silently swallows the next flag (#473).
  const BOOL = new Set(["printPlan", "defaults"]);
  const VALUE = new Set(["driver", "out", "skills", "agents", "packs", "plugins", "extras"]);
  const parsed = {};
  const raw = process.argv.slice(3);
  for (let i = 0; i < raw.length; i++) {
    const a = raw[i];
    if (!a.startsWith("--")) continue;
    const key = a.slice(2).replace(/-([a-z])/g, (_, c) => c.toUpperCase());
    if (BOOL.has(key)) parsed[key] = true;
    else if (VALUE.has(key)) parsed[key] = raw[++i];
  }

  const { registry, depMap, inventory } = loadPickerData();

  if (parsed.printPlan) {
    const plan = buildSelectionPlan({ choices: planFromFlags(parsed), registry, depMap });
    console.log(JSON.stringify(plan, null, 2));
    return;
  }

  const [maj, min] = process.versions.node.split(".").map(Number);
  const canDashboard = parsed.driver !== "linear" && process.stdout.isTTY && (maj > 26 || (maj === 26 && min >= 4));
  if (canDashboard) {
    try {
      await dashboardSelectItems(parsed, registry, depMap, inventory);
      return;
    } catch (err) {
      console.error(`dashboard unavailable (${err.message}) — falling back to linear prompts`);
    }
  }
  await linearSelectItems(parsed, registry, depMap, inventory);
}

function planChoicesToText(plan) {
  const parts = [];
  for (const [group, items] of Object.entries({ skills: plan.skills, agents: plan.agents, mcps: plan.mcps })) {
    parts.push(`${group}: ${items.map((i) => `${i.name} (${i.source})`).join(", ") || "(none)"}`);
  }
  parts.push(`packs: ${plan.packs.join(", ") || "(none)"}`);
  parts.push(`plugins: ${plan.plugins.join(", ") || "(none)"}`);
  parts.push(`extras: ${plan.extras.join(", ") || "(none)"}`);
  return parts.join("\n");
}

async function dashboardSelectItems(parsed, registry, depMap, inventory) {
  const { createCliRenderer, TextRenderable } = await import("@opentui/core");
  const { buildSelectionPlan } = await import("../installer/deploy-plan-items.mjs");

  // Flatten the DAG-ordered groups into a navigable line model.
  const lines = []; // {kind: "group"|"item", group, id, label, disabled?}
  for (const group of inventory.groups) {
    lines.push({ kind: "group", label: group.label });
    if (group.id === "skills") {
      for (const cat of group.items) {
        lines.push({ kind: "subgroup", label: `  [${cat.label}] (${cat.items.length})`, itemIds: cat.items.map((i) => i.id), itemGroup: "skills" });
        for (const item of cat.items) lines.push({ kind: "item", group: "skills", id: item.id, label: `    ${item.id}` });
      }
    } else if (group.id === "agents") {
      for (const tier of group.items) {
        lines.push({ kind: "subgroup", label: `  [${tier.label}] (${tier.items.length})`, itemIds: tier.items.map((i) => i.id), itemGroup: "agents" });
        for (const item of tier.items) lines.push({ kind: "item", group: "agents", id: item.id, label: `    ${item.id}` });
      }
    } else {
      for (const item of group.items) lines.push({ kind: "item", group: group.id, id: item.id, label: `  ${item.id}`, locked: group.id === "packs" ? "requires its matching pack merge step" : undefined });
    }
  }
  lines.push({ kind: "confirm", label: "  ▶ Confirm selection (emit plan)" });

  const selected = new Set();
  let cursor = 0;
  let viewportTop = 0;
  let done = false, cancelled = false;

  function choicesFromSelection() {
    const choices = { skills: [], agents: [], packs: [], plugins: [], extras: [] };
    for (const line of lines) {
      if (line.kind !== "item" || !selected.has(`${line.group}:${line.id}`)) continue;
      choices[line.group].push(line.id);
    }
    return choices;
  }

  function renderView() {
    const H = process.stdout.rows || 24;
    if (cursor < viewportTop) viewportTop = cursor;
    if (cursor >= viewportTop + H - 4) viewportTop = cursor - (H - 5);
    const out = [];
    out.push("Select deploy items  (↑/↓ move · space toggle · a all-in-group · n none-in-group · enter confirm · q quit)");
    for (let i = viewportTop; i < Math.min(lines.length, viewportTop + H - 3); i++) {
      const line = lines[i];
      const cursorMark = i === cursor ? ">" : " ";
      if (line.kind === "group" || line.kind === "subgroup") { out.push(`${cursorMark} ${line.label}`); continue; }
      if (line.kind === "confirm") { out.push(`${cursorMark}${line.label}`); continue; }
      const mark = selected.has(`${line.group}:${line.id}`) ? "[x]" : "[ ]";
      out.push(`${cursorMark} ${mark} ${line.label.trim()}${line.locked ? "   (locked: " + line.locked + ")" : ""}`);
    }
    return out.join("\n");
  }

  const renderer = await createCliRenderer({});
  const view = new TextRenderable(renderer, { content: renderView() });
  renderer.root.add(view);

  const finish = (ok) => { done = true; renderer.destroy(); if (!ok) cancelled = true; };
  renderer.keyInput.on("keypress", (event) => {
    if (event.name === "up") cursor = Math.max(0, cursor - 1);
    else if (event.name === "down") cursor = Math.min(lines.length - 1, cursor + 1);
    else if (event.name === "space") {
      const line = lines[cursor];
      if (line.kind === "item") {
        const key = `${line.group}:${line.id}`;
        if (selected.has(key)) selected.delete(key); else selected.add(key);
      } else if (line.kind === "subgroup") {
        // bulk-toggle the subgroup's items
        for (const id of line.itemIds || []) {
          const key = `${line.itemGroup}:${id}`;
          if (selected.has(key)) selected.delete(key); else selected.add(key);
        }
      }
    } else if (event.name === "a" || event.name === "n") {
      // all/none within the group of the cursor's nearest item
      let g = null;
      for (let i = cursor; i >= 0; i--) { if (lines[i].kind === "item") { g = lines[i].group; break; } if (lines[i].kind === "group") { g = lines[i].id || null; break; } }
      if (g) for (const l of lines) if (l.kind === "item" && l.group === g) {
        const key = `${l.group}:${l.id}`;
        if (event.name === "a") selected.add(key); else selected.delete(key);
      }
    } else if (event.name === "enter") {
      const line = lines[cursor];
      if (line.kind === "confirm") { finish(true); return; }
      if (line.kind === "item") {
        const key = `${line.group}:${line.id}`;
        if (selected.has(key)) selected.delete(key); else selected.add(key);
      }
    } else if (event.name === "q" || (event.name === "c" && event.ctrl)) {
      finish(false); return;
    }
    view.content = renderView();
    renderer.requestRender();
  });

  await new Promise((resolve) => {
    const t = setInterval(() => { if (done) { clearInterval(t); resolve(); } }, 50);
  });
  if (cancelled) { console.error("selection cancelled"); process.exit(1); }

  const plan = buildSelectionPlan({ choices: choicesFromSelection(), registry, depMap });
  const outText = JSON.stringify(plan, null, 2);
  if (parsed.out) { (await import("node:fs")).writeFileSync(parsed.out, outText); }
  else console.log(outText);
  console.error(planChoicesToText(plan));
}

async function linearSelectItems(parsed, registry, depMap, inventory) {
  const readline = await import("node:readline");
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  // Queue-based asks: readline emits piped lines faster than sequential
  // questions attach — a direct rl.question per ask drops buffered lines.
  const queued = [];
  let eof = false;
  const waiters = [];
  rl.on("line", (line) => {
    if (waiters.length) waiters.shift()(line);
    else queued.push(line);
  });
  rl.on("close", () => {
    eof = true;
    while (waiters.length) waiters.shift()(null);
  });
  const ask = async (q) => {
    // Prompts are UI — stderr keeps stdout pure JSON for the equivalence pin.
    process.stderr.write(q);
    if (queued.length) return queued.shift();
    if (eof) return null;
    return new Promise((res) => waiters.push(res));
  };
  try {
    const choices = { skills: [], agents: [], packs: [], plugins: [], extras: [] };
    for (const group of inventory.groups) {
      console.error(`\n== ${group.label} ==`);
      const answer = await ask(`  (a)ll / (s)kip / (l)ist items? [a/s/l]: `);
      if (answer === null) throw new Error("stdin closed - linear selection aborted (use --print-plan --defaults for headless)");
      const mode = answer.trim().toLowerCase();
      // Empty/unknown answers SKIP — an accidental Enter must not install the
      // entire catalog (prompt-eof-takes-default-headless).
      if (mode !== "a" && mode !== "l") continue;
      if (mode === "l") {
        for (const item of group.items.flatMap((c) => c.items || [c])) {
          const yn = await ask(`  include ${item.id}? [y/N]: `);
          if (yn === null) throw new Error("stdin closed - linear selection aborted");
          if (yn.trim().toLowerCase() === "y") choices[group.id].push(item.id);
        }
      } else if (mode === "a") {
        for (const item of group.items.flatMap((c) => c.items || [c])) choices[group.id].push(item.id);
      }
    }
    const plan = buildSelectionPlan({ choices, registry, depMap });
    const outText = JSON.stringify(plan, null, 2);
    if (parsed.out) { (await import("node:fs")).writeFileSync(parsed.out, outText); }
    else console.log(outText);
    console.error(planChoicesToText(plan));
  } finally {
    rl.close();
  }
}
