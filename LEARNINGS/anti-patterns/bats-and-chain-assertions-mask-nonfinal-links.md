# bats && -chained assertions only enforce the final link

- **Category**: anti-pattern
- **Confidence**: 0.95
- **Scope**: project
- **Evidence**: tests/test_jsonc_sibling.bats:33,37 (#432 review) — `[ a ] && [ b ] && [ c ]` under bats errexit passes with a false `a` (empirically verified 2026-09-19); only the link after the last `&&` aborts the test. Recurred 2026-09-20: tests/test_plan_executor.bats:176-177 (#470 review) — a 9-link ordering pin in the ticket's primary end-to-end trace enforced only the final `-lt`; written one day after this entry existed.

bats runs test bodies under `set -e`, but bash errexit exempts every command inside a `&&`/`||` list except the final one — an ordering pin `assert1 && assert2 && assert3` therefore enforces only assert3. Put each `[ ]` on its own line (bare mid-test assertions are fail-fast, per `bats-errexit-loop-failfast`), and make grep anchors unique to the target site: `if (Test-Path $ConfigFile) {` matched a pre-rollback backup block ~1000 lines before the real prompt (setup.ps1:644 vs 1728) and the pin stayed green. Found in #432 review.
