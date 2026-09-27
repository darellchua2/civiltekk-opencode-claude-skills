# PLAN: Wave 2 — consolidate 22 skills into 6 civiltekk- hosts

**Branch**: feat/604
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/604
**Base**: main — branched at 62daa74 (pre-Wave-1); the 6f hold parks this PLAN until PR #614 (feat/603) merges, then feat/604 rebases onto the post-Wave-1 main (**135 skills, lean 67, civiltekk-* hosts present**). All count arithmetic below assumes the post-rebase world.

## Acceptance Criteria

- [ ] 6 atomic commits `refactor(skills): consolidate X into Y`; counts green per commit
- [ ] impliesMcp edge re-homed in dependency-map.json + pack-frontend mcps (next-devtools value unchanged)
- [ ] All member triggers preserved in host descriptions; skill count = 119 after this wave (135 − 16: 22 members → 6 hosts)
- [ ] Withdrawn families stay unmerged: autoresearch (4), release trio (3)
- [ ] Merge-specific musts: zai endpoint-policy split preserved · opentofu provider-setup trimmed · test-gen ONE Iteration Protocol · reqs host carries old-name aliases · pr step-number pins reworded · pr-workflow-subagent allowlist gains the merged name

## Pattern template (identical to Wave 1 — skills/civiltekk-git-commits-skill is the reference host)

Method-only host ≤140 lines; `Consolidates <members> (#604)` first body line; trigger-union description (≤1024); side-files table; detection explicit>inferred>ask-once; boundaries; harness binding. references/<variant>.md = VALUES. Residue rule (Wave-1 constant + new LEARNINGS pattern): sweep `grep -rP '(?<!civiltekk-)(?<!/)<name>-skill'` AND the suffix-stripped stem; exempt: PLANS/, LEARNINGS/, CHANGELOG.md, docs/, registry.json pre-rebuild, host Consolidates line, README:256 history note. Count sweep per phase: skill_profiles six literals (if lean changes), init.bats agent/preset pins, README count sites + category parentheticals, setup.sh lean comment.

## Dependency & Consumer Map

| Node | Depends on | Consumers | Risk |
|------|-----------|-----------|------|
| 6 new hosts | Wave 1 merged (rebase) | agents, presets, installer, registry | med |
| `installer/dependency-map.json` impliesMcp key (Phase 2) | — | init.mjs, test_requires_skills impliesMcp check, pack-frontend mcps | high |
| `tests/test_skill_isolation.bats` | — (untouched — no handoff edges here) | guard | low |
| `agents/testing-subagent.md` (Phase 6) | — | test-generation routing | med |
| `agents/opentofu-explorer-subagent.md` (Phase 4) | — | 7→1 allowlist | med |
| `agents/pr-workflow-subagent.md` (Phase 5) | — | allowlist GAINS host; step-pin rewords | high |
| `skills/worktree-pipeline-skill/SKILL.md` (Phase 5) | — | cites pr-merge head-class rule | low |
| `agents/requirements-specialist-subagent.md` (Phase 1) | — | 2 allowlists + 4 body routes | med |
| README/setup.sh counts | every phase | docs honesty | low |

## Implementation Phases

### Phase 1: civiltekk-requirements-specs-skill
Absorbs: `brd-creation-skill` + `srs-creation-skill`. references/: `brd.md`, `srs.md`. Routes: brd (BABOK/IIBA sponsor-level why) | srs (IEEE 830 internal what; PRD back-compat triggers preserved verbatim in description).
MUST: host body carries old-name alias line ("formerly brd-creation-skill / srs-creation-skill") — citing skills and drafts reference the old names.
Consumers: agents/requirements-specialist-subagent.md (2 allowlists + 4 body routes), presets pack-docs + pack-business, README (category Framework), citing skills: interactive-document-rendering, technical-design-creation, vision-creation, worktree-pipeline §6b (draft-detection conventions — grep stems `brd-creation` / `srs-creation` and repoint live hits).
- [ ] **1.1** Author host + references per template (alias line included)
    — **Why:** same interview/render/linkage pipeline, two template variants — the cleanest Wave-2 merge warms up the run
    — **Done when:** host ≤140 lines; both trigger sets + PRD back-compat preserved; isolation bats green
    — **Consumers affected:** requirements-specialist, 4 citing skills
- [ ] **1.2** Delete + repoint (specialist agent, presets, README, citing skills)
    — **Why:** stale names break the doc-ladder routing (vision → brd → srs → plan)
    — **Done when:** lookbehind residue sweep clean
    — **Consumers affected:** doc-ladder chain
- [ ] **1.3** Registry rebuild + scoped gate + count (134)
    — **Why:** per-commit green
    — **Done when:** registry skills=134; affected bats green; sweep clean
    — **Consumers affected:** installer
- [ ] **1.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed single commit with PLAN ticks
    — **Consumers affected:** none beyond phase

### Phase 2: civiltekk-nextjs-skill
Absorbs: `nextjs-standard-setup-skill` + `nextjs-devtools-mcp-skill` + `nextjs-image-usage-skill` + `threejs-nextjs-skill` (amplify stays standalone; unit-test-creator belongs to Phase 6). references/: `setup.md`, `devtools-mcp.md`, `image.md`, `threejs.md`. Routes: scaffold | runtime-diagnosis | image-usage | threejs-integration.
MUSTS: (a) re-home `impliesMcp`: dependency-map key `nextjs-devtools-mcp-skill` → `civiltekk-nextjs-skill` (value `["next-devtools"]` unchanged) + pack-frontend `mcps` entry key; (b) devtools' file-based availability fallback stays in host boundaries (reachable without loading the reference); (c) add missing `metadata:` blocks (portability); (d) threejs dated version matrix lives in the reference (route-gated).
Consumers: agents/nextjs-specialist-subagent.md (4 allowlists + body), presets pack-frontend (4 skills + mcps), deploy/opencode.json (4 rules → 1), README (Framework-Specific category), tests (none pin these names — verified in review).
- [ ] **2.1** Author host + references + metadata blocks per template
    — **Why:** four reference cards share one routing method (the specialist's task-type matrix)
    — **Done when:** host ≤140; four trigger sets preserved; isolation green
    — **Consumers affected:** nextjs-specialist
- [ ] **2.2** Delete + repoint + impliesMcp re-home (agent, preset + mcps, opencode.json, README)
    — **Why:** a stale impliesMcp key silently breaks MCP opt-in for the whole family
    — **Done when:** `bats tests/test_requires_skills.bats` green (impliesMcp ⊆ deploy/opencode.json servers); residue clean
    — **Consumers affected:** installer MCP wiring, pack-frontend
- [ ] **2.3** Registry rebuild + scoped gate + count (131)
    — **Why:** per-commit green
    — **Done when:** registry skills=131; requires_skills + skill_profiles green
    — **Consumers affected:** installer
- [ ] **2.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 3: civiltekk-zai-media-skill
Absorbs: `zai-image-generation-skill` + `zai-video-skill` + `zai-asr-skill` + `zai-ocr-skill`. references/: `image.md`, `video.md`, `asr.md`, `ocr.md`. Routes: image | video | audio-transcribe | ocr.
MUSTS: (a) preserve the endpoint-policy split as per-variant values — image → coding-plan endpoint + `ZAI_IMAGE_ENDPOINT` + its compliance warning; video/asr/ocr → PAYG + `ZAI_MEDIA_ENDPOINT` — do NOT unify; (b) key-resolution block moves to host once (jq key-order drift noted in review — keep per-variant copies verbatim instead of merging if orders differ); (c) sync-vs-async discriminator in the route table (video polls — background-shell harness binding in host method); (d) OCR's `ponytail:` debt marker survives.
Consumers: agents/zai-media-subagent.md (4 allowlists → 1 + body), deploy/skill-profiles.json (zai-image-generation lean → host; lean 67→66 + six bats literals), deploy/opencode.json + README lean literal (217), README category (AI/Media or similar — verify), pack presets if any (grep), fellow skills (grep stems `zai-image` / `zai-video` / `zai-asr` / `zai-ocr`).
- [ ] **3.1** Author host + references per template (policy split preserved)
    — **Why:** one API family, four media variants; the split IS the compliance surface
    — **Done when:** host ≤140; four trigger sets preserved; per-variant env/endpoint values verbatim; isolation green
    — **Consumers affected:** zai-media-subagent
- [ ] **3.2** Delete + repoint (agent, skill-profiles lean 67→66 + literals, opencode.json, README counts + lean site)
    — **Why:** zai-image-generation is primary-visible — the rename must carry the lean entry or the skill vanishes from primaries
    — **Done when:** skill_profiles green; residue clean
    — **Consumers affected:** primary sessions, zai-media-subagent
- [ ] **3.3** Registry rebuild + scoped gate + count (128)
    — **Why:** per-commit green
    — **Done when:** registry skills=128; skill_profiles + isolation green
    — **Consumers affected:** installer
- [ ] **3.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 4: civiltekk-opentofu-skill
Absorbs: 7 dirs — `opentofu-provider-setup-skill`, `opentofu-provisioning-workflow-skill`, `opentofu-aws-explorer-skill`, `opentofu-kubernetes-explorer-skill`, `opentofu-neon-explorer-skill`, `opentofu-keycloak-explorer-skill`, `opentofu-ecr-provision-skill`. references/: `provider-setup.md` (TRIM the 402-line tutorial while moving — keep chain-root + per-provider essentials), `workflow.md`, `explorers.md` (aws + neon + keycloak + kubernetes as four sections; kubernetes' HCL blocks may stay inline), `ecr.md` (external repo pin `ecr/betekk_probe_engine_main/` survives verbatim). Routes: first-time-setup | plan-apply workflow | explore <target> | ecr-provision.
Consumers: agents/opentofu-explorer-subagent.md (7 allowlists → 1 + body chain-root references), presets pack-devops (7 → 1), deploy/opencode.json (7 → 1), README (category DevOps/Infrastructure — verify; count 128→122), fellow skills (amplify cites opentofu skills per review — grep stems).
- [ ] **4.1** Author host + references (provider-setup trimmed; explorers collapsed) per template
    — **Why:** biggest dir win of the program; the 4 explorers are one method modulo vocabulary
    — **Done when:** host ≤140; 7 trigger sets preserved; ecr pin intact; isolation green
    — **Consumers affected:** opentofu-explorer-subagent
- [ ] **4.2** Delete + repoint (agent 7→1, preset, opencode.json, README, fellow skills incl. amplify)
    — **Why:** the family's only consumer is one subagent — clean collapse
    — **Done when:** residue clean
    — **Consumers affected:** opentofu-explorer-subagent
- [ ] **4.3** Registry rebuild + scoped gate + count (122)
    — **Why:** per-commit green
    — **Done when:** registry skills=122; affected bats green
    — **Consumers affected:** installer
- [ ] **4.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 5: civiltekk-pr-workflow-skill
Absorbs: `pr-creation-workflow-skill` + `pr-merge-workflow-skill`. references/: `create.md` (8-step pre-merge pipeline), `merge.md` (5-phase post-merge: divergence pre-flight, head-class classifier, CI monitor, auto-heal, cleanup/tracker). Routes: create | merge/post-merge.
MUSTS (all step-pin rewords in the same phase): (a) `agents/pr-workflow-subagent.md` L119/147 cite "pr-creation-workflow-skill steps 2-3" → reword to reference anchors (`references/create.md` §steps); (b) `skills/gh-cli-setup-skill/SKILL.md:19` "(step 6)" anchor reword; (c) `skills/verification-loop-skill/SKILL.md` L65 table row repoint; (d) `skills/worktree-pipeline-skill/SKILL.md` cites "pr-merge-workflow-skill Phase 1 head-class rule" → host/merge route; (e) pr-workflow-subagent's allowlist GAINS civiltekk-pr-workflow-skill (it only allowlisted pr-creation — merge routing would break otherwise); (f) 3 bats files' pinned paths: test_default_behavior.bats, test_autoresearch_protocol.bats, test_tiered_gating.bats L173-177 (asserts `GATE <sha> tier=full` + `never satisfies this check` INSIDE pr-creation's SKILL.md — the literals must live in the host or references/create.md and the test path repointed).
Consumers: agents/pr-workflow-subagent.md + agents/repo-ops-specialist-subagent.md (2 allowlists → 1 each), presets pack-devops, deploy/opencode.json, README (Git/Workflow), the 4 skill-body citers above.
- [ ] **5.1** Author host + references per template (pinned literals carried — gating preamble, Iteration Protocol if pinned)
    — **Why:** two halves of one PR lifecycle; the create→merge boundary becomes a route
    — **Done when:** host ≤140; both trigger sets preserved; tiered_gating's asserted strings present once
    — **Consumers affected:** pr-workflow-subagent, repo-ops-specialist
- [ ] **5.2** Delete + repoint + ALL step-pin rewords (a–f) + allowlist gain
    — **Why:** step-number pins are prose contracts with subagents; stale pins misroute real PR flows
    — **Done when:** all six surfaces green in their tests; residue clean
    — **Consumers affected:** pipeline consumers, 4 citing skills
- [ ] **5.3** Registry rebuild + scoped gate + count (121)
    — **Why:** per-commit green
    — **Done when:** registry skills=121; tiered_gating + default_behavior + autoresearch_protocol green
    — **Consumers affected:** installer
- [ ] **5.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 6: civiltekk-test-generation-skill (fixes the isolation gap)
Absorbs: `test-generator-framework-skill` (the values host) + `python-pytest-creator-skill` + `nextjs-unit-test-creator-skill`. references/: `framework.md` (language/framework matrix + MagicMock pitfall — deduped here ONCE), `python.md` (pytest scenario taxonomies + template), `nextjs.md` (Next-16 render/action/route patterns). Routes: framework-matrix | python | nextjs.
MUSTS: (a) exactly ONE Iteration Protocol section (bats pin `appears_exactly_once`); (b) MagicMock-headers pitfall exists once (framework reference), cited by both stack references; (c) the creators' undeclared-prereq gap is ELIMINATED by the merge (dirs gone; no requiresSkills entry needed — note in commit body); (d) 6 pinned bats blocks repointed: test_default_behavior.bats (L366-377, 690-707, 718-736) + test_autoresearch_protocol.bats (L237-247, 437-448, 452-485) — pinned paths/preambles move to the host, host carries each pinned literal exactly once.
Consumers: agents/testing-subagent.md (3 allowlists → 1 + body), agents/tdd-subagent.md (grep — cites framework), presets pack-frontend (unit-test-creator), deploy/opencode.json (3 → 1), README (category Testing/Framework), fellow skills (grep stems `test-generator-framework` / `python-pytest-creator` / `nextjs-unit-test-creator`).
- [ ] **6.1** Author host + references per template (ONE Iteration Protocol; pitfall deduped)
    — **Why:** the framework was always the method host; the creators were stack values — the merge completes the shape and kills the latent isolation gap
    — **Done when:** host ≤140; three trigger sets preserved; `grep -c '## Iteration Protocol (opt-in)'` in host = 1; isolation green
    — **Consumers affected:** testing-subagent, tdd-subagent
- [ ] **6.2** Delete + repoint (testing-subagent, tdd-subagent if citing, preset, opencode.json, README, 6 bats blocks, fellow skills)
    — **Why:** every pinned block must find its literal in the host or CI lies
    — **Done when:** default_behavior + autoresearch_protocol green; residue clean
    — **Consumers affected:** CI, testing lattice
- [ ] **6.3** Registry rebuild + scoped gate + count (119)
    — **Why:** per-commit green; final ladder step hits the amended AC
    — **Done when:** registry skills=119; scoped bats green; count verified
    — **Consumers affected:** installer
- [ ] **6.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase

### Phase 7: Exit — full suite, final counts, sweep
- [ ] **7.1** Full gate: `bats tests/` exit=0 zero failures; LEARNINGS count sweep (lookbehind residue for all 22 members); registry committed clean
    — **Why:** ticket exit gate is tier=full unconditionally
    — **Done when:** suite green; sweep clean; `GATE <sha> tier=full` memo appended
    — **Consumers affected:** PR citation, reviewer
- [ ] **7.2** Verify ticket ACs end-to-end (6 commits, impliesMcp re-homed, triggers preserved, count 119, withdrawn families untouched); tick
    — **Why:** AC reconciliation before review
    — **Done when:** every AC tickable with evidence
    — **Consumers affected:** reviewer, PR
- [ ] **7.3** Commit PLAN ticks + memo; push
    — **Why:** traceability; final SHA carries tier=full memo
    — **Done when:** pushed; zero unchecked; `[goal:evidence]` emitted
    — **Consumers affected:** pipeline Step 9/10

## Technical Notes

- Count ladder (post-rebase base 135): 134 · 131 · 128 · 122 · 121 · 119. Lean: 67 → 66 (zai, Phase 3 only) → six bats literals that phase only.
- Rebase precondition: PR #614 must merge first — Phase 2's impliesMcp edit and Phase 6's bats blocks touch files #614 also touched (dependency-map context, README counts, test_default_behavior); union-resolution on conflict per #602/#603 precedent.
- The lookbehind residue grep `(?<!civiltekk-)(?<!/)name` is mandatory (Wave-1 LEARNINGS: rename-residue-sweeps-need-lookbehind-anchor).
- Concurrency: main churn observed 3× today (#606/#609/#612-adjacent releases) — rebase at boundaries, never mid-phase.
- Delegation model unchanged: N.1–N.2 to general-subagents (phase block + template + residue constant), N.3–N.4 (gate+commit) to orchestrator.

## Dependencies

Held at 6f vs PR #614 (open, feat/603): overlap on dependency-map.json, README counts, test_default_behavior.bats, skill-profiles shape. Auto-resume on #614 merge notification: rebase feat/604 onto updated main (union conflicts expected in the four files above), continue at Step 7.

## Risks & Mitigation

- **Phase 5 step-pin rewords are prose contracts** — each citing surface verified by its own test or explicit grep in the same commit.
- **Phase 6 pinned-literal migration** — six bats blocks; any literal landing twice/zero times trips `appears_exactly_once` or a failed grep; per-block verification in 6.2.
- **impliesMcp key rename** — test_requires_skills asserts values ⊆ deploy/opencode.json servers; value unchanged, key renamed — green by construction, verified in 2.3.
- **Count arithmetic** — 22−6=−16 → 119; re-derive from disk at 7.2, never from this note.
