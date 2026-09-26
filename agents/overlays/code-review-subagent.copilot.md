## Harness binding — GitHub Copilot

- **Project memory**: no memory tool — if the repo has a `LEARNINGS/` directory, grep/read entries bearing on the review topic before responding; otherwise proceed on the diff alone.
- **Delegation syntax**: use the Task tool, naming the subagent in the call — `explore` for codebase scanning, `general` for parallel review of independent files, `language-reviewer-subagent` for language-specific deep analysis. This agent installs to `~/.copilot/agents/` (user) or `.claude/agents/` (project — the Claude-format workspace dir VS Code reads).
