# LEARNINGS Index

<!-- AUTO-GENERATED — manual edits to the listing below will be overwritten on next learning write -->
<!-- To add context manually, edit above this comment or in individual learning files -->

## Folder Structure

| Folder | Purpose | Example |
|--------|---------|---------|
| `patterns/` | Reusable code/architecture patterns worth replicating | `event-driven-modules.md` |
| `decisions/` | Architectural decisions with rationale (ADR-lite) | `sqlite-over-postgres-local.md` |
| `anti-patterns/` | Things to avoid, with explanations | `mutable-default-args-python.md` |
| `solutions/` | Non-obvious fixes and workarounds worth remembering | `race-condition-mutex-fix.md` |
| `conventions/` | Team-agreed coding standards and naming rules | `kebab-case-files.md` |

## Entries

<!-- Entries are appended here automatically when new learnings are saved -->

### opencode.json // comments break CI

- **Category**: anti-pattern
- **File**: `anti-patterns/jsonc-comments-in-opencode-json.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Never add // comments to opencode_app/opencode.json — CI bats tests use Python json.load() which can't parse JSONC
- **Date**: 2026-07-26

### Skill permission allowlist — shipped 148, lean profile 46, deploy default lean

- **Category**: decision
- **File**: `decisions/skill-permission-allowlist.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Allowlist strategy hides 102 skills from primary's available_skills (148 shipped − 46 lean), cutting per-session description tokens
- **Date**: 2026-07-26

### Plugins need both plugin array + command block

- **Category**: solution
- **File**: `solutions/plugin-needs-command-block.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: opencode-goal-plugin requires BOTH plugin array entry AND command.goal config block — removing either breaks /goal
- **Date**: 2026-07-26

### Redocly `operation-description` is OFF by default in `recommended`

- **Category**: solution
- **File**: `solutions/redocly-operation-description-off-by-default.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: redocly's `recommended` ruleset does NOT enable `operation-description` (off by default); a per-field description mandate is load-bearing until `redocly.yaml` sets `operation-description: error`
- **Date**: 2026-08-05

### tsoa response examples use `@Example()` decorator, not `@example` JSDoc

- **Category**: solution
- **File**: `solutions/tsoa-response-example-decorator-not-jsdoc.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: tsoa response-body examples require the `@Example()`/`@Response()` TypeScript decorators; `@example` JSDoc only covers params/model props
- **Date**: 2026-08-05

### Tier→model swap blast radius (7 surfaces, plus deploy-script echoes)

- **Category**: pattern
- **File**: `patterns/tier-model-swap-blast-radius.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Model tier swaps touch 7 surfaces — tier JSON, presets, guard arrays, agent .md (desc+body→registry regen), SKILL prose, doc tables, and hardcoded model echoes in setup scripts (setup.sh --status)
- **Date**: 2026-08-27

### permission.task delegate changes — 4 sync surfaces + delegate ceiling check

- **Category**: convention
- **File**: `conventions/task-delegate-permission-sync.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Task-delegate allow-list changes sync 4 surfaces (frontmatter, registry regen, README row, agent-body note); delegation step wording must respect the delegate's own permission ceiling (bash:deny → parent owns diff/lint/commit)
- **Date**: 2026-08-27

### path-move restructure: anchor CI tarball gates, verify search-path consumers

- **Category**: solution
- **File**: `solutions/path-move-ci-gate-anchoring.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Path moves (#381): anchor CI `npm pack` grep gates to package-root paths (substring matches false-green); config files consumed via search-path chains (vibeguard.ts) need bridge symlink / explicit COPY per runtime
- **Date**: 2026-09-14

---

**Storage paths:**
- Project-level: `LEARNINGS/` (this directory, git-committed)
- User-level: `~/.config/opencode/learnings/` (personal, cross-project)
- Searchable memory: `memory` tool (primary for quick retrieval)

**Naming convention:** Use descriptive slugs (e.g., `event-driven-modules.md`), not dated or numbered prefixes. The category is determined by the subfolder.
