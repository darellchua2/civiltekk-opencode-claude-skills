# Advisory visibility checks must not run at full-catalog scale

- **Category**: anti-pattern
- **Confidence**: 0.9
- **Scope**: project
- **Evidence**: installer/init.mjs:701 (`add --all` path via deploy_content) and :983 (`update` runs it over ALL manifest entries).

checkStrictAllowlist warns per hidden skill with a JSON rule suggestion. Against the deployed default lean profile (deny-all + 46 allows of ~148 shipped skills) every `setup.sh --yes` redeploy and every `npx update` prints a 100+ line warning whose advice (paste allow rules / --permit) contradicts the lean-profile design — the deploy re-applies lean right after. Gate per-item advisory checks on partial selections; for full-catalog selections skip them or collapse to a one-line count. Found in #379 review.
