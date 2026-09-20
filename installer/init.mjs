#!/usr/bin/env node
// installer/init.mjs — opencode-init
//
// Project-scoped selective installer. Copies a curated subset of this repo's
// agents + skills into a target project's .opencode/ and writes a project
// opencode.json configuring that subset. Driven by flags (LLM/CI, primary) or
// an interactive TUI (humans, secondary). Zero external dependencies.
//
// Read modes (pure, no writes):
//   opencode-init --list agents [--category X]     # JSON of agents
//   opencode-init --list skills [--category X]     # JSON of skills
//   opencode-init --list categories                # unique categories + counts
//   opencode-init --list mcps                      # MCP servers from opencode.json
//   opencode-init --list presets                   # preset summaries
//   opencode-init --describe <name>                # full agent/skill entry + deps
//   opencode-init --expand <preset>                # full resolved install set
//   opencode-init --help
//
// Install (writes to <project>/.opencode/ + <project>/.opencode/opencode.json):
//   opencode-init --project ./myapp --preset review --yes
//   opencode-init --project . --agents code-review-subagent --mcps codegraph --yes
//   opencode-init ... --dry-run        # print manifest, write nothing
//   opencode-init ... --prune          # remove previously-installed entries not in the new set
//
// Config merge semantics (verified, opencode 1.18.11): project .opencode/opencode.json
// is read and has HIGHER precedence than <project>/opencode.json; it MERGES with the
// global ~/.config/opencode config. Agents/skills directories are ADDITIVE (unioned).
// => isolation (curated subset) only holds on a clean slate (no global deploy).

import { readFile, writeFile, mkdir, readdir, rm, cp, copyFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join, resolve, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import os from "node:os";
import { singleSelect, multiSelect, textInput, confirm } from "./tui-primitives.mjs";
import { readAgent, readSkill } from "./source.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = dirname(__dirname); // installer/.. = repo root
const INSTALLER = __dirname; // installer dir (post-split); source files co-located
const AGENTS_SRC = join(REPO, "agents");
const SKILLS_SRC = join(REPO, "skills");
const REGISTRY_FILE = join(INSTALLER, "registry.json");
const PRESETS_DIR = join(INSTALLER, "presets");
const DEPMAP_FILE = join(INSTALLER, "dependency-map.json");
const TIERS_FILE = join(INSTALLER, "agent-tiers.json");
const MODELS_DEFAULT = join(INSTALLER, "models.default.json");
const PROVIDER_MODELS = join(INSTALLER, "provider-models.json");
const RESOLVER = join(INSTALLER, "resolve-models.mjs");
const SOURCE_OC = join(REPO, "opencode_app/opencode.json");
const BUILTINS = new Set(["explore", "general", "scout", "build", "plan", "compaction", "title", "summary"]);
const USER_OC = join(os.homedir(), ".config/opencode");
const USER_AGENTS = join(USER_OC, "agents");
const USER_SKILLS = join(USER_OC, "skills");
const USER_CONFIG = join(USER_OC, "opencode.json");
const USER_MANIFEST = join(USER_OC, ".skill-manifest.json");
const USER_CLAUDE_SKILLS = join(os.homedir(), ".claude/skills");
const USER_AGENTS_SHARED = join(os.homedir(), ".agents/agents");
const USER_SKILLS_SHARED = join(os.homedir(), ".agents/skills");
const USER_KIMI_AGENTS = join(os.homedir(), ".kimi-code/agents");
const USER_KIMI_SKILLS = join(os.homedir(), ".kimi-code/skills");

// Per-target write contract (#453): user-scope dest dirs + transform mode.
// SINGLE SITE for target dest/transform resolution — write/update/remove paths
// resolve via TARGETS, never inline constants (PLAN-453 structural gate).
// Project-scope dest columns deferred to #454 (PLAN-453 Technical Notes).
const TARGETS = {
  opencode: { agentsDir: USER_AGENTS, skillsDir: USER_SKILLS, projectAgentsDir: ".opencode/agents", projectSkillsDir: ".opencode/skills", agentMode: "model-injected", skillMode: "verbatim" },
  claude: { skillsDir: USER_CLAUDE_SKILLS, skillMode: "model-strip" }, // agents skipped (#377; #457 adds them)
  agents: { agentsDir: USER_AGENTS_SHARED, skillsDir: USER_SKILLS_SHARED, agentMode: "verbatim", skillMode: "verbatim" },
  kimi: { agentsDir: USER_KIMI_AGENTS, skillsDir: USER_KIMI_SKILLS, projectAgentsDir: ".kimi-code/agents", projectSkillsDir: ".kimi-code/skills", agentMode: "kimi-translate", skillMode: "verbatim" },
};
// derived from the table so a new target row can't skip validation (both = opencode+claude alias)
const TARGET_VALUES = [...Object.keys(TARGETS), "both"];
const activeTargets = (target) => (target === "both" ? ["opencode", "claude"] : [target]);

// ─────────────────────────── arg parsing ────────────────────────────────
const BOOL_FLAGS = new Set(["yes", "dryRun", "force", "prune", "help", "verbose", "permit", "noDeps"]);
function parseArgs(argv) {
  const opts = { rest: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--") { opts.rest.push(...argv.slice(i + 1)); break; }
    if (a.startsWith("--")) {
      const key = a.slice(2).replace(/-([a-z])/g, (_, c) => c.toUpperCase());
      if (BOOL_FLAGS.has(key)) opts[key] = true;
      else {
        const next = argv[i + 1];
        if (next === undefined || next.startsWith("--")) opts[key] = true;
        else { opts[key] = next; i++; }
      }
    } else {
      opts.rest.push(a);
    }
  }
  return opts;
}

// ─────────────────────────── helpers ────────────────────────────────────
function die(msg, code = 1) { console.error(`error: ${msg}`); process.exit(code); }
async function readJsonMaybe(p) {
  if (!p || !existsSync(p)) return null;
  try {
    const txt = await readFile(p, "utf8");
    return JSON.parse(txt.replace(/^[ \t]*"\$comment"[ \t]*:.*$(\r?\n)?/gm, ""));
  } catch (e) { if (e.code === "ENOENT") return null; throw new Error(`bad JSON ${p}: ${e.message}`); }
}
const toList = (v) => (v ? String(v).split(",").map((s) => s.trim()).filter(Boolean) : []);

// ── content hashing (#379) ── update compares hashes of WRITTEN content, so
// model injection / model-strip differences are tracked per target, never
// false-positive on deterministic re-runs.
const sha256Hex = (s) => "sha256:" + createHash("sha256").update(s).digest("hex");
async function hashSkillDir(dir, transform) {
  // deterministic tree hash: sorted relative paths + file contents (no mtimes).
  // transform(rel, buf) lets callers hash WOULD-WRITE content (e.g. claude
  // model-strip) without touching disk.
  const files = [];
  const walk = async (d, prefix) => {
    if (!existsSync(d)) return;
    for (const e of await readdir(d, { withFileTypes: true })) {
      const rel = prefix ? `${prefix}/${e.name}` : e.name;
      if (e.isDirectory()) await walk(join(d, e.name), rel);
      else files.push([rel, await readFile(join(d, e.name))]);
    }
  };
  await walk(dir, "");
  files.sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
  const h = createHash("sha256");
  for (const [rel, buf] of files) {
    const b = transform ? transform(rel, buf) : buf;
    h.update(rel); h.update("\0"); h.update(b); h.update("\0");
  }
  return "sha256:" + h.digest("hex");
}

// ─────────────────────────── data loading ───────────────────────────────
async function loadRegistry() {
  const reg = await readJsonMaybe(REGISTRY_FILE);
  if (!reg) die(`registry not found at ${REGISTRY_FILE}. Run \`node ${join(INSTALLER, "build-registry.mjs")}\` first.`);
  return reg;
}
async function loadPresets() {
  if (!existsSync(PRESETS_DIR)) return {};
  const files = (await readdir(PRESETS_DIR)).filter((f) => /^pack-(.+)\.json$/.test(f));
  const out = {};
  for (const f of files) {
    const p = await readJsonMaybe(join(PRESETS_DIR, f));
    if (p && p.name) out[p.name] = p;
  }
  return out;
}
async function loadDepMap() {
  const d = await readJsonMaybe(DEPMAP_FILE);
  return { impliesMcp: (d && d.impliesMcp) || {}, requiresSkills: (d && d.requiresSkills) || {} };
}

// ─────────────────────────── selection resolver (Phase 3.1) ─────────────
// Pure function: input selection -> resolved install set with transitive closure.
export function resolveSelection({ agents: agentIn = [], skills: skillIn = [], mcps: mcpIn = [], presets = [] }, reg, depMap) {
  const agentByName = new Map(reg.agents.map((a) => [a.stem, a]));
  const skillByName = new Map(reg.skills.map((s) => [s.name, s]));
  const warnings = [];

  // expand presets
  const ag = new Set();
  const sk = new Set();
  const mc = new Set();
  for (const pn of presets) {
    const p = reg.__presets?.[pn];
    if (!p) { warnings.push(`unknown preset: ${pn}`); continue; }
    for (const a of p.agents || []) ag.add(a);
    for (const s of p.skills || []) sk.add(s);
    for (const m of p.mcps || []) mc.add(m);
  }
  for (const a of agentIn) { if (!agentByName.has(a)) warnings.push(`unknown agent: ${a}`); else ag.add(a); }
  for (const s of skillIn) { if (!skillByName.has(s)) warnings.push(`unknown skill: ${s}`); else sk.add(s); }
  for (const m of mcpIn) mc.add(m);

  // transitive closure of delegatesTo (exclude built-ins) — required for functional agents
  const queue = [...ag];
  while (queue.length) {
    const stem = queue.shift();
    const a = agentByName.get(stem);
    if (!a) continue;
    for (const d of a.delegatesTo) {
      if (BUILTINS.has(d)) continue;
      if (!agentByName.has(d)) continue; // delegate not in registry (e.g. stale ref)
      if (!ag.has(d)) { ag.add(d); queue.push(d); }
    }
  }

  // required skills from every selected agent (hard dep) + skills implied by selected skills (MCP)
  for (const stem of ag) {
    const a = agentByName.get(stem);
    if (!a) continue;
    for (const s of a.requiresSkills) {
      if (!skillByName.has(s)) { warnings.push(`${stem} requires unknown skill: ${s}`); continue; }
      sk.add(s);
    }
  }

  // required skills from every selected skill (dependency-map requiresSkills, #439).
  // Transitive closure mirroring the delegatesTo queue above; --no-deps bypasses
  // this resolver entirely. Cycles terminate via the Set; unknown names warn, never crash.
  const skillQueue = [...sk];
  while (skillQueue.length) {
    const sname = skillQueue.shift();
    for (const dep of depMap.requiresSkills[sname] || []) {
      if (!skillByName.has(dep)) { warnings.push(`${sname} requires unknown skill: ${dep}`); continue; }
      if (!sk.has(dep)) { sk.add(dep); skillQueue.push(dep); }
    }
  }

  for (const sname of sk) {
    const implied = depMap.impliesMcp[sname];
    if (implied) for (const m of implied) mc.add(m);
  }

  return {
    agents: [...ag].sort(),
    skills: [...sk].sort(),
    mcps: [...mc].sort(),
    warnings,
  };
}

// ─────────────────────────── read modes (Phase 2) ───────────────────────
async function cmdList(kind, reg, opts) {
  const cat = opts.category;
  if (kind === "categories") {
    const counts = {};
    for (const a of reg.agents) counts[a.category] = (counts[a.category] || 0) + 1;
    for (const s of reg.skills) counts[s.category] = (counts[s.category] || 0) + 1;
    const out = Object.keys(counts).sort().map((c) => ({ category: c, count: counts[c] }));
    process.stdout.write(JSON.stringify(out, null, 2) + "\n");
    return;
  }
  if (kind === "agents") {
    let rows = reg.agents.map((a) => ({ stem: a.stem, description: a.description, category: a.category, tier: a.tier }));
    if (cat) rows = rows.filter((a) => a.category === cat);
    process.stdout.write(JSON.stringify(rows, null, 2) + "\n");
    return;
  }
  if (kind === "skills") {
    let rows = reg.skills.map((s) => ({ name: s.name, description: s.description, category: s.category }));
    if (cat) rows = rows.filter((s) => s.category === cat);
    process.stdout.write(JSON.stringify(rows, null, 2) + "\n");
    return;
  }
  if (kind === "mcps") {
    const oc = await readJsonMaybe(SOURCE_OC);
    const rows = Object.entries((oc && oc.mcp && oc.mcp.servers) || {}).map(([k, v]) => ({ key: k, type: v.type, disabled: v.disabled === true }));
    process.stdout.write(JSON.stringify(rows, null, 2) + "\n");
    return;
  }
  if (kind === "presets") {
    const rows = Object.keys(reg.__presets).sort().map((k) => {
      const p = reg.__presets[k];
      return { name: p.name, description: p.description, agents: (p.agents || []).length, skills: (p.skills || []).length, mcps: (p.mcps || []).length };
    });
    process.stdout.write(JSON.stringify(rows, null, 2) + "\n");
    return;
  }
  die(`--list: unknown kind '${kind}'. Use agents|skills|categories|mcps|presets.`);
}

async function cmdDescribe(name, reg) {
  const a = reg.agents.find((x) => x.stem === name);
  if (a) {
    const tierModel = await tierToModel(a.tier);
    const modelAvailable = await isModelAvailable(tierModel);
    const out = { ...a, kind: "agent", resolvedModel: tierModel, modelAvailable };
    if (!modelAvailable) out.modelAvailabilityNote = `tier '${a.tier}' resolves to '${tierModel}' which is not in ${relative(INSTALLER, PROVIDER_MODELS)} — may be unselectable.`;
    process.stdout.write(JSON.stringify(out, null, 2) + "\n");
    return;
  }
  const s = reg.skills.find((x) => x.name === name);
  if (s) { process.stdout.write(JSON.stringify({ ...s, kind: "skill" }, null, 2) + "\n"); return; }
  die(`'${name}' not found. Try --list agents|skills.`, 2);
}

async function cmdExpand(presetName, reg, depMap) {
  const sel = resolveSelection({ presets: [presetName] }, { ...reg, __presets: await loadPresets() }, depMap);
  if (!reg.__presets?.[presetName] && !(await loadPresets())[presetName]) die(`unknown preset: ${presetName}`, 2);
  process.stdout.write(JSON.stringify({ preset: presetName, ...sel }, null, 2) + "\n");
}

// tier -> model lookup (from models.default.json, optionally overridden by --provider)
async function tierToModel(tier, provider) {
  if (provider) {
    const presets = await readJsonMaybe(join(INSTALLER, "provider-presets.json"));
    const p = presets && presets[provider];
    if (p) return tier === "primary" ? p.primary : (p.tiers && p.tiers[tier]) || null;
  }
  // resolver-faithful precedence (#379): provider > user models.json > default.
  // (project map is N/A for user-scope installs — no project context.)
  const user = await readJsonMaybe(join(USER_OC, "models.json"));
  if (user && user.tiers && user.tiers[tier]) return user.tiers[tier];
  const m = await readJsonMaybe(MODELS_DEFAULT);
  if (!m) return null;
  if (tier === "primary") return m.primary;
  return (m.tiers && m.tiers[tier]) || null;
}
// Per-agent pin beats tier resolution (mirrors resolve-models.mjs resolveAgent
// precedence: project override > global override > tier model). projectOverrides
// is the target project's .opencode/agent-overrides.json (read once by
// writeInstall); null at user scope where the project map is N/A.
async function agentModel(stem, tier, provider, projectOverrides = null) {
  if (projectOverrides && projectOverrides[stem] && projectOverrides[stem].model)
    return projectOverrides[stem].model;
  const ov = await readJsonMaybe(join(USER_OC, "agent-overrides.json"));
  if (ov && ov[stem] && ov[stem].model) return ov[stem].model;
  return tierToModel(tier, provider);
}
async function isModelAvailable(modelId) {
  if (!modelId) return false;
  const pm = await readJsonMaybe(PROVIDER_MODELS);
  if (!pm) return true; // can't check — assume ok
  // modelId is "provider/model-id" (e.g. "zai-coding-plan/glm-5.3"); provider-models.json
  // maps provider key -> [bare model ids]. Also tolerate a bare id match across providers.
  const slash = modelId.indexOf("/");
  const provider = slash >= 0 ? modelId.slice(0, slash) : null;
  const bare = slash >= 0 ? modelId.slice(slash + 1) : modelId;
  if (provider && Array.isArray(pm[provider]) && pm[provider].includes(bare)) return true;
  for (const k of Object.keys(pm)) {
    if (k.startsWith("$")) continue;
    if (Array.isArray(pm[k]) && pm[k].includes(bare)) return true;
  }
  return false;
}

// ─────────────────────────── clean-slate detection (Phase 0.2) ──────────
async function detectGlobalDeploy() {
  const home = os.homedir();
  const gAgents = join(home, ".config/opencode/agents");
  const gSkills = join(home, ".config/opencode/skills");
  let aCount = 0, sCount = 0;
  try { if (existsSync(gAgents)) aCount = (await readdir(gAgents)).filter((f) => f.endsWith(".md")).length; } catch {}
  try { if (existsSync(gSkills)) sCount = (await readdir(gSkills)).filter((d) => !d.startsWith("_")).length; } catch {}
  return { present: aCount > 0 || sCount > 0, agents: aCount, skills: sCount };
}

// ─────────────────────────── writer (Phase 3.2 / 3.3 / 3.5) ─────────────
async function filesDiffer(p1, p2) {
  try {
    const a = await readFile(p1, "utf8");
    const b = await readFile(p2, "utf8");
    return a !== b;
  } catch { return true; }
}

export async function writeInstall(sel, opts, reg, depMap) {
  const project = resolve(opts.project || process.cwd());
  // project destinations resolve from TARGETS (#454); targets without project
  // columns degrade to opencode (note printed by cmdAdd; the preset flow dies
  // on non-opencode --target before reaching here)
  const pTarget = TARGETS[opts.target]?.projectSkillsDir ? opts.target : "opencode";
  const pCfg = TARGETS[pTarget];
  const ocProject = pTarget === "opencode"; // gates opencode.json / models.json / AGENTS.md
  const ocDir = join(project, ".opencode");
  const agentsDir = join(project, pCfg.projectAgentsDir);
  const skillsDir = join(project, pCfg.projectSkillsDir);
  const targetRoot = dirname(agentsDir); // .opencode | .kimi-code
  const ocFile = join(ocDir, "opencode.json"); // Phase 0.1: .opencode/opencode.json (highest precedence)
  const modelsFile = join(ocDir, "models.json");
  const agentsMd = join(project, "AGENTS.md");
  const manifestFile = join(targetRoot, ".opencode-init.manifest.json");
  const dry = !!opts.dryRun;
  const force = !!opts.force;

  // existing manifest (for prune + idempotency)
  const prevManifest = (await readJsonMaybe(manifestFile)) || { agents: [], skills: [] };

  // collect write plan
  const plan = { agents: [], skills: [], conflicts: [] };
  for (const stem of sel.agents) {
    const src = join(AGENTS_SRC, `${stem}.md`);
    const dst = join(agentsDir, `${stem}.md`);
    if (!existsSync(src)) { sel.warnings.push(`source missing: agents/${stem}.md`); continue; }
    const exists = existsSync(dst);
    const owned = prevManifest.agents?.includes(stem);
    if (exists && !owned && await filesDiffer(src, dst)) plan.conflicts.push({ path: dst, kind: "agent", stem });
    else plan.agents.push({ stem, src, dst });
  }
  for (const sname of sel.skills) {
    const src = join(SKILLS_SRC, sname);
    const dst = join(skillsDir, sname);
    if (!existsSync(src)) { sel.warnings.push(`source missing: skills/${sname}`); continue; }
    const exists = existsSync(dst);
    const owned = prevManifest.skills?.includes(sname);
    if (exists && !owned && await dirDiffers(src, dst)) plan.conflicts.push({ path: dst, kind: "skill", name: sname });
    else plan.skills.push({ name: sname, src, dst });
  }

  // opencode.json conflict
  const ocConflict = ocProject && existsSync(ocFile) && !(prevManifest.configPath === ocFile);
  const manifest = {
    generatedAt: new Date().toISOString(),
    tool: "opencode-init",
    agents: sel.agents,
    skills: sel.skills,
    mcps: sel.mcps,
    ...(ocProject ? { configPath: ocFile, modelsPath: modelsFile, agentsMd } : {}),
  };

  if (dry) {
    process.stdout.write(JSON.stringify({ dryRun: true, project, ...manifest, agents: sel.agents, skills: sel.skills, mcps: sel.mcps, warnings: sel.warnings, conflicts: plan.conflicts.map((c) => c.path) }, null, 2) + "\n");
    return;
  }

  // conflicts: skip unless --force
  if (plan.conflicts.length && !force) {
    for (const c of plan.conflicts) console.error(`conflict (skipped, use --force): ${relative(project, c.path)}`);
  }

  // write agents + skills
  await mkdir(agentsDir, { recursive: true });
  await mkdir(skillsDir, { recursive: true });
  const tierModels = {}; // tier -> model (cache; feeds the models.json artifact below)
  const projectOverrides = ocProject ? await readJsonMaybe(join(ocDir, "agent-overrides.json")) : null; // #401
  for (const a of plan.agents) {
    await mkdir(dirname(a.dst), { recursive: true });
    let content = await readFile(a.src, "utf8");
    if (ocProject) {
      const agentReg = reg.agents.find((x) => x.stem === a.stem);
      const tier = agentReg?.tier || "unassigned";
      if (!tierModels[tier]) tierModels[tier] = await tierToModel(tier, opts.provider);
      content = injectModelLine(content, await agentModel(a.stem, tier, opts.provider, projectOverrides));
    } else {
      content = kimiAgentContent(content, (m) => console.error(`  kimi (${a.stem}): ${m}`));
    }
    await writeFile(a.dst, content, "utf8");
  }
  for (const s of plan.skills) { await mkdir(dirname(s.dst), { recursive: true }); await cp(s.src, s.dst, { recursive: true, force: true }); }

  // opencode-specific artifacts (opencode target only — kimi project installs
  // carry no opencode config; #454)
  if (ocProject) {
    // opencode.json
    if (ocConflict && !force) {
      console.error(`conflict (skipped, use --force): existing ${relative(project, ocFile)} not written by opencode-init`);
      manifest.configPath = prevManifest.configPath ?? null; // claim only what we wrote (#412)
    } else if (!existsSync(ocFile) || force || prevManifest.configPath === ocFile) {
      const oc = await generateOpenencodeJson(sel, project);
      await mkdir(ocDir, { recursive: true });
      await writeFile(ocFile, JSON.stringify(oc, null, 2) + "\n", "utf8");
    }

    // models.json (deploy-side tier->model map for the tiers actually used) —
    // conflict-gated like opencode.json: never clobber a hand-authored file (#412)
    const modelsConflict = existsSync(modelsFile) && !(prevManifest.modelsPath === modelsFile);
    if (modelsConflict && !force) {
      console.error(`conflict (skipped, use --force): existing ${relative(project, modelsFile)} not written by opencode-init`);
      manifest.modelsPath = prevManifest.modelsPath ?? null; // claim only what we wrote (#412)
    } else if (!existsSync(modelsFile) || force || prevManifest.modelsPath === modelsFile) {
      const usedTiers = [...new Set(sel.agents.map((stem) => reg.agents.find((x) => x.stem === stem)?.tier).filter(Boolean))];
      const modelsMap = { "$comment": "Generated by opencode-init. Tier->model map for the agents installed in this project.", tiers: {} };
      for (const t of usedTiers) modelsMap.tiers[t] = tierModels[t] || null;
      await writeFile(modelsFile, JSON.stringify(modelsMap, null, 2) + "\n", "utf8");
    }

    // AGENTS.md (Phase 3.5)
    await writeFile(agentsMd, generateAgentsMd(sel, reg), "utf8");
  } else if (sel.mcps.length) {
    console.error(`note: MCP servers are configured via opencode.json — skipped for ${pTarget} project installs`);
  }

  // manifest
  await writeFile(manifestFile, JSON.stringify(manifest, null, 2) + "\n", "utf8");

  console.log(`installed into ${project} (${pTarget} project target):`);
  console.log(`  agents:  ${sel.agents.length}  -> ${pCfg.projectAgentsDir}`);
  console.log(`  skills:  ${sel.skills.length}  -> ${pCfg.projectSkillsDir}`);
  console.log(`  mcps:    ${sel.mcps.length}`);
  if (ocProject) {
    console.log(`  config:  ${relative(project, ocFile)}`);
    console.log(`  models:  ${relative(project, modelsFile)}`);
    console.log(`  rules:   ${relative(project, agentsMd)}`);
  }
  if (sel.warnings.length) console.log(`  warnings: ${sel.warnings.length}`);
  for (const w of sel.warnings) console.log(`    - ${w}`);
}

async function dirDiffers(src, dst) {
  // shallow: compare file list + each SKILL.md / files
  try {
    const a = (await readdir(src, { recursive: true })).sort();
    const b = (await readdir(dst, { recursive: true })).sort();
    if (JSON.stringify(a) !== JSON.stringify(b)) return true;
    for (const f of a) {
      const fa = await readFile(join(src, f), "utf8").catch(() => null);
      const fb = await readFile(join(dst, f), "utf8").catch(() => null);
      if (fa !== fb) return true;
    }
    return false;
  } catch { return true; }
}

// Phase 3.3: generate <project>/.opencode/opencode.json (v2 shape)
async function generateOpenencodeJson(sel, project) {
  const src = await readJsonMaybe(SOURCE_OC);
  // v2 permissions array: LAST matching rule wins => deny-all first, allows after.
  const agentRules = [{ action: "subagent", resource: "*", effect: "deny" }]; // FIRST
  for (const stem of sel.agents) agentRules.push({ action: "subagent", resource: stem, effect: "allow" });
  agentRules.push({ action: "subagent", resource: "explore", effect: "allow" });
  agentRules.push({ action: "subagent", resource: "general", effect: "allow" });
  const skillRules = [{ action: "skill", resource: "*", effect: "deny" }]; // FIRST
  for (const s of sel.skills) skillRules.push({ action: "skill", resource: s, effect: "allow" });
  const servers = {};
  const toolRules = [];
  for (const m of sel.mcps) {
    const def = (src && src.mcp && src.mcp.servers && src.mcp.servers[m]) || {};
    servers[m] = { ...def, disabled: false };
    toolRules.push({ action: `${m}*`, resource: "*", effect: "allow" });
  }
  const readRules = [
    { action: "read", resource: "*", effect: "allow" },
    { action: "read", resource: "mcp:*", effect: "deny" },
  ];
  const oc = {
    "$schema": "https://opencode.ai/config.json",
    experimental: { subagent_depth: 3 },
    instructions: ["AGENTS.md"],
    permissions: [...skillRules, ...toolRules],
    agents: {
      build: { permissions: agentRules },
      plan: src?.agents?.plan || { permissions: [
        { action: "edit", resource: "*", effect: "ask" },
        { action: "shell", resource: "*", effect: "ask" },
        { action: "subagent", resource: "*", effect: "allow" },
      ] },
      explore: src?.agents?.explore || { permissions: readRules },
      general: src?.agents?.general || { permissions: readRules },
    },
    mcp: { servers },
  };
  return oc;
}

// Inject/replace a single `model: <value>` line in the YAML frontmatter.
// Mirrors resolve-models.mjs injectModel(): strip any existing model line, prepend.
export function injectModelLine(content, modelValue) {
  if (!modelValue) return content;
  const lines = content.split(/\r?\n/);
  if (lines.length === 0 || lines[0].trim() !== "---") {
    return `---\nmodel: ${modelValue}\n---\n${content}`;
  }
  let closeIdx = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") { closeIdx = i; break; }
  }
  if (closeIdx === -1) return content;
  const fmBody = lines.slice(1, closeIdx).filter((l) => !/^model\s*:/.test(l));
  fmBody.unshift(`model: ${modelValue}`);
  return [...lines.slice(0, 1), ...fmBody, ...lines.slice(closeIdx)].join("\n");
}

// Phase 3.5: slim AGENTS.md
function generateAgentsMd(sel, reg) {
  const agentByName = new Map(reg.agents.map((a) => [a.stem, a]));
  const lines = ["# Project OpenCode Instructions", ""];
  lines.push("> Generated by `opencode-init`. Trimmed to the installed agent/skill subset.");
  lines.push("");
  lines.push("## Installed agents");
  for (const stem of sel.agents) {
    const a = agentByName.get(stem);
    lines.push(`- **${stem}** (${a?.category || "?"}, tier ${a?.tier || "?"}) — ${a?.description || ""}`);
  }
  lines.push("");
  lines.push("## Installed skills");
  lines.push(`${sel.skills.length} skills (see \`.opencode/skills/\`).`);
  lines.push("");
  lines.push("## MCP servers");
  if (sel.mcps.length) for (const m of sel.mcps) lines.push(`- ${m}`);
  else lines.push("(none)");
  lines.push("");
  lines.push("## Notes");
  lines.push("- Config merge: opencode MERGES config + UNIONS agents/skills across locations. Isolation holds only on a clean slate (no global deploy).");
  lines.push("- `agents.build.permissions` subagent rules prevent auto-spawning unselected subagents; `@`-mention still bypasses it.");
  lines.push("");
  return lines.join("\n");
}

// Phase 3.7: prune manifest-owned entries not in the new set
export async function doPrune(sel, opts) {
  const project = resolve(opts.project || process.cwd());
  // manifest + dirs resolve from the TARGETS project columns (#454); relative
  // columns only ever join against the explicit project root here
  const pTarget = TARGETS[opts.target]?.projectSkillsDir ? opts.target : "opencode";
  const pCfg = TARGETS[pTarget];
  const agentsDir = join(project, pCfg.projectAgentsDir);
  const skillsDir = join(project, pCfg.projectSkillsDir);
  const manifestFile = join(dirname(agentsDir), ".opencode-init.manifest.json");
  const prev = await readJsonMaybe(manifestFile);
  if (!prev) die("no manifest found — nothing to prune (opencode-init has not installed here).");
  const keep = { agents: new Set(sel.agents), skills: new Set(sel.skills) };
  const removed = [];
  for (const stem of (prev.agents || [])) {
    if (keep.agents.has(stem)) continue;
    const f = join(agentsDir, `${stem}.md`);
    if (existsSync(f)) { await rm(f, { force: true }); removed.push(`agents/${stem}.md`); }
  }
  for (const sname of (prev.skills || [])) {
    if (keep.skills.has(sname)) continue;
    const d = join(skillsDir, sname);
    if (existsSync(d)) { await rm(d, { recursive: true, force: true }); removed.push(`skills/${sname}/`); }
  }
  console.log(`pruned ${removed.length} previously-installed entries not in the new set:`);
  for (const r of removed) console.log(`  - ${r}`);
  if (!removed.length) console.log("  (nothing to prune)");
}

// ─────────────────────────── summary + confirm (Phase 3.6) ──────────────
async function summarize(sel, project, globalDeploy) {
  // Printed to STDERR so --dry-run stdout stays clean machine-parseable JSON.
  const e = (...a) => console.error(...a);
  e(`\nProject: ${project}`);
  if (globalDeploy.present) {
    e(`⚠  GLOBAL DEPLOY DETECTED (${globalDeploy.agents} agents, ${globalDeploy.skills} skills in ~/.config/opencode/).`);
    e(`   This install is ADDITIVE — isolation requires a clean slate (opencode merges/unions config + agents/skills).`);
  } else {
    e(`   Clean slate: no global deploy detected — isolation will hold.`);
  }
  e(`\nAgents (${sel.agents.length}):  ${sel.agents.join(", ") || "(none)"}`);
  e(`Skills (${sel.skills.length}):  ${sel.skills.length > 12 ? sel.skills.slice(0, 12).join(", ") + `, …(+${sel.skills.length - 12})` : sel.skills.join(", ")}`);
  e(`MCPs   (${sel.mcps.length}):    ${sel.mcps.join(", ") || "(none)"}`);
  if (sel.warnings.length) { e(`Warnings:`); for (const w of sel.warnings) e(`  - ${w}`); }
  e("");
}

// ─────────────────────────── user-scope add/remove (Phase 3) ────────────
async function cmdAdd(args, opts, reg, depMap) {
  // --all (#379): full-catalog selection for delegated full deploys.
  if (opts.all) {
    const sel = {
      agents: reg.agents.map((a) => a.stem).sort(),
      skills: reg.skills.map((s) => s.name).sort(),
      mcps: [],
      warnings: [],
    };
    await writeUserScopeInstall(sel, opts, reg, depMap);
    return;
  }

  const name = args[0];
  if (!name) die("add: specify a skill or agent name (e.g. 'solid-principles-skill'). Use --list agents|skills to browse.", 2);

  const isAgent = reg.agents.some((a) => a.stem === name);
  const isSkill = reg.skills.some((s) => s.name === name);
  if (!isAgent && !isSkill) die(`'${name}' not found. Use --list agents|skills to browse.`, 2);

  const noDeps = !!opts.noDeps;
  let sel;
  if (noDeps) {
    sel = isAgent
      ? { agents: [name], skills: [], mcps: [], warnings: [] }
      : { agents: [], skills: [name], mcps: [], warnings: [] };
  } else {
    sel = resolveSelection(isAgent ? { agents: [name] } : { skills: [name] }, reg, depMap);
    // Visible notice for auto-added dependencies (#439): silent auto-install
    // is indistinguishable from a bug at the CLI. stderr so --dry-run stdout
    // stays machine-readable JSON. --no-deps skips this path.
    for (const s of sel.skills) if (s !== name) console.error(`also installing required skill: ${s} (required by ${name})`);
  }

  // --format → --target deprecated alias (#377): map values verbatim, warn once.
  if (opts.format !== undefined) {
    if (opts.target !== undefined)
      die("cannot use --format and --target together (--format is deprecated; use --target)", 2);
    opts.target = opts.format;
    console.error("warning: --format is deprecated; use --target (values: opencode, claude, agents, kimi, both)");
  }

  const project = opts.project === true ? process.cwd() : opts.project;
  if (project) {
    const tgt = opts.target || "opencode";
    if (TARGETS[tgt] && !TARGETS[tgt].projectSkillsDir)
      console.error(`note: --target ${tgt} has no project destination; --project uses opencode target.`);
    opts.project = project;
    await writeInstall(sel, opts, reg, depMap);
    return;
  }
  await writeUserScopeInstall(sel, opts, reg, depMap);
}

async function writeUserScopeInstall(sel, opts, reg, depMap) {
  const dry = !!opts.dryRun;
  const target = opts.target || "opencode";
  if (!TARGET_VALUES.includes(target))
    die(`invalid target '${target}'. Use: opencode, claude, agents, kimi, or both.`, 2);
  const doOc = target === "opencode" || target === "both";
  const doClaude = target === "claude" || target === "both";
  const claudeSkipWarning = doClaude && sel.agents.length
    ? `warning: ${sel.agents.length} agent(s) skipped — Claude Code target installs skills only (agents are opencode-specific)`
    : null;
  // Claude Code target installs skills only — surface the skip in the preview too (#377).

  if (dry) {
    if (claudeSkipWarning) console.error(claudeSkipWarning);
    const destinations = {};
    for (const t of activeTargets(target))
      destinations[t] = TARGETS[t].agentsDir ? dirname(TARGETS[t].agentsDir) : TARGETS[t].skillsDir;
    process.stdout.write(JSON.stringify({
      dryRun: true,
      scope: "user",
      target,
      // legacy single-destination key preserved for scripts (PLAN-453 step 1.1 contract)
      destination: doOc ? USER_OC : (target === "agents" ? dirname(TARGETS.agents.agentsDir) : TARGETS.claude.skillsDir),
      destinations,
      agents: sel.agents,
      skills: sel.skills,
      mcps: sel.mcps,
      warnings: sel.warnings,
    }, null, 2) + "\n");
    return;
  }

  // Write per active target, resolved from TARGETS (#453): dest dirs + transform
  // modes come from the table — no per-target bespoke branches. Written-content
  // hashes per entry (#379), keyed per target: agents → file bytes (model-
  // injected for opencode, raw verbatim elsewhere — foreign targets stay
  // unpinned), skills → written dir tree hash (post model-strip for claude).
  const newEntries = {};
  for (const t of activeTargets(target)) {
    const cfg = TARGETS[t];
    if (t === "claude" && claudeSkipWarning)
      console.error(claudeSkipWarning);
    if (cfg.agentsDir) {
      await mkdir(cfg.agentsDir, { recursive: true });
      for (const stem of sel.agents) {
        const agent = await readAgent(stem);
        let content = agent.content;
        if (cfg.agentMode === "model-injected") {
          const tier = reg.agents.find((a) => a.stem === stem)?.tier || "unassigned";
          content = injectModelLine(content, await agentModel(stem, tier, opts.provider));
        } else if (cfg.agentMode === "kimi-translate") {
          content = kimiAgentContent(content, (m) => console.error(`  kimi (${stem}): ${m}`));
        }
        await writeFile(join(cfg.agentsDir, `${stem}.md`), content, "utf8");
        newEntries[stem] = { type: "agent", targets: { ...(newEntries[stem]?.targets || {}), [t]: sha256Hex(content) } };
      }
    }
    if (cfg.skillsDir) {
      await mkdir(cfg.skillsDir, { recursive: true });
      for (const sname of sel.skills) {
        const skill = await readSkill(sname);
        const dst = join(cfg.skillsDir, sname);
        await cp(skill.dir, dst, { recursive: true, force: true });
        if (cfg.skillMode === "model-strip") {
          const skillMd = join(dst, "SKILL.md");
          if (existsSync(skillMd))
            await writeFile(skillMd, stripModelLine(await readFile(skillMd, "utf8")), "utf8");
        }
        newEntries[sname] = { type: "skill", targets: { ...(newEntries[sname]?.targets || {}), [t]: await hashSkillDir(dst) } };
      }
    }
  }

  // update user-scope manifest (tracks ALL targets for uninstall/update). Agents are
  // recorded only for targets that actually install them (opencode, agents, or both) —
  // claude-only installs still place no agent files anywhere (#377). entries merge
  // per-target: re-installing to one target preserves the other target's record.
  await mkdir(USER_OC, { recursive: true });
  const prevManifest = (await readJsonMaybe(USER_MANIFEST)) || { agents: [], skills: [] };
  const entries = { ...(prevManifest.entries || {}) };
  for (const [name, ent] of Object.entries(newEntries)) {
    entries[name] = { type: ent.type, targets: { ...(entries[name]?.targets || {}), ...ent.targets } };
  }
  const manifest = {
    generatedAt: new Date().toISOString(),
    tool: "opencode-skill",
    agents: (doOc || target === "agents") ? [...new Set([...(prevManifest.agents || []), ...sel.agents])].sort() : (prevManifest.agents || []),
    skills: [...new Set([...(prevManifest.skills || []), ...sel.skills])].sort(),
    entries,
  };
  await writeFile(USER_MANIFEST, JSON.stringify(manifest, null, 2) + "\n", "utf8");

  if (doOc) {
    console.log(`installed (opencode) → ${USER_OC}:`);
    console.log(`  agents:  ${sel.agents.length}  -> ~/.config/opencode/agents/`);
    console.log(`  skills:  ${sel.skills.length}  -> ~/.config/opencode/skills/`);
  }
  if (doClaude) console.log(`  claude:  ${sel.skills.length}  -> ~/.claude/skills/`);
  if (target === "agents") {
    console.log(`installed (agents, shared) → ${dirname(TARGETS.agents.agentsDir)}:`);
    console.log(`  agents:  ${sel.agents.length}  -> ~/.agents/agents/`);
    console.log(`  skills:  ${sel.skills.length}  -> ~/.agents/skills/`);
  }
  if (sel.warnings.length) for (const w of sel.warnings) console.log(`  - ${w}`);

  // opencode-specific checks (skip for claude-only)
  if (doOc) {
    await checkStrictAllowlist(sel, opts);
    await warnMCPs(sel, depMap);
    if (opts.permit) await permitMerge(sel);
  }
}

async function checkStrictAllowlist(sel, opts) {
  if (opts.permit) return; // --permit handles it — skip the warning
  const config = await readJsonMaybe(USER_CONFIG);
  if (!config) return;
  // skills live in the permissions array ({action:"skill"} rules)
  const perms = Array.isArray(config.permissions) ? config.permissions : [];
  const skillDenyAll = perms.some((r) => r && r.action === "skill" && r.resource === "*" && r.effect === "deny");
  if (skillDenyAll) {
    const hidden = sel.skills.filter((name) => !perms.some((r) => r && r.action === "skill" && r.resource === name && r.effect === "allow"));
    if (hidden.length) {
      // Full-catalog deploys/updates hit the lean profile BY DESIGN — collapse
      // to one line instead of 100+ misleading paste-me hints (CR-3).
      if (hidden.length > 20) {
        console.error(`\n⚠  STRICT ALLOWLIST — ${hidden.length} skill(s) HIDDEN (lean profile: by design for full-catalog installs).`);
      } else {
        console.error(`\n⚠  STRICT ALLOWLIST DETECTED — ${hidden.length} skill(s) installed but HIDDEN.`);
        console.error(`   Add to opencode.json permissions array, or re-run with --permit:`);
        for (const name of hidden) console.error(`     { "action": "skill", "resource": "${name}", "effect": "allow" }`);
      }
    }
  }
  // agents live in agents.build.permissions ({action:"subagent"} rules)
  const sub = config.agents?.build?.permissions;
  if (Array.isArray(sub) && sub.some((r) => r && r.action === "subagent" && r.resource === "*" && r.effect === "deny")) {
    const hiddenAgents = sel.agents.filter((stem) => !sub.some((r) => r && r.action === "subagent" && r.resource === stem && r.effect === "allow"));
    if (hiddenAgents.length) {
      console.error(`\n⚠  STRICT TASK ALLOWLIST — ${hiddenAgents.length} agent(s) installed but HIDDEN.`);
      console.error(`   Add to agent.build.permissions, or re-run with --permit:`);
      for (const stem of hiddenAgents) console.error(`     { "action": "subagent", "resource": "${stem}", "effect": "allow" }`);
    }
  }
}

async function warnMCPs(sel, depMap) {
  const needed = new Set();
  for (const sname of sel.skills) {
    const implied = depMap.impliesMcp[sname];
    if (implied) for (const m of implied) needed.add(m);
  }
  if (!needed.size) return;
  const oc = await readJsonMaybe(SOURCE_OC);
  console.error(`\n⚠  MCP REQUIREMENT — ${needed.size} MCP server(s) needed. Paste into opencode.json, or re-run with --project:`);
  for (const m of needed) {
    const def = oc?.mcp?.servers?.[m];
    const snippet = def ? { ...def, disabled: false } : { disabled: false };
    console.error(`     "servers": { "${m}": ${JSON.stringify(snippet)} }`);
  }
}

async function permitMerge(sel) {
  const config = (await readJsonMaybe(USER_CONFIG)) || {};
  if (existsSync(USER_CONFIG)) {
    const ts = new Date().toISOString().replace(/[:.]/g, "-");
    await copyFile(USER_CONFIG, `${USER_CONFIG}.bak-${ts}`);
    console.log(`  backup: opencode.json.bak-${ts}`);
  }
  // skills → permissions array ({action:"skill"} rules; last-match-wins:
  // replaces an existing same-resource rule in place, else appends)
  if (!Array.isArray(config.permissions)) config.permissions = [];
  for (const sname of sel.skills) {
    const i = config.permissions.findIndex((r) => r && r.action === "skill" && r.resource === sname);
    const rule = { action: "skill", resource: sname, effect: "allow" };
    if (i >= 0) config.permissions[i] = rule; else config.permissions.push(rule);
  }
  // agents → agents.build.permissions ({action:"subagent"} rules, same policy)
  let agentCount = 0;
  if (!config.agents || typeof config.agents !== "object") config.agents = {};
  if (!config.agents.build || typeof config.agents.build !== "object") config.agents.build = {};
  if (!Array.isArray(config.agents.build.permissions)) {
    // v1 map (or absent) under v2 — re-seed deny-all-first, matching the generator
    // (incl. explore/general allows, so build keeps spawning the built-ins)
    config.agents.build.permissions = [
      { action: "subagent", resource: "*", effect: "deny" },
      { action: "subagent", resource: "explore", effect: "allow" },
      { action: "subagent", resource: "general", effect: "allow" },
    ];
  }
  const sub = config.agents.build.permissions;
  for (const stem of sel.agents) {
    const i = sub.findIndex((r) => r && r.action === "subagent" && r.resource === stem);
    const rule = { action: "subagent", resource: stem, effect: "allow" };
    if (i >= 0) sub[i] = rule; else { sub.push(rule); agentCount++; }
  }
  await mkdir(USER_OC, { recursive: true });
  await writeFile(USER_CONFIG, JSON.stringify(config, null, 2) + "\n", "utf8");
  console.log(`  merged permissions array (${sel.skills.length} skill rules${agentCount ? `, ${agentCount} subagent rules` : ""})`);
}

// Claude Code uses the SAME SKILL.md format (Agent Skills open standard).
// Skills are directories under ~/.claude/skills/<name>/ — straight copy, no
// frontmatter manipulation needed EXCEPT stripping `model:` (Claude Code
// recognizes it and would try to use non-Claude model IDs like glm-5.3).
// Other unknown frontmatter fields (tier, permission, category) are safely ignored.
function stripModelLine(content) {
  const lines = content.split(/\r?\n/);
  if (lines.length === 0 || lines[0].trim() !== "---") return content;
  let closeIdx = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") { closeIdx = i; break; }
  }
  if (closeIdx === -1) return content;
  const fmBody = lines.slice(1, closeIdx).filter((l) => !/^model\s*:/.test(l));
  return [...lines.slice(0, 1), ...fmBody, ...lines.slice(closeIdx)].join("\n");
}

// Kimi tool-name map (#454): opencode permission action → Kimi tool name.
// Verified against Kimi's tools reference 2026-09-20 — there is no `WebFetch`
// (the fetch tool is `FetchURL`), and unknown names never match + warn.
const KIMI_TOOL_MAP = {
  read: "Read", edit: "Edit", write: "Write", bash: "Bash",
  glob: "Glob", grep: "Grep", webfetch: "FetchURL", websearch: "WebSearch",
};

// Translate an opencode agent file's `permissions` array into additive Kimi
// `tools:` / `disallowedTools:` frontmatter keys (#454). Insertion is at column
// 0 immediately after the opening `---` (injectModelLine precedent — never
// key-scanning, a `>-` folded scalar would corrupt otherwise). All existing
// keys (incl. `permissions`, which Kimi ignores) and the body stay verbatim.
// Deny wins on action conflicts; unmappable rules are dropped via warn().
function kimiAgentContent(content, warn) {
  const lines = content.split(/\r?\n/);
  if (lines[0]?.trim() !== "---") {
    warn("no frontmatter — installed verbatim, permissions not translated");
    return content;
  }
  let closeIdx = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") { closeIdx = i; break; }
  }
  if (closeIdx === -1) {
    warn("unterminated frontmatter — installed verbatim, permissions not translated");
    return content;
  }
  // minimal YAML subset parse of the permissions list:
  //   - action: <name> / resource: <glob> / effect: <allow|deny|ask>
  const rules = [];
  let cur = null;
  for (let i = 1; i < closeIdx; i++) {
    const a = lines[i].match(/^\s*-\s*action:\s*"?([\w:-]+)"?/);
    if (a) { cur = { action: a[1] }; rules.push(cur); continue; }
    if (!cur) continue;
    const r = lines[i].match(/^\s+resource:\s*'?([^'#]+?)'?\s*$/);
    if (r) cur.resource = r[1];
    const e = lines[i].match(/^\s+effect:\s*"?(\w+)"?/);
    if (e) cur.effect = e[1];
  }
  const tools = new Set(), denied = new Set(), dropped = new Set();
  for (const r of rules) {
    if (!r.action || !r.effect) continue;
    const tool = KIMI_TOOL_MAP[r.action];
    const global = r.resource === "*";
    const mcpGlob = typeof r.resource === "string" && r.resource.startsWith("mcp:");
    if (!tool || (!global && !mcpGlob) || (r.effect !== "allow" && r.effect !== "deny")) {
      dropped.add(`${r.action}(${r.resource ?? "*"})`);
      continue;
    }
    if (r.effect === "deny") denied.add(mcpGlob ? "mcp__*" : tool);
    else if (global) tools.add(tool); // allow on mcp:* is the default in Kimi — no key needed
  }
  for (const t of denied) tools.delete(t); // deny wins
  if (dropped.size) warn(`no Kimi equivalent — dropped: ${[...dropped].sort().join(", ")}`);
  if (!tools.size && !denied.size) return content;
  const insert = [];
  if (tools.size) insert.push("tools:", ...[...tools].sort().map((t) => `  - ${t}`));
  if (denied.size) insert.push("disallowedTools:", ...[...denied].sort().map((t) => `  - ${t}`));
  return [...lines.slice(0, 1), ...insert, ...lines.slice(1)].join("\n");
}

async function cmdRemove(args, opts) {
  const name = args[0];
  if (!name) die("remove: specify a skill or agent name.", 2);
  const project = opts.project === true ? process.cwd() : opts.project;
  if (project) {
    die("remove --project: use --prune instead (project-scope removal via manifest).", 2);
  }
  const prev = await readJsonMaybe(USER_MANIFEST);
  if (!prev) {
    console.log("no user-scope manifest found — nothing to remove.");
    console.log("(for entries installed before #379's manifest tracking, run `opencode-skill update` once to adopt them)");
    return;
  }
  const wasAgent = (prev.agents || []).includes(name);
  const wasSkill = (prev.skills || []).includes(name);
  if (!wasAgent && !wasSkill) {
    console.log(`'${name}' not found in user-scope manifest — nothing to remove.`);
    return;
  }
  // probe every target dir via TARGETS (#453) — remove cleans all of them
  // (opencode + claude + shared ~/.agents)
  for (const cfg of Object.values(TARGETS)) {
    if (wasAgent && cfg.agentsDir) {
      const f = join(cfg.agentsDir, `${name}.md`);
      if (existsSync(f)) await rm(f, { force: true });
    }
    if (wasSkill && cfg.skillsDir) {
      const d = join(cfg.skillsDir, name);
      if (existsSync(d)) await rm(d, { recursive: true, force: true });
    }
  }
  prev.agents = (prev.agents || []).filter((a) => a !== name);
  prev.skills = (prev.skills || []).filter((s) => s !== name);
  if (prev.entries) delete prev.entries[name];
  await writeFile(USER_MANIFEST, JSON.stringify(prev, null, 2) + "\n", "utf8");
  console.log(`removed '${name}' from user scope.`);
}

// ─────────────────────────── update (#379) ──────────────────────────────
// Upgrade manifest-installed entries in place: recompute WOULD-WRITE hashes
// (post model-injection / model-strip) vs stored, re-copy changed entries to
// their recorded targets, report drift. Registry-removed entries are reported,
// never auto-deleted without --prune.
async function cmdUpdate(args, opts) {
  const reg = await loadRegistry();
  const prev = await readJsonMaybe(USER_MANIFEST);
  if (!prev) die("no user-scope manifest found — nothing to update. Run `add` first (setup.sh users: one full re-run of ./deploy/setup.sh adopts the manifest).", 2);

  // Legacy manifest (pre-#379, name arrays only): synthesize entries by hashing
  // what is currently installed, then proceed. Missing files stay out of entries.
  let upgradedLegacy = false;
  const entries = { ...(prev.entries || {}) };
  if (!prev.entries) {
    upgradedLegacy = true;
    for (const a of prev.agents || []) {
      // probe every historical target dir via TARGETS so shared installs keep their lifecycle
      const targets = {};
      for (const [t, cfg] of Object.entries(TARGETS)) {
        if (!cfg.agentsDir) continue;
        const f = join(cfg.agentsDir, `${a}.md`);
        if (existsSync(f)) targets[t] = sha256Hex(await readFile(f, "utf8")); // installed bytes, as before
      }
      if (Object.keys(targets).length) entries[a] = { type: "agent", targets };
    }
    for (const s of prev.skills || []) {
      // probe every historical target dir via TARGETS so claude/shared installs keep their lifecycle
      const targets = {};
      for (const [t, cfg] of Object.entries(TARGETS)) {
        if (!cfg.skillsDir) continue;
        const d = join(cfg.skillsDir, s);
        if (existsSync(d)) targets[t] = await hashSkillDir(d); // installed bytes, as before
      }
      if (Object.keys(targets).length) entries[s] = { type: "skill", targets };
    }
  }

  const plan = { updated: [], unchanged: [], missing: [], registryRemoved: [], pruned: [] };
  const prune = !!opts.prune;
  const dry = !!opts.dryRun;

  const regAgentStems = new Set(reg.agents.map((a) => a.stem));
  const regSkillNames = new Set(reg.skills.map((s) => s.name));

  for (const [name, ent] of Object.entries(entries)) {
    const inRegistry = ent.type === "agent" ? regAgentStems.has(name) : regSkillNames.has(name);
    if (!inRegistry) {
      plan.registryRemoved.push(name);
      if (prune && !dry) {
        for (const t of Object.keys(ent.targets)) {
          const cfg = TARGETS[t];
          if (!cfg) { console.error(`warning: pruning '${name}': unknown install target '${t}' — its files (if any) were left in place`); continue; }
          const p = ent.type === "agent"
            ? (cfg.agentsDir ? join(cfg.agentsDir, `${name}.md`) : null)
            : (cfg.skillsDir ? join(cfg.skillsDir, name) : null);
          if (p && existsSync(p)) await rm(p, { recursive: true, force: true });
        }
        delete entries[name];
        prev.agents = (prev.agents || []).filter((x) => x !== name);
        prev.skills = (prev.skills || []).filter((x) => x !== name);
        plan.pruned.push(name);
      }
      continue;
    }

    let touched = false, wouldContent = null; // agent: the full would-write file content
    let missingTargets = 0;
    for (const target of Object.keys(ent.targets)) {
      const cfg = TARGETS[target];
      if (!cfg) {
        // explicit no-op on unknown target keys — never fallback-dispatch (older
        // binaries routed every non-opencode key through the claude branch)
        console.error(`warning: '${name}' has unknown install target '${target}' — skipping`);
        continue;
      }
      let wouldHash = null, installedPath = null;
      if (ent.type === "agent") {
        if (!cfg.agentsDir) { console.error(`warning: '${name}' target '${target}' does not install agents — skipping`); continue; }
        installedPath = join(cfg.agentsDir, `${name}.md`);
        const agent = await readAgent(name);
        if (cfg.agentMode === "model-injected") {
          const tier = reg.agents.find((a) => a.stem === name)?.tier || "unassigned";
          wouldContent = injectModelLine(agent.content, await agentModel(name, tier, opts.provider));
        } else if (cfg.agentMode === "kimi-translate") {
          wouldContent = kimiAgentContent(agent.content, () => {}); // warnings already surfaced at install
        } else {
          wouldContent = agent.content; // shared target: verbatim, unpinned (#453)
        }
        wouldHash = sha256Hex(wouldContent);
      } else {
        if (!cfg.skillsDir) { console.error(`warning: '${name}' target '${target}' does not install skills — skipping`); continue; }
        installedPath = join(cfg.skillsDir, name);
        const skill = await readSkill(name);
        wouldHash = cfg.skillMode === "model-strip"
          ? await hashSkillDir(skill.dir, (rel, buf) =>
              rel === "SKILL.md" ? Buffer.from(stripModelLine(buf.toString("utf8")), "utf8") : buf)
          : await hashSkillDir(skill.dir);
      }
      if (!existsSync(installedPath)) { plan.missing.push(`${name} (${target})`); missingTargets++; continue; }
      if (wouldHash === ent.targets[target]) continue;
      if (!dry) {
        if (ent.type === "agent") {
          await writeFile(installedPath, wouldContent, "utf8");
        } else {
          // clean re-copy: rm first so stale files from a thinner source converge
          const skill = await readSkill(name);
          await rm(installedPath, { recursive: true, force: true });
          await cp(skill.dir, installedPath, { recursive: true });
          if (cfg.skillMode === "model-strip") {
            const skillMd = join(installedPath, "SKILL.md");
            if (existsSync(skillMd))
              await writeFile(skillMd, stripModelLine(await readFile(skillMd, "utf8")), "utf8");
          }
        }
        ent.targets[target] = wouldHash;
      }
      touched = true;
    }
    // Per-target outcome roll-up (#400): an entry that updated ANY target
    // counts as updated (even if another target is missing — that target is
    // already listed in plan.missing); fully-missing entries report per-target
    // only; otherwise unchanged.
    if (touched) plan.updated.push(name);
    else if (missingTargets === 0) plan.unchanged.push(name);
  }

  if (dry) {
    process.stdout.write(JSON.stringify({ dryRun: true, scope: "user", legacyUpgraded: upgradedLegacy, ...plan }, null, 2) + "\n");
    return;
  }

  const manifest = { ...prev, generatedAt: new Date().toISOString(), entries };
  await writeFile(USER_MANIFEST, JSON.stringify(manifest, null, 2) + "\n", "utf8");

  console.log(`update complete: updated ${plan.updated.length} · unchanged ${plan.unchanged.length} · missing ${plan.missing.length}`);
  if (plan.registryRemoved.length) console.log(`  registry-removed (present locally): ${plan.registryRemoved.join(", ")}${prune ? "" : " — re-run with --prune to remove"}`);
  if (plan.pruned.length) console.log(`  pruned: ${plan.pruned.join(", ")}`);
  if (plan.missing.length) for (const m of plan.missing) console.log(`  missing: ${m}`);
  if (upgradedLegacy) console.log("  (legacy manifest upgraded with per-entry hashes)");

  // visibility check only — name-stable updates cannot grow the permissions
  // union; missing allow rules are NOT repaired (documented deviation, #379).
  const sel = {
    // opencode-target entries only: the allowlist is an opencode config check —
    // warning about skills never installed to opencode is noise (#453)
    agents: Object.entries(entries).filter(([, e]) => e.type === "agent" && e.targets?.opencode).map(([n]) => n),
    skills: Object.entries(entries).filter(([, e]) => e.type === "skill" && e.targets?.opencode).map(([n]) => n),
    warnings: [],
  };
  await checkStrictAllowlist(sel, opts);
}

// ─────────────────────────── main ───────────────────────────────────────
async function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.help) { printHelp(); return; }

  const reg = await loadRegistry();
  reg.__presets = await loadPresets();
  const depMap = await loadDepMap();

  // verb dispatch: add / remove (npx UX surface)
  if (opts.rest[0] === "add") { await cmdAdd(opts.rest.slice(1), opts, reg, depMap); return; }
  if (opts.rest[0] === "update") { await cmdUpdate(opts.rest.slice(1), opts); return; }
  if (opts.rest[0] === "remove") { await cmdRemove(opts.rest.slice(1), opts); return; }

  // read modes
  if (opts.list) { cmdList(opts.list, reg, opts); return; }
  if (opts.describe) { await cmdDescribe(opts.describe, reg); return; }
  if (opts.expand) { await cmdExpand(opts.expand, reg, depMap); return; }

  // no install inputs and no read mode -> help
  const hasInstallInput = opts.preset || opts.agents || opts.skills || opts.mcps || opts.prune;
  if (!hasInstallInput && !opts.help) { printHelp(); return; }

  // prune-only mode
  if (opts.prune && !opts.preset && !opts.agents && !opts.skills) {
    // prune against an empty selection = remove everything opencode-init installed
    const sel = resolveSelection({}, reg, depMap);
    await doPrune(sel, opts);
    return;
  }

  // resolve selection
  const sel = resolveSelection({
    presets: toList(opts.preset),
    agents: toList(opts.agents),
    skills: toList(opts.skills),
    mcps: toList(opts.mcps),
  }, reg, depMap);

  const project = resolve(opts.project || process.cwd());
  // preset/init flow installs the opencode target only (#454); kimi project
  // scope goes through `add --project --target kimi`
  if (opts.target && opts.target !== "opencode")
    die(`--target ${opts.target} is not supported here — preset/project installs use the opencode target (use 'add --project --target ${opts.target}' instead).`, 2);
  const globalDeploy = await detectGlobalDeploy();

  await summarize(sel, project, globalDeploy);

  if (opts.prune) await doPrune(sel, opts);

  // non-TTY install requires --yes
  const isTTY = process.stdin.isTTY && process.stdout.isTTY;
  if (!opts.yes && !opts.dryRun) {
    if (!isTTY) die("non-interactive install requires --yes (or --dry-run). Re-run with --yes.");
    // TUI interactive flow (Phase 4.1/4.2). Gathers input, then resolves + confirms + writes.
    const interactive = await runInteractive(reg, depMap, opts);
    if (!interactive) return; // user cancelled
    Object.assign(opts, interactive.opts);
    // re-resolve with the gathered inputs
    const sel2 = resolveSelection({
      presets: toList(opts.preset),
      agents: toList(opts.agents),
      skills: toList(opts.skills),
      mcps: toList(opts.mcps),
    }, reg, depMap);
    await summarize(sel2, project, globalDeploy);
    if (opts.prune) await doPrune(sel2, opts);
    const go = await confirm("Proceed with install?", false);
    if (go.aborted || !go.value) { console.error("cancelled"); return; }
    await writeInstall(sel2, opts, reg, depMap);
    return;
  }

  await writeInstall(sel, opts, reg, depMap);
}

// Phase 4.1/4.2: interactive TUI flow. Returns { opts: {preset,agents,skills,mcps,project,provider} } or null on cancel.
async function runInteractive(reg, depMap, opts) {
  const presetNames = Object.keys(reg.__presets).sort();
  // 1. target project
  const proj = await textInput("Target project path", opts.project || process.cwd());
  if (proj.aborted) return null;
  // 2. preset or manual
  const presetOpts = [{ label: "None — pick agents/skills manually", value: "" }, ...presetNames.map((k) => ({ label: `${k} — ${reg.__presets[k].description}`, value: k }))];
  const ps = await singleSelect("Choose a preset (or manual)", presetOpts, 0);
  if (ps.aborted) return null;
  const chosenPreset = ps.value;
  let agents = [];
  let skills = [];
  let mcps = [];
  if (chosenPreset) {
    // 3. confirm expansion
    const expanded = resolveSelection({ presets: [chosenPreset] }, reg, depMap);
    console.error(`\n${chosenPreset} expands to: ${expanded.agents.length} agents, ${expanded.skills.length} skills, ${expanded.mcps.length} MCPs (incl. auto-pulled deps).`);
    const ok = await confirm("Customize the selection before install?", false);
    if (ok.aborted) return null;
    if (ok.value) {
      agents = expanded.agents; skills = expanded.skills; mcps = expanded.mcps;
    }
  } else {
    agents = []; skills = []; mcps = [];
  }
  // 4. agents (multi-select, grouped flat — preset agents pre-checked)
  const aSel = await multiSelect("Agents (↑/↓ · space toggle · enter done)", reg.agents.map((a) => ({ label: `[${a.category}] ${a.stem}`, value: a.stem, checked: agents.includes(a.stem) })));
  if (aSel.aborted) return null;
  // resolve once to compute required skills (locked)
  const pre = resolveSelection({ agents: aSel.selected, skills, mcps }, reg, depMap);
  const requiredSkills = new Set(pre.skills);
  // 5. skills (required locked; optional selectable)
  const sSel = await multiSelect("Skills (🔒 = required by selected agents)", reg.skills.map((s) => ({ label: `[${s.category}] ${s.name}`, value: s.name, checked: requiredSkills.has(s.name), locked: requiredSkills.has(s.name) })));
  if (sSel.aborted) return null;
  // 6. mcps (auto-derived pre-checked)
  const oc = await readJsonMaybe(SOURCE_OC);
  const mSel = await multiSelect("MCP servers", Object.keys((oc && oc.mcp && oc.mcp.servers) || {}).map((k) => ({ label: k, value: k, checked: mcps.includes(k) })));
  if (mSel.aborted) return null;
  // 7. provider (simple single-select; default = use default tier map)
  const presets = await readJsonMaybe(join(INSTALLER, "provider-presets.json"));
  const provKeys = presets ? Object.keys(presets).filter((k) => !k.startsWith("$")) : [];
  const pSel = await singleSelect("Model provider (tier resolution)", [{ label: "default (models.default.json)", value: "" }, ...provKeys.map((k) => ({ label: k, value: k }))], 0);
  if (pSel.aborted) return null;
  return {
    opts: {
      project: proj.value || process.cwd(),
      preset: chosenPreset || undefined,
      agents: aSel.selected.join(",") || undefined,
      skills: sSel.selected.join(",") || undefined,
      mcps: mSel.selected.join(",") || undefined,
      provider: pSel.value || undefined,
    },
  };
}

function printHelp() {
  process.stdout.write(`opencode-skill — opencode skill/agent registry + CLI installer

USAGE
  opencode-skill add <name>                    install a skill or agent (USER scope)
  opencode-skill add <name> --project [dir]    install to project .opencode/ (full config)
  opencode-skill add --all --yes               install the full catalog (user scope)
  opencode-skill update [--prune]              re-copy manifest entries whose source changed
  opencode-skill remove <name>                 remove a user-scope install
  opencode-skill --list agents [--category X]      list agents (JSON)
  opencode-skill --list skills [--category X]      list skills (JSON)
  opencode-skill --list categories                 list categories + counts
  opencode-skill --list mcps                       list MCP servers
  opencode-skill --list presets                    list presets
  opencode-skill --describe <name>                 full agent/skill entry + deps
  opencode-skill --expand <preset>                 full resolved install set
  opencode-skill --project <dir> --preset <p> --yes       install a preset (project scope)
  opencode-skill --project <dir> --agents <a,b> --yes     install specific agents
  opencode-skill ... --dry-run                     preview, write nothing
  opencode-skill ... --prune                       remove previously-installed entries not in the set
  opencode-skill --help

SCOPE
  User scope (default for 'add'): drops files into ~/.config/opencode/{agents,skills}/.
  opencode auto-discovers them — no opencode.json touch unless --permit.
  Agents target (--target agents): cross-tool shared dir ~/.agents/{agents,skills}/
  (scanned by Kimi Code and pi; files are verbatim, agents stay model-unpinned).
  Kimi target (--target kimi): Kimi Code native dirs ~/.kimi-code/{agents,skills}/
  (user) and .kimi-code/{agents,skills}/ (project); permissions translate additively
  to tools/disallowedTools (lossy — unmapped rules dropped with a warning).
  Project scope (--project): writes .opencode/{agents,skills}/ + opencode.json + models.json + AGENTS.md.

FLAGS
  --project [dir]      project scope (default: cwd). Without 'add', takes a <dir> value.
  --preset <csv>       preset name(s): core review frontend backend docs devops business research cad
  --agents <csv>       agent stem(s)
  --skills <csv>       skill name(s)
  --mcps <csv>         MCP server key(s)
  --provider <name>    model provider for tier resolution (zai|anthropic|openai|…)
  --category <name>    filter for --list
  --yes                non-interactive (required for install without a TTY)
  --dry-run            preview the install manifest, write nothing
  --force              overwrite conflicting files opencode-init didn't write
  --prune              remove opencode-init-owned entries absent from the new set
  --permit             (user scope) backup opencode.json + merge permissions-array rules (skill allows + build's subagent rules)
  --no-deps            (add) skip transitive dependency resolution
  --target <t>         (add) install target: opencode (default), claude, agents (shared ~/.agents/), kimi, or both (--format is a deprecated alias)

CONFIG MERGE SEMANTICS
  opencode MERGES config and UNIONS agents/skills across ~/.config/opencode and
  <project>/.opencode. User-scope 'add' is a pure file-drop (auto-discovered);
  --permit backs up opencode.json then merges permissions-array rules: skill-allow entries plus agents.build subagent rules (deny-all-first seed incl. explore/general when absent or v1-shaped).
`);
}

const isMain = process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isMain) {
  main().catch((e) => { console.error(`opencode-skill: ${e.message}`); process.exit(1); });
}
