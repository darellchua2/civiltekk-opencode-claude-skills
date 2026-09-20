# PLAN: Add question-repair plugin to fix malformed prompt payloads

**Branch**: feat/448
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/448
**Base**: main

## Acceptance Criteria
- [ ] A fixture payload missing an option `description` validates and renders after normalization
- [ ] Option entries missing both fields are dropped, not passed through
- [ ] Valid payloads pass through unchanged (no mutation)
- [ ] Plugin deploys via `deploy/setup.sh` and loads without affecting other tools

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Use `codegraph_callers` (code) or `tofu graph` + grep (IaC)._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `plugins/question-repair.ts` | — (new file) | opencode runtime plugin loader (auto-load from `~/.config/opencode/plugins/`); `deploy_plugins()` wholesale copy in `deploy/setup.sh` (line 3231, invoked at 4303); `tests/test_question_repair_plugin.test.ts` | low |
| `tests/test_question_repair_plugin.test.ts` | `plugins/question-repair.ts` (step 1.1) | `node --test` suite (CI + local gates) | low |

Thin-map note: both consumers of the plugin node are passive (dir-copy deploy, runtime auto-load) — no existing file is edited, so blast radius is confined to the new file plus its test. Step 9 code review is unconditional regardless.

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Canonical step format
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: question-repair plugin + proof

- [ ] **1.1** Create `plugins/question-repair.ts` — plain default export `{ id: 'question-repair', setup }` registering `ctx.tool.hook('execute.before')` guarded on `event.tool === 'question'`, plus an exported pure `normalizeQuestionInput(input)` helper
    — **Why:** the plugin is the deliverable; exporting the pure helper mirrors the `opencode-auto-continue-v2.ts` pattern that `tests/test_auto_continue_plugin.test.ts` imports, and keeps the hook shell a thin guard + reference-swap (`if (repaired !== event.input) event.input = repaired`)
    — **Done when:** `node --check plugins/question-repair.ts` passes and the file exports both the pure function and a `{ id, setup }` default export
    — **Consumers affected:** opencode runtime plugin loader, `deploy_plugins()` copy, step 1.2's test import

- [ ] **1.2** Add `tests/test_question_repair_plugin.test.ts` — `node:test` + `assert/strict` covering: description filled from label; label filled from first 5 words of description; question filled from header (and header from question, truncated to 30 chars); options missing both fields dropped; items without options dropped; all-items-dropped and non-object inputs returned as the original reference; valid payloads returned as the same reference (no mutation); `multiple` defaulted to `false`; hook fires only for `event.tool === 'question'` (fake ctx capturing the hook)
    — **Why:** ticket ACs 1–3 plus the no-mutation and tool-guard guarantees need executable proof; one of the fixtures reproduces a real audited failure (missing `questions[1].question` from the 2026-08-16 "Storage design" call)
    — **Done when:** `node --test tests/test_question_repair_plugin.test.ts` exits 0 with every test green
    — **Consumers affected:** `node --test` suite (CI + local gates)

- [ ] **1.3** Run the regression gate: full `bats tests/` suite plus the new `node --test` file in the same session
    — **Why:** proves AC 4's "without affecting other tools" — the repo's established surface (351 bats tests) must stay green alongside the new proof
    — **Done when:** full bats suite reports 0 failures and the new test file is green in the same run; record the `GATE <short-sha> …` memo line
    — **Consumers affected:** none (read-only verification)

### Phase 2: deploy pickup verification

- [ ] **2.1** Verify deploy pickup: run `./deploy/setup.sh --dry-run` and confirm `plugins/question-repair.ts` appears in the deploy copy set
    — **Why:** `deploy_plugins()` (deploy/setup.sh:3231) copies every `plugins/*` item wholesale, so AC 4 needs zero setup.sh edits — the dry-run grep is the proof a new file is picked up unmodified
    — **Done when:** dry-run output contains `question-repair.ts` in a copy/`cp` line targeting `~/.config/opencode/plugins/`
    — **Consumers affected:** setup.sh deploy log (informational plugin count only)

## Technical Notes

- Repair rules (applied per question item, in order): `description ← label` when description missing; `label ← first 5 words of description` when label missing; `question ← header` when question missing; `header ← first 30 chars of question` when header missing; `multiple ← false` when absent.
- Drop rules: option entries missing BOTH `label` and `description`; question items that are not objects or have no usable `options` array.
- Bounded repair: if input is not an object, has no `questions` array, or every item is dropped, return the ORIGINAL input unchanged — the schema validator then produces its error; the plugin never invents a question.
- No-mutation contract: `normalizeQuestionInput` returns the same reference when nothing needs repair; the hook swaps `event.input` only when a different reference comes back. Valid payloads are never touched.
- Hook shape mirrors the proven production usage in `plugins/vibeguard.ts:490` (`ctx.tool.hook('execute.before', …)`, v2 API); the `event.tool` guard follows the documented v2 plugins-guide example (`if (event.tool === "read")`).
- Debug knob: `OPENCODE_QUESTION_REPAIR_DEBUG=1` logs one line per repair fired (this audit was only possible via DB forensics — the knob keeps future forensics cheap).
- Deliberately out of scope (per ticket Alternatives): dismissed/aborted labeling, upstream stuck-running prompts, any schema relaxation.
- `ponytail:` no config file — a repair table that never varies needs no `question-repair.config.json`; add one only if a second site needs different fill rules.

## Dependencies

None external. Single ticket, no `blocked-by:` refs.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| v2 hook event shape drifts | Mirrors `vibeguard.ts:490` already running in production on this install; failure mode is a no-op guard return, not a crash |
| Over-repair corrupts a valid payload | Same-reference no-op path + dedicated no-mutation test (AC 3) |
| `event.tool` field renamed upstream | Guard returns unchanged on unexpected shapes; repair logic is still pure-function testable |
| Plugin count/log drift concerns | `deploy_plugins()` has no fixed count constant — nothing to sync |
