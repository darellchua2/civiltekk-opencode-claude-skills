# PLAN: Standardize ticket/PR attribution and label taxonomy seeding

**Branch**: feat/404
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/404
**Base**: main

## Acceptance Criteria

- [ ] AC1 — `pr-creation-workflow-skill`: `gh pr create` includes `--assignee @me`; one line noting author = `gh auth` user by construction.
- [ ] AC2 — `ticket-creation-skill`: Attribution block in Step 4 — GitHub author/assignee resolve to the `gh auth` user; JIRA self-assignment fetches own `accountId` (`GET /rest/api/3/myself`) and passes it to the create call, with `PUT /rest/api/3/issue/{key}/assignee` as the guaranteed fallback.
- [ ] AC3 — `git-issue-labeler-skill`: Step 1 auto-seed (`gh label list` existence check → `gh label create` for missing) documented as intended behavior — fixed taxonomy = consistent baseline across repos; custom repo labels coexist, no migration needed.
- [ ] AC4 — New minimal `gh-cli-setup-skill`: per-OS install + `gh auth login`; `ticket-creation-skill` and `pr-creation-workflow-skill` reference it when `command -v gh` fails, then continue instead of erroring.
- [ ] AC5 — `agents/pr-workflow-subagent.md`: attribution bullet under JIRA Integration (self-assign via accountId; PR assignee `@me`).
- [ ] AC6 — No frontmatter shape changes to existing files; the NEW skill is registered everywhere a new skill requires: `deploy/skill-profiles.json` lean array, `opencode_app/opencode.json` skill allowlist (full profile), `installer/registry.json` rebuild, README count (149 → 150) + Git/Workflow row (15 → 16).

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/gh-cli-setup-skill/SKILL.md` | — | ticket-creation-skill §Prerequisites (fallback ref), pr-creation-workflow-skill (fallback ref), `installer/registry.json`, `deploy/skill-profiles.json`, `opencode_app/opencode.json`, README | med |
| `skills/ticket-creation-skill/SKILL.md` | gh-cli-setup-skill exists (wired ref, 2.1 before 2.2) | primary agent (`/create-ticket`), pr-workflow-subagent, README Git/Workflow listing | low |
| `skills/pr-creation-workflow-skill/SKILL.md` | gh-cli-setup-skill exists (wired ref) | pr-workflow-subagent (execution engine), repo-ops-specialist-subagent | low |
| `skills/git-issue-labeler-skill/SKILL.md` | — | ticket-creation-skill Step 4 (delegation), semantic-release-convention-skill (semver governance), repo-ops-specialist-subagent | low |
| `agents/pr-workflow-subagent.md` | — | primary session (task delegate), README Subagents table (row unchanged — body-only edit) | low |
| `installer/registry.json` | ALL frontmatter finalized (after 2.1; no existing frontmatter edits anywhere) | CI registry-drift gate, `installer/init.mjs` (`npx add` installer) | med |
| `deploy/skill-profiles.json` | `skills/gh-cli-setup-skill/` on disk (bats guard: every lean key must match a dir) | `deploy/setup.sh --skill-profile`, `tests/skill_profiles.bats` | med |
| `opencode_app/opencode.json` | `skills/gh-cli-setup-skill/` on disk | Docker/pm2 runtime full skill profile | low |
| `README.md` | all skills landed | humans + `documentation-consistency-skill` audits | low |

Map constraints: 2.1 precedes 2.2, 3.1, 3.2, 3.4; 3.4 is the last registration step; Phase 4 runs after everything.

## Implementation Phases

### Phase 1: Attribution edits (body-only, no frontmatter)

- [ ] **1.1** In `skills/pr-creation-workflow-skill/SKILL.md` step 6, change the `gh pr create` instruction to include `--assignee @me` and append one line noting the PR author is the `gh auth` user by construction (token owner; GitHub does not allow spoofing).
    — **Why:** AC1 — PRs currently create with no assignee; this is the only attribution gap on the GitHub side.
    — **Done when:** step 6 text contains `--assignee @me` and the author note; no frontmatter line touched.
    — **Consumers affected:** pr-workflow-subagent (inherits the engine behavior).
- [ ] **1.2** In `skills/ticket-creation-skill/SKILL.md`, add an "Attribution" block in Step 4: GitHub — author/assignee resolve to the `gh auth` user via the existing `--assignee @me`; JIRA — reporter defaults to the MCP/REST token account (automatic), assignee set explicitly by `accountId` fetched via `GET /rest/api/3/myself`, passed to the create call with `PUT /rest/api/3/issue/{key}/assignee` documented as the guaranteed fallback; note `atlassian_createJiraIssue` assignee-parameter support is unverified; state that `git config user.name`/`user.email` are not valid assignee sources.
    — **Why:** AC2 — JIRA tickets currently create unassigned; the accountId mechanics must be written where the create calls live.
    — **Done when:** Step 4 has the Attribution block covering GitHub + JIRA + git-config exclusion; no frontmatter touched.
    — **Consumers affected:** pr-workflow-subagent JIRA flow, primary `/create-ticket` flow.
- [ ] **1.3** In `skills/git-issue-labeler-skill/SKILL.md` (§Step 1 or §Best Practices), add a short note declaring the auto-seed behavior intended: the fixed 16-label taxonomy is the consistent baseline seeded into any repo via `gh label list` + `gh label create`; existing custom repo labels coexist — no migration, no conflict handling required.
    — **Why:** AC3 — the behavior already exists in code but reads accidental; documenting it as intended is the design decision from issue #404.
    — **Done when:** the note exists and states both the seeding rule and the coexistence rule; no frontmatter touched.
    — **Consumers affected:** ticket-creation-skill Step 4 delegation, repo-ops-specialist-subagent.
- [ ] **1.4** In `agents/pr-workflow-subagent.md` under "JIRA Integration", add one bullet: self-assign the linked ticket (accountId lookup per ticket-creation-skill §Attribution) and set the PR assignee to `@me` at creation.
    — **Why:** AC5 — the subagent's JIRA flow must mirror the skill-level attribution so delegation doesn't drop it.
    — **Done when:** the bullet exists in the JIRA Integration section; frontmatter unchanged (no registry rebuild needed for this file).
    — **Consumers affected:** primary session PR delegations.

### Phase 2: New gh-cli-setup-skill + wiring

- [ ] **2.1** Create `skills/gh-cli-setup-skill/SKILL.md` per the frontmatter contract: `name: gh-cli-setup-skill` (equals dir name), `description` ≤50 words with trigger phrases (gh not installed, gh auth login, github cli setup), `license: Apache-2.0`, `compatibility: opencode`, `category: Git/Workflow`. Body: verify with `command -v gh`; per-OS install (brew / apt / dnf / winget-choco); `gh auth login` (device flow default); verify `gh auth status`; exit guidance if token lacks `repo` scope.
    — **Why:** AC4 — there is no gh fallback in the config (verified 2026-09-18), so the missing-gh path in ticket/PR skills has nothing to trigger.
    — **Done when:** file exists on disk with contract-conformant frontmatter and the four body sections.
    — **Consumers affected:** registry (3.4), lean profile (3.1), full profile (3.2), both wiring refs (2.2).
- [ ] **2.2** Wire the fallback: in `skills/ticket-creation-skill/SKILL.md` §Prerequisites (GitHub) and §Common Issues, and in `skills/pr-creation-workflow-skill/SKILL.md` step 6 area, add: if `command -v gh` fails, load `gh-cli-setup-skill`, then continue the flow instead of erroring out.
    — **Why:** AC4 — the reference is the actual behavior change; without it the new skill is dead weight.
    — **Done when:** both files reference `gh-cli-setup-skill` behind a `command -v gh` failure condition.
    — **Consumers affected:** primary `/create-ticket` and PR flows in gh-less environments.

### Phase 3: New-skill registration sync

- [ ] **3.1** Add `"gh-cli-setup-skill"` to the `lean` array in `deploy/skill-profiles.json` (alphabetical position, matching the existing list ordering).
    — **Why:** AC6 — new skills default hidden; lean membership is what makes it loadable in the lean profile, and `tests/skill_profiles.bats` requires lean keys to match disk.
    — **Done when:** the key is in the array and `bats tests/skill_profiles.bats` passes (or is noted as CI-covered if bats is absent locally).
    — **Consumers affected:** `deploy/setup.sh --skill-profile lean`, skill_profiles bats test.
- [ ] **3.2** Add `{"action": "skill", "resource": "gh-cli-setup-skill", "effect": "allow"}` to the allow block in `opencode_app/opencode.json` (after the deny-all rule, alongside the other per-skill allows; strict JSON — no comments).
    — **Why:** AC6 — the full skill profile's single source is this file's permissions array; omitting it hides the skill in the Docker runtime.
    — **Done when:** the allow entry exists, the file parses as strict JSON (`node -e "JSON.parse(...)"` or jq), and no comment syntax was introduced (JSONC anti-pattern).
    — **Consumers affected:** opencode_app Docker/pm2 runtime.
- [ ] **3.3** Update `README.md`: the running total count note (149 → 150 with a "Post-#404: +1 `gh-cli-setup-skill`" clause) and the Git/Workflow row (15 → 16, add `gh-cli-setup-skill` to the listing).
    — **Why:** AC6 — README is the human-facing count surface the documentation-consistency audits check.
    — **Done when:** both the total and the Git/Workflow row reflect the new skill.
    — **Consumers affected:** documentation-consistency-skill audits, readers.
- [ ] **3.4** Run `node installer/build-registry.mjs` and commit the regenerated `installer/registry.json`.
    — **Why:** AC6 — CI has a registry drift gate that fails when frontmatter on disk and `installer/registry.json` disagree; the new skill's frontmatter must be registered.
    — **Done when:** `git status` shows `installer/registry.json` modified with exactly one added skill entry and the build command exits 0.
    — **Consumers affected:** `installer/init.mjs` (`npx add`), CI drift gate.

### Phase 4: Verification gate

- [ ] **4.1** Run the aggregate gate: `node installer/build-registry.mjs` (drift check exits 0), `bats tests/skill_profiles.bats` (or note bats absent → CI-covered), and `git diff origin/main...feat/404 --stat` confirming zero frontmatter (`---` block) changes in the four edited pre-existing files.
    — **Why:** AC6 — this is the repo's lint+typecheck equivalent: registry drift, lean-key/disk sync, and the no-shape-change guarantee are all mechanical checks.
    — **Done when:** all three checks pass or have documented CI-covered fallbacks.
    — **Consumers affected:** CI (PR checks), future `npx add` consumers.

## Technical Notes

- Re-validated against `origin/main` @ `2cf3844` in the worktree: all 8 target paths exist; `skills/gh-cli-setup-skill/` absent (to be created); no PLAN/BRD/SRS drafts adoptable; no commits touched target files after ticket creation — no stale deltas.
- JIRA reporter defaults to the MCP/REST token account — automatic; assignee is the only explicit field needed. JIRA assigns by `accountId`, never display name or email.
- This repo's deploy scripts (`setup.sh`, `setup.ps1`) auto-derive skill counts from disk (BT-157) — no count edits needed there; ticket AC6's "count sync" reduces to README + registry + profiles.
- Labeler seeding is live behavior: `priority: medium` was seeded into this repo at ticket-creation time via the Step 1 loop.

## Dependencies

- None external. No blocked-by tickets.

## Risks & Mitigation

- **Registry drift breaks CI** → 3.4 rebuilds registry.json in the same PR as the frontmatter it reflects; 4.1 re-runs the drift check.
- **Lean-array/disk mismatch fails bats** → 3.1 adds the key only after 2.1 created the dir; ordering enforced by the map.
- **Strict-JSON violation in opencode.json** (JSONC anti-pattern) → 3.2's done-when includes a JSON.parse check.
- **Unverified `atlassian_createJiraIssue` assignee param** → documented as unverified with the REST PUT as the guaranteed path; no runtime dependency on the unverified parameter.
