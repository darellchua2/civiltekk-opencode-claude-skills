# PLAN: /run-worktree-pipeline-v2 — pipeline with inline Step 8

**Branch**: feat/585
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/585
**Base**: main

## Acceptance Criteria
- [ ] `run-worktree-pipeline-v2` exists in the global commands block (user-space) with the Step-8 substitution map
- [ ] README documents the #582 experiment command set (`/review-arch`, `/review-inline`, `/run-plan-v2`, `/run-worktree-pipeline-v2`) in a compact experiment note
- [ ] `worktree-pipeline-skill`, `plan-execution-skill`, and all subagents byte-identical (no repo code changes beyond README)
- [ ] PR merged to main via the worktree pipeline itself

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `README.md` (experiment note) | — | repo readers, #582 A/B decision record | low |
| `~/.config/opencode/opencode.json` (user-space, NOT in PR) | — | local `/run-worktree-pipeline-v2` invocations | low |

No cross-module consumers → zero Step-7 reviewers selected (thin docs-only map; Step 9 code review backstops).

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Command + tracked docs
- [ ] **1.1** Add a compact "#582 experiment commands" note to README.md near the existing `/run-plan` / `/run-worktree-pipeline` usage rows, documenting the four experiment commands (`/review-arch`, `/review-inline`, `/run-plan-v2`, `/run-worktree-pipeline-v2`), their one-line semantics, and the hybrid scope (inline workers at Step 8; subagent reviewer at Step 9)
    — **Why:** the command definitions live only in machine-local config; the ticket requires a tracked definition (AC#2) so the A/B decision record is reproducible.
    — **Done when:** `rg -c "run-worktree-pipeline-v2" README.md` ≥ 1 AND `git diff --name-only origin/main...HEAD` lists exactly `README.md` (every other file byte-identical).
    — **Consumers affected:** repo readers; #582 decision record.
- [ ] **1.2** Verify AC#1: `run-worktree-pipeline-v2` present in `~/.config/opencode/opencode.json` commands with the substitution map (user-space — added outside this PR by design)
    — **Why:** AC#1 must be checked even though the artifact is deliberately outside the PR; the check rides this run's gate trace.
    — **Done when:** `python3 -c "import json;assert 'run-worktree-pipeline-v2' in json.load(open('/home/silentx/.config/opencode/opencode.json'))['commands']"` exits 0.
    — **Consumers affected:** none (read-only verification).

## Technical Notes
- AC#4 (PR merged to main) is owned by the executing worktree pipeline itself (its Step 10) — no PLAN step can merge its own PR; the AC is discharged by this very run.
- The command was already added to user-space config before this PLAN (pre-approved by the user); step 1.2 verifies rather than creates.
- No installer/preset/registry changes — the command is machine-local like its three siblings (`/run-plan`, `/create-ticket`, `/run-worktree-pipeline`), which are also hand-managed.
- `worktree-pipeline-skill` Step 9 review + Step 10 PR remain subagent-driven: reviewer isolation is the #582 A/B's epistemic variable and stays untouched.

## Dependencies
- None external. #582 merged (e5eba09) — this builds on its family.

## Risks & Mitigation
- **README drift** (counts change independently) → mitigation: the note names commands, not skill counts, so it cannot drift with registry arithmetic.
