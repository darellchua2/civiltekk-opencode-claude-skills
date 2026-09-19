---
name: docstring-generator-skill
description: Generate language-specific docstrings for C#, Java, Python, and TypeScript following industry standards (PEP 257, Javadoc, JSDoc, XML documentation)
license: Apache-2.0
compatibility: opencode
category: Documentation
---

## What I do

Generate per-language docstrings: Python (PEP 257 + Google/NumPy styles), Java (Javadoc), TypeScript/JavaScript (JSDoc), C# (XML `///` docs). Match each language's official conventions and the repo's existing docstring style.

## When to use me

Documenting public APIs, libraries, or onboarding-heavy modules; converting docstrings between styles; satisfying doc-coverage CI (e.g. docstring lint rules).

## House rules

- **Detect before generating**: scan the target file/package for an existing docstring style (Google vs NumPy in Python; `@param` vs `{param}` in JS) and MATCH it — mixed styles inside one module are worse than none.
- Public symbols get docstrings; trivial private helpers don't (PEP 257's own rule).
- Document contracts, not implementations: parameters/returns/raises (or `@throws`/`<exception>`), side effects, and units — never restate what the signature already says.
- House references: `python-docstring-generator` / `typescript-jsdoc-generator` / `java-javadoc-generator` / `csharp-xml-doc-generator` skills when a single-language deep pass is needed.

> Removed 2026-09: per-language docstring syntax catalogs with annotated examples (PEP 257 classes/functions, Javadoc tags, JSDoc tags, XML tags), full before/after documentation sessions, common-mistake galleries — each language's docstring spec is model-known; kept the style-matching rule and the coverage discipline.
