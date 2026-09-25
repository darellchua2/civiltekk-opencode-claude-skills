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

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Step 1 — execution model + cross-repo parsing
- [ ] **1.1** Replace the "Ticket order = execution order (sequential; never parallel worktrees)" bullet with the pipelining execution model: one active implementation at a time; a ticket's implementation starts once the previous implementation has shipped its PR AND the ticket's own blockers have merged; unblocked tickets never wait on CI; N background merge watchers may run concurrently.
    — **Why:** This is the core stall fix — CI wait must leave the main loop so the next implementable ticket proceeds (AC #1).
    — **Done when:** The bullet states one-active-implementation, advance-on-ship, and concurrent-watchers rules with no "never parallel worktrees" residue (`grep -c "never parallel worktrees"` → 0).
    — **Consumers affected:** OpenCode agent runtime executing multi-ticket runs; Failure Policy and Guarantees sections updated in Phase 5 to match.
- [ ] **1.2** Rewrite the `blocked-by:` rule from permanent skip to hold-and-resume: held tickets are reported as held; when the blocker's merge notification arrives mid-run, the ticket auto-resumes (rebase `feat/<KEY>` onto the updated base, continue at Step 7); tickets still held at run end are reported as deferred, not failed.
    — **Why:** A permanent skip forces the user to re-invoke the pipeline after every merge in a dependent chain (AC #4).
    — **Done when:** The Step 1 blocked-by bullet says hold + auto-resume + deferred-at-end, with the resume mechanics named; the word "skip" no longer describes the blocked-by path.
    — **Consumers affected:** Step 2 (resume path) and Failure Policy (deferral semantics) must stay consistent.
- [ ] **1.3** Extend the ticket-ref grammar and document the full Step-1 first-token taxonomy in one place: `--`flags, base-branch fallback test, bare numerics, `#N`, `owner/repo#N`, `[A-Z][A-Z0-9]+-\d+` (JIRA), and the new `repo/KEY` JIRA form matching `[\w.-]+/[A-Z][A-Z0-9]+-\d+`; bare `KEY` and all existing forms behave exactly as before.
    — **Why:** Cross-repo chaining needs the ticket ref to name its repo; an explicit taxonomy with a deterministic fallthrough prevents classifier drift on variants (LEARNINGS: exact-match branch taxonomy fallthrough).
    — **Done when:** The regex in Step 1 includes the `repo/KEY` alternative and the bullet enumerates every accepted token shape; existing forms are byte-identical in behavior.
    — **Consumers affected:** `--dry-run` predictions (1.5) and Steps 2–4 repo context (Phase 2) consume the resolved repo.
- [ ] **1.4** Add sibling-checkout resolution for `repo/KEY`: the named repo resolves to `../<repo>` relative to the main checkout, must exist and be a git repo (else one batched user ask, then abort if unresolved); base branch, `ls-remote` validation, worktree root, and gh context are resolved per repo.
    — **Why:** Without a local checkout the pipeline cannot cut branches or run gh/JIRA-aware steps for the foreign repo (AC #6).
    — **Done when:** Step 1 states the `../<repo>` resolution rule, the existence check, the ask-once-then-abort fallback, and per-repo base validation.
    — **Consumers affected:** Step 2 merged-check/branch-cut and Step 4 worktree root (Phase 2) thread this resolved repo path.
- [ ] **1.5** Extend the `--dry-run` block to print per-ticket hold/async predictions: which tickets will hold on `blocked-by:`, which will hold on open-PR overlap, which PRs will get background watchers, and the would-be branch/worktree names per repo.
    — **Why:** A run whose control flow changed must remain fully predictable before any mutation (AC #6).
    — **Done when:** The dry-run bullet lists hold predictions and watcher plans among its outputs; still read-only (no writes/mutations wording preserved).
    — **Consumers affected:** none (read-only path).

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
- [ ] **3.1** Insert the overlap guard between the PLAN push (6e) and plan review (Step 7): while any earlier in-run ticket still has an open PR, compute `comm -12` of `git diff --name-only origin/<base>...feat/<N>` against that PR's branch diff (per repo); a non-empty intersection holds ticket N — worktree kept, auto-resume on that PR's merge notification (rebase, re-run the full gate since the SHA changes, continue at Step 7).
    — **Why:** Two open PRs touching the same files would conflict after the first squash-merges; holding preserves mergeability without serializing independent work (AC #5).
    — **Done when:** The guard bullet exists at the 6e→7 boundary with the comm-based check, hold action, and resume mechanics (rebase + full re-gate) spelled out.
    — **Consumers affected:** Step 7 plan review must tolerate a deferred start; Failure Policy gains the corresponding hold semantics (Phase 5).

### Phase 4: Step 10 — 10a/10b split + background watcher
- [ ] **4.1** Split Step 10 into 10a (PR creation) and 10b (merge watching), preserving verbatim in 10a: the `GATE <short-sha> tier=full` citation requirement, the "never satisfies this citation" rule, the `Closes <TICKET_ID>` body rule, and the skip-steps instruction to `pr-workflow-subagent`.
    — **Why:** The tier3 gating assertions grep these exact phrases — their preservation keeps `tests/test_tiered_gating.bats` green while the step is restructured (AC #8).
    — **Done when:** Step 10 has 10a/10b headings; all four preserved phrases appear in 10a (`grep -F` each → found).
    — **Consumers affected:** `tests/test_tiered_gating.bats` tier3 assertions; `agents/pr-workflow-subagent.md` pipeline-mode contract (still accurate — 10a unchanged in substance).
- [ ] **4.2** Write the 10b watcher spec: background `timeout 1800 gh pr checks <num> --watch` (GNU coreutils; macOS `gtimeout`) → green-only `gh pr merge <num> --squash` → merge SHA capture via `gh pr view <num> --json mergeCommit` → cleanup only on success (`git worktree remove`, remote branch delete, fetch-only in the main checkout); zero configured checks → merge directly with a note; red or pending-at-timeout → no cleanup, report the failing check names.
    — **Why:** This is the mechanism that moves the CI wait out of the main loop while keeping merges green-only and the scene recoverable on red (AC #2, #7).
    — **Done when:** 10b specifies the watch command + timeout, green-only merge, SHA capture, success-only cleanup, zero-checks path, and the red/no-cleanup path.
    — **Consumers affected:** Failure Policy (Phase 5) defines what a red watcher report triggers; cleanup mirrors today's Step 10 tail.
- [ ] **4.3** Add the notification-handling rule: on a merge notification the main session reports the merge SHA and performs exactly one JIRA Done transition for JIRA tickets (status checked first, transition only if still open); on a red notification the fix is queued for the next implementation boundary (or immediate if idle), bounded at 2 fix-and-re-watch rounds per ticket before the ticket is failed.
    — **Why:** Merge-sensitive side effects (JIRA writes) need MCP tools that stay in the main session — the watcher script must hold no credentials (AC #7); the round bound keeps red-PR recovery finite (AC #2).
    — **Done when:** 10b (or an adjacent bullet) states the main-session JIRA transition, the credential-free constraint on the watcher, and the 2-round fix-and-re-watch bound.
    — **Consumers affected:** Failure Policy exhaustion semantics (Phase 5); `jira-status-updater` flow unchanged in count (exactly one transition).
- [ ] **4.4** Add the §Portability contract capability-binding block for the background mechanism, with per-harness bindings plus a portable fallback row and a bash note on the watcher snippet.
    — **Why:** AGENTS.md §Portability contract rule 1 requires per-harness bindings + a portable fallback for harness-specific mechanisms, and `tests/test_portability.bats` enforces a fallback row on background-shell mentions (AC #8).
    — **Done when:** The binding block exists in Step 10 with all three rows (OpenCode background shell with completion notification; Claude Code background Bash; Other/none foreground `timeout 1800 gh pr checks <num> --watch` as today's fallback) and the "Requires bash (git-bash/WSL on Windows)" note; `tests/test_portability.bats` background-mention test passes on the file.
    — **Consumers affected:** `tests/test_portability.bats`; cross-harness portability of the skill.

    Binding block to insert (Step 10):
    - OpenCode: background shell (`background: true` completion notification)
    - Claude Code: background Bash (run_in_background)
    - Other/none: foreground `gh pr checks --watch` before advancing (today's behavior)
- [ ] **4.5** Run the scoped guard suite `bats tests/test_portability.bats tests/test_tiered_gating.bats tests/test_skill_isolation.bats` in the worktree and fix any phrasing the assertions flag before proceeding.
    — **Why:** Fail-fast on the mechanical constraints (phrase preservation, fallback row, isolation) instead of discovering them at the exit gate.
    — **Done when:** All three bats files exit 0 in the worktree.
    — **Consumers affected:** none (verification-only step).

### Phase 5: Failure Policy, Guarantees, Return Contract
- [ ] **5.1** Rewrite the Failure Policy halt triggers: remove "CI red — any concluded failing check, or still pending at the 30-minute timeout" as a run-level abort; halt triggers become the executor's `[goal:blocked]` on the active ticket, review-fix exhaustion (Step 9), PR creation failure, and watcher exhaustion (2 fix-and-re-watch rounds); a red or timed-out watcher fails that ticket only — scene kept, independent tickets proceed, dependent tickets stay held and are reported deferred.
    — **Why:** One minor red check must not kill the remaining run — this is the abort-rule change the ticket names (AC #3).
    — **Done when:** The Failure Policy lists the new halt triggers, contains no run-level CI-red abort, and defines the per-ticket red-watcher outcome.
    — **Consumers affected:** Return Contract semantics (5.3); held/deferred reporting.
- [ ] **5.2** Update the Guarantees: replace "Sequential execution across tickets; one worktree live per ticket" with: one active implementation at a time; any number of background merge watchers; a ticket's worktree lives until its PR resolves (merge → cleaned up by the watcher; red → kept for fixes); every merge is green-only.
    — **Why:** The guarantees section is the contract readers trust — it must describe the new concurrency truthfully (AC #1, #2).
    — **Done when:** The guarantees bullet list states the new concurrency model and no longer claims one-live-worktree sequential execution.
    — **Consumers affected:** none (documentation-of-contract).
- [ ] **5.3** Update the Return Contract: Output = per ticket — PR URL + merge SHA (watcher-reported) + final state (merged / failed-red / deferred-held); Issues gains held and deferred tickets, red-watcher outcomes, and notes that the final report waits for outstanding watchers (each bounded by the 30-minute cap).
    — **Why:** Callers need the per-ticket terminal state of a run whose tickets now resolve asynchronously (AC #2, #3).
    — **Done when:** The Return Contract names watcher-reported merge SHAs and the held/deferred/red outcome vocabulary.
    — **Consumers affected:** none (reporting surface).

## Technical Notes

- From the ticket: 10a creates the PR exactly as today (gate-memo citation + `Closes <TICKET_ID>`); 10b is a plain background shell script — no new subagent, no credentials (gh uses the ambient auth; JIRA writes stay in the main session via MCP).
- The watcher runs from the ticket's repo directory so `gh` resolves the right remote; for foreign repos use `gh -R <owner/name>`.
- Post-merge deploys (e.g. DA-2951's `deploy-lambda.yml`) are ticket-PLAN concerns, not pipeline machinery — the merge notification proves the merge, not the deploy.
- Deliberately out of scope: auto-rebase of open PRs after unrelated merges (overlap-free PRs squash-merge cleanly), a dedicated watcher subagent, any change to `plan-execution-skill` (its gate/fix loops are per-ticket work), and frontmatter changes (no `installer/build-registry.mjs` regen needed).
- README command-table wording stays as-is: "PR merge" remains true; only its timing changed.
- `agents/pr-workflow-subagent.md` line "the orchestrator owns the merge via the CI gate" stays accurate — ownership moves from the orchestrating loop to the orchestrator's watcher, still not the subagent.

## Dependencies

None external — single-ticket run, no `blocked-by:`.

## Risks & Mitigation

- Tier3 phrase assertions break on the Step 10 rewrite → preserved verbatim in 4.1, verified in 4.5.
- Token-classifier regression on bare `KEY`/base-branch detection → 1.3 enumerates the full taxonomy with explicit fallthrough; existing forms byte-identical.
- Concurrent watchers interleaving JIRA/gh writes → each watcher is per-PR and stateless; the only shared resource (main checkout) is touched fetch-only.
- Scope creep into execution semantics of `plan-execution-skill` → explicitly out of scope in Technical Notes.
