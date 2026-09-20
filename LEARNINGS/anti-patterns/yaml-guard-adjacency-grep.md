# Anti-pattern: YAML guard via adjacency grep assumes key order and quoting

`grep -A1 "resource: X" | grep "effect: allow"` guards miss effect-before-resource ordering, unquoted resource values, and broader-glob allows. Scan per-rule blocks bounded by `- action:` and test action+effect flags at block close — see `tests/test_reviewer_no_writes.bats` (#445 review).
