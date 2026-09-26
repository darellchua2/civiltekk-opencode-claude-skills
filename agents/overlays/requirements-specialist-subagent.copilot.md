## Harness binding — GitHub Copilot

- **Headless mechanics**: no interactive clarification channel exists in a subagent run — the headless clause above applies verbatim.
- **Delegation syntax**: use the Task tool, naming the subagent — `image-analyzer-subagent` for image interpretation, `xlsx-specialist-subagent` for tabular exports, `explore` for repo scans. This agent installs to `~/.copilot/agents/` (user) or `.claude/agents/` (project).
