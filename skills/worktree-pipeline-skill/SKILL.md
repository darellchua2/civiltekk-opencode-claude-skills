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
  `^(#\d+|[\w.-]+/[\w.-]+#\d+|[A-Z][A-Z0-9]+-\d+|[\w.-]+/[A-Z][A-Z0-9]+-\d+)$`
  **and is not purely numeric**. Full first-token taxonomy, in test order:
  `--`flags → ticket forms (`#N` GitHub · `owner/repo#N` cross-repo GitHub ·
  bare numeric `N` (auto-`#N`) · `KEY` JIRA · `repo/KEY` cross-repo JIRA) →
  base-branch fallthrough. Every accepted token shape is listed here — a
  variant that matches none of them is the base-branch, never silently
  dropped.
- Bare numerics (`351`) auto-normalize to GitHub issue refs (`#351`).
- **`repo/KEY` cross-repo refs** (`canvastekk-workflow-engine/DA-2952`) name
  a foreign repo: resolve it to the sibling checkout `../<repo>` relative to
  the main checkout; it must exist and be a git repo — missing → one batched
  user ask for the local path, still unresolved → abort with a clear error.
  Bare `KEY`/`#N`/`owner/repo#N` behave exactly as before (session repo or
  named GitHub repo). Everything repo-scoped downstream — base branch, its
  validation, the worktree root, and the gh context — resolves **per
  ticket's repo** (Steps 2–4 run `git -C <repo>` and `gh ... -R
  <owner/name>` for foreign repos; the session repo is unchanged).
- Zero ticket refs → print usage and stop.
- The base-branch sets **both** where feat branches are cut from AND the PR
  target. Default (omitted): repo default branch via
  `git symbolic-ref --short refs/remotes/origin/HEAD` (yields
  `origin/<base>`; strip the prefix; fallback `main`).
- **Validate the base** after resolving it (per repo for `repo/KEY`
  tickets): `git ls-remote --exit-code --heads origin <base>`; non-zero exit
  → abort with a clear error naming the attempted base (fail-fast — never
  reach Step 2 with a typo'd base).
- **`--dry-run`**: print the resolved base (per repo), ticket execution
  order, per-ticket predictions — merged / held-on-`blocked-by:` /
  held-on-open-PR-overlap — which PRs will get background merge watchers,
  and the would-be `feat/<KEY>` branch + worktree names (per repo), then
  stop before Step 2. Read-only: no writes, no branch/worktree/remote
  mutations.
- **Dependency preflight (per-skill installs)**: hard deps — skill
  `plan-execution-skill` --gate (Step 8), agents `code-review-subagent`
  (Step 9) and `pr-workflow-subagent` (Step 10). Any missing → abort
  (`failed`) with the install hint
  `npx github:darellchua2/civiltekk-opencode-claude-skills add <name>`. Soft deps
  degrade with a note: `ticket-creation-skill` (only for new-work tickets,
  Step 3), `architecture-review-subagent` / `uiux-reviewer-subagent` /
  `requirements-specialist-subagent` (Step 7 skip-with-note rule).
- **Execution model (pipelined)**: ticket order = authoring order, but only
  **one implementation runs at a time**. The next ticket's implementation
  starts once the active ticket has **created its PR (Step 10a)** — not once
  it merges — AND this ticket's own blockers (below) have merged; unblocked
  tickets never wait on CI. A held ticket (blocked-by, 6f, or 10a overlap)
  **releases the implementation lane** — the next implementable ticket
  starts immediately. Each PR ships with a **background merge
  watcher** (Step 10b), so any number of PRs may be awaiting merge
  concurrently while the next implementation proceeds.
- **`blocked-by:` hold, not skip**: if a ticket's body contains
  `blocked-by: <ref>` naming a ticket that is not yet merged (an open PR
  counts as unmerged), **hold** it — report as held, keep it in run order.
  Evaluation point: the Step 3 body fetch (dry-run predicts it earlier); a
  blocked-by hold parks with whatever state exists — typically none, before
  branch/worktree/PLAN. **Auto-resume** when the blocker's merge
  notification arrives: re-enter at the first unexecuted step — rebase
  `feat/<KEY>` onto the updated base **only if the branch already exists**
  (push `--force-with-lease` after a resume rebase). Contrast: 6f/10a
  overlap holds park AFTER PLAN authoring, so their resume continues at
  Step 7 / 10a. Tickets still held when nothing else is runnable are
  reported deferred at run end, not failed. (No JIRA link traversal in v1 —
  body text only.)

## Steps 2-10 — per ticket (in order)

2. **Sync + branch** (all git/gh run in the ticket's repo — `git -C <repo>`
   and `gh ... -R <owner/name>` for foreign repos; session repo unchanged):
   `git fetch origin <base>`. **Merged-ticket check**:
   `gh pr list --state merged --head feat/<KEY>` non-empty → the ticket is
   already merged; report the skip with a note and advance to the next
   ticket. Otherwise cut `git branch feat/<KEY> origin/<base>`. If the
   branch or worktree already exists (mid-pipeline failure leftovers OR a
   held ticket resuming), report state and ask: prune / resume / refuse —
   never clobber silently; **resume** is the held path (Step 1): rebase
   `feat/<KEY>` onto the updated `origin/<base>` (push `--force-with-lease`
   after the rebase) and re-enter at the first unexecuted step.
3. **Ticket fetch/create**: existing ref → fetch its description (`gh issue
   view [-R <owner/name>]` / JIRA). JIRA access follows the **MCP Availability
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
   `$WORKTREE_PIPELINE_ROOT` when set (applies to ALL tickets — foreign
   repos included, a documented asymmetry), else
   `<ticket-repo>/../worktrees/` — derived from the ticket's repo, so
   `repo/KEY` tickets get a worktree root beside their own checkout.
   Pre-flight `git worktree list` for stale `<KEY>` entries.
   **CodeGraph index (conditional)**: iff the ticket repo's checkout has
   `.codegraph`, run `git -C <root>/<KEY> check-ignore -q .codegraph/` first — exit 0
   (ignored on the ticket branch) → run `npx @colbymchenry/codegraph init -i`
   **inside the new worktree** (before Step 5; 5–60s, index gitignored);
   exit 1 → skip init entirely with a one-line note (".codegraph/ not
   ignored in target repo — skipping init to keep commits clean") and
   continue on the rg/grep fallback (any other `check-ignore` exit →
   treat as the same soft-skip path); CLI absent or init failure → one-line
   soft-skip note and continue on rg/grep. No `.codegraph/` in the ticket
   repo's checkout → skip silently. Never write ignore entries (tracked
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
10. **PR + merge watching** — split: 10a foreground, 10b background.
    **10a — PR creation (foreground).** First the **authoritative overlap
    re-check** (the §6f early leg is advisory only): `comm -12` of
    `git -C <ticket-repo> diff --name-only origin/<base>...feat/<KEY> | sort`
    against each earlier
    in-run ticket's still-open PR diff (per repo, likewise sorted) —
    non-empty → hold ticket
    N pre-PR (worktree kept); auto-resume on that PR's merge notification:
    rebase, re-run the full gate (the SHA changes), push
    `--force-with-lease`, then create the PR. A PR
    that would show merge conflicts because an earlier in-run PR merged
    inside the 6e→10a window (stale base) classifies the same way —
    overlap-hold, never a failed ticket. Clear → `pr-workflow-subagent`
    creates the PR **target
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
    predate the merge). On PR creation the orchestrator **advances to the
    next implementable ticket** — it does NOT wait for CI (Step 1 execution
    model).
    **10b — merge watcher (background).** Spawn a background shell (harness
    binding below) that: `timeout 1800 gh pr checks -R <owner/name> <num>
    --watch` (GNU
    coreutils; macOS: `gtimeout`) — 30-minute timeout; merge only when green
    with `gh pr merge -R <owner/name> <num> --squash` — the `feat/<KEY>` head is
    short-lived, so squash is the classifier verdict
    (`pr-merge-workflow-skill` Phase 1 head-class rule); capture the merge
    SHA via `gh pr view -R <owner/name> <num> --json mergeCommit`; report the outcome to the
    main session (merge SHA on success; the failing check names on red).
    The `-R <owner/name>` flags are mandatory — the watcher runs
    unattended, so prose scoping rules elsewhere never reach it (session
    repo ≠ ticket repo for `repo/KEY` tickets).
    Zero configured checks (exits non-zero with "no checks reported") →
    merge directly with a "no CI configured" note. Red or
    pending-at-timeout → report and stop. The watcher performs **gh-side
    operations only** — watch → merge → SHA capture → report; it performs
    **no local git mutations** (worktree/ref mutations are the main
    session's, below, keeping them serialized away from concurrent
    `git worktree add` calls).
    **Notification handling** — main session, at step/ticket boundaries
    only (never mid-Task: a Step 8 run-plan or Step 9 review may run many
    minutes), in arrival order, each notification exactly once. On a merge
    notification: report the merge SHA, then run the cleanup the watcher
    must not — `git -C <ticket-repo> worktree remove <root>/<KEY>`, delete
    the remote branch, and `git -C <ticket-repo> fetch` in the ticket
    repo's main checkout (**fetch-only** — never
    `pull` in the user's main worktree; uncommitted state may conflict);
    JIRA tickets: ensure exactly one `jira-status-updater` transition to
    Done — check the ticket status first, transition only if still open. On
    a red notification: the fix is queued for the next boundary (immediate
    if idle), bounded at **2 fix-and-re-watch rounds per ticket**; red-fix
    pushes ride Step 9's re-gate rule — run the **full** gate once on the
    fixed tree and append its green `tier=full` memo for the new final SHA
    before re-watch (the 10a citation names the final pushed SHA).
    Harness binding (§Portability contract) for the background mechanism:
    - OpenCode: background shell (`background: true`) with completion
      notification.
    - Claude Code: background Bash (run_in_background).
    - Other/none: foreground `timeout 1800 gh pr checks <num> --watch`
      before advancing (the pre-#560 behavior).
    Requires bash (git-bash/WSL on Windows).

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

### 6f. Overlap hold gate (between 6e and Step 7)

**Early leg (advisory)**: while any earlier in-run ticket still has an open
PR, intersect that PR's branch diff with THIS ticket's PLAN **Dependency &
Consumer Map touch-set** (materialize the map's first-column file paths,
normalize, `sort` — `comm -12` needs sorted input; the map 6d just
validated — at this boundary the branch diff contains only the PLAN commit,
so a `comm -12` on branch diffs would be vacuous here). Non-empty
intersection → **hold** ticket N: keep the worktree, report held, and
auto-resume when that PR's merge notification arrives — rebase `feat/<KEY>`
onto the updated base (push `--force-with-lease` after the rebase) and
continue at Step 7, re-running the **full** gate iff the rebase touched
implementation commits (at this boundary the tree is PLAN-only — Step 8's
exit gate re-gates the real tree). Advisory default: an empty or missing
Consumer Map skips the early leg — worst case is a late hold at the 10a
authoritative check, never a wrong merge.

## Failure Policy

- **Ticket-failure triggers** (per ticket — nothing aborts the remaining
  run): the executor's `[goal:blocked]` terminal marker on the active
  ticket (Step 8), review-fix exhaustion after 2 iterations (Step 9), PR
  creation failure (Step 10a), or watcher exhaustion (Step 10b) — a
  pending-at-timeout watch fails the ticket immediately (pending CI has no
  concluded failure to fix; keep the worktree, report under Issues), while
  a concluded-red watch enters the 2 fix-and-re-watch rounds and fails the
  ticket once exhausted. CI red is
  **not** a run-level abort: a failed watcher fails that ticket
  only.
- **Keep the scene**: the failed ticket's worktree + `feat/<KEY>` branch
  stay in place for inspection (Step 2's prune/resume/refuse ask handles
  clean reruns); a red watcher never cleans up.
- **Tickets in flight when a ticket fails**: independent tickets proceed;
  dependent (held) tickets stay held and are reported **deferred** at run
  end. A `[goal:blocked]` on the active ticket pauses the implementation
  lane — background watchers keep running and notifications keep draining
  at boundaries.
- **Final report waits** for outstanding watchers (each bounded by the
  30-minute cap plus up to 2 red-fix rounds) before the Return Contract.
- **Return Contract semantics**: `partial` for any halt after a ticket has
  started OR any failed-red ticket; `success` allows deferred-held tickets
  (listed under Issues); `failed` is reserved for pre-execution failures
  (invalid base branch, zero tickets resolved, missing hard dependency from
  Step 1's preflight, unresolvable foreign repo).

## Guarantees

- One active implementation at a time; any number of background merge
  watchers. A ticket's worktree lives until its PR resolves — merge →
  cleaned up by the main session's notification handler; red → kept for
  fixes. Every merge is green-only; the watcher performs no local git
  mutations.
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

**Status:** success | partial | failed — deferred-held tickets alone do not
downgrade to `partial`; any failed-red ticket does
**Output:** per ticket — PR URL + merge SHA (watcher-reported) + final state
(merged / failed-red / deferred-held); one line each
**Summary:** 2-3 sentences max
**Issues:** blockers, held/deferred tickets, red-watcher outcomes, or "None"
