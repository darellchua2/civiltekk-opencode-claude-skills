# Plan step functions must return, never exit

- **Category**: anti-pattern
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #470 (code review round 1)

## Symptom

`setup_zai_api_key` (a NON-critical plan step) still ended an invalid/declined
key with `exit 1`. Under the #470 executor that bypassed the uniform epilogue
(no zip backup, no summary) and turned a warn-and-continue into a hard mid-
deploy failure — deterministic for headless `-y` with no `ZAI_API_KEY` (EOF →
invalid → decline default).

## Root cause

The step predated the executor; its `exit` was correct under the old
`|| true` call convention and silently wrong under the plan. The extraction
sweep looked for bare writes, not bare exits.

## Rule

When introducing a single executor with a uniform epilogue, grep every step
function for bare `exit` and convert to `return` (cancellation-that-stops =
critical step returning 1, never a bare exit). Safe because the executor
dispatches via `if ! "$func"` and the file has no `set -E` (the global ERR
trap never fires inside functions — do NOT add `set -E` while the executor
is dispatch-by-call: it would route every deliberate `return 1` through
error_handler's exit 1, bypassing the epilogue).
