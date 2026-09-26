## Harness binding — ZCode

- **Perception**: judge by whether image input actually works on your model; if it does, the native path is primary.
- **Auth (fallback recipe)**: the `~/.local/share/opencode/auth.json` lookup will not exist — set `ZAI_API_KEY` in the environment for the fallback recipe.
- **Delegation**: this agent is a leaf — it does not chain further. ZCode callers grant access via their subagent configuration (user-level `~/.zcode/agents/`).
