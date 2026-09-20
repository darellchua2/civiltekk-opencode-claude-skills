# Decision: reviewer subagents return LEARNINGS candidates as content

Reviewer subagents hold no edit permissions; they emit `LEARNINGS candidates:` blocks (Category / File / Confidence / Scope / Summary / Date) and the pipeline orchestrator writes the files, appends `_index.md` entries, and commits in the worktree — single-writer rule (#445).
