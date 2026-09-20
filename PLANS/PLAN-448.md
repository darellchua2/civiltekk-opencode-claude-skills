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
| `plugins/question-repair.ts` | — (new file) | opencode runtime plugin loader (auto-load from `~/.config/opencode/plugins/`); `deploy_plugins()` wholesale copy in `deploy/setup.sh` (line 3231, invoked at 4303); `tests/test_question_repair_plugin.test.ts`; Docker image via `opencode_app/Dockerfile:82` `COPY plugins/` (automatic, unchecked — see out-of-scope) | low |
| `tests/test_question_repair_plugin.test.ts` | `plugins/question-repair.ts` (step 1.1) | `node --test` suite (CI + local gates) | low |
| runtime edge: `plugins/vibeguard.ts` | coexists on the same `ctx.tool.hook('execute.before')` event; hook order is glob-order (implementation detail) | question-repair must be placeholder-safe (see Technical Notes) so vibeguard's `restoreDeep` (vibeguard.ts:490-496) can still unmask `__VG_…__` in repaired input | low |

Thin-map note: both consumers of the plugin node are passive (dir-copy deploy, runtime auto-load) — no existing file is edited, so blast radius is confined to the new file plus its test. Step 9 code review is unconditional regardless.

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Canonical step format
- [ ] **N.M** <single atomic action — verb + target + outcome>
    — **Why:** <what this unblocks / why it must precede others>
    — **Done when:** <objective, checkable completion signal>
    — **Consumers affected:** <who depends on this; none if N/A>

### Phase 1: question-repair plugin + proof

- [x] **1.1** Create `plugins/question-repair.ts` — plain default export `{ id: 'question-repair', setup }` registering `ctx.tool.hook('execute.before')` guarded on `event.tool === 'question'`, plus an exported pure `normalizeQuestionInput(input)` helper; when `OPENCODE_QUESTION_REPAIR_DEBUG=1`, setup logs a one-time `question-repair: loaded` marker and each repair fires one line
    — **Why:** the plugin is the deliverable; exporting the pure helper mirrors the `opencode-auto-continue-v2.ts` pattern that `tests/test_auto_continue_plugin.test.ts` imports, and keeps the hook shell a thin guard + reference-swap (`if (repaired !== event.input) event.input = repaired`); the loaded-marker gives step 2.2 a deterministic assertion target (setup runs at session start, no model behavior needed)
    — **Done when:** the plugin parses on import in the `node --test` run (repo precedent: `node --check` applies to `.mjs` only — release.yml:55 — since check mode cannot strip TS types) and the file exports both the pure function and a `{ id, setup }` default export
    — **Done:** wrote plugins/question-repair.ts (pure normalizeQuestionInput + {id,setup} hook with question-guard, placeholder-safe truncating fills, debug knob); files: plugins/question-repair.ts; fixes: gate spec corrected — node --check replaced by node --test import-parse (check mode cannot strip TS types; fix #1)
    — **Consumers affected:** opencode runtime plugin loader, `deploy_plugins()` copy, step 1.2's test import

- [x] **1.2** Add `tests/test_question_repair_plugin.test.ts` — `node:test` + `assert/strict` covering: description filled from label; label filled from first 5 words of description; question filled from header (and header from question, truncated to 30 chars); options missing both fields dropped; items without options dropped; all-items-dropped and non-object inputs returned as the original reference; valid payloads returned as the same reference (no mutation); truncating fills leave `__VG_…__` vibeguard placeholders intact (copy verbatim, never split); `multiple` defaulted to `false`; hook fires only for `event.tool === 'question'` (fake ctx capturing the hook)
    — **Why:** ticket ACs 1–3 plus the no-mutation and tool-guard guarantees need executable proof; one of the fixtures reproduces a real audited failure (missing `questions[1].question` from the 2026-08-16 "Storage design" call). Unit tests prove AC 1 up to field-shape conformance — that shape proxy plus step 2.2's live run together discharge AC 1's "renders"
    — **Done when:** `node --test tests/test_question_repair_plugin.test.ts` exits 0 with every test green
    — **Done:** 11/11 green incl. audited fixture, placeholder-safety, no-mutation, hook-guard; files: tests/test_question_repair_plugin.test.ts; fixes: none
    — **Consumers affected:** `node --test` suite (CI + local gates)

- [x] **1.3** Run the regression gate: full `bats tests/` suite plus the new `node --test` file in the same session
    — **Why:** proves AC 4's "without affecting other tools" — the repo's established surface (351 bats tests) must stay green alongside the new proof
    — **Done when:** full bats suite reports 0 failures and the new test file is green in the same run; record the `GATE <short-sha> …` memo line
    — **Done:** bats 351/351 + node --test 11/11 in the same session; files: none (verification); fixes: none
    — **Consumers affected:** none (read-only verification)

### Phase 2: deploy pickup, load proof, docs

- [ ] **2.1** Verify deploy pickup: run `./deploy/setup.sh --dry-run -y` and confirm `plugins/question-repair.ts` appears in the deploy copy set
    — **Why:** `deploy_plugins()` (deploy/setup.sh:3231) copies every `plugins/*` item wholesale, so AC 4 needs zero setup.sh edits — the dry-run grep is the proof a new file is picked up unmodified. Headless `--dry-run` WITHOUT `-y` menu-resolves to Quick/Skills-Only, which never calls `deploy_plugins()` (architecture-review Finding 1, empirically traced), so `-y` is mandatory; and `run_cmd` echoes the expanded `$HOME` path (setup.sh:974), never the literal `~`
    — **Done when:** dry-run output matches `\[DRY-RUN\] Would execute: cp -r .*plugins/question-repair\.ts .*/\.config/opencode/plugins/`
    — **Consumers affected:** setup.sh deploy log (informational plugin count only)

- [ ] **2.2** Load proof: deploy the reviewed file (`cp plugins/question-repair.ts ~/.config/opencode/plugins/`), run `OPENCODE_QUESTION_REPAIR_DEBUG=1 timeout 90 opencode run "Reply with just: ok"`, and assert the `question-repair: loaded` marker in the command output or the newest `~/.local/share/opencode/log/*.log`
    — **Why:** copy pickup proves nothing about runtime load — the repo learning `docker-v1-binary-ignores-v2-plugins-key` ("build green ≠ plugin loaded") mandates a runtime-presence assertion or an explicit descope; this smoke is the assertion and doubles as AC 1's render-side evidence. The cp intentionally deploys the reviewed file to the live install early (same model as the #447 rule deploy); idempotent on re-run
    — **Done when:** the marker string `question-repair: loaded` is found in output or the newest server log for a run of the deployed file
    — **Consumers affected:** user's global `~/.config/opencode/plugins/` (deliberate early deploy)

- [ ] **2.3** Add a README plugin section for question-repair (mirroring the existing vibeguard/auto-continue sections) and add the plugin name to the repo-tree comment at the top of README.md
    — **Why:** every existing local plugin documents itself in README; folding this into the plan pre-empts the docs-consistency pass (architecture-review Finding 4). Fixing the tree comment's pre-existing omission of `opencode-auto-continue-v2.ts` is NOT in scope — note it, don't fix it
    — **Done when:** `grep -c 'question-repair' README.md` ≥ 2 (tree comment + section heading)
    — **Consumers affected:** README readers; docs-consistency checks

## Technical Notes

- Repair rules (applied per question item, in order): `description ← label` when description missing; `label ← first 5 words of description` when label missing; `question ← header` when question missing; `header ← first 30 chars of question` when header missing; `multiple ← false` when absent.
- Placeholder safety (vibeguard coexistence): the truncating fills (`label ←`, `header ←`) must check the source string for `__VG` first — when present, copy the source verbatim (skip truncation) rather than risk splitting a `__VG_<CATEGORY>_<hash>__` placeholder, which vibeguard's `restoreDeep` could then fail to restore (vibeguard.ts:490-496 runs on the same `execute.before` event; hook order between the two plugins is glob-order and must not matter).
- Drop rules: option entries missing BOTH `label` and `description`; question items that are not objects or have no usable `options` array.
- Bounded repair: if input is not an object, has no `questions` array, or every item is dropped, return the ORIGINAL input unchanged — the schema validator then produces its error; the plugin never invents a question.
- No-mutation contract: `normalizeQuestionInput` returns the same reference when nothing needs repair; the hook swaps `event.input` only when a different reference comes back. Valid payloads are never touched.
- Hook shape mirrors the proven production usage in `plugins/vibeguard.ts:490` (`ctx.tool.hook('execute.before', …)`, v2 API); the `event.tool` guard follows the documented v2 plugins-guide example (`if (event.tool === "read")`).
- Debug knob: `OPENCODE_QUESTION_REPAIR_DEBUG=1` logs one line per repair fired (this audit was only possible via DB forensics — the knob keeps future forensics cheap).
- Deliberately out of scope (per ticket Alternatives + Mode R relay): dismissed/aborted labeling, upstream stuck-running prompts, any schema relaxation. Docker: explicitly out of scope for verification — `opencode_app/Dockerfile:82` wholesale-copies `plugins/` into the v2-runtime image so the plugin rides along automatically, and the interactive repair is not load-bearing for the web endpoint; no container presence check (file one only if the endpoint ever needs it).
- `ponytail:` no config file — a repair table that never varies needs no `question-repair.config.json`; add one only if a second site needs different fill rules.

## Dependencies

None external. Single ticket, no `blocked-by:` refs.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| v2 hook event shape drifts | Mirrors `vibeguard.ts:490` already running in production on this install; failure mode is a no-op guard return, not a crash |
| Over-repair corrupts a valid payload | Same-reference no-op path + dedicated no-mutation test (AC 3) |
| `event.tool` field renamed upstream | Guard returns unchanged on unexpected shapes; repair logic is still pure-function testable |
| Truncating fill splits a vibeguard `__VG_…__` placeholder → mask fragment renders in the UI (no leak; the mask holds) | Placeholder-aware fills copy verbatim when the source contains `__VG`; dedicated fixture test (step 1.2) |
| Plugin copies but silently never loads (the #387 class of failure) | Step 2.2 debug-knob load smoke asserts `question-repair: loaded` from the deployed file |
| Plugin count/log drift concerns | `deploy_plugins()` has no fixed count constant — nothing to sync |

## Gate Trace

- GATE 69532dc lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — bats 351/351, node --test tests/test_question_repair_plugin.test.ts 11/11 (Phase 1, first try)
