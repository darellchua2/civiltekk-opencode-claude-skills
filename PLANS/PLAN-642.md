# PLAN: LEARNINGS captures commit at end of ticket — kill the dirty `_index.md` clash

**Branch**: feat/642
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/642
**Base**: main

## Acceptance Criteria

Inherited from ticket #642 (definition of done — the PLAN never rewrites them):

- [ ] LEARNINGS captures land committed + pushed with a defined owner: **standalone sessions commit at write time** (one `chore(learnings): <slug>` commit: body + `_index.md` entry + `.gitignore` negation when the repo ignores `LEARNINGS/**/*.md`); **plan/pipeline runs never commit mid-phase** and land **one trailing `chore(learnings)` commit at end of ticket**. Push: only when the session's flow pushes — a local commit already clears the `pull`/`rebase` clash, and unconditional push would break on protected branches (plan-review gap resolution, 2026-09-29).
- [ ] No instruction surface leaves a checkout holding a dirty tracked `_index.md` at rest.
- [ ] The `.gitignore` `!`-negation requirement is taught wherever the commit rule lives (the add otherwise errors on / silently drops the ignored body file).
- [ ] `scope=user` captures (`~/.config/opencode/LEARNINGS/`) explicitly skip the commit (not a git repo).
- [ ] No SKILL.md frontmatter touched → `installer/registry.json` byte-identical (`node installer/build-registry.mjs --check` clean).
- [ ] No new fenced bash blocks in skill bodies (portability Bash rule) — new commands stay inline.
- [ ] `deploy/.AGENTS.md` change propagated to `~/.config/opencode/AGENTS.md` via redeploy, verified.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/continuous-learning-skill/SKILL.md` (body, new step 6) | — | primary sessions post-capture; deployed copies (redeploy); npx per-skill installs; `deploy/.AGENTS.md` §Memory Hygiene defers here | low — additive step, renumber 6→7, 7→8 |
| `deploy/.AGENTS.md` §Memory Hygiene | canonical rule wording (1.1) | `deploy/setup.sh` (copies to `~/.config/opencode/AGENTS.md`); every project post-redeploy; repo root `AGENTS.md` §Project Learnings points here | low-med — global propagation |
| `skills/plan-execution-skill/SKILL.md:98` | — | every `/run-plan` --gate run; README flavor docs | low — one sentence extension |
| `skills/plan-execution-inline-skill/SKILL.md:86` | — | `/run-plan-v2` + `/run-worktree-pipeline-v2` Step 8; `installer/presets/pack-inline-workers.json` membership | low — twin sentence |
| `skills/worktree-pipeline-skill/SKILL.md` Step 9 (:200-209) | — | both pipeline commands (v1 subagent arm + v2 inline arm); `tests/test_v2_pipeline_contract.bats` pins the **command template** only (verified: no test pins Step 9 skill text) | med — reorder of learnings-commit timing; ordering vs Step 10a + gate-memo citation must stay coherent |
| `skills/code-review-inline-skill/SKILL.md:88` | — | v2 pipeline Step 9; inline-workers preset | low — table row append |
| `.gitignore` | — | NOT edited by this ticket (future captures append negations per the new rule) | none |

Cross-module signal for Step 7 triage: `deploy/.AGENTS.md` is consumed by `deploy/setup.sh` (global deploy path) — consumer beyond the node itself → architecture review selected.

## Implementation Phases

### Phase 1: Canonical capture-commit rule

- [x] **1.1** Insert new step 6 into `skills/continuous-learning-skill/SKILL.md` §Core Workflow (after current step 5; renumber old 6→7, 7→8) stating: never leave `LEARNINGS/` dirty at rest; standalone session → commit at write time (`git add LEARNINGS/_index.md LEARNINGS/<category>/<slug>.md` → `git commit -m "chore(learnings): <slug>"`, pushed only when the session's flow pushes — a local commit already clears the pull/rebase clash; unconditional push breaks on protected branches); inside a plan-execution/worktree-pipeline run → working-tree only, the run lands one trailing `chore(learnings)` commit at end of ticket; when the repo ignores `LEARNINGS/**/*.md` the committing step also appends the `!LEARNINGS/<category>/<slug>.md` negation to `.gitignore` in the same commit; skip entirely when `scope=user` (not a git repo).
    — **Why:** This skill is the full procedure `deploy/.AGENTS.md` §Memory Hygiene defers to; without the commit step here the rule has no canonical home and every other surface restates it differently.
    — **Done when:** the numbered workflow contains the step between the `_index.md` write step (5) and "Suggest applications" (now 7); old steps 6-7 renumbered; no other section changed; frontmatter byte-identical.
    — **Consumers affected:** primary sessions post-capture; deployed copies on redeploy; npx installs.
    — **Done:** new step 6 inserted (standalone write-time commit with push-flow caveat / run working-tree-only + end-of-ticket sweep / gitignore-negation clause / scope=user skip); old 6-7 renumbered 7-8; files: skills/continuous-learning-skill/SKILL.md; fixes: none

- [x] **1.2** Add one bullet to `deploy/.AGENTS.md` §Memory Hygiene after the **Capture** bullet: standalone sessions commit each capture at write time — one `chore(learnings): <slug>` commit (body + `_index.md` + any needed `.gitignore` negation) — never left dirty (dirty tracked `_index.md` blocks `pull`/`rebase` against worktree merges); pipeline/plan runs never commit mid-phase, they land one trailing `chore(learnings)` commit at end of ticket; `scope=user` skips.
    — **Why:** This file deploys to `~/.config/opencode/AGENTS.md` — it is the line that reaches all projects; without it the rule stays repo-local.
    — **Done when:** bullet present after Capture; section otherwise untouched; full procedure still deferred to `continuous-learning-skill`.
    — **Consumers affected:** `deploy/setup.sh` copy step; every project post-redeploy.
    — **Done:** Commit bullet added after Capture in §Memory Hygiene (write-time commit, push-flow caveat, end-of-ticket sweep, scope=user skip); files: deploy/.AGENTS.md; fixes: none

### Phase 2: Pipeline surfaces adopt the same rule

- [ ] **2.1** Extend the rule-4f sentence at `skills/plan-execution-skill/SKILL.md:98`: after "PLAN ticks, Done lines, and gate memos ride inside this one atomic commit" append that LEARNINGS writes never do — they stay working-tree only through the run, and the run lands one trailing `chore(learnings)` commit at end of run (all bodies + `_index.md` + `.gitignore` negations when the repo ignores `LEARNINGS/**/*.md`); standalone runs commit + push it right after the exit gate (`--soft`: before the end-of-run tick commit); runs invoked as a pipeline subroutine leave the sweep to the pipeline's end-of-ticket commit.
    — **Why:** The per-phase commit is the place an executor would otherwise stage LEARNINGS by accident; the explicit ban + named trailing-commit owner closes the gap and states where the capture lands instead.
    — **Done when:** sentence extended; `git add <phase files>` add-list itself unchanged; no frontmatter change.
    — **Consumers affected:** every `/run-plan` --gate run (learnings now excluded from phase commits, guaranteed trailing commit).

- [ ] **2.2** Apply the identical extension to the twin line `skills/plan-execution-inline-skill/SKILL.md:86`.
    — **Why:** The inline executor powers `/run-plan-v2` and pipeline v2 Step 8; divergence between the twins is the classic drift source (same line, two files).
    — **Done when:** the two sentences are textually identical apart from nothing (byte-equal clause).
    — **Consumers affected:** `/run-plan-v2`, `/run-worktree-pipeline-v2` Step 8.

- [ ] **2.3** Rework the Step 9 LEARNINGS block `skills/worktree-pipeline-skill/SKILL.md:200-209` so that: all LEARNINGS writes from the entire run (phase-time captures left dirty by Step 8 + review candidates) land in **one dedicated end-of-ticket `chore(learnings)` commit** — the current "commit them with the review-fix commit" folding is removed; the commit includes each new body's `!LEARNINGS/<category>/<slug>.md` `.gitignore` negation where the repo ignores `LEARNINGS/**/*.md`; any final PLAN re-ticks / gate-memo appends fold into this same commit so its SHA is the final pushed SHA Step 10a cites (docs-only — anything code-shaped riding it triggers the re-gate rule); ordering stays after the bounded review loop and before Step 10a (overlap-hold rebase needs a clean tree). Also refresh the tracked `_index.md` row that summarizes the #445 single-writer rule (`:274` at plan time — locate by `#445`, line may drift) to name the single end-of-ticket commit instead of the old review-fix folding.
    — **Why:** Step 9 is the only surface that already commits learnings; aligning it with the end-of-ticket rule (user decision 2026-09-29) makes the pipeline the single sweep point and keeps review-fix commits logic-only. The index row is the tracked restatement of that rule — leaving it stale recreates the exact index/body drift the house rules kill.
    — **Done when:** Step 9 states the single end-of-ticket commit + negation clause + docs-only/re-gate clause + before-10a ordering; the `_index.md` #445 row names the end-of-ticket commit; the fetch-only workaround at :267-269 unchanged; `LEARNINGS candidates:` report contract untouched.
    — **Consumers affected:** both pipeline commands; Step 10a gate-memo citation path.

- [ ] **2.4** Append to the enforcement-delta table row at `skills/code-review-inline-skill/SKILL.md:88` ("You MAY write — restrict writes to LEARNINGS entries and granted fix commits"): "; every LEARNINGS write lands in the run's single end-of-ticket `chore(learnings)` commit — never in fix commits, never left dirty past the ruling commit step".
    — **Why:** The inline reviewer holds the write grant; without the pointer its writes could be folded into fix commits or left dirty, violating the rule Phase 2 just established.
    — **Done when:** row updated; no cross-skill path references added (Skill Isolation Contract).
    — **Consumers affected:** v2 pipeline Step 9 review arm.

### Phase 3: Verify + propagate

- [ ] **3.1** Verification greps + registry guard: `grep -c "chore(learnings)"` ≥1 in each of the 5 edited files; `grep -n "scope=user"` present in the new continuous-learning step; `grep -n "end of ticket"` present in plan-execution-skill and worktree-pipeline-skill; `node installer/build-registry.mjs --check` clean (frontmatter untouched → registry byte-identical); `git diff --stat origin/main` shows exactly the 6 files (5 skill bodies + `deploy/.AGENTS.md`), nothing else.
    — **Why:** Mechanical proof the ACs (frontmatter untouched, scope of change, rule present everywhere) hold before commit-heavy verification runs.
    — **Done when:** every listed command exits green / prints the expected count.
    — **Consumers affected:** none (verification only).

- [ ] **3.2** Full bats suite from the repo root (`bats tests/` or per-file if runner lacks bats, per CI invocation conventions) — the ticket exit-gate rehearsal for a docs-only change.
    — **Why:** The Consumer Map names tests as consumers; the suite is the repo's only executable guard that could regress on body-text changes (verified no pins on edited spans, so expectation: green).
    — **Done when:** suite exits 0 (or N/A cleanly reported where the runner lacks deps — then the exit gate records INCONCLUSIVE per verification-loop-skill, not silently skipped).
    — **Consumers affected:** CI mirrors this locally.

- [ ] **3.3** Redeploy + verify propagation: run `./deploy/setup.sh` (propagates `deploy/.AGENTS.md` → `~/.config/opencode/AGENTS.md`), then `grep -n "chore(learnings)" ~/.config/opencode/AGENTS.md` shows the new bullet.
    — **Why:** The ticket's Environment names the user-space deploy as the delivery vehicle; without redeploy the rule stays inert for all other projects.
    — **Done when:** redeploy exits clean and the grep hits.
    — **Consumers affected:** every project using the deployed config.

## Technical Notes

- Root-cause review (2026-09-29 session): the clash is two writers of the single tracked `_index.md` (`.gitignore:38` negation), only the worktree arm taught to commit. Evidence anchors verified in this worktree: `skills/plan-execution-skill/SKILL.md:98`, `skills/plan-execution-inline-skill/SKILL.md:86`, `skills/worktree-pipeline-skill/SKILL.md:200-209`, `skills/code-review-inline-skill/SKILL.md:88`, `skills/continuous-learning-skill/SKILL.md:47`, `.gitignore:37-38`.
- Draft plan from the review session: `~/.opencode/plan/PLAN-LEARNINGS-COMMIT-HYGIENE.md` (outside repo; content absorbed here).
- `plugins/opencode-learnings-autoinject.ts` is read-only (manifest injection, line 247) — no plugin change needed; the writer is always an agent following these instructions.
- House commit conventions: `fix(skills): ...` for the implementation commit; PLAN ticks ride the phase commit (4f); the trailing learnings rule this ticket introduces applies to captures made from now on.

## Dependencies

- None — no `blocked-by:` refs; single-ticket run.

## Risks & Mitigation

- **Wording drift between the twins** (2.1/2.2) → Done-when requires byte-equal clauses.
- **Step 9 reorder breaks the gate-memo citation** (final SHA must carry `tier=full`) → 2.3 keeps memo appends folded into the learnings commit and states the docs-only/re-gate clause; Step 9's existing re-gate rule is untouched.
- **Redeploy side effects** (setup.sh rewrites user config) → it is the documented idempotent redeploy path; run only after 3.1/3.2 green.
- **Bats unavailable locally** → report INCONCLUSIVE per verification-loop-skill gate semantics; never silently skip.
