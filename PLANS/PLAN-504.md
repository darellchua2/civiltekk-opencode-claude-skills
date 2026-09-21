# PLAN: Add question payload specs to worktree-pipeline-skill

**Branch**: feat/504
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/504
**Base**: main

## Acceptance Criteria
- [ ] 6a step 4 (multiple PLAN candidates) has a complete payload spec (`question`, `header`, `multiple`, ≥2 options with `label`+`description`)
- [ ] 6b (BRD/SRS draft linking) has a complete payload spec including the decline option
- [ ] Both specs follow the git-branch-workflow §Question Tool Spec shape exactly — no field omitted
- [ ] Inline in SKILL.md only (skill-isolation contract #437 — no shared files)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/worktree-pipeline-skill/SKILL.md` | — | primary agent at runtime (skill loader), `installer/registry.json` (description only — body not copied), deployed copy via `deploy/setup.sh` wholesale copy | low |

Single-node map: docs-only edit to one skill body; no code, no cross-module consumers. registry.json carries only the frontmatter `description` (unchanged) — no registry rebuild needed.

## Implementation Phases

### Phase 1: 6a payload spec (multiple-candidate adoption prompt)
- [ ] **1.1** In `skills/worktree-pipeline-skill/SKILL.md` §6a step 4, append a fenced json block with a complete `question` payload for "which draft to adopt" — `question` + `header` + `multiple:false` + options with `label` AND `description` (template options: adopt the listed draft / keep drafts in place; model instantiates per candidate), plus a one-line pointer to deployed `AGENTS.md` §Question Tool Payloads
    — **Why:** the site currently says "prompt the user which to adopt" with no payload — freehand construction is the dropped-field class (#448 audit: 7/1158 schema failures, all missing-required-field); a verbatim shape removes the improvisation
    — **Done when:** `rg -c '"header"' skills/worktree-pipeline-skill/SKILL.md` counts the 6a block and `rg '"multiple"'` + ≥2 `"label"` + `"description"` pairs all hit inside §6a
    — **Consumers affected:** model runtime at 6a step 4

### Phase 2: 6b payload spec (BRD/SRS link prompt) + exit gate
- [ ] **2.1** In §6b, replace the prose-only "ask the user (via `question`) whether to link one" bullet with the same-shape fenced json payload including an explicit decline option ("Skip — no link"), mirroring `skills/git-branch-workflow-setup-skill/SKILL.md` §Question Tool Spec field-for-field
    — **Why:** same freehand risk; the decline option encodes the existing "Declined/absent → empty path" behavior so the payload alone carries the full decision tree
    — **Done when:** §6b contains a json block with `question`, `header`, `multiple`, and a decline option whose label matches the skip semantics; shape matches the git-branch-workflow spec (same keys, same nesting)
    — **Consumers affected:** model runtime at 6b
- [ ] **2.2** Exit gate (full): repo bats suite + node plugin tests in the worktree; GATE memo recorded in this PLAN's trace
    — **Why:** pipeline ticket exit gate — the final pushed SHA must carry a green `tier=full` memo
    — **Done when:** `bats tests/` green and `node --test tests/test_question_repair_plugin.test.ts tests/test_vibeguard_walkdeep.test.ts` green on the worked tree; memo line appended under ## Gate Trace
    — **Consumers affected:** Step 9 review + Step 10 PR citation

## Technical Notes
- Mirror shape source: `skills/git-branch-workflow-setup-skill/SKILL.md` lines 70-98 (§Question Tool Spec).
- Hygiene rule pointer target: `deploy/.AGENTS.md` §Question Tool Payloads (one-line payloads, all fields).
- Skill-isolation contract #437: specs stay inline in SKILL.md — no shared spec file, no cross-skill reference beyond the prose pointer.
- Docs-only change: no lint/typecheck/build targets apply; gate = repo suites (bats + node --test).

## Dependencies
None (`blocked-by:` absent). Complements #448 (question-repair plugin) — source-side reduction of the same failure class.

## Risks & Mitigation
- Payload blocks could drift from the git-branch-workflow spec shape → Done-when greps pin the four field names per block; code review compares shapes explicitly.
- Over-specifying candidate options (dynamic draft names) → specs use template placeholders with a keep-in-place fallback option, matching 6a's variable candidate count.

## Gate Trace
