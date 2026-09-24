# Re-pointing a provenance citation to a different repo silently invalidates the license claim

**Category**: anti-pattern
**Confidence**: 0.85
**Scope**: project
**Date**: 2026-09-24

## Anti-pattern

Mirrors of the same content live under different licenses. #546's provenance
comment cited `anthropics/claude-code` `plugins/frontend-design` while keeping
the "Apache-2.0" label from the prior citation — but claude-code's LICENSE.md
is all-rights-reserved (Commercial Terms); the Apache-2.0 grant for that
content exists only in `anthropics/skills` `skills/frontend-design/` (per-skill
`LICENSE.txt`). Swapping the cited repo without re-verifying its license shipped
a false attribution on a redistributable artifact.

## Rule

When a provenance comment changes repos, re-verify the license against the
newly cited repo (GitHub API `license` field + LICENSE file), exactly as for a
new source. Prefer citing the per-skill license file over a repo README's
"many skills are Apache 2.0" blanket — repos like `anthropics/skills` carve out
doc skills. Keep the "adapted from" attribution wording (Apache-2.0 §4(c)).

Related: `plan-element-lists-drop-unnamed-upstream-sections` (same root cause:
element lists written from memory, not re-verified upstream).
