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

### Validator crashes on invalid input

- **Category**: anti-pattern
- **File**: `anti-patterns/validator-crashes-on-invalid-input.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Never let a validator traceback on the invalid input it exists to reject (#402 spec_to_dxf parallel-constraint crash); guard extractions or skip dependent checks when schema errors exist
- **Date**: 2026-09-19

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
- **Summary**: v1-only rule (SUPERSEDED for v2, #382): v1 opencode-goal-plugin needed BOTH plugin array entry AND command.goal block; the v2 rescoped @prevalentware/opencode-goal-plugin self-registers /goal, /pause_goal, /resume_goal — no commands block on v2
- **Date**: 2026-07-26

### Re-adopt goal mode as @prevalentware/opencode-goal-plugin (v2), caret-pinned

- **Category**: decision
- **File**: `decisions/goal-plugin-v2-readoption.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: plugins: ["@prevalentware/opencode-goal-plugin@^0.1.48"] — caret pin (v1 breakage was v1-only versions under v2 runtime, not pinning), no options (secure defaults), no commands.goal block; wejick/opencode-goal rejected; Docker inert until #387
- **Date**: 2026-09-14

### Docker v1 binary silently ignores the v2 `plugins` key

- **Category**: solution
- **File**: `solutions/docker-v1-binary-ignores-v2-plugins-key.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: The container's v1 opencode binary ignores the v2-native plugins key with NO warning — v2 plugin additions need a runtime-presence assertion or an explicit Docker descope (#387); build green ≠ plugin loaded. RESOLVED by #387: @opencode/cli v2 binary + authenticated healthcheck asserting goal presence
- **Date**: 2026-09-14

### Doc claims about runtime enforcement must match plugin defaults

- **Category**: convention
- **File**: `conventions/doc-claims-match-plugin-defaults.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Document only the enforcement a plugin's ACTIVE defaults provide (option-gated features get an inline "only when configured") — #382 review caught "enforces token/duration limits" claimed while both budgets ship unset
- **Date**: 2026-09-15

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

### init.mjs agentModel ↔ resolve-models resolveAgent precedence parity

- **Category**: convention
- **File**: `conventions/agent-override-precedence-parity.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: agentModel must mirror resolveAgent at both override levels (project > global > tier), incl. throw-on-malformed-JSON; changes land in both files + fake-HOME bats per level
- **Date**: 2026-09-19

---

- Project-level: `LEARNINGS/` (this directory, git-committed)
- User-level: `~/.config/opencode/learnings/` (personal, cross-project)
- Searchable memory: `memory` tool (primary for quick retrieval)

**Naming convention:** Use descriptive slugs (e.g., `event-driven-modules.md`), not dated or numbered prefixes. The category is determined by the subfolder.
