# Anti-pattern: plan-step premise already true

A plan step whose done-when grep is already green pre-work certifies
nothing — the executor ticks it with zero changes while the AC's actual
intent ships unverified.

PLAN-533 step 1.3 gated on `rg 'ponytail: this exists' agents/` → zero.
That grep returns zero *today* (no lens ever quoted that wording), so the
step was passable before any work, while AC #2's real deliverable —
markers stating the new vendored version — went unowned.

**Rule:** at plan review, run each grep-based done-when against the current
tree. An already-passing gate means the premise is stale — rewrite the gate
around the real deliverable (here: "all 8 markers state v4.10.0" + a
recorded lens-body delta review).

- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-22
