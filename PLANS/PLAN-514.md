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

- [x] **1.1** Add `metadata.harness: "opencode"` to the 12 Tier A skills — `opencode-agent-creation`, `opencode-skill-creation`, `opencode-skills-maintainer`, `opencode-repo-setup`, `opencode-v2-migration`, `agent-introspection-debugging`, `context-budget`, `documentation-sync-workflow`, `documentation-consistency`, `strategic-compact`, `continuous-learning`, `plan-execution-skill`. Quoted string per the Mode R ruling. Census (base-tree grep, re-verified at code review — the plan-stage census was itself wrong): 5 files HAVE `metadata:` (opencode-skills-maintainer, opencode-v2-migration, documentation-consistency, continuous-learning, plan-execution) → append the sub-key; 7 LACK it (opencode-agent-creation, opencode-skill-creation, opencode-repo-setup, agent-introspection-debugging, context-budget, documentation-sync-workflow, strategic-compact) → insert a new block. Never create a second `metadata:` key — the parser merges duplicate markers silently (build-registry.mjs:143).
    — **Why:** these skills are about OpenCode itself; the marker powers the #514-installed cross-target warning.
    — **Done when:** `rg -l 'harness: "opencode"'` returns all 12.
    — **Consumers affected:** build-registry extraction (Phase 2); #515 guard.
    — **Done:** 12/12 carry `harness: "opencode"` (census corrected pre-execution: 6 appended, 6 new blocks — plan-review finding 2); no duplicate `metadata:` markers; files: 12 SKILL.md; fixes: plan census error caught at review    — **Done:** 12/12 files carry `harness: "opencode"` (census corrected pre-execution: 6 appended, 6 new blocks — plan-review finding 2); no duplicate `metadata:` markers; files: 12 SKILL.md; fixes: plan census error caught at review
- [x] **1.2** Add `metadata.os: "linux"` to `playwright-responsive-audit-skill` (xvfb/pkill/DISPLAY) and `cad-viewer-skill` (ROS 2/MoveIt2).
    — **Why:** honest platform declarations; installer warns on installs elsewhere.
    — **Done when:** `rg -l 'os: "linux"'` returns both.
    — **Consumers affected:** installer OS warning; playwright Windows users get a heads-up (skill remains usable headless).
### Phase 2: registry extraction

- [x] **2.1** `installer/build-registry.mjs` — extend the skill entry (:222-223 area) with `os: (meta.os || "").split(/,\s*/).filter(Boolean)` and `harness: meta.harness || ""`; update the entry-shape doc comments (:14, :30).
    — **Why:** init.mjs reads registry.json only — this is the sole carrier (Mode R ruling, #512 relay).
    — **Done when:** regenerated registry.json shows `os`/`harness` on exactly the 14 marked skills and `[]`/`""` on the rest.
    — **Consumers affected:** init.mjs warnings (Phase 3).

### Phase 3: installer warnings

    — **Done:** extractor extended (os split-to-array, harness string) + entry-shape doc comments updated; regenerated registry.json carries os/harness on exactly the 14 marked skills ([]/"" elsewhere); --check GREEN; files: installer/build-registry.mjs, installer/registry.json; fixes: none- [x] **3.1** `installer/init.mjs` — helper pushing into the existing `sel.warnings` bus, called at exactly TWO sites after effective-target resolution: `writeUserScopeInstall` after the target normalization (~:707, harness warn iff `"opencode" ∉ activeTargets(target)` so `both` never warns) and `writeInstall` after `--project` target degradation (~:366). NOT in `resolveSelection` (target-free pure resolver shared with deploy picker + tests) and NOT in cmdAdd (its `--all` path bypasses target context): (a) `skill.harness === "opencode"` and effective target ≠ `opencode` → cross-harness warning; (b) `skill.os.length > 0` and mapped host platform (`darwin→macos`, `win32→windows`, `linux→linux`; unmapped platforms → warn — intentional honesty) not in `skill.os` → OS warning. Non-fatal; prints like existing warnings.
    — **Why:** honest cross-target installs (#509 epic); warnings mirror the lossy-translation style.
    — **Done when:** dry-run on a Tier A skill with `--target claude` emits the warning; opencode-target installs stay warning-free.
    — **Consumers affected:** installer users.
    — **Done:** pushPortabilityWarnings helper (PLATFORM_OS map, unmapped platforms warn intentionally) called at the two writer sites post-effective-target resolution — writeInstall [pTarget] and writeUserScopeInstall activeTargets(target) (both never warns); resolveSelection/cmdAdd untouched per plan-review integration ruling; files: installer/init.mjs; fixes: integration point per architecture review- [x] **3.2** Smoke test BOTH probe shapes under a sandboxed HOME: (a) `--dry-run` (warning in the JSON), and (b) the AC verbatim — the real non-dry `node installer/init.mjs add opencode-v2-migration-skill --target claude` (warning at the user-scope print site). Capture both warning lines in the PLAN.
    — **Why:** the ticket AC is observable installer output, not code existence.
    — **Done when:** warning line captured; no files written (dry-run).
    — **Consumers affected:** none (read-only probe).

### Phase 4: exit gate

    — **Done:** probes under sandboxed HOME (/tmp/opencode/fakehome): (A) --dry-run --target claude → warning in JSON; (B) AC verbatim real install → warning printed; (C) control opencode-target → 0 warnings; (D) OS branch win32-simulated → correct; files: none (read-only probes); fixes: none- [x] **4.1** Full gate: bats suite + `node installer/build-registry.mjs --check` (plain runs churn generatedAt — use --check) + `git diff origin/main...HEAD -- installer/registry.json` shows only `os`/`harness` additions + count checks unchanged (34 agents / 146 skills).
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
    — **Done:** --check GREEN; full bats 529/529; registry diff = os/harness additions + counts unchanged (34/146); files: none (verification); fixes: none
## Gate Trace

GATE e23bf4e tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a
Note: build axis = `build-registry.mjs --check` + regen shape audit (os/harness on exactly 14 skills); lint axis = coverage probes (12+2 frontmatter, 4/4 smoke probes). Later PLAN-only commits are tree-equivalent; CI is the unconditional re-run.

### Phase 5: Review fixes (post-Step-9)

- [x] **5.1** Repair the LEARNINGS batch: rewrite plan-per-file-census (had heredoc-script tail), create the missing decisions file, append the 3 missing _index entries; add the review's learning-write-heredoc candidate.
    — **Why:** review Major-1 — learnings stored corrupted and unfindable, gate-invisible.
    — **Done when:** anti-pattern file is markdown-only; decisions file exists; index gained 3 entries.
    — **Consumers affected:** future LEARNINGS recall; #515 authors.
    — **Done:** all three repaired + heredoc-anti-pattern captured; files: LEARNINGS/*; fixes: heredoc-as-content corruption
- [x] **5.2** Correct the PLAN 1.1 census to the base-tree truth (5 append / 7 new; opencode-skill-creation had none) and fix the learning file's census line.
    — **Why:** review Major-2 — the record feeds #515's guard authorship.
    — **Done when:** PLAN + learning state 5/7 with opencode-skill-creation in the lacks-list.
    — **Consumers affected:** #515 guard.
    — **Done:** corrected in both; files: PLANS/PLAN-514.md, LEARNINGS/anti-patterns/plan-per-file-census-unverified.md; fixes: twice-wrong census documented as the instance
- [x] **5.3** Restore the newline after the resolveSelection signature (review NOTE — edit artifact in an exported pure function) and add `.map((x) => x.trim())` to the os split (robustness against "linux , macos" spellings).
    — **Why:** NOTEs adopted — one edit artifact, one robustness gap.
    — **Done when:** signature on its own line; trim present.
    — **Consumers affected:** resolveSelection callers (none — cosmetic); os extraction edge.
    — **Done:** both applied; files: installer/init.mjs, installer/build-registry.mjs; fixes: none

## Gate Trace (review-fix)

GATE 5511a6f tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a
