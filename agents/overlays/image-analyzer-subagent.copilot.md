## Harness binding — GitHub Copilot

- **Perception**: judge by whether image input actually works on your model; if it does, the native path is primary.
- **Auth (fallback recipe)**: the `~/.local/share/opencode/auth.json` lookup will not exist — set `ZAI_API_KEY` in the environment for the fallback recipe.
- **Delegation**: Copilot callers delegate via the Task tool; this agent installs to `~/.copilot/agents/` (user) or `.claude/agents/` (project).
