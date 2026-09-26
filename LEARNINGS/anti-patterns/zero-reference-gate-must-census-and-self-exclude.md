# A zero-reference gate must census where the string lives and exclude itself

- **Category**: anti-pattern
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #506 (PLAN-506 arch review, BLOCK-1); evidence added #585

## Symptom

A "zero references to the removed slugs" gate grepped only `--include="*.md" --include="*.bats" --include="*.mjs"`. It missed the two real consumers — `opencode_app/Dockerfile:63` (extensionless) and `opencode_app/docker-entrypoint.sh:132` (`*.sh`) — and it matched the PLAN document itself, which quotes the slugs it bans. The gate could never exit clean while simultaneously certifying a hole it existed to plug.

## Rule

Before writing a zero-reference gate, census where the string ACTUALLY appears (all file types — extensionless `Dockerfile`, `*.sh`, configs) and derive the include set from that census, never from the expected doc types. Then exclude legitimate use-mention surfaces: the plan/work-order documents that name their own deletion targets (same class as CHANGELOG) and generated registries. Same genus as `case-sensitive-grep-gates-false-green` and `guard-regex-quote-shape-mismatch` — new failure axes: include-filter blindness + self-match.

**Evidence**: PLAN-506 gate 6.1 as drafted; fixed form: `grep -rn "<slugs>" . --exclude-dir=.git --exclude-dir=node_modules | grep -v CHANGELOG | grep -v "installer/registry.json" | grep -v "PLANS/"`.

## Opposite polarity (#585, 2026-09-26)

Positive-list done-when gates self-fail the same way: PLAN-585 step 1.1's gate ("diff lists exactly README.md") omitted the riding `PLANS/PLAN-585.md` artifact that pipeline contract §6e puts on every branch, and only an explicit deviation note rescued it. Exempt `PLANS/PLAN-*.md` from exact-list gates at authoring time — census the gate's own artifacts before pinning the list.
