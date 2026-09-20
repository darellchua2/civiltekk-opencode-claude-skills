# Delta derived from a single surface duplicates entries in the other

**Category**: anti-pattern
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-20

## Anti-pattern

When one change set must land in two arrays with different memberships
(shipped full allowlist vs lean profile), computing the delta against only
ONE target silently duplicates entries in the other — and Set-based guards
(subset tests, fail-closed typo checks) pass green over the duplicates.

## Context

#481 plan review: the reviewer skill union minus lean = 26, but minus the
shipped full allowlist = 3 (23 already ship). The drafted plan applied the
26-delta to BOTH files — `skill_profiles.bats` subset test and
`apply-skill-profile.mjs`'s typo guard would both stay green while
`opencode_app/opencode.json` grew 23 duplicate allow rules and every
published count lied.

## Fix

- Compute and assert the delta against EACH target surface
  (`union − lean`, `union − full`) before writing either file.
- Add a duplicate-resource check to the done-when of any allowlist append.
- Remember the guards: subset tests prove lean ⊆ full, NOT full-internal
  uniqueness — duplicates need their own assertion.

Related: `anti-patterns/profile-membership-breaks-count-arithmetic.md`,
`patterns/fail-closed-guard-couples-cross-file-edits.md`.
