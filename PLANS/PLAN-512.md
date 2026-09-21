# PLAN: Per-harness capability bindings in runtime-dependent skills

**Branch**: feat/512
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/512
**Base**: main

## Acceptance Criteria
- [ ] Every listed file carries the binding block in the canonical format
- [ ] OpenCode rows preserve current behavior verbatim
- [ ] No OpenCode-only mechanism remains without a portable fallback row in these files

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| 5 question-tool skills (ticket-creation, docling-mcp, worktree-pipeline, opencode-repo-setup, git-branch-workflow-setup) | #510 contract (merged) | agents running interactive flows; #515 guard (fallback-row check) | low |
| 2 background-exec skills (playwright-responsive-audit, zai-video) | #510 contract | agents running long polls/loops | low |
| 3 zai credential skills (zai-asr, zai-ocr, zai-image-generation) | #510 contract | media-subagent recipes | low |
| 4 subagent-delegation skills (error-resolver, vision-creation, technical-design-creation, plan-execution) | #510 contract | workflow runners | low |
| pptx-generate-template-skill (headless fallback extension) | #511 (merged — env-var snippets) | template pipeline | low |
| Deployed copies (~/.config/opencode) | this PR merged + redeploy | live sessions | none (source-of-truth repo; deploy is a separate act) |

## Implementation Phases

Binding-block format per AGENTS.md §Portability contract (merged via #510): capability sentence + OpenCode row + Claude Code row + portable-fallback row. Insert at the capability site; never restate the whole contract.

### Phase 1: question-tool bindings

- [x] **1.1** `skills/ticket-creation-skill/SKILL.md` — extend the Agent behavior rules (:120 area) with the question-tool binding block (OpenCode `question` · Claude `AskUserQuestion` · other/none: ask the same fields in a plain reply, proceed on defaults per the headless rule).
    — **Why:** :86/:120 instruct "batch a `question` call" as if universal; the tool name is OpenCode-specific.
    — **Done when:** the block exists in the file and mentions all three rows.
    — **Consumers affected:** ticket-flow agents on non-opencode harnesses.
    — **Done:** binding block appended after the behavior-rules list; files: skills/ticket-creation-skill/SKILL.md; fixes: none
- [x] **1.2** `skills/docling-mcp-skill/SKILL.md` — extend the :51 consent row with the same binding block (consent question).
    — **Why:** install-consent must be askable on any harness.
    — **Done when:** block present at the consent row.
    — **Consumers affected:** docling installers.
    — **Done:** binding inlined in the consent table row (no-answer = declined → headless soft-fail); files: skills/docling-mcp-skill/SKILL.md; fixes: none
- [x] **1.3** `skills/worktree-pipeline-skill/SKILL.md` — extend the :250 draft-linking ask with the binding block.
    — **Why:** PLAN-adoption prompting is a runtime `question` call.
    — **Done when:** block present near :250.
    — **Consumers affected:** pipeline runs on other harnesses.
    — **Done:** binding inlined at the draft-linking ask (unanswered = skip linking); files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **1.4** `skills/opencode-repo-setup-skill/SKILL.md` — add a minimal binding note at :48 (Step 2 — Ask): OpenCode `question` · Claude `AskUserQuestion` · none: print the numbered menu in a plain reply and wait for a reply.
    — **Why:** ticket scope; the skill is otherwise opencode-bound (harness metadata lands in #514) so the block stays minimal.
    — **Done when:** note present at Step 2.
    — **Consumers affected:** repo-setup agents.
    — **Done:** minimal binding note added under Step 2 heading; files: skills/opencode-repo-setup-skill/SKILL.md; fixes: none
- [x] **1.5** `skills/git-branch-workflow-setup-skill/SKILL.md` — soften :153: replace "they cannot use the `question` tool or spawn subagents" with "in OpenCode, skills are knowledge documents loaded BY agents — the `question` tool and subagent spawning belong to the agent layer (other harnesses differ; use the §Non-Interactive Fallback when prompting is unavailable)".
    — **Why:** the assertion is OpenCode-specific stated as universal.
    — **Done when:** the universal phrasing is gone; fallback reference retained.
    — **Consumers affected:** skill authors reading the assertion.
    — **Done:** universal phrasing replaced with opencode-scoped statement + fallback pointer; files: skills/git-branch-workflow-setup-skill/SKILL.md; fixes: none

### Phase 2: background-execution bindings

- [x] **2.1** `skills/playwright-responsive-audit-skill/SKILL.md` — insert the background-exec binding block at :32 (OpenCode `background: true` · Claude `run_in_background: true` · none: `nohup <cmd> > /tmp/opencode/audit-pass.log 2>&1 &` + re-check per step, stop via `kill`/`taskkill`).
    — **Why:** the loop's stoppable-pass model depends on background shells named opencode-style.
    — **Done when:** block present at :32 and names all three rows.
    — **Consumers affected:** audit runners on other harnesses.
    — **Done:** binding rows inlined in the loop paragraph; OpenCode row behavior preserved verbatim; files: skills/playwright-responsive-audit-skill/SKILL.md; fixes: none
- [x] **2.2** `skills/zai-video-skill/SKILL.md` — formalize the :90 fallback into the canonical block shape (same three rows; keep the existing nohup/log-poll wording as the fallback row).
    — **Why:** this file is the contract's cited prior art; aligning it makes the format self-demonstrating.
    — **Done when:** the block matches the canonical row structure.
    — **Consumers affected:** video-poll agents.
    — **Done:** canonical rows at the poll step; legacy fallback line repointed to the row; files: skills/zai-video-skill/SKILL.md; fixes: none

### Phase 3: zai credential + recipe-execution bindings

- [ ] **3.1** `skills/zai-asr-skill/SKILL.md`, **3.2** `skills/zai-ocr-skill/SKILL.md`, **3.3** `skills/zai-image-generation-skill/SKILL.md` — add one binding note above each credential recipe: credential source — `ZAI_API_KEY` env var works everywhere (portable row); the `~/.local/share/opencode/auth.json` lookup is an OpenCode-only bonus (ignore on other harnesses; export the env var). Recipe execution — requires bash + curl + jq (any harness with a shell tool).
    — **Why:** auth.json is opencode's credential store; env var is already the primary path in the recipes, the note makes the priority explicit per the contract.
    — **Done when:** note present in all three files; recipe logic untouched.
    — **Consumers affected:** zai-media recipe runners.

### Phase 4: subagent-delegation bindings

- [ ] **4.1** `skills/error-resolver-workflow-skill/SKILL.md` — extend :97 with the delegation binding (OpenCode/Claude: Task tool · other/none: run the subagent's diagnosis checklist inline; :98's direct-API fallback already covers the provider-level gap).
    — **Why:** "Task tool" phrasing reads universal; inline-run needs stating.
    — **Done when:** binding present at the primary path.
    — **Consumers affected:** error-resolution flows.
- [ ] **4.2** `skills/vision-creation-skill/SKILL.md` — add the delegation binding at :169 (pptx deck distillation) covering also the :171 image-routing mention.
    — **Why:** two delegation sites, one binding note covers both.
    — **Done when:** binding present; no per-site duplication.
    — **Consumers affected:** vision-flow runners.
- [ ] **4.3** `skills/technical-design-creation-skill/SKILL.md` — extend :355 (explore fallback) with the binding row (none: grep/glob/read inline — the sentence already lists them; make the row explicit).
    — **Why:** Task-tool phrasing at the fallback site.
    — **Done when:** binding row explicit at :355.
    — **Consumers affected:** design-authoring flows.
- [ ] **4.4** `skills/plan-execution-skill/SKILL.md` — extend :83 (responsive-audit spawn) with the delegation binding (none: run `npx playwright test` inline per the sentence's alternative).
    — **Why:** spawn phrasing; the inline alternative exists but isn't bound to a harness row.
    — **Done when:** binding present at :83.
    — **Consumers affected:** plan executors.

### Phase 5: pptx extension + verification

- [x] **5.1** `skills/pptx-generate-template-skill/SKILL.md` — extend the headless/subagent fallback (search "Headless / subagent mode") into the canonical block (OpenCode `question` · Claude `AskUserQuestion` · none/headless: print the table, proceed to Stage 3 — existing behavior).
    — **Why:** ticket scope; the fallback exists but isn't in canonical row form.
    — **Done when:** block in canonical shape.
    — **Consumers affected:** template pipeline on other harnesses.
    — **Done:** interactive binding rows appended at the Stage-2 confirmation fallback (:186); files: skills/pptx-generate-template-skill/SKILL.md; fixes: none
- [x] **5.2** Verification: repo-wide probe — every file listed in the ticket contains ≥1 binding block naming a portable fallback row (`rg -c 'Other/none:'` across the 16 files, ≥1 each); OpenCode rows unchanged (`git diff` shows no OpenCode-row text removed); full exit gate.
    — **Why:** the AC is coverage + non-regression, not prose quality.
    — **Done when:** 16/16 files carry a fallback row; diff audit clean; full suite green.
    — **Consumers affected:** #515 guard (will enforce presence mechanically).
    — **Done:** probe 15/15 files ≥1 binding/fallback marker (git-branch-workflow via its 3 pre-existing fallback sections); diff audit — 2 removed "OpenCode" lines are the zai-video rephrase with behavior preserved in the binding row; full suite 529/529; files: none (verification); fixes: none

## Gate Trace

GATE 727eeb2 tier=light lint=t typecheck=n.a build=- unit=t e2e=n.a
GATE 29b56d4 tier=light lint=t typecheck=n.a build=- unit=t e2e=n.a
GATE 863fefe tier=light lint=t typecheck=n.a build=- unit=t e2e=n.a
GATE 99b78bf tier=light lint=t typecheck=n.a build=- unit=t e2e=n.a
GATE 99b78bf tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a
Note: lint axis = binding-presence probes (per-phase counts in Done lines) + frontmatter validation via build-registry substitute. Later PLAN-only commits are tree-equivalent to 99b78bf content; CI is the unconditional re-run.

## Technical Notes
- Keep each insertion ≤5 lines; the contract section (AGENTS.md) stays the single full definition — skills carry only their local block.
- opencode-repo-setup gets a minimal note, not a full block: it is opencode-bound by subject (harness marker in #514); over-binding it would imply portability it doesn't have.
- zai recipes are NOT ported to PowerShell (that's a declaration in #513's scope, not a rewrite here) — the binding note only clarifies credential-source priority.
- `Task tool` is both OpenCode's and Claude Code's subagent tool name — the binding's value is the explicit inline fallback for harnesses without any subagent tool, not the rename.

## Dependencies
- blocked-by: #510 (conventions — merged via PR #523).

## Risks & Mitigation
- *Binding-block sprawl* (16 files × prose) → ≤5-line insertions at the capability site only; #515's guard checks presence, not prose volume.
- *Editing worktree-pipeline-skill while running it* → source edit affects future loads only; the running instructions live in session context.
- *Drift between the 4 near-identical question-tool blocks* → identical wording for the shared rows; per-site rows only where the capability differs (consent vs intake vs menu).
