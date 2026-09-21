# Dead functions kept alive by their own tests

- **Category**: anti-pattern
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #474 (review round 1)

## Symptom

deploy_skills_only had zero production callers after #470's plan model (the
build_plan skills-only branch calls the individual steps directly), but its
parity tests still passed — they pinned the wrapper, not the live path. The
de-bloat ticket nearly shipped a corpse guarded by green tests.

## Rule

When extracting plan steps, re-point function-level pins at the live step list
in the SAME change. A test that only executes a dead wrapper proves nothing
about the path users take.
