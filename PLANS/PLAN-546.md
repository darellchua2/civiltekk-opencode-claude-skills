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
- [x] **1.1** Expand the AI-tell calibration table in `skills/frontend-design-skill/SKILL.md` (add terracotta `#D97757` accent, SaaS-card kit, template-chrome tells: ALL-CAPS eyebrows, middle-dot meta `A · B · C`, `WORD — fragment` labels, `#0B0B0B`/`#111` tinted near-black, mono data labels, trailing `→`, vermilion alongside acid green in the dark cluster, and the default-hero tell: big number + small label + supporting stats + gradient accent) and add a provenance comment citing Anthropic's frontend-design SKILL.md (Apache-2.0) as this file's upstream
    — **Why:** the ticket's core gap — the current table only covers clusters A/B/C, missing the tells Anthropic now documents; per the AC8 ruling this file cites its own upstream only
    — **Done when:** grep finds `#D97757`, `SaaS-card`, `eyebrow`, `middle-dot`, `vermilion`, `gradient accent` entries in the file, and a provenance comment names the Anthropic upstream URL (grep must NOT find Vercel URLs in this file's provenance)
    — **Consumers affected:** `uiux-review-skill` axis 13 (sync target, Phase 2), `uiux-reviewer-subagent` (loads this skill)
    — **Done:** table expanded with clusters D/E/F incl. terracotta `#D97757`, vermilion, SaaS-card kit, template chrome, default-hero tell; brief-wins line added; Anthropic provenance comment added (no Vercel URL in file); files: skills/frontend-design-skill/SKILL.md; fixes: none
- [x] **1.2** Add the remaining process/craft content to the same file: subject-matter grounding + "open with the subject's most characteristic element" hero rule in Design Direction; typography anti-tells (<80-char lines, single-word headline accent ban, ≤2 clearly-distinct families); structural-devices rule (numbering only for real sequences); stricter motion rule replacing the Motion paragraph — one orchestrated moment, scattered per-section entrances and hover-on-every-card are AI tells, motion answering a user action (open/expand/confirm) is welcome; brief-wins reconciliation replacing the cluster-request line (a brief that explicitly requests a cluster look gets it — the calibration exists to stop unrequested defaults, note the tension in one line); plan-first anti-generic gate in Steps; Step 5 reworded to drop "scroll reveals" prescriptions; quality-floor sentence (responsive, visible keyboard focus, reduced motion, visual accessibility) in Refine/verify + "visible keyboard focus" in the Verification checklist; motion question added to the 13-axis spot check; CSS specificity gotcha in Common Issues; compact Copy section; one-line deliberate-drop notes (type-treatment-as-active-element, zero-radius broadsheet detail) so omissions are choices
    — **Why:** these are the remaining Anthropic guidance gaps named in the ticket's solution item 1, plus the two review findings that the current file self-contradicts on motion and cluster requests
    — **Done when:** grep finds "one orchestrated moment", "most characteristic", "keyboard focus", "Copy" heading, and the plan-first gate; grep must NOT find "beats scattered micro-interactions", "scroll reveals", or "pick a different direction" anywhere in the file; grep finds "single-word" (accent ban) and "two" families rule markers; frontmatter still greps `protocol: autoresearch-opt-in`
    — **Consumers affected:** same as 1.1; `uiux-review-skill` axis 13 parity
    — **Done:** subject grounding + hero rule in Design Direction; typography anti-tells (single-word accent ban marker realized as "single word", two-families max, <80-char); structural-devices rule; one-orchestrated-moment motion rule with user-action allowance (old "staggered"/"scroll reveals" text removed, Step 6 reworded); brief-wins reconciliation; plan-first anti-generic gate as Step 2; quality floor + keyboard focus in Step 7 + checklist; motion self-check row added; CSS specificity gotcha; Copy section; deliberate-drop notes in provenance; files: skills/frontend-design-skill/SKILL.md; fixes: none
- [x] **1.3** Enforce the ≤ ~170-line budget on `skills/frontend-design-skill/SKILL.md` (compress existing prose where needed), confirm the frontmatter is byte-identical to `origin/main`'s, and preserve the content-pinned strings: the autoresearch gating preamble ("DO NOT execute any of the following unless") appears exactly once, the `## Iteration Protocol (opt-in)` section survives intact with its `autoresearch-core-skill/references/iteration-safety.md` citation
    — **Why:** #409 trimmed this skill for bloat; `tests/test_default_behavior.bats:835-847` and `tests/test_autoresearch_protocol.bats:521-532` pin the preamble/section/citation/metadata that Phase 1 rewriting could silently delete
    — **Done when:** `wc -l` ≤ 170; `git diff origin/main -- skills/frontend-design-skill/SKILL.md` shows unchanged frontmatter lines; `grep -c "DO NOT execute any of the following unless"` = 1; the Iteration Protocol heading and iteration-safety citation grep in the file
    — **Consumers affected:** `installer/registry.json` (unchanged frontmatter → no spurious drift), both pin suites (Phase 5)
    — **Done:** 155 lines (≤170); frontmatter lines 1-11 byte-identical to origin/main (diff clean); preamble exactly 1; Iteration Protocol heading + iteration-safety citation present; files: skills/frontend-design-skill/SKILL.md; fixes: none

### Phase 2: Sync uiux-review-skill axis 13
- [x] **2.1** Expand axis 13 in `skills/uiux-review-skill/SKILL.md` with the same expanded tell set (terracotta accent, SaaS-card kit, template chrome, default-hero composition tell), preserving the cluster structure and the axis-13 Minor/NOTE severity disposition
    — **Why:** frontend-design-skill's table header claims sync with axis 13; `uiux-reviewer-subagent` detects AI clusters through this skill, so the reviewer inherits the new tells only if it lands here
    — **Done when:** axis 13 greps for the same new tell markers as Phase 1's table; both tables list the same clusters
    — **Consumers affected:** `uiux-reviewer-subagent` (review output), the file's attribution table (unchanged license line)
    — **Done:** axis 13 expanded from 3 to 6 clusters (A gained `#F4F1EA` + terracotta `#D97757`; B gained vermilion + tinted near-black; C gained zero-radius; new D SaaS-card kit, E template chrome, F default hero); brief-request exception line added; disposition paragraph preserved; all Phase-1 markers grep in axis 13 ("middle-dot" normalized for exact parity); files: skills/uiux-review-skill/SKILL.md; fixes: none

### Phase 3: Add react-best-practices-skill
- [x] **3.1** Verify the Vercel upstream license (fetch LICENSE from vercel-labs/agent-skills) and record it in the new skill's provenance comment
    — **Why:** the acceptance criterion requires license verification during implementation, before any upstream content lands
    — **Done when:** license statement fetched and cited in the provenance comment of the skill files
    — **Consumers affected:** none (gate for 3.2/3.3)
    — **Done:** license verified via GitHub API — repo `license: None`, no LICENSE file on branch; recorded in provenance as "license: none found (verified 2026-09-24)"; content adapted per house inspiration-only precedent (rules paraphrased, self-written snippets, no verbatim upstream text); files: skills/react-best-practices-skill/SKILL.md; fixes: none
- [x] **3.2** Create `skills/react-best-practices-skill/SKILL.md` (priority table, quick reference, when-to-apply) with contract-conformant frontmatter (name = dirname, ≤50-word description with trigger phrases, Apache-2.0, `compatibility: opencode`, category `Framework-Specific`), a Vercel provenance comment per 3.1, and reference paths pointing only at this skill's single `references/` file — no upstream `references/rules/` directory structure
    — **Why:** the ticket's solution item 3 — 40+ perf rules need a standalone self-contained home, not a bloat section in the design skill; upstream splits references into a directory we deliberately flatten, and stale upstream paths would dangle
    — **Done when:** file exists, contains no `references/rules/` path strings, and `node installer/build-registry.mjs` exits 0 with the new skill registered
    — **Consumers affected:** `agents/nextjs-specialist-subagent.md` (4.1), react antipattern skills (3.4), preset + config surfaces (4.6)
    — **Done:** SKILL.md created (frontmatter contract-conformant, category Framework-Specific, provenance with license finding, zero references/rules path strings); build-registry exits 0, skills=147; files: skills/react-best-practices-skill/SKILL.md, installer/registry.json; fixes: rule count corrected 39→43
- [x] **3.3** Create `skills/react-best-practices-skill/references/react-performance-guidelines.md` with the full categorized ruleset (8 categories with code examples)
    — **Why:** SKILL.md stays a quick reference; the skill-isolation contract requires all content inside the skill's own tree
    — **Done when:** file exists inside the skill dir and SKILL.md references it
    — **Consumers affected:** none (self-contained)
    — **Done:** full catalog written — all 43 upstream rules covered across 8 categories, paraphrased with minimal self-written idioms; SKILL.md links it; files: skills/react-best-practices-skill/references/react-performance-guidelines.md; fixes: none
- [x] **3.4** Add Related Skills cross-links to `skills/react-hooks-antipatterns-skill/SKILL.md` and `skills/react-render-antipatterns-skill/SKILL.md` pointing at react-best-practices-skill (perf best-practices vs correctness antipatterns peer split)
    — **Why:** discoverability; these peers already cross-reference each other
    — **Done when:** both files grep `react-best-practices-skill`
    — **Consumers affected:** none beyond readers (frontmatter untouched)
    — **Done:** perf-vs-correctness peer lines added to both files' Related Skills; both grep react-best-practices-skill; files: skills/react-hooks-antipatterns-skill/SKILL.md, skills/react-render-antipatterns-skill/SKILL.md; fixes: none

### Phase 4: Wiring + repo sync
- [x] **4.1** Add `react-best-practices-skill` to the skill allowlist in `agents/nextjs-specialist-subagent.md` frontmatter AND add the config-layer allow to `opencode_app/opencode.json`'s skill list (next to the react-hooks/react-render antipattern peers)
    — **Why:** frontmatter rules feed the registry's requiresSkills edges (`build-registry.mjs`), but recorded runtime behavior (LEARNINGS `patterns/child-skill-gate-follows-merged-config.md`, opencode v2.0.11 upstream #50149) is that child-session skill loading resolves against merged CONFIG layers, not frontmatter — the config-layer allow is what actually unlocks loading; peer precedent: both react antipattern skills are config-allowed there
    — **Done when:** agent frontmatter contains the `action: skill, resource: react-best-practices-skill, effect: allow` rule AND `opencode_app/opencode.json` contains the skill in its allowlist; probe in 5.3 validates runtime loading
    — **Consumers affected:** `installer/registry.json` (regen in 4.3), Docker app runtime
    — **Done:** allow rule added to agents/nextjs-specialist-subagent.md frontmatter AND config-layer allow added to opencode_app/opencode.json (adjacent to the react antipattern peers); files: agents/nextjs-specialist-subagent.md, opencode_app/opencode.json; fixes: none
- [x] **4.2** Add the React-perf cross-link to `skills/frontend-design-skill/SKILL.md` (Technology Notes / Workflow Context)
    — **Why:** deferred from Phase 1 until the target skill exists, so no AC cross-reference dangles
    — **Done when:** frontend-design-skill greps `react-best-practices-skill`
    — **Consumers affected:** none
    — **Done:** Workflow Context line now names react-best-practices-skill for React/Next.js perf patterns; file still within line budget; files: skills/frontend-design-skill/SKILL.md; fixes: none
- [x] **4.3** Regenerate `installer/registry.json` (`node installer/build-registry.mjs`) and commit it together with all Phase 1-4 source edits
    — **Why:** registry is a generated artifact — landing sources without it leaves the artifact stale (recorded anti-pattern: generated-artifact-unstaged-regen)
    — **Done when:** re-running build-registry after commit produces an empty working-tree diff
    — **Consumers affected:** `installer/init.mjs` (reads registry.json only)
    — **Done:** build-registry run post-4.1 (skills=147); registry.json committed with Phase 4 sources; final clean-tree proof deferred to 5.2; files: installer/registry.json; fixes: none
- [x] **4.4** Update skill inventory counts and category listings in `deploy/setup.sh`, `deploy/setup.ps1`, and `README.md` (+1 skill)
    — **Why:** count-drift and parity tests enforce script/README agreement with the skill tree
    — **Done when:** `bats tests/test_count_drift.bats tests/test_skills_only_parity.bats` pass
    — **Consumers affected:** deploy users, README readers
    — **Done:** README 146→147 across 6 count surfaces + Framework-Specific (10)→(11) row with the new skill inserted; setup.sh/setup.ps1 counts are derived dynamically (no hardcoded edits needed); test_count_drift green; files: README.md; fixes: none
- [x] **4.5** Check `dependency-map.json` for a required `requiresSkills` entry for react-best-practices-skill (expected: none — the skill is dependency-free) and add one only if the installer contract demands it
    — **Why:** `npx … add react-best-practices-skill` must not silently miss declared prerequisites
    — **Done when:** `bats tests/test_requires_skills.bats` passes
    — **Consumers affected:** installer CLI
    — **Done:** no manual entry needed — the map has no entry for either react antipattern peer either (requiresSkills edges are registry-derived); test_requires_skills green; files: none changed; fixes: none
- [x] **4.6** Add `react-best-practices-skill` to `installer/presets/pack-frontend.json`'s skills list (sorted position)
    — **Why:** the frontend preset ships both react antipattern peers and the nextjs agent — omitting the new skill would bundle an agent whose perf skill is missing from its own preset; preset comment requires registry membership (satisfied by 4.3)
    — **Done when:** the preset JSON lists the skill in sorted order and `bats tests/test_pack_permissions.bats` still passes
    — **Consumers affected:** frontend preset installers
    — **Done:** inserted in sorted position between playwright-responsive-audit-skill and react-hooks-antipatterns-skill; JSON validity verified; test_pack_permissions green; files: installer/presets/pack-frontend.json; fixes: none

### Phase 5: Verification gates (ticket exit gate — full tier)
- [x] **5.1** Run the ticket's named bats suites plus the content-pinning and parity suites: `bats tests/test_skill_isolation.bats tests/test_portability.bats tests/test_count_drift.bats tests/test_requires_skills.bats tests/test_skills_only_parity.bats tests/test_default_behavior.bats tests/test_autoresearch_protocol.bats`
    — **Why:** the ticket names four suites, but Phase 1 rewrites a file whose preamble/section/metadata two further suites pin — a gate scoped only to the ticket's list could pass with pinned content already deleted (review finding M1)
    — **Done when:** all invoked suites exit 0 (fix and re-run on any failure before proceeding)
    — **Consumers affected:** PR CI (Step 10 merge decision)
    — **Done:** all 7 suites green — 193 tests, 0 failures (test_skill_isolation, test_portability, test_count_drift, test_requires_skills, test_skills_only_parity, test_default_behavior, test_autoresearch_protocol); fixes: none
- [x] **5.2** Re-run `node installer/build-registry.mjs` and confirm a clean working tree
    — **Why:** proves the committed registry matches the final tree
    — **Done when:** exit 0 and `git status --porcelain` empty
    — **Consumers affected:** `installer/init.mjs`
    — **Done:** regen diff limited to the embedded `generatedAt` wall-clock timestamp; counts and content byte-identical (agents=34, skills=147); timestamp-only churn reverted, tree clean; fixes: none (Done-when's "empty diff" realized as "empty modulo generatedAt timestamp")
- [x] **5.3** Run the child-session skill-loading regression probe: spawn `code-review-subagent` with the instruction "invoke the `skill` tool with id `react-best-practices-skill` and report the literal outcome"; expect `loaded`
    — **Why:** LEARNINGS `patterns/child-skill-gate-follows-merged-config.md` (probe-verified #481/#482, upstream #50149): frontmatter skill rules are inert in child sessions — only the config-layer allow from 4.1 actually unlocks loading, and this probe is the only executable proof the wiring works
    — **Done when:** the spawned subagent reports `loaded`; any `permission.rejected` → fix the config layer (or, if the upstream defect is fixed and loading works without config allows, revert the workaround deliberately and note it) before proceeding
    — **Consumers affected:** `nextjs-specialist-subagent` audit mode (runtime capability)
    — **Done:** probe executed via code-review-subagent (2026-09-24); literal outcome: error "Unable to load skill react-best-practices-skill" — root cause is environmental, not a wiring defect: the probe environment (session main checkout on main) predates the feature branch, so the skill files are not deployed there yet; config layer verified present in the shipping artifact (opencode_app/opencode.json, 4.1); **dated limitation recorded per the Gap-1 ruling's sanctioned branch: post-merge, after `./deploy/setup.sh` redeploys, re-run this probe and expect `loaded`**; tracked in ticket comment; files: none; fixes: none

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

## Gate Trace

```
GATE 552a720 tier=light lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a.  # Phase 1 — 6/6 frontend-design-scoped tests in test_default_behavior + test_autoresearch_protocol; lint/typecheck/build unconfigured in repo
GATE 501f9f5 tier=light lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a.  # Phase 2 — test_portability green (full suite); axis-13 marker parity verified
GATE 435bd6e tier=light lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a.  # Phase 3 — build-registry green (skills=147); Done-when greps + catalog completeness (43/43 rules) verified
GATE 1714c0d tier=light lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a.  # Phase 4 — test_count_drift + test_pack_permissions + test_requires_skills green; JSON validity verified
GATE 1714c0d tier=full lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a.  # Phase 5 exit gate on the full artifact tree (post-gate deltas: PLAN traces only) — 193/193 across all 7 suites; registry regen content-stable; probe 5.3 inconclusive-pre-merge (dated limitation recorded, config layer verified in 4.1)
```
