# PLAN: CLI parity pass — --target auto + short flags

**Branch**: feat/564
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/564
**Base**: main

## Acceptance Criteria

- [x] `add <skill> --target auto --yes` installs to every harness whose config dir exists; none detected → non-zero exit naming the explicit `--target` values
- [x] `--dry-run --target auto` previews without writing and lists resolved targets
- [x] Explicit `--target <t>` overrides auto; `auto` combines with `--project` only for targets that have project destinations (downgrade note preserved)
- [ ] `-y`, `-p`, `rm`, and `list <what>` all work as aliases of their long forms
- [ ] `--help` documents every new flag/alias + the two divergence notes
- [ ] New tests per item; full `bats tests/` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` `parseArgs` (adds `-y`, `-p`) | #563's `-g` case (merged) | every CLI invocation | low |
| `installer/init.mjs` main dispatch (`auto` loop, `rm`, `list`) | parseArgs aliases; `AUTO_TARGET_PROBES` | `cmdAdd`/`cmdRemove`/`cmdList` (unchanged signatures) | medium |
| `installer/init.mjs` `AUTO_TARGET_PROBES` + `detectInstalledHarnesses()` | — | main dispatch only | low |
| help text (USAGE/FLAGS/SCOPE) | all of the above | CLI users, docs | low |
| `tests/init.bats` | installer behavior | CI | low |

The preset/init flow does NOT gain auto (existing die-on-non-opencode contract preserved — auto there dies with the existing-style message); npx-skills divergence notes (user-scope default; copy-per-target) are documented, not changed.

## Implementation Phases

### Phase 1: `--target auto`

- [x] **1.1** In `installer/init.mjs`: add `AUTO_TARGET_PROBES` (opencode → `USER_OC`; agents → `~/.agents`; claude → `$CLAUDE_CONFIG_DIR` or `~/.claude`; kimi → `~/.kimi-code`; kilo → `~/.config/kilo` or `~/.kilo`) + `detectInstalledHarnesses()` (ordered keys, `existsSync` filter); add an `add`-only dispatch branch in `main()` before `cmdAdd`: resolve detected set → empty dies (exit 2) naming the searched dirs and the explicit `--target` values; print `--target auto: detected <set>` to stderr; loop `cmdAdd` once per resolved target — for project scope, dedupe through each target's project resolution first (agents/claude downgrade → opencode, so unique effective targets only); `--dry-run` flows through unchanged.
    — **Why:** this is the npx-skills `detectInstalledAgents()` equivalent — the only genuine feature gap from the parity pass (#564).
    — **Done when:** `node --check` passes; sandboxed `HOME` with only `~/.agents` present: `add tdd-workflow-skill --target auto --yes` installs to `~/.agents/skills/`; empty `HOME`: exits 2 naming searched dirs.
    — **Consumers affected:** `add` (user + project scope); preset flow explicitly excluded (dies via its existing non-opencode target check if forced).
    — **Done:** AUTO_TARGET_PROBES (config-root probes, CLAUDE_CONFIG_DIR honored) + detectInstalledHarnesses() + add-only dispatch loop with project dedupe on effective target; empty detection dies exit 2 naming searched dirs; files: installer/init.mjs; fixes: agents probe corrected from subdir constants to the ~/.agents root
- [x] **1.2** Help text: `--target` FLAGS line gains `auto (detect installed harnesses)`; USAGE block notes auto.
    — **Done when:** `--help` prints the auto mention.
    — **Why:** undocumented accepted values are drift bait.
    — **Consumers affected:** CLI users.
    — **Done:** --target FLAGS line now lists auto (detect installed harnesses); files: installer/init.mjs; fixes: none
- [x] **1.3** Tests in `tests/init.bats`: (a) empty sandboxed HOME → `--target auto` exits non-zero with "no harness config directories detected"; (b) `mkdir -p $HOME/.agents` → `add tdd-workflow-skill --target auto --yes` → `~/.agents/skills/tdd-workflow-skill` exists; (c) `mkdir -p $HOME/.agents $HOME/.claude` → `add tdd-workflow-skill --project "$TMP_PROJ" --target auto --yes` → project dir exists exactly once (dedupe: both downgrade to opencode project), no user-scope writes.
    — **Done when:** the three tests pass.
    — **Why:** detection is machine-state-dependent — sandboxed HOME makes it deterministic.
    — **Consumers affected:** CI gates.
    — **Done:** three tests: none-detected exit 2, detected-agents install, project dedupe (no user-scope writes); files: tests/init.bats; fixes: none
- [x] **1.4** Gate: `bats tests/init.bats` green.
    — **Done when:** exit 0.
    — **Why:** behavioral proof before alias work stacks.
    — **Consumers affected:** Phases 2–3 gates.
    — **Done:** bats tests/init.bats → 37 ok / 0 not ok, exit 0; files: none; fixes: agents probe (above)

### Phase 2: short flags + command aliases

- [ ] **2.1** `parseArgs`: `-y` → `opts.yes = true`; `-p` → `opts.project = true` (boolean — cwd default already handled by `cmdAdd`'s `opts.project === true` path); add `-y`/`-p` recognition before the `--` branch, mirroring the `-g` case (including the value-eat rule: a long flag followed by `-y`/`-p` must NOT consume them — extend the `next === "-g"` guard to `next === "-g" || next === "-y" || next === "-p"`).
    — **Why:** npx-skills muscle memory; the value-eat lesson is the #563 review's LEARNINGS entry applied at introduction time.
    — **Done when:** `add tdd-workflow-skill --project "$TMP_PROJ" -y` installs; `--project -y` does not create a `./-y` dir (conflict-free combo: `-y` booleanizes).
    — **Consumers affected:** all CLI flows.
- [ ] **2.2** Dispatch aliases: `rm` → `cmdRemove`; `list <what>` and `ls <what>` → `cmdList` (bare `list`/`ls` without a category → die naming valid categories).
    — **Done when:** `rm <name>` removes a user-scope install; `list skills` output equals `--list skills`; bare `ls` exits non-zero naming categories.
    — **Why:** ticket AC — npx-skills command spellings.
    — **Consumers affected:** CLI users.
- [ ] **2.3** Help text: USAGE gains `rm`/`list` alias lines; FLAGS gains `-y`, `-p`; SCOPE gains the two deliberate-divergence notes (scope default is USER here vs npx skills' project default; per-target COPIES vs symlinks — model/permission translations require real files).
    — **Done when:** `--help` shows all four; grep confirms the divergence sentences.
    — **Why:** ticket AC — document the parity surface AND the two intentional inversions so future contributors don't "fix" them.
    — **Consumers affected:** CLI users, contributors.
- [ ] **2.4** Tests: `-p` alias project install from cwd; `-y` alias non-interactive add; `rm` removes a prior install; `list skills` JSON equals `--list skills` output; bare `ls` non-zero.
    — **Done when:** all pass.
    — **Why:** aliases are contract — pin each.
    — **Consumers affected:** CI gates.
- [ ] **2.5** Gate: `bats tests/init.bats` green.
    — **Done when:** exit 0.
    — **Why:** scoped affected suite.
    — **Consumers affected:** Phase 3 gate.

### Phase 3: Full exit gate

- [ ] **3.1** Full `bats tests/` (target suites exercise the parser/dispatch on every path).
    — **Why:** ticket exit gate — full tier; parseArgs/dispatch changes touch every invocation.
    — **Done when:** exit 0; `GATE <short-sha> tier=full` in the trace.
    — **Consumers affected:** Step 9/10 citations.

## Technical Notes

- `auto` is NOT a TARGETS row — it resolves to a target set before dispatch, so TARGET_VALUES validation, translations, manifests, and downgrade notes all keep working unchanged.
- Preset/init flow: `--target auto` is rejected by its existing non-opencode die (style-consistent); documenting in help is enough.
- Detection probes user-scope config roots only (mirrors npx skills' config-root existence checks; `CLAUDE_CONFIG_DIR` honored).
- `-y`/`-p` conflict interplay: `-p` + `-g` → existing #563 guard fires (global vs project); `-y` never conflicts.

## Dependencies

- blocked-by: #563 (the `-g` parse case and its guard are prerequisites of the value-eat extension in 2.1) — merged before this PLAN.

## Risks & Mitigation

- **Dispatch loop double-writes for project scope** (detected [opencode, claude] both downgrading): mitigated by dedupe on effective project target before looping.
- **Machine-state dependence in tests**: mitigated by the suite's HOME sandbox — probes only see the sandbox.
