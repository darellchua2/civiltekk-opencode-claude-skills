## Convention: Doc claims about runtime enforcement must match configured plugin options

**Context**: Code review of #382 flagged that `plan-automation-loop-skill` claimed the goal plugin "enforces turn/token/duration limits" — but the plugin ships `default_token_budget` and `max_goal_duration_seconds` **unset**, so with the repo's no-options config only turn limits (`max_auto_turns: 25`), no-progress pause, the prompt-failure ceiling, and Plan-mode locks are actually enforced.
**Pattern**: When documenting what a plugin/config enforces, enumerate the **defaults that are actually active**, not the feature list. Anything option-gated gets "(only when configured via <option>)" inline.
**Rationale**: An operator who walks away believing token/duration caps bound spend is bounded only by the turn cap — the doc created a false safety expectation.
**Applies to**: any `plugins`/`options` adoption in `opencode_app/opencode.json`; plugin capability claims in SKILL.md or README.
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-15

**Evidence**: #382 review (WARN, plan-automation-loop-skill/SKILL.md guardrails note); plugin README Options section (defaults: `default_token_budget` unset, `max_goal_duration_seconds` unset).

#510 instance: AGENTS.md §Portability intro claimed all three rules are
"enforced by the portability guard test (#515)" while #515's issued scope
enforces only rules 1–2 — doc claims must match the enforcing artifact's actual
scope; soften to per-rule attribution.
