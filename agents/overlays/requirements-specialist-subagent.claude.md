## Harness binding — Claude Code

- **Headless mechanics**: no `AskUserQuestion` in a subagent context — the headless clause above applies verbatim.
- **Delegation syntax**: use the Task tool, naming the subagent — `image-analyzer-subagent` for image interpretation, `xlsx-specialist-subagent` for tabular exports, `explore` for repo scans.
