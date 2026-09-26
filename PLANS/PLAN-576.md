# PLAN: Standardize subagents across harnesses: docs + pilot

**Branch**: feat/576
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/576
**Base**: main

## Acceptance Criteria
- [ ] `docs/harness-landscape-2026-09.md` covers the harness comparison (OpenCode, Claude Code, Codex, Copilot, ZCode, Kilo, pi, M365 Copilot), the standards layer (Agent Skills / AGENTS.md / MCP / ACP), and the standardization strategy
- [ ] `docs/subagent-portability-contract.md` specifies LCD rules, overlay convention, composition pipeline, and the lossy-translation registry
- [ ] 3 pilot agents (code-review-subagent, image-analyzer-subagent, requirements-specialist-subagent) retrofitted with behavior-equivalent OpenCode output
- [ ] Installer appends overlay fragments when present for the active target; manifest hashes track composed output
- [ ] `node installer/build-registry.mjs` run, registry.json committed; bats tests pass

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `docs/harness-landscape-2026-09.md` (new) | — | `docs/subagent-portability-contract.md` (references its conclusions) | low |
| `docs/subagent-portability-contract.md` (new) | landscape doc (1.1) | pilot retrofits (2.1–2.3), installer hook (3.1), future agent authoring | low |
| `agents/code-review-subagent.md` + `agents/overlays/code-review-subagent.opencode.md` | contract doc (1.2) | primary sessions delegating code review, `registry.json` (frontmatter extraction), `installer/init.mjs` write path | medium |
| `agents/image-analyzer-subagent.md` + `agents/overlays/image-analyzer-subagent.opencode.md` | contract doc (1.2) | responsive-audit, pptx-specialist, uiux-reviewer (delegators), registry.json | medium |
| `agents/requirements-specialist-subagent.md` + `agents/overlays/requirements-specialist-subagent.opencode.md` | contract doc (1.2) | worktree pipeline Step 7 relay (Mode R), registry.json | medium |
| `installer/init.mjs` (overlay-concat hook) | overlay convention (1.2, 2.x exemplars) | CLI entry (`package.json` bin), `tests/` bats suite, uninstall/update hash tracking (manifest #379) | high |

## Implementation Phases

### Phase 1: Documentation foundation
- [ ] **1.1** Write `docs/harness-landscape-2026-09.md`: per-harness breakdown (OpenCode, Claude Code, Codex, Copilot, ZCode, Kilo, pi, M365 Copilot) covering primary/subagent/skill/plugin/MCP concepts, the four-standard interoperability layer, the three-strategy tradeoff analysis (duplicate installs vs shared folders vs LCD+composition), and this repo's chosen strategy
    — **Why:** The contract doc (1.2) cites its conclusions; writing the landscape first keeps the pilot's format decisions grounded in reviewed research rather than session memory
    — **Done when:** File exists in `docs/` with a section per harness, the standards layer, the strategy comparison, and zero dangling cross-references to files that don't exist
    — **Consumers affected:** `docs/subagent-portability-contract.md` (step 1.2)
- [ ] **1.2** Write `docs/subagent-portability-contract.md`: LCD body rules (harness-neutral phrasing, universal return contract, runtime fallback one-liners), overlay naming `agents/overlays/<stem>.<target>.md`, composition pipeline order (frontmatter transform → body concat → config emit), per-target binding matrix (opencode/claude/kilo/kimi/zcode/copilot), and the lossy-translation registry (nested-subagent ban on ZCode, model-pin policy, question/memory fallbacks, skill-permission frontmatter)
    — **Why:** It is the authoring standard the pilot retrofits follow; retrofitting first would encode an unreviewed format into 3 agents
    — **Done when:** File exists and documents the overlay convention exactly as steps 2.x and 3.1 implement it
    — **Consumers affected:** steps 2.1–2.3, 3.1; all future `agents/` authoring

### Phase 2: Pilot retrofit (3 agents)
- [ ] **2.1** Retrofit `agents/code-review-subagent.md`: move OpenCode-specific prose (Task-tool delegation syntax with `subagent_type`, `explore`/`general`/`language-reviewer-subagent` invocation wording, question-tool/headless phrasing, LEARNINGS memory-tool recall) into `agents/overlays/code-review-subagent.opencode.md`; LCD core keeps the review workflow, severity rubric, universal return contract, and runtime fallbacks ("if no delegation tool: do the secondary review inline")
    — **Why:** Validates the contract on a delegating reviewer with the richest subagent-permission frontmatter — the hardest translation case among the three
    — **Done when:** Core body contains no OpenCode-only tool names; overlay carries them verbatim in meaning; frontmatter (permissions/mode/steps/description) unchanged
    — **Consumers affected:** `registry.json` (build-registry re-extraction in 4.1), primary sessions delegating code review
- [ ] **2.2** Retrofit `agents/image-analyzer-subagent.md`: deploy-specific model pin ("You run on zai-coding-plan/glm-5.3-flash") and provider-auth prose move to the opencode overlay; LCD core keeps native-perception claim conditioned ("when your runtime provides image input"), the Z.AI HTTP fallback recipe (runtime fallback — stays in core), and the delegation/result contract
    — **Why:** It is the only pilot case where the core/overlay split must preserve a runtime fallback (HTTP recipe) while demoting a deploy-time model pin — exercises the layer-3 rule
    — **Done when:** Core works for a non-ZAI deploy (claims conditioned on actual capability, fallback recipe intact); opencode overlay restores the exact pin and auth prose
    — **Consumers affected:** responsive-audit, pptx-specialist, uiux-reviewer (delegators); vision fallback path
- [ ] **2.3** Retrofit `agents/requirements-specialist-subagent.md`: generalize the headless clause (from "`question` tool is deny'd" to capability phrasing "no interactive clarification channel exists in a subagent session"), keep Mode R grilling workflow in core, move OpenCode-specific invocation wording to the opencode overlay
    — **Why:** Third structural variant (headless specialist, no delegation, no vision) — completes coverage of the coupling taxonomy found in the recon
    — **Done when:** Headless clause is harness-neutral and semantics-preserving; overlay carries opencode wording; frontmatter unchanged
    — **Consumers affected:** worktree pipeline Step 7 Requirements-Gaps relay; discovery flows
- [ ] **2.4** Behavior-equivalence check for all three: compose core+opencode-overlay per agent and diff against the pre-retrofit body; confirm every original instruction is present in meaning (reorganization allowed, loss not)
    — **Why:** AC requires zero behavior change on the primary target; this is the check that proves it
    — **Done when:** Equivalence verdict recorded per agent (in the phase commit message); any lost instruction restored before proceeding
    — **Consumers affected:** all three agents; ticket AC #3

### Phase 3: Installer composition hook
- [ ] **3.1** Add overlay-append to the per-target agent write path in `installer/init.mjs`: after frontmatter transform, if `agents/overlays/<stem>.<target>.md` exists in the source tree, append its content (separated by a blank line) to the body before writing; targets without an overlay file get unchanged bytes
    — **Why:** Makes composition real for every target rather than pilot-only manual state; slots into the existing `TARGETS` transform site (single site for write resolution, #453)
    — **Done when:** `--target opencode` install of code-review-subagent writes core+overlay content; `--target claude` writes core+claude-overlay if present else core; existing `claude-translate`/`kilo-translate`/`model-injected` modes still apply
    — **Consumers affected:** CLI users; manifest hash tracking (already hashes written bytes — no change needed); uninstall/update
- [ ] **3.2** Add a bats test for overlay composition: overlay present → appended; overlay absent → byte-identical to pre-hook output; composition composes with `claude-translate` (transform then append)
    — **Why:** The write path is the installer's highest-risk node (Consumer Map); a regression here corrupts every target silently
    — **Done when:** New test(s) pass in the full bats run (4.2)
    — **Consumers affected:** CI; tests/

### Phase 4: Registry sync + verification gate
- [ ] **4.1** Run `node installer/build-registry.mjs` and commit the regenerated `registry.json`
    — **Why:** Repo rule — any `agents/` frontmatter or file-set change requires registry rebuild; descriptions/frontmatter are unchanged in meaning but the build must be proven clean
    — **Done when:** `git status` shows only an intentional `registry.json` diff (or none) after the build; build exits 0
    — **Consumers affected:** installer registry consumers (init.mjs picker, site build)
- [ ] **4.2** Run the full bats suite (`tests/`); fix any failure caused by this PLAN's changes (pre-existing breakage reported explicitly, not silently fixed)
    — **Why:** Ticket exit gate — the full-tier verification for this change set
    — **Done when:** bats suite green, or failures triaged as pre-existing with evidence
    — **Consumers affected:** CI; ticket AC #5
- [ ] **4.3** Documentation consistency sweep: confirm `README.md`/`AGENTS.md` counts need no change (no new skills/agents — overlays are body fragments), and every cross-reference added in Phase 1 docs resolves to a real path
    — **Why:** AC cross-references must resolve; count tables drift is the repo's most common doc rot
    — **Done when:** grep of new docs' referenced paths all exist; no count-table edits required (or made if they are)
    — **Consumers affected:** docs readers; documentation-consistency checks

## Technical Notes
- Overlay convention for this ticket is agents-only (`agents/overlays/`); the skills-side equivalent (`skills/<name>/overlays/`) is future work and MUST NOT be started here (skill isolation contract #437 scope).
- `agents/overlays/` is not `_`-prefixed and lives outside `skills/`, so `tests/test_skill_isolation.bats` bans should not trigger — verify during 4.2, do not weaken the guard.
- Composition order is fixed: frontmatter transform first, body append second, config emit last (matches existing `claude-translate` then write flow).
- Behavior-equivalence (2.4) compares meaning, not bytes: the opencode composed artifact reorganizes prose into core+overlay; instruction parity is the bar.
- The `agents` (verbatim) install target receives the LCD core only — by design (it is the neutral interchange copy); document this consequence in the contract doc.

## Dependencies
- None external; single ticket, no `blocked-by:` refs.

## Risks & Mitigation
- **Registry drift**: build-registry extracts frontmatter only — frontmatter is unchanged, so drift risk is nil; 4.1 proves it.
- **Overlay/env coupling in tests**: bats tests run in CI without ripgrep — any new test uses `grep` (repo learning: CI runners lack ripgrep).
- **Silent guard weakening**: if the isolation guard or another bats test trips on `agents/overlays/`, fix the test's scope deliberately with justification in the commit — never delete an assertion to go green.
- **Vision fallback regression**: the Z.AI HTTP recipe is load-bearing for non-multimodal deploys — 2.2's done-when explicitly requires it stays intact in core.
