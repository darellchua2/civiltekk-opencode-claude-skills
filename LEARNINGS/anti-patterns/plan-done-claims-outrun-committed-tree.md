# PLAN Done claims outrun the committed tree

- **Category**: anti-patterns
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-26
- **Summary**: PLAN "Done: files:" lists can outrun the committed tree — PLAN-582 3.3 claimed README.md / opencode_app/README.md / deploy/setup.sh count-sync edits that the branch diff (13 files) did not contain: the edits existed only as worktree-local changes and the phase commit's explicit `git add` list omitted them. The work-tree census then passed while the merge audit failed. **Rule:** before ticking a step whose Done lists files, run `git status --short` and reconcile EVERY listed file into the phase commit; cross-check the plan's Done-files list against `git diff base...HEAD --stat` at gate time. (Near-neighbor of plan-map-claims-verified-without-command — merge/bump acceptable.)
