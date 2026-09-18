# Anti-pattern: a validator must never crash on the input it exists to reject

**Context**: #402 review — `spec_to_dxf.py` parallel/aligned constraint path called `math.dist` on unguarded `_point()` results and divided by line length without a zero guard; an invalid spec (malformed or zero-length line geometry referenced by a `parallel` constraint) raised TypeError/ZeroDivisionError before the validation report was emitted, breaking the "exit 1 + report, no traceback" contract on the tool's primary failure path.
**Pattern**: In every validator, either skip dependent checks when schema errors already exist, or guard every extracted value (None checks, zero-division) and downgrade to a named skip-with-warning. Corollary: a constraint/reference check that silently no-ops when under-specified (too few refs) is a false-confidence bug — emit a warning.
**Rationale**: The expected failure path of a validator is invalid input; a traceback there means the user never gets the named errors the tool promised.
**Alternatives Considered**: Wrap main() in a blanket try/except — wrong, it hides real bugs; guard at the point of use instead.
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-19
