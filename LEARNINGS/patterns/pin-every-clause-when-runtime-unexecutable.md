# Pin every behavioral clause when the target runtime is unexecutable in CI

- **Category**: pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #465

## Context

`deploy/setup.ps1` cannot execute on Linux CI (no pwsh), so fixes to it are
verified by static pins only. The #465 dry-run fix had two behavioral clauses:
pass `--preview-dir` to the resolver AND clear the stale preview dir first.

## Rule

A multi-clause fix verified by static analysis gets one pin per clause, not
one pin per fix. Pinning only the first clause left the second silently
deletable — deleting the `Remove-Item` line kept all five tests green while
reintroducing exactly the stale-preview bug the bash twin's `rm -rf`
(setup.sh:3008) prevents.

## Application

After writing the pins, re-read the diff clause-by-clause and ask "which pin
fails if I delete this line?" — every changed behavioral line must have at
least one. The #465 review caught the missing stale-clear pin with exactly
this deletion test.
