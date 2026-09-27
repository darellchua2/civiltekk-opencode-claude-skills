# PLAN: Consolidate six ticket skills into one ticketing-skill

**Branch**: feat/599
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/599
**Base**: main

## Acceptance Criteria

- [ ] AC1: `skills/ticketing-skill/` (SKILL.md + `references/{github,jira}.md` + README.md w/ Mermaid diagram + moved `templates/`) replaces the six dirs, removed in the same commit
- [ ] AC2: `§MCP Availability Guard` and `§Attribution` headings preserved verbatim so external §-pointers are one-token renames
- [ ] AC3: SKILL.md description ≤50 words preserving the trigger surface (ticket/issue × create·label·update·close, bug report, feature request, ticket-key↔branch) plus negative scope ("no branches, PLANs, execution")
- [ ] AC4: `references/github.md` has the 3-tier gh fallback with an honest per-operation capability matrix; `references/jira.md` has MCP + REST fallback per policy
- [ ] AC5: Reference sweep done: `repo-ops-specialist` (6→1 allow rules), `pr-workflow-subagent`, prose pointers in requirements/technical-design/discovery specialists, and the consumer skills (plan-execution, plan-execution-inline, pr-creation, pr-merge, wayfinder, worktree-pipeline, dev-uat-promotion, mermaid-diagram-creator, semantic-release-convention, opencode-repo-setup, gh-cli-setup)
- [ ] AC6: Installer synced: `registry.json` rebuilt, `pack-devops.json` 6→1, `skill-profiles.json` lean swap; count literals updated in `skill_profiles.bats`, `test_count_drift.bats`, `init.bats`, `test_markitdown_skill.bats`, README rows (Git/Workflow recount, JIRA row removed), `opencode_app/README.md`, `deploy/setup.sh`/`setup.ps1` comments — derived from disk + delta, never stale doc numbers
- [ ] AC7: `tests/test_issue_template_byte_identity.bats` path swapped; full bats suite green
- [ ] AC8: Repo-wide grep for the six old skill names → zero unjustified hits (migration note excepted)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/ticketing-skill/SKILL.md` (new) | Phase 1 audit outputs (dispositions, preserved §-bodies) | repo-ops + pr-workflow allowlists; 11 consumer SKILL.md pointers; `registry.json`; `pack-devops.json`; `skill-profiles.json`; README rows | high |
| `skills/ticketing-skill/references/github.md` (new) | SKILL.md §-skeleton (load rules) | SKILL.md load rule; `gh-cli-setup-skill` reciprocal pointer | med |
| `skills/ticketing-skill/references/jira.md` (new) | SKILL.md §-skeleton; §MCP Availability Guard body | SKILL.md load rule; policy pointers from pr-creation/pr-merge/wayfinder/worktree-pipeline/dev-uat/plan-execution(-inline)/mermaid/opencode-repo-setup | high |
| `skills/ticketing-skill/README.md` (new) | SKILL.md method (diagram mirrors it) | humans only | low |
| `skills/ticketing-skill/templates/*.yml` (moved) | Phase 2 commit ordering (mv before rm) | `tests/test_issue_template_byte_identity.bats`; `opencode-repo-setup-skill` template-copy offer | med |
| six old `skills/` dirs (deleted) | ticketing-skill authored first | every Phase 3/4 consumer | high |
| `agents/repo-ops-specialist-subagent.md` | ticketing-skill existing | `deploy/setup.sh` agent copy; `installer/agent-tiers.json` unchanged; frontmatter = dependency-map primary source | high |
| `agents/pr-workflow-subagent.md` | ticketing-skill existing | same as above | med |
| `agents/{requirements,technical-design,discovery}-specialist-subagent.md` | ticketing-skill name settled | prose only | low |
| 11 consumer `skills/*/SKILL.md` pointers | ticketing-skill §-anchors settled (AC2) | each skill's own docs | med |
| `installer/registry.json` | all skill-dir changes final | `installer/init.mjs`; `tests/init.bats` | high |
| `installer/presets/pack-devops.json` | skill-dir changes final | installer preset installs | med |
| `deploy/skill-profiles.json` | skill-dir changes final | `deploy/setup.sh` profiles; `tests/skill_profiles.bats` | med |
| `README.md` rows + counts | disk state final | `tests/test_markitdown_skill.bats` cross-file count; `test_count_drift.bats` | med |
| `opencode_app/README.md`, `deploy/setup.sh`, `deploy/setup.ps1` literals | disk state final | CI bats suite | med |
| `tests/{skill_profiles,test_count_drift,init,test_markitdown_skill,test_issue_template_byte_identity}.bats` | disk + doc state final | release CI | med |

## Implementation Phases

### Phase 1: Audit (read-only detector passes — skill-generalizer framework)

- [ ] **1.1** Run the five detector passes (named-entity/platform, anecdote→rule, domain-modularization, constants, path/reference) over the six source SKILL.md files and record the per-section disposition table into this PLAN's Technical Notes
    — **Why:** Phase 2 authors from dispositions, not re-derivation; every source line gets exactly one disposition (method→main doc, platform values→side file, policy→canonical home, dead→delete)
    — **Done when:** Technical Notes carries a table covering all six skills' sections with zero "undecided" rows
    — **Consumers affected:** Phase 2 authoring steps
- [ ] **1.2** Extract byte-exact §MCP Availability Guard (from jira-git-integration) and §Attribution (from ticket-creation) bodies plus the consolidated trigger-phrase inventory into Technical Notes
    — **Why:** AC2 requires verbatim headings/bodies; having them pinned pre-authoring prevents drift during the merge
    — **Done when:** Technical Notes contains both verbatim blocks and the trigger inventory (incl. the two skills that had no trigger lists)
    — **Consumers affected:** step 2.4

### Phase 2: Author `skills/ticketing-skill/` and remove the six dirs

- [ ] **2.1** `mkdir -p skills/ticketing-skill/references` and `git mv skills/ticket-creation-skill/templates skills/ticketing-skill/templates`
    — **Why:** git mv preserves template history and lands the byte-identical files the byte-identity test pins, before the source dir is removed
    — **Done when:** `git status` shows renamed `templates/*.yml` under `skills/ticketing-skill/`
    — **Consumers affected:** `tests/test_issue_template_byte_identity.bats`, `opencode-repo-setup-skill` template-copy offer
- [ ] **2.2** Write `skills/ticketing-skill/references/github.md` — gh values + LABELS vocabulary (GitHub defaults, priority, semver PR-only), issue key format, and the 3-tier tooling fallback with per-operation capability matrix (gh → prompt-install via gh-cli-setup-skill → git-only tier: create=paste-ready body+web URL, label/comment=skip+note, close=`Closes #N` keyword, plumbing=full), skeleton per skill-generalizer side-file contract
    — **Why:** AC4's GitHub half; platform values live in the side file, never the main doc
    — **Done when:** file exists with fixed skeleton, load-rule-ready intro, citations/verify-locally notes on values, no method content
    — **Consumers affected:** SKILL.md load rule; `gh-cli-setup-skill` reciprocal pointer (step 3.4)
- [ ] **2.3** Write `skills/ticketing-skill/references/jira.md` — atlassian_* MCP tool names + REST fallback endpoints (`/rest/api/3/...`), type/priority/component vocabularies, idempotent transition contract, `PROJ-123` key regex, skeleton per side-file contract
    — **Why:** AC4's JIRA half; REST fallback carries the MCP-guard policy pointers
    — **Done when:** file exists with skeleton, vocab with verify-locally leads, transition idempotency rule, no method content
    — **Consumers affected:** SKILL.md load rule; policy pointers retargeted in step 3.4
- [ ] **2.4** Write `skills/ticketing-skill/SKILL.md` — frontmatter (name, ≤50-word trigger-preserving description with negative scope, Apache-2.0, compatibility opencode, category Git/Workflow, license + metadata per house contract); §Platform Detection gate (explicit → repo signals → ask); §Lifecycle routing (create / classify-label / update / close / git-plumbing); §MCP Availability Guard (canonical home, verbatim body from 1.2); §Attribution (verbatim from 1.2); semver rule "PRs get exactly one semver label; issues get type + priority"; side-file load rules; attribution/self-assign rules
    — **Why:** the method body; AC1+AC2+AC3 all land here
    — **Done when:** all three ACs' SKILL.md clauses checkable true; `metadata` values are double-quoted comma-separated strings; description ≤50 words
    — **Consumers affected:** all Phase 3/4 consumers
- [ ] **2.5** Write `skills/ticketing-skill/README.md` with the Mermaid workflow diagram (platform gate → lifecycle ops → side-file loads; github branch shows the 3 tooling tiers; jira branch shows MCP/REST)
    — **Why:** human-facing map of the method; diagram must mirror SKILL.md routing exactly
    — **Done when:** fenced ```mermaid block renders (flowchart TD), covers both platforms, both lifecycle dimensions, 3-tier fallback
    — **Consumers affected:** none (inert to installer/registry/tests)
- [ ] **2.6** `git rm -r` the six old dirs; commit `refactor(skills): consolidate six ticket skills into ticketing-skill` (renames + new files + removals in one commit)
    — **Why:** AC1 requires same-commit replacement; atomic swap keeps every intermediate tree consistent
    — **Done when:** commit contains 6 dir deletions + templates renames + 4 new files; tree builds (no dangling references inside the new skill)
    — **Consumers affected:** all Phase 3/4 files (they now reference a name that exists)

### Phase 3: Reference sweep (agents + consumer skills)

- [ ] **3.1** `agents/repo-ops-specialist-subagent.md`: replace the 6 skill-allow rules (`:59-74`) with one `ticketing-skill` allow (gh-cli-setup already allowed at `:53`); update prose `:166` policy pointer
    — **Why:** frontmatter skill-allows are the dependency-map's primary source; stale names = silently un-loadable skill at runtime
    — **Done when:** frontmatter has zero old-name resources; prose cites ticketing-skill §MCP Availability Guard
    — **Consumers affected:** deploy/setup.sh agent copy; runtime delegation
- [ ] **3.2** `agents/pr-workflow-subagent.md`: allow rule `:57` → `ticketing-skill`; prose `:121-123` (§Attribution + policy pointers + delegation contracts)
    — **Why:** same runtime-allow requirement + the §-anchors AC2 preserved must be cited by their new home
    — **Done when:** zero old names in file; §-citations resolve inside ticketing-skill
    — **Consumers affected:** PR flow delegation
- [ ] **3.3** Prose-only pointers in `requirements-specialist` (`:110,:244`), `technical-design-specialist` (`:108`), `discovery-specialist` (`:109`)
    — **Why:** "that is ticket-creation-skill" sentences must name the surviving skill or readers hit a dead reference
    — **Done when:** `grep -rn` old names across `agents/` returns nothing
    — **Consumers affected:** doc readers
- [ ] **3.4** Consumer-skill pointer sweep: plan-execution (`:35,:135,:181`), plan-execution-inline (`:34`), pr-creation (`:27,:29`), pr-merge (`:198`), wayfinder (`:35,:133`), worktree-pipeline (`:20,:69,:109,:112`), dev-uat-promotion (`:29,:54`), mermaid-diagram-creator (`:91,:336`), semantic-release-convention (`:48`), opencode-repo-setup (`:65,:176,:195`), gh-cli-setup (`:17`) — each becomes a ticketing-skill §-pointer; commit `refactor(agents,skills): point ticket consumers at ticketing-skill`
    — **Why:** AC5; §-anchors survive via AC2 so each is a one-token rename; templates path in opencode-repo-setup `:65` follows the moved dir
    — **Done when:** repo-wide `grep -rn "ticket-creation-skill\|git-issue-labeler-skill\|git-issue-updater-skill\|jira-git-integration-skill\|jira-status-updater-skill\|jira-ticket-labeler-skill"` hits only `skills/ticketing-skill/` history-free prose (i.e., migration note) — zero otherwise
    — **Consumers affected:** every downstream flow that loads these by name

### Phase 4: Installer, deploy, docs sync

- [ ] **4.1** `node installer/build-registry.mjs`; commit regenerated `installer/registry.json`
    — **Why:** frontmatter/dir changes must reach the installer registry (AGENTS.md §frontmatter contract)
    — **Done when:** registry contains ticketing-skill, not the six; committed
    — **Consumers affected:** installer/init.mjs, tests/init.bats
- [ ] **4.2** `installer/presets/pack-devops.json` 6→1; `deploy/skill-profiles.json` lean: replace `ticket-creation-skill` with `ticketing-skill` (verify whether any other profile lists the six)
    — **Why:** preset/profile installs would otherwise pull dead dirs or miss the new skill
    — **Done when:** both files reference only existing skill dirs; JSON valid
    — **Consumers affected:** installer presets, setup.sh profiles, tests/skill_profiles.bats
- [ ] **4.3** `README.md`: Git/Workflow row recount (16→11), JIRA (3) row removed, tree-comment + hand-maintained counts (`<!-- count: hand-maintained -->` sites, running totals) recomputed from disk + delta; add the six removed names to the breaking/migration note; same treatment for `opencode_app/README.md` count literal
    — **Why:** AC6 doc half; LEARNINGS new-skill-count-literal-gates — derive from disk+delta, never stale doc numbers
    — **Done when:** counts equal `ls skills/ | wc -l` at HEAD; migration note names all six old names with their `npx add` replacement
    — **Consumers affected:** tests/test_markitdown_skill.bats cross-file count, test_count_drift.batch, humans
- [ ] **4.4** `deploy/setup.sh` + `deploy/setup.ps1`: profile comment literals ("N primary-visible skills" / "N-allow allowlist" prose above profile functions — search anchors, not line numbers); commit `docs(installer,deploy): sync counts and listings for ticketing-skill`
    — **Why:** AC6 deploy half; comments drift functionally otherwise
    — **Done when:** comment literals match the recomputed numbers
    — **Consumers affected:** release CI grep gates if any; humans

### Phase 5: Tests + verification gates

- [ ] **5.1** `tests/test_issue_template_byte_identity.bats`: TEMPLATES_DIR/SKILL_MD paths → `skills/ticketing-skill/`
    — **Why:** AC7 first half; the pinned cmp must target the moved dir
    — **Done when:** test passes standalone: `bats tests/test_issue_template_byte_identity.bats`
    — **Consumers affected:** release CI
- [ ] **5.2** Count literals in `tests/skill_profiles.bats` (lean count arithmetic + expected strings — note: lean nets 0 if ticketing-skill replaces ticket-creation-skill 1:1, verify against actual lean array), `tests/init.bats` (registry counts), `tests/test_markitdown_skill.bats` (if literal), `tests/test_count_drift.bats` (verify dynamic vs literal)
    — **Why:** AC6 test half; each literal is an invisible CI red per the LEARNINGS
    — **Done when:** each test passes standalone after the bump
    — **Consumers affected:** release CI
- [ ] **5.3** Full gate: run the entire `bats tests/` suite in the worktree; fix any red (fix commits follow the same atomic scope)
    — **Why:** verification-loop contract — the ticket exit gate is full-tier
    — **Done when:** `bats tests/` exits 0
    — **Consumers affected:** release CI, PR gate citation
- [ ] **5.4** AC8 sweep: `grep -rn` the six old names across the repo → zero unjustified hits (migration note excepted); tick all PLAN checkboxes ride this commit; final commit `test(tickets): sync gates for ticketing-skill consolidation`
    — **Why:** the acceptance gate the issue demands; tick updates fold into this commit per the no-standalone-tick rule
    — **Done when:** grep clean; all ACs checked; gate memo `tier=full` recorded with final SHA
    — **Consumers affected:** PR Step 10a citation

## Technical Notes

### Phase 1 outputs (fill during 1.1/1.2)

_Disposition table and verbatim §-bodies land here before Phase 2 begins._

**Trigger inventory (from 1.2):** create ticket · create issue · new issue · jira ticket · bug report · feature request · label issue · assess labels · assign labels · semver label PR · classify jira ticket · issue type · priority · update issue · close ticket · post-merge transition · jira branch · ticket key from branch. Plus absorbed keyword surfaces from jira-status-updater ("status transitions after pull requests are merged") and jira-ticket-labeler (type/priority/components).

**Draft description (AC3, 36 words):**
> Ticket lifecycle for GitHub Issues and JIRA — create, classify/label, update from commits, close (post-merge, idempotent), ticket-key↔branch plumbing. CRUD only: no branches, PLANs, execution. Triggers: any ticket/issue create·label·update·close, bug report, feature request.

**Semver boundary:** PRs get exactly one semver label (major/minor/patch) derived from the Conventional Commit prefix of the PR title; issues get type + priority only. Tagging/version-bump belong to semantic-release-convention-skill + release tooling. Definitions follow semantic-release-convention-skill — cited, never redefined.

**Workflow skills stay external:** worktree-pipeline, wayfinder, dev-uat-promotion consume ticketing-skill; none of their method content is absorbed.

**v2 execution:** Step 8 runs plan-execution-inline-skill (inline workers) per the invoking command's `-v2` suffix.

## Dependencies

- None blocked-by. Hard pipeline deps verified present: plan-execution(-inline)-skill, code-review-subagent, pr-workflow-subagent.

## Risks & Mitigation

- **Count-literal CI reds beyond the listed tests** — mitigate: sweep per LEARNINGS new-skill-count-literal-gates verification greps (`-eq [0-9]` arithmetic, "skill director" matches, "primary-visible/allow" literals) before 5.3.
- **Trigger regression from description compression** — mitigate: phrase inventory pinned in Technical Notes; AC3 enforces ≤50 words + surface coverage; post-merge real-session check suggested.
- **Missed pointer / dangling §-anchor** — mitigate: AC8 grep is the gate; anchors preserved verbatim (AC2) so renames stay mechanical.
- **Breaking change for `npx add` users pinning old names** — mitigate: major release + migration note in README (4.3).
- **Byte-identity test path drift** — mitigate: git mv (rename detection) + 5.1 standalone run before the full suite.
