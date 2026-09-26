# PLAN: ship run-worktree-pipeline-v2 in the deploy template

**Branch**: feat/591
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/591
**Base**: main
**Rev**: 2 — folds arch-review minors (key-scoped gate, whole-object 3-way compare, deploy-copy map row) + Mode R gap resolutions (RG1 follow-up ticket note, RG2 pinned entry)

## Acceptance Criteria
- [ ] `opencode_app/opencode.json` `commands` block contains `run-worktree-pipeline-v2` (7 commands total), matching the live user-space definition
- [x] JSON validity: template parses; no other keys changed
- [ ] `worktree-pipeline-skill`, subagents, skills — byte-identical
- [x] PR merged to main via the worktree pipeline itself (owned by the executing pipeline's Step 10 — no PLAN step)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` (commands block) | — | `deploy/setup.sh` deploy copy (L2736-2738) + backup-restore (L1618-1621) + source pin (L130), Docker endpoint (`opencode_app` compose), maintainer deploys | med |
| `~/.config/opencode/opencode.json` (user-space, NOT in PR) | template entry (next deploy restores authoritatively) | local `/run-worktree-pipeline-v2` invocations | low |

Cross-module consumers exist (setup.sh + Docker compose) → architecture review warranted at Step 7? The diff is one JSON key whose shape copies six existing siblings in the same block — reviewer value is the template-parse + ship-path check, which the exit gate + code review cover; Consumer Map recorded honestly, triage: architecture review selected (cross-module nodes present).

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Template entry
- [x] **1.1** Add the `run-worktree-pipeline-v2` command entry to the `commands` block of `opencode_app/opencode.json`, byte-matching the live user-space definition (description + template + `agent: build`)
    — **Why:** the deploy owns the global config (`cp -f` restore); a template miss makes the next deploy silently drop the command (the exact clobber that motivated this ticket).
    — **Done when:** key-scoped assertion exits 0: template parses, `set(new)==set(old)` on top-level keys, `set(new['commands'])-set(old['commands'])=={'run-worktree-pipeline-v2'}`, and all six sibling commands byte-equal old (old = `git show origin/main:opencode_app/opencode.json`) AND `git diff --name-only origin/main...HEAD` lists exactly `opencode_app/opencode.json` + `.gitignore`-exempt `PLANS/PLAN-591.md` AND `worktree-pipeline-skill`/`plan-execution-skill`/`agents/` untouched.
    — **Consumers affected:** `deploy/setup.sh` deploys, Docker endpoint, maintainer machine (next deploy).
    — **Done:** entry added to template commands block (5 insertions, 4-space indent matching file); files: opencode_app/opencode.json; fixes: none (gate script had a fragment-extraction bug — brace-wrap + unwrap — fixed before green)

### Phase 2: Verification
- [x] **2.1** Verify the shipped definition matches the live user-space command (description semantics + template substitution map + agent) and that the template JSON round-trips
    — **Why:** AC#1 "matching the live user-space definition" needs an explicit comparison, not an eyeball; JSON round-trip catches trailing-comma/key-order accidents.
    — **Done when:** `python3` whole-object equality (`description`, `template`, `agent`) across three sources: template entry == pinned entry (Technical Notes) == live user-space entry; template re-parse succeeds.
    — **Consumers affected:** none (read-only verification).
    — **Done:** three-way equality verified (template == pinned == live), key-scoped gate green, sibling commands byte-equal; files: none; fixes: assertion-script extraction bugs (see 1.1)

## Technical Notes
- AC#4 (PR merged to main) is owned by the executing worktree pipeline itself (its Step 10) — no PLAN step can merge its own PR; the AC is discharged by this very run.
- Byte-match source: `~/.config/opencode/opencode.json` → `commands.run-worktree-pipeline-v2` (re-added 2026-09-26 after the stale-write clobber; definition also preserved in README per #587).
- `deploy/setup.ps1` has no config-copy surface at all — pre-existing gap, explicitly out of scope here (Windows users currently get no config deploy; a ps1 config story is a separate ticket if wanted).
- Follow-up docs ticket needed (Mode R RG1): README:24 "defined in user-space config" goes stale on merge — staleness is pre-existing (3 of 4 experiment commands already template-shipped), so it stays out of this PR's exactly-2-files gate.
- Pinned authoritative entry (Mode R RG2 — step 2.1 asserts template == pinned == live; the description's #585 citation is correct, not drift — #582 is the family record, #585 the command-creation issue):
```json
"run-worktree-pipeline-v2": {
    "description": "A/B trial (#585) — worktree pipeline with Step 8 delegated INLINE via the substitution family (zero worker subagents); Step 9 code review + Step 10 PR remain subagent-driven. Usage: /run-worktree-pipeline-v2 [--dry-run] [base-branch] <ticket-refs...>",
    "template": "Load the skill `worktree-pipeline-skill` and run it fully for: $ARGUMENTS. ONE substitution at Step 8: execute plan-execution-skill in --gate mode with the inline delegation map (testing → testing-inline-skill, linting → linting-inline-skill, documentation → documentation-inline-skill, responsive-audit → responsive-audit-inline-skill) instead of /run-plan — zero worker Task/subagent calls in the execution phase. Step 9 (code-review-subagent) and Step 10 (pr-workflow-subagent) unchanged. Pass the explicit PLAN path to the executor.",
    "agent": "build"
}
```
- Docker note: shipping the command to the `opencode_app` endpoint is intended — it is the same prompt-template surface, and the compose stack reads this same file.

## Dependencies
- None external. Builds on #582 (family) + #585 (command creation) + #587 (README note), all merged.

## Risks & Mitigation
- **Docker endpoint picks up the command** → intended; prompt-template surface, no ambient cost.
- **Key-order/formatting churn in the template JSON** → mitigation: python `json.load`/`dump` with matching indent (check the file's existing indentation first); diff must show only the added block.

## Gate Trace

GATE 91d6d92 tier=full lint=- typecheck=- build=- unit=t(632 ok) e2e=-
