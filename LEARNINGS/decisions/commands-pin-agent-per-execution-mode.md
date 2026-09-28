# Shipped commands pin agent per execution mode, never unpin

- **Category**: decisions
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-28
- **Summary**: State-mutating pipeline commands (`/run-worktree-pipeline`, `/run-worktree-pipeline-v2`) pin `agent: "build"` deliberately: unpinning (unset `agent` = current agent) makes them invocable from Plan mode, whose read-only restrictions block the first mutating step — a confusing half-run instead of a clean switch. Read-only variants of the same flow (`/worktree-pipeline-preview`) pin `agent: "plan"` so planning sessions get a genuinely useful surface (inspect-only walk-through, would-be PLAN in-chat, stop before execution). Rule: when a command's flow mutates repo/remote state, route it to the agent whose mode permits that; expose plan-mode value via a separate preview command, not by loosening the pin. All shipped command entries stay model-free (companion: `solutions/commands-model-pins-bypass-tier-resolver.md`; mechanics: `solutions/opencode-v2-commands-agent-subagent-semantics.md`) (#638).
