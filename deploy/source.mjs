// deploy/source.mjs — source isolation module
//
// Single seam for all reads from {skills,agents}/ at the repo root.
// The eventual flip to per-skill HTTP remote fetch changes ONLY this file;
// every caller keeps calling readSkill("tdd-workflow-skill") regardless
// of transport.
//
// Exports:
//   readSkill(name, sourceRoot?)  → { content, frontmatter, path, dir }
//   readAgent(stem, sourceRoot?)  → { content, frontmatter, path }
//   listAvailable(type, sourceRoot?) → string[]   ("skills" | "agents")

import { readFile, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const DEFAULT_SOURCE_ROOT = join(__dirname, ".."); // deploy/.. = repo root

const skillDir = (root) => join(root, "skills");
const agentDir = (root) => join(root, "agents");

function extractFrontmatter(content) {
  const lines = content.split(/\r?\n/);
  if (lines.length === 0 || lines[0].trim() !== "---") return "";
  let close = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].trim() === "---") { close = i; break; }
  }
  if (close === -1) return "";
  return lines.slice(1, close).join("\n");
}

export async function listAvailable(type, sourceRoot = DEFAULT_SOURCE_ROOT) {
  if (type === "skills") {
    const dir = skillDir(sourceRoot);
    if (!existsSync(dir)) return [];
    return (await readdir(dir)).filter((d) => !d.startsWith("_")).sort();
  }
  if (type === "agents") {
    const dir = agentDir(sourceRoot);
    if (!existsSync(dir)) return [];
    return (await readdir(dir)).filter((f) => f.endsWith(".md")).map((f) => f.replace(/\.md$/, "")).sort();
  }
  throw new Error(`listAvailable: unknown type '${type}' — use 'skills' or 'agents'`);
}

export async function readSkill(name, sourceRoot = DEFAULT_SOURCE_ROOT) {
  const dir = join(skillDir(sourceRoot), name);
  const skillPath = join(dir, "SKILL.md");
  if (!existsSync(skillPath)) throw new Error(`skill not found: ${name} (looked at ${skillPath})`);
  const content = await readFile(skillPath, "utf8");
  return { content, frontmatter: extractFrontmatter(content), path: skillPath, dir };
}

export async function readAgent(stem, sourceRoot = DEFAULT_SOURCE_ROOT) {
  const agentPath = join(agentDir(sourceRoot), `${stem}.md`);
  if (!existsSync(agentPath)) throw new Error(`agent not found: ${stem} (looked at ${agentPath})`);
  const content = await readFile(agentPath, "utf8");
  return { content, frontmatter: extractFrontmatter(content), path: agentPath };
}

// ponytail: self-check — `node deploy/source.mjs` exercises all three exports.
const isMain = process.argv[1] && fileURLToPath(import.meta.url) === resolve(process.argv[1]);
if (isMain) {
  const assert = (cond, msg) => { if (!cond) { console.error(`FAIL: ${msg}`); process.exit(1); } };
  const skills = await listAvailable("skills");
  const agents = await listAvailable("agents");
  assert(skills.length > 0, "listAvailable(skills) empty");
  assert(agents.length > 0, "listAvailable(agents) empty");
  const s = await readSkill("tdd-workflow-skill");
  const a = await readAgent("tdd-subagent");
  assert(s.content.length > 0 && s.frontmatter.length > 0 && s.dir.length > 0, "readSkill shape");
  assert(a.content.length > 0 && a.frontmatter.length > 0, "readAgent shape");
  // parametrized sourceRoot
  const s2 = await readSkill("tdd-workflow-skill", DEFAULT_SOURCE_ROOT);
  assert(s2.content === s.content, "sourceRoot parametrization");
  console.log(`source.mjs self-check ✓  (skills=${skills.length}, agents=${agents.length})`);
}
