# Verified-stamp docs must cite every actionable claim

- **Category**: convention
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-15
- **Evidence**: MIGRATION.md:226-228, 258, 263-265 (feat/385 review, issue #385)

In any doc section stamped "Verified against <source>", every actionable
command, env var, and config field path must trace to that source — or carry
its own citation or explicit inference/unverified label at EACH occurrence,
not only where the claim first drives a recommendation. #385 review: the
cache-inference was labeled in the ranked-levers list but restated as bare
fact under "Why v2 dropped pruning"; `OPENCODE_DISABLE_AUTOCOMPACT` and
`opencode stats` shipped uncited (official kill switch is
`compaction.auto: false`); the v2 warming key is top-level `warming`, not
`session.warming`. Sibling: `doc-claims-match-plugin-defaults.md`.
