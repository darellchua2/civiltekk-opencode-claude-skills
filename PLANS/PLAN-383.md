# PLAN: Simplify skill content — trim model-known docs from top 50 skills

**Branch**: feat/383
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/383
**Base**: main

## Acceptance Criteria

- [ ] 5 pilot skills trimmed and shape approved: `clean-code-skill`, `nextjs-image-usage-skill`, `opentofu-kubernetes-explorer-skill`, `git-semantic-commits-skill`, `docx-creation-skill`
- [ ] `opencode-skill-creation-skill` + `opencode-skills-maintainer-skill` updated to lean standard (removes "more detail is better" mandate — prevents regrowth)
- [ ] Remaining 44 of top 50 trimmed by category (A textbook → ~40–80 lines; B vendor-ref → ~100–200; C house-workflow → ~40–60% cut; E office → SKILL.md ≤200 + `reference.md` sibling)
- [ ] All frontmatter byte-identical; `node deploy/build-registry.mjs` shows no unexpected diff
- [ ] All 22 `Learning:` entries across 5 skills preserved verbatim
- [ ] No dangling `§` section references (grep AGENTS.md chain, incl. `api-design-skill` §Authoring Quality Gate)
- [ ] Vendored `gsap-*` / `ponytail` skills untouched
- [ ] Lint/test gates pass

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---|---|---|---|
| `opencode_app/.opencode/skills/{clean-code,nextjs-image-usage,opentofu-kubernetes-explorer,git-semantic-commits,docx-creation}-skill/SKILL.md` | — | Agents that load these skills on invoke; `git-semantic-commits-skill` additionally routed from AGENTS.md §Commits | low (content-only, frontmatter frozen) |
| User approval of pilot shape | Phase 1 complete | Phases 2–3 (the approved shape is their reference standard) | — (gate) |
| `opencode-skill-creation-skill/SKILL.md` | Pilot shape approved | Every future skill (template mandates); `opencode-skills-maintainer-skill` audits against it | med (changes authoring standard) |
| `opencode-skills-maintainer-skill/SKILL.md` | Creation-skill lean standard | On-demand skill audits | med |
| 44 bulk skill files (lists in Phase 3) | Pilot shape + Phase 2 standard | Agents that load them; `deploy/registry.json` counts (unchanged) | low |
| `docx-creation-skill/reference.md`, `pdf-specialist-skill/reference.md`, `pptx-generate-slide-skill/reference.md` | — (new sibling files, category E only) | The SKILL.md that points to them; opencode v2 reads on demand | low |
| `deploy/registry.json` | — (verification only; expect NO diff) | Installer: `init.mjs`, `setup.sh` counts | low |

**Triage note (Step 7)**: content-only markdown edits; no cross-module code nodes → architecture review skipped. No frontend signal → uiux skipped. PLAN freshly generated → requirements review required.

## Implementation Phases

### Phase 1: Pilot (trim + per-skill commit + approval gate)

- [x] **1.1** Trim `clean-code-skill/SKILL.md` (934 → ~40–80 lines), category A: keep triggers/house rules + all 10 `Learning:` entries verbatim; delete Object Calisthenics/naming textbook and generic examples; commit `refactor(skills): trim textbook content from clean-code-skill`
    — **Why:** Largest Learning density (10 entries) — validates the aggressive A treatment at its riskiest point and sets the shape for Phase 3 batch A.
    — **Done when:** `wc -l` ≤ 80; `grep -c 'Learning: \`'` output equals 10; `git diff` on frontmatter block is empty; commit pushed.
    — **Consumers affected:** agents invoking clean-code-skill; none else (no § anchors reference it).
    — **Done:** trimmed 934->64 lines; all 10 Learning entries verbatim (rule+detection kept, code examples dropped); textbook deleted; files: clean-code-skill/SKILL.md; fixes: none
- [x] **1.2** Trim `nextjs-image-usage-skill/SKILL.md` (1287 → ~100–200 lines), category B: keep img→Image detection/conversion rules, Next.js 16 breaking changes, remote-domain config gotchas; delete prop tables and usage tutorials; commit `refactor(skills): trim vendor API reference from nextjs-image-usage-skill`
    — **Why:** Biggest file in the set — proves the B cut on the worst offender and preserves the version-pinned knowledge that models get wrong.
    — **Done when:** `wc -l` ≤ 200; frontmatter byte-identical; conversion-checklist + Next 16 breaking-changes sections present; commit pushed.
    — **Consumers affected:** agents invoking nextjs-image-usage-skill; none else.
    — **Done:** trimmed 1287->70 lines; kept img->Image conversion rule, Next 16 breaking-change table, remotePatterns config+security, failure->fix map; files: nextjs-image-usage-skill/SKILL.md; fixes: none
- [x] **1.3** Trim `opentofu-kubernetes-explorer-skill/SKILL.md` (1212 → ~100–200 lines), category B: keep house conventions (provider pinning, naming, workflow contract, exact commands); delete the 15-step HCL-per-resource tutorial; commit `refactor(skills): trim HCL recipes from opentofu-kubernetes-explorer-skill`
    — **Why:** Second-biggest file; the HCL recipes are the purest model-known content in the set — highest deletion yield.
    — **Done when:** `wc -l` ≤ 200; frontmatter byte-identical; house conventions + commands retained; commit pushed.
    — **Consumers affected:** opentofu-explorer-subagent (loads on invoke); none else.
    — **Done:** trimmed 1212->61 lines; kept provider pins (~> 2.24.0/~> 2.11.0), s3+lockdb backend, 4 connection methods, resource conventions; dropped 15-step HCL tutorial; files: opentofu-kubernetes-explorer-skill/SKILL.md; fixes: none
- [x] **1.4** Trim `git-semantic-commits-skill/SKILL.md` (776 → ~40–60% cut), category C: keep Conventional Commits house rules, granularity guidance, commitlint notes; delete template ceremony (Prerequisites/Common Issues/Verification boilerplate) and generic commit examples; commit `refactor(skills): trim ceremony from git-semantic-commits-skill`
    — **Why:** Routed from AGENTS.md §Commits — validates that externally-routed skills keep their contract through a C trim.
    — **Done when:** `wc -l` ≤ 465 (≥40% cut); frontmatter byte-identical; house rules + granularity table intact; commit pushed.
    — **Consumers affected:** primary sessions following AGENTS.md commit rules; repo-ops-specialist-subagent.
    — **Done:** trimmed 776->55 lines (93% cut); kept granularity doctrine + layer table + split rule + handoffs to git-compact-commits-skill/semantic-release-convention; files: git-semantic-commits-skill/SKILL.md; fixes: none
- [x] **1.5** Trim `docx-creation-skill/SKILL.md` (562 → SKILL.md ≤200) + create `reference.md` sibling, category E: keep workflow + OOXML quirks + AI-slop avoidance in SKILL.md; move XML reference tables to `reference.md` with a one-line pointer; commit `refactor(skills): split docx-creation reference into sibling file`
    — **Why:** Only pilot step exercising the v2 sibling-file pattern — must be proven before Phase 3 batch E (2 files) adopts it.
    — **Done when:** `wc -l SKILL.md` ≤ 200; `reference.md` exists in same dir; pointer line present; frontmatter byte-identical; commit pushed.
    — **Consumers affected:** docx-creation-subagent; office-document routing in AGENTS.md (no § anchor on this file).
    — **Done:** SKILL.md 562->68 + new reference.md sibling (187) with docx-js code patterns + XML reference; SKILL.md keeps house scripts, critical rules, 3-step edit workflow, design doctrine; files: docx-creation-skill/{SKILL.md,reference.md}; fixes: none
- [x] **1.6** HALT for user approval of pilot shape — present before/after line counts and one trimmed file (clean-code) to the user
    — **Why:** The ticket's first acceptance criterion requires shape approval; Phases 2–3 apply this shape 46 more times.
    — **Done when:** user explicitly approves in-session; on rejection, halt pipeline per failure policy (worktree kept).
    — **Consumers affected:** all Phase 2/3 steps (blocked until approved).
    — **Done:** user approved the pilot shape in-session ("continue completion of all phases"); Phases 2-3 unblocked.

### Phase 2: Fix the bloat source (anti-regrowth)

- [ ] **2.1** Rewrite `opencode-skill-creation-skill/SKILL.md` (492 → ~120 lines): delete "Be thorough: More detail is better than less" + ceremony-template mandate; install lean standard (target line budgets per category, model-knowledge rule: "encode only what is house-specific"); keep frontmatter contract table + registry rebuild instruction; commit `refactor(skills): adopt lean standard in opencode-skill-creation-skill`
    — **Why:** The template is the regrowth engine — every new skill inherits its padding unless this changes first.
    — **Done when:** mandate text absent (`grep -c "More detail is better"` = 0); lean-standard section present; frontmatter byte-identical; commit pushed.
    — **Consumers affected:** all future skill authoring; opencode-skills-maintainer-skill audits.
- [ ] **2.2** Update `opencode-skills-maintainer-skill/SKILL.md`: add a category-aware bloat check enforcing the lean standard — flag SKILL.md >300 lines for category A/B/E (E exempt when a `reference.md` sibling exists); for category C (house workflows, legitimately 400–600 lines post-trim), record the post-trim baseline in the maintainer and flag regrowth beyond it; commit `refactor(skills): add lean-standard bloat check to skills maintainer`
    — **Why:** Audits must enforce the new standard or drift back goes undetected.
    — **Done when:** bloat-check rule present with the >300-line threshold + E exception; commit pushed.
    — **Consumers affected:** on-demand skill audits.

### Phase 3: Bulk trim (44 files; category batches; one commit per batch)

Phase 3 preamble — per-file protocol (applies to every file below):

1. Read the full file.
2. `grep -rn '<skill-name>\|§'` across the AGENTS.md chain (`AGENTS.md`, `opencode_app/AGENTS.md`, `deploy/.AGENTS.md`, `~/.config/opencode/AGENTS.md`) → protect referenced sections.
3. Snapshot `Learning:` entries verbatim: `grep 'Learning: \`' <file>` → `/tmp/opencode/learnings-<skill>.txt`.
4. Keep triggers/house conventions/version-pinned facts/`Learning:` entries; delete model-known content + ceremony; verify frontmatter byte-identical.
5. Per batch, before its commit: re-run the §-resolution grep for every in-batch skill with an external anchor, and `diff` each Learning snapshot against the post-trim file — both must be clean.

- [ ] **3.1** Batch A — textbook, → ~40–80 lines each (10 files): `typescript-dry-principle`, `design-patterns` (5 Learnings), `authentication-authorization`, `code-smells`, `object-design` (2 Learnings), `performance-optimization`, `clean-architecture` (2 Learnings), `complexity-management`, `monorepo-management`, `solid-principles`; commit `refactor(skills): trim textbook content from 10 category-A skills`
    — **Why:** Biggest cuts, lowest risk — pure model-knowledge deletion with Learning preservation as the only care point.
    — **Done when:** each file ≤80 lines; Learning counts preserved (5+2+2); frontmatter byte-identical across all 10; commit pushed.
    — **Consumers affected:** agents invoking these skills on demand.
- [ ] **3.2** Batch B — vendor reference, → ~100–200 lines each (12 files): `nextjs-unit-test-creator`, `opentofu-aws-explorer`, `autodesk-aps`, `python-backend` (3 Learnings), `threejs-nextjs`, `opentofu-keycloak-explorer`, `opentofu-neon-explorer`, `playwright-responsive-audit`, `docstring-generator`, `opentofu-ecr-provision`, `nextjs-standard-setup`, `python-packaging`; commit `refactor(skills): trim vendor references from 12 category-B skills`
    — **Why:** Same treatment as pilot 1.2/1.3 at scale; version-pinned facts and house commands survive, tutorials go.
    — **Done when:** each file ≤200 lines; python-backend Learning count = 3; frontmatter byte-identical across all 12; commit pushed.
    — **Consumers affected:** agents/subagents invoking these skills; nextjs/cad specialist agents for the nextjs-* subset.
- [ ] **3.3** Batch C — house workflow, ~40–60% cut each (20 files): `horseshoe-paper-writing`, `wireframer`, `opentofu-provisioning-workflow`, `git-issue-updater`, `research-paper-generation`, `security-audit`, `tdd-workflow`, `git-compact-commits`, `pr-creation-workflow`, `api-design` (§Authoring Quality Gate must survive), `coverage-readme-workflow`, `jira-git-integration`, `jira-status-updater`, `plan-automation-loop`, `language-linting`, `continuous-learning`, `openapi-contract-adherence`, `deprecated-code-cleanup`, `plan-execution`, `documentation-consistency`; commit `refactor(skills): trim ceremony from 20 category-C skills`
    — **Why:** These encode house process — the trim removes template ceremony, never workflow logic or return contracts.
    — **Done when:** each file ≥40% smaller; api-design retains `§Authoring Quality Gate` heading; every skill's workflow steps + return contracts intact; commit pushed.
    — **Consumers affected:** every AGENTS.md-routed workflow that references these skills (security-audit, plan-*, git-*, documentation-sync).
- [x] **3.4** Batch E — office/media, SKILL.md ≤200 + `reference.md` sibling (2 files): `pdf-specialist-skill`, `pptx-generate-slide-skill`; commit `refactor(skills): split office reference material into sibling files`
    — **Why:** Same sibling-file pattern proven by pilot 1.5; dense format reference moves out of SKILL.md.
    — **Done when:** SKILL.md ≤200 lines each; `reference.md` siblings exist with pointer lines; commit pushed.
    — **Consumers affected:** pdf-specialist routing (AGENTS.md tier 4), pptx pipeline subagents.
    — **Done:** pdf-specialist 732->94 + reference.md (173); pptx-generate-slide 579->146 + reference.md (195); frontmatter frozen; done pre-merge, relocated to skills/ by the #384 merge commit a3d2acc.

### Phase 4: Verification & invariants

- [ ] **4.1** Invariant checks: `node deploy/build-registry.mjs --check` → expect exit 0 (the builder always rewrites `generatedAt` in write mode, so a plain diff can never be empty — `--check` normalizes it); `grep -rn '§' AGENTS.md opencode_app/AGENTS.md deploy/.AGENTS.md` — every referenced anchor still resolves in its target skill; `diff` every `/tmp/opencode/learnings-<skill>.txt` snapshot against the post-trim file (verbatim, not just count); total still 22; `git diff origin/main --stat -- 'opencode_app/.opencode/skills/gsap-*' 'opencode_app/.opencode/skills/ponytail*'` empty; registry count still 149. **On any violation: `git revert` the offending batch commit, re-trim, re-verify — never fix-forward past a broken invariant.**
    — **Why:** These are the ticket's hard invariants — any violation means a trim broke routing, memory, or the vendored pin.
    — **Done when:** all checks pass with the stated expected values.
    — **Consumers affected:** installer (registry), AGENTS.md routing, vendored-skill pin policy.
- [ ] **4.2** Gates: lint + test suite from `package.json` (discover scripts at execution; repo is Node — run whatever `npm run` exposes for lint/test; build only if deps/config/entry-points changed — they did not)
    — **Why:** Repo verification-gate policy: lint + typecheck always, tests on content-adjacent changes.
    — **Done when:** lint and test exit 0; failures either fixed or reported as pre-existing with evidence.
    — **Consumers affected:** CI (Step 10 re-runs them as PR checks).
- [ ] **4.3** Post-trim report + doc-sync check: total lines removed (`git diff origin/main --shortstat -- opencode_app/.opencode/skills/`), per-category totals, confirm no skill added/removed → no setup.sh/README count sync required; leave redeploy reminder (`./deploy/setup.sh`) in PR body
    — **Why:** Closes the loop on scope discipline and tells the user how to refresh deployed copies.
    — **Done when:** report produced; counts confirmed unchanged (149); note included in PR body.
    — **Consumers affected:** PR reviewers; user's deployed config.

## Technical Notes

- **Source of truth**: root `skills/` only (moved from `opencode_app/.opencode/skills/` by #384 mid-flight; merged into this branch at a3d2acc; `opencode_app/.opencode/` is now a symlink bridge — never edit through it) — never edit deployed `~/.config/opencode/` copies.
- **Frontmatter is frozen byte-for-byte** in every trim (name, description, license, compatibility, category, metadata). This keeps routing behavior and `registry.json` identical.
- **Category targets**: A → 40–80 lines; B → 100–200; C → 40–60% reduction; E → SKILL.md ≤200 + `reference.md` sibling with one-line pointer.
- **Protected content (never delete)**: `Learning:` entries (22 total: clean-code 10, design-patterns 5, python-backend 3, clean-architecture 2, object-design 2); externally-referenced § section anchors; trigger phrases in descriptions; return contracts; version-pinned breaking-change lists; house paths/commands.
- **Per-file § anchor check** precedes every trim (protocol in the Phase 3 preamble).
- **Commits**: Conventional Commits, one per pilot skill, one per category batch, one per Phase 2 file. No style-only mixing.
- **Model-knowledge rule** (the standard being installed): a skill encodes what is house-specific — triggers, conventions, version-pinned facts, workflow contracts — and never re-teaches what the model already knows.

## Dependencies

- None external. No `blocked-by:` tickets.

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| Trim degrades instruction-following or drops house rules | Pilot approval gate (1.6) before any bulk application |
| `Learning:` entries lost | Per-step count checks + Phase 4.1 total = 22 |
| Dangling § anchor breaks AGENTS.md routing | Per-file grep protocol + Phase 4.1 resolution check |
| Registry drift / routing change | Frontmatter frozen; 4.1 expects zero registry diff |
| Push fails (SSH key identity ≠ darellchua2) | `origin` is SSH; fallback = switch origin URL to HTTPS (gh credential helper auths as darellchua2) |
| Over-trim in category C removes workflow logic | C target is a percentage cut, not a line ceiling; return contracts + workflow steps listed as protected |
