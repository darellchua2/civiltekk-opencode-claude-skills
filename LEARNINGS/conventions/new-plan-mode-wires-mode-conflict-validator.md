# New ONLY-mode flag must extend validate_mode_conflicts in both lists

- **Category**: convention
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #472 (review round 1)

## Rule

Adding an ONLY-mode flag to setup.sh requires ALL of: defaults block entry,
parser arm, conflict validator registration in BOTH lists (modes exclusivity
+ enable-pack packless), build_plan branch, mode completion case, both help
surfaces, wiring pins. Missing the validator lets the build_plan elif chain
silently swallow any combined mode (`--check-catalog --skills-only` ran only
the check, exit 0) — the exact silent no-op the #470 validator exists to
prevent.
