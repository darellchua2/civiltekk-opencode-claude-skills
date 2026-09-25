---
name: dev-uat-promotion-skill
description: >-
  Orchestrate batch dev-to-uat branch promotion across many repos — remote
  dedup, fast-forward vs back-merge vs uat-only classification, protected
  branch PR fallback, verification, and per-ticket result comments.
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

## What I do

I am an **orchestration skill** for promoting `dev` → `uat` across a set of
repos (one JIRA Task per repo, or ad-hoc). I do NOT execute git operations
inline. I provide the primary agent with:

1. **Inventory logic** — how to enumerate repos and dedupe remotes (sibling
   clones and renamed GitHub repos are the norm, not the exception)
2. **Classification matrix** — ff-able / divergent / uat-only / equal, from a
   FRESH fetch
3. **Execution invariants** — the back-merge-first ordering, no force-push,
   main untouched, quarantine-on-failure
4. **Conflict resolution policy** — mechanical vs decision-grade conflicts
5. **Protected-branch fallback** — the PR path when direct uat push is
   rejected
6. **Ticket hygiene contract** — result comment + transition rules

Execution is plain git run by the primary agent (or delegated to
`repo-ops-specialist-subagent` with my §Delegation Spec).

## When to use me

Invoke me when asked to "promote dev to uat" for one repo or a batch, when
executing promotion JIRA Tasks (e.g. "Promote <repo> dev to uat"), or when
`/run-worktree-pipeline` hits promotion ops tickets (git-refs-only — no feat
branch, PLAN, or PR applies except the protected-branch fallback).

## Governance

> **Content Rule:** This skill MUST contain ZERO inline bash scripts and ZERO
> inline YAML templates. The process is described as ordered rules; any script
> written from it lives in `/tmp/opencode/` for the run only. This rule is
> auditable — inline executable script bodies are a defect.

This skill defers to:

| Aspect | Governing Skill / Agent | Section Reference |
|--------|-------------------------|-------------------|
| Branch flow & release conventions | `version-bump-standard-skill` | §Branch Flow |
| Merge strategy & tag mapping | `semantic-release-convention-skill` | §Branch-Aware Tag Mapping |
| New promotion tickets | `ticket-creation-skill` | full flow |
| PR on protected branches | `pr-workflow-subagent` | PR creation + gates |
| Bulk execution delegation | `repo-ops-specialist-subagent` | §Delegation Spec below |

## Inventory & Remote-Identity Dedup

Before ANY classification:

1. Enumerate candidate repo directories (e.g. `~/VSCODE/canvastekk-*`).
2. For each, read `git remote get-url origin` and normalize (strip `.git`).
3. **Resolve the canonical GitHub name**: `gh api repos/<owner/repo> --jq .full_name`.
   A configured URL may be an OLD NAME of a renamed repo — GitHub redirects
   old URLs, so two directories with different configured URLs can be ONE
   remote. Confirmed instance: `floor-flatness-assessment-demo` →
   `canvastekk-point-cloud-app`.
4. Group directories by canonical remote. **One promotion per distinct
   remote**; sibling-directory tickets for the same remote are FULFILLED
   (verified + commented), never re-executed.

## Classification (per distinct remote, fresh fetch first)

Fetch `dev` and `uat` immediately before deciding; never classify on stale
refs (a sibling promotion minutes ago can already have changed the remote).

| State | Test (`merge-base`) | Action |
|-------|--------------------|--------|
| `equal` | dev SHA == uat SHA | Nothing; report already-equal |
| `ff-able` | uat is ancestor of dev | Push dev → uat (fast-forward) |
| `uat-only` | dev is ancestor of uat | Push uat → dev (the back-merge IS the ff), then equal |
| `divergent` | both have unique commits | Back-merge uat into dev (§Back-Merge Procedure), push dev, then push dev → uat |

## Execution Invariants

- **Back-merge-first**: uat-specific commits land in dev BEFORE any uat push.
  dev → uat must always be a fast-forward.
- **No force-push anywhere.** A rejected push is a signal (remote moved, or
  branch protected) — re-fetch and re-classify, never retry blindly.
- **Main untouched.** Pushes target `refs/heads/dev` and `refs/heads/uat`
  only.
- **Fresh verification before every push**: ancestor checks against
  just-fetched refs; pushes use explicit SHAs so a concurrent remote update
  causes rejection, not corruption.
- **Never touch the user's working checkouts** beyond `git -C <repo> fetch` —
  merges happen in throwaway worktrees.
- **Worktrees**: `git worktree add --detach /tmp/opencode/prom-<KEY>
  <origin/dev SHA>`. On failure, QUARANTINE — keep the worktree for
  inspection, continue the batch, report. Before re-using a quarantined path,
  `git worktree prune` (a stale registration makes `worktree add` fail with
  exit 128).
- Back-merge commit message: `chore: back-merge uat into dev before dev-to-uat
  promotion (<KEY>)`.

## Conflict Resolution Policy

On merge conflict inside the worktree:

1. **Characterize first**: `git diff --name-only --diff-filter=U`.
2. **Mechanical** (both-append index/list files, e.g. `LEARNINGS/_index.md`):
   union-merge; then PROVE losslessness — zero lines present in the losing
   side but absent from the result (`comm -13`). Non-zero → treat as
   decision-grade.
3. **Modify/delete**: decide by lifecycle. A PLAN (or other artifact) for a
   **Done** ticket where dev deleted it as cleanup → **deletion wins**;
   preserve any unique knowledge from the surviving-but-deleted side as a
   JIRA comment on that artifact's ticket. Anything else → decision-grade.
4. **Decision-grade**: quarantine the repo (keep worktree, no pushes), comment
   the ticket with the exact conflict, continue the batch, surface to the user.

## Protected Branches (push policy classification)

Some `uat` branches reject direct pushes (e.g. `canvastekk-devops`: PR-only,
merge commits forbidden, required check `check-source-branch`). The first
rejected push is the probe:

1. On a GH006 protected-branch rejection: back-merge into dev as usual (dev
   accepted the merge), then open `gh pr create --base uat --head dev`.
2. Watch required checks to green.
3. Merge with **squash** — rebase merge fails when the PR carries a back-merge
   commit ("can't be rebased").
4. Squash rewrites SHAs, so verify **content equality**
   (`git diff origin/dev origin/uat` empty) instead of SHA equality, and
   record the SHA divergence as protection-design in the ticket comment.

## Verification Gate (per remote)

- Direct-push repos: `git ls-remote` shows dev == uat.
- Squash-merged protected repos: content-diff empty.
- Re-verify via ls-remote (remote truth), not local refs.

## Ticket Hygiene

- Every ticket gets a result comment: action taken, resulting SHAs,
  verification method, and that the uat push triggers UAT deploys.
- Transition to **Done** only when the verification gate passed.
- `blocked-by:` unmet → comment the skip reason, leave open.
- Fulfilled-by-sibling tickets: comment the dedup evidence (canonical remote
  name) and transition Done.

## Deployment Warning

Pushing `uat` triggers UAT deployments (Amplify for FE apps, CI for
services). Surface this before the first push of a batch.

## Delegation Spec

Payload for `repo-ops-specialist-subagent`:

```
repos: [<abs paths>]
tickets: { <KEY>: { repo, action: ff|back-merge|uat-only, blocked-by? } }
invariants: back-merge-first; no force-push; main untouched;
            worktrees in /tmp/opencode/prom-<KEY>; quarantine-on-conflict
verification: ls-remote dev==uat (content-diff for squash-merged)
reporting: per-ticket comment + Done transition on pass
```

## Return Contract

- `complete` — every distinct remote promoted and verified; all tickets
  commented (Done or justified skip)
- `partial` — one or more quarantined or skipped; per-repo table with exact
  conflict or blocker
- `failed` — pre-execution abort (missing remotes, git unavailable)
