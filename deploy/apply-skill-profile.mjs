#!/usr/bin/env node
// Apply a skill profile (lean|full) to a DEPLOYED opencode config (v2 shape).
//
// Rewrites ONLY the skill entries of the target config's `permissions` array
// (rules with `action: "skill"`); all other permission entries pass through:
//   lean -> [{ resource: "*", effect: "deny" }, ...<lean keys>: "allow"]   (from skill-profiles.json)
//   full -> no-op (deploy verbatim; the shipped opencode.json IS the full profile)
//
// v2 `permissions` arrays use last-match-wins, so the deny-all skill rule is
// emitted first and the allows after it.
// Never edits the source `deploy/opencode.json` (single source of truth).
// Mirrors merge-packs.mjs CLI conventions so setup.sh can call it the same way.

import { readFileSync, writeFileSync, existsSync } from "node:fs";

function usage() {
  console.log(`Usage: node apply-skill-profile.mjs --config <path> --profiles <path> [--profile lean|full]
   or: node apply-skill-profile.mjs --reconcile-shipped <shipped-config> --config <deployed-config> --skills-dir <repo>/skills --deployed-skills-dir <deployed>/skills [--dry-run]

  --config    Path to the DEPLOYED opencode.json to patch in place.
  --profiles  Path to deploy/skill-profiles.json (lean key list).
  --profile   Profile to apply. Default: lean. "full" is a verified no-op:
              the config keeps the shipped allowlist verbatim.
  --reconcile-shipped <path>   Declined-copy migration (#625): merge the shipped
              config's skill-allow rules into the DEPLOYED config's permissions —
              add missing shipped allows, drop rules whose resource no longer
              exists under --skills-dir OR --deployed-skills-dir, preserve
              everything non-skill. --dry-run prints the would-be changes.
  --skills-dir / --deployed-skills-dir   Resource-existence roots for the
              reconcile drop predicate (a rule survives if the resource exists
              in either).

Exits non-zero on: missing/unparseable config or profiles, unknown profile,
lean keys not present in the config's shipped skill allows (guards typo'd keys).`);
}

const args = process.argv.slice(2);
function argValue(flag) {
  const i = args.indexOf(flag);
  if (i === -1) return undefined;
  return args[i + 1];
}

const configPath = argValue("--config");
const profilesPath = argValue("--profiles");
const profile = argValue("--profile") ?? "lean";
const reconcileShipped = argValue("--reconcile-shipped");
const skillsDir = argValue("--skills-dir");
const deployedSkillsDir = argValue("--deployed-skills-dir");
const dryRun = args.includes("--dry-run");

if (!configPath) {
  usage();
  process.exit(1);
}
if (reconcileShipped && (!skillsDir || !deployedSkillsDir)) {
  console.error("apply-skill-profile: --reconcile-shipped requires --skills-dir and --deployed-skills-dir");
  process.exit(1);
}
if (!reconcileShipped && !profilesPath) {
  usage();
  process.exit(1);
}
if (!reconcileShipped && !["lean", "full"].includes(profile)) {
  console.error(`apply-skill-profile: unknown profile "${profile}" (expected lean|full)`);
  process.exit(1);
}
for (const p of [configPath, profilesPath, reconcileShipped].filter(Boolean)) {
  if (!existsSync(p)) {
    console.error(`apply-skill-profile: file not found: ${p}`);
    process.exit(1);
  }
}

const config = JSON.parse(readFileSync(configPath, "utf8"));

// ── Reconcile mode (#625): declined-copy migration ────────────────────────
// Merge the shipped config's skill-allow rules into the DEPLOYED config's
// permissions. Drop predicate: a rule dies only if its resource exists in
// NEITHER the repo skills dir NOR the deployed skills dir (user-authored
// customs live only in the latter and always survive). Everything non-skill
// passes through untouched. --dry-run prints and writes nothing.
if (reconcileShipped) {
  const shippedCfg = JSON.parse(readFileSync(reconcileShipped, "utf8"));
  const isSkillAllow = (r) => r && r.action === "skill" && r.effect === "allow" && r.resource !== "*";
  const deployedAllows = (config.permissions ?? []).filter(isSkillAllow).map((r) => r.resource);
  const shippedAllows = (shippedCfg.permissions ?? []).filter(isSkillAllow).map((r) => r.resource);
  const exists = (res) => existsSync(`${skillsDir}/${res}`) || existsSync(`${deployedSkillsDir}/${res}`);

  const toAdd = shippedAllows.filter((r) => !deployedAllows.includes(r) && exists(r));
  const toDrop = deployedAllows.filter((r) => !shippedAllows.includes(r) && !exists(r));
  const keptCustom = deployedAllows.filter((r) => !shippedAllows.includes(r) && exists(r));

  if (dryRun) {
    console.log(`reconcile (dry run): would add ${toAdd.length}, would drop ${toDrop.length}, kept custom ${keptCustom.length}`);
    if (toAdd.length) console.log(`  add: ${toAdd.join(", ")}`);
    if (toDrop.length) console.log(`  drop: ${toDrop.join(", ")}`);
    process.exit(0);
  }

  const denyRule = (config.permissions ?? []).find((r) => r.action === "skill" && r.resource === "*" && r.effect === "deny");
  const nonSkillRules = (config.permissions ?? []).filter((r) => !(r && r.action === "skill"));
  const mergedAllows = [...new Set([...deployedAllows.filter((r) => !toDrop.includes(r)), ...toAdd])].sort();
  config.permissions = [
    ...nonSkillRules,
    denyRule ?? { action: "skill", resource: "*", effect: "deny" },
    ...mergedAllows.map((resource) => ({ action: "skill", resource, effect: "allow" })),
  ];
  writeFileSync(configPath, JSON.stringify(config, null, 2) + "\n");
  console.log(`reconcile: added ${toAdd.length}, dropped ${toDrop.length}, kept ${keptCustom.length} custom allows; deny-first preserved`);
  process.exit(0);
}

const profiles = reconcileShipped ? null : JSON.parse(readFileSync(profilesPath, "utf8"));

const isSkillRule = (r) => r && r.action === "skill";
const skillAllows = (cfg) =>
  (cfg.permissions ?? [])
    .filter((r) => isSkillRule(r) && r.effect === "allow" && r.resource !== "*")
    .map((r) => r.resource);

if (profile === "full") {
  console.log(`apply-skill-profile: full — deployed verbatim (${skillAllows(config).length} allows, no rewrite)`);
  process.exit(0);
}

const lean = profiles.lean;
if (!Array.isArray(lean) || lean.length === 0) {
  console.error("apply-skill-profile: profiles file has no non-empty .lean array");
  process.exit(1);
}

const shipped = new Set(skillAllows(config));
const missing = lean.filter((k) => !shipped.has(k));
if (missing.length > 0) {
  console.error(
    `apply-skill-profile: lean keys not present in shipped skill allows (typo guard): ${missing.join(", ")}`
  );
  console.error(
    `Hint: the deployed config's skill allows are stale (skill renames land in deploy/opencode.json, not in an existing config you declined to overwrite). Re-run ./deploy/setup.sh and ACCEPT the config copy — models are re-resolved afterward; back up the old config first if you customized beyond models.`
  );
  process.exit(1);
}

const rebuilt = [
  { action: "skill", resource: "*", effect: "deny" },
  ...[...lean].sort().map((resource) => ({ action: "skill", resource, effect: "allow" })),
];
config.permissions = [...(config.permissions ?? []).filter((r) => !isSkillRule(r)), ...rebuilt];

writeFileSync(configPath, JSON.stringify(config, null, 2) + "\n");
console.log(
  `apply-skill-profile: lean — deployed permissions array rewritten to ${lean.length} skill allows + deny-all skill rule`
);
