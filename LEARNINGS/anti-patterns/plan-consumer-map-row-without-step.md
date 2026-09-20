# Anti-pattern: PLAN consumer-map row without an owning step

A Dependency & Consumer Map row that names a consumer but maps to no
implementation step is a silent coverage hole.

PLAN-487's map listed `opencode_app/README.md` as the Dockerfile's consumer
yet no Phase 1–5 step owned its rewrite (PLAN-487.md:27 vs :88-105 at review
time); the file carries the strongest privacy claims in the repo
(opencode_app/README.md:159) and a link into a directory the same PLAN
deletes. Caught by architecture review as a Major.

**Rule:** at plan review, walk every map row → at least one implementation
step. A row with zero owning steps is a Major finding.

- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
