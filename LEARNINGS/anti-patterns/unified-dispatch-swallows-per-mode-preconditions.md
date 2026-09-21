# Unified dispatch swallows per-mode preconditions

- **Category**: anti-pattern
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Ticket**: #470 (architecture review)

## Symptom

Collapsing setup.sh's six mode branches into one planner/executor nearly
shipped three regressions at once: skills-only (documented as the
offline/headless escape path) would have gained the network check and menu
gate it never had; its hidden `check_dependencies` precondition vanished
from the step list; models-only/migrate-only lost their node-presence gates.

## Root cause

Per-branch code encodes not just steps but PRECONDITION EXCLUSIONS — which
gates each branch deliberately runs before/instead of others. A unified
dispatch sees only the steps; the exclusions are invisible coupling.

## Rule

Before unifying N mode branches, enumerate a per-mode precondition matrix
(deps check? network check? menu? header? early-exit ordering?) and pin one
execution trace per mode. Fail-fast validation (conflicts) must run BEFORE
any interactive gate — build plans twice: once pre-menu for validation,
again after the menu mutates flags.
