---
name: civiltekk-documentation-inline-skill
description: >-
  In-session documentation delegate — docstrings and docs for new/changed
  symbols only, generating language-specific docstrings for C#, Java,
  Python, and TypeScript (PEP 257, Javadoc, JSDoc, XML). Triggers: inline
  docs, docstrings in-session, plan-execution-inline-skill documentation
  step, generate docstrings, convert docstring styles, doc-coverage CI.
license: Apache-2.0
compatibility: opencode
metadata:
  mirrors: documentation-subagent
category: Documentation
---

# Documentation (inline)

You are executing the documentation delegate's workflow **in this session**.
Same trade as the rest of the inline family: session context and full tool
access instead of isolation — the discipline below keeps that honest.

Consolidates documentation-inline-skill + docstring-generator-skill (#603).
This file carries the inline METHOD (decision tree, scope bounds,
enforcement deltas, output contract); the docstring-generator's per-language
format VALUES moved to `references/docstring-formats.md`.

## Decision tree

1. **Skip check:** the diff adds/changes no functions, classes, or public
   surface (pure-data, config, lockfiles, generated code) → report "no doc
   surface", stop.
2. **Enumerate:** new/changed symbols from the diff (`git diff --name-only
   --diff-filter=AM`, then symbol-level for touched files). Existing symbols
   whose contracts did not change are out of scope.
3. **Standards — route `docstring-formats`:** per-language docstring values
   (Python PEP 257 + Google/NumPy styles, Java Javadoc, TS/JS JSDoc, C# XML
   `///` docs; detect the file's existing style and MATCH it; document
   contracts, not implementations) live in `references/docstring-formats.md`
   — load it before writing any docstring. Prose style via
   `technical-writing-skill` (Diataxis for guides, Google dev-docs style for
   references).
4. **Write:** docstrings only — no README rewrites, no ADRs, no changelogs
   unless the diff itself is a docs change.
5. **Verify:** every written docstring's parameters/returns match the signature
   (drift between doc and code is worse than no doc).

## Side file (load rules)

| Read | When | Use |
|------|------|-----|
| `references/docstring-formats.md` | route `docstring-formats` (decision-tree step 3) | Per-language docstring formats (PEP 257/Google/NumPy, Javadoc, JSDoc, XML `///`), style-matching rule, contracts-not-implementations, doc-coverage discipline |

Side files carry VALUES only; this file carries the METHOD — the decision
tree, scope bounds, and output contract above are the method.

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
