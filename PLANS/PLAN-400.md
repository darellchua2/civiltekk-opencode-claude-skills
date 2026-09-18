# PLAN: update — per-target outcome reporting (#400)

**Branch**: feat/400
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/400
**Base**: main (20d3ed3)

## Acceptance Criteria

From ticket #400:

- [x] bats case: multi-target entry, one target missing + one changed → `update` re-copies the changed target AND reports the entry under `updated`
- [x] Report line reflects per-target outcomes without double-counting entries — entries with no missing target land in exactly one of `updated`/`unchanged`; a partially-missing entry counts under `updated` iff a present target changed (its missing target stays in `missing` detail); a fully-missing entry reports per-target `missing` only (ticket-sanctioned)
- [x] Full bats suite green; no behavior change to file operations (reporting only)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` `cmdUpdate` bucket logic (:925-967) | — | report line, `--dry-run` JSON plan, `tests/update.bats` | low |

## Implementation Phases

### Phase 1: Per-target classification + bats

- [x] **1.1** `cmdUpdate`: replace the entry-level `touched`/`missingHere` flags with per-target counting — `updatedTargets` (targets whose hash changed) and `missingTargets` (count); entry classified: `plan.updated` if any target updated, else `plan.unchanged` if no target missing, else fully-missing (already listed per-target in `plan.missing` as `name (target)`, counted there). A partially-missing entry that updated counts ONLY under `updated`; its missing target remains in the `missing` detail list. No file-operation changes — the write path already handles each target independently
    — **Why:** CR-6: an entry with one changed + one missing target is reported solely under `missing` although its changed target was re-copied, understating what `update` did.
    — **Done when:** `node --check`; fake-HOME scenario: install `--target both` → remove claude dir → mutate source → `update` prints `updated 1 · ...`, JSON plan has the entry under `updated` and `name (claude)` under `missing`.
    — **Consumers affected:** `update` report line, dry-run JSON, `tests/update.bats`.

- [x] **1.2** `tests/update.bats`: new case — `add tdd-workflow-skill --target both --yes`; `rm -rf` the claude dir; append a mutation marker to the source (cp backup/restore discipline + teardown fallback); run `update --dry-run` (assert JSON plan: entry under `updated`, `tdd-workflow-skill (claude)` under `missing`, claude dir still absent); then run a real `update` (assert report line `updated 1` and the stderr footer `missing: tdd-workflow-skill (claude)`); assert the opencode copy carries the mutation and the claude dir stays absent
    — **Why:** The ticket's acceptance is an executable proof of exactly this scenario; the real run prints no JSON, so the plan requires both a dry-run pass (JSON) and a real pass (report line + footer) (REQ-1).
    — **Done when:** `bats tests/update.bats` green (7 cases).
    — **Consumers affected:** CI.

**Phase gate:** full bats suite green; registry `--check`; public `add --dry-run` unchanged.

## Technical Notes

- Current bookkeeping: `touched`/`missingHere` booleans; `if (missingHere) continue;` skips the entry-level push entirely — the changed target's update is invisible in the report.
- `plan.missing` entries are already per-target (`name (target)`); they double as the detail list for the report footer.
- Out of scope: re-creating missing targets (update is upgrade-from-source; re-creation would change lifecycle semantics — separate decision if ever asked).

## Dependencies

- None. Closes #400.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Double-counting entry in updated + missing buckets | Entry-level push is an exclusive if/else-if chain; missing stays per-target detail only |
| Report-line count shift surprises scripters | `updated` now counts entries whose any-target updated — the previously-correct-seeming `updated 0` was the bug; change noted in PR body |
