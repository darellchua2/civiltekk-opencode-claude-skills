# PLAN: Deduplicate policy prose across ticket/issue skills

**Branch**: feat/434
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/434
**Base**: main

## Acceptance Criteria

- [x] AC1 — Attribution rule stated in exactly one skill; pr-creation points to it
- [x] AC2 — MCP guard policy text lives only in `jira-git-integration-skill`; the other 4 copies are pointer + endpoint line; existing `§MCP Availability Guard` pointers still resolve
- [x] AC3 — gh-cli fallback stated once in `ticket-creation-skill`, no inline auth commands
- [x] AC4 — `node installer/build-registry.mjs` exit 0, `--check` no drift, bats suite green
- [x] AC5 — No skill/agent count changes (bodies only — no adds/removes)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `skills/jira-git-integration-skill/SKILL.md` | — | `git-issue-updater-skill` (Related:34), `jira-status-updater-skill` (Related), `wayfinder-skill` + `worktree-pipeline-skill` (new direct pointers, 1.6), all 4 guard-pointer skills (1.2–1.5) | medium |
| `skills/ticket-creation-skill/SKILL.md` | jira-git-integration guard (1.1) | `wayfinder-skill:133`, `worktree-pipeline-skill:73` (re-pointed 1.6), internal self-refs `:50`/`:72-73`/`:192` (§MCP Availability Guard REST fallback), `agents/pr-workflow-subagent.md:122` (§Attribution pointer), `opencode-repo-setup-skill:60,140` | medium |
| `skills/pr-creation-workflow-skill/SKILL.md` | ticket-creation §Attribution (2.1) | `agents/pr-workflow-subagent.md`, `agents/repo-ops-specialist-subagent.md`, `skills/gh-cli-setup-skill:18` (pins "step 6" — no renumbering), `skills/semantic-release-convention-skill`, `skills/verification-loop-skill` | low |
| `skills/git-issue-updater-skill/SKILL.md` | jira-git-integration guard (1.1) | `jira-git-integration-skill:34` Related pointer | low |
| `skills/jira-status-updater-skill/SKILL.md` | jira-git-integration guard (1.1) | `jira-git-integration-skill:34` Related pointer | low |
| `skills/opencode-repo-setup-skill/SKILL.md` | jira-git-integration guard (1.1) | guard option-1 enable pointers (`git-issue-updater:21`, `jira-status-updater:22`, `ticket-creation` guard) | low |
| `skills/wayfinder-skill/SKILL.md` | jira-git-integration guard (1.1) | none (leaf consumer) | low |
| `skills/worktree-pipeline-skill/SKILL.md` | jira-git-integration guard (1.1) | none (leaf consumer) | low |
| `agents/repo-ops-specialist-subagent.md` | jira-git-integration guard (1.1) | none — 6th policy copy + a structural claim already false today (it asserts each listed skill carries its own guard; `jira-ticket-labeler` has none) | medium |
| `skills/agent-introspection-debugging-skill/SKILL.md` | jira-git-integration guard (1.1) | none (vague "follow the MCP Availability Guard" ref at `:78`, no § sigil — resolves via one hop) | low |

Cross-module consumers exist (agents + 4 non-target skills point into the edited nodes) → architecture review selected at pipeline Step 7. No frontend signal → uiux not selected.

Accepted agent-local restatements (review ruling, Mode R): `agents/pr-workflow-subagent.md:126` keeps its "MCP GUARD" application — it restates policy premises but adds PR-specific law ("Never fail the PR flow on a disabled server") that legitimately lives in the agent. `agents/pr-workflow-subagent.md:122` keeps its 8-word attribution gloss beside its §Attribution pointer (AC1 is skills/-scoped).

## Implementation Phases

### Phase 1: MCP Availability Guard — single policy home

- [x] **1.1** Rewrite `skills/jira-git-integration-skill/SKILL.md` §MCP Availability Guard as the canonical policy block: disabled-by-default status, absent-tools rule (never attempt/hallucinate), per-project enable via `opencode-repo-setup-skill`, REST-fallback pattern with cloudId discovery (`_edge/tenant_info`), headless degrade order
    — **Why:** its frontmatter already declares it "JIRA-Git plumbing shared by other JIRA skills"; a policy change must have exactly one edit point
    — **Done when:** the section carries the full policy incl. the cloudId discovery line and the scoped/unscoped token pair (scoped → `api.atlassian.com/ex/jira/{cloudId}`, unscoped → site-direct `/rest/api/3/`); the enable line names `opencode-repo-setup-skill` with the FULL server entry (no inert bare-stub `{"disabled":false}` JSON — the stub is `opencode-repo-setup-skill:83`'s documented inert-server trap); and `grep -rn '_edge/tenant_info' skills/` (excluding `_archived`) returns exactly this one file
    — **Consumers affected:** all five skills that currently restate the guard (1.2–1.5), wayfinder + worktree-pipeline (1.6)
    — **Done:** canonical policy home written (disabled-by-default, absent-tools rule, FULL-entry enable caveat, REST + cloudId discovery, scoped/unscoped pair); tenant_info grep single-hit confirmed; fixes: none

- [x] **1.2** `skills/git-issue-updater-skill/SKILL.md`: replace the guard body's policy bullets with one pointer line to `jira-git-integration-skill` §MCP Availability Guard + keep only the skill-specific REST comment endpoint (`POST .../issue/<KEY>/comment`); heading `## MCP Availability Guard (JIRA branch only)` stays verbatim
    — **Why:** AC2 — policy dedup while preserving the heading the AC freezes
    — **Done when:** policy bullets (absent-tools rule, enable offer, cloudId) are gone from this file; heading + endpoint line remain; the skill-specific degrade scope stays folded into the pointer line ("GitHub comments go through `gh` — always available; commit detection and GitHub updates unaffected")
    — **Consumers affected:** none beyond readers; `jira-git-integration-skill:34` Related pointer unchanged
    — **Done:** guard reduced to pointer + REST comment endpoint, heading verbatim; fixes: none

- [x] **1.3** `skills/jira-status-updater-skill/SKILL.md`: same reduction as 1.2, keeping its REST transition endpoint (`POST .../transitions`); heading `## MCP Availability Guard` stays verbatim
    — **Why:** AC2 — same policy, same dedup
    — **Done when:** policy bullets gone; heading + endpoint line remain; step 5's inline REST fallback note still coherent (it names the payload shape, not the guard); the unique observability clauses survive — "report the transition as skipped AND log the detected ticket key" and "never fail the PR-merge workflow" fold into the pointer line
    — **Consumers affected:** none beyond readers
    — **Done:** guard reduced to pointer + transitions endpoint, key-log/never-fail clauses folded; fixes: none

- [x] **1.4** `skills/ticket-creation-skill/SKILL.md`: reduce §MCP Availability Guard (JIRA steps) to the pointer + its REST fallback line; the three-option degrade ladder moves out (policy now lives at the home); internal reference at `:192` ("§MCP Availability Guard REST fallback") must still read true
    — **Why:** AC2 + the most-referenced copy (wayfinder/worktree-pipeline currently route policy through this file)
    — **Done when:** guard section is pointer + endpoint only; `:50`/`:72-73`/`:192` references all resolve; heading stays verbatim
    — **Consumers affected:** `wayfinder-skill:133`, `worktree-pipeline-skill:73` (re-pointed in 1.6), `pr-workflow-subagent` (§Attribution, untouched heading)
    — **Done:** guard reduced to pointer + REST line; :50/:52/:185 references verified coherent post-shrink; fixes: none

- [x] **1.5** `skills/opencode-repo-setup-skill/SKILL.md:158`: drop the restated REST/cloudId pattern; keep the unique token-creation URL (`id.atlassian.com/manage-profile/security/api-tokens`) and add the pointer to the guard home
    — **Why:** AC2's fifth copy — this one rewords rather than copies verbatim, the drift-prone variant
    — **Done when:** no `_edge/tenant_info` or `api.atlassian.com/ex/jira` restatement remains in the file; token URL + pointer remain
    — **Consumers affected:** guard option-1 enable flow readers
    — **Done:** REST/cloudId restatement dropped; token URL + pointer kept; fixes: none

- [x] **1.6** Re-point `skills/wayfinder-skill/SKILL.md:132-133` and `skills/worktree-pipeline-skill/SKILL.md:73` directly at `jira-git-integration-skill` §MCP Availability Guard (kill the pointer-to-pointer chain via ticket-creation)
    — **Why:** chained pointers rot; the policy home is now jira-git-integration, one hop only
    — **Done when:** both files name jira-git-integration-skill §MCP Availability Guard; wayfinder's own degrade-destination wording ("headless → degrade to GitHub/local-markdown") is preserved verbatim; `grep -rn 'ticket-creation-skill.*MCP Availability Guard' skills/` returns no policy-route hits
    — **Consumers affected:** none (leaf consumers)
    — **Done:** wayfinder + worktree-pipeline re-pointed at the guard home; policy-route grep clean; fixes: none

- [x] **1.7** `agents/repo-ops-specialist-subagent.md:166`: replace the full condensed policy restatement AND its structural claim ("each of those skills carries its own MCP Availability Guard" — already false today: it enumerates `jira-ticket-labeler`, which has no guard heading) with a single pointer to `jira-git-integration-skill` §MCP Availability Guard; pointer-only — no new policy text in the agent
    — **Why:** review BLOCK + Mode R ruling — the claim goes false (and is false now), and repo-ops is the agent future sessions load for repo setup; a stale map there silently defeats the dedup at its main propagation point
    — **Done when:** the file names jira-git-integration-skill §MCP Availability Guard; the "carries its own guard" claim is gone; no guard policy bullets (absent-rule, enable, REST/cloudId) remain in the agent body
    — **Consumers affected:** sessions that load repo-ops-specialist for MCP enable flows
    — **Done:** policy restatement + false structural claim replaced with pointer-only line at :166; fixes: none

### Phase 2: Attribution + semver governance pointers

- [x] **2.1** `skills/pr-creation-workflow-skill/SKILL.md` step 6: replace the restated attribution parenthetical ("token owner; GitHub does not allow spoofing…") with a pointer to `ticket-creation-skill` §Attribution; keep the `--assignee @me` mechanics and the gh-cli fallback sentence; do not renumber steps
    — **Why:** AC1 — the rule already lives in ticket-creation §Attribution; `gh-cli-setup-skill:18` pins "step 6" by number
    — **Done when:** `grep -n 'token owner' skills/pr-creation-workflow-skill/SKILL.md` returns nothing; step 6 keeps gh-fallback + `@me`
    — **Consumers affected:** `agents/pr-workflow-subagent.md` (already points at §Attribution — unchanged)
    — **Done:** attribution parenthetical replaced with ticket-creation-skill §Attribution pointer; @me + gh-cli fallback kept; step numbers untouched; fixes: none

- [x] **2.2** `skills/pr-creation-workflow-skill/SKILL.md` step 7: add the missing governance pointer to `semantic-release-convention` (mirror git-issue-labeler Step 3's "Governance: semantic-release-convention" wording)
    — **Why:** step 7 restates the semver mapping without naming its source of truth — third copy of the rule, ungoverned
    — **Done when:** step 7 names `semantic-release-convention` as governance; mapping text unchanged
    — **Consumers affected:** none
    — **Done:** step 7 gained Governance: semantic-release-convention (labeler wording mirrored); mapping text unchanged; fixes: none

### Phase 3: gh-cli fallback — single statement

- [x] **3.1** `skills/ticket-creation-skill/SKILL.md`: keep the §Prerequisites pointer sentence as the single statement; §Common Issues "GitHub CLI Missing or Not Authenticated" drops the duplicated explanation and the inline `gh auth login && gh auth status` block, keeping only the load-`gh-cli-setup-skill` pointer; subsection heading `### GitHub CLI Missing or Not Authenticated` stays verbatim (gh-cli-setup:17 pins §Common Issues); no other change to the Example Usage section (rule-added-example-stale sweep: confirm the example teaches no gh-auth inline flow)
    — **Why:** AC3 — `gh-cli-setup-skill` owns install/auth; two restatements in one file is the drift the ticket exists to remove. Mode R ruling on record: state checks (`gh auth status`) may remain; auth flows (`gh auth login`) may not
    — **Done when:** exactly one fallback statement in the file; `grep -n 'gh auth login' skills/ticket-creation-skill/SKILL.md` returns nothing (the `:296` checklist `gh auth status` intentionally survives — it is a state check); example section still coherent
    — **Consumers affected:** none (gh-cli-setup-skill:18 references pr-creation step 6, not this section)
    — **Done:** Common Issues section reduced to single gh-cli-setup-skill pointer (state check kept per Mode R); gh auth login grep clean; heading verbatim; fixes: none

### Phase 4: Gates + pointer audit + learning

- [x] **4.1** Pointer-resolution audit: `grep -rn '§MCP Availability Guard\|§Attribution' skills/ agents/` — every reference's target heading exists verbatim in the target file (heading-rename-syncs-quoted-pointers); plus `grep -rn '_edge/tenant_info' skills/` (excluding `_archived/`) returns exactly one hit (jira-git-integration); plus the §-sigil blind spot sweep — `grep -rn 'MCP Availability Guard' agents/ skills/` catches bare-name references (repo-ops:166 must be §-form after 1.7; `agent-introspection-debugging-skill:78`'s vague ref is accepted one-hop — Technical Notes names the home)
    — **Why:** AC2's "pointers still resolve" is checkable only by sweeping every quoted § pointer repo-wide; the §-less references evade a sigil-only grep (Mode R flagged)
    — **Done when:** audit prints zero broken references; single tenant_info hit confirmed; every bare-name guard reference is either §-form or explicitly accepted in Technical Notes
    — **Consumers affected:** all §-pointer consumers (verification only, no edits)
    — **Done:** 11 §-refs swept: all targets exist verbatim; tenant_info single-hit; bare-name hits are headings/self-refs/accepted (introspection:78, pr-workflow-subagent:122); fixes: none

- [x] **4.2** Registry gates: `node installer/build-registry.mjs` exit 0; `--check` reports no drift
    — **Why:** AC4 front half + AC5 — body-only edits must leave counts and registry untouched
    — **Done when:** both commands exit 0; registry diff empty
    — **Consumers affected:** installer/registry consumers (no-op expected)
    — **Done:** registry regen no-op (0 churn lines); --check exit 0; fixes: none

- [x] **4.3** Bats suite: run the full bats suite (locate via `ls installer/tests/*.bats tests/*.bats 2>/dev/null` or repo docs); all tests pass
    — **Why:** AC4 back half — count-drift and structure tests pin the surfaces this PLAN touches
    — **Done when:** suite green, zero failures
    — **Consumers affected:** none (verification only)
    — **Done:** full bats suite green; fixes: none

- [x] **4.4** Capture one LEARNINGS entry (decision: MCP Availability Guard single-homed at jira-git-integration-skill; per-skill copies are pointer + endpoint, heading frozen)
    — **Why:** memory-hygiene contract — one 2-line add per non-trivial decision
    — **Done when:** `LEARNINGS/decisions/` (or `conventions/`) file added, ≤2 lines of body
    — **Consumers affected:** future guard edits route to one file
    — **Done:** LEARNINGS/decisions/mcp-guard-single-homed.md added (2-line body); fixes: none

## Technical Notes

- From ticket #434: keep `## MCP Availability Guard` headings verbatim — three skills + one agent reference the section by name. No step renumbering in pr-creation-workflow-skill (gh-cli-setup pins "step 6").
- **Scope rulings (architecture review + Mode R, on record):** AC1 and AC2 are skills/-scoped — the "other 4 copies" arithmetic maps to steps 1.2–1.5; agents are consumers, so `pr-workflow-subagent.md:126` (agent-local guard application with PR-specific never-fail law) and `:122` (8-word attribution gloss beside its §Attribution pointer) are accepted restatements, not violations. AC5's "bodies only" means the count freeze (no skill/agent adds or removes) — it does NOT freeze agent bodies; step 1.7's agent-body edit is in-ticket.
- `agent-introspection-debugging-skill:78`'s vague "follow the MCP Availability Guard" (no § sigil) resolves to `jira-git-integration-skill` §MCP Availability Guard via one hop after 1.1 — accepted as-is.
- No skill/agent adds or removes → README/setup.sh/setup.ps1 count literals untouched by design (sync-rules table not triggered).
- `_archived/` skills are out of scope (unregistered, reference legacy names by design).
- Gate memo convention per `verification-loop-skill` §The gate contract — record `GATE <short-sha> …` in the trace block per phase.

## Dependencies

None — #404 and #409 are merged; base main @ 5274dff2 already contains both.

## Risks & Mitigations

- **Pointer strands** (a § reference whose target heading changed) — mitigated by 1.2–1.5 heading freeze + 4.1 repo-wide sweep.
- **Over-trim** (removing a genuinely unique detail with the policy copy) — mitigated by per-step "keep" lists (endpoint lines, token URL, `:192` self-ref) and review at Step 7/9.
- **Count drift false alarm** — mitigated by 4.2 registry `--check` before bats.
GATE b7adc49 lint=- typecheck=- build=- unit=t e2e=n.a.
GATE 0e19269 lint=- typecheck=- build=- unit=t e2e=n.a.
GATE b798738 lint=- typecheck=- build=- unit=t e2e=n.a.
GATE 37e5651 lint=- typecheck=- build=- unit=t e2e=n.a.
GATE 31527ed lint=- typecheck=- build=- unit=t e2e=n.a. (merged 9.13.0 base; full suite 351/351 incl. skill_isolation)
