#!/usr/bin/env node
// Hermetic invocation of the shared compose helper for the bats guards (#576).
// Usage: compose_agent.mjs <stem> <target> [agentMode]
//   agentMode defaults to "model-injected"; pass "verbatim" to exercise the
//   never-compose rule. Composed body goes to stdout.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { composeAgentBody } from "../../installer/overlay.mjs";

const repo = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const [stem, target, agentMode = "model-injected"] = process.argv.slice(2);
const body = readFileSync(join(repo, "agents", `${stem}.md`), "utf8");
process.stdout.write(await composeAgentBody({ stem, body, agentsSrc: join(repo, "agents"), target, agentMode, warn: (m) => console.error(m) }));
