#!/usr/bin/env node
// deploy/seed-pi-provider.mjs
//
// pi Z.AI provider seeder (#573). Merges a `zai` provider block into the pi
// coding agent's ~/.pi/agent/models.json — merge-never-clobber: sibling
// providers and every other top-level key are preserved byte-for-byte.
//
// Companion to deploy/merge-packs.mjs (same conventions: ES modules, async
// main(), camelCase args, zero external dependencies — Node built-ins only).
//
// Semantics:
//   - Missing config file => starts from {} (parent dirs created).
//   - providers.zai is REPLACED wholesale on re-run (idempotent — our own
//     block is canonical); every other providers.* entry is untouched.
//   - apiKey stays the literal "$ZAI_API_KEY" — pi resolves $VAR env
//     interpolation at runtime, so the secret never lands in the file.
//   - Endpoint: Z.AI PAAS OpenAI chat-completions base (pi speaks
//     openai-completions). NOT the coding-plan endpoint (subscription-bound)
//     and NOT /api/v1 (OpenAI Responses — that is the codex base).
//   - Malformed existing JSON => exit non-zero with path + parse error;
//     nothing written.
//   - --dry-run => print the delta; write nothing; exit 0.
//   - Idempotent: when the serialized output equals current bytes, the file
//     is not rewritten (mtime preserved).
//   - Output file mode 0600 (provider config is user-private).
//
// Usage:
//   node seed-pi-provider.mjs --config <models.json> [--dry-run]

import { chmodSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const ZAI_PROVIDER = {
  api: "openai-completions",
  baseUrl: "https://api.z.ai/api/paas/v4",
  apiKey: "$ZAI_API_KEY",
  models: [
    {
      id: "glm-5.3",
      name: "GLM-5.3",
      reasoning: true,
      contextWindow: 200000,
      maxTokens: 32768,
    },
    {
      id: "glm-5.3-flash",
      name: "GLM-5.3 Flash",
      contextWindow: 1000000,
      maxTokens: 32768,
    },
  ],
};

function parseArgs(argv) {
  const args = { config: null, dryRun: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--config") args.config = argv[++i];
    else if (a === "--dry-run") args.dryRun = true;
    else {
      console.error(`Unknown argument: ${a}`);
      process.exit(1);
    }
  }
  if (!args.config) {
    console.error("Usage: node seed-pi-provider.mjs --config <models.json> [--dry-run]");
    process.exit(1);
  }
  return args;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  let config = {};
  let before = null;
  try {
    before = readFileSync(args.config, "utf8");
  } catch {
    // Missing file is the fresh-install path, not an error.
  }
  if (before !== null) {
    try {
      config = JSON.parse(before);
    } catch (err) {
      console.error(`Cannot parse ${args.config}: ${err.message} — nothing written`);
      process.exit(1);
    }
    if (typeof config !== "object" || config === null || Array.isArray(config)) {
      console.error(`${args.config}: top level must be a JSON object — nothing written`);
      process.exit(1);
    }
  }

  if (!config.providers || typeof config.providers !== "object") {
    config.providers = {};
  }
  config.providers.zai = ZAI_PROVIDER;

  const after = JSON.stringify(config, null, 2) + "\n";
  const siblings = Object.keys(config.providers).filter((k) => k !== "zai");

  if (args.dryRun) {
    console.log(`[DRY-RUN] Would seed providers.zai into ${args.config}`);
    console.log(`[DRY-RUN] Preserved sibling providers: ${siblings.join(", ") || "(none)"}`);
    console.log(`[DRY-RUN] apiKey: "$ZAI_API_KEY" (pi env-interpolation form — no secret stored)`);
    return;
  }

  if (after === before) {
    console.log(`${args.config}: zai provider already current — no write`);
    return;
  }

  mkdirSync(dirname(args.config), { recursive: true });
  writeFileSync(args.config, after);
  try {
    chmodSync(args.config, 0o600);
  } catch {
    // chmod is best-effort (exotic filesystems); the write already succeeded.
  }
  console.log(`${args.config}: zai provider seeded (siblings preserved: ${siblings.join(", ") || "none"})`);
  console.log(`  activate: pi --provider zai --model glm-5.3 (or pick via /model)`);
}

main().catch((err) => {
  console.error(err && err.message ? err.message : err);
  process.exit(1);
});
