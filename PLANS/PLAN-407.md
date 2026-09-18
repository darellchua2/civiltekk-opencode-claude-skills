# PLAN: Consolidate grill skills into one skill with modes

**Branch**: feat/407
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/407
**Base**: main

## Acceptance Criteria
- [ ] One grill skill directory remains (`skills/grilling-skill/`); directory name equals skill name (kebab-case)
- [ ] Trigger phrases `grill`, `grill me`, `grill with docs` all route to it with the correct mode; description ≤50 words preserving all trigger phrases
- [ ] `--docs` mode is self-contained: inlines the CONTEXT.md glossary convention and the ADR three-criteria gate (hard-to-reverse + surprising + real trade-off); `skills/grilling-skill/SKILL.md` contains zero references to `domain-modeling-skill` (scoped to this file only — step 2.1 and README legitimately keep theirs)
- [ ] `--plan` mode emits output that parses under the execution contract: `^### Phase`, `- [ ] **N.M**`, `- [x]` completion; rationale triple survives checkbox flips verbatim
- [ ] `skills/grill-me-skill/` and `skills/grill-with-docs-skill/` deleted; zero remaining references outside `_archived/` and `node_modules/`
- [ ] `registry.json` regenerated via `node installer/build-registry.mjs` and committed
- [ ] Sync surfaces updated: README counts (root **and** `opencode_app/README.md`) + category table, `deploy/skill-profiles.json`, `opencode_app/opencode.json`, `installer/presets/pack-business.json`, `tests/skill_profiles.bats` (pinned lean count 47 → 45, no backfill)
- [ ] `bats tests/` suite passes

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/grilling-skill/SKILL.md` | — | picker users; `agents/requirements-specialist-subagent.md` + `agents/discovery-specialist-subagent.md` (frontmatter skill allow); `installer/registry.json`; `deploy/skill-profiles.json`; `opencode_app/opencode.json`; `installer/presets/pack-business.json`; README | med |
| `skills/grill-me-skill/` (delete) | — | allowlists (`opencode_app/opencode.json`, `deploy/skill-profiles.json`), `installer/registry.json`, `installer/presets/pack-business.json`, README (root + opencode_app), `tests/skill_profiles.bats` (lean-count pin) | low |
| `skills/grill-with-docs-skill/` (delete) | grilling-skill (conceptual router) | `skills/domain-modeling-skill/SKILL.md` pairing text, allowlists, registry, READMEs, lean-count pin | low |
| `installer/registry.json` | `installer/build-registry.mjs` + `skills/*` contents | installer `add` command, preset validation, setup counts | med |
| `deploy/skill-profiles.json` | skill directory names | `setup.sh --skill-profile` (lean/shipped profiles); pinned by `tests/skill_profiles.bats` (lean=47 → 45 at six sites: lines 5, 7, 26, 28, 47, 64) | med |
| `opencode_app/opencode.json` | skill names | Docker/pm2 web runtime allowlist | low |
| `README.md` (root) + `opencode_app/README.md:30` | `skills/` dir listing (BT-157 hand-maintained); guarded by `tests/test_markitdown_skill.bats:95-102` which greps BOTH files | doc-consistency checks, humans, CI | med |
| `skills/domain-modeling-skill/SKILL.md`, `skills/wayfinder-skill/SKILL.md` | grilling-skill name (survives) | readers of pairing/chain docs | low |
| `deploy/setup.sh` / `deploy/setup.ps1` counts | derive dynamically (`count_skills()`, no hardcoded literals — enforced by `tests/test_count_drift.bats:26-35`) | none to edit — auto-satisfied by 3.1's deletion; verified in 4.2 | low |

## Implementation Phases

### Phase 1: Consolidate skill content
- [x] **1.1** Rework `skills/grilling-skill/SKILL.md`: keep frontmatter keys (`name: grilling-skill`, `license: Apache-2.0`, `compatibility: opencode`, `category: Planning & Alignment`), rewrite description ≤50 words preserving triggers (`grill`, `grill me`, `grill with docs`, `stress-test`); add a Modes section that explicitly supersedes all engine-framing restatements (body intro, "When to use me", Integration table, References): default = interview only; `--docs` = inlines the doc-capture convention directly (source: domain-modeling-skill, NOT the grill-with-docs router): CONTEXT.md glossary capture (canonical term + definition + `_Avoid_` aliases), the ADR three-criteria gate (offer an ADR only when a decision is hard-to-reverse AND surprising AND a real trade-off — all three; most sessions create zero ADRs), and the ADR format (`docs/adr/NNNN-slug.md`, sequential, directory created lazily) — the mode MUST be self-contained with no instruction to load or delegate to `domain-modeling-skill` (absent from the lean profile; delegation would break `--docs` for lean primaries — the failure mode #407 removes); `--plan` = emit `PLANS/PLAN-GIT-{issue}.md` per the canonical contract (see Technical Notes); keep the five interview rules verbatim; remove every `grill-me-skill`/`grill-with-docs-skill`/`domain-modeling-skill` string
    — **Why:** the surviving engine must become the single self-contained entry point before the routers are deleted, or their trigger phrases orphan and `--docs` dead-ends under lean-profile deny-all
    — **Done when:** SKILL.md documents all three modes and states the Modes section supersedes prior restatements; contains zero `grill-me-skill`, `grill-with-docs-skill`, or `domain-modeling-skill` strings; description ≤50 words; frontmatter keys unchanged; five interview rules textually unchanged
    — **Consumers affected:** agents allowing `grilling-skill` (name unchanged — no frontmatter edits), registry (3.3), README row (3.2), `domain-modeling-skill` pairing text (2.1)
    — **Done:** rewrote SKILL.md: Modes section (default / --docs inline capture / --plan emitter) supersedes restatements; description 49 words; zero forbidden strings (grep=0); five interview rules diff-verified byte-identical; files: skills/grilling-skill/SKILL.md; fixes: none

### Phase 2: Reference and allowlist sweep (deleted dirs still present — harmless)
- [ ] **2.1** Update `skills/domain-modeling-skill/SKILL.md`: replace the grill-with-docs pairing text with the consolidated form — it remains the canonical full doc-capture engine; `grilling-skill --docs` carries the compact inline copy
    — **Why:** only live doc describing the old pairing; stale pointers misroute users; noting canonicity mitigates the two-copy drift risk introduced by inlining
    — **Done when:** file contains no `grill-with-docs-skill` string; pairing text names `grilling-skill --docs`
    — **Consumers affected:** readers of domain-modeling docs
- [ ] **2.2** Check `skills/wayfinder-skill/SKILL.md` grilling references; update only if they name the deleted routers (grilling-skill survives — expect no change)
    — **Why:** sweep completeness; wayfinder chains from the grill family
    — **Done when:** file contains no references to the two deleted skill names
    — **Consumers affected:** wayfinder readers
- [ ] **2.3** Update `deploy/skill-profiles.json`: remove `grill-me-skill` and `grill-with-docs-skill` entries (shipped/lean lists); keep `grilling-skill`. Then update `tests/skill_profiles.bats` to pin 45 at all six literal sites — header comments (lines 5, 7), test names (lines 26, 47), count assertion (line 28), expected output (line 64: `45 deny-ok non-skill-ok`). Do NOT backfill the lean profile to 47: the count is an outcome of curation, not a target; backfilled skills would be re-exposed to lean primaries, which the profile intentionally hides
    — **Why:** denied-but-deleted entries are dead config; the bats suite pins the lean count as a deliberate change-detector — deleting two lean keys without re-pinning fails the Phase 4 verification gate
    — **Done when:** JSON valid (`node -e JSON.parse`); zero deleted names present; `grilling-skill` still listed; `grep -nE '\b47\b' tests/skill_profiles.bats` returns nothing
    — **Consumers affected:** `setup.sh --skill-profile lean|full`; CI release workflow (`.github/workflows/release.yml:24` runs bats)
- [ ] **2.4** Update `opencode_app/opencode.json`: remove the two deleted skills from any skill allowlist entries; keep `grilling-skill`
    — **Why:** Docker web runtime allowlist must match the shipped skill set
    — **Done when:** JSON valid, zero deleted names present
    — **Consumers affected:** `docker compose up` runtime
- [ ] **2.5** Update `installer/presets/pack-business.json`: remove the two deleted skills from the preset skill list; keep `grilling-skill`
    — **Why:** preset installs must not reference nonexistent skills
    — **Done when:** JSON valid, zero deleted names present
    — **Consumers affected:** `opencode-init` pack-business users

### Phase 3: Deletion, counts, registry (land together — no red intermediate commit)
- [ ] **3.1** `git rm -r skills/grill-me-skill skills/grill-with-docs-skill`
    — **Why:** both are pure routers with zero unique interview knowledge; keeping them guarantees drift. Placed here so the Phase 3 commit contains deletion + count re-pin + registry regen together (reviewer WARN: intermediate red commits make bisect guesswork)
    — **Done when:** both directories absent from `git ls-files`
    — **Consumers affected:** all swept in Phase 2; count sites re-pinned in 3.2
- [ ] **3.2** Update root `README.md` (149 → 147 at four count sites; Skill Categories table is one row per category — edit the **Planning & Alignment** row: drop the two names from the cell, `(4)` → `(2)`, rewrite the grilling-skill cell description to the modes form; append migration-history note `Post-#407: −2 grill routers (merged into grilling-skill modes) → 147`) AND `opencode_app/README.md` line 30 (`149 skill directories` → `147`)
    — **Why:** BT-157 marks counts hand-maintained; `tests/test_markitdown_skill.bats:95-102` greps BOTH files against disk count — missing opencode_app leaves red CI and a wrong Docker-docs claim
    — **Done when:** no `149` skill-count hits remain in either README (`grep -n 149 README.md opencode_app/README.md` shows no skill-directory hits); Planning & Alignment row shows `(2)`
    — **Consumers affected:** README readers, doc-consistency checks, CI
- [ ] **3.3** Run `node installer/build-registry.mjs` and verify `installer/registry.json` no longer contains the deleted skills
    — **Why:** registry is generated — hand edits would be overwritten; AC requires regeneration + commit
    — **Done when:** build exits 0; `grep -c "grill-me-skill\|grill-with-docs-skill" installer/registry.json` → 0
    — **Consumers affected:** installer `add`, preset validation

### Phase 4: Verification gate
- [ ] **4.1** Repo-wide sweep: `grep -rn "grill-me-skill\|grill-with-docs-skill"` excluding `_archived/`, `node_modules/`, `.git/`, and this PLAN file → zero hits; plus bare-fragment sweep (`grill-me`, `grill-with-docs`) for variable indirection. Note: `domain-modeling-skill` is NOT in this sweep — its zero-string rule is scoped to `skills/grilling-skill/SKILL.md` only (verified in 1.1)
    — **Why:** AC requires zero live references to deleted skills; literal-only greps miss indirection
    — **Done when:** both sweep commands return empty
    — **Consumers affected:** none (verification)
- [ ] **4.2** Run the explicit gates: `bats tests/` (package.json scripts is empty — gate discovery by name, per PLAN-381 precedent) and `node installer/build-registry.mjs`; commit any generated artifacts; verify working tree clean
    — **Why:** AGENTS.md verification gate; the bats suite covers the pinned counts (`skill_profiles.bats`, `test_markitdown_skill.bats`, `test_count_drift.bats`) and registry integrity that CI (`release.yml:24`) enforces on merge
    — **Done when:** `bats tests/` all pass; registry build exits 0; `git status` clean after artifact commit
    — **Consumers affected:** CI, Step 9 code review, PR checks

## Technical Notes
- Survivor name is `grilling-skill` (the engine) — preserves git history, agent frontmatter skill-allows for `requirements-specialist-subagent`/`discovery-specialist-subagent`, and wayfinder/domain-modeling prose references.
- Frontmatter shape change → 6 consumer classes per LEARNINGS `frontmatter-shape-change-blast-radius` — plus the consolidation variant this PLAN adds: skill-dir add/remove trips **literal-count test assertions** (`skill_profiles.bats` pinned 47 ×6; `test_markitdown_skill.bats` 149-count grep across both READMEs). Sweep `grep -rn 'skill director\|lean has exactly\|deny-ok' tests/` on any skill-count change.
- Engine interview rules preserved textually (verified by diff in 1.1's Done-when).
- `--plan` emitter spec (folded into 1.1): emit `PLANS/PLAN-GIT-{issue}.md` with `**Branch**`/`**Issue**`/`**Base**` header, `## Acceptance Criteria`, `## Dependency & Consumer Map` table, `### Phase N:` sections of `- [ ] **N.M**` steps each carrying `— **Why:**` / `— **Done when:**` / `— **Consumers affected:**` — the exact contract `plan-automation-loop-skill` parses (`^### Phase`, `- [ ] **N.M**`, `[x]`) and `plan-updater` flips verbatim. This PLAN file itself follows that contract (dogfood).
- `deploy/setup.sh` + `deploy/setup.ps1` counts need NO edit: both derive counts dynamically (`count_skills()` at setup.sh:417; ps1 equivalent), and `test_count_drift.bats:26-35` forbids hardcoded literals — ticket req satisfied by 3.1's deletion, verified in 4.2.

## Dependencies
None external. Companion ticket #408 (execution-family consolidation) is independent; its parser tests may later consume this skill's `--plan` output.

## Risks & Mitigation
- *Registry drift* → regenerate via build-registry.mjs only (3.3), never hand-edit.
- *Count drift* → all five count sites updated together (3.2); verified by grep + pinned bats tests.
- *Allowlist orphaning* → grilling-skill keeps its lean slot; verified in 2.3.
- *Lost trigger phrases* → description diff checked against old grill-me/grill-with-docs descriptions during 1.1 self-review.
- *Two-copy drift of the ADR/glossary convention* (inline copy vs canonical domain-modeling-skill) → 2.1 records canonicity; compact copy is intentionally smaller (gate + format, not full engine).
- *Red intermediate commits* → deletion bundled into Phase 3 with counts + registry (reviewer WARN 2).
