# PLAN: Standardize ticket/PR attribution and label taxonomy seeding

**Branch**: feat/404
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/404
**Base**: main
**Revision**: 2 — post architecture review (reject→remediated) + Mode R relay round 1

## Acceptance Criteria

- [ ] AC1 — `pr-creation-workflow-skill`: `gh pr create` includes `--assignee @me`; one line noting author = `gh auth` user by construction.
- [ ] AC2 — `ticket-creation-skill`: Attribution block in Step 4 — GitHub author/assignee resolve to the `gh auth` user; JIRA self-assignment fetches own `accountId` (`GET /rest/api/3/myself`) and passes it to the create call, with `PUT /rest/api/3/issue/{key}/assignee` as the guaranteed fallback.
- [ ] AC3 — `git-issue-labeler-skill`: Step 1 auto-seed (`gh label list` existence check → `gh label create` for missing) documented as intended behavior — fixed taxonomy = consistent baseline across repos; custom repo labels coexist, no migration needed.
- [ ] AC4 — New minimal `gh-cli-setup-skill`: per-OS install + `gh auth login`; `ticket-creation-skill` and `pr-creation-workflow-skill` reference it when `command -v gh` fails, then continue instead of erroring.
- [ ] AC5 — `agents/pr-workflow-subagent.md`: attribution bullet under JIRA Integration (self-assign via accountId; PR assignee `@me`).
- [ ] AC6 — No frontmatter **shape** changes to existing files; the NEW skill is registered everywhere a new skill requires: `deploy/skill-profiles.json` lean array, `opencode_app/opencode.json` skill allowlist (full profile), `installer/registry.json` rebuild, README count (149 → 150) + Git/Workflow row (15 → 16).

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/gh-cli-setup-skill/SKILL.md` | — | ticket-creation-skill §Prerequisites (fallback ref), pr-creation-workflow-skill (fallback ref), `installer/registry.json`, `deploy/skill-profiles.json`, `opencode_app/opencode.json`, README, both agent allow rules (2.3) | med |
| `skills/ticket-creation-skill/SKILL.md` | gh-cli-setup-skill exists (wired ref, 2.1 before 2.2) | primary agent (`/create-ticket`), pr-workflow-subagent, repo-ops-specialist-subagent, README Git/Workflow listing | low |
| `skills/pr-creation-workflow-skill/SKILL.md` | gh-cli-setup-skill exists (wired ref) | pr-workflow-subagent (execution engine), repo-ops-specialist-subagent | low |
| `skills/git-issue-labeler-skill/SKILL.md` | — | ticket-creation-skill Step 4 (delegation), semantic-release-convention-skill (semver governance), repo-ops-specialist-subagent | low |
| `agents/pr-workflow-subagent.md` | gh-cli-setup-skill exists (2.3 allow rule → loadable) | primary session (task delegate), README Subagents table (row unchanged) | med (registry coupling: frontmatter value change feeds 3.4) |
| `agents/repo-ops-specialist-subagent.md` | gh-cli-setup-skill exists (2.3 allow rule → loadable) | primary session (task delegate) | med (registry coupling: frontmatter value change feeds 3.4) |
| `installer/registry.json` | ALL frontmatter finalized (2.1 new file; 2.3 value-only edits — no shape changes anywhere) | CI registry-drift gate (`build-registry.mjs --check` in release.yml), `installer/init.mjs` (`npx add` installer) | med |
| `deploy/skill-profiles.json` | `skills/gh-cli-setup-skill/` on disk; `opencode_app/opencode.json` allow entry (bats: lean ⊆ shipped allows) | `deploy/setup.sh --skill-profile`, `tests/skill_profiles.bats` (hardcoded lean-count literals: 47 → 48) | med |
| `tests/skill_profiles.bats` | lean-array edit (3.2) | CI bats suite (release.yml) | med |
| `opencode_app/opencode.json` | `skills/gh-cli-setup-skill/` on disk | Docker/pm2 runtime full skill profile; `tests/skill_profiles.bats` subset check | low |
| `README.md` | all skills landed | humans + `documentation-consistency-skill` audits; CI-gated literal at `README.md:15` (`test_markitdown_skill.bats`) | med |
| `opencode_app/README.md` | skill count on disk (2.1) | CI-gated literal at `:30` (`test_markitdown_skill.bats`) | med |

Map constraints: 2.1 precedes 2.2, 2.3, 3.1, 3.2, 3.4 · 3.1 (allow entry) precedes 3.2 (lean — the subset bats check requires the allow to exist first) · 3.4 is the last registration step · Phase 4 runs after everything.

## Implementation Phases

### Phase 1: Attribution edits (body-only, no frontmatter)

- [ ] **1.1** In `skills/pr-creation-workflow-skill/SKILL.md` step 6, change the `gh pr create` instruction to include `--assignee @me` and append one line noting the PR author is the `gh auth` user by construction (token owner; GitHub does not allow spoofing).
    — **Why:** AC1 — PRs currently create with no assignee; this is the only attribution gap on the GitHub side.
    — **Done when:** step 6 text contains `--assignee @me` and the author note; no frontmatter line touched.
    — **Consumers affected:** pr-workflow-subagent (inherits the engine behavior).
- [ ] **1.2** In `skills/ticket-creation-skill/SKILL.md`, add an "Attribution" block in Step 4: GitHub — author/assignee resolve to the `gh auth` user via the existing `--assignee @me`; JIRA — reporter defaults to the MCP/REST token account (automatic), assignee set explicitly by `accountId` fetched via `GET /rest/api/3/myself`, passed to the create call with `PUT /rest/api/3/issue/{key}/assignee` documented as the guaranteed fallback; state that `git config user.name`/`user.email` are not valid assignee sources. The `atlassian_createJiraIssue` assignee-parameter note must carry exactly ONE terminal label per Mode R resolution: **(a)** `verified present` — schema inspected (live if the server is enabled, else the pinned server's published docs; enabling a disabled MCP server just for this check is NOT permitted) and an assignee param exists → document MCP-direct as primary, REST PUT fallback; **(b)** `verified absent` — schema inspected, no param → REST PUT is the only path; **(c)** `unverified — server absent` — server disabled AND schema not statically inspectable → REST PUT as the only guaranteed path plus a one-line re-check trigger ("re-inspect when a project enables the atlassian MCP"). No bare "unverified" without an evidence trail.
    — **Why:** AC2 — JIRA tickets currently create unassigned; the accountId mechanics must be written where the create calls live, and the ticket's "check at implementation time" instruction must resolve to a terminal, evidence-backed state.
    — **Done when:** Step 4 has the Attribution block covering GitHub + JIRA + git-config exclusion, and the assignee-param note carries exactly one of labels (a)/(b)/(c) with its evidence basis stated.
    — **Consumers affected:** pr-workflow-subagent JIRA flow, primary `/create-ticket` flow.
- [ ] **1.3** In `skills/git-issue-labeler-skill/SKILL.md` (§Step 1 or §Best Practices), add a short note declaring the auto-seed behavior intended: the fixed 16-label taxonomy is the consistent baseline seeded into any repo via `gh label list` + `gh label create`; existing custom repo labels coexist — no migration, no conflict handling required.
    — **Why:** AC3 — the behavior already exists in code but reads accidental; documenting it as intended is the design decision from issue #404.
    — **Done when:** the note exists and states both the seeding rule and the coexistence rule; no frontmatter touched.
    — **Consumers affected:** ticket-creation-skill Step 4 delegation, repo-ops-specialist-subagent.
- [ ] **1.4** In `agents/pr-workflow-subagent.md` under "JIRA Integration", add one bullet: self-assign the linked ticket (accountId lookup per ticket-creation-skill §Attribution) and set the PR assignee to `@me` at creation.
    — **Why:** AC5 — the subagent's JIRA flow must mirror the skill-level attribution so delegation doesn't drop it.
    — **Done when:** the bullet exists in the JIRA Integration section; this step touches no frontmatter (the frontmatter value change lands in 2.3; registry rebuild in 3.4).
    — **Consumers affected:** primary session PR delegations.

### Phase 2: New gh-cli-setup-skill + wiring

- [ ] **2.1** Create `skills/gh-cli-setup-skill/SKILL.md` per the frontmatter contract: `name: gh-cli-setup-skill` (equals dir name), `description` ≤50 words with trigger phrases (gh not installed, gh auth login, github cli setup), `license: Apache-2.0`, `compatibility: opencode`, `category: Git/Workflow`. Body: verify with `command -v gh`; per-OS install (brew / apt / dnf / winget-choco); `gh auth login` (device flow default); verify `gh auth status`; exit guidance if token lacks `repo` scope.
    — **Why:** AC4 — there is no gh fallback in the config (verified 2026-09-18), so the missing-gh path in ticket/PR skills has nothing to trigger.
    — **Done when:** file exists on disk with contract-conformant frontmatter and the four body sections.
    — **Consumers affected:** registry (3.4), full profile (3.1), lean profile (3.2), agent allow rules (2.3), both wiring refs (2.2).
- [ ] **2.2** Wire the fallback: in `skills/ticket-creation-skill/SKILL.md` §Prerequisites (GitHub) and §Common Issues, and in `skills/pr-creation-workflow-skill/SKILL.md` step 6 area, add: if `command -v gh` fails, load `gh-cli-setup-skill`, then continue the flow instead of erroring out.
    — **Why:** AC4 — the reference is the actual behavior change; without it the new skill is dead weight.
    — **Done when:** both files reference `gh-cli-setup-skill` behind a `command -v gh` failure condition.
    — **Consumers affected:** primary `/create-ticket` and PR flows in gh-less environments.
- [ ] **2.3** Add one `{"action": "skill", "resource": "gh-cli-setup-skill", "effect": "allow"}` rule to the `permissions` skill-allow block of BOTH `agents/pr-workflow-subagent.md` AND `agents/repo-ops-specialist-subagent.md` — value-only addition to the existing arrays; no key added or removed (Mode R resolution: repo-ops is included because its own frontmatter allows both AC4-wired skills, so a repo-ops delegation in a gh-less environment hits the identical dead end).
    — **Why:** AC4's "then continue instead of erroring" must hold for delegated flows, not just primary — these two agents are the complete set of consumers of the wired skills (grep across `agents/*.md`).
    — **Done when:** both agent files contain the allow rule inside their existing `permissions` arrays; zero shape change (no keys added/removed, array order otherwise untouched).
    — **Consumers affected:** 3.4 registry rebuild (picks up the value deltas), delegated ticket/PR flows.

### Phase 3: New-skill registration sync

- [ ] **3.1** Add `{"action": "skill", "resource": "gh-cli-setup-skill", "effect": "allow"}` to the allow block in `opencode_app/opencode.json` (after the deny-all rule, alongside the other per-skill allows; strict JSON — no comments).
    — **Why:** AC6 — the full skill profile's single source is this file's permissions array; omitting it hides the skill in the Docker runtime. Also a hard prerequisite for 3.2: `tests/skill_profiles.bats` asserts lean ⊆ shipped allows.
    — **Done when:** the allow entry exists, the file parses as strict JSON (`node -e "JSON.parse(...)"`), and no comment syntax was introduced (JSONC anti-pattern).
    — **Consumers affected:** opencode_app Docker/pm2 runtime, 3.2's bats subset check.
- [ ] **3.2** Add `"gh-cli-setup-skill"` to the `lean` array in `deploy/skill-profiles.json`, AND bump every hardcoded lean-count literal in `tests/skill_profiles.bats` from 47 to 48 (header note ~line 5, "lean has exactly 47 keys" assertion, "exactly 47 allow rules" apply-skill-profile test, "47 deny-ok non-skill-ok" assertion).
    — **Why:** AC6 — lean membership makes the skill loadable in the lean profile (BLOCK-1: the bats count assertions are CI-enforced and no step owned them in revision 1); the key must match the dir on disk.
    — **Done when:** the key is in the array; `grep -c '47' ` on the four count-literal sites shows 48; `bats tests/skill_profiles.bats` passes (or is noted as CI-covered if bats is absent locally).
    — **Consumers affected:** `deploy/setup.sh --skill-profile lean`, skill_profiles bats test, apply-skill-profile.mjs derived counts.
- [ ] **3.3** Update the count surfaces: `README.md:15` CI-gated literal (`149 skill directories` → 150), `opencode_app/README.md:30` CI-gated literal (→ 150), the root README running-total note (Post-#404 clause) and Git/Workflow row (15 → 16, add `gh-cli-setup-skill`), plus the stale count sweep in root README (`:250`, `:566`, `:397` allow/lean counts → 106/47 and lean 48, `:409` — grep-verify each).
    — **Why:** AC6 — both READMEs carry literals compared against disk count by `tests/test_markitdown_skill.bats` (BLOCK-2: the Docker README literal had no owning step in revision 1); the remaining notes are the documentation-consistency audit surface.
    — **Done when:** `grep -rn '149 skill director' README.md opencode_app/README.md` exits 1 (no match); Git/Workflow row shows 16 and lists the skill; stale literals at the swept lines updated and consistent with disk.
    — **Consumers affected:** documentation-consistency-skill audits, test_markitdown_skill.bats CI check, readers.
- [ ] **3.4** Run `node installer/build-registry.mjs` and commit the regenerated `installer/registry.json` (picks up the new skill's frontmatter AND the 2.3 value-level agent deltas).
    — **Why:** AC6 — CI has a registry drift gate (`build-registry.mjs --check`) that fails when frontmatter on disk and `installer/registry.json` disagree.
    — **Done when:** `git status` shows `installer/registry.json` modified with exactly the new skill entry plus the two agent value deltas and the build command exits 0.
    — **Consumers affected:** `installer/init.mjs` (`npx add`), CI drift gate.

### Phase 4: Verification gate

- [ ] **4.1** Run the aggregate gate: `node installer/build-registry.mjs` (drift check exits 0), `bats tests/skill_profiles.bats` and `bats tests/test_markitdown_skill.bats` (or note bats absent → CI-covered), and a frontmatter **shape** check — for each of the five edited pre-existing files (`skills/pr-creation-workflow-skill/SKILL.md`, `skills/ticket-creation-skill/SKILL.md`, `skills/git-issue-labeler-skill/SKILL.md`, `agents/pr-workflow-subagent.md`, `agents/repo-ops-specialist-subagent.md`), compare the leading `---` block between `git show origin/main:<path>` and the working copy with `awk '/^---$/{c++} c<2'`; assert the only diffs are value-level allow-rule entries in the two agent files (1.x steps touch no frontmatter at all).
    — **Why:** AC6 — the no-shape-change guarantee is load-bearing; `git diff --stat` cannot prove hunk location (review WARN-3), so the leading-`---`-block comparison is the mechanical check. Registry drift + lean-key/disk sync + count literals are the repo's lint+typecheck equivalent.
    — **Done when:** all checks pass or have documented CI-covered fallbacks.
    — **Consumers affected:** CI (PR checks), future `npx add` consumers.

## Technical Notes

- Re-validated against `origin/main` @ `2cf3844` in the worktree: all 8 target paths exist; `skills/gh-cli-setup-skill/` absent (to be created); no PLAN/BRD/SRS drafts adoptable; no commits touched target files after ticket creation — no stale deltas.
- JIRA reporter defaults to the MCP/REST token account — automatic; assignee is the only explicit field needed. JIRA assigns by `accountId`, never display name or email.
- This repo's deploy scripts (`setup.sh`, `setup.ps1`) auto-derive skill counts from disk (BT-157) — no count edits needed there; ticket AC6's "count sync in setup.sh/setup.ps1" reduces to README + registry + profiles + bats literals.
- **AC6 interpretation (Mode R, binding):** "No frontmatter shape changes" forbids SHAPE (keys/structure) only — value-level allow-rule additions (2.3) are permitted and registry-covered. Ticket AC6's README/setup count-sync language is honored via 3.3 + the auto-derive note above.
- CI-gated count literals (verified in worktree): `tests/skill_profiles.bats` (four `47` sites), `README.md:15`, `opencode_app/README.md:30` — all owned by steps 3.2/3.3 in this revision.
- Labeler seeding is live behavior: `priority: medium` was seeded into this repo at ticket-creation time via the Step 1 loop.

## Dependencies

- None external. No blocked-by tickets.

## Risks & Mitigation

- **Registry drift breaks CI** → 3.4 rebuilds registry.json in the same PR as the frontmatter it reflects (including 2.3 value deltas); 4.1 re-runs the drift check.
- **Lean-array/disk or lean/allow mismatch fails bats** → 3.1 (allow) precedes 3.2 (lean) per the map constraint; 3.2 bumps the count literals in the same step that adds the key.
- **Strict-JSON violation in opencode.json** (JSONC anti-pattern) → 3.1's done-when includes a JSON.parse check.
- **Unverified `atlassian_createJiraIssue` assignee param** → 1.2's three-terminal-label done-when forces an evidence-backed state (a/b/c); no runtime dependency on the unverified parameter; REST PUT always documented.
- **Mode R override risk** — repo-ops-specialist allow rule was decided YES contrary to the reviewer's recommendation, on file evidence (agent allows both wired skills); if overruled back, repo-ops-delegated flows re-open the Gap-1 blocked check and must be re-flagged.
