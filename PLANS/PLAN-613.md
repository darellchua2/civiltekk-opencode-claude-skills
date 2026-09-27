# PLAN: Fully inline /run-worktree-pipeline-v2 — zero subagents end to end

**Branch**: feat/613
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/613
**Base**: main

## Acceptance Criteria

- [ ] v2 command template spawns no subagents: Steps 7, 8, 9, 10 all in-session
- [ ] Step 7 reviewers run inline via deployed agent definitions as checklists (CLI + Docker resolution paths; unresolvable → report unavailable and stop)
- [ ] Step 9 code review inline; max 2 fix-re-review iterations + full re-gate-before-fix-push rule preserved
- [ ] Step 10 PR creation + merge watch inline (`gh` + background shell poll, no subagent)
- [ ] v1 `/run-worktree-pipeline` byte-unchanged (still subagent-driven)
- [ ] `deploy/opencode.json` parses as valid JSON; user-space entry matches template after redeploy
- [ ] README no longer claims Step 9/10 stay subagent-driven for v2; no stale wording remains (`rg "Step 9.*Step 10"`)

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it. Use `codegraph_callers` (code) or `tofu graph` + grep (IaC)._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/opencode.json` → `commands.run-worktree-pipeline-v2` | — | opencode runtime (command invocation); `deploy/setup.sh` (copies to user space); `installer/presets/pack-inline-workers.json` description references the command | medium |
| `README.md` two-flavors line | 1.1 (wording must match final template semantics) | humans, docs consumers; documentation-consistency checks that grep this claim | low |
| `installer/presets/pack-inline-workers.json` | — | `installer/init.mjs` / `npx ... add` preset installs | low |
| `tests/test_requires_skills.bats`, `tests/test_mcp_count_consistency.bats` | — | read only the `deploy/opencode.json` `mcp` block — no commands-block pins (inspected in Step 7 review; no breakage) | none |

Runtime behavior (template-following) is unverifiable by unit test — the AC
targets the config content itself; the redeploy step makes user space match.

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Command template substitution (source of truth)

- [x] **1.1** Rewrite `deploy/opencode.json` → `commands.run-worktree-pipeline-v2` description + template to the fully-inline contract: no subagent spawns anywhere in the run; Step 7 selected reviewers (architecture/language/uiux) run in-session by loading deployed `agents/<reviewer>-subagent.md` as checklist (`~/.config/opencode/agents/` CLI, `/app/.opencode/agents/` Docker; neither resolves → report unavailable, stop), `reviewer-baseline-skill` first, same severity gates + Return Contract, requirements-specialist Mode R relay in-session the same way; Step 8 via `plan-execution-inline-skill` with the explicit PLAN path; Step 9 by loading `agents/code-review-subagent.md` as checklist, computing `git diff origin/<base>...feat/<KEY>` directly in the worktree, writing LEARNINGS directly, max 2 fix-re-review iterations + full re-gate-before-fix-push unchanged; Step 10 by loading `agents/pr-workflow-subagent.md` as checklist, PR via `gh` in-session, merge watch via background shell poll instead of a background subagent; pin `subagent: false` explicitly (mechanism parity with `/review-inline`, NOTE-2 of Step 7 review)
    — **Why:** this substitution is the feature — every downstream step (README claim, preset membership, user-space runtime behavior) derives from this template
    — **Done when:** the JSON entry parses; its text contains "spawn no subagents" (or equivalent prohibition), the `agents/<reviewer>-subagent.md` checklist mechanism for Steps 7/9/10, both resolution paths, and the background-shell merge watch
    — **Consumers affected:** opencode runtime, setup.sh copy, preset description
    — **Done:** v2 entry rewritten to the fully-inline contract (all four steps in-session, both resolution paths, `subagent: false` pin); files: deploy/opencode.json; fixes: none
- [x] **1.2** Byte-guard the v1 command: verify `commands.run-worktree-pipeline` (and `review-arch`/`review-inline`) are untouched by the edit
    — **Why:** the ticket requires v1 stays subagent-driven; a template-wide edit could silently drift siblings (the 2026-09-26 stale-write clobber precedent)
    — **Done when:** `git diff` on `deploy/opencode.json` shows changes only inside the `run-worktree-pipeline-v2` key
    — **Consumers affected:** v1 pipeline users (unchanged behavior)
    — **Done:** diff scoped to the single `@@ -661,3 +661,4 @@` hunk (v2 entry only); no sibling command keys in the diff; files: deploy/opencode.json; fixes: none

### Phase 2: Docs + preset sync

- [ ] **2.1** Update the `README.md` two-flavors line: v2 becomes "fully in-session, zero subagents end to end"; drop the "pipeline Step 9 review + Step 10 PR stay subagent-driven" claim
    — **Why:** README is the usage contract; a stale claim would tell users v2 spawns reviewer subagents after they've been removed
    — **Done when:** `rg "Step 9" README.md` finds no subagent-driven claim for v2, and the line states both flavors' true behavior
    — **Consumers affected:** docs readers; documentation-consistency sweeps
- [ ] **2.2** Update `installer/presets/pack-inline-workers.json`: add `reviewer-baseline-skill` and `language-review-checklists-skill` (the two skills the v2 template names explicitly) to the skills array; NARROW the description to "reviewer baselines for inline pipeline reviews" — no full reviewer-knowledge-closure claim (WARN-1 resolution: the agents' full knowledge closure is ~40 skills, several unregistered — graceful degradation, not silent breakage; full closure deferred to a follow-up ticket)
    — **Why:** the pack's contract forbids claiming coverage it doesn't carry; the two named skills are the non-negotiable inline-review baselines the template instructs to load first
    — **Done when:** both skill names appear in the preset's skills array and the description claims only baselines (no "review coverage" overclaim)
    — **Consumers affected:** `npx ... add` / preset installs
- [ ] **2.3** Sweep stale wording repo-wide: `rg "Step 9.*Step 10" README.md deploy/ installer/`, `rg "run-worktree-pipeline-v2"`, and `rg -in "subagent-driven|remain subagent|stay subagent" README.md deploy/ installer/ agents/ skills/` — fix any remaining "subagent-driven at Step 9/10 for v2" phrasing (CHANGELOG and PLANS history lines are immutable, skip them)
    — **Why:** the AC bans stale wording; directory-scoped sweeps miss repo-root docs (documented anti-pattern), and single-pattern sweeps miss one-step phrasings (NOTE-4)
    — **Done when:** all three rg sweeps return only historical (CHANGELOG/PLANS) or already-correct matches
    — **Consumers affected:** none beyond docs accuracy

### Phase 3: Redeploy + end-to-end verification

- [ ] **3.1** Run `./deploy/setup.sh` to refresh user-space config from the template
    — **Why:** the runtime reads `~/.config/opencode/opencode.json`, not the repo; source-of-truth edits are inert until deployed (AGENTS.md: never edit deployed copies directly)
    — **Done when:** setup.sh exits 0
    — **Consumers affected:** user-space runtime for all sessions
- [ ] **3.2** Verify the deployed entry: `python3` JSON-parse of user-space `~/.config/opencode/opencode.json`, byte-compare `commands.run-worktree-pipeline-v2` against the template, and confirm v1 + `review-arch`/`review-inline` entries byte-equal their pre-change state — baseline = `git show origin/main:deploy/opencode.json` (clean reference, never the possibly-drifted user-space copy, NOTE-3)
    — **Why:** AC#6 — template/user-space parity and the v1-unchanged guard at the artifact the runtime actually reads
    — **Done when:** parse exits 0; the four entry comparisons against the named git baseline report equal
    — **Consumers affected:** runtime command resolution (verified)
- [ ] **3.3** Full-gate run and final AC sweep: run the verification gate (lint/typecheck/build/unit per repo discovery — bats tests exist under `tests/`), then tick PLAN acceptance criteria against evidence
    — **Why:** the exit gate is the run's last gate; AC ticks need evidence, not intent
    — **Done when:** gate memo carries `tier=full` green for the final tree; all 7 AC checkboxes ticked with evidence lines
    — **Consumers affected:** PR creation (Step 10 cites this memo)

## Technical Notes

- Substitution pattern precedent: #597 (Step 8 substitution via command template; skill body stays shared). v1 behavior is preserved by not touching `worktree-pipeline-skill/SKILL.md`.
- In-session reviewer mechanism precedent: the `/review-inline` command template (`deploy/opencode.json:649-654`) — deployed agent definition loaded as checklist, same workflow/severity gates/Return Contract.
- Inline review tradeoff (accepted by user): reviewers share the building context — fresh-eyes isolation is lost by design on v2; v1 remains the isolated-review flavor.
- The `agent` field of the v2 command stays `build` (in-session execution requires the build agent, not a subagent).
- Conventional Commits: config change = `feat(opencode): ...` or per-scope splits (docs/preset separate); commitlint body ≤72 chars.
- Preflight asymmetry (NOTE-1, pre-existing since #597): the shared skill's dependency preflight hard-requires `plan-execution-skill` though v2 never invokes it — minimal inline-preset installs abort at preflight. SKILL.md stays untouched here (v1-byte-unchanged design); follow-up ticket to be filed for inline-aware preflight.
- Preset closure decision (WARN-1): description narrowed to reviewer baselines; full knowledge-closure enumeration (~40 skills, several unregistered) rejected as unshippable — follow-up ticket may revisit with a registered-skills-only closure.

## Dependencies

None — single ticket, no `blocked-by:` refs.

## Risks & Mitigation

- **Template/runtime drift**: the runtime may not follow long inline-review instructions verbatim → mitigation: template phrasing mirrors the proven `/review-inline` mechanism; acceptance is config-content per the AC, runtime behavior observed on first v2 run.
- **User-space clobber on redeploy** (seen 2026-09-26): setup.sh could restore stale state → mitigation: step 3.2's byte-compare catches drift immediately.
- **Reviewer anchoring**: inline reviewers see the whole build history → mitigation: `reviewer-baseline-skill` loaded first (epistemic honesty rules); severity gates unchanged.
- **Preset drift**: adding skills to the pack without registry impact — presets are installer-only (init.mjs reads registry.json; pack skills need registry entries, both already registered) → mitigation: `node installer/build-registry.mjs` not required (no frontmatter change), verified by pack JSON parse.
