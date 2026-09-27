# PLAN: Wave 2 — consolidate 22 skills into 6 civiltekk- hosts

**Branch**: feat/604
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/604
**Base**: main @ 7a725c5 (post-Wave-1: 135 skills, lean 67, 11 civiltekk-* hosts present). All count arithmetic assumes this base.

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
Consumers: agents/requirements-specialist-subagent.md (2 allowlists + 4 body routes), presets pack-docs + pack-business, deploy/opencode.json (srs-creation :145 + brd-creation :150 allow rules → one host rule), README (category Framework), citing skills: interactive-document-rendering, technical-design-creation, vision-creation (grep stems `brd-creation` / `srs-creation` and repoint live hits; worktree-pipeline §6b cites concepts only — no stem hits, verify by grep).
- [x] **1.1** Author host + references per template (alias line included)
    — **Why:** same interview/render/linkage pipeline, two template variants — the cleanest Wave-2 merge warms up the run
    — **Done when:** host ≤140 lines; both trigger sets + PRD back-compat preserved; isolation bats green
    — **Consumers affected:** requirements-specialist, 4 citing skills
    — **Done:** method host + brd|srs routes, alias line, 447-char union description incl. all PRD back-compat triggers; files: skills/civiltekk-requirements-specs-skill/{SKILL.md,references/brd.md,references/srs.md}; fixes: none
- [x] **1.2** Delete + repoint (specialist agent, presets, README, citing skills)
    — **Why:** stale names break the doc-ladder routing (vision → brd → srs → plan)
    — **Done when:** lookbehind residue sweep clean
    — **Consumers affected:** doc-ladder chain
    — **Done:** 2 dirs git-rm; repointed: specialist agent (2 allows + 4 body routes), 2 presets, opencode.json 2->1, README 135->134 + Framework 18->17 + history note, 3 citing skills; lean untouched (neither member lean - verified); residue sanctioned-only; fixes: none
- [x] **1.3** Registry rebuild + scoped gate + count (134)
    — **Why:** per-commit green
    — **Done when:** registry skills=134; affected bats green; sweep clean
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=134); scoped gate green (103 incl. requires_skills pin); count 134; fixes: none
- [x] **1.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed single commit with PLAN ticks
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a.

### Phase 2: civiltekk-nextjs-skill
Absorbs: `nextjs-standard-setup-skill` + `nextjs-devtools-mcp-skill` + `nextjs-image-usage-skill` + `threejs-nextjs-skill` (amplify stays standalone; unit-test-creator belongs to Phase 6). references/: `setup.md`, `devtools-mcp.md`, `image.md`, `threejs.md`. Routes: scaffold | runtime-diagnosis | image-usage | threejs-integration.
MUSTS: (a) re-home `impliesMcp`: dependency-map key `nextjs-devtools-mcp-skill` → `civiltekk-nextjs-skill` (value `["next-devtools"]` unchanged) + pack-frontend `mcps` entry key; (b) devtools' file-based availability fallback stays in host boundaries (reachable without loading the reference); (c) add missing `metadata:` blocks (portability); (d) threejs dated version matrix lives in the reference (route-gated).
Consumers: agents/nextjs-specialist-subagent.md (4 allowlists + body), presets pack-frontend (skills list only — its `mcps` is a bare server-name array, nothing skill-keyed to re-home), deploy/opencode.json (2 rules → 1: nextjs-devtools-mcp :310 + threejs :400; standard-setup and image-usage are not primary-visible), README (Framework-Specific category), fellow skills (grep stems — 9 live cites: accessibility-a11y, amplify ×3, authentication-authorization, civiltekk-python-backend + its scaffold.md, frontend-design), tests (none pin these names — verified in review).
- [x] **2.1** Author host + references + metadata blocks per template
    — **Why:** four reference cards share one routing method (the specialist's task-type matrix)
    — **Done when:** host ≤140; four trigger sets preserved; isolation green
    — **Consumers affected:** nextjs-specialist
    — **Done:** 4 routes scaffold|runtime-diagnosis|image-usage|threejs; devtools availability gate + fallback in host; metadata pattern merged; 687-char union description; files: skills/civiltekk-nextjs-skill/{SKILL.md,references/{setup,devtools-mcp,image,threejs}.md}; fixes: none
- [x] **2.2** Delete + repoint + impliesMcp re-home (agent, preset + mcps, opencode.json, README)
    — **Why:** a stale impliesMcp key silently breaks MCP opt-in for the whole family
    — **Done when:** `bats tests/test_requires_skills.bats` green (impliesMcp ⊆ deploy/opencode.json servers); residue clean
    — **Consumers affected:** installer MCP wiring, pack-frontend
    — **Done:** 4 dirs git-rm; impliesMcp key renamed (value unchanged); pack-frontend 4->1; agent 4->1; opencode.json 2->1; README 134->131 (Framework-Specific 8->5); 7 fellow-cites across 6 files (amplify x2 not 3 - grep truth); residue sanctioned-only; fixes: none
- [x] **2.3** Registry rebuild + scoped gate + count (131)
    — **Why:** per-commit green
    — **Done when:** registry skills=131; requires_skills + skill_profiles green
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=131); scoped gate green incl. requires_skills impliesMcp pin + isolation; count 131; fixes: none
- [x] **2.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; fixes: n.a. (stash-split incident resolved: an earlier mixed commit was soft-reset and re-split clean; force-pushed pre-PR)

### Phase 3: civiltekk-zai-media-skill
Absorbs: `zai-image-generation-skill` + `zai-video-skill` + `zai-asr-skill` + `zai-ocr-skill`. references/: `image.md`, `video.md`, `asr.md`, `ocr.md`. Routes: image | video | audio-transcribe | ocr.
MUSTS: (a) preserve the endpoint-policy split as per-variant values — image → coding-plan endpoint + `ZAI_IMAGE_ENDPOINT` + its compliance warning; video/asr/ocr → PAYG + `ZAI_MEDIA_ENDPOINT` — do NOT unify; (b) key-resolution block moves to host once (jq key-order drift noted in review — keep per-variant copies verbatim instead of merging if orders differ); (c) sync-vs-async discriminator in the route table (video polls — background-shell harness binding in host method); (d) OCR's `ponytail:` debt marker survives.
Consumers: agents/zai-media-subagent.md (4 allowlists → 1 + body), deploy/skill-profiles.json (zai-image-generation lean entry → host by SUBSTITUTION — lean stays 67 per the Wave-1 lean-host-union decision; no bats literal change), deploy/opencode.json (zai rules if any — grep), README category (AI/Media or similar — verify), pack presets if any (grep), fellow skills (grep stems `zai-image` / `zai-video` / `zai-asr` / `zai-ocr`).
- [x] **3.1** Author host + references per template (policy split preserved)
    — **Why:** one API family, four media variants; the split IS the compliance surface
    — **Done when:** host ≤140; four trigger sets preserved; per-variant env/endpoint values verbatim; isolation green
    — **Consumers affected:** zai-media-subagent
    — **Done:** routes image|video|transcribe|ocr; sync-vs-async discriminator + background-shell harness binding in host; endpoint-policy split verbatim per-variant (ZAI_IMAGE_ENDPOINT coding-plan vs ZAI_MEDIA_ENDPOINT PAYG); ponytail debt marker survived in ocr.md; 771-char 16-phrase union description; files: skills/civiltekk-zai-media-skill/{SKILL.md,references/{image,video,asr,ocr}.md}; fixes: none
- [x] **3.2** Delete + repoint (agent, skill-profiles lean entry substituted by host — count stays 67, no literal edits, opencode.json if rules exist, README counts)
    — **Why:** zai-image-generation is primary-visible — the rename must carry the lean entry or the skill vanishes from primaries (substitution, per the Wave-1 union decision)
    — **Done when:** skill_profiles green with lean still 67; residue clean
    — **Consumers affected:** primary sessions, zai-media-subagent
    — **Done:** 4 dirs git-rm; agent 4->1; skill-profiles lean SUBSTITUTION (stays 67, no literal edits — verified only zai-image was lean); opencode.json 4->1; README 131->128 (Media Generation 4->1); zero fellow-cites (grep truth); residue sanctioned-only; fixes: none
- [x] **3.3** Registry rebuild + scoped gate + count (128)
    — **Why:** per-commit green
    — **Done when:** registry skills=128; skill_profiles + isolation green
    — **Consumers affected:** installer
    — **Done:** registry rebuilt (skills=128); scoped gate green (128 tests incl. portability + isolation); count 128; fixes: none
- [x] **3.4** Commit + push
    — **Why:** atomicity
    — **Done when:** pushed
    — **Consumers affected:** none beyond phase
    — **Done:** committed + pushed with PLAN ticks; separate fix(skills) commit resolved stash-recovery markers in the P2 host (caught by P3 residue sweep); fixes: conflict-marker resolution

### Phase 4: civiltekk-opentofu-skill
Absorbs: 7 dirs — `opentofu-provider-setup-skill`, `opentofu-provisioning-workflow-skill`, `opentofu-aws-explorer-skill`, `opentofu-kubernetes-explorer-skill`, `opentofu-neon-explorer-skill`, `opentofu-keycloak-explorer-skill`, `opentofu-ecr-provision-skill`. references/: `provider-setup.md` (TRIM the 402-line tutorial while moving — keep chain-root + per-provider essentials), `workflow.md`, `explorers.md` (aws + neon + keycloak + kubernetes as four sections; kubernetes' HCL blocks may stay inline), `ecr.md` (external repo pin `ecr/betekk_probe_engine_main/` survives verbatim). Routes: first-time-setup | plan-apply workflow | explore <target> | ecr-provision.
Consumers: agents/opentofu-explorer-subagent.md (7 allowlists → 1 + body chain-root references), presets pack-devops (7 → 1), README (category DevOps/Infrastructure — verify; count 128→122), fellow skills (grep stems — amplify cites opentofu skills). NOTE: no deploy/opencode.json rules exist for opentofu-* (allowlists live solely in the agent — verified).
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
MUSTS (all step-pin rewords in the same phase): (a) `agents/pr-workflow-subagent.md` L119/147 cite "pr-creation-workflow-skill steps 2-3" → reword to reference anchors (`references/create.md` §steps); (b) `skills/gh-cli-setup-skill/SKILL.md:19` "(step 6)" anchor reword; (c) `skills/verification-loop-skill/SKILL.md` L65 table row repoint; (d) `skills/worktree-pipeline-skill/SKILL.md` cites "pr-merge-workflow-skill Phase 1 head-class rule" → host/merge route; (e) pr-workflow-subagent's allowlist GAINS civiltekk-pr-workflow-skill (it only allowlisted pr-creation — merge routing would break otherwise); (f) 3 bats files' pinned paths: test_default_behavior.bats (L366-377 pr-creation block), test_autoresearch_protocol.bats (L237-247 pr-creation block + L265-267 pr-merge crash-recovery cite — the merged pr host must cite BOTH `evaluator-contract.md` and `crash-recovery.md` from autoresearch-core), test_tiered_gating.bats L173-177 (asserts `GATE <sha> tier=full` + `never satisfies this check` INSIDE pr-creation's SKILL.md — the literals must live in the host or references/create.md and the test path repointed); (g) `skills/semantic-release-convention-skill/SKILL.md:18,:210` cite pr-merge-workflow-skill head-class rule → repoint (5th skill-body citer).
Consumers: agents/pr-workflow-subagent.md + agents/repo-ops-specialist-subagent.md (2 allowlists → 1 each), presets pack-devops, README (Git/Workflow), the 5 skill-body citers above.
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
MUSTS: (a) exactly ONE Iteration Protocol section (bats pin `appears_exactly_once`); (b) MagicMock-headers pitfall exists once (framework reference), cited by both stack references; (c) the creators' undeclared-prereq gap is ELIMINATED by the merge (dirs gone; no requiresSkills entry needed — note in commit body); (d) pinned bats blocks repointed (inventory re-derived from disk — review-corrected): test_default_behavior.bats L690-707 + L718-736 (pytest-creator) + L747-766 (nextjs-unit-test-creator — preamble + appears_exactly_once + evaluator-token pins) and test_autoresearch_protocol.bats L437-448 + L452-485 (pytest + unit-test Iteration-Protocol/metadata/reference-cite pins); the L366-377 and L237-247 blocks are pr-creation's (Phase 5 scope).
Consumers: agents/testing-subagent.md (3 allowlists → 1 + body), agents/tdd-subagent.md (grep — review found no live cites; skip if clean), presets pack-frontend (unit-test-creator), deploy/opencode.json (grep — review found no rules for these members; skip if clean), README (category Testing/Framework), fellow skills (grep stems `test-generator-framework` / `python-pytest-creator` / `nextjs-unit-test-creator`).
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

- Count ladder (base 135): 134 · 131 · 128 · 122 · 121 · 119. Lean stays 67 throughout (zai host substitutes its member per the union decision — no literal edits).
- The lookbehind residue grep `(?<!civiltekk-)(?<!/)name` is mandatory (Wave-1 LEARNINGS: rename-residue-sweeps-need-lookbehind-anchor).
- Bats-pin inventories are re-derived from disk per member (`grep -n '<stem>' tests/`) at each phase — never transcribed from ticket prose (review LEARNINGS candidate on PLAN-604's own Phase-6 mis-scoping).
- Delegation model unchanged: N.1–N.2 to general-subagents (phase block + template + residue constant), N.3–N.4 (gate+commit) to orchestrator. Custom reviewer agents are absent from this session's registry — reviews run via general-agent reviewer prompts; PR creation direct via gh per pr-workflow method.

## Dependencies

None active (the #614 hold resolved — Wave 1 merged as 7a725c5 before this PLAN committed). Phases ordered risk-ascending; Phase 6 last (pinned-literal discipline).

## Risks & Mitigation

- **Phase 5 step-pin rewords are prose contracts** — each citing surface verified by its own test or explicit grep in the same commit; five skill-body citers incl. semantic-release.
- **Phase 6 pinned-literal migration** — six bats blocks; any literal landing twice/zero times trips `appears_exactly_once` or a failed grep; per-block verification in 6.2.
- **Conflict-marker guard** — Phase 7 adds a repo-wide `grep -rn "^<<<<<<<"` to the exit sweep (the P2 incident shipped markers through a green scoped gate; prose is untested surface).
- **impliesMcp key rename** — test_requires_skills asserts values ⊆ deploy/opencode.json servers; value unchanged, key renamed — green by construction, verified in 2.3.
- **Count arithmetic** — 22−6=−16 → 119; re-derive from disk at 7.2, never from this note.
WORK LOG - W2 base 8cf5b6c
GATE 8cf5b6c tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 0814744 tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 1dea685 tier=light lint=- typecheck=- build=- unit=t e2e=n.a
