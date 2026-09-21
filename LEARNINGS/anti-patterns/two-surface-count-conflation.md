# Two artifact surfaces, one count vocabulary — every count names its surface

**Category**: anti-pattern
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-20

## Anti-pattern

When a repo ships two surfaces of the same artifact kind (root `skills/` =
deployable; `opencode_app/.opencode/skills/` = Docker-app project surface),
any count, guard, or derivation computed against ONE surface misclassifies
everything that lives on the other — and the error reads as a defect in the
data ("phantom allow") rather than in the derivation.

## Context

Both misses in the 2026-09-20 permission session were single-surface
derivations:

1. #481 plan: the reviewer-skill delta was computed against lean only
   (union−lean = 26) and applied to BOTH files — the full profile already
   shipped 23 of them (union−full = 3). Subset guards passed green over the
   would-be duplicates (`delta-derived-from-single-surface.md`).
2. #481 code review: flagged `github-runners-setup-skill` as a phantom
   allow because it had no root `skills/` dir — it lives on the app surface
   (#361). Corrected in #486's investigation.

## Fix

- Guards validate against the UNION of surfaces, filtered by artifact
  marker (`SKILL.md` presence — raw readdir counts `skills/_archived`).
- Disjointness asserted too: a same-named dir on both surfaces shadows
  ambiguously in the Docker app.
- Counts are surface-explicit at current-state sites: "106 rules = 105
  deployable + 1 app-scoped". Convention: DATED narratives keep their
  period-true counts (falsifying history is the mirror error — see
  `partial-record-refresh-contradicts-itself.md`); current-state claims
  carry the qualifier inline next to the number.
- Sweeps for a count include the docs-of-record dirs that cite it
  (`count-sweeps-include-docs-of-record.md`).

## Evidence

#486: union guard + negative fixture added to `tests/skill_profiles.bats`;
six current-state count sites annotated; decision recorded in
`decisions/app-scoped-skill-surface.md`.

Related: `anti-patterns/delta-derived-from-single-surface.md` (the family
parent), `patterns/count-sweeps-include-docs-of-record.md`,
`anti-patterns/partial-record-refresh-contradicts-itself.md`,
`decisions/app-scoped-skill-surface.md`.

**Evidence (2026-09-21, #506):** a single regenerated index entry carried heading "shipped 148, lean profile 46" above a Summary stating 146/106/70/36 — same entry, two count surfaces, caught at code review; headings are the grep surface and must derive from the same disk pass as the body.
