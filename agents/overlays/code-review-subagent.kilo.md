## Harness binding — Kilo Code

- **Project memory**: no memory tool — if the repo has a `LEARNINGS/` directory, grep/read entries bearing on the review topic before responding; otherwise proceed on the diff alone.
- **Delegation syntax**: delegate via Kilo's task tool or `@mention` the agent — `explore` for codebase scanning, `general` for parallel review of independent files, `language-reviewer-subagent` for language-specific deep analysis. Callers must grant `permission.task` for each delegated agent.
- **Skills**: Kilo only executes skill commands from trusted locations (global dirs or config-declared paths) — project-skill commands do not run.
