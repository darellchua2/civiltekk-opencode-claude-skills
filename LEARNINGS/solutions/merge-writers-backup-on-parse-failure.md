# Merge writers must back up unparseable user JSON, never reset to {}

- **Category**: solution
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #471 (review round 1)

## Context

`register_provider_auth` merges one key into the user's auth.json. The
inherited pattern reset `auth = {}` on any parse failure (FileNotFoundError
AND ValueError alike) — so a half-written auth.json got replaced by a
one-entry file, silently destroying every stored provider key.

## Rule

For merge-into-user-JSON writers, distinguish MISSING (start fresh) from
CORRUPT (back up via `os.replace(f, f + ".corrupt.bak")`, warn on stderr,
then start fresh). Add `os.chmod(f, 0o600)` when the file holds secrets —
default umask leaves API keys group/world-readable.
