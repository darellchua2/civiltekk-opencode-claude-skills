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

### bats test bodies run under errexit — for-loop assertions are fail-fast

- **Category**: solution
- **File**: `solutions/bats-errexit-loop-failfast.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: bats-core runs test bodies under `set -e` — a failing grep/cmp inside a for-loop aborts the test immediately; do not flag multi-iteration assertion loops as false-pass (#417 review false positive)
- **Date**: 2026-09-19

### Validator crashes on invalid input

- **Category**: anti-pattern
- **File**: `anti-patterns/validator-crashes-on-invalid-input.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Never let a validator traceback on the invalid input it exists to reject (#402 spec_to_dxf parallel-constraint crash); guard extractions or skip dependent checks when schema errors exist
- **Date**: 2026-09-19

### Global in-flight guard bleeds across sessions

- **Category**: anti-pattern
- **File**: `anti-patterns/global-in-flight-guard-cross-session-bleed.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Scope hook-suppression/in-flight guards to the affected entity (per-session Set), never a global counter — a send in flight for session A must not swallow a real user message in session B (#418 auto-continue review round 2)
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
### Unexpanded `$(cat …)` in subagent prompt + cwd on wrong branch

- **Category**: anti-pattern
- **File**: `anti-patterns/unexpanded-cat-embedding-wrong-branch-cwd.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: #383 review spawn delivered literal `$(cat …)` (never expanded) while the subagent's clone sat on main without the feat/383 ref — read-only tools returned the pre-trim side; embed real `git show` output or run the reviewer in the branch worktree
- **Date**: 2026-09-17

### Literal-only stale-path greps miss variable indirection

- **Category**: anti-pattern
- **File**: `anti-patterns/literal-only-path-sweep-misses-variable-indirection.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: Path-move sweeps grepping only literal `deploy/<file>` miss `${DEPLOY_DIR}/<file>` forms — #378's setup.sh:3008 provider-models guard silently skipped post-move while all PLAN grep gates read 0; sweep the variables that resolve into the moved dir, not just literal paths
- **Date**: 2026-09-15

### Verified-stamp docs must cite every actionable claim

- **Category**: convention
- **File**: `conventions/verified-doc-claims-need-citations.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: In docs stamped "Verified against <source>", every command/env var/field path must trace to that source or carry an inference label at EACH occurrence — #385 review caught unlabeled cache-inference restated under "Why v2 dropped pruning", uncited `OPENCODE_DISABLE_AUTOCOMPACT`/`opencode stats`, and `session.warming` (actual key: top-level `warming`)
- **Date**: 2026-09-15

### Skill-content trim with verbatim preservation (#383 recipe)

- **Category**: pattern
- **File**: `patterns/skill-trim-verbatim-preservation.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: 93% SKILL.md trim recipe — frontmatter byte-identical, Learning entries verbatim, external anchors + live workflow contracts intact, dated removal-note blockquote, compose-don't-duplicate pointers
- **Date**: 2026-09-17

### bats structure pin: grep line-ordering test for shell call ordering

- **Category**: pattern
- **File**: `patterns/bats-structure-pin-call-order.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Pin call order in big shell scripts with bats grep line-number assertions (mig < deploy_content < config-only resolver) + negative grep of the removed pattern — #379's ordering rule regression net
- **Date**: 2026-09-17

### Safety snapshot gated on a side-effect-created directory

- **Category**: anti-pattern
- **File**: `anti-patterns/conditional-backup-dead-path.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: deploy_content's content-backup gate `[ -d "$BACKUP_DIR" ]` is dead in `--yes` redeploys (config-overwrite prompt auto-accepts default n → no create_backup) — snapshots must mkdir their own target
- **Date**: 2026-09-17

### Legacy manifest upgrades must probe every on-disk target

- **Category**: anti-pattern
- **File**: `anti-patterns/legacy-upgrade-target-probe.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: #379 legacy entries synthesis hashes opencode targets only — claude-target installs silently stop being updated/pruned; probe every target dir when upgrading manifests
- **Date**: 2026-09-17

### Advisory visibility checks must not run at full-catalog scale

- **Category**: anti-pattern
- **File**: `anti-patterns/advisory-check-full-catalog-noise.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: checkStrictAllowlist on `add --all`/`update` prints 100+ misleading warning lines against the default lean profile — gate per-item advisories to partial selections
- **Date**: 2026-09-17

### Normative rule added, in-file example left stale

- **Category**: anti-pattern
- **File**: `anti-patterns/rule-added-example-stale.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: when a commit adds or changes a skill rule, sweep the same file's Example Usage of that flow — stale examples are the strongest signal teaching agents the deprecated behavior
- **Date**: 2026-09-19

### Derive consistency pins from the source-of-truth file at runtime

- **Category**: convention
- **File**: `conventions/derived-consistency-pins.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: #439 review: tests pinning two files together must derive expectations from the source-of-truth file at runtime (grep HANDOFF_* from the guard), not restate literals in both — derived pins make drift a hard failure instead of two files aging separately
- **Date**: 2026-09-19

### Adaptive review drops proactive requirements review; gaps flow via Mode R relay

- **Category**: decision
- **File**: `decisions/adaptive-review-requirements-relay.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Step 7 selects reviewers by blast-radius only; uiux gained a required Requirements Gaps field; surfaced gaps relay to requirements-specialist Mode R; Step 1 preflight guards per-skill installs
- **Date**: 2026-09-18

### Case-sensitive grep gates false-green on file-tree prose

- **Category**: anti-pattern
- **File**: `anti-patterns/case-sensitive-grep-gates-false-green.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: #423 review: PLAN-423 3.5 gate read green while README.md:32 still said "Symlink bridge" — case-sensitive prose grep missed the capital, and the line-anchored path pattern can't match ASCII trees that split parent/child across lines; use grep -i plus bare child-name patterns for tree blocks
- **Date**: 2026-09-19

### Guard-regex quote-shape mismatch false-greens on regression spellings

- **Category**: anti-pattern
- **File**: `anti-patterns/guard-regex-quote-shape-mismatch.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: #437 review: the isolation guard's segmented `"_"` pattern passed its canary yet missed 8/10 real spellings incl. the exact pre-fix lines (`parents[2] / "_common"`); census historical lines before writing grep guards and plant those spellings in canaries
- **Date**: 2026-09-19

### `git stash` exits 0 on nothing-to-save — porcelain-gated STASHED flags lie

- **Category**: anti-pattern
- **File**: `anti-patterns/git-stash-nothing-to-save-exit-zero.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: #423 fix round: `git status --porcelain` counts untracked files as dirty but `git stash` (no -u) stashes nothing and still exits 0 — a STASHED flag set from porcelain + exit code goes true with no stash created, and the later pop fails on an empty stash; gate on `--untracked-files=no` or compare the refs/stash rev before/after
- **Date**: 2026-09-19

---

- Project-level: `LEARNINGS/` (this directory, git-committed)
- User-level: `~/.config/opencode/learnings/` (personal, cross-project)
- Searchable memory: `memory` tool (primary for quick retrieval)

**Naming convention:** Use descriptive slugs (e.g., `event-driven-modules.md`), not dated or numbered prefixes. The category is determined by the subfolder.

### `gh api --paginate --jq` evaluates per page — aggregations count pages

- **Category**: anti-pattern
- **File**: `anti-patterns/gh-api-paginate-jq-per-page-aggregation.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: REST `--paginate` applies `--jq` once per page (concatenated text; `--slurp` is mutually exclusive with `--jq`) — `[...]|length` emits one number per page and breaks silently at >100 items (per_page forced to 100); stream items with `--jq` then `wc -l` / `jq -s` instead (#361 review: dispatcher idle-count)
- **Date**: 2026-09-19

### Single-homed policy prose — copies are pointer + skill-specific only

- **Category**: convention
- **File**: `conventions/policy-single-home-pointer-shape.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: #434 review: dedup-target copies of single-homed policy keep pointer + skill-specific endpoint/skip clause only; compressed policy ladders inside copies are residual drift (genus of conditional-mode-blocks-supersede-all-restatements); glosses belong to consumers, not §-section owners
- **Date**: 2026-09-19

### Uncoordinated `execute.before` writers on `event.input` — vibeguard restore vs. plugin payload rewrites

- **Category**: anti-pattern
- **File**: `anti-patterns/concurrent-execute-before-writers-event-input.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: #448 plan review: multiple plugins hooking `ctx.tool.hook("execute.before")` share `event.input` in glob order — payload-rewriting plugins must never write partial/truncated strings that could split a vibeguard `__VG_<CATEGORY>_<hash>__` placeholder (restoreDeep could not restore fragments); copy verbatim or skip
- **Date**: 2026-09-20

### `setup.sh --dry-run` under non-interactive stdin takes the skills-only path — plugin deploy is never previewed

- **Category**: solution
- **File**: `solutions/setup-sh-dry-run-menu-skips-plugin-deploy.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: #448 plan review (empirically traced): default/EOF menu path resolves to Quick/Skills-Only which never calls `deploy_plugins()` — use `--dry-run -y` for plugin-deploy previews; also `run_cmd` echoes the expanded `$HOME` path, never literal `~`, so grep gates must match the absolute form
- **Date**: 2026-09-20

### Fix-round PLAN sync stopped at the AC block — Technical Notes and gate trace left stale

- **Category**: anti-pattern
- **File**: `anti-patterns/plan-fix-round-ac-only-sync.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: #448 re-review: behavior-changing fix synced the amended AC + code + tests but left PLANS/PLAN-448.md:79 stating the superseded drop rule and no GATE memo for the re-run — sweep every PLAN restatement (Technical Notes, step enumerations, gate trace) of a changed rule, not just the AC block
- **Date**: 2026-09-20
