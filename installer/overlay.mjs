// Shared agent-body composition: LCD core + per-target overlay append (#576).
//
// SINGLE SITE for the overlay rule (learning: parallel-write-path-bypasses-
// composition-hook) — consumed by BOTH agent write paths:
//   - installer/init.mjs add loop (per-target agentMode transform FIRST, then compose)
//   - deploy/setup.sh full deploy via resolve-models.mjs renderAgent (compose BEFORE injectModel)
//
// Rule (docs/subagent-portability-contract.md):
//   - overlay file = agents/overlays/<stem>.<target>.md, appended blank-line separated
//   - verbatim agentMode NEVER composes (the `agents` target is the neutral interchange copy)
//   - absent overlay = unchanged body
import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";

// Agent modes that must never compose. `verbatim` = the agents/ interchange
// target; `.agents.md` overlay files are invalid by contract.
const NO_COMPOSE_MODES = new Set(["verbatim"]);

export async function composeAgentBody({ stem, body, agentsSrc, target, agentMode = "", warn = () => {} }) {
  if (!target || NO_COMPOSE_MODES.has(agentMode)) return body;
  const file = join(agentsSrc, "overlays", `${stem}.${target}.md`);
  if (!existsSync(file)) return body;
  let overlay;
  try {
    overlay = await readFile(file, "utf8");
  } catch (e) {
    warn(`overlay unreadable, skipped (${file}): ${e.message}`);
    return body;
  }
  warn(`composed overlay ${stem}.${target}.md`);
  const base = body.endsWith("\n") ? body : body + "\n";
  return base + "\n" + overlay.trimEnd() + "\n";
}
