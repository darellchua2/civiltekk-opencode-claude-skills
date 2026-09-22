# PLAN: Portability metadata + installer target/platform warnings

**Branch**: feat/514
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/514
**Base**: main

## Acceptance Criteria
- [ ] Tier A and OS-limited skills carry correct metadata
- [ ] `npx . add opencode-v2-migration-skill --target claude` prints the portability warning
- [ ] `node installer/build-registry.mjs --check` exits 0 (never a plain-run zero-diff gate — plain runs always churn generatedAt)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| 12 Tier A SKILL.md frontmatter | #510 vocabulary (merged); Mode R spelling ruling (`harness: "opencode"`) | build-registry extraction, #515 guard | low |
| 2 OS-limited SKILL.md frontmatter (playwright-responsive-audit, cad-viewer) | #510 vocabulary | build-registry, installer OS warning | low |
| `installer/build-registry.mjs` | frontmatter values present (Phase 1) | registry.json consumers (init.mjs, README table) | med |
| `installer/init.mjs` | registry carrying `os`/`harness` (Phase 2) | installer users on cross-target/platform installs | med |
| `registry.json` | both installer edits + frontmatter | installer resolver, setup counts | low (generated) |

## Implementation Phases

### Phase 1: frontmatter metadata

- [x] **1.1** Add `metadata.harness: "opencode"` to the 12 Tier A skills — `opencode-agent-creation`, `opencode-skill-creation`, `opencode-skills-maintainer`, `opencode-repo-setup`, `opencode-v2-migration`, `agent-introspection-debugging`, `context-budget`, `documentation-sync-workflow`, `documentation-consistency`, `strategic-compact`, `continuous-learning`, `plan-execution-skill`. Quoted string per the Mode R ruling. Census (verified by tree grep at plan review): 6 files HAVE `metadata:` (opencode-skill-creation, opencode-skills-maintainer, opencode-v2-migration, documentation-consistency, continuous-learning, plan-execution) → append the sub-key; 6 LACK it (opencode-agent-creation, opencode-repo-setup, agent-introspection-debugging, context-budget, documentation-sync-workflow, strategic-compact) → insert a new block. Never create a second `metadata:` key — the parser merges duplicate markers silently (build-registry.mjs:143).
    — **Why:** these skills are about OpenCode itself; the marker powers the #514-installed cross-target warning.
    — **Done when:** `rg -l 'harness: "opencode"'` returns all 12.
    — **Consumers affected:** build-registry extraction (Phase 2); #515 guard.
    — **Done:** 12/12 carry `harness: "opencode"` (census corrected pre-execution: 6 appended, 6 new blocks — plan-review finding 2); no duplicate `metadata:` markers; files: 12 SKILL.md; fixes: plan census error caught at review    — **Done:** 12/12 files carry `harness: "opencode"` (census corrected pre-execution: 6 appended, 6 new blocks — plan-review finding 2); no duplicate `metadata:` markers; files: 12 SKILL.md; fixes: plan census error caught at review
- [ ] **1.2** Add `metadata.os: "linux"` to `playwright-responsive-audit-skill` (xvfb/pkill/DISPLAY) and `cad-viewer-skill` (ROS 2/MoveIt2).
    — **Why:** honest platform declarations; installer warns on installs elsewhere.
    — **Done when:** `rg -l 'os: "linux"'` returns both.
    — **Consumers affected:** installer OS warning; playwright Windows users get a heads-up (skill remains usable headless).
### Phase 2: registry extraction

- [ ] **2.1** `installer/build-registry.mjs` — extend the skill entry (:222-223 area) with `os: (meta.os || "").split(/,\s*/).filter(Boolean)` and `harness: meta.harness || ""`; update the entry-shape doc comments (:14, :30).
    — **Why:** init.mjs reads registry.json only — this is the sole carrier (Mode R ruling, #512 relay).
    — **Done when:** regenerated registry.json shows `os`/`harness` on exactly the 14 marked skills and `[]`/`""` on the rest.
    — **Consumers affected:** init.mjs warnings (Phase 3).

### Phase 3: installer warnings

- [ ] **3.1** `installer/init.mjs` — helper pushing into the existing `sel.warnings` bus, called at exactly TWO sites after effective-target resolution: `writeUserScopeInstall` after the target normalization (~:707, harness warn iff `"opencode" ∉ activeTargets(target)` so `both` never warns) and `writeInstall` after `--project` target degradation (~:366). NOT in `resolveSelection` (target-free pure resolver shared with deploy picker + tests) and NOT in cmdAdd (its `--all` path bypasses target context): (a) `skill.harness === "opencode"` and effective target ≠ `opencode` → cross-harness warning; (b) `skill.os.length > 0` and mapped host platform (`darwin→macos`, `win32→windows`, `linux→linux`; unmapped platforms → warn — intentional honesty) not in `skill.os` → OS warning. Non-fatal; prints like existing warnings.
    — **Why:** honest cross-target installs (#509 epic); warnings mirror the lossy-translation style.
    — **Done when:** dry-run on a Tier A skill with `--target claude` emits the warning; opencode-target installs stay warning-free.
    — **Consumers affected:** installer users.
- [ ] **3.2** Smoke test BOTH probe shapes under a sandboxed HOME: (a) `--dry-run` (warning in the JSON), and (b) the AC verbatim — the real non-dry `node installer/init.mjs add opencode-v2-migration-skill --target claude` (warning at the user-scope print site). Capture both warning lines in the PLAN.
    — **Why:** the ticket AC is observable installer output, not code existence.
    — **Done when:** warning line captured; no files written (dry-run).
    — **Consumers affected:** none (read-only probe).

### Phase 4: exit gate

- [ ] **4.1** Full gate: bats suite + `node installer/build-registry.mjs --check` (plain runs churn generatedAt — use --check) + `git diff origin/main...HEAD -- installer/registry.json` shows only `os`/`harness` additions + count checks unchanged (34 agents / 146 skills).
    — **Why:** frontmatter contract requires committed registry; counts must not drift.
    — **Done when:** suite green; registry diff shape exact; counts unchanged.
    — **Consumers affected:** installer, setup counts, #515 guard (authored against these keys).

## Technical Notes
- Token: `harness: "opencode"`, `os: "linux"` — double-quoted comma-separated strings per Mode R ruling (#510); extractor splits on `/,\\s*/`.
- `os` values vocabulary: `linux`, `macos`, `windows` (lowercase); platform map lives in init.mjs.
- Warning text includes the skill name + the reason ("opencode-only skill", "unsupported on this platform") + "install anyway" hint — non-blocking.
- The `registry.json` regeneratedAt timestamp will move; content diff reviewed for os/harness shape only.

## Dependencies
- blocked-by: #510 (vocabulary), #512/#513 (same-file body edits land first — merged).

## Risks & Mitigation
- *Warning spam on legit installs* → warnings fire only on explicit target/platform mismatch; opencode-target installs unaffected.
- *Registry shape break* → additive keys only; init.mjs consumers ignore unknown fields today (verified: registry reader maps known keys).
- *Playwright os too strict* → ticket-issued scope (`linux`); revisit via the os vocabulary if Windows headless use is reported.
