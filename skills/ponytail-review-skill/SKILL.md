---
name: ponytail-review-skill
description: "Diff-only over-engineering review — flag reinvented stdlib, unneeded deps, speculative abstractions with concrete replacements. Triggers: over-engineered diff, simplify this change, review for bloat."
license: MIT
compatibility: opencode
category: Code Quality
---

<!--
  Vendored from @dietrichgebert/ponytail v4.8.4 (MIT)
  Source: https://github.com/DietrichGebert/ponytail/blob/v4.8.4/skills/ponytail-review/SKILL.md
  Pinned at tag v4.8.4. Re-vendor deliberately on upstream bumps.
  See ../../plugins/ATTRIBUTION.md for license and attribution.
-->

Review diffs for unnecessary complexity. One line per finding: location, what
to cut, what replaces it. The diff's best outcome is getting shorter.

## Format

`L<line>: <tag> <what>. <replacement>.`, or `<file>:L<line>: ...` for
multi-file diffs.

Tags:

- `delete:` dead code, unused flexibility, speculative feature. Replacement: nothing.
- `stdlib:` hand-rolled thing the standard library ships. Name the function.
- `native:` dependency or code doing what the platform already does. Name the feature.
- `yagni:` abstraction with one implementation, config nobody sets, layer with one caller.
- `shrink:` same logic, fewer lines. Show the shorter form.

## Examples

❌ "This EmailValidator class might be more complex than necessary, have you
considered whether all these validation rules are needed at this stage?"

✅ `L12-38: stdlib: 27-line validator class. "@" in email, 1 line, real validation is the confirmation mail.`

✅ `L4: native: moment.js imported for one format call. Intl.DateTimeFormat, 0 deps.`

✅ `repo.py:L88: yagni: AbstractRepository with one implementation. Inline it until a second one exists.`

✅ `L52-71: delete: retry wrapper around an idempotent local call. Nothing replaces it.`

✅ `L30-44: shrink: manual loop builds dict. dict(zip(keys, values)), 1 line.`

## Scoring

End with the only metric that matters: `net: -<N> lines possible.`

If there is nothing to cut, say `Lean already. Ship.` and stop.

## Boundaries

Scope: over-engineering and complexity only. Correctness bugs, security holes,
and performance are explicitly out of scope. Route them to a normal review
pass, not this one. A single smoke test or `assert`-based
self-check is the ponytail minimum, not bloat, never flag it for deletion.
Does not apply the fixes, only lists them.
"stop ponytail-review" or "normal mode": revert to verbose review style.
