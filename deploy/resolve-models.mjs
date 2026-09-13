#!/usr/bin/env node
// deploy/resolve-models.mjs
//
// v2.0 model resolver. Source agent .md files are model-free; each agent's tier
// lives in deploy/agent-tiers.json. This resolver reads the tier registry, the
// default tier->model map, optional user/project tier maps and per-agent
// overrides, then injects a concrete `model:` into each deployed agent .md
// frontmatter and patches the deployed opencode.json (explore/general always;
// top-level `model` only with --inject-primary, e.g. Docker — local deploys
// ship no baked-in primary so the end user picks at runtime).
//
// Zero external dependencies - Node built-ins only (fs, path, process).
//
// Resolution precedence (highest wins):
//   1. project agent-overrides[agent].model
//   2. global agent-overrides[agent].model
//   3. project models.json tiers[<tier>]
//   4. global  models.json tiers[<tier>]
//   5. models.default.json tiers[<tier>]
//
// Usage:
//   node resolve-models.mjs \
//     --agents-src <dir> --agents-dest <dir> \
//     --tiers <agent-tiers.json> --default-map <models.default.json> \
//     [--user-map <~/.config/opencode/models.json>] \
//     [--project-map <./.opencode/models.json>] \
//     [--overrides <~/.config/opencode/agent-overrides.json>] \
//     [--project-overrides <./.opencode/agent-overrides.json>] \
//     [--config-src <opencode.json>] [--config-dest <deployed config.json>] \
//     [--state <.resolved-models.json sidecar>] \
//     [--provider <name> --presets <provider-presets.json>] \
//     [--inject-primary] [--force] [--dry-run] [--preview-dir <path>] [--provider-models <file>] [--verbose] [--json]

import { readFile, writeFile, readdir, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, dirname, basename } from "node:path";

// ─────────────────────────── arg parsing ────────────────────────────────
const camel = (s) => s.replace(/-([a-z])/g, (_, c) => c.toUpperCase());

function parseArgsCamel(argv) {
  const out = {
    agentsSrc: null, agentsDest: null,
    tiers: null, defaultMap: null,
    userMap: null, projectMap: null,
    overrides: null, projectOverrides: null,
    configSrc: null, configDest: null,
    state: null, provider: null, presets: null, providerModels: null,
    force: false, dryRun: false, verbose: false, json: false, injectPrimary: false,
  };
  const boolKeys = new Set(["force", "dryRun", "verbose", "json", "liftOnly", "injectPrimary"]);
  for (let i = 0; i < argv.length; i++) {
    let a = argv[i];
    if (!a.startsWith("--")) continue;
    let key = a.slice(2);
    key = camel(key);
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

// tolerate $comment keys + trailing commas minimally (our own files use $comment)
function stripJsonComments(txt) {
  // Remove `"$comment": "...",` lines (with optional trailing comma) - our data files use these.
  return txt.replace(/^[ \t]*"\$comment"[ \t]*:.*$(\r?\n)?/gm, "");
}

function readFrontmatterModel(content) {
  const lines = content.split(/\r?\n/);
  if (lines[0] === undefined || lines[0].trim() !== "---") return null;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") break;
    const m = lines[i].match(/^model\s*:\s*(.+?)\s*$/);
    if (m) return m[1].trim();
  }
  return null;
}

// Inject/replace a single `model: <value>` line in the frontmatter.
function injectModel(content, modelValue) {
  const lines = content.split(/\r?\n/);
  if (lines.length === 0 || lines[0].trim() !== "---") {
    // No frontmatter at all - create a minimal one.
    return `---\nmodel: ${modelValue}\n---\n${content}`;
  }
  let closeIdx = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") { closeIdx = i; break; }
  }
  if (closeIdx === -1) {
    // Malformed (no closing fence) - leave content untouched, surface error upstream.
    throw new Error("Frontmatter has no closing ---");
  }
  const fmBody = lines.slice(1, closeIdx).filter((l) => !/^model\s*:/.test(l));
  fmBody.unshift(`model: ${modelValue}`);
  const out = [lines[0], ...fmBody, ...lines.slice(closeIdx)];
  return out.join("\n");
}

// ─────────────────────────── main ───────────────────────────────────────
async function main() {
  // lift-only needs fewer args than a full resolve
  const required = O.liftOnly
    ? ["agentsDest", "defaultMap"]
    : ["agentsSrc", "agentsDest", "tiers", "defaultMap"];
  for (const k of required) {
    if (!O[k]) {
      console.error(`error: --${k.replace(/([A-Z])/g, "-$1").toLowerCase()} is required`);
      process.exit(2);
    }
  }

  const tiersDoc = await readJsonMaybe(O.tiers);
  const defaultMap = await readJsonMaybe(O.defaultMap);
  const userMap = await readJsonMaybe(O.userMap);
  const projectMap = await readJsonMaybe(O.projectMap);
  const overrides = (await readJsonMaybe(O.overrides)) || {};
  const projectOverrides = (await readJsonMaybe(O.projectOverrides)) || {};
  const state = (await readJsonMaybe(O.state)) || {};
  const providerModelsMap = await readJsonMaybe(O.providerModels);

  // Provider shortcut: presets[provider] acts as a (global) tier map override.
  let providerMap = null;
  if (O.provider) {
    if (!O.presets) {
      console.error("error: --provider requires --presets <provider-presets.json>");
      process.exit(2);
    }
    const presets = await readJsonMaybe(O.presets);
    providerMap = presets && presets[O.provider];
    if (!providerMap) {
      console.error(`error: provider "${O.provider}" not found in ${O.presets}`);
      process.exit(2);
    }
  }

  // ── lift-only mode: scan deployed agents for non-default customizations and
  // write them to the overrides file (used by v1.x -> v2.0 migration). No model
  // injection, no config patch, no sidecar. Exits after writing.
  if (O.liftOnly) {
    if (!O.agentsDest || !O.defaultMap) {
      console.error("error: --lift-only requires --agents-dest <dir> --default-map <file>");
      process.exit(2);
    }
    const defaultTiersSet = (defaultMap && defaultMap.tiers) || {};
    const known = new Set([defaultMap && defaultMap.primary, ...Object.values(defaultTiersSet)]);
    const existing = (await readJsonMaybe(O.overrides)) || {};
    let lifted = 0;
    if (existsSync(O.agentsDest)) {
      for (const f of (await readdir(O.agentsDest)).filter((x) => x.endsWith(".md"))) {
        const stem = basename(f, ".md");
        const content = await readFile(join(O.agentsDest, f), "utf8");
        const m = readFrontmatterModel(content);
        if (m && !known.has(m)) { existing[stem] = { model: m }; lifted++; }
      }
    }
    if (O.overrides && !O.dryRun) {
      await mkdir(dirname(O.overrides), { recursive: true });
      await writeFile(O.overrides, JSON.stringify(existing, null, 2) + "\n", "utf8");
    }
    console.log(`${O.dryRun ? "[DRY-RUN] " : ""}Lifted ${lifted} customization(s) ${O.dryRun ? "(not written)" : "into " + O.overrides}`);
    return;
  }

  const tierOf = (tiersDoc && tiersDoc.tiers) || {};
  const defaultTiers = (defaultMap && defaultMap.tiers) || {};
  const userTiers = (userMap && userMap.tiers) || {};
  const projectTiers = (projectMap && projectMap.tiers) || {};
  const providerTiers = (providerMap && providerMap.tiers) || {};

  // Effective tier model: project > provider > user > default
  function tierModel(tier) {
    return projectTiers[tier] ?? providerTiers[tier] ?? userTiers[tier] ?? defaultTiers[tier] ?? null;
  }
  function effectivePrimary() {
    // Explicit choices (project/provider/user override) always win. The bare
    // default (models.default.json `primary`) is only used when --inject-primary
    // is passed (Docker build). Local deploys omit it so the deployed config
    // ships no top-level `model` — the end user picks at runtime.
    return (projectMap && projectMap.primary)
      ?? (providerMap && providerMap.primary)
      ?? (userMap && userMap.primary)
      ?? (O.injectPrimary ? (defaultMap && defaultMap.primary) : null)
      ?? null;
  }
  // Per-agent resolution: project override > global override > tier model
  function resolveAgent(stem) {
    const tier = tierOf[stem];
    if (!tier) return { tier: null, model: null, reason: "no-tier" };
    if (projectOverrides[stem] && projectOverrides[stem].model) {
      return { tier, model: projectOverrides[stem].model, reason: "project-override" };
    }
    if (overrides[stem] && overrides[stem].model) {
      return { tier, model: overrides[stem].model, reason: "global-override" };
    }
    const m = tierModel(tier);
    return { tier, model: m, reason: m ? `tier:${tier}` : "unresolved" };
  }

  // Known z.ai default set - used to recognise "pre-sidecar, ours" during preserve checks.
  const knownDefaults = new Set(Object.values(defaultTiers));
  knownDefaults.add(defaultMap && defaultMap.primary);

  // ── resolve agents ──
  const srcFiles = (await readdir(O.agentsSrc))
    .filter((f) => f.endsWith(".md"));

  const rows = []; // {stem, tier, model, reason, action}
  const newState = {};

  for (const f of srcFiles) {
    const stem = basename(f, ".md");
    const srcPath = join(O.agentsSrc, f);
    const destPath = join(O.agentsDest, f);
    const { tier, model, reason } = resolveAgent(stem);

    if (!model) {
      rows.push({ stem, tier, model: null, reason, action: "SKIP (unresolved)" });
      continue;
    }

    let action = "WRITE";
    let preserved = false;
    if (!O.force && existsSync(destPath)) {
      const destContent = await readFile(destPath, "utf8");
      const destModel = readFrontmatterModel(destContent);
      const tracked = state[stem] && state[stem].model;
      if (tracked) {
        // We managed this file before. If the user changed it since, preserve.
        if (destModel && destModel !== tracked) {
          action = "PRESERVE (user-edited)";
          preserved = true;
        }
      } else {
        // No prior state (first run / pre-migration). If the existing model is one
        // of our known defaults, treat as ours and adopt. Otherwise preserve.
        if (destModel && !knownDefaults.has(destModel)) {
          action = "PRESERVE (unknown customization - use --force or add to agent-overrides.json)";
          preserved = true;
        }
      }
    }

    if (!preserved) {
      newState[stem] = { tier, model };
    } else {
      // keep whatever is tracked (or nothing) - do not update state for preserved
      if (state[stem]) newState[stem] = state[stem];
    }

    rows.push({ stem, tier, model: preserved ? "(preserved)" : model, reason, action });
  }

  // ── resolve config (explore/general always; primary only if --inject-primary or explicit override) ──
  const primary = effectivePrimary();
  const exploreModel = tierModel("fast");
  const generalModel = tierModel("reasoning");
  let configPatched = false;
  let configObj = null;
  let sourceConfigPins = null;
  if (O.configDest && (primary || exploreModel || generalModel)) {
    if (O.configSrc && existsSync(O.configSrc)) {
      configObj = await readJsonMaybe(O.configSrc);
    } else if (existsSync(O.configDest)) {
      configObj = await readJsonMaybe(O.configDest);
    }
    if (configObj) {
      // Snapshot raw source-config pins BEFORE patching, for the exposed-model guard.
      sourceConfigPins = {
        "source opencode.json model": configObj.model,
        "source opencode.json agents.explore": configObj.agents && configObj.agents.explore && configObj.agents.explore.model,
        "source opencode.json agents.general": configObj.agents && configObj.agents.general && configObj.agents.general.model,
      };
      if (primary) configObj.model = primary;
      // ponytail: clear stale explicit primary (e.g. removed models.json override)
      else delete configObj.model;
      configObj.agents = configObj.agents || {};
      if (exploreModel) {
        configObj.agents.explore = configObj.agents.explore || {};
        configObj.agents.explore.model = exploreModel;
      }
      if (generalModel) {
        configObj.agents.general = configObj.agents.general || {};
        configObj.agents.general.model = generalModel;
      }
      configPatched = true;
    }
  }

  // ── vision sanity note (cannot truly detect multimodal capability) ──
  const visionStems = Object.entries(tierOf)
    .filter(([, t]) => t === "vision")
    .map(([stem]) => stem);

  // ── output counters ──
  const written = rows.filter((r) => r.action === "WRITE").length;
  const preserved = rows.filter((r) => r.action.startsWith("PRESERVE")).length;
  const skipped = rows.filter((r) => r.action.startsWith("SKIP")).length;

  // Human table (stderr). Suppressed in --json mode so stdout stays clean.
  if (!O.json) {
    const cStem = Math.max(4, ...rows.map((r) => r.stem.length));
    const cTier = Math.max(4, ...rows.map((r) => (r.tier || "-").length));
    const cModel = Math.max(5, ...rows.map((r) => (r.model || "-").length));
    const cAction = Math.max(6, ...rows.map((r) => r.action.length));
    const fmt = (s, w) => (s + " ".repeat(w)).slice(0, w);
    const header = `${fmt("AGENT", cStem)}  ${fmt("TIER", cTier)}  ${fmt("MODEL", cModel)}  ACTION`;
    const bar = "=".repeat(header.length);
    if (O.verbose || O.dryRun) {
      console.error(`${O.dryRun ? "[DRY-RUN] " : ""}Model resolution:`);
      console.error(bar);
      console.error(header);
      console.error(bar);
      for (const r of rows) {
        console.error(`${fmt(r.stem, cStem)}  ${fmt(r.tier || "-", cTier)}  ${fmt(r.model || "-", cModel)}  ${r.action}`);
      }
      console.error(bar);
    }
    console.error(`Primary: ${primary || "-"}  |  explore: ${exploreModel || "-"}  |  general: ${generalModel || "-"}${configPatched ? "  (config patched)" : ""}`);
    console.error(`Summary: ${written} written, ${preserved} preserved, ${skipped} skipped.`);
    if (visionStems.length && O.verbose) {
      console.error(`Note: vision-tier agents [${visionStems.join(", ")}] require a multimodal model.`);
    }
  }

  // ── exposed-model guard (deploy-time fail-fast) ──
  // Validates every resolved model (per-agent + primary/explore/general + raw
  // source-config pins) against provider-models.json, so a tier pinned to a model
  // its provider doesn't serve is caught at deploy — not at first subagent spawn.
  // Skipped when --provider-models is absent (back-compat) or --force is set.
  let guardOffenders = [];
  const guardWarns = [];
  if (providerModelsMap && !O.force) {
    const checkModel = (label, modelStr) => {
      if (!modelStr || modelStr === "(preserved)") return;
      const s = String(modelStr);
      const slash = s.indexOf("/");
      if (slash === -1) {
        guardWarns.push(`guard: ${label} model "${s}" has no provider/ prefix — skipped`);
        return;
      }
      const prov = s.slice(0, slash);
      const mdl = s.slice(slash + 1);
      const list = providerModelsMap[prov];
      if (!list) {
        guardWarns.push(`guard: ${label} provider "${prov}" not in provider-models map — skipped (cannot validate)`);
        return;
      }
      const exposed = new Set(list.map((m) => (typeof m === "string" && m.includes("/") ? m.slice(m.indexOf("/") + 1) : m)));
      if (!exposed.has(mdl)) {
        guardOffenders.push(`${label} pins "${s}" — "${mdl}" NOT exposed by provider "${prov}"`);
      }
    };
    for (const stem of Object.keys(newState)) {
      checkModel(`agent ${stem} (${tierOf[stem] || "?"})`, newState[stem] && newState[stem].model);
    }
    if (primary) checkModel("primary", primary);
    if (exploreModel) checkModel("explore (fast tier)", exploreModel);
    if (generalModel) checkModel("general (reasoning tier)", generalModel);
    if (sourceConfigPins) {
      for (const [label, val] of Object.entries(sourceConfigPins)) checkModel(label, val);
    }
  }
  if (providerModelsMap && guardWarns.length && !O.json) {
    for (const w of guardWarns) console.error(w);
  }
  if (guardOffenders.length) {
    console.error(`\nerror: ${guardOffenders.length} resolved model(s) pinned to a model its provider does not expose:`);
    for (const o of guardOffenders) console.error(`  - ${o}`);
    console.error("Fix the tier map (deploy/models.default.json / deploy/provider-presets.json) or the source opencode.json pin,");
    console.error("or update deploy/provider-models.json. Bypass with --force (not recommended).");
    process.exit(1);
  }

  // Determine where resolved files go and whether to write at all.
  // - apply:                write to real agents-dest + config-dest + state sidecar.
  // - dry-run + preview-dir: stage COMPLETE resolved files (model: injected) into
  //   preview-dir so the user can inspect exactly what would land in ~/.config.
  // - dry-run, no preview-dir: write nothing (still prints the table + a sample).
  const writeRows = rows.filter((r) => r.action === "WRITE" && newState[r.stem] && newState[r.stem].model);
  const outDir = (O.dryRun && O.previewDir) ? O.previewDir : O.agentsDest;
  const doWrite = !O.dryRun || !!O.previewDir;

  // Render the complete resolved content (source .md with model: injected) for one agent.
  async function renderAgent(r) {
    const srcPath = join(O.agentsSrc, r.stem + ".md");
    const content = await readFile(srcPath, "utf8");
    return injectModel(content, newState[r.stem].model);
  }

  // Dry-run: dump ONE complete resolved .md so the user sees the full file with
  // the model: line in place (not just the table).
  if (O.dryRun && writeRows.length && !O.json) {
    const sample = writeRows[0];
    const rendered = await renderAgent(sample);
    const bar = "─".repeat(72);
    console.error("");
    console.error(bar);
    console.error(`[DRY-RUN] Complete resolved preview: ${sample.stem}.md  (model: ${newState[sample.stem].model})`);
    console.error(bar);
    process.stdout.write(rendered);
    if (!rendered.endsWith("\n")) process.stdout.write("\n");
    console.error(bar);
    if (writeRows.length > 1) {
      console.error(`(+ ${writeRows.length - 1} more agent file(s) resolved identically — use --preview-dir to stage them all)`);
    }
  }

  if (O.dryRun && !O.previewDir) {
    if (!O.json) console.error("(dry-run: no files written — pass --preview-dir <path> to stage complete resolved files)");
    // Do not return early: fall through to JSON emission (if --json) so callers
    // still get the structured summary. The write block below is guarded by
    // `doWrite` (= !dryRun || previewDir) so nothing is written here.
  }

  // ── write resolved agent files ──
  if (doWrite) {
    await mkdir(outDir, { recursive: true });
    const total = writeRows.length;
    const verb = O.dryRun ? "Staging" : "Writing";
    const label = O.dryRun ? `(dry-run -> ${outDir})` : `(provider: ${O.provider || "default"})`;
    const showBar = !O.json && !O.verbose && process.stderr.isTTY && total > 1;
    if (!O.json && !O.verbose) {
      process.stderr.write(`\x1b[36m${verb} ${total} resolved agent file(s) ${label}...\x1b[0m\n`);
    }
    for (let i = 0; i < total; i++) {
      const r = writeRows[i];
      const rendered = await renderAgent(r);
      await writeFile(join(outDir, r.stem + ".md"), rendered, "utf8");
      if (showBar) {
        const pct = Math.round(((i + 1) / total) * 100);
        const filled = Math.round(((i + 1) / total) * 24);
        const bar = "█".repeat(filled).padEnd(24, "░");
        process.stderr.write(`\r  [${bar}] ${i + 1}/${total} (${pct}%) `);
      }
    }
    if (showBar) process.stderr.write("\r\x1b[K"); // clear the bar line; header + summary remain
    if (O.dryRun) {
      console.error(`${verb}d ${total} complete resolved agent file(s) -> ${outDir}`);
    }
  }

  // config.json: apply writes real config-dest; preview writes opencode.json into the preview dir.
  if (configPatched && configObj && doWrite) {
    const cfgOut = (O.dryRun && O.previewDir) ? join(outDir, "opencode.json") : O.configDest;
    await mkdir(dirname(cfgOut), { recursive: true });
    await writeFile(cfgOut, JSON.stringify(configObj, null, 2) + "\n", "utf8");
    if (O.dryRun) console.error(`[DRY-RUN] Staged resolved opencode.json -> ${cfgOut}`);
  }

  // State sidecar: real apply only (never in dry-run/preview).
  if (O.state && !O.dryRun) {
    await mkdir(dirname(O.state), { recursive: true });
    await writeFile(O.state, JSON.stringify(newState, null, 2) + "\n", "utf8");
  }

  // JSON summary emitted LAST so `written` / `configPatched` reflect what was
  // actually persisted to disk (writes happen above). stdout stays clean
  // because all human output is guarded by `!O.json`.
  if (O.json) {
    console.log(JSON.stringify({
      mode: O.dryRun ? "dry-run" : "apply",
      provider: O.provider || null,
      primary, exploreModel, generalModel, configPatched,
      written, preserved, skipped,
      agents: rows,
    }, null, 2));
  }
}

main().catch((e) => {
  console.error(`fatal: ${e.message}`);
  process.exit(1);
});
