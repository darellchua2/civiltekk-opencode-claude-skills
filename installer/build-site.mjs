#!/usr/bin/env node
// installer/build-site.mjs
//
// Reads installer/registry.json → emits docs/index.html (browsable catalog with
// category filter + search) + docs/registry.json (static JSON API). Output
// to /docs for GitHub Pages. Zero-dep, mirrors build-registry.mjs ethos.
//
// Usage: node installer/build-site.mjs

import { readFile, writeFile, mkdir, copyFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = dirname(__dirname);
const REGISTRY = join(REPO, "installer/registry.json");
const OUT_DIR = join(REPO, "docs");
const GH_BASE = "https://github.com/darellchua2/civiltekk-opencode-claude-skills/blob/main";

function esc(s) {
  return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function card(item, kind) {
  const url = kind === "agent"
    ? `${GH_BASE}/agents/${item.stem}.md`
    : `${GH_BASE}/skills/${item.name}/SKILL.md`;
  const name = kind === "agent" ? item.stem : item.name;
  const tier = item.tier ? `<span class="badge tier">${esc(item.tier)}</span>` : "";
  const req = item.requiredByAgents?.length
    ? `<span class="badge req">required by ${item.requiredByAgents.length}</span>` : "";
  return `      <article class="card" data-name="${esc(name.toLowerCase())}" data-category="${esc(item.category)}" data-kind="${kind}">
        <div class="card-head">
          <h3><a href="${url}" target="_blank" rel="noopener">${esc(name)}</a></h3>
          <span class="badge cat">${esc(item.category)}</span>
          ${tier}${req}
        </div>
        <p>${esc(item.description)}</p>
        <code class="install">opencode-skill add ${esc(name)}</code>
      </article>`;
}

function renderHtml(reg) {
  const categories = [...new Set([...reg.agents.map(a => a.category), ...reg.skills.map(s => s.category)])].sort();
  const catPills = categories.map(c => `<button class="pill" data-cat="${esc(c)}">${esc(c)}</button>`).join("\n        ");
  const agentCards = reg.agents.map(a => card(a, "agent")).join("\n");
  const skillCards = reg.skills.map(s => card(s, "skill")).join("\n");

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>civiltekk-opencode-claude-skills — Skill & Agent Catalog</title>
<style>
  :root { --bg: #0d1117; --card: #161b22; --border: #30363d; --text: #e6edf3; --muted: #7d8590; --accent: #2f81f7; --accent2: #a371f7; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: var(--bg); color: var(--text); line-height: 1.5; }
  header { padding: 2rem 1.5rem 1rem; border-bottom: 1px solid var(--border); }
  header h1 { margin: 0 0 .25rem; font-size: 1.5rem; }
  header p { margin: 0 0 1rem; color: var(--muted); }
  input[type="search"] { width: 100%; max-width: 480px; padding: .5rem .75rem; font-size: .95rem; background: var(--card); border: 1px solid var(--border); border-radius: 6px; color: var(--text); }
  .pills { display: flex; flex-wrap: wrap; gap: .4rem; margin-top: .75rem; }
  .pill { padding: .25rem .65rem; font-size: .8rem; background: transparent; border: 1px solid var(--border); border-radius: 999px; color: var(--muted); cursor: pointer; transition: all .15s; }
  .pill:hover { border-color: var(--accent); color: var(--text); }
  .pill.active { background: var(--accent); border-color: var(--accent); color: #fff; }
  main { padding: 1.5rem; }
  .count { color: var(--muted); font-size: .85rem; margin-bottom: 1rem; }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 1rem; }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; transition: border-color .15s; }
  .card:hover { border-color: var(--accent); }
  .card-head { display: flex; align-items: center; flex-wrap: wrap; gap: .4rem; margin-bottom: .5rem; }
  .card-head h3 { margin: 0; font-size: .95rem; }
  .card-head h3 a { color: var(--accent); text-decoration: none; }
  .card-head h3 a:hover { text-decoration: underline; }
  .card p { margin: 0 0 .5rem; font-size: .82rem; color: var(--muted); display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
  .badge { font-size: .7rem; padding: .1rem .45rem; border-radius: 4px; white-space: nowrap; }
  .badge.cat { background: var(--border); color: var(--text); }
  .badge.tier { background: rgba(47,129,247,.15); color: var(--accent); }
  .badge.req { background: rgba(163,113,247,.15); color: var(--accent2); }
  .install { display: block; font-size: .75rem; color: var(--accent2); background: var(--bg); padding: .3rem .5rem; border-radius: 4px; overflow-x: auto; white-space: nowrap; }
  h2 { font-size: 1.1rem; margin: 2rem 0 .75rem; border-bottom: 1px solid var(--border); padding-bottom: .5rem; }
  .hidden { display: none; }
</style>
</head>
<body>
<header>
  <h1>civiltekk-opencode-claude-skills Catalog</h1>
  <p>${reg.agents.length} agents &middot; ${reg.skills.length} skills &middot; <code>npx github:darellchua2/civiltekk-opencode-claude-skills add &lt;name&gt;</code></p>
  <input type="search" id="search" placeholder="Search skills and agents…" autocomplete="off">
  <div class="pills" id="pills">
        <button class="pill active" data-cat="*">all</button>
        ${catPills}
  </div>
</header>
<main>
  <div class="count" id="count">Showing all ${reg.agents.length + reg.skills.length} items</div>

  <h2>Agents</h2>
  <div class="grid" id="agents">
${agentCards}
  </div>

  <h2>Skills</h2>
  <div class="grid" id="skills">
${skillCards}
  </div>
</main>
<script>
  const search = document.getElementById('search');
  const pills = document.querySelectorAll('.pill');
  const cards = document.querySelectorAll('.card');
  const countEl = document.getElementById('count');
  let activeCat = '*';
  function update() {
    const q = search.value.toLowerCase().trim();
    let visible = 0;
    cards.forEach(c => {
      const matchText = !q || c.dataset.name.includes(q);
      const matchCat = activeCat === '*' || c.dataset.category === activeCat;
      const show = matchText && matchCat;
      c.classList.toggle('hidden', !show);
      if (show) visible++;
    });
    countEl.textContent = visible === cards.length ? 'Showing all ' + visible + ' items' : 'Showing ' + visible + ' of ' + cards.length;
  }
  search.addEventListener('input', update);
  pills.forEach(p => p.addEventListener('click', () => {
    pills.forEach(x => x.classList.remove('active'));
    p.classList.add('active');
    activeCat = p.dataset.cat;
    update();
  }));
</script>
</body>
</html>
`;
}

async function build() {
  const reg = JSON.parse(await readFile(REGISTRY, "utf8"));
  await mkdir(OUT_DIR, { recursive: true });
  await copyFile(REGISTRY, join(OUT_DIR, "registry.json"));
  await writeFile(join(OUT_DIR, "index.html"), renderHtml(reg), "utf8");
  console.log(`built catalog: ${OUT_DIR}/index.html (${reg.agents.length} agents, ${reg.skills.length} skills)`);
  console.log(`static API: ${OUT_DIR}/registry.json`);
}

build().catch((e) => { console.error(`build-site error: ${e.message}`); process.exit(1); });
