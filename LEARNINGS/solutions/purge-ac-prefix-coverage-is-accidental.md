# Solution: Purge AC prefix coverage is accidental

A purge AC's grep alternation gates every removed id only if each id is either named or a prefix-sibling of a named pattern. #522's 3-alternative grep covered its 4th (flagged) id purely because the extension shared a string prefix with a named token; a differently-named extension id would slip the gate green. Purge ACs should list every removed id in the pattern explicitly, flagged extensions included.

**Confidence:** medium
**Scope:** project
**Evidence:** #522 plan review 2026-09-22 — AC `glm-4\.7-flash` alternation prefix-matches `glm-4.7-flashx` by luck, not design
**Date:** 2026-09-22
