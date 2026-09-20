# The child skill gate follows the merged config, not the agent frontmatter

**Category**: pattern
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-20

## Pattern

On opencode v2.0.11, a subagent's skill loading resolves against the merged
CONFIG set (defaults → global → project → agent-declared config,
last-match-wins) — NOT against the agent markdown frontmatter's
`permissions` skill rules. Tool-action rules (`shell`, `subagent`) from
frontmatter DO apply in child sessions; `skill` rules do not (upstream
anomalyco/opencode#50149).

Consequences:

- A global deny-all + allowlist governs subagent skill access too — the
  frontmatter allow is dead weight until upstream fixes it.
- The working unlock is a CONFIG-layer allow: project `opencode.json` or
  the global/deployed config (that is the #481 interim workaround).

## Regression probe (3 steps, re-run per opencode upgrade)

1. Spawn a reviewer subagent (e.g. `code-review-subagent`) with the
   instruction: "invoke the `skill` tool with id `reviewer-baseline-skill`
   and report the literal outcome".
2. Expect: `loaded`.
3. Any `permission.rejected` → the workaround regressed (or the upstream
   fix changed shape) — re-derive before touching configs.

Flip side (checks the bug itself is still present): remove the config
allow in a scratch project and expect `permission.rejected` — if it loads
WITHOUT config allows, the upstream fix landed and the workaround should
be reverted (lean re-trim + redeploy).

## Evidence

#481 mechanism probe (session ses_f41646fd7ffe3ZtRmEBAeEBb7n): scratch
project `.opencode/opencode.json` with one skill allow appended after the
global deny-all → child subagent `skill` call returned `loaded` (first
success; every frontmatter-only attempt returned `permission.rejected`).
#482 probe matrix: `shell` deny from frontmatter DOES filter the child's
toolset — the defect is `skill`-action-specific.

Related: `decisions/skill-permission-allowlist.md` (unverified marker),
`anti-patterns/v1-action-names-inert-under-v2.md`,
`patterns/permission-probe-2x2-matrix.md`.
