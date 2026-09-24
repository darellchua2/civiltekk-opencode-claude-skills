---
name: worktree-pipeline-skill
description: >-
  Tracker-ticket-to-merged-PR pipeline via git worktrees — sync, plan,
  adaptive review, /run-plan, code review, PR merge. Triggers:
  run-worktree-pipeline, worktree pipeline, ticket to PR pipeline,
  tracker ticket pipeline.
license: Apache-2.0
compatibility: opencode
metadata:
  pattern: hub-and-spoke
category: Git/Workflow
---

## What I do

I run the **full ticket-to-merged-PR pipeline**, one ticket at a time, each in
its own **git worktree** so the main working tree stays free. I am the
orchestrator: heavy knowledge lives in the skills/subagents I drive
(`ticket-creation-skill` for new tickets, `plan-execution-skill` --gate for
execution, `pr-workflow-subagent` for the PR) — I own sequencing, PLAN
authoring, worktree lifecycle, and re-validation.

Usage: `/run-worktree-pipeline [--dry-run] [base-branch] <ticket-refs...>`

## Step 1 — Parse arguments

- Leading `--`-flags are stripped before the first-token test (`--dry-run`
  is the only flag).
- First token is a **base-branch** iff it fails the ticket regex
  `^(#\d+|[\w.-]+/[\w.-]+#\d+|[A-Z][A-Z0-9]+-\d+)$` **and is not purely
  numeric**.
- Bare numerics (`351`) auto-normalize to GitHub issue refs (`#351`).
- Zero ticket refs → print usage and stop.
- The base-branch sets **both** where feat branches are cut from AND the PR
  target. Default (omitted): repo default branch via
  `git symbolic-ref --short refs/remotes/origin/HEAD` (yields
  `origin/<base>`; strip the prefix; fallback `main`).
- **Validate the base** after resolving it:
  `git ls-remote --exit-code --heads origin <base>`; non-zero exit → abort
  with a clear error naming the attempted base (fail-fast — never reach
  Step 2 with a typo'd base).
- **`--dry-run`**: print the resolved base, ticket execution order,
  per-ticket skip predictions (merged / `blocked-by:`), and the would-be
  `feat/<KEY>` branch + worktree names, then stop before Step 2. Read-only:
  no writes, no branch/worktree/remote mutations.
- **Dependency preflight (per-skill installs)**: hard deps — skill
  `plan-execution-skill` --gate (Step 8), agents `code-review-subagent`
  (Step 9) and `pr-workflow-subagent` (Step 10). Any missing → abort
  (`failed`) with the install hint
  `npx github:darellchua2/civiltekk-opencode-claude-skills add <name>`. Soft deps
  degrade with a note: `ticket-creation-skill` (only for new-work tickets,
  Step 3), `architecture-review-subagent` / `uiux-reviewer-subagent` /
  `requirements-specialist-subagent` (Step 7 skip-with-note rule).
- **Ticket order = execution order** (sequential; never parallel worktrees).
  Before starting a ticket, if its body contains `blocked-by: <ref>` naming a
  ticket that is not yet merged, skip it and report why (no JIRA link
  traversal in v1).

## Steps 2-10 — per ticket (in order)

2. **Sync + branch**: `git fetch origin <base>`. **Merged-ticket skip**:
   `gh pr list --state merged --head feat/<KEY>` non-empty → the ticket is
   already merged; report the skip with a note and advance to the next
   ticket. Otherwise cut `git branch feat/<KEY> origin/<base>`. If the
   branch or worktree already
   exists (mid-pipeline failure leftovers), report state and ask:
   prune / resume / refuse — never clobber silently.
3. **Ticket fetch/create**: existing ref → fetch its description
   (`gh issue view` / JIRA). JIRA access follows the **MCP Availability
   Guard** (policy: `jira-git-integration-skill` §MCP Availability Guard):
   `atlassian_*` tools present → use them; absent → REST fallback
   via API token; headless → degrade with a clear report. New work → create the
   ticket first via `ticket-creation-skill` (`/create-ticket`), then
   continue.
4. **Worktree**: locate the **main** checkout via
   `git worktree list --porcelain | sed -n 's/^worktree //p' | head -1`
   (NOT `$(git rev-parse --show-toplevel)` — that nests when invoked from a
   worktree). Create `git worktree add <root>/<KEY> feat/<KEY>` — **always,
   even when the ticket is in this repo**. `<root>` is
   `$WORKTREE_PIPELINE_ROOT` when set, else `<main-repo>/../worktrees/`.
   Pre-flight `git worktree list` for stale `<KEY>` entries.
   **CodeGraph index (conditional)**: iff `<main-repo>/.codegraph` exists,
   run `git -C <root>/<KEY> check-ignore -q .codegraph/` first — exit 0
   (ignored on the ticket branch) → run `npx @colbymchenry/codegraph init -i`
   **inside the new worktree** (before Step 5; 5–60s, index gitignored);
   exit 1 → skip init entirely with a one-line note (".codegraph/ not
   ignored in target repo — skipping init to keep commits clean") and
   continue on the rg/grep fallback (any other `check-ignore` exit →
   treat as the same soft-skip path); CLI absent or init failure → one-line
   soft-skip note and continue on rg/grep. No `.codegraph/` in the main
   checkout → skip silently. Never write ignore entries (tracked
   `.gitignore` edits stage into per-phase commits; per-worktree
   `info/exclude` is not honored by linked worktrees). Never symlink the
   main checkout's `.codegraph/` into the worktree — the index reflects the
   main checkout's branch state and paths (sharing undocumented).
5. **Re-validate**: cross-check the ticket description once more against the
   latest `origin/<base>` content **in the worktree**; if stale, update the
   ticket and note deltas before proceeding.
6. **PLAN authoring** (self-contained — this skill owns it; see §PLAN
   Authoring): adopt/generate the ticket-scoped PLAN in the worktree, run the
   atomicity self-check, commit and push it on `feat/<KEY>`.
7. **Plan review (§Adaptive Review)**: you triage before delegating — from
   the ticket, the PLAN's Dependency & Consumer Map, and the touched paths,
   select reviewers, then issue **parallel Task calls** for the selected
   ones only (a selected reviewer absent from this session's agent list →
   skip it with a note; per-skill installs may not carry every reviewer):
   - `architecture-review-subagent` iff the Consumer Map has **cross-module
     nodes** (a consumer beyond the node itself).
   - `uiux-reviewer-subagent` iff **frontend signal** (tsx/jsx/vue/svelte/css
     files, components/pages/app paths, UI keywords in the diff).
   No proactive requirements review — requirements coverage is
   reviewer-owned: each selected reviewer verifies the PLAN against the
   ticket's stated requirements and emits **Requirements Gaps** for
   anything missing or ambiguous (never a silent assumption). A thin-map
   backend ticket may select zero reviewers — Step 9 code review
   (unconditional) backstops.
   **Requirements Gaps relay**: any reviewer (here or Step 9) returning a
   non-empty `Requirements Gaps` array → relay it to
   `requirements-specialist-subagent` **Mode R** and apply the answers to
   the PLAN before proceeding (max 2 relay rounds — agent contract bound;
   agent absent → surface the gaps to the user directly and proceed on
   their answers).
   Triage assumptions (stated, not hidden): a thin Consumer Map may skip
   architecture review, so author the map honestly at Step 6.
   `coverage-subagent` is NOT part of plan review — it is a coverage
   *reporting* agent, so reviewing a pre-implementation PLAN is a stage
   mismatch (nothing measurable exists yet). Apply findings to the
   PLAN; re-review only when findings were structural. Zero selected
   reviewers → skip delegation entirely.
8. **Execute**: run `/run-plan PLANS/PLAN-${KEY}.md`
   (`plan-execution-skill` --gate) **inside the worktree** — always pass the
   explicit PLAN path, never rely on branch-name auto-detect. Plan review
   happened upstream in Step 7 — the executor must not re-review. Gate
   sequence, tier selection (light default per phase; full per
   `verification-loop-skill` §Tiered gating), pass semantics, and memo
   format come from `verification-loop-skill` §The gate contract (this
   skill defines none of them); the executor commits + pushes per phase and
   writes the gate memo, and the run's last gate — the **ticket exit
   gate** — is full.
9. **Code review**: `code-review-subagent` has `edit: deny` (bash is allowlisted to read-only git, and its cwd is the session checkout, not the worktree) — **you compute
   the diff** (`git diff origin/<base>...feat/<KEY>` and `--stat`) and embed
   it (file list + hunks) in the Task prompt. Fix findings: severity ≥
   Major mandatory; Minor by judgment. **Re-gate after review fixes**: fix
   commits land after the exit gate, so before pushing a fix commit re-run
   the **full** gate once on the fixed tree and append its `tier=full` memo
   line — the final pushed SHA must carry a green `tier=full` memo (a
   review-fix push without one breaks Step 10's citation). Relay any
   non-empty `Requirements Gaps` array per Step 7's relay rule before fixing.
   **LEARNINGS capture is yours, not the reviewer's**: reviewers have no
   write access — they return LEARNINGS candidates as report content (a
   `LEARNINGS candidates:` block). For each candidate, write
   `LEARNINGS/<category>/<slug>.md` in the worktree (skip if the file
   already exists; suffix `-2` on a genuine distinct-entry collision),
   append its `_index.md` entry, and commit them with the review-fix
   commit — or a dedicated `chore(learnings)` commit when the review
   found nothing to fix. Any PLAN re-ticks from review fixes (gate-memo
   append, Done-line updates) fold into that same review-fix/learnings
   commit — never their own `docs(plan)` commit.
   **Bounded loop: max 2
   fix-and-re-review iterations** — exhaustion → halt per §Failure Policy.
10. **PR + cleanup**: `pr-workflow-subagent` creates the PR **target
    `<base>`** — the Task prompt MUST state gates are green by citing the
    final `GATE <short-sha> tier=full` memo line for the pushed SHA from the PLAN
    trace block (that citation IS the pipeline-mode gate memo per
    `verification-loop-skill` §Gate memo; a `tier=light` line is phase
     evidence and never satisfies this citation) and instruct it to skip its
    steps 2 / 2.5 / 3 / 4: run-plan verified the gate per phase, docstrings
    were filled before the gate, coverage badges
    stay out (README must not change after Step 9 review — CI carries the
    coverage signal), and the PLAN is ticked and committed; the CI gate
    below is the merge decision. The Task
    prompt MUST instruct it to include `Closes <TICKET_ID>`
    in the PR body (keep the `#` — `Closes #366`, not `Closes 366`; must
    predate the merge).
    **CI gate**: `timeout 1800 gh pr checks <num> --watch` (GNU coreutils;
    macOS: `gtimeout`) — 30-minute timeout; merge when green with
    `gh pr merge <num> --squash` — the `feat/<KEY>` head is short-lived, so
    squash is the classifier verdict (`pr-merge-workflow-skill` Phase 1
    head-class rule).
    Zero configured checks (exits non-zero with "no checks reported") → merge
    directly with a "no CI configured" note. JIRA tickets: after merge,
    ensure exactly one `jira-status-updater` transition to Done —
    pr-workflow-subagent's Task ends at PR creation, so this is yours:
    check the ticket status first, transition only if still open. Then
    `git worktree remove <root>/<KEY>`,
    delete the remote branch, and `git fetch` in the main checkout
    (**fetch-only** — never `pull` in the user's main worktree; uncommitted
    state may conflict). Advance to the next ticket.

## PLAN Authoring (Step 6 detail)

All commands run **in the worktree** (`worktrees/<KEY>`), on `feat/<KEY>`.
`$TICKET_ID` is the normalized ref (`#123` or `PROJ-123`); `$KEY` is its
alphanumeric form (`123` or `PROJ-123`).

### 6a. Adopt or rename an existing PLAN draft

Before generating from scratch, check whether an existing draft should be
adopted (avoids duplicate plans, preserves git history). Canonical filename:
`PLANS/PLAN-${KEY}.md` — Step 8 invokes this exact path. Drafts named
`PLAN-GIT-<issue-number>.md` or other variants are `git mv`'d to the
canonical form on adoption.

1. **Search candidates in `PLANS/` only** (never repo root — a root
   `PLAN.md` may belong to unrelated active work):
   `ls PLANS/PLAN.md PLANS/PLAN-DRAFT-*.md PLANS/TODO-*.md 2>/dev/null`
   Also prior-iteration canonical names (`PLANS/PLAN-GIT-*.md` etc.).
2. **Already adopted?** Canonical name exists → skip to 6d.
3. **Single candidate → auto-adopt** via `git mv` (preserves history):
   `git mv "PLANS/PLAN-DRAFT-<slug>.md" "PLANS/PLAN-${KEY}.md"`.
   Before auto-adopting a generic `PLANS/PLAN.md`, verify its `**Issue:**`
   header matches this ticket; mismatch → non-candidate + warn.
4. **Multiple candidates → prompt the user** which to adopt, via the `question`
   tool with this payload shape (instantiate options from the actual drafts —
   best three matches plus the decline option, keeping within the 2-4 option
   cap; keep payloads small per deployed `AGENTS.md` §Question Tool Payloads):

   ```json
   {
     "questions": [
       {
         "question": "Multiple PLAN drafts match this ticket. Which should be adopted as PLANS/PLAN-<KEY>.md?",
         "header": "PLAN draft adoption",
         "multiple": false,
         "options": [
           {
             "label": "Adopt <draft-name>",
             "description": "git mv the draft to the canonical PLANS/PLAN-<KEY>.md form and continue with it."
           },
           {
             "label": "Keep drafts in place",
             "description": "Adopt nothing now; generate a fresh PLAN from the ticket and leave the drafts for manual cleanup."
           }
         ]
       }
     ]
   }
   ```
5. **Non-adopted candidates → left in place with a warning** (user cleans up).
6. **No candidate / no `PLANS/` dir** → `mkdir -p PLANS`, continue to 6b.

> Note: 6a searches relative to the worktree cwd — drafts must be
> **committed to `<base>`** to be adoptable here; uncommitted main-worktree
> drafts are invisible by design.

### 6b. BRD/SRS draft linking

Document-ladder order: **BRD first, then SRS**. For each:

```bash
ls docs/brd/BRD-draft-*.md 2>/dev/null   # then docs/srs/SRS-draft-*.md
```

If drafts found, ask the user (via `question` — harness binding, §Portability contract: OpenCode `question` · Claude Code `AskUserQuestion` · Other/none — plain-reply ask, skip linking if unanswered) whether to link one, using this
payload shape (instantiate `<BRD|SRS>`, `<key>`, and the draft name per ladder
order):

```json
{
  "questions": [
    {
      "question": "Found <BRD|SRS> draft(s). Link one to this ticket's PLAN?",
      "header": "Draft linking",
      "multiple": false,
      "options": [
        {
          "label": "Link <draft-name>",
          "description": "Rename the draft to the <BRD|SRS>-<key> form, repoint its **PLAN**: header, and record the path for 6c header injection."
        },
        {
          "label": "Skip — no link",
          "description": "Leave drafts in place; continue with an empty doc path (backward-compatible)."
        }
      ]
    }
  ]
}
```

On link:
- Rename: `git mv docs/brd/BRD-draft-{slug}.md docs/brd/BRD-{key}.md`
  (plain `mv` + `git add` if untracked); same for SRS.
- Update the doc header `**PLAN**:` placeholder to `PLANS/PLAN-{key}.md`.
- Record `BRD_PATH` / `SRS_PATH` for header injection in 6c.
- Declined/absent → empty path (skip — backward-compatible).

### 6c. Generate the PLAN

Write `PLANS/PLAN-${KEY}.md` using this template:

```markdown
# PLAN: <title>

**Branch**: feat/<KEY>
**Issue**: <ticket URL>          ← + `**BRD**: <path>` / `**SRS**: <path>` lines when linked
**Base**: <base>

## Acceptance Criteria
- [ ] <checkable criteria from the ticket>

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Use `codegraph_callers` (code) or `tofu graph` + grep (IaC)._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `path/to/file`      | —                         | caller-A, module-B              | low/med/high |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Canonical step format
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: <name>
- [ ] **1.1** <atomic action> (per canonical format)
…

## Technical Notes
<from ticket>

## Dependencies
<external dependencies / blocked-by tickets>

## Risks & Mitigation
<risks + mitigations>
```

**Step authoring rules** (enforced by 6d):
- **Atomic**: one reversible concern per step; two concerns → split.
- **Rationale mandatory**: every step has **Why**; a step without it is malformed.
- **Completion signal**: objective **Done when**, never subjective "done".
- **Consumers explicit**: blast radius visible to reviewers; "none" if isolated.

### 6d. Atomicity self-check (commit gate)

1. Read the PLAN back from disk.
2. For every `- [ ] **N.M**` / `- [x] **N.M**` step, confirm the three
   rationale lines follow it: `— **Why:**`, `— **Done when:**`,
   `— **Consumers affected:**`.
3. **Any step missing any field → do NOT commit.** Surface malformed steps
   (line number + text), fix, re-check. Gate must pass with zero malformed
   steps.
4. Also verify: Dependency & Consumer Map section exists; phase ordering
   matches the map's constraints; every Acceptance Criterion is addressed
   by ≥1 implementation step (catches silently forgotten requirements at
   authoring time — belt for thin-map tickets that select zero reviewers).

### 6e. Commit and push the PLAN

```bash
git add "PLANS/PLAN-${KEY}.md" docs/brd/ docs/srs/ 2>/dev/null
git commit -m "docs(plan): add PLAN-${KEY}.md for ${TICKET_ID}"
git push -u origin "feat/${KEY}"
```

`/run-plan` commits implementation phases, not an untracked PLAN — an
untracked PLAN file would be lost on worktree removal, which is why this
step pushes it.

> Skipped by design in pipeline context: initial ticket progress comment
> (execution follows immediately; ticket updates flow through Step 5
> re-validation and pr-workflow) and the branch-workflow setup signal
> (pipeline runs assume an established repo; run `/create-ticket` standalone
> if you want that signal).

## Failure Policy

- **Halt triggers**: the executor's `[goal:blocked]` terminal marker
  (Step 8), review-fix exhaustion after 2 iterations (Step 9), CI red —
  any concluded failing check, or still pending at the 30-minute timeout
  (Step 10), or PR creation failure.
- **Keep the scene**: the failed ticket's worktree + `feat/<KEY>` branch
  stay in place for inspection (Step 2's prune/resume/refuse ask handles
  clean reruns).
- **Abort remaining tickets** — no override; per-ticket status report.
- **Return Contract semantics**: `partial` for any halt after a ticket has
  started; `failed` is reserved for pre-execution failures (invalid base
  branch, zero tickets resolved, missing hard dependency from Step 1's
  preflight).

## Guarantees

- Sequential execution across tickets; one worktree live per ticket.
- Every ticket re-validated against latest `origin/<base>` before execution.
- The main working tree is never checked out on a feat branch.
- Every PLAN passes the atomicity self-check before commit.
- No standalone tick/progress commits at any step — PLAN updates ride the
  phase's atomic commit (Step 8) or fold into the review-fix commit
  (Step 9); the squash merge keeps PLAN noise out of release notes.
- Delegation is hub-and-spoke from the primary session (build agent allows
  `task: {"*": allow}`); delegates whose cwd is the session checkout (not the
  worktree) receive precomputed diffs.
- Each worktree gets a CodeGraph index when the main checkout has one
  (skipped with a note when the index would be unignored, the CLI is
  absent, or init fails).

## Return Contract

**Status:** success | partial | failed
**Output:** per ticket — PR URL + merge SHA; one line each
**Summary:** 2-3 sentences max
**Issues:** blockers, skipped (`blocked-by:`) tickets, or "None"
