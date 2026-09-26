## Harness binding — Kilo Code

- **Perception**: judge by whether image input actually works on your model; if it does, the native path is primary.
- **Auth (fallback recipe)**: the `~/.local/share/opencode/auth.json` lookup will not exist — set `ZAI_API_KEY` in the environment for the fallback recipe.
- **Delegation**: Kilo callers delegate via the task tool or `@mention`; this agent installs to `~/.config/kilo/agent/` (user) or `.kilo/agent/` (project).
