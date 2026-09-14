## Decision: Re-adopt goal mode as @prevalentware/opencode-goal-plugin (v2), caret-pinned

**Context**: The v1 pin `opencode-goal-plugin@0.8.1` was removed in `5f95d9c` (v1-only plugin versions under a v2 runtime produced boot warnings; the README watch-list tracked the re-add). Upstream rescoped to `@prevalentware/opencode-goal-plugin` and shipped OpenCode v2 support (since `0.1.30`; `0.1.48` published 2026-09-07; actively released).
**Pattern**: `opencode_app/opencode.json` → `"plugins": ["@prevalentware/opencode-goal-plugin@^0.1.48"]` — caret pin, no options object (secure defaults: `restricted_agents: ["plan"]`, `allow_goal_execution_from_plan: false`), and **no `commands.goal` block** (the v2 package self-registers `/goal`, `/pause_goal`, `/resume_goal` — see the superseded note in `solutions/plugin-needs-command-block.md`).
**Rationale** (corrected per plan review): the v1 breakage cause was v1-only plugin versions under a v2 runtime plus exact pins that never floated to v2 releases — **not pinning itself**. A caret pin to the v2-native line bounds drift within `0.1.x`, keeps boots reproducible (repo convention: committed lockfile), and upgrades deliberately. Fallback: if opencode v2 cannot resolve the `@^` constraint at boot, use the bare name AND record the audited version (`npm view`) in the README re-add note.
**Alternatives Considered**: `wejick/opencode-goal` (rejected: 0★, 2 commits, GitHub-only, 4000-char objective cap, no Plan-mode safety). Vendoring the source (rejected: unlike vibeguard, upstream ships v2 — no port needed). Bare name as default (rejected: unreviewed overnight drift on every boot, no reproducibility).
**Trade-offs**:
- Pro: reproducible boots; Plan-mode safety (plan-agent goals stay paused, continuation pinned to `build`); evidence-gated completion; token/turn budgets with wrap-up handoff.
- Con: Docker endpoint stays plugin-inert until the container v2 binary bump (#387); caret still floats `0.1.x` patches.
**Confidence**: 0.85
**Scope**: project
**Date**: 2026-09-14

**References**:
- `opencode_app/opencode.json` — `plugins` array
- `README.md` — v2 watch-list re-add note (Knowledge Persistence section)
- `LEARNINGS/solutions/plugin-needs-command-block.md` — v1 both-entries rule, superseded
- `LEARNINGS/solutions/docker-v1-binary-ignores-v2-plugins-key.md` — Docker descope rationale
- Issues #382, #387; commit `5f95d9c`
