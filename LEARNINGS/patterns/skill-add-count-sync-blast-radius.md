# skill-add count sync blast radius — 8 surfaces, number-keyed ones hide from name-keyed sweeps

- **Category**: pattern
- **Confidence**: 0.95
- **Scope**: project
- **Added**: 2026-09-19 (#402 architecture review)

## Rule

Adding one skill touches EIGHT count surfaces, and they fail in two classes:

1. **Name-keyed** (a `grep <skill-name>` finds them): README category row
   (~598), README Subagents delegation row (~641), README preset-table row
   (~266, resolver-derived but the text still needs the edit),
   `installer/presets/pack-*.json` (array + description), and
   `installer/registry.json` (rebuild per BT-157 — rides the SAME commit as
   the frontmatter change; `tests/init.bats` + `tests/deploy_delegate.bats`
   enforce registry-vs-disk per commit).
2. **Number-keyed** (a bare count no name-grep can flag): the five
   hand-maintained totals — README.md ~15 (tree), ~250 (init subset),
   ~409 (profile-immune), ~566 (modularization), opencode_app/README.md ~30
   (Docker). Two carry `<!-- count: hand-maintained — sync on skill add
   (BT-157) -->`; the rest are bare. Sweep with
   `grep -rnE "orchestrat(es|ing) 14|149 skill"` — include the verb-form
   alternation, "orchestrates 14" vs "orchestrating 14".

Dynamic surfaces are safe by design: banner `$(count_skills ...)`,
`test_count_drift.bats` (disk-vs-disk), `skill_profiles.bats` (lean subset).
Also append the migration changelog chain (README ~570) — house precedent
appends one `Post-<ref>: +1 <skill> → **N**.` entry per addition.

## Evidence

#402 (feat/402, 2026-09-19): cad-redraw-skill add — 3 of 5 totals initially
unowned in PLAN-402; architecture review caught them; final gates used the
number+verb-keyed sweep (clean) + `build-registry.mjs --check` (green).

Related: `conventions/task-delegate-permission-sync.md` (same
multi-surface discipline for permission.task edges),
`solutions/docs-registry-is-build-site-artifact.md`.
