# `${XDG_DATA_HOME:-…}` punches through HOME-only test sandboxes

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #471 (review round 1)

## Symptom

Credential-seeding tests sandboxed `HOME` into a temp dir, yet on machines
exporting `XDG_DATA_HOME` they wrote `new-provider` entries into the
developer's REAL `~/.local/share/opencode/auth.json` (setup.sh resolves the
auth path via `${XDG_DATA_HOME:-$HOME/.local/share}`), and assertions read
the untouched sandbox copy — red per-environment, not per-change.

## Rule

When code resolves paths as `${XDG_*:-$HOME/…}`, sandboxing HOME alone is
not sandboxing: `unset XDG_DATA_HOME XDG_CONFIG_HOME` inside the test's
bash -c (after the HOME export). Same family as
bats-source-sandbox-clobbered-globals — any env var the code consults before
the sandboxed one is an unsandboxed channel.
