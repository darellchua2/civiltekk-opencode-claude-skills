# PLAN: aggregate --target auto --dry-run into one JSON doc

**Branch**: feat/568
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/568
**Base**: main (6f0932c)

## Acceptance Criteria

- [x] `--target auto --dry-run` with multiple detected harnesses prints ONE JSON doc with `auto: true` and a `targets` array (one entry per resolved target, each carrying its own `target`/`destinations`)
- [x] Single detected harness also yields the wrapped shape (uniform contract)
- [x] Project-scope auto dry-run (`--project --target auto --dry-run`) uses the same wrapped shape via the `writeInstall` sink; dedupe behavior unchanged
- [x] Nothing is written to disk on dry-run; explicit `--target <t> --dry-run` still prints its plain single doc (shape unchanged)
- [x] Help text + README updated (NDJSON sentence replaced)
- [x] New tests per item; full `bats tests/` green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `writeUserScopeInstall` dry branch (jsonSink opt) | — | main auto dispatch (sink); plain CLI (unchanged print) | low |
| `writeInstall` dry branch (jsonSink opt) | — | main auto dispatch (sink); plain CLI (unchanged print) | low |
| `main()` auto dispatch (dry-run aggregation) | both sinks | `--target auto --dry-run` users (new contract, zero existing consumers — feature shipped #566) | medium |
| help + README wording | aggregation | CLI users, docs | low |
| `tests/init.bats` | installer behavior | CI | low |

The `jsonSink` opt is additive and internal: without it, both dry branches print exactly as before. Non-dry auto stays the per-target loop (only the dry-run machine contract changes — review answer from #566). No `blocked-by:` — #567 touched cmdAdd's prune guard, orthogonal surface.

## Implementation Phases

### Phase 1: sink + aggregation + docs + tests

- [x] **1.1** Both dry branches gain sink support: hoist the inline JSON object into a `doc` const; `if (opts.jsonSink) { opts.jsonSink.push(doc); return; }` before the existing `process.stdout.write(JSON.stringify(doc, ...))`. Sites: `writeUserScopeInstall` (~:863, user scope) and `writeInstall` (~:526, project scope).
    — **Why:** lets the auto dispatch collect per-target docs without refactoring the print pipeline or duplicating preview logic.
    — **Done when:** `node --check` passes; plain `--dry-run` output byte-identical to before (existing tests green); sink call sites return without printing.
    — **Consumers affected:** plain dry-run users (none — output unchanged); auto dispatch (new).
    — **Done:** jsonSink opt in both dry branches (doc hoisted to const; sink collects instead of printing); files: installer/init.mjs; fixes: none
- [x] **1.2** Auto dispatch (`main()` :1518): before the install loop, `if (opts.dryRun)` — loop `cmdAdd` with `{ ...opts, target: t, jsonSink: sink }`, then print ONE doc `{ dryRun: true, auto: true, scope: "user"|"project", targets: sink }` (pretty-printed, trailing newline). Non-dry path unchanged.
    — **Why:** the #566 review's recommended answer — one aggregated doc matches `--target both`'s single-doc contract; uniform wrapper even for one detected harness (one shape, no consumers of the old multi-doc shape to break).
    — **Done when:** sandboxed HOME with two detected harnesses: stdout parses as one JSON doc, `auto === true`, `targets.length === 2`; nothing written to disk.
    — **Consumers affected:** `--target auto --dry-run` only.
    — **Done:** auto dispatch dry-run aggregates into one { dryRun, auto, scope, targets } doc; non-dry loop unchanged; files: installer/init.mjs; fixes: none
- [x] **1.3** Help SCOPE paragraph: replace the NDJSON sentence with the aggregated shape; README `auto` target-table row notes "dry-run → one aggregated JSON doc".
    — **Done when:** `--help` shows the new contract; README row updated.
    — **Why:** the NDJSON sentence shipped in #566 is now wrong — stale-contract drift.
    — **Consumers affected:** CLI users, docs readers.
    — **Done:** help SCOPE sentence now documents the aggregated shape; README auto row notes the dry-run doc; files: installer/init.mjs, README.md; fixes: none
- [x] **1.4** Tests in `tests/init.bats`: (a) HOME with `.agents` + `.claude` → `add tdd-workflow-skill --target auto --dry-run` → stdout parses as ONE doc (`auto: true`, `targets.length === 2`, per-target `target` values distinct, `dryRun: true`), and no skills dirs created in either root; (b) HOME with only `.claude` → wrapped shape with `targets.length === 1`; (c) HOME with `.agents` + `.claude` + `--project "$TMP_PROJ" --target auto --dry-run` → one doc with `targets.length === 1` (dedupe) and `scope: "project"`, nothing written; (d) explicit `--target claude --dry-run` still prints its plain unwrapped doc (regression guard on the unchanged path).
    — **Done when:** all four pass.
    — **Why:** the doc shape is a machine contract — pin every shape branch.
    — **Consumers affected:** CI gates.
    — **Done:** four tests: multi-detected wrap + no writes, single wrap, project dedupe wrap, explicit-target plain-doc regression guard; files: tests/init.bats; fixes: bats combines stderr into $output — tests strip the stderr prefix via sed before JSON parse
- [x] **1.5** Gate: `bats tests/init.bats` green.
    — **Done when:** exit 0.
    — **Why:** behavioral proof before the exit gate.
    — **Consumers affected:** Phase 2 gate.
    — **Done:** bats tests/init.bats → 46 ok / 0 not ok, exit 0; files: none; fixes: stderr-combined-capture sed strip (above)

### Phase 2: Full exit gate

- [x] **2.1** Full `bats tests/`.
    — **Why:** ticket exit gate — full tier.
    — **Done when:** exit 0; `GATE <short-sha> tier=full` appended to the trace below.
    — **Consumers affected:** Step 9/10 citations.
    — **Done:** bats tests/ → 581 ok / 0 not ok, exit 0 (577 + 4 new); files: none; fixes: none

## Technical Notes

- The sink is a plain array on opts — cmdAdd passes `opts` through to `writeUserScopeInstall`/`writeInstall` verbatim, so `{ ...opts, jsonSink: sink }` at the dispatch is the only wiring needed.
- `scope` in the wrapper mirrors the invocation (user default; project when `--project`).
- stderr notes (detected-harness line, downgrade notices) are unaffected — stdout stays pure JSON.

## Dependencies

None (no `blocked-by:`).

## Risks & Mitigation

- **Shape churn for early adopters**: the multi-doc NDJSON shape shipped only in #566 (days old, documented as interim in its PR body) — acceptable to replace now; the interim sentence is updated in the same change.

## Gate Trace

GATE 51e6320 tier=light lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a
GATE <full-sha> tier=full lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a
