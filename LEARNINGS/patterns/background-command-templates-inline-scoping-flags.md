# Pattern: background command templates inline scoping flags

A literal background-shell command template must inline its scoping flags
(`gh -R <owner/name>`, `git -C <dir>`); prose scoping rules elsewhere in the
document never reach the runtime artifact. A background shell executes the
spelled command verbatim — no agent judgment intercepts it to apply "the gh
context resolves per ticket's repo" stated three sections earlier.

Evidence: worktree-pipeline SKILL.md 10b watcher commands (`gh pr checks`,
`gh pr merge`, `gh pr view`) vs the Step 1 blanket per-repo rule (#560
review) — for `repo/KEY` tickets the unscoped gh calls would resolve against
the session repo, where a PR-number collision can squash-merge the wrong PR.

- **Confidence**: 0.75
- **Scope**: project
- **Date**: 2026-09-25
