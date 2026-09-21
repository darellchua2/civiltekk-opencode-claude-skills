# "Pre-verified repo facts" embedded in review briefs are claims, not evidence

- **Category**: anti-pattern
- **Confidence**: high
- **Scope**: project
- **Added**: 2026-09-21 (#519 plan review)

## Symptom

An orchestrator briefing a reviewer writes "grep-verified: no other skill
hardcodes X". The reviewer trusts the claim, the review passes, and a
contradicting file ships.

## Cause

The orchestrator's grep covered the wrong corpus or predates the relevant
edit; the claim then launders into every downstream decision as evidence.
#519: the brief asserted "no merge-method defaults elsewhere" while
`semantic-release-convention-skill` carried nine squash directives including
a governance MUST and an "Allow merge commits: No" settings recommendation —
caught only because the reviewer re-ran the grep.

## Fix

Treat orchestrator-embedded facts as claims: re-run the one grep before
relying on them, and phrase briefs as claims with the command that produced
them (`grep -rn '<pattern>' <corpus>` → "verify"), not as settled facts.

## Evidence

#519 plan review (2026-09-21): BLOCK 1 existed solely because the brief's
negative claim was wrong; the reviewer's independent grep of
`skills/semantic-release-convention-skill/SKILL.md` (:18, :126, :196-214,
:388, :401) found the contradiction before execution.
