# Menu-case-to-flag extraction must re-derive the menu path's free preconditions

- **Category**: pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #466

## Symptom

Giving PeonPing (menu option 5) a `--peonping` flag would silently drop two
preconditions the menu path got for free: menu options run after main's
`check_dependencies` AND the network check. Copying only the case body
(`setup_peonping`) would have shipped a flag that fails differently offline.

## Rule

Extracting a menu case into a CLI flag: list what executed BEFORE the menu
in the interactive flow (dependency checks, network checks, header/logging),
decide explicitly which the flag re-adds and which it deliberately omits,
and record that decision in the block comment. The #466 flag re-added
check_dependencies but intentionally omitted the network check (matching
--quick's offline-tolerant precedent).
