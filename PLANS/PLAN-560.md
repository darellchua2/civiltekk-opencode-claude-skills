# PLAN: worktree-pipeline — async merge wait + cross-repo chaining

**Branch**: feat/560
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/560
**Base**: main

## Acceptance Criteria
- [ ] Multi-ticket run: independent ticket #2's implementation starts while ticket #1's PR CI runs
- [ ] Green-only merge; red PR keeps scene, reports failing checks, merges after bounded fix-and-re-watch
- [ ] CI red no longer aborts remaining tickets; only `[goal:blocked]` on the active ticket halts
- [ ] `blocked-by:` tickets hold and auto-resume on the blocker's merge notification
- [ ] Overlap with an open in-run PR holds the later ticket until merge
- [ ] `repo/KEY` refs work in sibling repos; bare `KEY` unchanged; `--dry-run` prints hold/async predictions
- [ ] JIRA Done transition by main session post-notification; watcher script credential-free
- [ ] Portability guard + skill-isolation bats tests pass

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Use `codegraph_callers` (code) or `tofu graph` + grep (IaC)._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/worktree-pipeline-skill/SKILL.md` | — | OpenCode agent runtime (executes the workflow), `tests/test_tiered_gating.bats` tier3 phrase assertions (Step 8/9/10 wording), `tests/test_portability.bats` (background-mention fallback guard), `tests/test_skill_isolation.bats` (structural), `README.md` command table (prose mention), `agents/pr-workflow-subagent.md` (pipeline-mode contract references Step 10 semantics) | medium |

_Prose references confirmed unchanged-accurate under this rework (no edits planned; provenance: `grep -rn "worktree-pipeline" skills/*/SKILL.md` → the three files below, each checked against the amended flow): `skills/verification-loop-skill/SKILL.md`, `skills/jira-status-updater-skill/SKILL.md`, `skills/plan-execution-skill/SKILL.md` (review NOTE #9)._

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Step 1 — execution model + cross-repo parsing
- [x] **1.1** Replace the "Ticket order = execution order (sequential; never parallel worktrees)" bullet with the pipelining execution model: one active implementation at a time; a ticket's implementation starts once the previous implementation has created its PR (Step 10a) AND the ticket's own blockers have merged; unblocked tickets never wait on CI; N background merge watchers may run concurrently.
    — **Why:** This is the core stall fix — CI wait must leave the main loop so the next implementable ticket proceeds (AC #1). "Created its PR (10a)" is the deliberate advance trigger: reading it as merge would re-serialize the run (Requirements answer #2).
    — **Done when:** The bullet states one-active-implementation, advance-at-10a-PR-creation, and concurrent-watchers rules with no "never parallel worktrees" residue (`grep -c "never parallel worktrees"` → 0).
    — **Consumers affected:** OpenCode agent runtime executing multi-ticket runs; Failure Policy and Guarantees sections updated in Phase 5 to match.
    — **Done:** Execution-model bullet landed (advance at 10a PR creation, one active implementation, N concurrent watchers); residue grep → 0; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **1.2** Rewrite the `blocked-by:` rule from permanent skip to hold-and-resume: held tickets are reported as held; when the blocker's merge notification arrives mid-run, the ticket auto-resumes (rebase `feat/<KEY>` onto the updated base, continue at Step 7); tickets still held at run end are reported as deferred, not failed.
    — **Why:** A permanent skip forces the user to re-invoke the pipeline after every merge in a dependent chain (AC #4).
    — **Done when:** The Step 1 blocked-by bullet says hold + auto-resume + deferred-at-end, with the resume mechanics named; the word "skip" no longer describes the blocked-by path.
    — **Consumers affected:** Step 2 (resume path) and Failure Policy (deferral semantics) must stay consistent.
    — **Done:** blocked-by bullet rewritten (hold / open-PR-counts-as-unmerged / auto-resume via rebase to Step 7 / deferred-at-end); files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **1.3** Extend the ticket-ref grammar and document the full Step-1 first-token taxonomy in one place: `--`flags, base-branch fallback test, bare numerics, `#N`, `owner/repo#N`, `[A-Z][A-Z0-9]+-\d+` (JIRA), and the new `repo/KEY` JIRA form matching `[\w.-]+/[A-Z][A-Z0-9]+-\d+`; bare `KEY` and all existing forms behave exactly as before.
    — **Why:** Cross-repo chaining needs the ticket ref to name its repo; an explicit taxonomy with a deterministic fallthrough prevents classifier drift on variants (LEARNINGS: exact-match branch taxonomy fallthrough).
    — **Done when:** The regex in Step 1 includes the `repo/KEY` alternative and the bullet enumerates every accepted token shape; existing forms are byte-identical in behavior.
    — **Consumers affected:** `--dry-run` predictions (1.5) and Steps 2–4 repo context (Phase 2) consume the resolved repo.
    — **Done:** Regex gains `[\w.-]+/[A-Z][A-Z0-9]+-\d+`; taxonomy enumerated in test order on the base-branch bullet; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **1.4** Add sibling-checkout resolution for `repo/KEY`: the named repo resolves to `../<repo>` relative to the main checkout, must exist and be a git repo (else one batched user ask, then abort if unresolved); base branch, `ls-remote` validation, worktree root, and gh context are resolved per repo.
    — **Why:** Without a local checkout the pipeline cannot cut branches or run gh/JIRA-aware steps for the foreign repo (AC #6).
    — **Done when:** Step 1 states the `../<repo>` resolution rule, the existence check, the ask-once-then-abort fallback, and per-repo base validation.
    — **Consumers affected:** Step 2 merged-check/branch-cut and Step 4 worktree root (Phase 2) thread this resolved repo path.
    — **Done:** repo/KEY resolution bullet added (sibling checkout, ask-once-then-abort, per-repo base/gh/worktree scoping); base-validation bullet gains per-repo note; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
- [x] **1.5** Extend the `--dry-run` block to print per-ticket hold/async predictions: which tickets will hold on `blocked-by:`, which will hold on open-PR overlap, which PRs will get background watchers, and the would-be branch/worktree names per repo.
    — **Why:** A run whose control flow changed must remain fully predictable before any mutation (AC #6).
    — **Done when:** The dry-run bullet lists hold predictions and watcher plans among its outputs; still read-only (no writes/mutations wording preserved).
    — **Consumers affected:** none (read-only path).
    — **Done:** dry-run bullet prints merged/held-on-blocked-by/held-on-overlap predictions + watcher plans + per-repo branch/worktree names; files: skills/worktree-pipeline-skill/SKILL.md; fixes: none

### Phase 2: Steps 2–4 — per-repo context threading
- [ ] **2.1** Thread the ticket's resolved repo through Steps 2–3: the merged-PR check, branch cut, and ticket fetch run against the ticket's repo (`git -C <repo>`, `gh ... -R <owner/name>` for foreign repos; session repo unchanged); the held-resume path rides the existing prune/resume/refuse ask with resume defined as rebase onto the updated base.
    — **Why:** Cross-repo tickets must hit their own repo's git remote and issue tracker, and a resumed held ticket must not clobber prior work (AC #4, #6).
    — **Done when:** Steps 2 and 3 name the repo-scoped commands; the resume semantics of 1.2 are operationalized in Step 2's leftover-ask rule.
    — **Consumers affected:** Step 4 worktree creation consumes the same resolved repo and branch.
- [ ] **2.2** Make the Step 4 worktree root per-repo: `<ticket-repo>/../worktrees/` (or `$WORKTREE_PIPELINE_ROOT` for the session repo, unchanged); the CodeGraph conditional is evaluated against the ticket's repo checkout.
    — **Why:** A foreign repo's worktree must branch from that repo's storage layout, not the session repo's (AC #6).
    — **Done when:** Step 4 derives `<root>` from the ticket's repo; existing `$WORKTREE_PIPELINE_ROOT` and CodeGraph rules otherwise unchanged.
    — **Consumers affected:** Step 10 cleanup (Phase 4) removes from the same per-repo root.

### Phase 3: Step 6e→7 boundary — overlap guard
- [ ] **3.1** Insert the overlap guard's early leg between the PLAN push (6e) and plan review (Step 7): while any earlier in-run ticket still has an open PR, intersect that PR's branch diff with THIS ticket's PLAN Dependency & Consumer Map touch-set (the map 6d just validated); a non-empty intersection holds ticket N — worktree kept, auto-resume on that PR's merge notification (rebase, re-run the full gate since the SHA changes, continue at Step 7). Advisory default: an empty or missing Consumer Map skips the early leg — worst case is a late hold at the 10a authoritative check (new step 4.2), never a wrong merge.
    — **Why:** Two open PRs touching the same files would conflict after the first squash-merges; holding preserves mergeability without serializing independent work (AC #5). The branch diff at 6e→7 contains only the PLAN doc commit, so the authoritative `comm -12` is vacuous here — the freshly-authored Consumer-Map touch-set is the only non-vacuous early signal (review BLOCK finding; Requirements answer #1).
    — **Done when:** The 6e→7 guard bullet exists with the Consumer-Map intersection, the empty-map advisory fallback, and the hold/resume mechanics (rebase + full re-gate) spelled out; no `comm -12` at this boundary.
    — **Consumers affected:** Step 7 plan review must tolerate a deferred start; the 10a authoritative leg (4.2) and Failure Policy hold semantics (Phase 5) complete the guard.

### Phase 4: Step 10 — 10a/10b split + background watcher
- [ ] **4.1** Split Step 10 into 10a (PR creation) and 10b (merge watching), preserving verbatim in 10a: the `GATE <short-sha> tier=full` citation requirement, the "never satisfies this citation" rule, the `Closes <TICKET_ID>` body rule, and the skip-steps instruction to `pr-workflow-subagent`.
    — **Why:** The tier3 gating assertions grep these exact phrases — their preservation keeps `tests/test_tiered_gating.bats` green while the step is restructured (AC #8). Two further asserted phrases live in Step 7's prose — `Step 9 code review` and `(unconditional) backstops` (asserted at `tests/test_tiered_gating.bats:162-164`), inside the region Phase 3 edits — and must survive untouched (review WARN #5).
    — **Done when:** Step 10 has 10a/10b headings; all four 10a phrases AND both Step-7 phrases appear (`grep -F` each → found).
    — **Consumers affected:** `tests/test_tiered_gating.bats` tier3 assertions; `agents/pr-workflow-subagent.md` pipeline-mode contract (still accurate — 10a unchanged in substance).
- [ ] **4.2** Add the authoritative overlap re-check to 10a, pre-PR: before `pr-workflow-subagent` creates the PR, compute `comm -12` of `git diff --name-only origin/<base>...feat/<KEY>` against each earlier in-run ticket's still-open PR diff (per repo); a non-empty intersection holds ticket N pre-PR (worktree kept) — auto-resume on that PR's merge notification: rebase, re-run the full gate (the SHA changes), then create the PR. A PR showing merge conflicts because an earlier in-run PR merged inside the 6e→10a window (stale base) is classified the same way — overlap-hold: rebase onto the updated base, full re-gate, re-create the PR — never a failed ticket.
    — **Why:** The complete implementation diff only exists at 10a — this is the guard's authoritative leg (Requirements answer #1c); catching overlap here prevents a conflicting PR from ever opening (AC #5). The stale-base clause closes the residual class the open-PR check cannot see (re-review NOTE #1).
    — **Done when:** 10a contains the pre-PR `comm -12` re-check with the hold action and the rebase + full-re-gate + create-PR resume path, plus the stale-base conflict classification (overlap-hold, not failure).
    — **Consumers affected:** `pr-workflow-subagent` invocation waits on this check; 4.4's notification handler classifies watcher merge-conflict failures via this rule; Failure Policy hold semantics (Phase 5).
- [ ] **4.3** Write the 10b watcher spec: background `timeout 1800 gh pr checks <num> --watch` (GNU coreutils; macOS `gtimeout`) → green-only `gh pr merge <num> --squash` → merge SHA capture via `gh pr view <num> --json mergeCommit` → report the outcome to the main session; zero configured checks → merge directly with a note; red or pending-at-timeout → report the failing check names, no local mutations of any kind. The watcher performs gh-side operations only — `git worktree remove`, remote branch delete, and the main-checkout fetch move to the main session's notification handler (4.4).
    — **Why:** This is the mechanism that moves the CI wait out of the main loop while keeping merges green-only and the scene recoverable on red (AC #2, #7). A gh-only watcher eliminates the mutation race: a background `git worktree remove` racing the main session's concurrent `git worktree add` for the next ticket can fail the run with a git lock error (review WARN #2) — all local worktree/ref mutations stay serialized in the main session.
    — **Done when:** 10b specifies the watch command + timeout, green-only merge, SHA capture, the report-to-main-session contract, the zero-checks path, the red path, and states the watcher performs no local git mutations.
    — **Consumers affected:** 4.4 (owns cleanup + JIRA transition); Failure Policy (Phase 5) defines what a red watcher report triggers.
- [ ] **4.4** Add the notification-handling rule: notifications queue and drain at step/ticket boundaries only — never mid-Task (a Step 8 run-plan or Step 9 review Task may run many minutes), in arrival order, each exactly once (exactly-once dedupes the single JIRA Done transition). On a merge notification the main session reports the merge SHA, performs the watcher's cleanup (`git worktree remove <root>/<KEY>`, remote branch delete, fetch-only in the main checkout), and performs exactly one JIRA Done transition for JIRA tickets (status checked first, transition only if still open). On a red notification the fix is queued for the next boundary (or immediate if idle), bounded at 2 fix-and-re-watch rounds per ticket before the ticket is failed; red-fix pushes ride the existing re-gate-once rule — full gate + fresh green `tier=full` memo for the new final SHA before re-watch, since the 10a citation names the final pushed SHA.
    — **Why:** Merge-sensitive side effects (JIRA writes) need MCP tools that stay in the main session — the watcher script must hold no credentials (AC #7); an event-driven contract without a processing-boundary rule makes JIRA transitions and held-ticket resumes nondeterministic (review WARN #6; Requirements answer #5); the re-gate clause prevents the PR citation from naming a stale SHA (review WARN #4; Requirements answer #4); the round bound keeps red-PR recovery finite (AC #2).
    — **Done when:** 10b (or an adjacent bullet) states the boundary-drain rule (boundaries-only, arrival order, exactly-once), the main-session cleanup + JIRA transition, the credential-free constraint on the watcher, the 2-round bound, and the red-fix re-gate requirement.
    — **Consumers affected:** Failure Policy exhaustion semantics (Phase 5); `jira-status-updater` flow unchanged in count (exactly one transition); Step 9's re-gate rule now also governs watcher fix rounds.
- [ ] **4.5** Add the §Portability contract capability-binding block for the background mechanism, with per-harness bindings plus a portable fallback row and a bash note on the watcher snippet.
    — **Why:** AGENTS.md §Portability contract rule 1 requires per-harness bindings + a portable fallback for harness-specific mechanisms, and `tests/test_portability.bats` enforces a fallback row on background-shell mentions (AC #8).
    — **Done when:** The binding block exists in Step 10 with all three rows (OpenCode background shell with completion notification; Claude Code background Bash; Other/none foreground `timeout 1800 gh pr checks <num> --watch` as today's fallback) and the "Requires bash (git-bash/WSL on Windows)" note; `tests/test_portability.bats` background-mention test passes on the file.
    — **Consumers affected:** `tests/test_portability.bats`; cross-harness portability of the skill.

    Binding block to insert (Step 10):
    - OpenCode: background shell (`background: true` completion notification)
    - Claude Code: background Bash (run_in_background)
    - Other/none: foreground `gh pr checks --watch` before advancing (today's behavior)

### Phase 5: Failure Policy, Guarantees, Return Contract
- [ ] **5.1** Rewrite the Failure Policy halt triggers: remove "CI red — any concluded failing check, or still pending at the 30-minute timeout" as a run-level abort; halt triggers become the executor's `[goal:blocked]` on the active ticket, review-fix exhaustion (Step 9), PR creation failure, and watcher exhaustion (2 fix-and-re-watch rounds); a red or timed-out watcher fails that ticket only — scene kept, independent tickets proceed, dependent tickets stay held and are reported deferred.
    — **Why:** One minor red check must not kill the remaining run — this is the abort-rule change the ticket names (AC #3).
    — **Done when:** The Failure Policy lists the new halt triggers, contains no run-level CI-red abort, and defines the per-ticket red-watcher outcome.
    — **Consumers affected:** Return Contract semantics (5.3); held/deferred reporting.
- [ ] **5.2** Update the Guarantees: replace "Sequential execution across tickets; one worktree live per ticket" with: one active implementation at a time; any number of background merge watchers; a ticket's worktree lives until its PR resolves (merge → cleaned up by the main session's notification handler; red → kept for fixes); every merge is green-only; the watcher performs no local git mutations.
    — **Why:** The guarantees section is the contract readers trust — it must describe the new concurrency truthfully (AC #1, #2).
    — **Done when:** The guarantees bullet list states the new concurrency model and no longer claims one-live-worktree sequential execution.
    — **Consumers affected:** none (documentation-of-contract).
- [ ] **5.3** Update the Return Contract: Output = per ticket — PR URL + merge SHA (watcher-reported) + final state (merged / failed-red / deferred-held); Issues gains held and deferred tickets, red-watcher outcomes, and notes that the final report waits for outstanding watchers (each watcher bounded by the 30-minute cap plus up to 2 red-fix-and-re-watch rounds). Deferred-only remainder (no failures) reports run Status `success` with deferred tickets under Issues; any failed-red ticket → `partial` (Requirements answer #3).
    — **Why:** Callers need the per-ticket terminal state of a run whose tickets now resolve asynchronously (AC #2, #3).
    — **Done when:** The Return Contract names watcher-reported merge SHAs and the held/deferred/red outcome vocabulary.
    — **Consumers affected:** none (reporting surface).
- [ ] **5.4** Run the scoped guard suite `bats tests/test_portability.bats tests/test_tiered_gating.bats tests/test_skill_isolation.bats` in the worktree after the last content edit and fix any phrasing the assertions flag.
    — **Why:** Fail-fast on the mechanical constraints (phrase preservation, fallback row, isolation) — and per the done-when-gate-escapes-its-phase rule, the final-state sweep belongs after the last edit, not inside Phase 4 (review NOTE #7).
    — **Done when:** All three bats files exit 0 in the worktree.
    — **Consumers affected:** none (verification-only step).

## Technical Notes

- From the ticket: 10a creates the PR exactly as today (gate-memo citation + `Closes <TICKET_ID>`); 10b is a plain background shell script — no new subagent, no credentials (gh uses the ambient auth; JIRA writes stay in the main session via MCP). The watcher is gh-only; all local worktree/ref mutations run in the main session's notification handler.
- The watcher runs from the ticket's repo directory so `gh` resolves the right remote; for foreign repos use `gh -R <owner/name>`.
- Post-merge deploys (e.g. DA-2951's `deploy-lambda.yml`) are ticket-PLAN concerns, not pipeline machinery — the merge notification proves the merge, not the deploy.
- Deliberately out of scope: auto-rebase of open PRs after unrelated merges (overlap-free PRs squash-merge cleanly), a dedicated watcher subagent, any change to `plan-execution-skill` (its gate/fix loops are per-ticket work), and frontmatter changes (no `installer/build-registry.mjs` regen needed).
- README command-table wording stays as-is: "PR merge" remains true; only its timing changed.
- `agents/pr-workflow-subagent.md` line "the orchestrator owns the merge via the CI gate" stays accurate — ownership moves from the orchestrating loop to the orchestrator's watcher, still not the subagent.

## Dependencies

None external — single-ticket run, no `blocked-by:`.

## Risks & Mitigation

- Tier3 phrase assertions break on the Step 10 rewrite → preserved verbatim in 4.1, verified in 5.4.
- Token-classifier regression on bare `KEY`/base-branch detection → 1.3 enumerates the full taxonomy with explicit fallthrough; existing forms byte-identical.
- Concurrent watchers vs the orchestrator mutating the same repo's worktree metadata → the watcher is gh-only; all local worktree/ref mutations are serialized in the main session at notification boundaries (review WARN #2).
- Scope creep into execution semantics of `plan-execution-skill` → explicitly out of scope in Technical Notes.
