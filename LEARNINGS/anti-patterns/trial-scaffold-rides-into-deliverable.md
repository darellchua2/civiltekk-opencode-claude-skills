# Trial scaffold rides into the deliverable

- **Category**: anti-patterns
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-26
- **Summary**: Proof-of-mechanism scratch edits must not ride into the deliverable branch — #582's /run-plan-v2 zero-Task trial committed its scaffold docs line (3796e8c) as permanent content in `docs/subagent-portability-contract.md:43`, which then duplicated #583's authoritative copilot-destinations note and added an unverified "both load in VS Code" claim. **Rule:** trial commits prove the mechanism, then get reverted before the deliverable PR; if a trial edit is genuinely worth keeping, re-land it deliberately (correct section, verified claims) as its own change.
