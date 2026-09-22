# Portability warnings live in the install writers, not the resolver

- **Category**: decision
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #514

## Decision

Cross-target/platform portability warnings push into the existing `sel.warnings`
bus at exactly two sites, AFTER effective-target resolution:
`writeUserScopeInstall` (harness warn iff `"opencode" ∉ activeTargets(target)` —
so `--target both` never warns) and `writeInstall` (after `--project` target
degradation, which would otherwise emit spurious warnings).

## Why not the alternatives

- `resolveSelection` is a target-free pure function shared with the deploy
  picker (deploy-plan-items.mjs) and unit tests — threading target through it
  ripples for no benefit.
- `cmdAdd`'s early paths that lack target context would silently skip the check.
- The `--all` catalog path routes through `writeUserScopeInstall`, so it
  inherits the warnings for free.
