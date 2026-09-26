## Harness binding — OpenCode

- **Perception**: you run on `zai-coding-plan/glm-5.3-flash` (vision tier, native multimodal) — the native path is your primary perception. The fallback recipe's auth lookup reads `~/.local/share/opencode/auth.json` (`zai-coding-plan` or `zai` key); on this deploy that is the expected key source, with `ZAI_API_KEY` as fallback.
- **Delegation**: callers grant access via OpenCode v2 `subagent` permission rules (`resource: image-analyzer-subagent`, `effect: allow`).
