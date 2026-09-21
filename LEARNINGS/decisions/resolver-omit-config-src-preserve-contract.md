# Decline-config contract honored by omitting --config-src

- **Category**: decision
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #470 (D2)

## Decision

"Decline config overwrite" (SKIP_CONFIG_COPY=true) means the user's existing
opencode.json wins: `run_resolver` omits `--config-src`, and
resolve-models.mjs's configSrc→configDest fallback (:280-285) bases its
in-place model patch on the existing file. With no existing config, no
config is written at all (write gated on `configPatched`, :463-468) — agents
still resolve. Execution-verified both directions during the #470 arch
review.

## Nuance

Not byte-preserving: with no `--provider`, a stale explicit `model` key is
deleted (:293-295) and explore/general pins are overwritten — that is the
resolver doing its job on the user's file, documented so it is not later
misread as a decline-contract bug.

## Scope

bash-first. setup.ps1's Invoke-Resolver still passes --config-src
unconditionally (Windows decline still rebases on stock) — parity deferred
to #474's thin launcher; models-only/migrate-only keep stock-base this
ticket (fresh-machine usefulness), follow-up to align via the same fallback
when CONFIG_FILE exists.

## Update 2026-09-21 (#491)

The anticipated alignment landed: run_resolver now presence-gates
--config-src for --models-only/--migrate (decline still wins first). The
#474 launcher made the ps1 mirror moot (delegation). Strict-JSON dest
requirement documented in solutions/readjsonmaybe-strict-json-jsonc-claims.md.
