# Steps appended to one build_plan branch vanish when main rebuilds the plan

- **Category**: anti-pattern
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #474 (review round 1)

## Symptom

The #474 load-preset step was appended only in build_plan's full branch, but
main rebuilds the plan after the headless no-TTY default flips SKILLS_ONLY —
the rebuild re-derives steps from flags alone, so `--preset foo` was silently
ignored on headless runs.

## Rule

Any conditionally-appended side-step must be added in EVERY branch it applies
to (full, quick, skills-only, models-only), because the menu/headless paths
rebuild the plan; or main must warn loudly when a requested side-step was
dropped by the rebuild.
