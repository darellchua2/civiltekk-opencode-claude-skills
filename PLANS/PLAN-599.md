# PLAN: Consolidate six ticket skills into one ticketing-skill

**Branch**: feat/599
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/599
**Base**: main

**Revision 2** — architecture review + Mode R adjudication applied: `opencode_app/opencode.json` (full-profile single source) added as consumer + step; all sync surfaces folded into the same commit as the disk change (release.yml runs `build-registry.mjs --check` + every bats file per push — each commit below leaves CI green); corrected count arithmetic (Git/Workflow 16→14, JIRA (3) row removed, total 155→150, lean stays 78); 12th consumer `grilling-skill:144`; AC8 LEARNINGS disposition buckets adjudicated.

## Acceptance Criteria

- [ ] AC1: `skills/ticketing-skill/` (SKILL.md + `references/{github,jira}.md` + README.md w/ Mermaid diagram + moved `templates/`) replaces the six dirs, removed in the same commit
- [ ] AC2: `§MCP Availability Guard` and `§Attribution` headings preserved verbatim so external §-pointers are one-token renames
- [ ] AC3: SKILL.md description ≤50 words preserving the trigger surface (ticket/issue × create·label·update·close, bug report, feature request, ticket-key↔branch) plus negative scope ("no branches, PLANs, execution")
- [ ] AC4: `references/github.md` has the 3-tier gh fallback with an honest per-operation capability matrix; `references/jira.md` has MCP + REST fallback per policy
- [ ] AC5: Reference sweep: `repo-ops-specialist` (6→1 allow rules), `pr-workflow-subagent`, prose pointers in requirements/technical-design/discovery specialists, and the 12 consumer skills (plan-execution, plan-execution-inline, pr-creation, pr-merge, wayfinder, worktree-pipeline, dev-uat-promotion, mermaid-diagram-creator, semantic-release-convention, opencode-repo-setup, gh-cli-setup, grilling)
- [ ] AC6: Installer synced: `registry.json` rebuilt, `pack-devops.json` 6→1, `skill-profiles.json` lean swap, **`opencode_app/opencode.json` swept in the same commit** (6 allow rules → one `ticketing-skill` allow + `/create-ticket` template retarget — Mode R strengthening; gated by skill_profiles.bats :54 subset AND :63 dead-allow); count literals updated (skill_profiles.bats, init.bats, test_markitdown_skill.bats, README rows, opencode_app/README.md, deploy/setup.sh + setup.ps1 comments — disk + delta, never stale doc numbers; test_count_drift.bats is dynamic → no-op)
- [ ] AC7: `tests/test_issue_template_byte_identity.bats` path swapped (in the consolidation commit); full bats suite green
- [ ] AC8: Repo-wide grep for the six old names → zero hits outside the adjudicated disposition (Phase 5 buckets): **update** mcp-guard-single-homed, blocked-by-format-single-home:14, policy-single-home-pointer-shape:3, section-pins-target-heading-anchors:10 (live pins — retarget to ticketing-skill), `_index.md` mirrors :252,:258,:741,:1002; **grandfather as justified** CHANGELOG.md:645, PLANS/PLAN-{512,560,595}.md, rule-added-example-stale:8, gh-issue-edit-body-replaces-not-appends.md:23, `_index.md`:894

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/ticketing-skill/SKILL.md` (new) | Phase 1 audit outputs (dispositions, preserved §-bodies) | repo-ops + pr-workflow allowlists; 12 consumer SKILL.md pointers; `registry.json`; `pack-devops.json`; `skill-profiles.json`; `opencode_app/opencode.json` allow + `/create-ticket` template; README rows | high |
| `skills/ticketing-skill/references/github.md` (new) | SKILL.md §-skeleton (load rules) | SKILL.md load rule; `gh-cli-setup-skill` reciprocal pointer | med |
| `skills/ticketing-skill/references/jira.md` (new) | SKILL.md §-skeleton; §MCP Availability Guard body | SKILL.md load rule; policy pointers from 8 consumer skills | high |
| `skills/ticketing-skill/README.md` (new) | SKILL.md method (diagram mirrors it) | humans only | low |
| `skills/ticketing-skill/templates/*.yml` (moved) | Phase 2 ordering (mv before rm) | `tests/test_issue_template_byte_identity.bats`; `opencode-repo-setup-skill` template-copy offer | med |
| six old `skills/` dirs (deleted) | ticketing-skill authored first | every Phase 3/5 consumer | high |
| `opencode_app/opencode.json` | ticketing-skill existing; **same commit** as lean swap + dir swap (skill_profiles.bats :54 subset + :63 dead-allow gate both directions) | Docker app runtime; `tests/skill_profiles.bats` | high |
| `installer/registry.json` | all skill-dir + frontmatter changes (rebuilt in BOTH the Phase 2 and Phase 3 commits — `--check` runs per push) | `installer/init.mjs`; `tests/init.bats` | high |
| `installer/presets/pack-devops.json`, `deploy/skill-profiles.json` | skill-dir changes final; same commit as dir swap | installer presets; setup.sh profiles; `tests/skill_profiles.bats` | med |
| `README.md` rows + counts | disk state final; **same commit** as dir swap (test_markitdown cross-file count is per-push) | `tests/test_markitdown_skill.bats`; humans | med |
| `opencode_app/README.md` count | same commit as dir swap | CI bats count match | med |
| `agents/repo-ops-specialist-subagent.md` | ticketing-skill existing | deploy/setup.sh agent copy; runtime delegation; dependency-map primary source | high |
| `agents/pr-workflow-subagent.md` | ticketing-skill existing | same | med |
| `agents/{requirements,technical-design,discovery}-specialist-subagent.md` | ticketing-skill name settled | prose only | low |
| 12 consumer `skills/*/SKILL.md` pointers | §-anchors settled (AC2) | each skill's own docs | med |
| `deploy/setup.sh`, `deploy/setup.ps1` comment literals | disk state final (not CI-gated — drift only) | humans | low |
| `LEARNINGS/` live docs + `_index.md` mirrors | ticketing-skill §-anchors settled | auto-injected manifest every session | med |
| `tests/*.bats` literals | disk + doc + config state final | release CI | med |

## Implementation Phases

### Phase 1: Audit (read-only detector passes — skill-generalizer framework)

- [x] **1.1** Run the five detector passes (named-entity/platform, anecdote→rule, domain-modularization, constants, path/reference) over the six source SKILL.md files and record the per-section disposition table into this PLAN's Technical Notes
    — **Why:** Phase 2 authors from dispositions, not re-derivation; every source line gets exactly one disposition (method→main doc, platform values→side file, policy→canonical home, dead→delete)
    — **Done when:** Technical Notes carries a table covering all six skills' sections with zero "undecided" rows
    — **Consumers affected:** Phase 2 authoring steps
    — **Done:** Disposition table written into Technical Notes covering all six skills; zero undecided rows
- [x] **1.2** Extract byte-exact §MCP Availability Guard (from jira-git-integration) and §Attribution (from ticket-creation) bodies plus the consolidated trigger-phrase inventory into Technical Notes
    — **Why:** AC2 requires verbatim headings/bodies; pinning them pre-authoring prevents drift during the merge
    — **Done when:** Technical Notes contains both verbatim blocks and the trigger inventory (incl. the two skills that had no trigger lists)
    — **Consumers affected:** step 2.4
    — **Done:** Verbatim §MCP Availability Guard + §Attribution bodies and trigger inventory pinned in Technical Notes

### Phase 2: Author `skills/ticketing-skill/` + CI-green atomic swap (ONE commit)

_All of 2.1–2.10 lands in a single commit so release.yml (build-registry --check + full bats per push) stays green at that SHA._

- [x] **2.1** `mkdir -p skills/ticketing-skill/references`; `git mv skills/ticket-creation-skill/templates skills/ticketing-skill/templates`
    — **Why:** git mv preserves template history and lands the byte-identical files the byte-identity test pins, before the source dir is removed
    — **Done when:** `git status` shows renamed `templates/*.yml` under `skills/ticketing-skill/`
    — **Consumers affected:** byte-identity test, opencode-repo-setup template-copy offer
    — **Done:** git mv templates → skills/ticketing-skill/templates (3 renames detected); references/ dir created
- [x] **2.2** Write `skills/ticketing-skill/references/github.md` — gh values + LABELS vocabulary (GitHub defaults, priority, semver PR-only), issue key format, 3-tier tooling fallback with per-operation capability matrix (gh → prompt-install via gh-cli-setup-skill → git-only tier: create=paste-ready body+web URL, label/comment=skip+note, close=`Closes #N` keyword, plumbing=full), skeleton per side-file contract
    — **Why:** AC4 GitHub half; platform values live in the side file, never the main doc
    — **Done when:** file exists with fixed skeleton, citations/verify-locally notes on values, no method content
    — **Consumers affected:** SKILL.md load rule; gh-cli-setup reciprocal pointer (3.4)
    — **Done:** references/github.md written: 3-tier fallback + tier-3 capability matrix, LABELS array, keywords, semver rule, key format, templates contract
- [x] **2.3** Write `skills/ticketing-skill/references/jira.md` — atlassian_* MCP tools + REST fallback endpoints (`/rest/api/3/...`), type/priority/component vocabularies, idempotent transition contract, `PROJ-123` key regex, skeleton per side-file contract
    — **Why:** AC4 JIRA half; REST fallback carries the MCP-guard policy
    — **Done when:** file exists with skeleton, vocab with verify-locally leads, transition idempotency rule, no method content
    — **Consumers affected:** SKILL.md load rule; policy pointers retargeted in 3.4
    — **Done:** references/jira.md written: MCP discovery, REST endpoint table, type/priority vocab, transitions, key format, description templates
- [x] **2.4** Write `skills/ticketing-skill/SKILL.md` — frontmatter (name, ≤50-word trigger-preserving description with negative scope, Apache-2.0, compatibility opencode, category Git/Workflow, metadata per house contract); §Platform Detection gate (explicit → repo signals → ask); §Lifecycle routing (create / classify-label / update / close / git-plumbing); §MCP Availability Guard (canonical home, verbatim from 1.2); §Attribution (verbatim from 1.2); semver rule "PRs get exactly one semver label; issues get type + priority"; side-file load rules
    — **Why:** the method body; AC1+AC2+AC3 land here
    — **Done when:** AC1–AC3 SKILL.md clauses checkable true; metadata values double-quoted comma-separated strings; description ≤50 words
    — **Consumers affected:** all Phase 3/5 consumers
    — **Done:** SKILL.md written: 31-word description, §Platform Detection, §Lifecycle (5 ops), §MCP Availability Guard + §Attribution verbatim, boundaries; files: skills/ticketing-skill/SKILL.md; fixes: none
- [x] **2.5** Write `skills/ticketing-skill/README.md` with the Mermaid workflow diagram (platform gate → lifecycle ops → side-file loads; github branch shows 3 tooling tiers; jira branch shows MCP/REST)
    — **Why:** human-facing map; diagram must mirror SKILL.md routing exactly
    — **Done when:** fenced ```mermaid flowchart covers both platforms, both lifecycle dimensions, 3-tier fallback
    — **Consumers affected:** none (inert to installer/registry/tests)
    — **Done:** README.md written with mermaid flowchart (both platforms, both routing dimensions, 3-tier + MCP/REST fallback)
- [x] **2.6** Sweep `opencode_app/opencode.json`: the six allow rules (`:130,:195,:200,:205,:210,:215`) → one `ticketing-skill` allow; retarget the `/create-ticket` command template (`:665`) to load `ticketing-skill`
    — **Why:** full-profile single source (deploy/skill-profiles.json `_comment`); unswept, skill_profiles.bats :54 (lean ⊆ app allows) AND :63 (dead-allow guard) both fail — Mode R strengthening
    — **Done when:** zero old names in the file; `node -e JSON.parse` validates; both gating tests green at this SHA
    — **Consumers affected:** Docker app runtime, tests/skill_profiles.bats
    — **Done:** opencode_app/opencode.json: 6 allow rules → 1 ticketing-skill allow (:130 block), 5-rule block removed, /create-ticket template retargeted; JSON valid; 0 old names
- [x] **2.7** Installer sync: `node installer/build-registry.mjs` (regenerate); `installer/presets/pack-devops.json` six entries → `ticketing-skill`; `deploy/skill-profiles.json` lean: `ticket-creation-skill` → `ticketing-skill` (1:1, lean count stays 78)
    — **Why:** `--check` runs per push — registry must match disk in THIS commit; presets/profiles would pull dead dirs otherwise
    — **Done when:** `build-registry.mjs --check` exits 0; both JSONs reference only existing dirs
    — **Consumers affected:** installer/init.mjs, tests/init.bats, tests/skill_profiles.bats
    — **Done:** registry rebuilt (agents=34, skills=150, --check PASS); pack-devops 6→1; skill-profiles lean 1:1 swap (count 78); fixes: preset alphabetical placement
- [x] **2.8** Docs counts (disk + delta): README Git/Workflow row 16→**14** (row holds only ticket-creation/git-issue-labeler/git-issue-updater of the six), JIRA (3) row removed, tree-comment + hand-maintained counts + running totals **155→150**; migration note naming the six old names with `npx add ticketing-skill` replacement; `opencode_app/README.md` count literal same delta
    — **Why:** test_markitdown cross-file count is per-push; LEARNINGS new-skill-count-literal-gates — derive from disk, never stale doc numbers (review caught 16→11 as wrong-base arithmetic)
    — **Done when:** README counts equal `ls skills/ | wc -l` at HEAD; migration note present
    — **Consumers affected:** tests/test_markitdown_skill.bats, humans
    — **Done:** README 155→150 ×6 sites, Git/Workflow 16→14 with ticketing-skill, JIRA (3) row removed, history line + migration note (#599 names + replacement); opencode_app/README 155→150
- [x] **2.9** `tests/test_issue_template_byte_identity.bats`: TEMPLATES_DIR/SKILL_MD → `skills/ticketing-skill/`
    — **Why:** AC7 first half; the pinned cmp must target the moved dir in this commit or the push is red
    — **Done when:** `bats tests/test_issue_template_byte_identity.bats` passes at this tree
    — **Consumers affected:** release CI
    — **Done:** tests/test_issue_template_byte_identity.bats paths swapped; 3/3 pass standalone
- [x] **2.10** `git rm -r` the six old dirs; single commit `refactor(skills): consolidate six ticket skills into ticketing-skill` (renames + new files + removals + 2.6–2.9 + Phase 1 PLAN edits)
    — **Why:** AC1 same-commit replacement; every per-push gate green at this SHA (registry --check, skill_profiles :54/:63, markitdown count, byte-identity, count_drift, init)
    — **Done when:** commit lands; `bats tests/skill_profiles.bats tests/test_issue_template_byte_identity.bats tests/test_markitdown_skill.bats tests/test_count_drift.bats tests/init.bats` all green at this SHA
    — **Consumers affected:** all downstream consumers
    — **Done:** Six dirs git rm-ed; single commit landed; gate green (registry --check + 5 suites = 71/71 ok, 0 not-ok)

### Phase 3: Reference sweep (agents + 12 consumer skills)

- [x] **3.1** `agents/repo-ops-specialist-subagent.md`: 6 skill-allow rules (`:59-74`) → one `ticketing-skill` allow (gh-cli-setup already at `:53`); prose `:166` policy pointer
    — **Why:** frontmatter skill-allows are the dependency-map primary source; stale names = silently un-loadable skill
    — **Done when:** zero old names in file; prose cites ticketing-skill §MCP Availability Guard
    — **Consumers affected:** deploy/setup.sh agent copy, runtime delegation
    — **Done:** repo-ops: 6 contiguous allow rules → 1 ticketing-skill; 6-line toolbox prose → 1 line; :166 policy pointer retargeted
- [x] **3.2** `agents/pr-workflow-subagent.md`: allow rule `:57` → `ticketing-skill`; prose `:121-123` (§Attribution + policy + delegation contracts)
    — **Why:** same runtime-allow requirement; AC2 anchors must be cited by their new home
    — **Done when:** zero old names; §-citations resolve inside ticketing-skill
    — **Consumers affected:** PR flow delegation
    — **Done:** pr-workflow: allow :57 → ticketing-skill; :121-123 JIRA block retargeted (guard, §Attribution, delegation contract)
- [x] **3.3** Prose pointers in `requirements-specialist` (`:110,:244`), `technical-design-specialist` (`:108`), `discovery-specialist` (`:109`)
    — **Why:** dead references misroute readers
    — **Done when:** `grep -rn` old names across `agents/` returns nothing
    — **Consumers affected:** doc readers
    — **Done:** requirements (:110,:244), technical-design (:108), discovery (:109) prose pointers renamed; agents/ grep clean
- [x] **3.4** Consumer sweep (12 skills): plan-execution (`:35,:135,:181`), plan-execution-inline (`:34`), pr-creation (`:27,:29`), pr-merge (`:198`), wayfinder (`:35,:133`), worktree-pipeline (`:20,:69,:109,:112`), dev-uat-promotion (`:29,:54`), mermaid-diagram-creator (`:91,:336`), semantic-release-convention (`:48`), opencode-repo-setup (`:65,:176,:195`), gh-cli-setup (`:17`), **grilling (`:144`)** — each a ticketing-skill §-pointer; run `build-registry.mjs`, include any diff; commit `refactor(agents,skills): point ticket consumers at ticketing-skill`
    — **Why:** AC5; grilling was the review-caught 12th consumer; registry re-check because agent/frontmatter-adjacent files changed in this commit
    — **Done when:** repo-wide old-name grep hits only the Phase 5 adjudicated buckets (LEARNINGS/CHANGELOG/PLANS)
    — **Consumers affected:** every downstream flow loading these by name
    — **Done:** 16 consumer files swept (12 skills incl. grilling:144 + 3 short-name stragglers + gh-cli anchor fix §Prerequisites→§Platform Detection); registry rebuilt clean; grep = only README migration note

### Phase 4: Deploy comment literals

- [ ] **4.1** `deploy/setup.sh` + `deploy/setup.ps1`: profile comment literals ("N primary-visible skills" / "N-allow allowlist" prose above profile functions — search anchors, not line numbers); commit `docs(deploy): sync setup comment literals for ticketing-skill`
    — **Why:** AC6 deploy half; functional counts auto-derive, comments drift
    — **Done when:** comment literals match recomputed numbers (derive from disk + delta)
    — **Consumers affected:** humans

### Phase 5: LEARNINGS adjudication + verification gates

- [ ] **5.1** LEARNINGS update bucket per Mode R: `decisions/mcp-guard-single-homed.md` (canonical home → ticketing-skill, evidence-add), `conventions/blocked-by-format-single-home.md:14` (producer → ticketing-skill), `conventions/policy-single-home-pointer-shape.md:3` (context note: home moved in #599), `conventions/section-pins-target-heading-anchors.md:10` (**live pins retargeted** to ticketing-skill — manifest is auto-injected, stale pins misroute), `_index.md` mirrors `:252,:258,:741,:1002`; commit `chore(learnings): retarget ticket-skill pins to ticketing-skill`
    — **Why:** AC8 update bucket; live convention docs become factually wrong at merge otherwise
    — **Done when:** update-bucket files contain zero old names (except explicitly marked historical narrative)
    — **Consumers affected:** every future session's auto-injected manifest
- [ ] **5.2** Full gate: entire `bats tests/` suite in the worktree; fix any red
    — **Why:** verification-loop contract — ticket exit gate is full-tier
    — **Done when:** `bats tests/` exits 0
    — **Consumers affected:** release CI, PR gate citation
- [ ] **5.3** AC8 adjudicated sweep: old-name grep repo-wide → zero hits outside the grandfather list (CHANGELOG.md:645; PLANS/PLAN-{512,560,595}.md; rule-added-example-stale:8; gh-issue-edit-body-replaces-not-appends.md:23; `_index.md`:894); tick checkboxes ride this commit; final commit `test(tickets): adjudicate AC8 sweep for ticketing-skill consolidation`
    — **Why:** the acceptance gate with a pre-adjudicated disposition so it cannot stall
    — **Done when:** grep clean per buckets; all ACs checked; gate memo `tier=full` recorded with final SHA
    — **Consumers affected:** PR Step 10a citation

## Technical Notes

### Phase 1 outputs (filled 1.1/1.2)

**Disposition table** — every source section → exactly one destination (main=SKILL.md method · github/jira=side-file values · delete):

| Source section | Destination |
|---|---|
| ticket-creation: Step 1 platform detect | main §Platform Detection (explicit > repo signals > ask; atlassian-absent rule kept) |
| ticket-creation: intake stages 1–5, behavior rules, harness binding, ticket-vs-plan boundary, Step 4b sequence handoff, blocked-by recording | main §Create |
| ticket-creation: bug/feature field tables + rendering schemas + Jira description mapping | main §Create (schema); Jira renderings → jira.md |
| ticket-creation: gh commands; atlassian commands + project select | github.md §Create; jira.md §Create |
| ticket-creation: §MCP Availability Guard (was a pointer) | superseded by main canonical home (verbatim body below) |
| ticket-creation: §Attribution | main §Attribution VERBATIM |
| ticket-creation: examples, platform comparison, checklists | delete (README diagram + routing cover them) |
| git-issue-labeler: "PRs get exactly one semver label; issues type+priority"; assignment caps; semantic-judgment caveat | main §Classify / Label |
| git-issue-labeler: LABELS array + taxonomy + auto-create loop + keyword lists | github.md §Labels |
| git-issue-labeler: semver structural regex; governance pointer | github.md §Semver (governance cite to semantic-release-convention-skill preserved) |
| git-issue-updater: commit→comment workflow, house comment template, idempotency, ref-detection ORDER | main §Update |
| git-issue-updater: per-platform endpoints/regexes | github.md §Update; jira.md §Comment |
| jira-git-integration: §MCP Availability Guard | main §MCP Availability Guard VERBATIM (canonical home moves here) |
| jira-git-integration: discovery workflow (resources→user→projects→create) | jira.md §MCP Tools |
| jira-git-integration: branch naming + commit footers (general rule) | main §Git Plumbing (ABC-123 specifics → jira.md) |
| jira-status-updater: exactly-once contract, merge comment template, key-detection-from-PR | main §Close |
| jira-status-updater: transition pick priority + REST transitions endpoint | jira.md §Transitions |
| jira-ticket-labeler: type/priority keyword tables, GitHub→JIRA mapping, components, Bug-vs-Task heuristics | jira.md §Vocabulary |
| jira-ticket-labeler: "Why separate from git-issue-labeler", taxonomy comparison, MCP guard paragraph | delete (one skill now; main guard covers) |
| both labelers: sync contract | note in both side files ("kept in sync within this skill") |

**Verbatim §MCP Availability Guard** (from jira-git-integration:17–26 — the canonical body): "The `atlassian` MCP server is **disabled by default** (opt-in). Before any `atlassian_*` call, check whether the tools exist in your tool list: If `atlassian_*` tools are absent, do NOT attempt or hallucinate them. · Interactive: offer per-project enable via `opencode-repo-setup-skill` (writes the FULL atlassian server entry into the project `opencode.json` — a bare `{"disabled":false}` stub is inert; effective next session, so this session must degrade). · Fallback: REST with an API token — `curl -u email:token` against `https://<site>.atlassian.net` (discover cloudId unauthenticated: `curl https://<site>.atlassian.net/_edge/tenant_info`); scoped tokens use `api.atlassian.com/ex/jira/{cloudId}`, unscoped use site-direct `/rest/api/3/`. · No credentials/headless: report the JIRA operation as skipped — never block the calling workflow."

**Verbatim §Attribution** (from ticket-creation:181–188): GitHub — issue author is the `gh auth` user by construction (token owner — GitHub does not allow spoofing); `--assignee @me` self-assigns the same identity; `git config user.name`/`user.email` are NOT valid assignee sources. JIRA reporter — defaults to the account behind the MCP token / REST credentials. JIRA assignee — must be set explicitly by `accountId`: REST `GET /rest/api/3/myself` → `.accountId` (MCP v2: `atlassianUserInfo`/`lookupJiraAccountId`); REST `PUT /rest/api/3/issue/{key}/assignee` `{"accountId":"<id>"}` — the only guaranteed path; `atlassian_createJiraIssue` (v1) assignee parameter unverified — re-inspect live; until then REST PUT or MCP v2 `editJiraIssue`.

**Trigger inventory (from 1.2):** create ticket · create issue · new issue · jira ticket · bug report · feature request · label issue · assess labels · assign labels · semver label PR · classify jira ticket · issue type · priority · update issue · close ticket · post-merge transition · jira branch · ticket key from branch. Plus absorbed keyword surfaces from jira-status-updater ("status transitions after pull requests are merged") and jira-ticket-labeler (type/priority/components).

**Draft description (AC3, 36 words):**
> Ticket lifecycle for GitHub Issues and JIRA — create, classify/label, update from commits, close (post-merge, idempotent), ticket-key↔branch plumbing. CRUD only: no branches, PLANs, execution. Triggers: any ticket/issue create·label·update·close, bug report, feature request.

**Semver boundary:** PRs get exactly one semver label (major/minor/patch) from the PR title's Conventional Commit prefix; issues get type + priority only. Tagging/version-bump belong to semantic-release-convention-skill + release tooling. Definitions follow semantic-release-convention-skill — cited, never redefined.

**Workflow skills stay external:** worktree-pipeline, wayfinder, dev-uat-promotion consume ticketing-skill; none of their method content is absorbed.

**Count arithmetic (corrected per review):** Git/Workflow row holds 3 of the six (ticket-creation, git-issue-labeler, git-issue-updater) → 16−3+1=**14**; JIRA (3) row removed; total skills 155−6+1=**150**; lean 78 unchanged (1:1 swap).

**Execution mode:** Pipeline Step 8 (execute) runs `plan-execution-inline-skill` (inline workers) per the invoking command's `-v2` suffix; per-phase commits follow this PLAN's commit boundaries (Phase 2 = one commit).

## Dependencies

- None blocked-by. Hard pipeline deps verified present: plan-execution(-inline)-skill, code-review-subagent, pr-workflow-subagent.

## Risks & Mitigation

- **Per-push CI reds from unsynced surfaces** — mitigated structurally: every sync surface (registry, lean, app config, README counts, byte-test path) rides the SAME commit as the disk change (Phase 2 single commit; registry re-check in 3.4).
- **Count-literal misses beyond listed tests** — mitigate: run the LEARNINGS verification greps (`-eq [0-9]` arithmetic, "skill director" matches, "primary-visible/allow" literals) before 5.2.
- **Trigger regression from description compression** — mitigate: phrase inventory pinned above; AC3 enforces ≤50 words + surface coverage.
- **Missed pointer / dangling §-anchor** — mitigate: AC8 adjudicated buckets make the final grep decidable; anchors preserved verbatim (AC2).
- **Breaking change for `npx add` users pinning old names** — mitigate: major release + migration note (2.8).
- **Byte-identity test path drift** — mitigate: git mv rename detection + 2.9 standalone run inside the Phase 2 commit.

## Gate Trace

```
GATE ffc7b14 tier=full lint=n.a typecheck=n.a build=n.a unit=71/71(bats: skill_profiles, byte-identity, markitdown, count_drift, init) e2e=n.a — Phase 2 (critical-area anchors: installer registry + CI-gated count tests)
GATE acfbe53 tier=light lint=n.a typecheck=n.a build=n.a unit=13/13(bats: skill_isolation, skill_profiles) + build-registry --check PASS e2e=n.a — Phase 3 (scoped: frontmatter/body pointer sweep)
```
