# PLAN: Publish two new LEARNINGS entries to the tracked index

**Branch**: feat/542
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/542
**Base**: main

## Acceptance Criteria

- [ ] Both files tracked and pushed, referenced from the new `_index.md` rows
- [ ] `.gitignore` diff = exactly 2 negation lines
- [ ] `_index.md` diff = exactly the 2 new entry blocks (17 insertions)
- [ ] `git check-ignore`: the two files NOT ignored; every other `LEARNINGS/**/*.md` still ignored
- [ ] bats suite green (full run — no LEARNINGS consumers expected, prove it)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `.gitignore` (+2 per-file negations after :38, mirroring the `!LEARNINGS/_index.md` precedent) | — | git index behavior only — grep census of tests/ shows zero bats consume .gitignore or LEARNINGS contents (4 comment-only mentions) | low — file-level rule `LEARNINGS/**/*.md` permits per-file negation (parent dirs not excluded) |
| `LEARNINGS/_index.md` (+17 lines, the two entry blocks) | .gitignore unchanged for it (already negated :38) | local auto-inject plugin (reads disk, not git); humans; cloners browsing the index | low — additive rows; references the two files tracked in this same change |
| `LEARNINGS/patterns/by-reference-docs-mechanize-no-duplication-with-sentinel-greps.md` (new) | negation precedes `git add` | `_index.md` row (within-change) | low — new file |
| `LEARNINGS/conventions/docs-runnable-snippets-must-match-ci-invocation.md` (new) | negation precedes `git add` | `_index.md` row (within-change) | low — new file |

No cross-module consumers → zero Step-7 reviewers (thin map; Step 9 code review backstops).

## Implementation Phases

### Phase 1: Publish the two entries + full exit gate

- [ ] **1.1** Materialize the change in the worktree (it cuts from origin/main and lacks the maintainer's uncommitted local state — copy from the main checkout at /home/silentx/VSCODE/civiltekk-opencode-claude-skills): (a) append 2 negation lines to `.gitignore` after :38 (`!LEARNINGS/patterns/by-reference-docs-mechanize-no-duplication-with-sentinel-greps.md`, `!LEARNINGS/conventions/docs-runnable-snippets-must-match-ci-invocation.md`); (b) `cp` the two content files from the main checkout; (c) `cp` the main checkout's `LEARNINGS/_index.md` over the worktree's (its diff vs origin/main is exactly the +17 entry rows — verified pre-plan: `git diff --stat` = 17 insertions, nothing else).
    — **Why:** the ticket's deliverable — publish exactly these two entries; the copy step is required because gitignored+uncommitted state does not travel with worktrees
    — **Done when:** all three artifacts present in worktree; `git status` shows .gitignore, _index.md modified + 2 untracked-but-now-includable files
    — **Consumers affected:** none at runtime (documentation)
- [ ] **1.2** Full exit gate: (a) `git check-ignore -q` exits NON-zero for both new files; a control file (any other `LEARNINGS/**/*.md`) STILL ignored; (b) `.gitignore` diff vs origin/main = exactly 2 added lines, both negations; (c) `_index.md` diff = exactly 17 insertions containing the two `### ` entry headings; (d) `git add` all four artifacts → `git status --cached` shows exactly 4 paths; (e) full bats suite `bats tests/` green
    — **Why:** AC requires mechanical proof of scope exactness (2 lines, 17 rows, 4 paths) and no test regressions
    — **Done when:** all green
    — **Consumers affected:** pipeline gate memo
- [ ] **1.3** Commit (`docs(learnings): publish two new entries to the tracked index`), write the `tier=full` gate memo into the Trace block, tick ACs, push
    — **Why:** PR citation requires a green tier=full memo on the pushed SHA
    — **Done when:** memo on pushed SHA; PLAN fully ticked
    — **Consumers affected:** pr-workflow citation

## Technical Notes

- Negation placement: after the existing `!LEARNINGS/_index.md` (:38) — gitignore is last-match-wins and parent dirs of these files are not ignored, so per-file negation works.
- The three evidence-add edits from the same session stay LOCAL (still-ignored files) — out of scope by ticket design.

## Dependencies

None. Hard pipeline deps satisfied (plan-execution-skill, code-review-subagent, pr-workflow-subagent).

## Risks & Mitigation

- **Over-publishing** (more than 2 files/17 rows riding along) — mitigated by 1.2(b)(c)(d) exactness checks against origin/main diffs.
- **Broken negation syntax** (file stays ignored, add silently no-ops) — mitigated by 1.2(a) check-ignore assertions BEFORE add, and staged-path count.

## Trace

| Phase | Gate | Result | Notes |
|-------|------|--------|-------|
| — | — | — | executor appends per-phase rows; final `tier=full` memo line required |
