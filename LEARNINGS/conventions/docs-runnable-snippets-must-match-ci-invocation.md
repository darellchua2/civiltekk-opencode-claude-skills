# Runnable doc snippets must mirror CI's invocation

**Category**: conventions
**Confidence**: 0.9
**Scope**: project
**Date**: 2026-09-23

## Convention

When documenting a command CI already runs, copy CI's setup lines (PATH exports, env vars), not the idealized form. CONTRIBUTING.md:23-24 told contributors to init the bats-core submodule then call bare `bats tests/` — the submodule lands bats at `tests/lib/bats-core/bin/bats`, off-PATH; CI survives only because release.yml:36-38 exports that bin dir. First-time contributors run doc snippets verbatim on clean machines (#539 code review WARN).
