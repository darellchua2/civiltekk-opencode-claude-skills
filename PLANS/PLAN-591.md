# PLAN: ship run-worktree-pipeline-v2 in the deploy template

**Branch**: feat/591
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/591
**Base**: main

## Acceptance Criteria
- [ ] `opencode_app/opencode.json` `commands` block contains `run-worktree-pipeline-v2` (7 commands total), matching the live user-space definition
- [ ] JSON validity: template parses; no other keys changed
- [ ] `worktree-pipeline-skill`, subagents, skills — byte-identical
- [ ] PR merged to main via the worktree pipeline itself (owned by the executing pipeline's Step 10 — no PLAN step)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` (commands block) | — | `deploy/setup.sh` copy (L130, L1618-1621), Docker endpoint (`opencode_app` compose), maintainer deploys | med |
| `~/.config/opencode/opencode.json` (user-space, NOT in PR) | template entry (next deploy restores authoritatively) | local `/run-worktree-pipeline-v2` invocations | low |

Cross-module consumers exist (setup.sh + Docker compose) → architecture review warranted at Step 7? The diff is one JSON key whose shape copies six existing siblings in the same block — reviewer value is the template-parse + ship-path check, which the exit gate + code review cover; Consumer Map recorded honestly, triage: architecture review selected (cross-module nodes present).

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Template entry
- [ ] **1.1** Add the `run-worktree-pipeline-v2` command entry to the `commands` block of `opencode_app/opencode.json`, byte-matching the live user-space definition (description + template + `agent: build`)
    — **Why:** the deploy owns the global config (`cp -f` restore); a template miss makes the next deploy silently drop the command (the exact clobber that motivated this ticket).
    — **Done when:** `python3 -c "import json;t=json.load(open('opencode_app/opencode.json'));assert 'run-worktree-pipeline-v2' in t['commands'] and len(t['commands'])==7"` exits 0 AND `git diff --name-only origin/main...HEAD` lists exactly `opencode_app/opencode.json` plus `PLANS/PLAN-591.md` (riding PLAN, exempt per zero-reference-gate learnings) AND `worktree-pipeline-skill`/`plan-execution-skill`/`agents/` untouched.
    — **Consumers affected:** `deploy/setup.sh` deploys, Docker endpoint, maintainer machine (next deploy).

### Phase 2: Verification
- [ ] **2.1** Verify the shipped definition matches the live user-space command (description semantics + template substitution map + agent) and that the template JSON round-trips
    — **Why:** AC#1 "matching the live user-space definition" needs an explicit comparison, not an eyeball; JSON round-trip catches trailing-comma/key-order accidents.
    — **Done when:** `python3` comparison of the two command objects' `template` fields returns equal, and template re-parse succeeds.
    — **Consumers affected:** none (read-only verification).

## Technical Notes
- AC#4 (PR merged to main) is owned by the executing worktree pipeline itself (its Step 10) — no PLAN step can merge its own PR; the AC is discharged by this very run.
- Byte-match source: `~/.config/opencode/opencode.json` → `commands.run-worktree-pipeline-v2` (re-added 2026-09-26 after the stale-write clobber; definition also preserved in README per #587).
- `deploy/setup.ps1` has no config-copy surface at all — pre-existing gap, explicitly out of scope here (Windows users currently get no config deploy; a ps1 config story is a separate ticket if wanted).
- Docker note: shipping the command to the `opencode_app` endpoint is intended — it is the same prompt-template surface, and the compose stack reads this same file.

## Dependencies
- None external. Builds on #582 (family) + #585 (command creation) + #587 (README note), all merged.

## Risks & Mitigation
- **Docker endpoint picks up the command** → intended; prompt-template surface, no ambient cost.
- **Key-order/formatting churn in the template JSON** → mitigation: python `json.load`/`dump` with matching indent (check the file's existing indentation first); diff must show only the added block.
