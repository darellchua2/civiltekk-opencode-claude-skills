# A derived summary tuple must be self-consistent — arithmetic and derivation semantics

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #506 (arch review BLOCK-2 + Mode R round 1)

## Symptom

PLAN-506's AC stated "146 shipped / 107 full allows / 70 lean / 36 hidden vs full". The tuple fails its own arithmetic (107−70=37, not 36) because the derivation command (`grep -c '"action": "skill"'`) counts the deny-all rule at `opencode_app/opencode.json:29-31` — raw rule count 107, allow-effect rules 106, and only 106−70=36 matches the AC's own "hidden" claim. Two count surfaces, one vocabulary — the `two-surface-count-conflation` genus inside a single entry.

## Rule

Before hard-coding derived counts into an AC or summary: (a) the derivation command must match the claim's semantics — count `"effect": "allow"` within the rule family (`grep -A3 '"action": "skill"' … | grep -c '"effect": "allow"'`), not the rule key; (b) the tuple must pass its own arithmetic; (c) check for members that live on another surface (`github-runners-setup-skill` is the app-scoped allow, absent from root `skills/`) and annotate rather than silently drop them.

**Evidence**: corrected tuple 146/106/70/36 with the app-scoped annotation; recorded in PLAN-506 Technical Notes and the rebuilt `_index.md` entry.
