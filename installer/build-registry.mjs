#!/usr/bin/env node
// installer/build-registry.mjs
//
// Scans agent + skill frontmatter and emits installer/registry.json — the single
// data source for installer/init.mjs (--list / --expand / --describe / resolver /
// TUI). Zero external dependencies (Node built-ins only), matching the repo's
// other .mjs tooling (merge-packs.mjs, resolve-models.mjs, tui.mjs).
//
// The YAML frontmatter parser is intentionally minimal: it only needs to read
// the shapes that exist in THIS repo (verified):
//   (a) scalar:        `task: allow`  /  `edit: allow`  /  `bash: deny`
//   (b) nested map:    `permission.task:` then indented `  "*": deny` / `  explore: allow`
//                      `permission.skill:` then indented `  <name>: allow`
//                      `metadata:` then indented `  audience: …` / `  workflow: …`
//   (c) sequence:      `permissions:` then indented `  - action: read` items with
//                      deeper continuation lines (`    resource: '*'`) — collected
//                      into an array of flat rule objects ({action,resource,effect})
//   (d) absent keys:   e.g. explorer-subagent has no task rules at all
// Descriptions are single-line scalars or folded block scalars (`description: >-`
// with deeper-indented continuation lines, space-joined). No YAML anchors are used.
//
// NOTE (opencode v2): source agents ship native v2 frontmatter — `permissions:`
// rules arrays ({action,resource,effect}); the legacy `permission:` nested-map
// shape is still parsed for user-authored pre-v2 files (opencode v2 also
// auto-translates those at runtime). Registry edges derive from BOTH shapes.
//
// Output shape (installer/registry.json):
//   { "$comment": …, "generatedAt": …, "agents": [...], "skills": [...] }
//   agent: { stem, description, mode, tier, category, requiresSkills[], delegatesTo[], requiredBy[] }
//   skill: { name, description, category, audience, workflow, requiredByAgents[] }
//
// Usage: node installer/build-registry.mjs            # writes installer/registry.json
//        node installer/build-registry.mjs --check    # exit non-zero if output would differ (CI drift guard)

import { readFile, writeFile, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = dirname(__dirname);
const AGENTS_DIR = join(REPO, "agents");
const SKILLS_DIR = join(REPO, "skills");
const TIERS_FILE = join(REPO, "installer/agent-tiers.json");
const OUT_FILE = join(REPO, "installer/registry.json");

const CHECK = process.argv.includes("--check");

// ─────────────────────────── helpers ────────────────────────────────────
async function readJsonMaybe(p) {
  if (!p || !existsSync(p)) return null;
  try {
    const txt = await readFile(p, "utf8");
    return JSON.parse(txt.replace(/^[ \t]*"\$comment"[ \t]*:.*$(\r?\n)?/gm, ""));
  } catch { return null; }
}

// Extract the frontmatter body (between the --- fences) as an array of lines.
function frontmatterLines(content) {
  const lines = content.split(/\r?\n/);
  if (lines.length === 0 || lines[0].trim() !== "---") return null;
  let close = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") { close = i; break; }
  }
  if (close === -1) return null;
  return lines.slice(1, close);
}

// Parse the minimal YAML subset into a nested object via an indentation stack.
// Handles arbitrary nesting depth (permission.task.* is 3 levels: permission→task→leaf)
// and sequence blocks (permissions: → `- action: x` items with deeper continuation
// key:value lines collect into an array of flat objects; `- scalar` items supported).
// Key extraction: split on the first ": " (colon-space) so quoted keys containing
// colons (e.g. "mcp:*") survive; a line ending in ":" (no trailing value) is a map marker.
export function parseFrontmatter(fmLines) {
  const root = {};
  const stack = []; // [{ depth, key }]
  const unquote = (s) => s.trim().replace(/^['"]|['"]$/g, "");
  let fold = null; // { indent, target, key, parts } while consuming a block scalar
  let seqItem = null; // { depth, obj } active sequence-map item consuming continuation lines
  for (const raw of fmLines) {
    const trimmed = raw.trim();
    const indent = raw.length - raw.replace(/^\s+/, "").length;
    if (fold) {
      if (trimmed === "") continue; // blank inside block: paragraph sep, keep folding
      if (indent > fold.indent) { fold.parts.push(trimmed); continue; }
      // ponytail: space-join covers folded `>-`; repo has no literal `|` blocks needing \n
      fold.target[fold.key] = fold.parts.join(" ");
      fold = null; // this line ends the block — process it normally below
    }
    if (trimmed === "" || trimmed.startsWith("#")) continue;
    const depth = Math.floor(indent / 2);
    // sequence item: `- value` / `- key: value` at this depth
    const seqMatch = trimmed.match(/^- (.+)$/);
    if (seqMatch) {
      while (stack.length && stack[stack.length - 1].depth >= depth) stack.pop();
      const arrFrame = stack[stack.length - 1]; // key at depth-1 owns the sequence
      if (!arrFrame) { console.error(`warn: stray sequence item dropped: ${trimmed}`); continue; }
      let holder = root; // object the array lives on (exclude the naming frame)
      for (let i = 0; i < stack.length - 1; i++) holder = holder[stack[i].key];
      if (!Array.isArray(holder[arrFrame.key])) holder[arrFrame.key] = []; // map-marker {} → sequence
      const body = seqMatch[1];
      const ci = body.indexOf(": ");
      if (ci === -1) { holder[arrFrame.key].push(unquote(body)); seqItem = null; continue; } // - scalar
      const item = {};
      item[unquote(body.slice(0, ci))] = unquote(body.slice(ci + 2));
      holder[arrFrame.key].push(item);
      seqItem = { depth, obj: item }; // continuation lines (depth > this) fill the item
      continue;
    }
    // continuation line of the current sequence-map item
    if (seqItem && depth > seqItem.depth) {
      const m = trimmed.match(/^([^:]+):\s*(.*)$/);
      if (m) seqItem.obj[unquote(m[1])] = unquote(m[2]);
      continue;
    }
    seqItem = null; // anything at item depth or shallower ends the item
    let key, val;
    const mapMatch = trimmed.match(/^([^:]+):\s*$/); // "key:" → map marker
    if (mapMatch) {
      key = unquote(mapMatch[1]);
      val = "";
    } else {
      const ci = trimmed.indexOf(": ");
      if (ci === -1) continue; // not key:value, skip
      key = unquote(trimmed.slice(0, ci));
      val = unquote(trimmed.slice(ci + 2));
      if (/^[>|][+-]?$/.test(val)) {
        // block scalar (e.g. `description: >-`): fold deeper-indented lines into one string
        while (stack.length && stack[stack.length - 1].depth >= depth) stack.pop();
        let parent = root;
        for (const frame of stack) parent = parent[frame.key];
        fold = { indent, target: parent, key, parts: [] };
        continue;
      }
    }
    // pop stack until parent is at depth-1
    while (stack.length && stack[stack.length - 1].depth >= depth) stack.pop();
    let parent = root;
    for (const frame of stack) parent = parent[frame.key];
    if (val === "") {
      if (parent[key] === undefined) parent[key] = {};
      stack.push({ depth, key });
    } else {
      parent[key] = val;
    }
  }
  if (fold) fold.target[fold.key] = fold.parts.join(" ");
  return root;
}

function keysOf(mapVal) {
  if (!mapVal || typeof mapVal !== "object" || Array.isArray(mapVal)) return [];
  return Object.keys(mapVal).filter((k) => k !== "*");
}

// ─────────────────────────── build ──────────────────────────────────────
async function build() {
  const tiersDoc = await readJsonMaybe(TIERS_FILE);
  const tierOf = (tiersDoc && tiersDoc.tiers) || {};

  // --- agents ---
  const agentEntries = (await readdir(AGENTS_DIR))
    .filter((f) => f.endsWith(".md"))
    .map((f) => f.replace(/\.md$/, ""))
    .sort();
  const agents = [];
  for (const stem of agentEntries) {
    const content = await readFile(join(AGENTS_DIR, `${stem}.md`), "utf8");
    const fmLines = frontmatterLines(content);
    if (!fmLines) { console.error(`warn: ${stem}: no frontmatter`); continue; }
    const fm = parseFrontmatter(fmLines);
    // v2 permissions array (native form post-#380); legacy `permission:` maps
    // (user-authored pre-v2 files) still honored via the same keysOf semantics.
    // Precedence: a non-empty permissions array suppresses the legacy map
    // wholesale (per-file, not per-action); permissions: [] falls back to the map.
    const perm = fm.permission || {};
    const rules = Array.isArray(fm.permissions) ? fm.permissions : [];
    const ruleRes = (action) => rules.filter((r) => r && r.action === action && r.resource !== "*").map((r) => r.resource);
    const requiresSkills = rules.length ? ruleRes("skill") : keysOf(perm.skill);
    const delegatesTo = rules.length ? ruleRes("task") : keysOf(perm.task); // empty when task is a scalar like "allow"
    const category = fm.category || "uncategorized";
    if (!fm.category) console.error(`warn: ${stem}: no category (-> uncategorized)`);
    agents.push({
      stem,
      description: fm.description || "",
      mode: fm.mode || "",
      tier: tierOf[stem] || "unassigned",
      category,
      requiresSkills,
      delegatesTo,
      requiredBy: [], // filled after all agents parsed
    });
  }

  // reverse edges: agent X is requiredBy agent Y if Y.delegatesTo includes X
  for (const a of agents) {
    for (const d of a.delegatesTo) {
      const target = agents.find((x) => x.stem === d);
      if (target) target.requiredBy.push(a.stem);
    }
  }

  // --- skills ---
  const skillDirs = (await readdir(SKILLS_DIR)).filter((d) => !d.startsWith("_")).sort();
  const skills = [];
  for (const name of skillDirs) {
    const sf = join(SKILLS_DIR, name, "SKILL.md");
    if (!existsSync(sf)) { console.error(`warn: ${name}: no SKILL.md`); continue; }
    const content = await readFile(sf, "utf8");
    const fmLines = frontmatterLines(content);
    if (!fmLines) { console.error(`warn: ${name}: no frontmatter`); continue; }
    const fm = parseFrontmatter(fmLines);
    const meta = fm.metadata || {};
    const category = fm.category || "uncategorized";
    if (!fm.category) console.error(`warn: ${name}: no category (-> uncategorized)`);
    skills.push({
      name,
      description: fm.description || "",
      category,
      audience: meta.audience || "",
      workflow: meta.workflow || "",
      requiredByAgents: [], // filled after
    });
  }

  // reverse edges: skill S is requiredByAgents any agent whose requiresSkills includes S
  for (const a of agents) {
    for (const s of a.requiresSkills) {
      const target = skills.find((x) => x.name === s);
      if (target) target.requiredByAgents.push(a.stem);
    }
  }

  const out = {
    "$comment": "Generated by installer/build-registry.mjs from agent + skill frontmatter. Do NOT edit by hand — regenerate with `node installer/build-registry.mjs`. Single source of truth for installer/init.mjs (--list/--expand/--describe/resolver/TUI) and the README category table.",
    generatedAt: new Date().toISOString(),
    counts: { agents: agents.length, skills: skills.length },
    agents,
    skills,
  };

  const serialized = JSON.stringify(out, null, 2) + "\n";

  if (CHECK) {
    const existing = existsSync(OUT_FILE) ? await readFile(OUT_FILE, "utf8") : "";
    // ignore generatedAt for drift comparison
    const norm = (s) => s.replace(/"generatedAt"\s*:\s*"[^"]*"/, '"generatedAt":"__"');
    if (norm(existing) !== norm(serialized)) {
      console.error(`registry drift detected: installer/registry.json is out of date. Run \`node installer/build-registry.mjs\` and commit.`);
      process.exit(1);
    }
    console.log(`registry OK (agents=${agents.length}, skills=${skills.length}, no drift)`);
    return;
  }

  await writeFile(OUT_FILE, serialized, "utf8");
  console.log(`wrote ${OUT_FILE} (agents=${agents.length}, skills=${skills.length})`);

  // fixture sanity: spot-check 5 agents (Phase 1.3 requirement)
  const spot = ["code-review-subagent", "architecture-review-subagent", "explorer-subagent", "startup-founder-primary-agent", "tdd-subagent"];
  for (const s of spot) {
    const a = agents.find((x) => x.stem === s);
    if (!a) { console.error(`fixture FAIL: ${s} not found`); process.exit(1); }
    console.log(`fixture ${s}: category=${a.category} tier=${a.tier} skills=${a.requiresSkills.length} delegates=${a.delegatesTo.length}`);
  }
}

const isMain = process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isMain) {
  build().catch((e) => { console.error(`build-registry error: ${e.message}`); process.exit(1); });
}
