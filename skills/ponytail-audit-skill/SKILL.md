---
name: ponytail-audit-skill
description: "Whole-repo over-engineering audit — ranked delete/stdlib/native/yagni/shrink findings with net removable count. One-shot report, applies nothing. Triggers: audit for over-engineering, find bloat, what can I delete."
license: MIT
compatibility: opencode
category: Code Quality
---

<!--
  Vendored from @dietrichgebert/ponytail v4.8.4 (MIT)
  Source: https://github.com/DietrichGebert/ponytail/blob/v4.8.4/skills/ponytail-audit/SKILL.md
  Pinned at tag v4.8.4. Re-vendor deliberately on upstream bumps.
  See ../../plugins/ATTRIBUTION.md for license and attribution.
-->

ponytail-review-skill, repo-wide. Scan the whole tree instead of a diff. Rank
findings biggest cut first.

## Tags

Same as ponytail-review-skill:

- `delete:` dead code, unused flexibility, speculative feature. Replacement: nothing.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `yagni:` abstraction with one implementation, config nobody sets, layer with one caller.
- `shrink:` same logic, fewer lines. Show the shorter form.

## Hunt

Deps the stdlib or platform already ships, single-implementation interfaces,
factories with one product, wrappers that only delegate, files exporting one
thing, dead flags and config, hand-rolled stdlib.

## Output

One line per finding, ranked: `<tag> <what to cut>. <replacement>. [path]`.
End with `net: -<N> lines, -<M> deps possible.` Nothing to cut: `Lean already. Ship.`

## Boundaries

Scope: over-engineering and complexity only. Correctness bugs, security holes,
and performance are explicitly out of scope. Route them to a normal review
pass. Lists findings, applies nothing. One-shot.
"stop ponytail-audit" or "normal mode" to revert.
