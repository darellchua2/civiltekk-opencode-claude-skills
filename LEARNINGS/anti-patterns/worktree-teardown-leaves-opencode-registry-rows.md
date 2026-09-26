# Anti-pattern: worktree teardown deletes the directory but not the registry rows naming it

**Context**: 2026-09-26 — `opencode reload` failed whole-command with `ENOENT ... FileSystem.realPath (/home/silentx/VSCODE/worktrees/DA-2996)`. The worktree-pipeline teardown removed git worktrees cleanly, but `~/.local/share/opencode/opencode.db` had accumulated 56 `worktree`/`project` rows naming deleted directories; reload re-resolves every registered directory and dies on the first stale one.
**Pattern**: Any teardown that removes a directory must, in the same step, delete the registry rows that key on that path — enumerate the stores (git worktree metadata, opencode `worktree` + `project` tables) and clear each.
**Rationale**: Registries without garbage collection gain one dangling row per deleted artifact; any consumer that `realPath`s each row fails on the first stale entry, and the failure surfaces months later in an unrelated command.
**Alternatives Considered**: `mkdir` the dead path so `realPath` succeeds — rejected, leaves a phantom project forever; patching reload to skip ENOENT — upstream code, not ours.
**Confidence**: 0.9
**Scope**: project
