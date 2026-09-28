# amend-after-sed needs a re-stage — the SHA silently stays

**Category**: anti-pattern
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-28

## Anti-pattern

Mutating a file with `sed` (or any working-tree edit) BETWEEN `git add` and
`git commit --amend` commits the STALE index: amend snapshots the index, not
the working tree. When the mutation lands within the same second as the
original commit, the amended commit is byte-identical (same tree, same
committer timestamp) — the SHA does not change, the push ships the
placeholder, and a working-tree `grep` shows the "fixed" text because it
reads the uncommitted file.

## Fix

After any working-tree mutation between `git add` and `--amend`, re-run
`git add <file>` before amending. Verify the COMMITTED view, never the
working tree: `git show HEAD:<file> | grep <sentinel>`; `git status
--porcelain` showing the file modified is the tell that the sed never staged.

## Evidence

#636 Step 8 exit memo: `sed -i "s/GATE PENDING/GATE <sha>/"` ran after
staging, `git commit --amend --no-edit --quiet` was a no-op, and 3083957
pushed carrying `GATE PENDING`; repaired by re-staging + amend + push
`--force-with-lease` to 5717dbd.
