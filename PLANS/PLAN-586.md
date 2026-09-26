# PLAN: Add skill-generalizer skill from civiltekk-cad-app

**Branch**: feat/586
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/586
**Base**: main

## Acceptance Criteria
- [x] `skills/skill-generalizer/SKILL.md` exists, self-contained, frontmatter uses top-level `category: OpenCode Meta`
- [ ] README.md skill counts 153 → 154 (intro, opencode-init, tree, profiles, catalog summary + current count) and OpenCode Meta row lists it
- [ ] `opencode_app/README.md` count 153 → 154
- [ ] `opencode_app/opencode.json` permissions allow rule added (full-profile single source)
- [ ] `deploy/skill-profiles.json` lean array entry added
- [ ] isolation + skill-profile tests pass

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/skill-generalizer/SKILL.md` | — | `npx add skill-generalizer` installer, `count_skills()` in deploy/setup.sh, GitHub Pages catalog, skill-profile guards | low |
| `README.md` | skill dir present (count integrity) | humans; documentation-consistency audits | low |
| `opencode_app/README.md` | skill dir present | Docker self-host users | low |
| `opencode_app/opencode.json` | skill dir present (allow rule must name an existing skill) | full-profile deploy (`opencode_app` container) | medium (JSON syntax) |
| `deploy/skill-profiles.json` | skill dir present (lean key guarded by `tests/skill_profiles.bats`) | lean-profile deploys | medium (guard test) |

## Implementation Phases

### Phase 1: Copy and normalize the skill
- [x] **1.1** Copy `SKILL.md` from `civiltekk-cad-app` checkout `.agents/skills/skill-generalizer/` into `skills/skill-generalizer/` in this worktree, byte-identical
    — **Why:** the skill content is already generalized and audited (commit f2fe101 in the source repo); the move must not rewrite method content (source skill's own identity-preservation rule)
    — **Done when:** `git status` shows `skills/skill-generalizer/SKILL.md` staged-new and `diff` vs the source file is empty
    — **Consumers affected:** every downstream registration (Phases 2–3) requires the dir to exist first
    — **Done:** verbatim copy verified by empty `diff`; files: `skills/skill-generalizer/SKILL.md`; fixes: none
- [x] **1.2** Normalize frontmatter: replace the `metadata:` block (`category: civiltekk`) with top-level `category: OpenCode Meta`, matching repo convention (e.g. `skills/opencode-skill-creation-skill/SKILL.md`)
    — **Why:** setup.sh derives per-category counts from the top-level `category:` field; `civiltekk` is not a registry group in this repo
    — **Done when:** `grep -n "^category: OpenCode Meta" skills/skill-generalizer/SKILL.md` hits and no `category: civiltekk` remains
    — **Consumers affected:** setup.sh banner counts, GitHub Pages catalog grouping
    — **Done:** frontmatter normalized to top-level `category: OpenCode Meta`; files: `skills/skill-generalizer/SKILL.md`; fixes: none

### Phase 2: Register the skill everywhere AGENTS.md requires
- [x] **2.1** Update README.md: six current-count instances 153 → 154 (lines 5, 74, 108, 249, 286, 288), lean count 76 → 77 (line 249), and the OpenCode Meta category row (6) → (7) listing `skill-generalizer`
    — **Why:** README is the human-facing source of record; AGENTS.md §doc-sync mandates count + category sync for every new/removed skill
    — **Done when:** `grep -c "153" README.md` returns only the history sentence (line 288 keeps 123/146 as history), and the OpenCode Meta row contains `skill-generalizer`
    — **Consumers affected:** readers; documentation-consistency audits
    — **Done:** all six counts + lean count + category row updated, "153" now only in the history sentence; files: `README.md`; fixes: none
- [x] **2.2** Update `opencode_app/README.md` line 26: 153 → 154 skill directories
    — **Why:** Docker self-host docs mirror repo content counts
    — **Done when:** `grep -n "154 skill directories" opencode_app/README.md` hits
    — **Consumers affected:** Docker self-host users
    — **Done:** count updated; files: `opencode_app/README.md`; fixes: none
- [x] **2.3** Add an allow rule `{"action": "skill", "resource": "skill-generalizer", "effect": "allow"}` to `opencode_app/opencode.json` immediately after the `opencode-v2-migration-skill` entry, keeping the OpenCode Meta skill group contiguous
    — **Why:** the full profile's single source is this permissions array; an unlisted skill is invisible to full-profile deploys
    — **Done when:** `python3 -c "import json; json.load(open('opencode_app/opencode.json'))"` parses and the resource appears exactly once
    — **Consumers affected:** full-profile deploy in the `opencode_app` container
    — **Done:** rule added in the OpenCode Meta group; JSON parses; resource present exactly once; files: `opencode_app/opencode.json`; fixes: none
- [x] **2.4** Insert `"skill-generalizer"` into the `lean` array of `deploy/skill-profiles.json` at its alphabetical position (between `security-audit-skill` and `solid-principles-skill`)
    — **Why:** skill-generalizer is a primary-session workflow skill like its OpenCode Meta siblings; the lean array is sorted and guard-tested
    — **Done when:** `python3` JSON parse succeeds, `len(lean) == 77`, and the array remains sorted
    — **Consumers affected:** lean-profile deploys; `tests/skill_profiles.bats`
    — **Done:** entry inserted at the planned position; JSON parses; len==77. Deviation: the "remains sorted" clause was a wrong authoring assumption — the array has a pre-existing non-alphabetical Experiment group (not touched); the repo's actual invariant is the bats guard. Fix: updated the count pin in `tests/skill_profiles.bats` 76 → 77 (6 sites); full skill_profiles run green 8/8; files: `deploy/skill-profiles.json`, `tests/skill_profiles.bats`; fixes: test-count pin update

### Phase 3: Verify gates
- [ ] **3.1** Run the repo guards: skill-profile test (`tests/skill_profiles.bats` if bats exists, else scripted equivalent: every lean key maps to an existing skill dir, every lean key appears in the permissions array) and skill-isolation check (no `_common` refs, no sibling-skill path escapes in the new skill)
    — **Why:** these are the mechanical enforcement AGENTS.md names for exactly this change
    — **Done when:** guard script exits 0 (or bats run passes) with the new key validated
    — **Consumers affected:** CI on the PR
- [ ] **3.2** Full-tree grep audit: no remaining stale count ("153" outside the history sentence, "76 primary-visible" in setup.sh comment updated to 77), JSON files parse, frontmatter `name: skill-generalizer` matches the directory name
    — **Why:** belt for the doc-sync contract; a stale count fails documentation-consistency audits later
    — **Done when:** audit script prints zero findings
    — **Consumers affected:** none (verification only)

## Technical Notes
- Source: `/home/silentx/VSCODE/civiltekk-cad-app/.agents/skills/skill-generalizer/SKILL.md` (last touched by f2fe101, already audit-generalized).
- Keep the directory name `skill-generalizer` — suffix-optional per AGENTS.md; renaming breaks identity (the skill's own anti-pattern rule).
- `deploy/setup.sh` + `setup.ps1` need NO edits: counts are derived from disk since BT-157, except the stale comment at setup.sh:3579 (76 → 77).
- The removal from `civiltekk-cad-app` happens AFTER this merges, in a separate commit in that repo (outside this PR).

## Dependencies
None — single contained ticket.

## Risks & Mitigation
- JSON syntax breakage in two config files → mitigate with parse checks in 2.3/2.4 Done-when.
- Count drift (README claims vs disk) → mitigate with the 3.2 grep audit; setup.sh derives from disk so the banner cannot drift.
- Lean guard failure (key without dir) → impossible by phase ordering (1.1 precedes 2.4).

## Gate Trace
GATE PENDING
