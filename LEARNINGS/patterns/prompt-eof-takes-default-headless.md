# Prompt EOF takes the default — headless safety hinges on gate defaults

- **Category**: pattern
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #466

## Context

setup.sh's `prompt_user`/`prompt_yes_no` resolve EOF stdin (`read` with no
TTY) to the declared default (`${result:-$default_value}`) — they never hang
and never return junk. So the headless safety of any code path is decided
entirely by what each gate prompt's default IS.

## Rule

When giving a menu case a flag spelling (or adding any headless-reachable
path), audit its gate prompts' defaults: the action must happen iff the
default is the intended one. Worked example: bare headless `--peonping`
installs because "Install PeonPing?" defaults y, while "Reinstall?" defaults
n (keeps existing) — both correct by accident of the defaults, verified
during the #466 review. A prompt defaulting to skip would make the flag a
silent no-op headless.
