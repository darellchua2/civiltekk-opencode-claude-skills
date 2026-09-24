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

> Clarification (review ruling, 2026-09-24, recorded as a comment on #546): AC8's "cite both upstreams" means each derived file cites its own source — frontend-design-skill cites Anthropic (Apache-2.0), react-best-practices-skill cites Vercel (license verified in step 3.1). No touched file cites an upstream it did not derive from.

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/frontend-design-skill/SKILL.md` | `skills/uiux-review-skill/SKILL.md` axis 13 (sync claim in its table header) | `uiux-reviewer-subagent` (skill allowlist), wireframer→uiux-review pipeline docs, `installer/registry.json`, deploy counts, README, `tests/test_default_behavior.bats:835-847` (pins gating preamble exactly-once), `tests/test_autoresearch_protocol.bats:521-532` (pins Iteration Protocol section, `metadata.protocol: autoresearch-opt-in`, iteration-safety citation) | med |
| `skills/uiux-review-skill/SKILL.md` | frontend-design-skill tell table (content parity) | `uiux-reviewer-subagent`, `installer/registry.json`, deploy counts | med |
| `skills/react-best-practices-skill/` (new) | upstream Vercel license verification | `agents/nextjs-specialist-subagent.md` (allowlist), react antipattern skills (Related Skills), `installer/registry.json`, deploy counts, README, `dependency-map.json`, `installer/presets/pack-frontend.json`, `opencode_app/opencode.json` skill allowlist | med |
| `agents/nextjs-specialist-subagent.md` | `skills/react-best-practices-skill/` existing | `installer/registry.json` (frontmatter skill rules feed registry edges via `build-registry.mjs`), agent count listings; runtime child-session skill loading is governed by CONFIG layers, not frontmatter (LEARNINGS `patterns/child-skill-gate-follows-merged-config.md`, upstream #50149) → config-layer allow required for actual loading | med |
| `installer/presets/pack-frontend.json` | `skills/react-best-practices-skill/` registered in registry (preset comment requires registry membership) | frontend preset installers | low |
| `opencode_app/opencode.json` | `skills/react-best-practices-skill/` existing | Docker standalone app runtime (skill allowlist governs subagent loading) | low |
| `skills/react-hooks-antipatterns-skill/SKILL.md` | `skills/react-best-practices-skill/` existing (link target) | `nextjs-specialist-subagent` (loads it), registry (content-only edit, frontmatter untouched) | low |
| `skills/react-render-antipatterns-skill/SKILL.md` | `skills/react-best-practices-skill/` existing (link target) | same as above | low |
| `installer/registry.json` | all skill/agent source edits | `installer/init.mjs` | low (generated) |
| `deploy/setup.sh` / `deploy/setup.ps1` / `README.md` | final skill/agent inventory | deploy users, `tests/test_count_drift.bats`, `tests/test_skills_only_parity.bats` | med |

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Upgrade frontend-design-skill from Anthropic guidance
- [ ] **1.1** Expand the AI-tell calibration table in `skills/frontend-design-skill/SKILL.md` (add terracotta `#D97757` accent, SaaS-card kit, template-chrome tells: ALL-CAPS eyebrows, middle-dot meta `A · B · C`, `WORD — fragment` labels, `#0B0B0B`/`#111` tinted near-black, mono data labels, trailing `→`, vermilion alongside acid green in the dark cluster, and the default-hero tell: big number + small label + supporting stats + gradient accent) and add a provenance comment citing Anthropic's frontend-design SKILL.md (Apache-2.0) as this file's upstream
    — **Why:** the ticket's core gap — the current table only covers clusters A/B/C, missing the tells Anthropic now documents; per the AC8 ruling this file cites its own upstream only
    — **Done when:** grep finds `#D97757`, `SaaS-card`, `eyebrow`, `middle-dot`, `vermilion`, `gradient accent` entries in the file, and a provenance comment names the Anthropic upstream URL (grep must NOT find Vercel URLs in this file's provenance)
    — **Consumers affected:** `uiux-review-skill` axis 13 (sync target, Phase 2), `uiux-reviewer-subagent` (loads this skill)
- [ ] **1.2** Add the remaining process/craft content to the same file: subject-matter grounding + "open with the subject's most characteristic element" hero rule in Design Direction; typography anti-tells (<80-char lines, single-word headline accent ban, ≤2 clearly-distinct families); structural-devices rule (numbering only for real sequences); stricter motion rule replacing the Motion paragraph — one orchestrated moment, scattered per-section entrances and hover-on-every-card are AI tells, motion answering a user action (open/expand/confirm) is welcome; brief-wins reconciliation replacing the cluster-request line (a brief that explicitly requests a cluster look gets it — the calibration exists to stop unrequested defaults, note the tension in one line); plan-first anti-generic gate in Steps; Step 5 reworded to drop "scroll reveals" prescriptions; quality-floor sentence (responsive, visible keyboard focus, reduced motion, visual accessibility) in Refine/verify + "visible keyboard focus" in the Verification checklist; motion question added to the 13-axis spot check; CSS specificity gotcha in Common Issues; compact Copy section; one-line deliberate-drop notes (type-treatment-as-active-element, zero-radius broadsheet detail) so omissions are choices
    — **Why:** these are the remaining Anthropic guidance gaps named in the ticket's solution item 1, plus the two review findings that the current file self-contradicts on motion and cluster requests
    — **Done when:** grep finds "one orchestrated moment", "most characteristic", "keyboard focus", "Copy" heading, and the plan-first gate; grep must NOT find "beats scattered micro-interactions", "scroll reveals", or "pick a different direction" anywhere in the file; grep finds "single-word" (accent ban) and "two" families rule markers; frontmatter still greps `protocol: autoresearch-opt-in`
    — **Consumers affected:** same as 1.1; `uiux-review-skill` axis 13 parity
- [ ] **1.3** Enforce the ≤ ~170-line budget on `skills/frontend-design-skill/SKILL.md` (compress existing prose where needed), confirm the frontmatter is byte-identical to `origin/main`'s, and preserve the content-pinned strings: the autoresearch gating preamble ("DO NOT execute any of the following unless") appears exactly once, the `## Iteration Protocol (opt-in)` section survives intact with its `autoresearch-core-skill/references/iteration-safety.md` citation
    — **Why:** #409 trimmed this skill for bloat; `tests/test_default_behavior.bats:835-847` and `tests/test_autoresearch_protocol.bats:521-532` pin the preamble/section/citation/metadata that Phase 1 rewriting could silently delete
    — **Done when:** `wc -l` ≤ 170; `git diff origin/main -- skills/frontend-design-skill/SKILL.md` shows unchanged frontmatter lines; `grep -c "DO NOT execute any of the following unless"` = 1; the Iteration Protocol heading and iteration-safety citation grep in the file
    — **Consumers affected:** `installer/registry.json` (unchanged frontmatter → no spurious drift), both pin suites (Phase 5)

### Phase 2: Sync uiux-review-skill axis 13
- [ ] **2.1** Expand axis 13 in `skills/uiux-review-skill/SKILL.md` with the same expanded tell set (terracotta accent, SaaS-card kit, template chrome, default-hero composition tell), preserving the cluster structure and the axis-13 Minor/NOTE severity disposition
    — **Why:** frontend-design-skill's table header claims sync with axis 13; `uiux-reviewer-subagent` detects AI clusters through this skill, so the reviewer inherits the new tells only if it lands here
    — **Done when:** axis 13 greps for the same new tell markers as Phase 1's table; both tables list the same clusters
    — **Consumers affected:** `uiux-reviewer-subagent` (review output), the file's attribution table (unchanged license line)

### Phase 3: Add react-best-practices-skill
- [ ] **3.1** Verify the Vercel upstream license (fetch LICENSE from vercel-labs/agent-skills) and record it in the new skill's provenance comment
    — **Why:** the acceptance criterion requires license verification during implementation, before any upstream content lands
    — **Done when:** license statement fetched and cited in the provenance comment of the skill files
    — **Consumers affected:** none (gate for 3.2/3.3)
- [ ] **3.2** Create `skills/react-best-practices-skill/SKILL.md` (priority table, quick reference, when-to-apply) with contract-conformant frontmatter (name = dirname, ≤50-word description with trigger phrases, Apache-2.0, `compatibility: opencode`, category `Framework-Specific`), a Vercel provenance comment per 3.1, and reference paths pointing only at this skill's single `references/` file — no upstream `references/rules/` directory structure
    — **Why:** the ticket's solution item 3 — 40+ perf rules need a standalone self-contained home, not a bloat section in the design skill; upstream splits references into a directory we deliberately flatten, and stale upstream paths would dangle
    — **Done when:** file exists, contains no `references/rules/` path strings, and `node installer/build-registry.mjs` exits 0 with the new skill registered
    — **Consumers affected:** `agents/nextjs-specialist-subagent.md` (4.1), react antipattern skills (3.4), preset + config surfaces (4.6)
- [ ] **3.3** Create `skills/react-best-practices-skill/references/react-performance-guidelines.md` with the full categorized ruleset (8 categories with code examples)
    — **Why:** SKILL.md stays a quick reference; the skill-isolation contract requires all content inside the skill's own tree
    — **Done when:** file exists inside the skill dir and SKILL.md references it
    — **Consumers affected:** none (self-contained)
- [ ] **3.4** Add Related Skills cross-links to `skills/react-hooks-antipatterns-skill/SKILL.md` and `skills/react-render-antipatterns-skill/SKILL.md` pointing at react-best-practices-skill (perf best-practices vs correctness antipatterns peer split)
    — **Why:** discoverability; these peers already cross-reference each other
    — **Done when:** both files grep `react-best-practices-skill`
    — **Consumers affected:** none beyond readers (frontmatter untouched)

### Phase 4: Wiring + repo sync
- [ ] **4.1** Add `react-best-practices-skill` to the skill allowlist in `agents/nextjs-specialist-subagent.md` frontmatter AND add the config-layer allow to `opencode_app/opencode.json`'s skill list (next to the react-hooks/react-render antipattern peers)
    — **Why:** frontmatter rules feed the registry's requiresSkills edges (`build-registry.mjs`), but recorded runtime behavior (LEARNINGS `patterns/child-skill-gate-follows-merged-config.md`, opencode v2.0.11 upstream #50149) is that child-session skill loading resolves against merged CONFIG layers, not frontmatter — the config-layer allow is what actually unlocks loading; peer precedent: both react antipattern skills are config-allowed there
    — **Done when:** agent frontmatter contains the `action: skill, resource: react-best-practices-skill, effect: allow` rule AND `opencode_app/opencode.json` contains the skill in its allowlist; probe in 5.3 validates runtime loading
    — **Consumers affected:** `installer/registry.json` (regen in 4.3), Docker app runtime
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
- [ ] **4.6** Add `react-best-practices-skill` to `installer/presets/pack-frontend.json`'s skills list (sorted position)
    — **Why:** the frontend preset ships both react antipattern peers and the nextjs agent — omitting the new skill would bundle an agent whose perf skill is missing from its own preset; preset comment requires registry membership (satisfied by 4.3)
    — **Done when:** the preset JSON lists the skill in sorted order and `bats tests/test_pack_permissions.bats` still passes
    — **Consumers affected:** frontend preset installers

### Phase 5: Verification gates (ticket exit gate — full tier)
- [ ] **5.1** Run the ticket's named bats suites plus the content-pinning and parity suites: `bats tests/test_skill_isolation.bats tests/test_portability.bats tests/test_count_drift.bats tests/test_requires_skills.bats tests/test_skills_only_parity.bats tests/test_default_behavior.bats tests/test_autoresearch_protocol.bats`
    — **Why:** the ticket names four suites, but Phase 1 rewrites a file whose preamble/section/metadata two further suites pin — a gate scoped only to the ticket's list could pass with pinned content already deleted (review finding M1)
    — **Done when:** all invoked suites exit 0 (fix and re-run on any failure before proceeding)
    — **Consumers affected:** PR CI (Step 10 merge decision)
- [ ] **5.2** Re-run `node installer/build-registry.mjs` and confirm a clean working tree
    — **Why:** proves the committed registry matches the final tree
    — **Done when:** exit 0 and `git status --porcelain` empty
    — **Consumers affected:** `installer/init.mjs`
- [ ] **5.3** Run the child-session skill-loading regression probe: spawn `code-review-subagent` with the instruction "invoke the `skill` tool with id `react-best-practices-skill` and report the literal outcome"; expect `loaded`
    — **Why:** LEARNINGS `patterns/child-skill-gate-follows-merged-config.md` (probe-verified #481/#482, upstream #50149): frontmatter skill rules are inert in child sessions — only the config-layer allow from 4.1 actually unlocks loading, and this probe is the only executable proof the wiring works
    — **Done when:** the spawned subagent reports `loaded`; any `permission.rejected` → fix the config layer (or, if the upstream defect is fixed and loading works without config allows, revert the workaround deliberately and note it) before proceeding
    — **Consumers affected:** `nextjs-specialist-subagent` audit mode (runtime capability)

## Technical Notes
- Upstream sources: Anthropic `frontend-design` SKILL.md (claude-code plugins, Apache-2.0) for design guidance; Vercel `react-best-practices` skill (vercel-labs/agent-skills, react-best-practices branch) for the perf ruleset. Per the AC8 ruling, provenance is per-file: frontend-design-skill cites Anthropic only; react-best-practices-skill cites Vercel only.
- Motion-rule reconciliation: the design skill's current "staggered beats + scattered micro-interactions" line is REPLACED by the stricter one-orchestrated-moment rule — Anthropic documents scattered entrances as an AI tell; this tightens the skill's own anti-slop positioning. Contradictory "scroll reveals" prescriptions in the Motion paragraph and Step 5 are removed in the same edit (removal-assertions in 1.2's Done-when).
- Cluster-request position (review ruling): the brief's explicit request wins, including when it asks for an AI-cluster look; the ask-why behavior survives for unstated cases via the tension note.
- No new subagent; both `uiux-reviewer-subagent` and `nextjs-specialist-subagent` inherit new capabilities through skills they already load / newly allowlist. Knowledge stays in skills (repo rule: "The skill is the source of truth for review domain knowledge; this subagent file orchestrates workflow and delegation").
- Wiring mechanism (review ruling on Gap 1): frontmatter allow = registry edges only; config-layer allow in `opencode_app/opencode.json` = actual child-session loading; step 5.3's probe (recipe from LEARNINGS `patterns/child-skill-gate-follows-merged-config.md` — that file is not on this branch, so the recipe is embedded here: spawn reviewer subagent → instruct `skill` tool call with the id → expect `loaded`, any `permission.rejected` = regressed config layer) is the executable proof.

## Dependencies
None — no `blocked-by:` tickets.

## Risks & Mitigation
- **Frontmatter drift** on edited skills breaking the registry or description word cap → step 1.3 byte-stability check; new skill validated by build-registry in 3.2.
- **Pinned-content deletion** during prose compression (gating preamble, Iteration Protocol section, metadata.protocol, iteration-safety citation) → 1.3 constraints + the two pin suites added to 5.1 (review finding M1).
- **Count parity misses** between `setup.sh` and its PowerShell mirror → both updated in the same step 4.4, enforced by bats.
- **License uncertainty on Vercel content** → gated by 3.1 before any upstream text lands.
- **Re-bloat regression vs #409** → line budget step 1.3 plus prose compression.
- **Inert allowlist wiring** (child-session skill loading follows config layers, upstream #50149) → config-layer allow in 4.1 + runtime probe 5.3 as the executable gate.
