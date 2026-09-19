# Anti-pattern: subagent review prompts with unexpanded `$(cat …)` + cwd on the wrong branch

**Context**: #383 content-trim review spawn. The parent's prompt embedded 7 file bodies as literal
`$(cat skills/…/SKILL.md)` — the substitution never executed. The subagent's cwd was on `main`
(pre-trim side), the `feat/383` ref did not exist in that clone (not in `.git/packed-refs`, no loose
ref, no `.git/worktrees/`, no copy under `/tmp/opencode`), and `bash:deny` blocked `git show`.
Review could not run: zero evidence, no fabricating findings.

**Pattern to avoid**: Assembling a subagent prompt that contains `$(cat …)` without a shell that
expands it, while assuming the subagent shares the parent's checkout. A subagent shares the
filesystem, NOT the parent's HEAD or worktree.

**Fix**: Build review payloads with real command output (`git show <branch>:<path>` via a script
whose stdout is pasted in), OR run the reviewer with cwd = the feature-branch worktree, OR grant
bash so the reviewer can `git show` itself. Verify before spawn: the branch ref exists in the
clone the subagent sees.

**Rationale**: Read-only tools (read/glob/grep) silently return the WRONG SIDE of the diff when cwd
is on main — a naive reviewer would have "reviewed" the pre-trim files and signed off.

**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-17
