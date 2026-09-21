## Pattern: token-enumeration AC greps go green while concept mentions survive

**Context**: #507 — the acceptance grep enumerated the five removed v1 tool tokens (`pty_spawn|pty_read|pty_write|pty_kill|notifyOnExit`) and passed, while `skills/plan-execution-skill/SKILL.md:83` still taught the concept in prose ("PTY loop"); only the code review's concept-level sweep caught it.

**Pattern**: vocabulary-migration ACs must grep the CONCEPT word case-insensitively with word boundaries on BOTH sides (`grep -rinE '\bpty\b'`), not the retired tool-name list. Bare `pty_` also false-positives on `empty_*` identifiers — boundaries both sides are required. Third false-green sibling after `case-sensitive-grep-gates-false-green` and `literal-only-path-sweep-misses-variable-indirection`.

**Alternatives Considered**: trusting the token list as "what agents invoke" — rejected: prose like "PTY loop" still teaches the removed capability and re-propagates it on every plan-execution run.
