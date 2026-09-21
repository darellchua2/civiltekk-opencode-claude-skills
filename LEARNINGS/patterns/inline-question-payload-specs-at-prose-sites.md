## Inline question-payload specs at prose-only prompt sites

- **Category**: pattern
- **File**: `patterns/inline-question-payload-specs-at-prose-sites.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: embed verbatim `question`-tool payload JSON (all four levels: `questions[]` wrapper, `question`+`header`+`multiple:false`, `options[]` with `label` AND `description`) at every prose-only prompt site — #448's audit found 7/1158 schema failures, all missing-required-field from freehand construction; enumerate every placeholder the model must instantiate and cap option lists so instantiation + decline stays within the 2-4 option hygiene bound; duplication across skills is intentional per #437, never extract it (#504)
- **Date**: 2026-09-21
