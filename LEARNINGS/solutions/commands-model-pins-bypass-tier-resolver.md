# Commands model pins bypass the tier resolver

- **Category**: solutions
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-26
- **Summary**: The deploy-time model resolver's blast radius is agent `.md` files + built-in agent blocks in opencode.json — nothing rewrites `commands.<name>.model`, and the #281 exposed-model guard covers tier/agent pins, not command entries. A provider-qualified `model:` pinned in the SHIPPED commands block is therefore provider-locked across `--provider` swaps (dead slash commands for other-provider users). **Rule:** keep shipped command entries model-free; to pin a model for an experiment/A/B, redefine the command in a project `.opencode/opencode.json` (v2 Loading: project replaces global same-name commands) and keep the parity pin out of the shipped config. (#582 re-review N1; companion `opencode-v2-commands-agent-subagent-semantics`.)
