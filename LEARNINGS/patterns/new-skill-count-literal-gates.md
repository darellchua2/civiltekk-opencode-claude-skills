## Pattern: New-skill addition — count-literal consumer classes beyond the obvious surfaces

**Context**: PLAN-404 review (new `gh-cli-setup-skill`). The obvious sync surfaces (registry rebuild, lean array, full-profile allow, README count+row) were planned; CI still would have gone red twice.
**Pattern**: A skill-count-changing change sweeps SIX consumer classes past the obvious ones:
1. **Tests hardcoding profile sizes** — `tests/skill_profiles.bats` pins the lean count as literal arithmetic (`[ "$count" -eq 47 ]` :26-29, expected-string `"47 deny-ok non-skill-ok"` :64, header comment :5-8); every lean addition must bump them in the same PR.
2. **Tests gating README literals against disk** — `tests/test_markitdown_skill.bats:99-105` greps `[0-9]+ skill director(y|ies)` from BOTH `README.md` (first match = :15 tree comment) and `opencode_app/README.md` (:30) and compares to disk count.
3. **Docker README count literal** — `opencode_app/README.md:30` ("149 skill directories") is a sync surface the ticket's own list omits; repo AGENTS.md sync table includes it.
4. **Hand-maintained doc counts** — README.md :250, :566 (`<!-- count: hand-maintained -->`), :397 ("105 allows" / "46 primary-visible"), :409, :570 running-total narrative.
5. **Subagent frontmatter skill-allow rules** — any skill a DELEGATED flow must load needs an allow rule in the executing agent's frontmatter (`pr-workflow-subagent.md:47-75`, `repo-ops-specialist-subagent.md`); a lean slot only serves the primary.
6. **Deploy-script comment literals** — `deploy/setup.sh` (search-anchor: `run_skill_profile` header comments) hardcodes "N primary-visible skills" / "N-allow allowlist" in prose comments above the profile functions (counts auto-derive functionally; the comments drift; line numbers drift too — search the anchors, don't trust cited lines). Missed by PLAN-404 rev 2 — caught at code review.
**Rationale**: Same failure mode as frontmatter-shape-change-blast-radius: literal assertions and doc literals are invisible to "who references this file" sweeps; they fail at full-suite time (release.yml runs every tests/*.bats, :66-69).
**Verification**: `grep -rnE '\-eq 4[0-9]|"[0-9]+ deny-ok' tests/` + `grep -rn "skill director" README.md opencode_app/README.md tests/` + `grep -rnE '[0-9]+ (primary-visible|allow)' deploy/setup.sh` before sign-off on any skill add/remove. When sweeping already-stale hand-maintained literals (README.md:397 said 105/46 while disk was 106/47), derive target values from current disk + delta — never from the stale doc's own numbers (PLAN-404 rev 2 encoded 106 instead of the correct 107 this way).
**Confidence**: 0.95
**Scope**: project
**Date**: 2026-09-19

**Evidence**: PLAN-404 review — skill_profiles.bats 47-literal and opencode_app/README.md:30 both unowned by any phase; caught at plan review, not CI.
