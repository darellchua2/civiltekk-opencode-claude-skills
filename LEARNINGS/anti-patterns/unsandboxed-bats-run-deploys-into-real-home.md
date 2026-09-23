# Tests that execute setup.sh end-to-end need a mktemp HOME, not just source-pins

- **Category**: anti-pattern
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #474 (review round 1)

## Symptom

`run bash "$SETUP_SH" -A` in test_subcommands.bats ran unsandboxed: even a
"no-op" flag falls through to the headless skills-only default, which performs
a real deploy into the developer's live ~/.config/opencode — including
cleanup_old_backups pruning genuine backups to 5.

## Rule

Any test invoking setup.sh end-to-end (not merely sourcing a function) must
export a mktemp HOME first. Source-pin tests are safe; execution tests are not.

## Evidence

- #537 (review round 1): the new `--list-items` tests ran the script with the
  developer's real HOME — `init_logging` (setup.sh:387-398) mkdirs/touches
  `~/.opencode-setup.log` on every run. Neighboring tests all sandboxed;
  the newest ones were the outlier. Fixed with `export HOME=mktemp` in both.
