# Canonical-form guards need regex, not case-globs

- **Category**: solutions
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-22
- **Ticket**: #515

## Symptom

The portability guard's canonical-form check was written as shell case-globs
(`'  os: "'*'"'`), which can only validate quote-wrapping — `os: "Linux"`,
`os: "linux,macos"`, and `harness: "opencode, Claude Code"` all pass while
violating the advertised `"[a-z0-9]+(, [a-z0-9]+)*"` form. Masked on the first
run because the check skipped (zero real declarations at the time); only
seeded fixtures exercised it.

## Fix / Rule

Case-globs cannot express character classes. Implement advertised-form checks
as a regex inversion: select the target lines, then `rg -v` the canonical
pattern and fail on any output. Extract the shared primitive (frontmatter slice
via `awk 'NR==1 && /^---$/{next} /^---$/{exit} {print}'`) once and reuse it
across checks instead of per-check `head -n N` heuristics that break on long
frontmatter. Verify with a seed that violates the FORM (not just the wrapper).
