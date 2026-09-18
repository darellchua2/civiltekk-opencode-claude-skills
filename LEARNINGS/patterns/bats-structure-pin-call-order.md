# bats structure pin: grep line-ordering test for shell call ordering

- **Category**: pattern
- **Confidence**: 0.9
- **Scope**: project
- **Evidence**: tests/deploy_delegate.bats:39-53 (pins `run_migration` < `deploy_content` < `RESOLVER_CONFIG_ONLY=true run_resolver` plus a negative grep that the old rsync loop is gone).

When a refactor's correctness rests on call ORDER inside a 4k-line shell script (lift must see pre-overwrite agents; CLI owns agent files before config-only resolve), pin it with a bats test: `grep -n` each anchor (exact indentation to disambiguate call sites), assert line numbers ascending, and negatively grep the removed pattern. Cheap, review-anchored, and survives future edits. Established in #379 (replicates the ARCH pin technique).
