# `git stash` exits 0 on "No local changes to save" — porcelain-gated STASHED flags lie

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Ticket**: #423 (fix-verification round)

## Symptom

`restart-opencode-docker.sh` fix round introduced:

```bash
STASHED=0
if [ -n "$(git status --porcelain)" ]; then
  git stash -q && STASHED=1
fi
```

An operator checkout containing ONLY untracked files (scratch notes, artifacts)
hard-fails every redeploy: `git status --porcelain` lists untracked (`??`) as
dirty, `git stash` without `-u` stashes nothing yet still exits 0 ("No local
changes to save"), so `STASHED=1` records a stash that was never created — and
the later `git stash pop` fails on an empty stash list with a misleading
"stash pop conflict" error.

## Rule

Never derive "a stash exists" from a dirtiness check. Either:

- gate on tracked-only dirt (`git status --porcelain --untracked-files=no`) so
  `git stash` always has real work, or
- compare `git rev-parse -q --verify refs/stash` before/after the stash and set
  the flag from the ref delta (also immune to pre-existing stash entries).

`git stash push` exiting 0 with nothing saved is documented git behavior —
treat "exit 0" as "command ran", not "state changed".
