---
name: documentation-inline-skill
description: >-
  In-session documentation delegate — docstrings and docs for new/changed
  symbols only, following per-language standards via technical-writing-skill.
  Decision tree with skip rules, scope bounds, enforcement deltas, and output
  contract. Triggers: inline docs, docstrings in-session, /run-plan-v2
  documentation step.
license: Apache-2.0
compatibility: opencode
metadata:
  experiment: inline-family
  mirrors: documentation-subagent
category: experiment
---

# Documentation (inline)

You are executing the documentation delegate's workflow **in this session**.
Same trade as the rest of the inline family: session context and full tool
access instead of isolation — the discipline below keeps that honest.

## Decision tree

1. **Skip check:** the diff adds/changes no functions, classes, or public
   surface (pure-data, config, lockfiles, generated code) → report "no doc
   surface", stop.
2. **Enumerate:** new/changed symbols from the diff (`git diff --name-only
   --diff-filter=AM`, then symbol-level for touched files). Existing symbols
   whose contracts did not change are out of scope.
3. **Standards:** per language — PEP 257 (Python), JSDoc (TS/JS), Javadoc
   (Java), XML docs (C#); prose style via `technical-writing-skill` (Diataxis
   for guides, Google dev-docs style for references). Match the file's existing
   docstring dialect before importing a standard.
4. **Write:** docstrings only — no README rewrites, no ADRs, no changelogs
   unless the diff itself is a docs change.
5. **Verify:** every written docstring's parameters/returns match the signature
   (drift between doc and code is worse than no doc).

## Scope bounds

- Touch only files in the current diff, only the doc comments of the enumerated
  symbols. No drive-by fixes to neighboring docs.

## Enforcement deltas (vs documentation-subagent)

| Subagent enforcement | Inline discipline (you) |
|---|---|
| Fresh context window | Enumerate the symbol list explicitly before writing so coverage is checkable |
| Isolated edit sandbox | Edits land directly — list every file+symbol documented in Output |
| Tier model | Same model as the caller — do not guess APIs you cannot see; mark uncertain refs unverified |

## Output contract

**Status:** [success | partial | failed]
**Output:** symbols documented (file → symbol list) + skips with reasons
**Summary:** ≤3 sentences
**Issues:** signature/doc mismatches found elsewhere, or "None"
