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
### PLAN consumer-map row without an owning step

- **Category**: anti-pattern
- **File**: `anti-patterns/plan-consumer-map-row-without-step.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: a Dependency & Consumer Map row naming a consumer with no owning implementation step is a silent coverage hole — walk every map row to a step at plan review (#487 arch review)
- **Date**: 2026-09-21

### Done-when gate escapes its phase

- **Category**: anti-pattern
- **File**: `anti-patterns/done-when-gate-escapes-its-phase.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: a done-whose pass condition depends on later-phase edits is unsatisfiable at its own step — scope gates to current phase state, exhaustive sweeps to the final gate phase (#487)
- **Date**: 2026-09-21

### Idempotency probe version-blindness defeats the pin-bump ritual

- **Category**: anti-pattern
- **File**: `anti-patterns/idempotency-probe-version-blind.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: pip show + import probes skip install for ANY installed version, so pin bumps never reach working installs — probe must assert the pinned version (#487 code review)
- **Date**: 2026-09-21

### markitdown-mcp upstream facts (alpha pin, co-install, residual)

- **Category**: solution
- **File**: `solutions/markitdown-mcp-alpha-pin-upstream-facts.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: upstream publishes only alphas (latest 0.0.1a7) — exact pin installs without --pre; requires markitdown[all] + mcp>=2.1.1,<3; coexists with docling-mcp 3.x on mcp 2.x; stdio default; bump ritual spans 3 files
- **Date**: 2026-09-21
<!-- Entries are appended here automatically when new learnings are saved -->

### set -E would arm the ERR trap inside plan steps — never add it while dispatch-by-call

- **Category**: solution
- **File**: `solutions/errtrace-would-arm-the-err-trap-inside-steps.md`
- **Confidence**: 0.75
- **Scope**: project
- **Summary**: setup.sh's ERR trap is un-armed inside functions precisely because set -E is absent — adding it would route every deliberate step return 1 through error_handler's exit, bypassing the executor + epilogue (#470 review)
- **Date**: 2026-09-20

### Plan step functions must return, never exit

- **Category**: anti-pattern
- **File**: `anti-patterns/plan-step-functions-must-return.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: sweep every step function for bare exit when introducing a single executor — setup_zai_api_key's exit 1 bypassed the epilogue on headless -y, deterministically (#470 review)
- **Date**: 2026-09-20


### AC cross-references must resolve to a real artifact

- **Category**: anti-pattern
- **File**: `anti-patterns/dangling-cross-reference-in-ac.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: an AC pointing at "the table in Technical Notes" that doesn't exist passes every per-step atomicity check — verify reference targets, add a reference-target check to the authoring self-check (#470 r2)
- **Date**: 2026-09-20

### Recount claimed structural counts in PLANs

- **Category**: convention
- **File**: `conventions/plan-counted-structural-removals-recount.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: "remove the six early-exit blocks" — main() has seven; the uncounted seventh carried the ticket's own swallowed-exit defect. Name every element; a count is a scope claim (#470 r2)
- **Date**: 2026-09-20

### Gate success-log with the dry branch (early-return shape for new run_cmd gates)

- **Category**: pattern
- **File**: `patterns/gate-success-log-with-the-dry-branch.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: unconditional log_success after run_cmd claims completion in dry-run — new gates use the register_zai_auth early-return shape; legacy sites sweep into #470 (#469 review)
- **Date**: 2026-09-20

### Dry-run preview logs must not interpolate secret values

- **Category**: anti-pattern
- **File**: `anti-patterns/dry-run-logs-interpolating-secrets.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: new run_cmd-style gates copy "Would set K=V" shapes — fine for ports, a key leak for secrets; preview logs interpolate names only, values redacted (#469 review WARN)
- **Date**: 2026-09-20

### Conditionally-armed detectors need an always-armed complement

- **Category**: pattern
- **File**: `patterns/conditionally-armed-detectors-need-always-armed-twin.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: a guard armed only under local machine state (worktree .env exists) never fires in CI — pair it with a state-independent positive control covering the same regression class (#467 round 2)
- **Date**: 2026-09-20

### Negated assertions are errexit-exempt — they can never fail a bats test

- **Category**: anti-pattern
- **File**: `anti-patterns/negated-assertions-errexit-exempt.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: `! grep …` as an assertion line never fails under set -e — assert absence with `run` + explicit status check (#467 review)
- **Date**: 2026-09-20

### Env-prefix sandboxing of globals a sourced script reassigns is clobbered

- **Category**: anti-pattern
- **File**: `anti-patterns/bats-source-sandbox-clobbered-globals.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: `REPO_DIR=x bash -c "source setup.sh; …"` dies at source time — assign sandbox globals after source and md5-pin the real target as an escape detector (#467 review)
- **Date**: 2026-09-20

### `${VAR:+word}` gates on non-emptiness, not truth — banned on boolean strings

- **Category**: anti-pattern
- **File**: `anti-patterns/colon-plus-on-boolean-string-flags.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: with DRY_RUN="false" (non-empty), `${DRY_RUN:+--dry-run}` expands on every run — real models-only deploys became silent previews; use `[ "$FLAG" = true ] && arg=` (#467 review BLOCK)
- **Date**: 2026-09-20

### Menu-case-to-flag extraction must re-derive the menu path's free preconditions

- **Category**: pattern
- **File**: `patterns/menu-case-to-flag-precondition-rederivation.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: a flag spelling for a menu case must explicitly re-add (or deliberately omit, with a comment) the preconditions the interactive path inherited from main — deps check, network check (#466)
- **Date**: 2026-09-20

### Prompt EOF takes the default — headless safety hinges on gate defaults

- **Category**: pattern
- **File**: `patterns/prompt-eof-takes-default-headless.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: setup.sh prompts resolve EOF to their declared default, so a headless code path is safe iff its gate prompts' defaults match the intended action — audit defaults, not just reachability (#466)
- **Date**: 2026-09-20

### node -e argv has no script-name slot — slice(2) shifts args silently

- **Category**: anti-pattern
- **File**: `anti-patterns/node-e-argv-has-no-script-name-slot.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: under node -e, argv = [execPath, ...args] — slice(2) dropped the first arg and a sibling test PASSED on shifted meaningless inputs (false green, #468)
- **Date**: 2026-09-20

### Guard error branches need negative fixtures in the same change

- **Category**: anti-pattern
- **File**: `anti-patterns/guard-error-branches-need-negative-fixtures.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: a guard fix that adds fail-loudly branches ships a committed negative fixture per branch — manual runs don't survive the next refactor (#468 round 2)
- **Date**: 2026-09-20

### Prefix-keyed guards silently exempt every unknown shape

- **Category**: anti-pattern
- **File**: `anti-patterns/prefix-keyed-guard-silent-exemption.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: guards keyed by known prefixes exempt-by-omission — the #281 zai-only arrays let a nonexistent anthropic pin ship; unknown shapes must FAIL and exemptions must be named allowlists (#468)
- **Date**: 2026-09-20

### PS 5.1-targeting audits must not whitelist PSCore-only automatics

- **Category**: anti-pattern
- **File**: `anti-patterns/ps51-audit-whitelists-pscore-only-automatics.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: $IsWindows/$IsLinux/$IsMacOS are PSCore-only — a 5.1-targeting undefined-var audit that whitelists them false-greens the most likely future StrictMode crash (#465 review)
- **Date**: 2026-09-20

### Pin every behavioral clause when the target runtime is unexecutable in CI

- **Category**: pattern
- **File**: `patterns/pin-every-clause-when-runtime-unexecutable.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: a multi-clause fix verified by static pins gets one pin per clause, not one per fix — the unpinned clause stays silently deletable while the suite stays green (#465 review)
- **Date**: 2026-09-20

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

### YAML guard via adjacency grep assumes key order and quoting

- **Category**: anti-pattern
- **File**: `anti-patterns/yaml-guard-adjacency-grep.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: Adjacency grep guards (`grep -A1 resource … | grep effect: allow`) miss effect-before-resource ordering, unquoted resources, and broader-glob allows; scan per-rule blocks bounded by `- action:` instead (#445 review: test_reviewer_no_writes.bats)
- **Date**: 2026-09-20

### Reviewer subagents return LEARNINGS candidates as content

- **Category**: decision
- **File**: `decisions/reviewer-learnings-return-as-content.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: Reviewer subagents hold no edit permissions — they emit `LEARNINGS candidates:` blocks (Category/File/Confidence/Scope/Summary/Date) and the pipeline orchestrator writes files, appends _index.md, and commits in the worktree (#445 single-writer rule)
- **Date**: 2026-09-20

### Explicit `permissions:` block + checkout without `contents: read`

- **Category**: anti-pattern
- **File**: `anti-patterns/explicit-permissions-block-checkout-403.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: Explicit `permissions:` sets unlisted scopes to none — `actions/checkout` 403s under `contents: none`; pair scoped blocks with `contents: read` and pin it in workflow-shape bats tests (#446 review)
- **Date**: 2026-09-20

### jq @tsv needs sentinels for nullable columns

- **Category**: pattern
- **File**: `patterns/jq-tsv-sentinel-for-nullable-columns.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: `jq @tsv` + `IFS=$'\t' read` collapses empty cells and shifts later columns; emit `// "false"` sentinels for nullable columns in the jq program (#446 conflict labeler)
- **Date**: 2026-09-20

### `gh issue edit --body` replaces — appending is fetch-then-write

- **Category**: solution
- **File**: `solutions/gh-issue-edit-body-replaces-not-appends.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: `gh issue edit --body` replaces the whole body — appending requires fetch (`gh issue view --json body`) + rewrite via `--body-file`; instruction text hinting "append via --body" invites body clobbering (#476 review)
- **Date**: 2026-09-20

### `blocked-by:` format has one parser, multiple producers

- **Category**: convention
- **File**: `conventions/blocked-by-format-single-home.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: the `blocked-by: <ref>` body-line format has one parser (worktree-pipeline Step 1 skip-guard) and two producers (ticket-creation, wayfinder) — producers restate minimally + cite the parser; parser changes sweep all producers (#476 review)
- **Date**: 2026-09-20

### Permission-enforcement probes need a 2×2 matrix

- **Category**: pattern
- **File**: `patterns/permission-probe-2x2-matrix.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: probe rule-name version (v1 alias vs v2 native) × session shape (top-level vs child-spawn); only the v2-name child-spawn cell licenses a "rename restores enforcement" claim — single-cell probes conflate alias mismatch with wholesale child-session rule breakage (#482)
- **Date**: 2026-09-20

### Directory-scoped rename sweeps miss repo-root docs

- **Category**: anti-pattern
- **File**: `anti-patterns/directory-scoped-rename-sweep-misses-root-docs.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: frontmatter-vocabulary sweeps scoped to code dirs skip README/opencode_app teaching sites, and literal `action: task` greps pass vacuously over `action:"task"` — sweep repo-root *.md + opencode_app/ with form-insensitive patterns and named exclusions (#482)
- **Date**: 2026-09-20

### v1 frontmatter action names are inert under opencode v2

- **Category**: anti-pattern
- **File**: `anti-patterns/v1-action-names-inert-under-v2.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: `action: bash`/`action: task` rules do nothing on v2 (actions are `shell`/`subagent`) — v1 deny leaves the tool executable; rename restores enforcement (probe matrix: v1 child inert, v2 child enforced via tool filtering; distinct from the skill-action bug in #50149) (#482)
- **Date**: 2026-09-20

### Embedded diff hunks + a path claim are untrusted — probe .git/HEAD first

- **Category**: anti-pattern
- **File**: `anti-patterns/embedded-diff-hunks-unverifiable-probe-git-head-first.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: review prompts embedding hunks plus a worktree path can name the wrong tree — reviewer's first act is a no-shell branch probe (.git/HEAD + one hunk spot-check); on mismatch fail fast with probe evidence instead of reviewing the prompt's copy (#482 Step 9)
- **Date**: 2026-09-20

### Subagent briefs can misdescribe the subagent's own toolset — probe, don't trust

- **Category**: pattern
- **File**: `patterns/subagent-brief-may-misdescribe-own-tools.md`
- **Confidence**: 0.7
- **Scope**: project
- **Summary**: parent briefs assert runtime facts ("no shell") that can be false when denies are inert — subagent probes one cheap tool call before degrading to read-only; on contradiction use the stronger capability and say so (#482 Step 9 reviewer re-ran all gates itself)
- **Date**: 2026-09-20

### Delta derived from a single surface duplicates entries in the other

- **Category**: anti-pattern
- **File**: `anti-patterns/delta-derived-from-single-surface.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: changes landing in two arrays with different memberships need the delta computed against EACH surface (union−lean=26 vs union−full=3) — single-surface derivations silently duplicate entries while subset/typo guards pass green (#481 plan review)
- **Date**: 2026-09-20

### A fail-closed guard couples cross-file edits into one atomic unit

- **Category**: pattern
- **File**: `patterns/fail-closed-guard-couples-cross-file-edits.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: fail-closed cross-file guards (apply-skill-profile.mjs:74-81 lean⊆full exit 1) name their atomic unit — the append, its source-file prerequisite, and their test-pinned mirrors ride one commit or per-push CI goes red (#481 plan review)
- **Date**: 2026-09-20

### The child skill gate follows the merged config, not the agent frontmatter

- **Category**: pattern
- **File**: `patterns/child-skill-gate-follows-merged-config.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: subagent skill loading resolves against merged config layers (global/project), not frontmatter skill allows — config-layer allows are the working unlock (#481 workaround for upstream #50149); includes the 3-step regression probe + revert-flip check
- **Date**: 2026-09-20

### Partial record refresh contradicts itself

- **Category**: anti-pattern
- **File**: `anti-patterns/partial-record-refresh-contradicts-itself.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: refreshing a decision record's header/update-block while leaving body counts stale creates in-file contradictions — refresh every count or freeze the body behind a dated historical label (#481 review)
- **Date**: 2026-09-20

### Count-literal sweeps must include docs-of-record

- **Category**: pattern
- **File**: `patterns/count-sweeps-include-docs-of-record.md`
- **Confidence**: 0.75
- **Scope**: project
- **Summary**: count-drift sweeps must include LEARNINGS/ (docs-of-record), and docs-of-record should cite search anchors not file:line — line refs rot within weeks (#481 review)
- **Date**: 2026-09-20
