# PLAN: Auto-install prerequisite skills on npx add (requiresSkills edge)

**Branch**: feat/439
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/439
**Base**: main

## Acceptance Criteria

- [ ] AC1: `dependency-map.json` carries a `requiresSkills` edge and `resolveSelection` consumes it (unknown names warn, matching existing behavior)
- [ ] AC2: `add pptx-template-modifier-skill` auto-installs `pptx-generate-slide-skill` with a visible notice; `--no-deps` installs only the named skill
- [ ] AC3: Dry-run output lists the auto-added skill; user-scope manifest tracks it for update/uninstall
- [ ] AC4: A bats test covers: auto-add on `add`, `--no-deps` opt-out, dry-run listing, and map-entry↔HANDOFF_* consistency
- [ ] AC5: Full bats suite green (including `tests/test_skill_isolation.bats` and existing init/update suites)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/dependency-map.json` (new `requiresSkills` key) | — | `loadDepMap()` → `resolveSelection`, `warnMCPs` (both in init.mjs) | low |
| `installer/init.mjs` `loadDepMap()` (return full map) | 1.1 | exactly two indexing sites: `resolveSelection` (line ~187) and `warnMCPs` (line ~756) — both must switch to `depMap.impliesMcp?.[s]` | med (missed site = MCP hints silently vanish) |
| `installer/init.mjs` `resolveSelection` (skill→skill transitive closure) | 1.1, 1.2 | `cmdAdd`, `--all` path, presets expansion, `--project` path (`writeInstall`) — all route through it | med (closure bug affects every selection path) |
| `installer/init.mjs` `cmdAdd` (auto-add notice) | 1.3 | CLI UX only — stdout text | low |
| user-scope manifest (`writeUserScopeInstall`) | — (already records `sel.skills`) | `update`/`uninstall` commands | low (no code change expected; AC3 verified by test) |
| `tests/test_requires_skills.bats` (new) | Phases 1–2 (asserts their behavior) | CI bats suite | low |
| `installer/registry.json` | — (must NOT change: no frontmatter edits) | installer | low (gate verifies zero diff) |

Cross-module consumers beyond `installer/init.mjs` + tests: **none**. The skills tree is untouched (the pptx prerequisite declaration already shipped in #437). Justifies Step 7 zero-reviewer triage; Step 9 code review backstops.

## Implementation Phases

### Phase 1: Data + resolver
- [ ] **1.1** Add `"requiresSkills": {"pptx-template-modifier-skill": ["pptx-generate-slide-skill"]}` to `installer/dependency-map.json`; update the `$comment` to document both edge types (impliesMcp: skill→MCP; requiresSkills: skill→skill, mirroring the SKILL.md declaration from #437)
    — **Why:** the map is the established non-frontmatter home for installer dependency edges; the edge mirrors the declared modifier→slide handoff (#439 problem statement).
    — **Done when:** JSON parses and `requiresSkills` key present.
    — **Consumers affected:** loadDepMap, the Phase 3 consistency test.

- [ ] **1.2** Change `loadDepMap()` to return the full map (`{ impliesMcp, requiresSkills }`); update both direct-indexing sites (`resolveSelection` line ~187, `warnMCPs` line ~756) to `depMap.impliesMcp?.[sname] || []`
    — **Why:** today loadDepMap flattens to `impliesMcp` only, so a second edge type is invisible to the resolver; both indexing sites must switch together or MCP requirement hints silently disappear (the exact class of partial-proceed breakage).
    — **Done when:** `grep -n 'depMap\[' installer/init.mjs` returns no direct-index hits; markitdown/docling MCP warn behavior unchanged (covered by existing bats suites in AC5).
    — **Consumers affected:** every selection path + MCP warn notice.

- [ ] **1.3** In `resolveSelection`, add skill→skill transitive closure mirroring the agent `delegatesTo` queue: for each selected skill, enqueue its `requiresSkills` entries (unknown names push a warning like the agent path, never a crash), iterate to closure
    — **Why:** this is the single point every selection path (`add`, `--all`, presets, `--project`) already routes through — one closure makes auto-add work everywhere with no per-command code.
    — **Done when:** `resolveSelection({skills:["pptx-template-modifier-skill"]}, reg, map)` resolves to both skills; unknown edge names produce warnings; existing init.bats selection tests stay green.
    — **Consumers affected:** cmdAdd, cmdUpdate paths, TUI selection, presets.

### Phase 2: Visible notice
- [ ] **2.1** In `cmdAdd`, after `resolveSelection` (deps path only), print a notice line naming skills added beyond the requested one (e.g. `also installing required skill(s): pptx-generate-slide-skill (required by pptx-template-modifier-skill)`) before delegating to the write path; `--no-deps` and no-dep cases print nothing extra
    — **Why:** silent auto-install is indistinguishable from a bug at the CLI; one printed line is the contract "visible notice" from AC2.
    — **Done when:** `add pptx-template-modifier-skill` stdout contains the notice; `--no-deps` run does not.
    — **Consumers affected:** CLI users only.

### Phase 3: Tests
- [ ] **3.1** Create `tests/test_requires_skills.bats` (sandboxed-HOME pattern from tests/init.bats): (a) `add pptx-template-modifier-skill --yes` → both skill dirs exist under `$HOME/.config/opencode/skills/` and manifest lists both; (b) `--no-deps` → only the modifier dir; (c) `--dry-run` JSON `skills` array contains both; (d) consistency pin: `dependency-map.json` `requiresSkills` equals exactly the `HANDOFF_OWNER→HANDOFF_TARGET` pair declared in `tests/test_skill_isolation.bats` (grep the pair from that file; JSON equality via python3)
    — **Why:** AC4; (d) makes AGENTS.md's "HANDOFF_* is the source of truth" rule mechanically enforced against the installer edge, so the two can never drift silently.
    — **Done when:** `bats tests/test_requires_skills.bats` green.
    — **Consumers affected:** CI bats suite.

### Phase 4: Verification gates
- [ ] **4.1** Full bats suite (`bats tests/`) + registry sanity (`node installer/build-registry.mjs` → `git diff` empty apart from `generatedAt`, which is reverted)
    — **Why:** AC5 + house rule that registry rebuilds follow frontmatter changes only (none here).
    — **Done when:** full suite exits 0; `git diff --stat installer/registry.json` empty after timestamp revert.
    — **Consumers affected:** none (verification only).

## Technical Notes

- The user-scope manifest already records `sel.skills` (init.mjs `writeUserScopeInstall`), so AC3's manifest half needs no code — only a test proving it.
- Dry-run already dumps `sel.skills` (cmdAdd dry path), so AC3's dry-run half likewise needs no code.
- Do NOT touch the skills tree: the SKILL.md prerequisite declaration shipped with #437; this ticket is installer-side only.
- `--no-deps` already short-circuits `resolveSelection` in `cmdAdd` (init.mjs line ~602) — no change needed there.

## Dependencies

- None external. Follow-up to #437 (declaration) and #304 (npx add model).

## Risks & Mitigation

- **Missed depMap indexing site** (MCP hints vanish): 1.2's done-when greps for direct indexing; existing markitdown/docling bats suites cover the warn path.
- **Selection closure loops** (circular skill deps): closure uses a Set with visited semantics (same as the agent queue) — cycles terminate; a future self-edge would be a no-op.
- **Notice text churn breaking tests**: tests assert the required skill name appears in output, not exact phrasing.
