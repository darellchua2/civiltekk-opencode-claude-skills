#!/usr/bin/env bats

# Tests for the ponytail plugin (plugins/opencode-ponytail-scoped.ts +
# plugins/ponytail/instructions.cjs) — injection content per #533 Phase 1:
# v4.10.0 rewording, gate sentence, marker idempotency, and the persisted
# default mode (env var → config file → full; /ponytail default <mode>).
# Node is guaranteed wherever the installer ran; grep only (no ripgrep on CI runners).

REPO="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
PLUGIN="${REPO}/plugins/opencode-ponytail-scoped.ts"
CJS="${REPO}/plugins/ponytail/instructions.cjs"

# Shared JS prelude: fake v2 ctx capturing commands + hooks, plugin loaded via
# native TS type-stripping (node >= 22.18 / 24). HOME is redirected by the caller.
PRELUDE='
import { pathToFileURL } from "url";
import { createRequire } from "module";
import * as fs from "fs";
const req = createRequire(import.meta.url);
const cfgPath = req("path").join(req("os").homedir(), ".local", "share", "opencode", "ponytail-config.json");
const mod = await import(pathToFileURL(process.env.PONYTAIL_PLUGIN).href);
const cmds = [];
const hooks = {};
const prompts = [];
const ctx = {
  command: { transform: (fn) => fn({ add: (c) => cmds.push(c) }) },
  session: { hook: (n, f) => { hooks[n] = f; }, prompt: async (p) => { prompts.push(p && p.text); } },
};
await mod.default.setup(ctx);
'

# Runs the plugin under a sandboxed HOME (persisted config resolves inside it).
run_plugin() {
  run env HOME="$1" PONYTAIL_PLUGIN="$PLUGIN" node --input-type=module -e "${PRELUDE} $2"
}

setup() {
  export SANDBOX="$(mktemp -d)"
}
teardown() { rm -rf "$SANDBOX"; }

# ── Injection content (#533 steps 1.1/1.6) ─────────────────────────────────────

@test "full-mode injection carries marker, v4.10.0 ceiling wording, gate sentence" {
  run node -e "const m=require('${CJS}');process.stdout.write(m.getPonytailInstructions('full'))"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "PONYTAIL MODE ACTIVE"
  echo "$output" | grep -q "cut a real corner with a known ceiling"
  echo "$output" | grep -q "Lazy code without its check is unfinished"
}

@test "marker appears exactly once (single payload; caller-side guard checks duplicates)" {
  run node -e "const m=require('${CJS}');process.stdout.write(m.getPonytailInstructions('full'))"
  [ "$status" -eq 0 ]
  count="$(echo "$output" | grep -c 'PONYTAIL MODE ACTIVE')"
  [ "$count" -eq 1 ]
}

@test "off mode injects nothing" {
  run node -e "const m=require('${CJS}');process.stdout.write('['+m.getPonytailInstructions('off')+']')"
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]
}

@test "old generic marker wording is gone from the injected ruleset" {
  run node -e "const m=require('${CJS}');process.stdout.write(m.getPonytailInstructions('full'))"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q 'ponytail: this exists'
}

# ── Persisted default mode (#533 step 1.4) ─────────────────────────────────────

@test "/ponytail default <mode> writes the config; a fresh process (restart) picks it up" {
  # Process 1: set the persisted default and prove the file landed under the state dir.
  run_plugin "$SANDBOX" '
const cmd = cmds.find((c) => c.name === "ponytail");
await cmd.execute({ prompt: { text: "default lite" }, sessionID: "s1", delivery: {} });
const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
if (cfg.defaultMode !== "lite") { console.log("FAIL defaultMode=" + cfg.defaultMode); process.exit(1); }
console.log("OK written");
'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "OK written"

  # Process 2 (restart): fresh module load resolves the default from the config file.
  run_plugin "$SANDBOX" '
const system = [];
await hooks.context({ sessionID: "s2", agent: undefined, system });
if (!system[0] || !system[0].text.startsWith("PONYTAIL MODE ACTIVE — level: lite")) {
  console.log("FAIL injected=" + (system[0] && system[0].text.slice(0, 40)));
  process.exit(1);
}
console.log("OK restart-picks-up");
'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "OK restart-picks-up"
}

@test "PONYTAIL_DEFAULT_MODE env var wins over the persisted config file" {
  mkdir -p "${SANDBOX}/.local/share/opencode"
  printf '{"defaultMode":"lite"}' > "${SANDBOX}/.local/share/opencode/ponytail-config.json"
  run env HOME="$SANDBOX" PONYTAIL_PLUGIN="$PLUGIN" PONYTAIL_DEFAULT_MODE=ultra \
    node --input-type=module -e "${PRELUDE}
const system = [];
await hooks.context({ sessionID: 'sx', agent: undefined, system });
if (!system[0] || !system[0].text.startsWith('PONYTAIL MODE ACTIVE — level: ultra')) {
  console.log('FAIL ' + (system[0] && system[0].text.slice(0, 40)));
  process.exit(1);
}
console.log('OK env-wins');
"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "OK env-wins"
}

@test "/ponytail default merges (keeps sibling keys), survives a UTF-8 BOM, rejects invalid modes" {
  mkdir -p "${SANDBOX}/.local/share/opencode"
  printf '\xEF\xBB\xBF{"otherKey":42}' > "${SANDBOX}/.local/share/opencode/ponytail-config.json"
  run_plugin "$SANDBOX" '
const cmd = cmds.find((c) => c.name === "ponytail");
await cmd.execute({ prompt: { text: "default ultra" }, sessionID: "s1", delivery: {} });
await cmd.execute({ prompt: { text: "default bogus" }, sessionID: "s1", delivery: {} });
const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
if (cfg.defaultMode !== "ultra") { console.log("FAIL defaultMode=" + cfg.defaultMode); process.exit(1); }
if (cfg.otherKey !== 42) { console.log("FAIL sibling key clobbered"); process.exit(1); }
if (!prompts.some((t) => t && t.includes("could not set the default"))) {
  console.log("FAIL invalid mode not rejected"); process.exit(1);
}
console.log("OK merge-bom-invalid");
'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "OK merge-bom-invalid"
}

@test "same-process new sessions see the persisted default immediately (no restart needed)" {
  run_plugin "$SANDBOX" '
const cmd = cmds.find((c) => c.name === "ponytail");
// session s1 sets the default; session s2 (SAME process, after the write) injects lite
await cmd.execute({ prompt: { text: "default lite" }, sessionID: "s1", delivery: {} });
const system = [];
await hooks.context({ sessionID: "s2", agent: undefined, system });
if (!system[0] || !system[0].text.startsWith("PONYTAIL MODE ACTIVE — level: lite")) {
  console.log("FAIL injected=" + (system[0] && system[0].text.slice(0, 40)));
  process.exit(1);
}
console.log("OK same-process-pickup");
'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "OK same-process-pickup"
}

@test "unparseable config is backed up before rewrite (.corrupt-* aside), new config valid" {
  mkdir -p "${SANDBOX}/.local/share/opencode"
  printf 'not json at all {{{' > "${SANDBOX}/.local/share/opencode/ponytail-config.json"
  run_plugin "$SANDBOX" '
const cmd = cmds.find((c) => c.name === "ponytail");
await cmd.execute({ prompt: { text: "default ultra" }, sessionID: "s1", delivery: {} });
const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
if (cfg.defaultMode !== "ultra") { console.log("FAIL defaultMode=" + cfg.defaultMode); process.exit(1); }
const dir = req("path").dirname(cfgPath);
const backups = fs.readdirSync(dir).filter((f) => f.startsWith("ponytail-config.json.corrupt-"));
if (backups.length !== 1) { console.log("FAIL backups=" + backups.length); process.exit(1); }
if (!fs.readFileSync(req("path").join(dir, backups[0]), "utf8").includes("not json")) {
  console.log("FAIL backup content mismatch"); process.exit(1);
}
console.log("OK corrupt-backup");
'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "OK corrupt-backup"
}

@test "default-mode resolution falls back to full with no env var and no config file" {
  run_plugin "$SANDBOX" '
const system = [];
await hooks.context({ sessionID: "sf", agent: undefined, system });
if (!system[0] || !system[0].text.startsWith("PONYTAIL MODE ACTIVE — level: full")) {
  console.log("FAIL " + (system[0] && system[0].text.slice(0, 40)));
  process.exit(1);
}
console.log("OK fallback-full");
'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "OK fallback-full"
}
