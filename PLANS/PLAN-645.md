# PLAN: Fix skills-audit defects — skill-generalizer YAML, maintainer self-check, PR label guidance

**Branch**: feat/645
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/645
**Base**: main

## Acceptance Criteria

- [x] All 120 SKILL.md frontmatters parse under strict `yaml.safe_load` (frontmatter block extracted, not whole file)
- [x] The maintainer skill's §Validation snippet no longer false-positives on a clean library (extracts the `---`-delimited block before parsing)
- [x] `references/create.md` step 7 documents the working REST label fallback for the live-broken `gh pr edit --add-label`, keeping step numbering and all external § anchors intact
- [x] `node installer/build-registry.mjs --check` green; bats suite green where installed

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/skill-generalizer/SKILL.md` | — | installer registry (lenient parse today), any strict-YAML consumer | low |
| `skills/opencode-skills-maintainer-skill/SKILL.md` | — | future audit runs (deployed copies refresh on reinstall) | low |
| `skills/civiltekk-pr-workflow-skill/references/create.md` | side-file contract of its SKILL.md | `agents/pr-workflow-subagent.md` (§Steps citations), `skills/civiltekk-pr-workflow-skill/SKILL.md` (§Steps step 3), `skills/gh-cli-setup-skill/SKILL.md` (§Steps citation), future PR-create runs | med — external § anchors + step numbering MUST survive |

## Implementation Phases

### Phase 1: Fix the three audit defects

- [x] **1.1** Fold `skill-generalizer`'s `description:` into the `>-` block style (content unchanged, colon-safe), matching the other 119 skills
    — **Why:** Issue defect 1 — the plain scalar contains `origin: strip` (colon+space), the only strict-YAML parse failure in the library; folded style is the established house pattern.
    — **Done when:** strict frontmatter parse over all 120 SKILL.md files reports zero failures.
    — **Consumers affected:** registry builder (already lenient — no behavior change); strict external consumers (now work).
    — **Done:** description folded to `>-` with a live assert that the parsed string is byte-identical (registry.json cannot drift); files: skills/skill-generalizer/SKILL.md; fixes: none
- [x] **1.2** Fix the maintainer skill's §Validation snippet to extract the `---`-delimited frontmatter block before `yaml.safe_load` (one fenced code block replacement; same check semantics otherwise)
    — **Why:** Issue defect 2 — the current snippet parses frontmatter + markdown body as one YAML document, reporting 120/120 false "bad-YAML" on a clean library; an audit step that always fires is worse than none.
    — **Done when:** the snippet, run as written in a clean checkout, reports zero bad-YAML lines for all 120 skills.
    — **Consumers affected:** future audit runs (deployed copies refresh on reinstall).
    — **Done:** §Validation python line now extracts the `---`-delimited block before yaml.safe_load; the fixed snippet was executed verbatim in the Phase 1 gate over all 120 skills — zero bad-YAML lines; files: skills/opencode-skills-maintainer-skill/SKILL.md; fixes: none
- [x] **1.3** In `references/create.md` step 7, keep `gh pr edit --add-label` as first attempt and document the REST fallback (`gh api -X POST repos/<owner>/<repo>/issues/<n>/labels -f 'labels[]=<label>'`) for the Projects-classic GraphQL breakage; step numbering and heading anchors unchanged
    — **Why:** Issue defect 3 — the documented command is live-broken (observed 2026-09-29); external § anchor consumers (pr-workflow-subagent, gh-cli-setup-skill, own SKILL.md) cite this file's steps, so the fix must be additive inside step 7, not a renumber.
    — **Done when:** step 7 shows attempt-then-fallback; `grep -c '§Steps'` citations still resolve; steps still numbered 1–8.
    — **Consumers affected:** pr-workflow runs (working labels again); anchor consumers (unbroken by construction).
    — **Done:** step 7 keeps `gh pr edit` as first attempt + documents the REST `gh api` fallback with the observed 2026-09-29 error signature; step count verified 8, external §Steps citations unchanged; files: skills/civiltekk-pr-workflow-skill/references/create.md; fixes: none

### Phase 2: Ticket exit gate (full)

- [x] **2.1** Run the full gate on the final tree: strict-YAML validation over all skills (proves 1.1 + 1.2 together), `node installer/build-registry.mjs --check`, bats suite if `bats` is installed (else record the substitute evidence: strict-YAML + registry checks); lint/typecheck n.a (no toolchain configured for this docs+shell repo — recorded, not silently skipped)
    — **Why:** Issue AC — registry green + strict parse green + tests-where-runnable is the strongest verification this repo's manifests expose.
    — **Done when:** all applicable checks green; `GATE <sha> tier=full` memo line recorded in the PLAN trace block.
    — **Consumers affected:** Step 10a PR creation (cites this memo line).
    — **Done:** full gate green on final tree (strict-YAML 120/120, registry no drift, bats suite exit 0); lint/typecheck recorded n.a — no toolchain configured in manifests (docs+shell repo); anchor grep: all 5 external citation sites resolve; files: PLANS/PLAN-645.md; fixes: none

## Technical Notes

- Verification commands discovered from manifests: package.json scripts = none; no Makefile/pyproject; the repo's structural checks are `installer/build-registry.mjs --check` (registry) and `tests/*.bats` (bats runner — availability to be probed at gate time; CI has no test/lint workflow, only release + conflict-labeler).
- Fix shapes were specified in the issue References section; all three are additive/in-place edits — no renumbering, no anchor renames.
- The deployed copies at `~/.config/opencode/skills/` refresh on reinstall; fixing the source repo is the ticket's scope.

## Dependencies

- None. Audit source: skills-repo review 2026-09-29 (issue body carries full evidence).

## Risks & Mitigation

- **Anchor drift in create.md**: additive-only edit inside step 7; gate greps the external citations still resolve.
- **Snippet fix changes the maintainer skill's own deployed behavior**: the corrected snippet is strictly stronger (frontmatter-only parse); no semantics lost.

## Gate Trace

- GATE 137353d tier=full lint=n.a typecheck=n.a build=t(registry --check, no drift) unit=t(strict-YAML 120/120 clean + bats suite green) e2e=n.a(no frontend) — Phase 1 exit, zero fixes
- GATE 3895c5b tier=full lint=n.a typecheck=n.a build=t(registry no drift) unit=t(strict-YAML 120/120 + bats green) e2e=n.a — TICKET EXIT GATE on final tree, zero fixes
