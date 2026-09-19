# Pattern: skill-dir consolidation trips count literals everywhere

Consolidating/removing skill dirs breaks literal-count assertions far beyond the registry — and `package.json` scripts is `{}` in this repo, so plans must name gates explicitly.

Sweep before finishing any skill-count change:

```bash
grep -rn 'skill director\|lean has exactly\|deny-ok\|primary-visible\|allows)' tests/ deploy/ README.md opencode_app/README.md
```

Surfaces that bit in practice (#407, #408): `tests/skill_profiles.bats` (pinned lean count at SIX literal sites: 2 header comments, 2 test names, `-eq` assertion, `"N deny-ok non-skill-ok"` output string); `tests/test_markitdown_skill.bats:95-102` (greps skill-directory counts across BOTH root `README.md` and `opencode_app/README.md`); prose literals in `deploy/setup.sh`, `deploy/setup.ps1`, `README.md` ("N primary-visible skills", "(N allows)") — no bats guard covers the prose, so CI stays green while docs lie.

Also: `package.json` scripts is `{}` — a plan that says "discover gates from package.json" discovers zero commands. Name `bats tests/` + `node installer/build-registry.mjs` explicitly (PLAN-381 precedent).

Recurrences: PLAN-404 rev 2 (caught at review), #407, #408 — third strike prompted this note. Evidence: `tests/skill_profiles.bats` 47→45→44 history; `deploy/setup.sh` "48 primary-visible" stale until #408.
