# Add-a-skill deploy completion set

- **Category**: convention
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-10-01
- **Ticket**: #654

## Rule

Adding one skill to this repo touches FIVE surfaces; all five before the run is done:

1. `skills/<name>/` tree (SKILL.md frontmatter contract: name = dir, category)
2. `installer/registry.json` — regenerated via `node installer/build-registry.mjs` (drift-guarded by `--check` in CI)
3. `deploy/opencode.json` — an `{"action":"skill","resource":"<name>","effect":"allow"}` rule; `deploy/skill-profiles.json` lean entries MUST be a subset of these allows (test: tests/skill_profiles.bats #2) and `apply-skill-profile.mjs` FAILS CLOSED at deploy time when the allow is missing ("Skill-profile application failed (exit 1)" cascades into SKILLS_ONLY/headless/plan-executor test failures)
4. `deploy/skill-profiles.json` — lean array iff primary-visible (test asserts lean count literal; bump it with the array)
5. `README.md` — count literals (5-6 spots, no test enforces them; sweep mechanically) + Skill Categories row

## Evidence

#654 gate run 2026-10-01: lean added without the allow rule -> full-suite full gate caught 7 failures across 5 files, all rooted in the missing allow; fix was one JSON rule + two test count literals.
