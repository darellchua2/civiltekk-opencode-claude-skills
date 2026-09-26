# Pattern: event-driven contracts need a notification boundary rule

Prompt-level pipeline contracts that introduce background watchers or event
notifications must state when the agent may act on them. Without a boundary
rule, merge-sensitive side effects (JIRA transitions, held-ticket resumes)
happen at nondeterministic times — mid-delegated-Task, late, or twice.

From PLAN-560 (worktree-pipeline async merge watchers): the rule that holds is
"notifications queue and drain at step/ticket boundaries only, never
mid-Task, in arrival order, each exactly once." Boundaries-only keeps
delegated Tasks absorbable; exactly-once dedupes single-shot side effects
(e.g. one JIRA Done transition); arrival order keeps resumes deterministic.

- **Confidence**: 0.7
- **Scope**: project
- **Date**: 2026-09-25
