# PLAN: Standardize subagents across harnesses: docs + pilot

**Branch**: feat/576
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/576
**Base**: main
**Rev**: 3 — re-review gate fixes applied (New-1/2/3)

## Gate trace

GATE 0ee91e2 tier=light lint=n.a. typecheck=n.a. build=- unit=n.a. e2e=n.a. — Phase 1 docs-only; done-when checks ran (paths on disk, sections present, pi source pinned)
GATE a10a5c1 tier=light lint=n.a. typecheck=n.a. build=t unit=n.a. e2e=n.a. — Phase 2: token-manifest greps green (7 banned=0, 9 required≥1), registry extraction build OK (restored; 4.1 owns diff)

## Acceptance Criteria
- [ ] `docs/harness-landscape-2026-09.md` covers the harness comparison (OpenCode, Claude Code, Codex, Copilot, ZCode, Kilo, pi, M365 Copilot), the standards layer (Agent Skills / AGENTS.md / MCP / ACP), the standardization strategy, a pi section grounded in https://pi.dev/docs/latest, and a "Planned targets — not composable" note for zcode/copilot
- [ ] `docs/subagent-portability-contract.md` specifies LCD rules, the two-tier binding matrix (composable: opencode/claude/agents/kimi/kilo vs documented-only: zcode/copilot/codex/pi/M365), overlay convention, composition pipeline, the moved-token manifest requirement, the lossy-translation registry, and a parity-verdict appendix
- [ ] 3 pilot agents retrofitted, each as LCD core + `.opencode.md` overlay + minimal `.claude.md` overlay, with behavior-equivalent OpenCode output proven mechanically
- [ ] Both agent write paths (npx `installer/init.mjs` AND `deploy/setup.sh` → `installer/resolve-models.mjs`) compose overlays through one shared helper; composed-body bytes byte-identical across paths for the opencode target, CI-asserted in `tests/agent_lcd_pilot.bats`; manifest hash tracking unchanged
- [ ] Mechanical parity gate green: per-agent moved tokens absent from core and present in composed output; `Other/none:` fallback row present in every core; meaning-parity signoff recorded in the contract appendix
- [ ] Guard tests green: orphan-overlay guard (no overlay for a target without a TARGETS row), no `.agents.md` overlays (verbatim target never composes), `tests/init.bats` enumeration aligned with registry semantics
- [ ] `node installer/build-registry.mjs` diff matches exactly the expected scope (one description change — image-analyzer, 2.2 — plus generatedAt; 2.1/2.3 entries byte-identical) and is committed; full bats suite passes

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `docs/harness-landscape-2026-09.md` (new) | — | contract doc (1.2) | low |
| `docs/subagent-portability-contract.md` (new) | landscape doc (1.1) | pilot retrofits (2.x), helper (3.1), guards (3.3), future agent authoring | low |
| `installer/overlay.mjs` (new, shared compose helper) | contract doc (1.2) | `installer/init.mjs` agent loop, `installer/resolve-models.mjs` `renderAgent`, bats 3.3/3.4 | high |
| `installer/init.mjs` (helper wiring) | `installer/overlay.mjs` (3.1) | CLI bin (`package.json`), `tests/init.bats`, manifest hash tracking | high |
| `installer/resolve-models.mjs` + `deploy/setup.sh` (renderAgent seam: compose before injectModel) | `installer/overlay.mjs` (3.1) | full-deploy users (`./deploy/setup.sh` — primary distribution mode) | high |
| `agents/{code-review,image-analyzer,requirements-specialist}-subagent.md` + 2 overlays each | contract doc (1.2) | `registry.json` (4.1 — description diffs), delegating agents, both write paths | medium |
| `tests/init.bats` (enumeration alignment) | overlays existing (2.x) | CI | low |
| `tests/agent_lcd_pilot.bats` (new) | helper (3.1), pilots (2.x) | CI, future retrofit audits | low |

## Implementation Phases

### Phase 1: Documentation foundation
- [x] **1.1** Write `docs/harness-landscape-2026-09.md`: per-harness breakdown (OpenCode, Claude Code, Codex, Copilot, ZCode, Kilo, pi, M365 Copilot) across primary/subagent/skill/plugin/MCP concepts, the four-standard interoperability layer, the three-strategy tradeoff (duplicate installs vs shared folders vs LCD+composition), the chosen strategy, a pi section grounded in https://pi.dev/docs/latest (no native subagents; delegation via extensions/tmux/RPC/SDK embedding; Agent Skills dirs; project-trust security model), and a "Planned targets — not composable" note for zcode/copilot (follow-up ticket)
    — **Why:** The contract doc (1.2) cites its conclusions; the zcode/copilot note captures user intent without implying support, per REQ-BIND
    — **Done when:** File exists with a section per harness, the standards layer, the strategy comparison, the pi section sourced from docs/latest, the planned-targets note, and zero dangling cross-references
    — **Consumers affected:** `docs/subagent-portability-contract.md` (step 1.2)
    — **Done:** 8 per-harness sections + standards layer + strategy table + pi section (docs/latest-sourced) + planned-targets note; all present-tense path refs verified on disk; files: docs/harness-landscape-2026-09.md; fixes: none
- [x] **1.2** Write `docs/subagent-portability-contract.md`: LCD body rules (harness-neutral phrasing, universal return contract, `Other/none:` runtime-fallback rows), the two-tier binding matrix per REQ-BIND (overlay suffixes valid only for composable targets), overlay naming `agents/overlays/<stem>.<target>.md` with `.agents.md` declared invalid (verbatim target never composes), composition pipeline order (frontmatter transform → body concat → config emit; renderAgent composes before injectModel), the moved-token manifest requirement per REQ-PARITY, pilot per-target coverage statement per REQ-PILOT (kimi/kilo LCD-only as documented improvement; claude minimal overlay), the lossy-translation registry, and an empty parity-verdict appendix
    — **Why:** It is the authoring standard the pilot retrofits and the shared helper both implement; an undocumented convention cannot be reviewed or audited
    — **Done when:** File exists and every mechanism named here matches what steps 2.x/3.x build, including the appendix section existing (empty)
    — **Consumers affected:** steps 2.1–2.4, 3.1, 3.3, 3.4; all future `agents/` authoring
    — **Done:** 9 sections incl. two-tier matrix, overlay convention, pipeline order, initial token manifests, pilot coverage table, lossy registry, appendix skeleton with 3 preliminary placeholders; files: docs/subagent-portability-contract.md; fixes: none

### Phase 2: Pilot retrofit (core + opencode overlay + minimal claude overlay each)
- [x] **2.1** Retrofit `agents/code-review-subagent.md` into LCD core + `agents/overlays/code-review-subagent.opencode.md` + `agents/overlays/code-review-subagent.claude.md`: OpenCode-specific invocation prose (Task-tool `subagent_type` syntax, explore/general/language-reviewer delegation, memory-tool LEARNINGS recall, question-tool/headless phrasing) moves to the opencode overlay; the claude overlay carries the Claude Task-tool binding (~5–15 lines); LCD core keeps the review workflow, severity rubric, `Patterns applied/violated` contract, and `Other/none:` inline-fallback row
    — **Why:** Validates the contract on a delegating reviewer with the richest subagent-permission frontmatter — the hardest translation case of the three
    — **Done when:** Core contains no OpenCode-only invocation snippets (token list per contract manifest); both overlays exist; frontmatter untouched
    — **Consumers affected:** `registry.json` (4.1), primary sessions delegating code review, claude-target users
    — **Done:** LCD core + opencode + claude overlays extracted; 3 OpenCode-coupled spots rewritten (memory recall, language-reviewer delegation, explore/general syntax); frontmatter untouched; files: agents/code-review-subagent.md, agents/overlays/code-review-subagent.{opencode,claude}.md; fixes: none
- [x] **2.2** Retrofit `agents/image-analyzer-subagent.md` into core + two overlays, including review Minors: the deploy model pin ("zai-coding-plan/glm-5.3-flash", prose AND the frontmatter description at :3) is replaced — core conditions native perception on actual runtime capability ("when your runtime provides image input"), the Z.AI HTTP fallback recipe stays in core as a runtime fallback, the opencode overlay restores the exact pin + provider-auth prose, and the stale `permission.task` v1 syntax (:196-197) is rewritten to capability phrasing; the description becomes capability-neutral
    — **Why:** Only pilot case exercising the layer-3 rule (runtime fallback stays core, deploy pin moves to overlay) — and the description de-pin is what makes the 4.1 registry diff intentional rather than churn
    — **Done when:** Core works for a non-ZAI deploy (conditioned claim, fallback recipe intact, no provider pin anywhere in core incl. description); opencode overlay restores pin/auth prose; both overlays exist
    — **Consumers affected:** `registry.json` (4.1 — the single expected description diff), responsive-audit/pptx-specialist/uiux-reviewer delegators, vision fallback path
    — **Done:** description de-pinned, perception capability-conditioned, recipe prose generalized, permission.task v1 syntax replaced; overlays restore pin/auth/delegability; frontmatter otherwise untouched; files: agents/image-analyzer-subagent.md, agents/overlays/image-analyzer-subagent.{opencode,claude}.md; fixes: none
- [x] **2.3** Retrofit `agents/requirements-specialist-subagent.md` into core + two overlays: generalize the headless clause from "`question` tool is deny'd" to capability phrasing ("no interactive clarification channel exists in a subagent session — proceed on stated assumptions"), Mode R workflow stays in core, OpenCode invocation wording moves to the opencode overlay, claude overlay carries the Task binding
    — **Why:** Third structural variant (headless specialist, no delegation, no vision) completes the coupling taxonomy from the recon
    — **Done when:** Headless clause is harness-neutral and semantics-preserving; core free of OpenCode-only invocation snippets; both overlays exist; frontmatter untouched
    — **Consumers affected:** worktree pipeline Step 7 Requirements-Gaps relay; discovery flows
    — **Done:** headless clause generalized to capability phrasing, Mode A mechanism wording generalized; overlays carry question-deny explanation + Task syntax; files: agents/requirements-specialist-subagent.md, agents/overlays/requirements-specialist-subagent.{opencode,claude}.md; fixes: none
- [x] **2.4** Advisory pre-composition: hand-compose core+opencode-overlay per pilot per the contract's pipeline prose, record a preliminary meaning-parity verdict per agent in the contract appendix, explicitly marked non-authoritative
    — **Why:** Early signal catches gross retrofit errors before installer work, without the phase-escape anti-pattern — the authoritative gate deliberately lives in 3.4 where the real composer exists (learning: done-when-gate-escapes-its-phase)
    — **Done when:** Appendix holds three preliminary verdicts, each marked "preliminary — superseded by 3.4"
    — **Consumers affected:** step 3.4 (final verdicts supersede these)
    — **Done:** preliminary verdicts recorded in contract appendix (PASS x3, marked superseded-by-3.4); uniform Other/none bindings section added to all 3 cores; files: docs/subagent-portability-contract.md, 3 agent cores; fixes: none

### Phase 3: Shared composition + mechanical guards
- [ ] **3.1** Create `installer/overlay.mjs` exporting a shared compose helper (read `agents/overlays/<stem>.<target>.md` when it exists, append blank-line-separated to the body; never compose for `agentMode: "verbatim"` or targets without a TARGETS row) and wire BOTH write paths: the `installer/init.mjs` agent write loop (after per-target frontmatter transform) and `resolve-models.mjs` `renderAgent` (compose before `injectModel`)
    — **Why:** BLOCK-1 — two independent writers of deployed agent bytes exist; a hook in only one silently regresses the flagship `./deploy/setup.sh` path (learning: parallel-write-path-bypasses-composition-hook); one helper prevents implementation drift (REQ-COMPOSE)
    — **Done when:** Composing code exists exactly once; both paths call it; a manual spot check shows identical composed bodies from both seams for one pilot
    — **Consumers affected:** every install path (npx add, setup.sh deploy); steps 3.3/3.4
- [ ] **3.2** Align `tests/init.bats` agent enumeration with registry semantics (`-maxdepth 1` on the disk-side count, matching `build-registry.mjs` non-recursive enumeration), framed as semantics-preserving: overlays are not agents
    — **Why:** Major-3 — the current recursive `find` breaks count parity the moment `agents/overlays/*.md` exists; aligning proactively avoids a discovered-mid-gate guard edit
    — **Done when:** `tests/init.bats` green on the tree with overlays present; the assertion still proves "registry matches disk agents"
    — **Consumers affected:** CI; guard suite integrity
- [ ] **3.3** Add `tests/agent_lcd_pilot.bats`: (a) token-purity gate per REQ-PARITY — for each pilot's moved-token manifest, invoke the shared helper directly and assert banned invocation tokens absent from core (case-insensitive) and present in composed output; (b) `Other/none:` fallback-row presence asserted per core; (c) claude-path output contains the Claude Task binding; (d) kimi/kilo outputs contain the fallback row and no OpenCode-only tokens; (e) model-inject-then-append ordering on the opencode path; (f) orphan-overlay guard — every `agents/overlays/*.<target>.md` suffix ∈ TARGETS rows; (g) no `.agents.md` overlay files exist
    — **Why:** Minor-3 + REQ-BIND/REQ-PARITY — the mechanical floor that makes the remaining 31 retrofits auditable instead of judgment calls, and the guard that kills dead overlay files
    — **Done when:** All assertions green; tokens chosen to ban invocation snippets, not legitimate negative mentions ("NEVER call `question`" stays legal in a core)
    — **Consumers affected:** CI; step 4.2 full suite; future retrofit audits
- [ ] **3.4** Authoritative equivalence gate per REQ-COMPOSE/PARITY: for each pilot on the **opencode target only**, compose through BOTH write-path seams (init.mjs loop and renderAgent — opencode-only by design) and assert byte-identity of composed bodies; claude composed output is validated by content assertions only (3.3c Task binding + token gate — the renderAgent seam has no claude-translate, so cross-seam claude comparison is structurally unsatisfiable); run the 3.3 token gate; add the byte-identity assertions to `tests/agent_lcd_pilot.bats` so the AC-4 guarantee survives the ticket; record final meaning-parity verdicts in the contract appendix (replacing 2.4's preliminary entries)
    — **Why:** AC "behavior-equivalent OpenCode output" must be proven by the real composer across the real write paths — and only where both seams actually produce that target (learning: gate-matrix-must-match-seam-capabilities); Minor-4 — verdicts in a durable artifact, not a commit message
    — **Done when:** Byte-identity assertions pass for all 3 opencode combinations and live in `tests/agent_lcd_pilot.bats`; claude content assertions green; appendix verdicts final and dated
    — **Consumers affected:** ticket ACs 3–5; contract appendix readers; future retrofit audits

### Phase 4: Registry + verification gate
- [ ] **4.1** Run `node installer/build-registry.mjs`; review the diff; expected scope is exactly ONE description change (image-analyzer-subagent, from 2.2) plus `generatedAt` churn — the code-review and requirements-specialist registry entries must be byte-identical (their frontmatter is untouched; any diff there means a frontmatter edit slipped and halts); commit as one atomic registry commit
    — **Why:** Frontmatter deliberately changes in 2.2, so a plain-run diff is intentional this time — the phantom-gate anti-pattern (learning: build-registry-plain-run-churns-generatedat, recurrence #7 avoided) is dodged by enumerating the expected churn instead of demanding an empty diff
    — **Done when:** Diff matches the expected scope exactly (halt and fix if anything else appears); committed
    — **Consumers affected:** installer registry consumers (init.mjs picker, site build)
- [ ] **4.2** Run the full bats suite; fix failures caused by this PLAN's changes; report pre-existing breakage explicitly with evidence
    — **Why:** Ticket exit gate — the full-tier verification for this change set
    — **Done when:** Suite green, or failures triaged as pre-existing with evidence
    — **Consumers affected:** CI; ticket AC 7
- [ ] **4.3** Documentation consistency sweep: confirm `README.md`/`AGENTS.md` counts need no change (overlays are body fragments, not new skills/agents), and every cross-reference in the two new docs resolves to a real path
    — **Why:** AC cross-references must resolve (learning: dangling-cross-reference-in-ac); count-table drift is the repo's most common doc rot
    — **Done when:** All referenced paths exist on disk; no count edits required (or made if they are)
    — **Consumers affected:** docs readers; documentation-consistency checks

## Technical Notes
- Overlay convention this ticket is agents-only; the skills-side equivalent (`skills/<name>/overlays/`) is future work and MUST NOT start here (isolation contract #437 scope).
- `agents/overlays/` is not `_`-prefixed and lives outside `skills/` — the isolation guard does not scope it (verified: tests grep `skills/_common` literally and scope tests 2–4 to `skills/`); do not weaken any guard.
- Composition order fixed: frontmatter transform → body append → model injection (renderAgent seam composes BEFORE `injectModel`) → config emit.
- The `agents` (verbatim) install target receives the LCD core only — enforced, not just documented (3.1 helper rule + 3.3g assertion).
- zcode/copilot TARGETS rows + kimi/kilo overlays → follow-up ticket "Portability phase 2" (REQ-BIND defer); this ticket ships the planned-targets documentation only.
- pi remains documented-only: LCD core + `Other/none:` fallback is its entire contract surface (no composition path, no subagents natively — RPC/SDK embedding is the documented delegation route).

## Dependencies
- None external; single ticket, no `blocked-by:` refs.

## Risks & Mitigation
- **Two-writer regression (BLOCK-1 class)**: mitigated by the single shared helper (3.1) and the byte-identity assertions across both seams (3.4).
- **Registry churn phantom gate**: dodged by enumerating expected churn in 4.1 (description diffs are intentional this round).
- **Token-gate false positives**: tokens ban invocation snippets, not negative mentions; case-insensitive matching per the false-green-grep learning.
- **Guard weakening**: any guard edit is scoped and justified in its commit — never delete assertions to go green.
- **Vision fallback regression**: the Z.AI HTTP recipe is load-bearing for non-multimodal deploys — 2.2's done-when requires it intact in core.
