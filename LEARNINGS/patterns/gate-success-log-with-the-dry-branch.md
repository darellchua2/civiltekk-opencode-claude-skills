# Unconditional log_success after run_cmd overstates completion in dry-run

- **Category**: pattern
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #469 (review round 1)

## Context

After `run_cmd ln -sf …`, an unconditional `log_success "opencode-init
installed"` prints SUCCESS even in dry-run where nothing executed. The same
trait exists in deploy_plugins. The truthful in-tree shape is
register_zai_auth's early-return: gate the whole write+log block on DRY_RUN
and log a "[DRY-RUN] Would …" line instead.

## Rule

Prefer the early-return gate (dry branch logs Would-do, real branch writes
then logs success) when adding run_cmd gates to new functions — the adjacent
`[DRY-RUN]` line plus a SUCCESS line is tolerated in legacy sites but is the
wrong shape for new code. #470's plan executor should sweep the legacy sites.
