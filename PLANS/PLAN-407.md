# PLAN: Consolidate grill skills into one skill with modes

**Branch**: feat/407
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/407
**Base**: main

## Acceptance Criteria
- [ ] One grill skill directory remains (`skills/grilling-skill/`); directory name equals skill name (kebab-case)
- [ ] Trigger phrases `grill`, `grill me`, `grill with docs` all route to it with the correct mode; description ≤50 words preserving all trigger phrases
- [ ] `--plan` mode emits output that parses under the execution contract: `^### Phase`, `- [ ] **N.M**`, `- [x]` completion; rationale triple survives checkbox flips verbatim
- [ ] `skills/grill-me-skill/` and `skills/grill-with-docs-skill/` deleted; zero remaining references outside `_archived/` and `node_modules/`
- [ ] `registry.json` regenerated via `node installer/build-registry.mjs` and committed
- [ ] Sync surfaces updated: README counts + category table, `deploy/skill-profiles.json`, `opencode_app/opencode.json`, `installer/presets/pack-business.json`

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/grilling-skill/SKILL.md` | — | picker users; `agents/requirements-specialist-subagent.md` + `agents/discovery-specialist-subagent.md` (frontmatter skill allow); `installer/registry.json`; `deploy/skill-profiles.json`; `opencode_app/opencode.json`; `installer/presets/pack-business.json`; README | med |
| `skills/grill-me-skill/` (delete) | — | allowlists (`opencode_app/opencode.json`, `deploy/skill-profiles.json`), `installer/registry.json`, `installer/presets/pack-business.json`, README | low |
| `skills/grill-with-docs-skill/` (delete) | grilling-skill (conceptual router) | `skills/domain-modeling-skill/SKILL.md` pairing text, allowlists, registry, README | low |
| `installer/registry.json` | `installer/build-registry.mjs` + `skills/*` contents | installer `add` command, preset validation, setup counts | med |
| `deploy/skill-profiles.json` | skill directory names | `setup.sh --skill-profile` (lean/shipped profiles) | low |
| `opencode_app/opencode.json` | skill names | Docker/pm2 web runtime allowlist | low |
| `README.md` (counts, rows) | `skills/` dir listing (BT-157 hand-maintained) | doc-consistency checks, humans | low |
| `skills/domain-modeling-skill/SKILL.md`, `skills/wayfinder-skill/SKILL.md` | grilling-skill name (survives) | readers of pairing/chain docs | low |

## Implementation Phases

### Phase 1: Consolidate skill content
- [ ] **1.1** Rework `skills/grilling-skill/SKILL.md`: keep frontmatter keys (`name: grilling-skill`, `license: Apache-2.0`, `compatibility: opencode`, `category: Planning & Alignment`), rewrite description ≤50 words preserving triggers (`grill`, `grill me`, `grill with docs`, `stress-test`), add a Modes section (default interview / `--docs` CONTEXT.md+ADR capture folded in from grill-with-docs / `--plan` PLAN.md emitter), keep the five interview rules verbatim, remove all mentions of `grill-me-skill` and `grill-with-docs-skill`
    — **Why:** the surviving engine must become the single entry point before the routers are deleted, or their trigger phrases orphan
    — **Done when:** SKILL.md documents all three modes, contains no `grill-me-skill`/`grill-with-docs-skill` strings, description ≤50 words, frontmatter keys unchanged
    — **Consumers affected:** agents allowing `grilling-skill` (unchanged name — no frontmatter edits needed), registry (regenerated in 3.2), README row (3.1)
- [ ] **1.2** `git rm -r skills/grill-me-skill skills/grill-with-docs-skill`
    — **Why:** both are pure routers with zero unique interview knowledge; keeping them guarantees drift
    — **Done when:** both directories absent from `git ls-files`
    — **Consumers affected:** allowlists, registry, pack-business preset, README — all swept in Phase 2

### Phase 2: Reference and allowlist sweep
- [ ] **2.1** Update `skills/domain-modeling-skill/SKILL.md`: replace the grill-with-docs pairing text with the consolidated form (`grilling-skill --docs` mode)
    — **Why:** only live doc describing the old pairing; stale pointers misroute users
    — **Done when:** file contains no `grill-with-docs-skill` string
    — **Consumers affected:** readers of domain-modeling docs
- [ ] **2.2** Update `skills/wayfinder-skill/SKILL.md` grilling references if they name the deleted routers (grilling-skill survives — expect no change)
    — **Why:** sweep completeness; wayfinder chains from the grill family
    — **Done when:** file contains no references to the two deleted skill names
    — **Consumers affected:** wayfinder readers
- [ ] **2.3** Update `deploy/skill-profiles.json`: remove `grill-me-skill` and `grill-with-docs-skill` entries wherever they appear (shipped/lean lists); keep `grilling-skill`
    — **Why:** denied-but-deleted entries are dead config; grilling-skill must keep its lean slot so nothing orphans
    — **Done when:** JSON valid (`node -e JSON.parse`), zero deleted names present, `grilling-skill` still listed
    — **Consumers affected:** `setup.sh --skill-profile lean|full`
- [ ] **2.4** Update `opencode_app/opencode.json`: remove the two deleted skills from any skill allowlist entries; keep `grilling-skill`
    — **Why:** Docker web runtime allowlist must match the shipped skill set
    — **Done when:** JSON valid, zero deleted names present
    — **Consumers affected:** `docker compose up` runtime
- [ ] **2.5** Update `installer/presets/pack-business.json`: remove the two deleted skills from the preset skill list; keep `grilling-skill`
    — **Why:** preset installs must not reference nonexistent skills
    — **Done when:** JSON valid, zero deleted names present
    — **Consumers affected:** `opencode-init` pack-business users

### Phase 3: Counts and registry
- [ ] **3.1** Update `README.md`: change 149 → 147 at the four count sites (file-tree line, opencode-init section, lean-profile section, modularization section), remove the two skills' rows from the Skill Categories table, update the `grilling-skill` row description to the modes form, append migration-history note `Post-#407: −2 grill routers (merged into grilling-skill modes) → 147`
    — **Why:** BT-157 marks counts hand-maintained; doc-consistency checks compare them to reality
    — **Done when:** `grep -c 149 README.md` returns no skill-count hits; table has no deleted-skill rows
    — **Consumers affected:** README readers, documentation-consistency checks
- [ ] **3.2** Run `node installer/build-registry.mjs` and verify `installer/registry.json` no longer contains the deleted skills
    — **Why:** registry is generated — hand edits would be overwritten; AC requires regeneration + commit
    — **Done when:** build exits 0; `grep -c "grill-me-skill\|grill-with-docs-skill" installer/registry.json` → 0
    — **Consumers affected:** installer `add`, preset validation

### Phase 4: Verification gate
- [ ] **4.1** Repo-wide sweep: `grep -rn "grill-me-skill\|grill-with-docs-skill"` excluding `_archived/`, `node_modules/`, `.git/`, and this PLAN file → zero hits
    — **Why:** AC requires zero live references; literal-only greps miss indirection, so also sweep bare `grill-me`/`grill-with-docs` fragments
    — **Done when:** sweep command output is empty
    — **Consumers affected:** none (verification)
- [ ] **4.2** Run repo verification gates discovered from `package.json` (lint/test/build scripts where defined) plus `node installer/build-registry.mjs`; commit any generated artifacts
    — **Why:** AGENTS.md verification gate: lint + typecheck always; build on registry/config changes
    — **Done when:** all discovered gate commands exit 0; working tree clean after artifact commit
    — **Consumers affected:** CI, Step 9 code review, PR checks

## Technical Notes
- Survivor name is `grilling-skill` (the engine) — preserves git history, agent frontmatter skill-allows for `requirements-specialist-subagent`/`discovery-specialist-subagent`, and wayfinder/domain-modeling prose references.
- Frontmatter shape change → 6 consumer classes per LEARNINGS `frontmatter-shape-change-blast-radius` (registry, profiles, presets, app config, README, agent allows) — all covered by Phases 2–3.
- Engine interview rules preserved verbatim per LEARNINGS `skill-trim-verbatim-preservation`.
- `--plan` emitter spec (folded into 1.1): emit `PLANS/PLAN-GIT-{issue}.md` with `**Branch**`/`**Issue**`/`**Base**` header, `## Acceptance Criteria`, `## Dependency & Consumer Map` table, `### Phase N:` sections of `- [ ] **N.M**` steps each carrying `— **Why:**` / `— **Done when:**` / `— **Consumers affected:**` — the exact contract `plan-automation-loop-skill` parses (`^### Phase`, `- [ ] **N.M**`, `[x]`) and `plan-updater` flips verbatim. This PLAN file itself follows that contract (dogfood).

## Dependencies
None external. Companion ticket #408 (execution-family consolidation) is independent; its parser tests may later consume this skill's `--plan` output.

## Risks & Mitigation
- *Registry drift* → regenerate via build-registry.mjs only (3.2), never hand-edit.
- *Count drift* → all four README count sites updated together (3.1); verified by grep.
- *Allowlist orphaning* → grilling-skill keeps its lean slot; verified in 2.3.
- *Lost trigger phrases* → description diff checked against old grill-me/grill-with-docs descriptions during 1.1 self-review.
