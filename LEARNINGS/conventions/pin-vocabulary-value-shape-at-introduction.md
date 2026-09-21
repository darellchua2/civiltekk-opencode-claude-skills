# Pin vocabulary value shape at introduction

- **Category**: convention
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Ticket**: #510

## Symptom

#510's new §Portability contract showed `metadata.os: [linux, macos, windows]`
unquoted (a YAML flow sequence) while the frontmatter contract row two lines up
says `metadata` is an "opaque string map" and the PLAN called the values
"list-shaped strings" — three defensible spellings facing the downstream
implementers (#512–#514), each parsing differently under the repo's zero-dep
frontmatter parser (a bracketed value lands in registry.json as a literal
bracketed string; a block sequence forks the value type).

## Fix / Rule

Pin the exact value spelling (quoting included) in the same change that
introduces new frontmatter vocabulary. Canonical here: **double-quoted,
comma-separated lowercase strings** — `os: "linux, macos"`, `harness:
"opencode"`; never brackets, never block sequences. Mode R verified the runtime
schema live (opencode.ai/docs/skills: metadata is a string-to-string map).
State the extraction path in the same breath (build-registry.mjs →
registry.json → init.mjs) so consumers can't guess.
