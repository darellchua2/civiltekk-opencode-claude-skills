# Pattern: contracts adding rebases must state force-push

Any contract that rebases an already-pushed branch must state the force-push
story (`--force-with-lease`) at every rebase site. Downstream per-phase
plain pushes then fail non-fast-forward with an error the contract never
anticipated — the first resume in practice dies at the next phase push.

Evidence: worktree-pipeline SKILL.md resume paths (Step 2 held-resume, 6f
overlap resume, 10a pre-PR resume) all rebase a branch already pushed at 6e;
zero force mentions existed before the #560 review fix.

- **Confidence**: 0.75
- **Scope**: project
- **Date**: 2026-09-25
