# Docstring formats — route `docstring-formats` (values)

Values file for `civiltekk-documentation-inline-skill` decision-tree step 3.
Carried from docstring-generator-skill (#603 consolidation); the METHOD
(skip rules, scope bounds, output contract) lives in the host SKILL.md.

## Per-language formats

- **Python:** PEP 257, with Google / NumPy / Sphinx style options
- **Java:** Javadoc with proper tags (`@param`, `@return`, `@throws`)
- **TypeScript/JavaScript:** JSDoc with `@type`, `@param`, `@return` tags
  (TSDoc where the repo uses `.ts`-native tooling)
- **C#:** XML documentation with `<summary>`, `<param>`, `<returns>` tags

Match each language's official conventions AND the repo's existing docstring
style. Each language's full docstring syntax spec is model-known — no syntax
catalog here; the rules below are the discipline that makes generation safe.

## When this route applies

Documenting public APIs, libraries, or onboarding-heavy modules; converting
docstrings between styles (Google ↔ NumPy, JSDoc ↔ TSDoc); satisfying
doc-coverage CI (e.g. docstring lint rules).

## House rules

- **Detect before generating:** scan the target file/package for an existing
  docstring style (Google vs NumPy in Python; `@param` vs `{param}` in JS)
  and MATCH it — mixed styles inside one module are worse than none.
- Public symbols get docstrings; trivial private helpers don't (PEP 257's own
  rule).
- **Document contracts, not implementations:** parameters/returns/raises (or
  `@throws`/`<exception>`), side effects, and units — never restate what the
  signature already says.

## Provenance

Removed 2026-09 (scope note carried from the absorbed skill): per-language
docstring syntax catalogs with annotated examples (PEP 257 classes/functions,
Javadoc tags, JSDoc tags, XML tags), full before/after documentation
sessions, common-mistake galleries — each language's docstring spec is
model-known; the style-matching rule and the coverage discipline were kept.
