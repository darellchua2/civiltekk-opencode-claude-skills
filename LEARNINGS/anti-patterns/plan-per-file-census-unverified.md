# PLAN per-file census claims must be derived from the tree

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #514

## Symptom

PLAN-514 step 1.1 asserted a per-file frontmatter split ("8 lack `metadata:`, 4
have it — one to verify") without a tree grep. Actual census: 6/6. Literal
execution would have created a duplicate `metadata:` YAML key in 2 skills —
and every current gate stays green on that mistake: `rg -l` counts files not
blocks, build-registry's hand-rolled parser silently merges duplicate map
markers (build-registry.mjs:143), and `--check` compares derived fields only.

## Fix / Rule

Any PLAN claim enumerating files-by-shape ("N have X, M lack X") must carry —
or be preceded by — a one-line grep census of the actual tree. Plan reviewers:
verify census numbers before approving; executors: re-run the census before the
first edit.
EOF
cat >> LEARNINGS/_index.md <<'EOF'

### PLAN per-file census claims must be derived from the tree

- **Category**: anti-pattern
- **File**: `anti-patterns/plan-per-file-census-unverified.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: a PLAN step's "N files have X, M lack X" split authored without a tree grep shipped a wrong 4/8 census that would have created duplicate `metadata:` keys invisible to every gate — derive enumerations from the tree, reviewers verify the numbers (#514 plan review)
- **Date**: 2026-09-22

### Portability warnings live in the install writers, not the resolver

- **Category**: decision
- **File**: `decisions/portability-warnings-in-writers-not-resolver.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: #514 warnings push into sel.warnings at the two writer sites AFTER effective-target resolution (writeUserScopeInstall via activeTargets — `both` never warns; writeInstall after --project degradation) — not in the target-free resolveSelection (shared with deploy picker + tests) and not in cmdAdd (--all bypasses target)
- **Date**: 2026-09-22
EOF
mkdir -p LEARNINGS/decisions && cat > LEARNINGS/decisions/portability-warnings-in-writers-not-resolver.md <<'EOF'
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
- `cmdAdd`'s `--all` path returns before any target context — a check there
  never fires for full-catalog installs.
EOF
echo OK