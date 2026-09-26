# opencode v2 commands: agent/subagent/model semantics

- **Category**: solutions
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-26
- **Summary**: Verified against opencode.ai v2 docs/commands (2026-09-26): the JSON key is `commands` (plural); `agent` selects the executor; `subagent: true|false` forces child/current session (omitted = child iff the agent's `mode: subagent`); `subtask` is a deprecated alias; model precedence is command-model > agent's configured model > session model — so subagent-delegating commands do NOT run on the session default unless `model:` is pinned on the command. A/B-style comparisons must pin `model:` identically per arm and record the resolved model (#582 plan review M3).
