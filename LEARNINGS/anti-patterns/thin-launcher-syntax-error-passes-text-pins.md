# A thin launcher with a syntax error passes every textual delegation pin

- **Category**: anti-pattern
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #474 (review round 1, BLOCK)

## Symptom

The #474 ps1 rewrite left a stray `}` plus a duplicated tail (an edit artifact
of a partial-block replacement). The file was unparseable PowerShell — it
would have died before param() binding on every Windows invocation — yet all
486 bats pins stayed green, because every ps1 pin is a textual grep and CI has
no pwsh to parse with.

## Rule

When a runtime is absent from CI, a rewrite of a file in that language needs a
structural proxy before merge: a brace/quote balance check outside strings and
comments, or `pwsh -NoParse` parse when a host exists. Textual delegation pins
cannot catch a file that will not parse.
