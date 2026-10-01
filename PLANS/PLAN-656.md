# PLAN: Consolidate pipeline + plan command pairs into single inline-default commands

**Branch**: feat/656
**Issue**: https://github.com/darellchua2/civiltekk-skills/issues/656
**Base**: main

## Acceptance Criteria

From ticket #656 — inherited verbatim; these are the definition of done:

- [x] `deploy/opencode.json`: `run-worktree-pipeline` carries the inline-default template + arm-selection sentence (`agent: build`, `subagent: false`); `run-plan` routes to the inline executor by default; `run-worktree-pipeline-v2` and `run-plan-v2` keys are deleted
- [x] `worktree-pipeline-skill` SKILL.md carries the arm-selection rule (inline default; subagent = explicit request + OpenCode harness + deps resolve, else inline fallback with note) as a portability capability block; preflight checks the inline dep set first and the subagent set only on opt-in
- [x] `plan-execution-inline-skill` and `plan-execution-skill` each carry a sibling-routing one-liner with the same 3 conditions
- [x] README command table + two-flavors paragraph rewritten: one flavor per flow, inline default, subagent opt-in OpenCode-only
- [x] `tests/test_v2_pipeline_contract.bats` repurposed to pin the consolidated entry (inline-default pins, opt-in conditions, both `-v2` keys absent); no test anywhere pins `run-plan-v2`
- [x] `installer/presets/pack-inline-workers.json` `-v2` wording updated
- [x] `installer/registry.json` regenerated if any SKILL.md description changed
- [x] Live `~/.config/opencode/opencode.json` surgically updated (2 command keys updated, 2 v2 keys deleted)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `skills/worktree-pipeline-skill/SKILL.md` | 1.1 wording decided before 2.1 template cites it | `/run-worktree-pipeline` + `/worktree-pipeline-preview` command templates (load the skill), `tests/test_v2_pipeline_contract.bats` (preflight grep pins "resolved per arm" + both executor names), `installer/registry.json` (description only), preset membership | medium |
| `deploy/opencode.json` → `commands` | Phase 1 (templates cite the skill's arm rule) | opencode runtime (every pipeline/plan invocation), `deploy/setup.sh` (copies to user space), `tests/test_v2_pipeline_contract.bats`, `installer/presets/pack-inline-workers.json` (prose references) | high |
| `skills/plan-execution-inline-skill/SKILL.md` | — | `/run-plan` (new default route), worktree-pipeline Step 8 inline arm, `pack-inline-workers` preset, dependency-map requiresSkills edges | low |
| `skills/plan-execution-skill/SKILL.md` | — | `/run-plan` (opt-in route), worktree-pipeline Step 8 subagent arm | low |
| `tests/test_v2_pipeline_contract.bats` | Phases 1–2 (pins the new entries) | CI gate (every PR) | medium |
| `README.md` (~16–24, ~95, ~274) | Phases 1–2 (describes what exists) | humans, docs-sync audits | low |
| `installer/presets/pack-inline-workers.json` | Phase 2 (references command names) | `installer/init.mjs --preset inline-workers`, preset description text in README ~95 | low (hand-maintained file — surgical edit only) |
| `installer/registry.json` | SKILL.md frontmatter (unchanged by design) | `installer/init.mjs`, `installer/build-registry.mjs` | low (expected byte-unchanged) |
| `~/.config/opencode/opencode.json` (user-space, outside repo) | Phase 2 template (source of the merged entries) | live command invocations; next `setup.sh` deploy restores authoritatively | medium (surgical single-key edits — permissions preserved) |

## Implementation Phases

### Phase 1: Skill layer — the arm contract (one commit)

— **Done (1.1):** arm-selection capability block + preflight flip + What-I-do/Steps 7/8/9/10a markers + stale-v1 note removed; pins verified (`resolved per arm`=1, both executor names=3 each, v2-string=0, frontmatter untouched — first diff hunk @L17); files: skills/worktree-pipeline-skill/SKILL.md; fixes: none
— **Done (1.2):** sibling-routing block (default-executor, 3 conditions, inline-with-note) inserted after the inline-trade paragraph; frontmatter byte-unchanged; files: skills/plan-execution-inline-skill/SKILL.md; fixes: none
— **Done (1.3):** mirror opt-in routing block inserted between What-I-do and Modes; frontmatter byte-unchanged; files: skills/plan-execution-skill/SKILL.md; fixes: none

GATE 62da9cb tier=light lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a

- [x] **1.1** Rewrite the arm-selection contract in `skills/worktree-pipeline-skill/SKILL.md`: the "Dependency preflight (per-skill installs, resolved per arm)" block (lines ~65–79) flips to inline-default — inline dep set (`plan-execution-inline-skill`, `code-review-inline-skill`, `civiltekk-pr-workflow-skill`, `architecture-review-skill`) is THE primary set; the subagent set (`plan-execution-skill` --gate, `code-review-subagent`, `pr-workflow-subagent`) is checked only on explicit opt-in. Add the opt-in rule as a §Portability capability block: subagent orchestration requires (1) explicit user request, (2) harness is OpenCode, (3) subagent deps resolve — any unmet condition → run inline with a prominent note, never abort. Keep the literal phrases `resolved per arm` and both executor skill names (test pins). Sweep the rest of the body (§What I do, Steps 7/9/10 arm references, §Guarantees) for "v1/v2 template marks the arm" wording and repoint to the new default/opt-in rule. Description frontmatter untouched.
    — **Why:** the arm fork currently lives only in command templates (OpenCode-only, name-collision-prone); moving it into the skill makes it portable and kills the `-v2` prose collapse at the root.
    — **Done when:** SKILL.md states inline-default + 3-condition opt-in + inline-fallback-with-note; `grep -c "resolved per arm"` ≥ 1 and both executor skill names still present; no `run-worktree-pipeline-v2` string remains in the file; description frontmatter byte-unchanged.
    — **Consumers affected:** both pipeline command templates (v2 semantics become the single template's), `tests/test_v2_pipeline_contract.bats` preflight grep, natural-language invocation on non-OpenCode harnesses (now gets inline deterministically).

- [x] **1.2** Add a sibling-routing one-liner to `skills/plan-execution-inline-skill/SKILL.md` body (after the frontmatter intro): "Default executor for `/run-plan` and pipeline Step 8. The subagent sibling `plan-execution-skill` (--gate) runs only on explicit user request + OpenCode harness + deps resolve; otherwise this skill executes with a note." Body-only — frontmatter untouched.
    — **Why:** the plan pair spans two skills (not merged, by ticket decision); the routing rule must be visible from the skill layer so natural-language invocation on any harness resolves the same way the command does.
    — **Done when:** the one-liner exists; frontmatter byte-unchanged (registry unaffected).
    — **Consumers affected:** `/run-plan` invocations, worktree-pipeline Step 8, `pack-inline-workers` preset consumers.

- [x] **1.3** Add the mirror one-liner to `skills/plan-execution-skill/SKILL.md` body: "Opt-in executor: invoked only when the user explicitly requests subagent orchestration on OpenCode and this skill resolves; otherwise `plan-execution-inline-skill` executes the same plan inline (same gate contract)." Body-only — frontmatter untouched.
    — **Why:** symmetric routing — a reader landing on the subagent skill must learn it is the opt-in arm, not the default.
    — **Done when:** one-liner exists; frontmatter byte-unchanged.
    — **Consumers affected:** `/run-plan` opt-in route, pipeline Step 8 subagent arm.

### Phase 2: Command layer — merge + delete (one commit)

— **Done (2.1):** `run-worktree-pipeline` template = arm sentence + full former-v2 template (extracted programmatically — no transcription); `agent: build`, `subagent: false`; description single-flavor; files: deploy/opencode.json; fixes: none
— **Done (2.2):** `run-plan` template routes inline-default with the 3-condition opt-in to `plan-execution-skill` --gate; `subagent: false`; description keeps /goal-path note; files: deploy/opencode.json; fixes: none
— **Done (2.3):** both `-v2` keys deleted; commands = [run-plan, create-ticket, run-worktree-pipeline, review-arch, review-inline, worktree-pipeline-preview]; siblings + permissions + mcp deep-equal HEAD; files: deploy/opencode.json; fixes: render() first attempt dropped trailing commas on middle entries → JSON invalid → restored from git and re-ran with comma fix (1 fix, caught by the in-script parse)

GATE e849424 tier=light lint=t (JSON.parse + deep-equal siblings vs HEAD) typecheck=n.a build=n.a unit=stale-until-3.1 (contract test pins deleted v2 key — intentional transition state, PLAN-650 precedent; push deferred to Phase 3 boundary — never push red) e2e=n.a

- [x] **2.1** Rewrite `deploy/opencode.json` → `commands.run-worktree-pipeline`: template = the current `run-worktree-pipeline-v2` template body, prefixed with the arm sentence "Run fully INLINE by default per worktree-pipeline-skill §arm selection — subagent orchestration only on explicit user request + OpenCode + deps resolve (unavailable → proceed inline with a prominent note)." Set `subagent: false`; keep `agent: "build"`; update `description` to the single-flavor contract (usage line unchanged).
    — **Why:** one command, inline default — the ticket's core consolidation; `subagent: false` keeps command execution in-session for the inline arm.
    — **Done when:** template carries "spawn NO subagents anywhere in the run" + all four inline skill names + the arm sentence; `subagent === false`; `agent === "build"`; JSON parses.
    — **Consumers affected:** every pipeline invocation; `tests/test_v2_pipeline_contract.bats` (pins this entry); setup.sh deploys.

- [x] **2.2** Rewrite `deploy/opencode.json` → `commands.run-plan`: template = "Execute the plan file given as the argument INLINE by default via `plan-execution-inline-skill` (same gate contract): $ARGUMENTS. Route to `plan-execution-skill` --gate (subagent workers) ONLY on explicit user request + OpenCode harness + the skill resolving; otherwise proceed inline with a note." Set `subagent: false`; keep `agent: "build"`; update `description` (keep the /goal-path note).
    — **Why:** same consolidation for the plan pair; routing (not skill merge) per ticket decision.
    — **Done when:** template names both executors + the 3-condition opt-in; `subagent === false`; JSON parses.
    — **Consumers affected:** every /run-plan invocation; long-hands-off /goal runs that cite it.

- [x] **2.3** Delete `commands.run-worktree-pipeline-v2` and `commands.run-plan-v2` from `deploy/opencode.json` (same commit as 2.1–2.2).
    — **Why:** hard-delete per ticket decision — the `-v2` spellings are the collision surface; prose mentioning them now resolves to the single inline-default command.
    — **Done when:** neither key exists in the parsed JSON; sibling command entries byte-unchanged.
    — **Consumers affected:** muscle-memory `-v2` invocations (fail loudly in the palette → user retypes the single name), docs and tests updated in Phases 3–4.

### Phase 3: Tests — repin the consolidated contract (one commit)

— **Done (3.1):** contract guard rewritten: 11 tests pinning the consolidated entries (subagent:false, zero-subagent directive, steps 7/9/10 inline mechanics, opt-in sentence, run-plan inline routing, both -v2 keys ABSENT, Docker dead-letter, preset guards, arm-aware preflight, sibling one-liner pins) — bats 11/11 green; files: tests/test_v2_pipeline_contract.bats; fixes: none
— **Done (3.2):** sweep complete — live hits dispositioned: README + pack-inline-workers.json → Phase 4; skills/architecture-review-skill/SKILL.md → fixed in place (dead command reference repointed to the skill's inline arm, body-only); LEARNINGS ×2 → immutable-history skip; tests file → absence-pin only; files: skills/architecture-review-skill/SKILL.md; fixes: none

- [x] **3.1** Repurpose `tests/test_v2_pipeline_contract.bats` to pin the consolidated entries: retarget the template assertions from the deleted `run-worktree-pipeline-v2` key to `run-worktree-pipeline` (zero-subagent directive, `code-review-inline-skill` / `civiltekk-pr-workflow-skill` / `create route` / `reviewer-baseline-skill` phrases, `subagent:false`); add assertions that BOTH `-v2` keys are absent and that `run-plan` names `plan-execution-inline-skill` as default + carries the opt-in phrase; keep the Docker dead-letter, preset-caveat, preset-membership, and arm-aware preflight tests (preflight grep pins stay valid — 1.1 preserved the phrases).
    — **Why:** the contract test is the drift guard for a template reshaped 3× before; it must pin the new shape or CI green-lies.
    — **Done when:** `bats tests/test_v2_pipeline_contract.bats` passes against the Phase 2 tree; every assertion names an entry that exists; the two sibling SKILL.md bodies (plan-execution-inline-skill, plan-execution-skill) each match a grep for the routing one-liner phrase "explicit user request" (all skill-layer restatements of the 3-condition rule CI-pinned — review Finding 2).
    — **Consumers affected:** CI gate on every PR; future template edits (guarded).

- [x] **3.2** Sweep the repo for `run-worktree-pipeline-v2` / `run-plan-v2` in live files (exclude `PLANS/`, `CHANGELOG.md`, `.git/`): every hit dispositioned — README and installer preset fixed in Phase 4, historical LEARNINGS bodies left intact with a one-line justification (immutable history), any hit in `opencode_app/` or other configs fixed in place.
    — **Why:** stale spellings in live docs teach users the dead command; the sweep is the AC's "no test anywhere pins run-plan-v2" plus its generalization.
    — **Done when:** the grep lists zero live-file hits outside the documented skips.
    — **Consumers affected:** readers of README/preset; future greppers.

### Phase 4: Docs + installer wording (one commit)

— **Done (4.1):** README updated — both command table rows carry inline-default wording, two-flavors paragraph → "One execution flavor — inline by default" with the opt-in + fallback-note semantics, preset table row + category listing repointed; zero `-v2` spellings remain; files: README.md; fixes: none
— **Done (4.2):** preset `$comment` + `description` surgically repointed to the inline-default commands; JSON parses; `skills` array untouched; files: installer/presets/pack-inline-workers.json; fixes: none
— **Done (5.1):** live `~/.config/opencode/opencode.json` surgically updated at its own 2-space indentation (first attempt assumed template indentation — no-op, no write; re-ran adapted): both consolidated entries deep-equal template, both `-v2` keys deleted, command set matches template, sibling entries + mcp deep-equal pre-change baseline, `architecture-review-skill` allow entry restored (allowlist 71, no duplicates — skill load confirmed working in-session); files: ~/.config/opencode/opencode.json (user-space, no repo commit); fixes: none
— **Done (4.3):** `git diff --stat installer/registry.json` empty — all Phase 1 skill edits verified body-only, no regen needed (justification: registry derives from description frontmatter, which is byte-unchanged); files: none; fixes: none

- [x] **4.1** Update `README.md`: command table (single `/run-worktree-pipeline` + `/run-plan` rows with inline-default descriptions), replace the two-flavors paragraph (~line 24) with the single-flavor contract (inline default everywhere; subagent orchestration OpenCode-only on explicit request), fix the preset table row (~95) and category listing (~274) wording.
    — **Why:** README is the usage-docs home; it currently teaches the dead `-v2` commands.
    — **Done when:** no `-v2` command spelling remains in README; the paragraph states default + opt-in + fallback-note semantics.
    — **Consumers affected:** humans; docs-sync audits (counts unchanged — no skills/agents added or removed).

- [x] **4.2** Update `installer/presets/pack-inline-workers.json` `$comment` + `description`: replace `/run-worktree-pipeline-v2` / `/run-plan-v2` command references with the consolidated inline-default names (e.g. "the /run-worktree-pipeline inline architecture-review route"). Surgical string edits only — the file is hand-maintained and regenerating would drop it.
    — **Why:** the preset prose names commands that will not exist.
    — **Done when:** both fields parse as JSON and carry no `-v2` spelling; `skills` array byte-unchanged.
    — **Consumers affected:** `installer/init.mjs --preset inline-workers` consumers, preset documentation.

- [x] **4.3** Registry check: confirm no SKILL.md `description` frontmatter changed in Phase 1 (all edits body-only). If — and only if — any description changed, run `node installer/build-registry.mjs` and commit the regen; otherwise report `installer/registry.json` byte-unchanged with that justification.
    — **Why:** the registry derives from frontmatter; body-only edits must not touch it (spurious regens churn the diff).
    — **Done when:** `git diff --stat installer/registry.json` is empty with the body-only justification stated, or the regen is committed alongside the verified frontmatter change.
    — **Consumers affected:** `installer/init.mjs` (reads registry.json), build-registry CI expectations.

### Phase 5: Live user-space deploy (local mutation — no repo commit)

- [x] **5.1** Surgically update `~/.config/opencode/opencode.json`: set `commands.run-worktree-pipeline` and `commands.run-plan` to the Phase 2 entries (byte-matching the template), delete both `-v2` keys, preserving every other key including `permissions` customizations. Additionally restore the template-declared skill-allow entries missing from the live allowlist — at minimum `architecture-review-skill` (drift observed during Step 7: template allows it, live 69-entry allowlist does not, skill load got `permission.rejected` — review Finding 1). Verify: file parses; the two keys equal the template entries; the `-v2` keys are gone; sibling entries byte-unchanged; `architecture-review-skill` present in the allowlist.
    — **Why:** the live config is what the next `/run-worktree-pipeline` invocation actually reads; without this, the merge lands only on next full deploy (whose config copy is prompt-guarded — PLAN-613 precedent) — and the prompt-guarded copy also strands every template-added permission entry (Finding 1).
    — **Done when:** the node JSON assertions above all pass against the live file.
    — **Consumers affected:** every command invocation in the user's sessions from now on.

## Technical Notes

- 3-condition opt-in rule (everywhere identical): (1) explicit user request, (2) harness is OpenCode, (3) subagent deps resolve — unmet → inline fallback with a prominent note, never abort.
- Keep the literal test-pinned phrases in `worktree-pipeline-skill/SKILL.md`: `resolved per arm`, `plan-execution-inline-skill`, `plan-execution-skill`.
- Do not merge the two plan-execution skills (ticket decision); routing only.
- LEARNINGS capture (decision: command-layer fork → inline-default consolidation) rides the pipeline's end-of-ticket `chore(learnings)` commit, not a phase commit.

## Dependencies

- None (no blocked-by tickets; all deps in-repo).

## Risks & Mitigations

- **Muscle-memory `-v2` invocations fail loudly** → acceptable per ticket decision (hard-delete); palette retypes to the single name; prose `-v2` mentions now resolve to inline-default semantics anyway.
- **Test pins drift from template wording** → 3.1 authored against the exact 2.1 phrases; executor re-runs bats after Phase 2+3.
- **Live-config surgical edit clobbers permissions** → 5.1 asserts sibling entries byte-unchanged; baseline = `git show origin/main:deploy/opencode.json` for template equality, never the possibly-drifted live copy.
- **Hand-maintained preset dropped by a careless regen** → 4.2 is surgical string edits; no generator runs.
GATE 487e8b1 tier=light lint=n.a typecheck=n.a build=n.a unit=t (bats contract 11/11; sweep dispositioned) e2e=n.a
GATE 0ac028b tier=full lint=t (JSON.parse preset) typecheck=n.a build=n.a unit=t (bats tests/ 646/646 — full suite, exit-gate tree: Phase 5 is repo-commit-free) e2e=n.a
