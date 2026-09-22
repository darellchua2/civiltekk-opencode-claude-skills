# Anti-pattern: persisted default frozen at module load

A runtime-persisted default resolved into a module-load const can never
observe its own writer in-process.

The ponytail wrapper (plugins/opencode-ponytail-scoped.ts) computed
`PONYTAIL_DEFAULT_MODE` once at plugin load; `/ponytail default lite`
confirmed "new sessions pick it up" while every new session in the same
long-lived server process kept the load-time value until an opaque restart
(#533 code review Major 1).

**Rule:** persisted settings need a mutable shadow updated on successful
persist (or a lazy read per resolution), and the success message must match
the actual pickup semantics. Two-process restart tests pin the easy half —
add a same-process new-session probe.

- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-22
