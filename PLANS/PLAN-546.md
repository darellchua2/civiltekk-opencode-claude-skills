# PLAN: Upgrade frontend-design-skill with Anthropic + Vercel sources

**Branch**: feat/546
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/546
**Base**: main

## Acceptance Criteria
- [ ] frontend-design-skill: expanded tell table (terracotta `#D97757`, SaaS-card kit, template chrome: ALL-CAPS eyebrows, middle-dot meta `A · B · C`, `WORD — fragment` labels, `#0B0B0B`/`#111`, mono data labels, trailing `→`), subject-matter grounding, typography anti-tells (<80-char lines, single-word headline accent ban, ≤2 families), numbering-only-for-sequences rule, stricter motion rule, plan-first anti-generic gate, CSS specificity gotcha, Copy section — file ≤ ~170 lines
- [ ] uiux-review-skill axis 13 synced with the expanded tell list
- [ ] react-best-practices-skill: self-contained, frontmatter conforms (name = dirname, ≤50-word description, Apache-2.0, `compatibility: opencode`, category)
- [ ] nextjs-specialist-subagent frontmatter allows react-best-practices-skill
- [ ] Cross-links added in frontend-design-skill + both react antipattern skills
- [ ] `registry.json` regenerated and committed; no count drift in setup.sh/setup.ps1/README
- [ ] bats pass: test_skill_isolation, test_portability, test_count_drift, test_requires_skills
- [ ] Provenance comments cite both upstreams with licenses (Anthropic Apache-2.0; Vercel license verified during implementation)

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/frontend-design-skill/SKILL.md` | `skills/uiux-review-skill/SKILL.md` axis 13 (sync claim in its table header) | `uiux-reviewer-subagent` (skill allowlist), wireframer→uiux-review pipeline docs, `installer/registry.json`, deploy counts, README | med |
| `skills/uiux-review-skill/SKILL.md` | frontend-design-skill tell table (content parity) | `uiux-reviewer-subagent`, `installer/registry.json`, deploy counts | med |
| `skills/react-best-practices-skill/` (new) | upstream Vercel license verification | `agents/nextjs-specialist-subagent.md` (allowlist), react antipattern skills (Related Skills), `installer/registry.json`, deploy counts, README, `dependency-map.json` | med |
| `agents/nextjs-specialist-subagent.md` | `skills/react-best-practices-skill/` existing | opencode agent loader (frontmatter permissions), `installer/registry.json`, agent count listings | med |
| `skills/react-hooks-antipatterns-skill/SKILL.md` | `skills/react-best-practices-skill/` existing (link target) | `nextjs-specialist-subagent` (loads it), registry (content-only edit, frontmatter untouched) | low |
| `skills/react-render-antipatterns-skill/SKILL.md` | `skills/react-best-practices-skill/` existing (link target) | same as above | low |
| `installer/registry.json` | all skill/agent source edits | `installer/init.mjs` | low (generated) |
| `deploy/setup.sh` / `deploy/setup.ps1` / `README.md` | final skill/agent inventory | deploy users, `tests/test_count_drift.bats`, `tests/test_skills_only_parity.bats` | med |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Upgrade frontend-design-skill from Anthropic guidance
- [ ] **1.1** Expand the AI-tell calibration table in `skills/frontend-design-skill/SKILL.md` (add terracotta `#D97757` accent, SaaS-card kit, template-chrome tells: ALL-CAPS eyebrows, middle-dot meta `A · B · C`, `WORD — fragment` labels, `#0B0B0B`/`#111` tinted near-black, mono data labels, trailing `→`) and add a provenance comment citing both upstream sources
    — **Why:** the ticket's core gap — the current table only covers clusters A/B/C, missing the tells Anthropic now documents
    — **Done when:** grep finds `#D97757`, `SaaS-card`, `eyebrow`, `middle-dot` entries in the file and a provenance comment naming both upstream URLs
    — **Consumers affected:** `uiux-review-skill` axis 13 (sync target, Phase 2), `uiux-reviewer-subagent` (loads this skill)
- [ ] **1.2** Add the remaining process/craft content to the same file: subject-matter grounding in Design Direction, typography anti-tells (<80-char lines, single-word headline accent ban, ≤2 clearly-distinct families), structural-devices rule (numbering only for real sequences), stricter motion rule (one orchestrated moment; no scattered per-section entrances or hover-on-every-card), plan-first anti-generic gate in Steps, CSS specificity gotcha in Common Issues, compact Copy section
    — **Why:** these are the remaining Anthropic guidance gaps named in the ticket's solution item 1
    — **Done when:** each named element greps in the file (subject matter, 80-char, sequence, orchestrated, specificity, Copy)
    — **Consumers affected:** same as 1.1
- [ ] **1.3** Enforce the ≤ ~170-line budget on `skills/frontend-design-skill/SKILL.md` (compress existing prose where needed) and confirm the frontmatter is byte-identical to `origin/main`'s
    — **Why:** #409 trimmed this skill for bloat; the ticket promises the file stays lean and registry-stable
    — **Done when:** `wc -l` ≤ 170 and `git diff origin/main -- skills/frontend-design-skill/SKILL.md` shows unchanged frontmatter lines
    — **Consumers affected:** `installer/registry.json` (unchanged frontmatter → no spurious drift)

### Phase 2: Sync uiux-review-skill axis 13
- [ ] **2.1** Expand axis 13 in `skills/uiux-review-skill/SKILL.md` with the same expanded tell set (terracotta accent, SaaS-card kit, template chrome), preserving the cluster structure and the axis-13 Minor/NOTE severity disposition
    — **Why:** frontend-design-skill's table header claims sync with axis 13; `uiux-reviewer-subagent` detects AI clusters through this skill, so the reviewer inherits the new tells only if it lands here
    — **Done when:** axis 13 greps for the same new tell markers as Phase 1's table; both tables list the same clusters
    — **Consumers affected:** `uiux-reviewer-subagent` (review output), the file's attribution table (unchanged license line)

### Phase 3: Add react-best-practices-skill
- [ ] **3.1** Verify the Vercel upstream license (fetch LICENSE from vercel-labs/agent-skills) and record it in the new skill's provenance comment
    — **Why:** the acceptance criterion requires license verification during implementation, before any upstream content lands
    — **Done when:** license statement fetched and cited in the provenance comment of the skill files
    — **Consumers affected:** none (gate for 3.2/3.3)
- [ ] **3.2** Create `skills/react-best-practices-skill/SKILL.md` (priority table, quick reference, when-to-apply) with contract-conformant frontmatter (name = dirname, ≤50-word description with trigger phrases, Apache-2.0, `compatibility: opencode`, category `Framework-Specific`)
    — **Why:** the ticket's solution item 3 — 40+ perf rules need a standalone self-contained home, not a bloat section in the design skill
    — **Done when:** file exists and `node installer/build-registry.mjs` exits 0 with the new skill registered
    — **Consumers affected:** `agents/nextjs-specialist-subagent.md` (4.1), react antipattern skills (3.4)
- [ ] **3.3** Create `skills/react-best-practices-skill/references/react-performance-guidelines.md` with the full categorized ruleset (8 categories with code examples)
    — **Why:** SKILL.md stays a quick reference; the skill-isolation contract requires all content inside the skill's own tree
    — **Done when:** file exists inside the skill dir and SKILL.md references it
    — **Consumers affected:** none (self-contained)
- [ ] **3.4** Add Related Skills cross-links to `skills/react-hooks-antipatterns-skill/SKILL.md` and `skills/react-render-antipatterns-skill/SKILL.md` pointing at react-best-practices-skill (perf best-practices vs correctness antipatterns peer split)
    — **Why:** discoverability; these peers already cross-reference each other
    — **Done when:** both files grep `react-best-practices-skill`
    — **Consumers affected:** none beyond readers (frontmatter untouched)

### Phase 4: Wiring + repo sync
- [ ] **4.1** Add `react-best-practices-skill` to the skill allowlist in `agents/nextjs-specialist-subagent.md` frontmatter
    — **Why:** the subagent's audit mode must load the new perf rules (ticket solution item 3); subagent-only skills are enabled in the agent's frontmatter per repo policy
    — **Done when:** frontmatter contains the `action: skill, resource: react-best-practices-skill, effect: allow` rule
    — **Consumers affected:** `installer/registry.json` (agent frontmatter change → regen required in 4.3)
- [ ] **4.2** Add the React-perf cross-link to `skills/frontend-design-skill/SKILL.md` (Technology Notes / Workflow Context)
    — **Why:** deferred from Phase 1 until the target skill exists, so no AC cross-reference dangles
    — **Done when:** frontend-design-skill greps `react-best-practices-skill`
    — **Consumers affected:** none
- [ ] **4.3** Regenerate `installer/registry.json` (`node installer/build-registry.mjs`) and commit it together with all Phase 1-4 source edits
    — **Why:** registry is a generated artifact — landing sources without it leaves the artifact stale (recorded anti-pattern: generated-artifact-unstaged-regen)
    — **Done when:** re-running build-registry after commit produces an empty working-tree diff
    — **Consumers affected:** `installer/init.mjs` (reads registry.json only)
- [ ] **4.4** Update skill inventory counts and category listings in `deploy/setup.sh`, `deploy/setup.ps1`, and `README.md` (+1 skill)
    — **Why:** count-drift and parity tests enforce script/README agreement with the skill tree
    — **Done when:** `bats tests/test_count_drift.bats tests/test_skills_only_parity.bats` pass
    — **Consumers affected:** deploy users, README readers
- [ ] **4.5** Check `dependency-map.json` for a required `requiresSkills` entry for react-best-practices-skill (expected: none — the skill is dependency-free) and add one only if the installer contract demands it
    — **Why:** `npx … add react-best-practices-skill` must not silently miss declared prerequisites
    — **Done when:** `bats tests/test_requires_skills.bats` passes
    — **Consumers affected:** installer CLI

### Phase 5: Verification gates (ticket exit gate — full tier)
- [ ] **5.1** Run the ticket's named bats suites plus the parity suite: `bats tests/test_skill_isolation.bats tests/test_portability.bats tests/test_count_drift.bats tests/test_requires_skills.bats tests/test_skills_only_parity.bats`
    — **Why:** the ticket's acceptance criteria name these suites; the pipeline exit gate is full tier
    — **Done when:** all invoked suites exit 0 (fix and re-run on any failure before proceeding)
    — **Consumers affected:** PR CI (Step 10 merge decision)
- [ ] **5.2** Re-run `node installer/build-registry.mjs` and confirm a clean working tree
    — **Why:** proves the committed registry matches the final tree
    — **Done when:** exit 0 and `git status --porcelain` empty
    — **Consumers affected:** `installer/init.mjs`

## Technical Notes
- Upstream sources: Anthropic `frontend-design` SKILL.md (claude-code plugins, Apache-2.0) for design guidance; Vercel `react-best-practices` skill (vercel-labs/agent-skills, react-best-practices branch) for the perf ruleset. Both cited in provenance comments; no PolyForm-NC content involved.
- Motion-rule reconciliation: the design skill's current "staggered beats + scattered micro-interactions" line is REPLACED by the stricter one-orchestrated-moment rule — Anthropic documents scattered entrances as an AI tell; this tightens the skill's own anti-slop positioning.
- No new subagent; both `uiux-reviewer-subagent` and `nextjs-specialist-subagent` inherit new capabilities through skills they already load / newly allowlist.
- Knowledge stays in skills (repo rule: "The skill is the source of truth for review domain knowledge; this subagent file orchestrates workflow and delegation").

## Dependencies
None — no `blocked-by:` tickets.

## Risks & Mitigation
- **Frontmatter drift** on edited skills breaking the registry or description word cap → step 1.3 byte-stability check; new skill validated by build-registry in 3.2.
- **Count parity misses** between `setup.sh` and its PowerShell mirror → both updated in the same step 4.4, enforced by bats.
- **License uncertainty on Vercel content** → gated by 3.1 before any upstream text lands.
- **Re-bloat regression vs #409** → line budget step 1.3 plus prose compression.
