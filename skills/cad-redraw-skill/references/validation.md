# Validation and acceptance policies

Two independent axes, never conflated:

1. **Structural/dimensional accuracy** — deterministic: fingerprint diff,
   spec constraint arithmetic, ezdxf entity checks. Machine-verifiable.
2. **Visual similarity** — registered image comparison. Finds omitted walls,
   shifted holes, wrong arcs, text collisions, layout errors. NEVER evidence
   of physical size; comparison artifacts are labeled "visual only".

## Fingerprint diff gate (Mode A / Mode B)

`fingerprint_diff.py source.json target.json` exits 0 only when:

- entity counts match per type and per space (modelspace/paperspace);
- every source layer, block, text style, and dimension style exists in the
  target;
- dimension, leader, text, and MTEXT counts match — a source dimension or
  leader missing from the target is a **failure**, not a warning;
- extents agree within tolerance (default 1e-6 drawing units).

The diff report is included in the final response even when it passes.
Silent passing is forbidden — report what was compared.

## Spec validation gate (Mode C, before drawing)

`spec_to_dxf.py --check-only` fails on: schema violations, duplicate entity
IDs, references to undefined views/layers/entities, non-positive dimensions,
constraint arithmetic failures, and profile violations:

| Profile | Requirement to draw |
|---|---|
| `strict-dimensioned` | declared unit system + every load-bearing dimension `known`/`scaled` |
| `general` / `hybrid` | no impossible geometry; `inferred` values have assumption entries |
| `visual-trace` | none beyond schema; output cannot claim scale |
| `geometry-only` | annotation layers absent from the drawn output |

A `strict-dimensioned` spec without units or anchors is **blocked**, not
downgraded silently.

## Dispositions

Exactly one per run, in the final response:

- `pass` — selected profile and all required checks green; no unstated
  uncertainty.
- `pass_with_warnings` — deliverable usable; documented noncritical
  uncertainty (e.g., non-empty `assumptions`, preflight warnings).
- `needs_review` — a human decision is required: conflicting dimensions,
  `unreadable` load-bearing values, `inferred` geometry in a
  `strict-dimensioned` context.
- `blocked` — required source evidence missing (no scale anchor for a
  dimensioned profile, unreadable spec errors).
- `fail` — output corrupt or a mandatory check failed (fingerprint diff red
  on Mode A, draw failure, constraint violation).

Escalation is one-way and honest: when in doubt between two dispositions,
take the lower one and state why.

## Report contract

Every run reports: files produced, checks actually run (never "validated"
in the abstract), fingerprint-diff result, evidence-level counts
(`known/scaled/inferred/unreadable`), assumptions, warnings, and the
disposition with its trigger.
