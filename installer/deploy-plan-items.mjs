// installer/deploy-plan-items.mjs
//
// Pure module for the per-item deploy picker (#473): the selectable inventory
// (skills by category, agents by tier, MCP packs, plugins, extras) and the
// selection→plan builder. The dependency closure is init.mjs's exported
// resolveSelection — ONE implementation, so the dashboard's lock display is
// exactly what `init.mjs add` installs (arch review: never fork the edge set).
//
// No I/O beyond caller-passed data — every pin runs this module headlessly.

import { resolveSelection } from "./init.mjs";

export const EXTRA_ITEMS = ["local-llm", "vllm"];

// Implied-MCP id → provider pack name (dependency-map.json impliesMcp values
// are MCP server ids; the executor's pack merge consumes pack names). Pinned
// by test_select_items.bats against the live dependency map.
export const MCP_TO_PACK = { docling: "docling", markitdown: "markitdown", "next-devtools": "nextjs" };

/** Grouped selectable inventory from caller-loaded data. */
export function buildInventory({ registry, packNames, pluginNames }) {
  const categories = new Map();
  for (const s of registry.skills) {
    const cat = s.category || "Uncategorized";
    if (!categories.has(cat)) categories.set(cat, []);
    categories.get(cat).push({ id: s.name, label: s.name, description: s.description || "" });
  }
  const tiers = new Map();
  for (const a of registry.agents) {
    const tier = a.tier || "unassigned";
    if (!tiers.has(tier)) tiers.set(tier, []);
    tiers.get(tier).push({ id: a.stem, label: a.stem, description: a.description || "" });
  }
  return {
    groups: [
      { id: "skills", label: "Skills", kind: "multi", items: [...categories.entries()].map(([cat, items]) => ({ id: `skills:${cat}`, label: cat, items })) },
      { id: "agents", label: "Agents", kind: "multi", items: [...tiers.entries()].map(([tier, items]) => ({ id: `agents:${tier}`, label: tier, items })) },
      { id: "packs", label: "MCP Packs", kind: "multi", items: packNames.map((p) => ({ id: p, label: p, description: `provider pack (${p})` })) },
      { id: "plugins", label: "Plugins", kind: "multi", items: pluginNames.map((p) => ({ id: p, label: p })) },
      { id: "extras", label: "Extras", kind: "multi", items: EXTRA_ITEMS.map((e) => ({ id: e, label: e })) },
    ],
    counts: { skills: registry.skills.length, agents: registry.agents.length, packs: packNames.length, plugins: pluginNames.length, extras: EXTRA_ITEMS.length },
  };
}

/**
 * choices: { skills: [names], agents: [stems], packs: [names], plugins: [names], extras: [names] }
 * Returns the plan: every inclusion annotated `direct` or `locked-by:<id>`
 * with a human reason, plus the resolver warnings (unknown names, etc.).
 * The closure is resolveSelection's — the same one `init.mjs add` executes.
 */
export function buildSelectionPlan({ choices, registry, depMap }) {
  const sel = resolveSelection(
    { agents: choices.agents || [], skills: choices.skills || [], mcps: choices.packs || [] },
    registry,
    depMap,
  );

  // Provenance: which DIRECT choice pulled each resolved item in? Solo
  // closures per direct item; an item first appearing in a solo closure is
  // attributed to it. Direct picks are attributed to themselves.
  const directSkills = new Set(choices.skills || []);
  const directAgents = new Set(choices.agents || []);
  const directPacks = new Set(choices.packs || []);
  const solo = new Map();
  for (const s of directSkills) solo.set(`skill:${s}`, resolveSelection({ skills: [s] }, registry, depMap));
  for (const a of directAgents) solo.set(`agent:${a}`, resolveSelection({ agents: [a] }, registry, depMap));
  for (const m of directPacks) solo.set(`pack:${m}`, resolveSelection({ mcps: [m] }, registry, depMap));
  // Attribution must test membership IN the solo closure for the matching
  // pool — the union pool is tautologically true for every mapped item, which
  // credited every locked dep to the first solo entry (#473 review WARN 1).
  const whoPulled = (poolKey, name, directSet, groupLabel) => {
    if (directSet.has(name)) return { source: "direct", reason: `selected in ${groupLabel}` };
    for (const [key, res] of solo) {
      if ((res[poolKey] || []).includes(name)) {
        return { source: `locked-by:${key.split(":")[1]}`, reason: `required by ${key.split(":")[1]}` };
      }
    }
    return { source: "locked-by:transitive", reason: "transitive dependency" };
  };

  // Implied MCPs (impliesMcp via resolveSelection) map to their provider packs
  // (module-scope MCP_TO_PACK) so the executor's pack merge applies them
  // (review Gap: otherwise the plan advertises an MCP nothing enables).
  const packs = [...new Set([
    ...directPacks,
    ...sel.mcps.map((m) => MCP_TO_PACK[m]).filter(Boolean),
  ])].sort();
  const plugins = (choices.plugins || []).sort();
  const extras = (choices.extras || []).sort();
  return {
    skills: sel.skills.map((name) => ({ name, ...whoPulled("skills", name, directSkills, "skills") })),
    agents: sel.agents.map((name) => ({ name, ...whoPulled("agents", name, directAgents, "agents") })),
    mcps: sel.mcps.map((name) => ({ name, ...whoPulled("mcps", name, directPacks, "packs") })),
    packs, plugins, extras,
    warnings: sel.warnings,
  };
}
