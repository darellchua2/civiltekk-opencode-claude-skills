# Env-prefix sandboxing of globals a sourced script reassigns is clobbered

- **Category**: anti-pattern
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #467 (review round 1)

## Symptom

A bats pin ran `REPO_DIR="$d/repo" bash -c "source deploy/setup.sh; …
setup_local_llm_env"`, expecting the sandboxed repo dir. setup.sh:70
unconditionally reassigns `REPO_DIR` from `SCRIPT_DIR` at source time — the
env prefix was dead on arrival. Consequences stacked three ways: the dry pin
went vacuously green (asserted on a file nothing wrote), the real-run
"positive control" rewrote the developer's actual worktree `.env`, and the
bug it existed to catch was untested.

## Root cause

Environment prefixes only seed the initial environment; any global the
sourced script assigns unconditionally overwrites it before the function
under test runs.

## Rule

Assign sandbox globals AFTER `source`, inside the same bash -c (the way
`DRY_RUN` already was). Add a sandbox-escape detector when the real target
exists (md5 the worktree file before/after and assert equality) so a future
clobber fails loudly instead of mutating user config.

## Evidence

- #537 (Phase 2 verification, live hit): a sandbox harness set `CONFIG_DIR`
  BEFORE sourcing setup.sh; the sourced top-level reassignment pointed the
  apply at the real `~/.config/opencode/plugins/` — byte-identical plugin
  artifacts redeployed (harmless here, exactly what a redeploy writes), but
  the test verified nothing. Re-harnessed with after-source overrides.
