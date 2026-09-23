# By-reference docs mechanize no-duplication with sentinel greps

**Category**: patterns
**Confidence**: 0.8
**Scope**: project
**Date**: 2026-09-23

## Pattern

By-reference doc tickets (#539 CONTRIBUTING.md) mechanize their no-duplication AC:
sentinel greps for the copyable table-header rows (`| Key | Rule |`, `| Trigger | What to update |` absent from the new doc) plus a zero-`^|`-table-lines rule, a per-citation heading-existence grep in the source doc, and `test -f` for every file-level link. Prose-only "no copying" ACs are unenforceable at review time. Origin: PLAN-539 architecture review.
