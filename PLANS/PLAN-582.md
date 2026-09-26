# PLAN: A/B harness — /review-arch pilot + inline skill family

**Branch**: feat/582
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/582
**Base**: main

## Acceptance Criteria
- [ ] `/review-arch` and `/review-inline` exist in the global commands block and target the same review workflow
- [ ] Four `*-inline-skill` dirs exist: self-contained, frontmatter contract conformant (`name` = dir, `license`, `compatibility`, `metadata`), `requiresSkills` declared
- [ ] `/run-plan-v2` command entry exists referencing only skills that exist; documented zero-subagent substitution map
- [ ] `pack-experiment` preset installs the family opt-in; default `setup.sh` deploy unchanged
- [ ] `build-registry.mjs` + `registry.json` rebuilt; skill counts synced (README; setup.sh derives from registry)
- [ ] A/B protocol + numbers recorded in issue #582 with a keep/park decision per variant (pilot/pipeline runs are user-executed post-merge; this PLAN delivers the harness + protocol)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/testing-inline-skill/SKILL.md` | — | dependency-map entry, registry scan, lean profile | low |
| `skills/linting-inline-skill/SKILL.md` | — | dependency-map entry, registry scan, lean profile | low |
| `skills/documentation-inline-skill/SKILL.md` | — | dependency-map entry, registry scan, lean profile | low |
| `skills/responsive-audit-inline-skill/SKILL.md` | — | dependency-map entry, registry scan, lean profile | low |
| `installer/dependency-map.json` | 4 skill dirs exist (name match) | `build-registry.mjs` edges, `init.mjs` resolveSelection | med |
| `installer/presets/pack-experiment.json` | registry contains the 4 skills | `init.mjs --preset experiment` | low |
| `installer/registry.json` (generated) | dependency-map + presets + skill scan | `init.mjs`, `setup.sh` category/help generation | med |
| `deploy/skill-profiles.json` | 4 skill dirs exist | `setup.sh --skill-profile lean`, `tests/skill_profiles.bats` | low |
| `README.md` | final registry counts (153) | repo readers, preset table consumers | low |
| `~/.config/opencode/opencode.json` (user-space, not in PR) | skills installed locally for `/run-plan-v2` | local A/B runs | low |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Pilot commands (user-space)
- [ ] **1.1** Add `review-arch` and `review-inline` command entries to the `commands` block of `~/.config/opencode/opencode.json`
    — **Why:** unblocks the pilot A/B measurement (issue AC #1); user-space so it lands outside the PR by design.
    — **Done when:** `python3 -c "import json;c=json.load(open('/home/silentx/.config/opencode/opencode.json'))['commands'];assert 'review-arch' in c and 'review-inline' in c"` exits 0.
    — **Consumers affected:** local `/review-arch` + `/review-inline` invocations.

### Phase 2: Inline executor skill family (repo)
- [ ] **2.1** Create `skills/testing-inline-skill/SKILL.md` — decision tree (framework detect → scope to step's Done-when → runnable check), Enforcement deltas section, `requiresSkills: ["verification-loop-skill"]`
    — **Why:** first family member; establishes the structure the other three copy.
    — **Done when:** frontmatter `name` equals dir name, `license: Apache-2.0`, `compatibility: opencode`, `metadata` present; body contains "Enforcement deltas" heading.
    — **Consumers affected:** dependency-map (3.1), registry scan (3.3).
- [ ] **2.2** Create `skills/linting-inline-skill/SKILL.md` — thin tree over `language-linting-skill` + `verification-loop-skill` rules (language detect → scoped lint → gate semantics), same structure
    — **Why:** mirrors `linting-subagent` for `/run-plan-v2`.
    — **Done when:** same checks as 2.1.
    — **Consumers affected:** dependency-map (3.1), registry scan (3.3).
- [ ] **2.3** Create `skills/documentation-inline-skill/SKILL.md` — docstring standards (PEP 257/Javadoc/JSDoc) + skip rules + same-phase commit binding, same structure
    — **Why:** mirrors `documentation-subagent`.
    — **Done when:** same checks as 2.1.
    — **Consumers affected:** dependency-map (3.1), registry scan (3.3).
- [ ] **2.4** Create `skills/responsive-audit-inline-skill/SKILL.md` — wraps the documented inline loop of `playwright-responsive-audit-skill` (detect→fix→re-verify tiers), same structure
    — **Why:** mirrors `responsive-audit-subagent`; the inline fallback already specified in plan-execution-skill §84 needs a loadable home.
    — **Done when:** same checks as 2.1.
    — **Consumers affected:** dependency-map (3.1), registry scan (3.3).

### Phase 3: Installer + docs wiring (repo)
- [ ] **3.1** Declare `requiresSkills` entries for the four inline skills in `installer/dependency-map.json`
    — **Why:** registry edges derive from the dependency map; the installer must co-install prerequisites (declared-handoff pattern, #437).
    — **Done when:** `python3 -c "import json;d=json.load(open('installer/dependency-map.json'))['requiresSkills'];assert all(k in d for k in ['testing-inline-skill','linting-inline-skill','documentation-inline-skill','responsive-audit-inline-skill'])"` exits 0.
    — **Consumers affected:** registry rebuild (3.3).
- [ ] **3.2** Create `installer/presets/pack-experiment.json` — `agents: []`, `skills: [the four inline skills]`, `mcps: []`, with `$comment` noting experiment status
    — **Why:** opt-in distribution keeps default deploys unchanged (AC #4).
    — **Done when:** valid JSON, `name: "experiment"`, skills array matches the four dir names exactly.
    — **Consumers affected:** registry rebuild (3.3), README preset table (3.5).
- [ ] **3.3** Rebuild the registry: `node installer/build-registry.mjs`
    — **Why:** registry auto-scans `skills/*/SKILL.md`; the rebuild embeds the new skills, dependency-map edges, and `__presets.pack-experiment`.
    — **Done when:** script prints `registry OK (…no drift)`; `python3 -c "import json;r=json.load(open('installer/registry.json'));names=[s['stem'] for s in r['skills'] if isinstance(s,dict) else s];assert all(n in str(r) for n in ['testing-inline-skill','linting-inline-skill','documentation-inline-skill','responsive-audit-inline-skill','pack-experiment'])"` exits 0.
    — **Consumers affected:** `init.mjs`, `setup.sh` category generation, README counts (3.5).
- [ ] **3.4** Add the four inline skills to `deploy/skill-profiles.json` `lean` array
    — **Why:** primary sessions must be able to load them for `/run-plan-v2`; guard `tests/skill_profiles.bats` requires lean keys to match disk dirs.
    — **Done when:** keys present in `lean`; `bats tests/skill_profiles.bats` passes.
    — **Consumers affected:** lean deploy profile count statement in README (3.5).
- [ ] **3.5** Sync README: 149→153 skill counts (lines ~72, ~247, ~284), lean count 72→76, add `experiment` row to the preset table
    — **Why:** documentation-sync rule (AGENTS.md: new skills → counts + category listing); setup.sh derives from registry so README is the only hand-maintained surface.
    — **Done when:** `rg -c "153 skills" README.md` ≥ 2 and preset table contains an `experiment` row.
    — **Consumers affected:** repo readers.
- [ ] **3.6** Add `run-plan-v2` command entry to the global commands block (user-space)
    — **Why:** completes the A/B pair for the pipeline; deferred to after 2.x so it references existing skills only.
    — **Done when:** `python3 -c "import json;c=json.load(open('/home/silentx/.config/opencode/opencode.json'))['commands'];assert 'run-plan-v2' in c"` exits 0.
    — **Consumers affected:** local `/run-plan-v2` invocations.

### Phase 4: Verification + issue protocol
- [ ] **4.1** Run repo gates: `node installer/build-registry.mjs` drift check, `bats tests/skill_isolation.bats tests/skill_profiles.bats`, and re-verify 3.3/3.4/3.5 assertions
    — **Why:** registry/profile/isolation guards are the repo's mechanical enforcement; the exit gate re-runs them at full tier.
    — **Done when:** all green with no drift.
    — **Consumers affected:** none (read-only verification).
- [ ] **4.2** Post the A/B measurement protocol as a comment on issue #582 (pilot: fresh session per variant, `/sessions` token capture, context meter before/after; pipeline: same small PLAN per variant, compaction events; model-mix note; keep/park decision template)
    — **Why:** AC #6 requires the protocol and numbers home to be recorded in the issue; post-merge the user only executes and appends results.
    — **Done when:** `gh issue view 582 --comments` shows the protocol comment.
    — **Consumers affected:** issue #582 readers (post-merge measurement).

## Technical Notes
- Executor trees stay thin: role decision tree + Enforcement deltas + `requiresSkills`; knowledge lives in the existing skills they declare (declared-handoff, no vendoring — isolation contract #437).
- User-space command entries (`~/.config/opencode/opencode.json`) are intentionally outside the PR; they are machine-local config the ACs require.
- Frontmatter contract per repo AGENTS.md: `name` = dir name, `description` ≤50 words with triggers, `license: Apache-2.0`, `compatibility: opencode`, `metadata` house sub-keys. No `category` in frontmatter is fine (installer-registry-only key may be set for registry grouping).

## Dependencies
- None external. Post-merge user steps (recorded in issue #582): pilot A/B run (`/review-arch` vs `/review-inline`), `/run-plan-v2` smoke on a small PLAN, numbers + keep/park decision (AC #6).

## Risks & Mitigation
- **AC #3/#6 cannot be fully executed by this pipeline** (need fresh interactive sessions + a small PLAN target) → mitigation: harness + protocol shipped; issue #582 records the post-merge protocol; exit gate verifies all file/JSON/test-level Done-whens.
- **Registry shape drift** (skill entry is object vs string) → mitigation: 3.3 Done-when asserts via substring, robust to both shapes; drift check in the build script is authoritative.
- **bats unavailable in environment** → mitigation: run via `npx bats` if present; if the runner is absent, run the guard scripts' assertions manually and note it in the gate memo as inconclusive-then-manual.
