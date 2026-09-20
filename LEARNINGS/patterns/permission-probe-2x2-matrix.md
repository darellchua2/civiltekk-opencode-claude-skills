# Permission-enforcement probes need a 2×2 matrix

**Category**: pattern
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-20

## Pattern

When probing whether a permission rule enforces, cross TWO axes — rule-name
version (v1 alias vs v2 native) × session shape (top-level `--agent` vs
child-spawn subagent). A single cell cannot attribute inertness.

## Context

#482's pre-plan probe (v1 `bash` deny, child-spawn reviewer) showed the rule
inert but conflated two failure modes: alias mismatch (rename fixes) vs
child-session rule application wholesale-broken upstream
(anomalyco/opencode#50149 family). The first drafted follow-up probe
(v2 name, top-level `--agent`) still left the deployment-relevant cell
unmeasured — a top-level ENFORCED verdict is consistent with both "alias
fixed" and "child rules broken", i.e. a false green for the claim that
matters ("rename restores subagent deny enforcement").

## Method

1. Cell A — v1 name, child-spawn (reproduces the incident).
2. Cell B — v2 name, top-level (`opencode run --agent` in a throwaway
   project; `timeout` — a deny that degrades to `ask` hangs non-interactive
   runs).
3. Cell C — v2 name, child-spawn (parent run spawns a mode:subagent probe
   agent). **Only this cell licenses a "restores enforcement" claim** —
   every deny rule in `agents/*.md` is deployed in the child shape.
4. Throwaway project under `/tmp/opencode/`; delete after recording
   verdicts.

## Evidence

PLAN-482 rev 1 step 1.1 drafted cell B only; architecture review +
Mode R ruling 2 added cell C (#482, 2026-09-20).

Related: `anti-patterns/v1-action-names-inert-under-v2.md` (written at #482
execution), upstream anomalyco/opencode#50149.
