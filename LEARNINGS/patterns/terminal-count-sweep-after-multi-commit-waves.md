# Pattern: terminal count sweep after multi-commit count-change waves

Updating count literals inside each consolidation commit guarantees the final
commit's count differs from intermediate ones unless a terminal sweep
re-greps EVERY surface (README:217 held 121 after the 121->119 sweep fixed
5/76/101 — the exact count-restating-surfaces recurrence). In multi-commit
count-change waves: enumerate all count surfaces up front, update literals
once in the exit-gate commit, and grep-verify each surface in the done-when.
