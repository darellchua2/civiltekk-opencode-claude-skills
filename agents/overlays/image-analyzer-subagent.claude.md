## Harness binding — Claude Code

- **Perception**: judge by whether image input actually works on your model; if it does, the native path is primary.
- **Auth (fallback recipe)**: the `~/.local/share/opencode/auth.json` lookup will not exist — set `ZAI_API_KEY` in the environment for the fallback recipe.
- **Delegation**: Claude Code callers delegate via the Task tool after defining this subagent in `.claude/agents/` (installer `--target claude` writes it there).
