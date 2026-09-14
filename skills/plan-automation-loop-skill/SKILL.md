---
name: plan-automation-loop-skill
description: >-
  Fully-automated PLAN execution via /run-plan — implement, verify
  (lint+build+test+e2e gate), commit, push per phase. Triggers: run-plan,
  automation loop, implement PLAN-*.md.
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: Git/Workflow
---

## What I do

I run a **fully-automated, phase-by-phase PLAN execution loop** with a hard verification gate
between phases. I am the "do the whole plan end-to-end, hands-off" skill:

1. **Resolve the plan** from the `/run-plan` argument (explicit path/glob, or auto-detect from branch).
2. **Discover verification commands** once (lint / build / test / e2e) from project manifests.
3. **For each phase, in order:**
   - Implement every atomic step in the phase.
   - **Ensure newly added code has unit tests** (generate the missing ones first).
   - **Run the verification gate:** lint → build/typecheck → unit tests → Playwright e2e (frontend only).
   - Fix failures with bounded retries (max 3) — never push red.
   - On green: **record a `— Done:` traceability line under each completed step** (what was done + fixes applied + files), mark the phase checkbox `[x]`, commit, push.
4. **Advance** to the next phase. Repeat until all phases are done.
5. **Final validation** against the plan's acceptance criteria.

I am the strict, push-per-phase sibling of `plan-execution-skill`. The difference: that skill
delegates softly and updates progress; **I enforce a gate, write missing tests, run e2e, leave a
per-step traceability record, and commit+push every phase.** I compose the existing skills rather
than reimplementing them.

## When to use me

Use this skill when:

- The user types **`/run-plan PLAN-*.md`** (the **primary** path — plain command, soft
  guardrails: phase/fix budgets, halt rules, idempotent resume; use for both short and long runs).
- The user says "fully implement the plan", "run the plan to completion", "automation loop".
  (For long hands-off runs, `/goal` wraps this skill with plugin-enforced runtime guardrails —
  the goal plugin is back as `@prevalentware/opencode-goal-plugin` (OpenCode v2-native since
  0.1.30); in that mode the skill MUST emit `[goal:*]` markers and close the goal via the
  plugin's `update_goal` tool.)

**Trigger phrases:**

- `implement PLAN-*.md` / `fully implement PLAN` / `implement the plan`
- `run plan to completion` / `automation loop`
- `implement plan and commit per phase`
- "implement the plan with full automation"

**Do NOT use me when:**

- The user wants a single step or read-only analysis → use `plan-execution-skill` or just do it.
- The user wants to plan/preview without committing → use `plan-execution-skill` (no push).
- No PLAN file exists → author one first via `worktree-pipeline-skill` §PLAN Authoring (or run `/run-worktree-pipeline` end-to-end).

> **`/run-plan` (primary).** It loads this skill directly; the soft budgets and HALT rules below
> are the guardrails. `/goal` + skill is the runtime-guarded path again (plugin re-added as
> `@prevalentware/opencode-goal-plugin`, v2) — in that mode the skill MUST emit `[goal:*]` markers
> (see Guardrails) for pipeline halt detection AND close the goal via the plugin's `update_goal`
> tool (`complete` requires every requirement mapped to evidence).

## Prerequisites

- A PLAN file (glob `PLAN*.md`) exists in the repo, following the structure in `plan-execution-skill`.
- The repo is a git repo on a working branch (not `main`/`master`).
- Lint / build / test commands are discoverable (see Step 2) or the user can supply them.
- **Optional:** Playwright is installed (`playwright.config.*` + `@playwright/test`) for e2e.
- The agent has `bash`, `edit`, `write`, and `task` permissions (the `build` agent does).

## Core Workflow — The Phase Loop

### Step 1: Resolve the plan file

Resolve from the `/run-plan` argument first; fall back to branch auto-detection.

```text
ARG = $ARGUMENTS  (e.g. "PLAN-GIT-123.md", or "implement PLAN-GIT-123.md")

1. Strip a leading verb if present ("implement", "execute", "run", "do").
2. If the remainder is a path or glob that matches a file → use it.
   - Glob (e.g. "PLAN*.md"): if exactly one match → use it.
                           if multiple → list them and ask the user to pick (question tool).
3. Else auto-detect from the current branch (see plan-execution-skill Step 1):
     GitHub branch GIT-123 → PLANS/PLAN-GIT-123.md
     JIRA branch PROJ-123  → PLANS/PLAN-PROJ-123.md
4. If still unresolved → STOP and tell the user which PLAN file to pass.
```

Read the full PLAN with the `Read` tool. Note the `## Dependency & Consumer Map` and
`## Acceptance Criteria` sections — both are consulted later.

### Step 2: Discover verification commands (ONCE)

Detect the project's lint / build / test / e2e commands from manifests. Do this **once** and reuse
for every phase. Prefer commands already recorded in the project's `AGENTS.md` / `instructions`;
otherwise infer, then **ask the user to confirm and persist them** in `AGENTS.md`.

**Detection order (per command):**

| Command | Look in (first hit wins) |
|---------|--------------------------|
| lint    | `package.json` `scripts.lint` • `pyproject.toml` `[tool.*]` ruff/eslint • `Makefile` `lint` • `.pre-commit-config` |
| build   | `package.json` `scripts.build` / `tsc` • `pyproject.toml` build • `Makefile` `build` |
| test    | `package.json` `scripts.test` • `pyproject.toml` pytest • `Makefile` `test` |
| typecheck | `package.json` `scripts.typecheck` / `tsc --noEmit` • `mypy`/`pyright` config |
| e2e     | `package.json` `scripts.e2e`/`test:e2e` • `npx playwright test` (only if Playwright configured) |

Cache the resolved set, e.g.:

```text
GATE.lint   = "npm run lint"
GATE.build  = "npm run build"
GATE.test   = "npm test -- --run"      # vitest non-watch; pytest; etc.
GATE.typecheck = "npx tsc --noEmit"
GATE.e2e    = "npx playwright test"    # only if Playwright present
```

If a command cannot be found and the user can't supply it, **skip that gate step and say so
explicitly** (e.g. "no build step detected — skipping build gate"). Never silently invent a command.

### Step 3: Establish a clean baseline

```bash
git status --porcelain            # note any pre-existing uncommitted work
git rev-parse --abbrev-ref HEAD   # confirm we're NOT on main/master
```

If there is unrelated uncommitted work, **stop and ask** before mixing it into phase commits.
If on `main`/`master`, **stop and ask** — never auto-commit to a protected branch.

### Step 4: The Phase Loop

Enforce the **Guardrails & Budget** caps (see that section) across the whole run — check them
before starting each phase and after each fix attempt.

```text
for each phase in plan order (Phase 1, 2, … N):
    [guardrail] if phases_done >= MAX_PHASES or total_fixes >= MAX_FIXES → HALT + [goal:blocked]
    4a. IMPLEMENT  — execute every atomic step in the phase (delegate per Step 4a matrix)
                     keep a per-step WORK LOG (what was done, files touched) for Step 8
                     if functions/classes added or changed → documentation-subagent adds docstrings
    4b. TEST NEW CODE — ensure newly added code has unit tests (Step 5)
    4c. VERIFY     — run the Phase Verification Gate (Step 6): lint → build → unit → e2e
    4d. FIX-ON-FAIL — if any gate step fails, fix and re-run (max 3 attempts; Step 7)
                     append each applied fix to the failing step's WORK LOG
                     increment total_fixes; if total_fixes >= MAX_FIXES → HALT + [goal:blocked]
    4e. ON GREEN   — tick ALL checkboxes (phase-level + every sub-step + satisfied acceptance
                     criteria) + write the `— Done:` traceability line under each step (Step 8)
    4f. COMMIT     — one atomic phase commit (Step 9)
    4g. PUSH       — push the branch (Step 9)
    4h. REPORT     — one-line phase status, then continue to next phase

when all phases done → Step 10: Final acceptance validation
```

**A phase advances ONLY when its gate is fully green.** Red gate = no checkbox, no Done line,
no commit, no push.

#### Step 4a: Implement the phase (delegate matrix)

Surface each step's `Consumers affected` before mutating its target (see `plan-execution-skill`).
Then delegate by task type. **As each step is completed, record a one-line entry in a per-step WORK
LOG** (what was implemented + files touched) — Step 8 turns this into the traceability record.

| Task type | Delegate to | Reason |
|-----------|-------------|--------|
| Test generation | `testing-subagent` | Framework-aware test writing |
| Refactor / DRY | `code-review-subagent` | SOLID + clean-code expertise |
| Lint setup/fix | `linting-subagent` (or `linting-workflow-skill`) | Multi-language lint |
| Docstrings for new/changed functions & classes | `documentation-subagent` | Language-specific docstrings (PEP 257 / Javadoc / JSDoc / XML docs) via `docstring-generator-skill` |
| Other docs (README, ADRs, guides) | `documentation-subagent` | Standards-compliant docs |
| Build/deploy/git | Handle directly | Needs full bash |
| Simple implementation | Handle directly | Straightforward |

**Docstring rule (mandatory for code phases):** if any step in the phase **adds or modifies a
function, method, or class**, delegate docstring updates to `documentation-subagent` as part of
implementation — *before* the gate — so doc coverage ships in the same phase commit. Skip only for
pure-data/trivial changes (constants, type aliases with no logic). The gate does not enforce
docstrings, but a code phase with undocumented public functions is incomplete.

Verify each step's **`Done when`** signal passes before considering the step complete.

### Step 5: Ensure newly added code has unit tests

Before running the gate, confirm new code is covered:

1. **Find new/modified source files in this phase:**
   ```bash
   git diff --name-only --diff-filter=AM   # added/modified, staged + unstaged
   ```
2. **Filter out non-source** (configs, docs, generated, the PLAN file itself).
3. **For each source file, check a corresponding test exists.** Conventions:
   - TS/JS: `src/foo/bar.ts` → `src/foo/bar.test.ts` or `__tests__/bar.test.ts`
   - Python: `src/foo/bar.py` → `tests/foo/test_bar.py` or `src/foo/test_bar.py`
   - If unsure of convention, mirror the nearest existing test file's location.
4. **If a test file is missing for new logic** → generate one via `testing-subagent` (or
   `tdd-workflow-skill`), covering the happy path + key edge cases. Trivial pure-data additions
   (a constant, a type with no logic) need no test — YAGNI applies to tests too.

This step runs BEFORE the test gate so the unit-test run actually exercises the new code.

### Step 6: Phase Verification Gate

Run in this order. Each step must pass (exit 0 / no new errors) before the next. Capture full
output so failures can be diagnosed.

```text
1. LINT        → GATE.lint
2. TYPECHECK   → GATE.typecheck   (skip if none; often folded into build)
3. BUILD       → GATE.build
4. UNIT TESTS  → GATE.test
5. E2E         → GATE.e2e   ONLY IF the phase touched frontend code (Step 6a)
```

**Gate semantics:**

- **Lint:** zero NEW errors/warnings on changed files. Pre-existing errors are noted, not blocked,
  unless the change introduces them.
- **Build/typecheck:** succeeds with no type errors.
- **Unit tests:** all pass. If coverage tooling exists, no coverage regression on changed lines.
- **E2e:** all relevant specs pass.

**Falsifiable done-predicate (verdict per phase):** after running the gate, record exactly one verdict:

- `VERIFIED` — every applicable gate ran (exit 0 / no new errors) and output was captured as evidence.
- `NOT VERIFIED` — a gate ran and failed.
- `INCONCLUSIVE` — a gate could not run (missing tooling, environment, skip applied).

`INCONCLUSIVE` is NOT a pass. The loop may only advance on `VERIFIED`. On `NOT VERIFIED`, enter the fix-on-fail loop (Step 7). On `INCONCLUSIVE`, either install/repair the missing gate, replace it with the closest executable check, or stop and report — never tick the phase as done on an unrun gate.

#### Step 6a: Frontend / E2E detection (when to run Playwright)

Run the e2e gate **only when BOTH** hold:

1. **Playwright is configured:** `playwright.config.{ts,js,mjs,cjs}` exists AND `@playwright/test`
   is in `package.json` (devDependencies) OR `GATE.e2e` was discovered.
2. **The phase touched frontend code.** Frontend = any changed file matching:
   - `**/components/**/*.{tsx,jsx,vue,svelte}`
   - `**/app/**`, `**/pages/**`, `**/routes/**`, `src/ui/**`
   - `*.tsx`, `*.jsx`, `*.vue`, `*.svelte` (non-story, non-test)
   - route handlers / middleware that affect rendered pages

If Playwright is configured but the phase is backend-only → **skip e2e** and say so. If the phase
is frontend but Playwright is NOT configured → note it and skip (do not install Playwright unprompted).

> **Responsive/visual scope → spawn the subagent, don't run inline.** If the phase touched
> frontend code AND the plan calls for visual/responsive/breakpoint verification (or wireframer
> baselines exist), do NOT run `npx playwright test` inline. Instead spawn
> `responsive-audit-subagent` via the Task tool — it loads `playwright-responsive-audit-skill`
> (subagent-only; not loadable from this primary session) and runs the PTY-driven
> detect→fix→re-verify loop. Reserve inline `npx playwright test` for plain functional e2e.

### Step 7: Fix-on-fail (bounded retries)

If any gate step fails:

```text
attempt = 0
while attempt < 3 and gate not green:
    attempt += 1
    1. Read the failing command's output (full stderr).
    2. Diagnose root cause (not symptom) — use error-resolver-workflow-skill if needed.
    3. Fix the implementation (or the test, if the test was wrong).
    4. APPEND the applied fix to the relevant step's WORK LOG
       (e.g. "fix-on-fail a2: tightened email regex — unit test caught '+' edge case").
    5. Re-run the FAILED step, then re-run the whole gate to confirm no regression.
```

After 3 failed attempts on the same gate step: **STOP**. Do not mark the checkbox, do not write a
Done line, do not commit, do not push. Report the blocker with the failing output and the last
attempted fix, then ask the user. (Under `AUTORESEARCH_PROTOCOL=1`, see the Iteration Protocol
section instead.)

**Never push red code. Never commit a half-passing gate.** A failing gate halts the loop.

### Step 8: Tick every checkbox + record traceability

Once the gate is green, update the PLAN for the completed phase. Tick **every** checkbox the phase
owns, then add a `— Done:` traceability line under each atomic step. Use `edit` (Read the PLAN
first). **A completed phase must leave zero unchecked boxes in its own section.**

**Tick ALL of these (in order):**

1. **The phase-level checkbox** — if the plan has one (e.g. `- [ ] Phase N`, or a `[ ]` on the
   `### Phase N:` header line), flip it `- [ ]` → `- [x]`.
2. **Every atomic sub-step** in the phase: `- [ ] **N.M** …` → `- [x] **N.M** …`. Do not skip any —
   not even "trivial" ones. An unchecked box inside a "complete" phase breaks progress tracking and
   breaks resume (the loop resumes at the first `- [ ]` it finds).
3. **Any acceptance-criteria items** (in `## Acceptance Criteria`) that this phase satisfied:
   `- [ ]` → `- [x]`. A criterion spanning multiple phases is ticked when the last contributing
   phase lands.

Sanity-check after editing: `grep -n "^- \[ \]" <PLAN>` inside the completed phase should return
nothing. Then add the `— Done:` traceability line per step (below).

**Before (the step as authored):**

```text
- [ ] **2.3** Add checkout form validation
    — **Why:** prevent invalid submissions
    — **Done when:** form blocks empty/invalid fields
    — **Consumers affected:** CheckoutButton
```

**After (completed + traced):**

```text
- [x] **2.3** Add checkout form validation
    — **Why:** prevent invalid submissions
    — **Done when:** form blocks empty/invalid fields
    — **Consumers affected:** CheckoutButton
    — **Done:** Zod schema + inline error UI; files: src/checkout/CheckoutForm.tsx, schema.ts;
      fixes: tightened email regex after unit-test edge case (fix-on-fail attempt 2)
```

**`— Done:` line format:**

```text
— **Done:** <one-line work summary>; files: <comma-separated files>; fixes: <fixes applied, or "none">
```

Rules:

- Write one `— Done:` line per completed step, indented to match the existing `— **Why:**` block.
- **`fixes:` MUST list every fix applied during Step 7** for that step, or `none` if the gate passed
  first try. This is the core traceability requirement — reviewers must be able to see what was
  changed to get the code green.
- Keep it to one logical line (wrap if needed, but compact — it's a trace, not prose).
- Only mark a step `[x]` (and write its Done line) when its `Done when` signal is objectively
  satisfied AND the gate passed. Do not trace partial phases.
- If a step intentionally deviated from the authored action, note it in the work summary
  (e.g. "used react-hook-form instead of raw state — see ADR-007").

> **Commit-hash traceability (optional).** The default is one atomic commit per phase (Step 9), so
> the commit hash isn't known when the Done line is written. If the project wants the hash linked
> inside each Done line, split into two commits: (1) commit the code → capture hash, (2) write the
> checkboxes + `— Done:` lines including the hash, then commit `docs(plan): trace Phase N (<hash>)`.

### Step 9: Commit and push (one atomic commit per phase)

Stage this phase's implementation changes **together with** the PLAN update (checkboxes + `— Done:`
traceability lines) in a single atomic commit, then push.

```bash
# stage the phase's code changes (be specific — avoid git add -A if unrelated files exist)
git add <phase files...> PLANS/PLAN-*.md

git commit -m "<type>(<scope>): implement Phase N — <short summary>" \
           -m "Plan: <PLAN file>. Gate: lint+build+test(+e2e) green. Trace: per-step Done lines."
git push
```

**Commit conventions** (follow `git-semantic-commits-skill`):

- Conventional Commits: `feat`/`fix`/`refactor`/`test`/`docs`/`chore` `(scope)`.
- One logical change per commit = the phase. Wrap body at 72 chars.
- Reference the PLAN in the body. Include a one-line gate proof.
- If the project's commitlint mandates a different format/width, follow it.
- Never mix style-only changes with logic in the same commit.

**Why code + PLAN in one commit:** keeps the PLAN perfectly in sync with the commit history and the
per-step traceability travels with the implementation it describes. (Use the two-commit split from
Step 8 if you need the hash inside the Done lines.)

**Push:** `git push` (set upstream if needed: `git push -u origin <branch>`). If push is rejected
(non-fast-forward), **stop and ask** — never force-push.

### Step 10: Final validation

When the last phase completes, sweep the PLAN for any unchecked box — phases, sub-steps, and
acceptance criteria should all be `[x]`:

```bash
grep -n "^- \[ \]" "<PLAN file>"        # ANY unchecked box anywhere = incomplete
```

If the grep is empty → all phases, sub-steps, and acceptance criteria are complete → report
success. If any `- [ ]` remains but all phases ran → report exactly which items are unmet and ask
the user (don't fabricate completion, don't tick boxes whose `Done when` isn't satisfied).

## Guardrails & Budget

`/run-plan` runs on opencode's **native agent loop** — by default it has NO runtime guardrails
(no idle auto-resume, no real token counting, no compaction-survival). To prevent runaway runs,
enforce these **soft, instruction-level budgets**. The agent obeys them; they are not enforced by
the runtime. Track each counter across the whole invocation.

| Guardrail | Default | Override (in the arg) | On breach |
|-----------|---------|-----------------------|-----------|
| Max phases per run | 12 | `--max-phases N` | HALT: report progress, emit `[goal:blocked]`, do not start the next phase |
| Max fix attempts PER gate step | 3 | — (Step 7) | HALT that phase (already in Step 7) |
| Max TOTAL fix attempts across the run | 20 | `--max-fixes N` | HALT: `[goal:blocked] budget exhausted` |
| Protected branch | `main`/`master` | — | HALT before the first commit (Step 3) |

**Enforcement:**

- Parse optional overrides from `$ARGUMENTS` first: `--max-phases N`, `--max-fixes N` (integers).
  Unknown/garbage flags are ignored, not folded into the plan path.
- Before each phase: `phases_done >= MAX_PHASES` → stop.
- After each fix attempt: increment `total_fixes`; `total_fixes >= MAX_FIXES` → stop.
- A HALT is terminal for the invocation — summarize what's done, what remains, the next concrete
  step, and the resume command. `/run-plan <PLAN>` is idempotent (completed phases stay `[x]`).

**Completion markers (structured terminal state):**

Always end the run with exactly one terminal block. These markers are the inter-skill terminal
protocol (e.g. `worktree-pipeline-skill` halts on `[goal:blocked]`). When the run was started
via `/goal`, ALSO close the goal through the plugin's `update_goal` tool (`complete` with
evidence, or `unmet` with a concrete blocker):

```text
# success — all phases done + acceptance criteria met
[goal:evidence] <one-line summary: phases done, gate results, key files, commit range>
[goal:complete]

# halted / blocked
[goal:blocked] <concrete reason — failing gate, budget exhausted, needs user input>
```

Rules:

- `[goal:complete]` is only valid when immediately preceded by a non-empty `[goal:evidence]` line
  (commands run + results) — keep this shape so a returning plugin accepts it.
- `[goal:blocked]` must state the specific blocker on the line above / inline.
- Markers go on their own final line(s) of the assistant response. `[plan:*]` aliases are
  acceptable when no plugin is present.

> **Runtime-enforced guardrails are available via `/goal`.** The soft budgets above are obeyed by
> the agent; the re-added goal plugin (`@prevalentware/opencode-goal-plugin`) enforces turn
> limits, no-progress safeguards, idle auto-resume, and evidence-gated completion when the run is
> driven through `/goal` (token/duration budgets apply only when configured via plugin options —
> both default to unset). Note the Docker endpoint stays plugin-inert until the v2 binary bump
> (#387).

## Reporting format

After each phase, emit a concise status block:

```markdown
## Phase N: <name> — ✅ committed & pushed
- Gate: lint ✓ | build ✓ | unit ✓ (12) | e2e ✓ (4, frontend)
- New code tests: added 3 (bar.test.ts, baz.test.ts)
- Trace: per-step `— Done:` lines written (fixes recorded on steps 2.1, 2.4)
- Commit: <hash> feat(auth): implement Phase 2 — login flow
- Next: Phase 3 — <name>
```

On a halted phase:

```markdown
## Phase N: <name> — ⛔ blocked after 3 fix attempts
- Failing gate: unit tests (2 failing) — see output below
- Last fix tried: <description>
- Action needed: <specific question for the user>
```

## Stop conditions

Stop the loop (do not advance) when any of these is true:

- **Gate red after 3 fix attempts** → report blocker, ask user.
- **Phase budget hit** (`phases_done >= MAX_PHASES`, default 12) → HALT, emit `[goal:blocked]`.
- **Global fix budget hit** (`total_fixes >= MAX_FIXES`, default 20) → HALT, emit `[goal:blocked] budget exhausted`.
- **Unrecoverable error** (missing dependency, env issue, permissions) → report, ask user.
- **User intervention needed** (architectural decision, ambiguous step) → ask, then resume.
- **User says pause/stop** ("stop", "pause", "halt") → stop cleanly at the current phase boundary.
- **Protected branch** (`main`/`master`) → stop before the first commit, ask.
- **All phases complete** → run Step 10 and finish.

Resume on the next incomplete phase by re-running `/run-plan <PLAN>` (idempotent: completed phases
are already `[x]` + traced and committed).

## Compose, don't duplicate

This skill orchestrates existing capabilities — it does not reimplement them:

| Capability | Reuse |
|-----------|-------|
| Parse plan / execute steps / delegate | `plan-execution-skill` |
| Update checkboxes / commit progress | `plan-updater-skill` |
| Verification philosophy / checkpoints | `verification-loop-skill` |
| Commit message format / granularity | `git-semantic-commits-skill` |
| Generate unit tests for new code | `testing-subagent` / `tdd-workflow-skill` |
| Lint discovery + fixing | `linting-workflow-skill` / `linting-subagent` |
| Diagnose failures | `error-resolver-workflow-skill` |
| Responsive/visual e2e | `responsive-audit-subagent` (loads subagent-only `playwright-responsive-audit-skill`; PTY-driven loop) |

## Integration with Other Skills

| Skill | Integration Point |
|-------|-------------------|
| `plan-execution-skill` | Source of plan structure + step delegation patterns |
| `plan-updater-skill` | Checkbox + commit mechanics (this skill inlines them per-phase + adds traceability) |
| `verification-loop-skill` | Gate philosophy; this skill makes gates mandatory per phase |
| `git-semantic-commits-skill` | Per-phase commit formatting |
| `worktree-pipeline-skill` | Authors the PLAN files this skill consumes (§PLAN Authoring); pipeline passes the explicit PLAN path (`PLANS/PLAN-${KEY}.md`) and plan review happens upstream — /run-plan never re-reviews |

## Best Practices

- **Discover commands once, persist them.** Record the resolved gate in `AGENTS.md` so future runs
  (and other agents) don't re-discover.
- **Never push red.** The gate is the contract; a failing gate halts, full stop.
- **Atomic per phase.** One commit = one phase's work + its checkboxes + its Done lines. Easy to
  review, easy to revert.
- **Always leave a trace.** Every completed step gets a `— Done:` line with the fixes applied —
  traceability is not optional.
- **Read fully, then act.** Trace each step's consumers before mutating (prevents confident-wrong fixes).
- **Frontend e2e is conditional.** Don't run Playwright on backend-only phases; don't install it unprompted.
- **Idempotent.** Re-running `/run-plan` resumes at the first unchecked phase.

## Example: `/run-plan PLAN-GIT-123.md`

```text
User: /run-plan PLAN-GIT-123.md

Agent: Resolved plan: PLANS/PLAN-GIT-123.md (5 phases, 3 already complete)
       Gate discovered: lint=npm run lint | build=npm run build | test=npx vitest run
                        e2e=npx playwright test (Playwright configured)
       Resuming at Phase 4: "Checkout flow" (frontend — e2e will run)

[implements Phase 4 steps, logging work per step]
[writes 2 missing unit tests for new Checkout components]
[gate: lint ✓ | build ✓ | unit ✓ (18) | e2e ✓ (6)]
[marks Phase 4 steps [x] + writes `— Done:` lines (records the email-regex fix on step 4.2)]
[commit: feat(checkout): implement Phase 4 — checkout flow  (abc1234)]
[push]

## Phase 4: Checkout flow — ✅ committed & pushed
- Gate: lint ✓ | build ✓ | unit ✓ (18) | e2e ✓ (6, frontend)
- New code tests: added 2 (CheckoutForm.test.tsx, useCart.test.ts)
- Trace: per-step `— Done:` lines written (fix on 4.2)
- Commit: abc1234
- Next: Phase 5 — <name>

Resulting PLAN excerpt (Phase 4, step 4.2):

  - [x] **4.2** Validate checkout form fields
      — **Why:** prevent invalid submissions
      — **Done when:** form blocks empty/invalid fields
      — **Consumers affected:** CheckoutButton
      — **Done:** Zod schema + inline error UI; files: src/checkout/CheckoutForm.tsx, schema.ts;
        fixes: tightened email regex after unit-test '+' edge case (fix-on-fail attempt 2)

… (Phase 5) …

All 5 phases complete. Acceptance criteria: 6/6 satisfied. ✅
```

## References

- `plan-execution-skill` — plan structure, step parsing, delegation matrix
- `plan-updater-skill` — checkbox + commit mechanics
- `verification-loop-skill` — verification checkpoints
- `git-semantic-commits-skill` — commit format + granularity
- `testing-subagent` / `tdd-workflow-skill` — unit-test generation
- `linting-workflow-skill` / `linting-subagent` — lint discovery + fixes
- `error-resolver-workflow-skill` — diagnose gate failures
- `responsive-audit-subagent` — cross-breakpoint UI verification (loads `playwright-responsive-audit-skill`; PTY-driven loop)
- `/run-plan` command — the primary entry point that loads this skill (defined in `opencode.json`
  `commands.run-plan`)

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.**
When unset, this skill behaves exactly as documented above; this block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

1. **Gate check:** confirm the env var is set; if unset, follow the default behavior above.
2. **Auto-detection:** if the run looks iterative (many phases, repeated fix cycles), prompt ONCE
   per session: "Enable autoresearch protocol for this run? (y/n)". Cache the answer.
3. **Evaluator contract:** the gate IS the evaluator — emit `{"pass":bool,"score":N}` from the
   verification gate output (pass = all gate steps green; score = fraction of gate steps green).
   Pass determines commit/push vs revert; no LLM self-judgment ("looks good" is forbidden).
4. **Git-as-memory:** commit before each gate verify; on `pass:false` after 3 attempts, leave the
   working tree intact and report (do NOT auto-revert phase work — surface it to the user).
5. **Stuck detection:** 3 consecutive non-green gates on the same phase → pivot approach;
   5 → escalate to user. See `autoresearch-core-skill/references/stuck-detection.md`.
6. **Bounded-by-default:** `Iterations: N` where N = number of incomplete phases. Hard cap 100.
   Each phase = one iteration. Safety blocks `.env`, `node_modules/`, `rm -rf`, `git push --force`.
7. **Audit trail:** append each phase result to `plan-automation-results.tsv`
   (columns: phase, commit, gate_steps_green, gate_steps_total, status, summary, timestamp).

### Skill-specific override

**The verification gate replaces LLM self-judgment.** "Phase done" is defined mechanically by the
gate (lint exit 0 + build exit 0 + unit tests pass + e2e pass when applicable), not by the agent
asserting completion. A phase with a red gate is NEVER marked complete (no checkbox, no Done line),
regardless of how the code reads.
