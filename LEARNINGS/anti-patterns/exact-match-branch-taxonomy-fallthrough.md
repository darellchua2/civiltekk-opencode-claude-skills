# Exact-match branch lists in agent-facing classifiers fall through on variants

- **Category**: anti-pattern
- **Confidence**: high
- **Scope**: project
- **Added**: 2026-09-21 (#519 code review)

## Symptom

A classifier rule enumerates long-lived branches exactly (`develop`,
`release/*`) and sends everything else to a default arm. Plausible variants —
bare `release`, `development`, case differences (`Main`, `DEV`) — fall through
to the default and recreate the exact incident the classifier exists to
prevent (#55/#72 squash promotions).

## Cause

Enumerations read as "examples of the class" to humans but execute as exact
string matches. The gap between the two is invisible until an unlisted
variant ships.

## Fix

Pair every branch enumeration with: (1) the missing obvious siblings
(`release`, `development` alongside `develop`/`release/*`); (2) an explicit
matching statement ("exact and case-sensitive"); (3) a fall-through heuristic
for the residue — "environment-shaped or release-lane name not listed →
treat as long-lived (the harm asymmetry favors the safe arm) or ask".

## Evidence

#519 code review (2026-09-21): head-class classifier lists in
`skills/pr-merge-workflow-skill/SKILL.md` and
`skills/semantic-release-convention-skill/SKILL.md` §4 both missed bare
`release` and `development`; fixed in the same change.

Related: `conventions/merge-method-by-head-branch-class.md`.
