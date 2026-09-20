#!/usr/bin/env node
// Regenerate installer/provider-models.json from the models.dev catalog (#472).
//
//   node deploy/regen-provider-models.mjs                 # fetch + write
//   node deploy/regen-provider-models.mjs --check         # warn-only drift diff
//   node deploy/regen-provider-models.mjs --catalog F     # offline fixture (tests)
//
// Byte-stable output: provider keys keep the shipped file's order, ids are
// sorted, 2-space JSON + trailing newline. Uncataloged prefixes (zai-custom)
// and the $comment are preserved verbatim; a shipped KNOWN-catalog provider
// missing from the catalog is an error (typo detection — no silent skips).

import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const TARGET = join(HERE, "..", "installer", "provider-models.json");
const CATALOG_URL = "https://models.dev/api.json";
const KNOWN_CATALOG_PROVIDERS = new Set(["zai", "zai-coding-plan", "anthropic", "openai"]);

const args = process.argv.slice(2);
let catalogFile = null, checkOnly = false;
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--catalog") catalogFile = args[++i];
  else if (args[i] === "--check") checkOnly = true;
  else { console.error(`unknown argument: ${args[i]}`); process.exit(2); }
}

async function loadCatalog() {
  if (catalogFile) return JSON.parse(readFileSync(catalogFile, "utf8"));
  const res = await fetch(CATALOG_URL, { signal: AbortSignal.timeout(15000) });
  if (!res.ok) throw new Error(`catalog fetch failed: HTTP ${res.status}`);
  return res.json();
}

const shipped = JSON.parse(readFileSync(TARGET, "utf8"));
let catalog;
try {
  catalog = await loadCatalog();
} catch (err) {
  console.error(`regen: catalog unavailable — ${err.message}`);
  process.exit(1);
}

let fatal = false;
const regenerated = {};
// A missing KNOWN provider is fatal only when OTHER known providers are
// present in the catalog (real breakage). A partial catalog — e.g. an
// offline test fixture — legitimately omits some providers, so absence
// there means "fixture scope", and the prefix is preserved untouched.
const knownInCatalog = [...KNOWN_CATALOG_PROVIDERS].filter((k) => catalog[k]?.models);
for (const key of Object.keys(shipped)) {
  if (key === "$comment") { regenerated[key] = shipped[key]; continue; }
  const entry = catalog[key];
  if (!entry || !entry.models || typeof entry.models !== "object") {
    if (KNOWN_CATALOG_PROVIDERS.has(key) &&
        knownInCatalog.some((k) => k !== key)) {
      // A known-catalog provider absent from a real catalog is a
      // typo/breakage — never a silent skip (the #468 blind-spot class).
      console.error(`regen: shipped provider '${key}' is missing from the catalog — refusing to drop it. Fix the key name or the catalog source.`);
      fatal = true;
      regenerated[key] = shipped[key];
    } else {
      // Genuinely non-catalog prefix (zai-custom) or partial-fixture scope:
      // preserve untouched.
      regenerated[key] = shipped[key];
    }
    continue;
  }
  regenerated[key] = Object.keys(entry.models).sort();
}

if (checkOnly) {
  let drifted = false;
  for (const key of Object.keys(shipped)) {
    if (key === "$comment" || !catalog[key]?.models) continue;
    const live = new Set(Object.keys(catalog[key].models).sort());
    const have = new Set(shipped[key]);
    const missing = [...live].filter((id) => !have.has(id));
    const extra = have.has(null) ? [] : [...have].filter((id) => !live.has(id));
    if (missing.length || extra.length) {
      drifted = true;
      if (missing.length) console.warn(`[check-catalog] ${key}: in catalog but NOT shipped — ${missing.join(", ")}`);
      if (extra.length) console.warn(`[check-catalog] ${key}: shipped but NOT in catalog — ${extra.join(", ")}`);
    }
  }
  if (drifted) {
    console.warn("[check-catalog] provider-models.json has drifted from models.dev — run: node deploy/regen-provider-models.mjs");
  } else {
    console.log("[check-catalog] provider-models.json matches the live models.dev catalog");
  }
  if (fatal) process.exit(1);
  process.exit(0); // warn-only: drift is a warning, not an error (#472)
}

if (fatal) process.exit(1);
writeFileSync(TARGET, JSON.stringify(regenerated, null, 2) + "\n");
console.log(`regen: wrote ${TARGET} (${Object.keys(regenerated).filter((k) => k !== "$comment").length} providers)`);
