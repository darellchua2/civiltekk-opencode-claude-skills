# Credential-regex host:port false-positive

**Type:** solution (refines the SECRET_ASSIGNMENT false-negative pattern)
**Confidence:** 0.9 (verified via node regex test)
**Scope:** any secret-detection / redaction regex that targets connection-string credentials

## Problem

The URL-credential regex `://[^:\s]+:[^@\s]+@` — recommended to catch `user:pass@host`
connection strings — **cannot distinguish `user:pass@host` (credential) from `host:port@path`
(port + @-route)**. It matches any `scheme://X:Y@` where X has no colon and Y has no `@`.

### Confirmed false-positives (node-tested)

| Input (NON-secret URL) | Match | Result |
|---|---|---|
| `http://localhost:3000/@user/profile` | `://localhost:3000/@` | redacted + mangled |
| `https://example.com:8080/@team/notes` | `://example.com:8080/@` | redacted + mangled |

The redaction **stops at the first `@`**, so it corrupts the URL into a placeholder and
leaves `/team/notes` dangling. The vibeguard `exclude` list (`localhost`, `example.com`)
does **not** suppress these because the regex match is a *substring*
(`://localhost:3000/@`), not an exact exclude-token match.

### Confirmed safe (no false-positive)

- `https://en.wikipedia.org/wiki/Foo` (no `:…@`) — no match ✓
- `git@github.com:user/repo.git` (no `://`) — no match ✓
- `https://registry.npmjs.org/@scope/pkg` (no `:` between `://` and `@`) — no match ✓

## Impact

Correctness/UX, **not** a security leak: vibeguard restores the real value at tool-exec
time, but the LLM sees a placeholder where it expected a URL. If the LLM copies the
placeholder into a file written to disk, that file gets `__VG_…__` instead of the real
URL. Common in dev (localhost dev servers, routes with `@`).

## Fix options

1. **Require a host-like segment after `@`** (preferred):
   `://[^:/\s]+:[^/\s@]+@[A-Za-z0-9][A-Za-z0-9.-]*`
2. **Reject pure-numeric (port) segment between `:` and `@`** via negative lookahead:
   `://[^:\s]+:(?![0-9]+@)[^@\s]+@`

## Evidence

`opencode_app/.opencode/vibeguard.config.json` pattern `DB_CONNECTION_STRING` (line 13 of
the 9-pattern `regex` array). Surfaced in PLAN-GIT-315 review.

> **Update 2026-09-21 (#506):** the config moved to `plugins/vibeguard.config.json` (v2 port;
> pattern now at :16) and the fix SHIPPED — the current pattern `://[^:\s]+:[^@\s/]+@` rejects a
> `/`-containing segment between `:` and `@`, so `localhost:3000/@user` and `example.com:8080/@team`
> no longer match. Original evidence path kept above as historical record.
