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


### By-reference docs mechanize no-duplication with sentinel greps

- **Category**: patterns
- **File**: `LEARNINGS/patterns/by-reference-docs-mechanize-no-duplication-with-sentinel-greps.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: No-duplication ACs get sentinel greps (table-header rows, zero ^| lines), heading-existence greps per citation, and test -f per file link — prose-only checks are unenforceable (#539).

### Runnable doc snippets must mirror CI's invocation

- **Category**: conventions
- **File**: `LEARNINGS/conventions/docs-runnable-snippets-must-match-ci-invocation.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Copy CI's setup lines (PATH export, env) into runnable doc snippets — bats lives off-PATH at tests/lib/bats-core/bin; bare `bats` fails on clean machines (#539).


### Tracked LEARNINGS entries need gitignore negations

- **Category**: conventions
- **File**: `LEARNINGS/conventions/tracked-learnings-entries-need-gitignore-negations.md`
- **Confidence**: 0.7
- **Scope**: project
- **Summary**: Publish entries via `!` negation lines, never `git add -f` (#544 vs #542 divergence); keep full File: path prefix in index rows.

### Line-pinned incident learnings drift after the fix lands

- **Category**: anti-patterns
- **File**: `LEARNINGS/anti-patterns/line-pinned-incident-learnings-drift-after-fix-lands.md`
- **Confidence**: 0.7
- **Scope**: project
- **Summary**: Pin the fixed lines as exemplar or drop line pins for pre-fix states — pins to pre-fix lines go false when fix+entry ship together (#539/#542).

<!-- Entries are appended here automatically when new learnings are saved -->

### Re-vendor version-string census

- **Category**: pattern
- **File**: `LEARNINGS/patterns/re-vendor-version-string-census.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: A re-vendor PLAN must own the old-version-string census, not just the pin files. PLAN-533 bumped 2 of 18 files carrying v4.8.4; two steps actively forbade touching theirs. Rule: exit gate `rg -l '<old-version>' --glob '!PLANS/**'` → zero (or explicit allowlist) — a stale pin in 13+ files means the next maintainer trusts a lying version.

### Plan-step premise already true

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/plan-step-premise-already-true.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: A plan step whose done-when grep is already green pre-work certifies nothing — the executor ticks it with zero changes while the AC's real intent ships unverified. Rule: at plan review, run each grep-based done-when against the current tree; an already-passing gate means the premise is stale — rewrite it around the real deliverable.

### Plugin-persisted state needs a volume-backed path

- **Category**: decision
- **File**: `LEARNINGS/decisions/plugin-persisted-state-needs-volume-backed-path.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: Plugin state that must survive restarts goes under ~/.local/share/opencode/, not ~/.config/opencode/ — docker compose mounts only the data dir; config-dir and /app state dies on container recreation. Pin the path in the PLAN (or record an env-var-only limitation); a map row naming the docker consumer without an owning step is the plan-consumer-map-row-without-step anti-pattern.

### Persisted default frozen at module load

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/persisted-default-frozen-at-module-load.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: A runtime-persisted default resolved into a module-load const can never observe its own writer in-process — the command that persists it overpromises until an opaque restart. Rule: mutable shadow updated on successful persist (or lazy read), success message matches pickup semantics, plus a same-process new-session test.

### Shipped side artifacts need a full lifecycle

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/shipped-side-artifacts-need-full-lifecycle.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: Wiring a new artifact class into install paths but not update/remove/prune leaves it stale or orphaned on the refresh path (#533: update refreshed skill bodies while the shipped plugin kept injecting old rules). Rule: enumerate add/update/remove/prune up front; refresh from manifest record ∪ current edges filtered to receiving targets.

### Advisory visibility checks must not run at full-catalog scale

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/advisory-check-full-catalog-noise.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: checkStrictAllowlist warns per hidden skill with a JSON rule suggestion. Against the deployed default lean profile (deny-all + 46 allows of ~148 shipped skills) every `setup.sh --yes` redeploy and every `npx update` prints a 100+ line warning whose advice (paste allow rules / --permit) contradicts the lean-profile design — the deploy re-applies lean right after. Gate per-item advisory checks on pa

### A bare mv beside run_cmd breaks the --dry-run contract

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/bare-mv-beside-run-cmd-breaks-dry-run.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: In the deploy scripts' config phase, every new filesystem mutation must route through `run_cmd` (bash) or an `if (-not $DryRun)` guard (PowerShell) — "preview all actions without making changes" is the documented contract (setup.sh:39). The legacy migrate block was the known leaky precedent NOT to copy. **Resolved 2026-09-21 (#506):** the bash migrate block is now `run_cmd`-wrapped (`deploy/setup.

### bats && -chained assertions only enforce the final link

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/bats-and-chain-assertions-mask-nonfinal-links.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: bats runs test bodies under `set -e`, but bash errexit exempts every command inside a `&&`/`||` list except the final one — an ordering pin `assert1 && assert2 && assert3` therefore enforces only assert3. Put each `[ ]` on its own line (bare mid-test assertions are fail-fast, per `bats-errexit-loop-failfast`), and make grep anchors unique to the target site: `if (Test-Path $ConfigFile) {` matched 

### Safety snapshot gated on a side-effect-created directory

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/conditional-backup-dead-path.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: BACKUP_DIR is created as a side effect of unrelated user choices (config-overwrite confirm, v1→v2 migration). A pre-clobber snapshot must `mkdir -p` its own target whenever there is content to snapshot — never depend on the backup dir already existing. In a `--yes` redeploy (the standard path) the gate skips the snapshot exactly when force-copy is about to overwrite local edits. Found in #379 revi

### Anti-pattern: explicit `permissions:` block + checkout without `contents: read`

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/explicit-permissions-block-checkout-403.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: An explicit `permissions:` block switches the job to explicit mode — every unlisted scope becomes `none`, and `actions/checkout` under `contents: none` fails with "Resource not accessible by integration" (403). Pair any scoped block whose job runs checkout with `contents: read`, and pin it in the workflow-shape bats test (#446 review; actions/labeler#870).

### Anti-pattern: regenerated artifact left unstaged after phase work

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/generated-artifact-unstaged-regen.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: `node installer/build-registry.mjs` writes `installer/registry.json` on disk; if the phase commit doesn't `git add` it, the branch ships main's stale registry while local gates pass (they read disk). #408 merged-state caught it only at code review — the reviewer's diff-alphabetical-skip noticed `installer/registry.json` missing between `pack-devops.json` and `opencode_app/README.md`.

### `gh api --paginate --jq` evaluates per page — aggregations count pages

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/gh-api-paginate-jq-per-page-aggregation.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: `gh api --paginate --jq '<aggregate>'` applies the jq template **once per response page** and concatenates the text output — it does not aggregate across pages. Expressions like `[.items[] | select(...)] | length` therefore emit one number per page; command substitution captures `"2\n1"` and the downstream `[ "$n" -gt 0 ]` fails with "integer expression expected" (silently taking the else branch).

### Anti-pattern: a global in-flight guard bleeds across sessions

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/global-in-flight-guard-cross-session-bleed.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: **Context**: #418 review round 2 — the auto-continue plugin's own-send echo guard used a single global counter; while a send to session A was in flight, the prompt hook dropped a *real* user message in session B, silently keeping B ESC-latched and its counter stale on a multi-session server.

### Legacy manifest upgrades must probe every on-disk target, not just the default

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/legacy-upgrade-target-probe.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: A legacy manifest that recorded names but not per-target state loses the target set on upgrade. Synthesizing `entries` from only the default target silently stops maintaining the other targets: `update` never re-copies or prunes them (stale forever), while `remove`/`--prune` still delete them — inconsistent lifecycle. Upgrade loops must existsSync-probe every known target dir and record what they 

### Anti-pattern: merge-resolved JSON duplicate keys pass every lenient gate

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/merge-resolved-json-duplicate-keys-pass-lenient-gates.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: Resolving a merge conflict by deleting one side's line can duplicate the neighbor line; JSON parsers last-win, so bats + `--check` stay green while a future single-copy edit gets silently shadowed.

### Parking/renaming a runtime-READ config file needs a conflict guard

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/park-read-config-file-needs-conflict-guard.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Parking/renaming a config file the runtime actively READS (`opencode.jsonc`) has different safety semantics than parking one it ignores (`config.json`): an unconditional rename can silently disable a user's sole live config. Require a both-exist guard (or prompt), and scope the invariant to the script's END STATE — the resolver also writes `opencode.json` in apply mode (decline-copy path, `--model

### Partial version-normalization sweep leaves display sites lying

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/partial-version-normalization-sweep.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: When a binary's version banner format differs from a bare semver, a normalization fix that touches only the compare sites is a partial sweep: every consumer of the string — comparisons AND display/summary interpolation — must route through one shared normalizer, or display sites print raw banners and, for format-crossing upgrades (v1 bare vs v2 prefixed), can mislabel which package is actually ins

### Anti-pattern: profile-membership breaks count arithmetic

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/profile-membership-breaks-count-arithmetic.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: Before writing a N→N−k target for a profile/count in a plan, grep which arrays actually contain each removed key — do not infer from one surface.

### pty streaming semantics unportable to background exit

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/pty-streaming-semantics-unportable-to-background-exit.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: Rewriting PTY-era prompts onto v2 `background: true` without redesigning the event model yields unexecutable instructions — a never-exiting watcher produces exactly one notification (at exit) with no stream-read/kill API; map to per-run exiting background commands, long-runners only as out-of-band servers (#507) — original context:sistent `--ui` watch runner started with `background: true`, plus sentinel-file early-stop. Verified against opencode.ai/v2/docs/tools: a background command notifies the session ONCE, when it finishes; a watcher that never exits never notifies; there is no stream-read of a running command and no kill API.

### token enumeration ac greps miss concept mentions

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/token-enumeration-ac-greps-miss-concept-mentions.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: Vocabulary-migration AC greps that enumerate retired API token names go green while concept-level prose mentions survive — grep the concept word case-insensitively with word boundaries (`\bpty\b`; bare `pty_` false-positives on `empty_*`) (#507) — original context:n|pty_read|pty_write|pty_kill|notifyOnExit`) and passed, while `skills/plan-execution-skill/SKILL.md:83` still taught the concept in prose ("PTY loop"); only the code review's concept-level sweep caught it.

### Anti-pattern: YAML guard via adjacency grep assumes key order and quoting

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/yaml-guard-adjacency-grep.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: `grep -A1 "resource: X" | grep "effect: allow"` guards miss effect-before-resource ordering, unquoted resource values, and broader-glob allows. Scan per-rule blocks bounded by `- action:` and test action+effect flags at block close — see `tests/test_reviewer_no_writes.bats` (#445 review).

### doc commands teach explicit timeout when bound exceeds default

- **Category**: convention
- **File**: `LEARNINGS/conventions/doc-commands-teach-explicit-timeout-when-bound-exceeds-default.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: v2 foreground shell defaults to 120000 ms; doc'd commands whose own bound exceeds it get harness-killed before their internal limit unless the doc names an explicit `timeout` ≥ the bound or runs the command as a background command (#507) — original context:` run verbatim in the foreground; the v2 shell's 2-minute foreground default harness-kills it long before its own bound on slow or 4K downloads.

### Decision: Adaptive review drops proactive requirements review; gaps flow via Mode R relay

- **Category**: decision
- **File**: `LEARNINGS/decisions/adaptive-review-requirements-relay.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: Worktree-pipeline Step 7 selects reviewers by blast-radius only (no proactive requirements review); uiux gained a required Requirements Gaps field; surfaced gaps relay to requirements-specialist Mode R; Step 1 preflight guards per-skill installs (2026-09-18).

### Decision: MCP Availability Guard single-homed at jira-git-integration-skill

- **Category**: decision
- **File**: `LEARNINGS/decisions/mcp-guard-single-homed.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: Policy text lives only in `jira-git-integration-skill` §MCP Availability Guard; per-skill copies are pointer + their own REST endpoint, headings frozen verbatim (#434).

### Decision: reviewer subagents return LEARNINGS candidates as content

- **Category**: decision
- **File**: `LEARNINGS/decisions/reviewer-learnings-return-as-content.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: Reviewer subagents hold no edit permissions — they emit `LEARNINGS candidates:` blocks (Category/File/Confidence/Scope/Summary/Date) and the pipeline orchestrator writes files, appends _index.md, and commits in the worktree (#445 single-writer rule).

### v1-to-v2 CLI migration must uninstall before install

- **Category**: decision
- **File**: `LEARNINGS/decisions/v1-to-v2-migrate-uninstall-before-install.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: The v1 npm package `opencode-ai` (frozen 1.18.31) and the v2 scoped package `@opencode/cli` both provide the `opencode` bin; installing v2 over a package-managed v1 leaves the shared bin link shadowed or broken (npm owns bin links per package — uninstalling the stale one afterward can remove the link v2 needs). The official order (opencode.ai/v2 migrate-v1: "Remove a package-managed V1 installatio

### bats structure pin: grep line-ordering test for shell call ordering

- **Category**: pattern
- **File**: `LEARNINGS/patterns/bats-structure-pin-call-order.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: When a refactor's correctness rests on call ORDER inside a 4k-line shell script (lift must see pre-overwrite agents; CLI owns agent files before config-only resolve), pin it with a bats test: `grep -n` each anchor (exact indentation to disambiguate call sites), assert line numbers ascending, and negatively grep the removed pattern. Cheap, review-anchored, and survives future edits. Established in 

### Pattern: jq @tsv needs sentinels for nullable columns

- **Category**: pattern
- **File**: `LEARNINGS/patterns/jq-tsv-sentinel-for-nullable-columns.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: `jq @tsv` output parsed with `IFS=$'\t' read` collapses empty cells — tab is IFS whitespace, so a null field shifts every later column left. Emit a sentinel for nullable columns in the jq program (`// "false"`) and rely on positional parsing only for never-null enum fields (#446 conflict labeler).

### Pattern: skill-dir consolidation trips count literals everywhere

- **Category**: pattern
- **File**: `LEARNINGS/patterns/skill-dir-consolidation-count-literals.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: Consolidating/removing skill dirs breaks literal-count assertions far beyond the registry — and `package.json` scripts is `{}` in this repo, so plans must name gates explicitly.

### Credential-regex host:port false-positive

- **Category**: solution
- **File**: `LEARNINGS/solutions/credential-regex-host-port-false-positive.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: The URL-credential regex `://[^:\s]+:[^@\s]+@` — recommended to catch `user:pass@host` connection strings — **cannot distinguish `user:pass@host` (credential) from `host:port@path` (port + @-route)**. It matches any `scheme://X:Y@` where X has no colon and Y has no `@`.

### docling-mcp-server defaults to streamable-http, not stdio

- **Category**: solution
- **File**: `LEARNINGS/solutions/docling-mcp-defaults-to-http.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: `docling-mcp-server` (PyPI `docling-mcp[local]`) defaults to `--transport streamable-http` — it starts a uvicorn HTTP app and never speaks stdio. OpenCode (`type: "local"`, stdio) gets silence and reports `MCP error -32000: Connection closed`, even though the binary spawns cleanly. Fix: `command: ["docling-mcp-server", "--transport", "stdio"]`. Also: its pip install needs `--break-system-packages`

### ERR-trap interpolations need nounset defaults — a crashing handler masks the real rc

- **Category**: solution
- **File**: `LEARNINGS/solutions/err-trap-interpolations-need-nounset-defaults.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: **Audit rule for new traps**: every variable interpolated in a trap *action* string gets a nounset default (`:-`), because a trap can fire in contexts with a different variable universe than the authoring site — and a handler that crashes converts any non-zero into 127, masking the real return code. Prefer degrading the diagnostic (`line 0`) over rc masking. Related but distinct: `unguarded-empty-

### plugin tool input frozen v2011

- **Category**: solution
- **File**: `LEARNINGS/solutions/plugin-tool-input-frozen-v2011.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: **Context**: After the 2026-09-20 opencode 2.0.11 upgrade, EVERY `question` call failed with `Attempted to assign to readonly property` before any part was created — the whole prompt layer was dead (`/goal`, pipelines, intake). DB forensics showed zero question parts since the upgrade date.

### Redocly `operation-description` is OFF by default in `recommended`

- **Category**: solution
- **File**: `LEARNINGS/solutions/redocly-operation-description-off-by-default.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: "Redocly's default `recommended` ruleset already enforces `operation-description` as an error."

### tsoa response examples: `@Example()` decorator, not `@example` JSDoc

- **Category**: solution
- **File**: `LEARNINGS/solutions/tsoa-response-example-decorator-not-jsdoc.md`
- **Confidence**: n.a.
- **Scope**: project
- **Summary**: tsoa has **two** different example mechanisms that are easy to conflate:

### Dead functions kept alive by their own tests

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/dead-function-kept-alive-by-its-tests.md`
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: deploy_skills_only had zero production callers after #470's plan model (the build_plan skills-only branch calls the individual steps directly), but its parity tests still passed — they pinned the wrapper, not the live path. The de-bloat ticket nearly shipped a corpse guarded by green tests.

### A derived summary tuple must be self-consistent — arithmetic and derivation semantics

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/derived-summary-tuple-must-be-self-consistent.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: PLAN-506's AC stated "146 shipped / 107 full allows / 70 lean / 36 hidden vs full". The tuple fails its own arithmetic (107−70=37, not 36) because the derivation command (`grep -c '"action": "skill"'`) counts the deny-all rule at `opencode_app/opencode.json:29-31` — raw rule count 107, allow-effect rules 106, and only 106−70=36 matches the AC's own "hidden" claim. Two count surfaces, one vocabular

### Anti-pattern: done-when gate escapes its phase

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/done-when-gate-escapes-its-phase.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: A done-when gate whose pass condition depends on edits scheduled in a *later* phase is unsatisfiable at its own step and forces either early cross-phase edits or gate rot.

### Anti-pattern: idempotency probe version-blindness defeats the pin-bump ritual

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/idempotency-probe-version-blind.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: `pip show <pkg>` + import probes skip the install for ANY installed version, so pin bumps never propagate to working installs — the probe only heals broken installs. The retired `--force-reinstall` flow converged to the pin; the probe does not.

### Invariant scope: quantifier must match the loop it lives in

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/invariant-scope-quantifier-vs-per-phase-loop.md`
- **Confidence**: 0.75
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: plan-execution 4c stated "The pushed SHA must carry a green `tier=full` memo" inside a per-phase loop whose 4f/4g push every iteration — light-gate phases legitimately produce only `tier=light` memos (code review #488).

### A dry-run leak test asserting only exit 0 has no teeth

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/leak-test-asserts-exit-only.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: `select_dry_run_with_preseeded_plan_writes_nothing` asserted only `[ "$status" -eq 0 ]`. Walking it against the unfixed code: the child CLI (init.mjs add) has no TTY guard on the add path, so without the --dry-run forwarding it really installs and STILL exits 0 — the test passed on the exact regression it existed to catch.

### Steps that shell out to child CLIs inherit no dry-run behavior

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/new-steps-calling-child-clis-inherit-no-dry-run.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: The #473 select-consumption step ran `node init.mjs add <name>` with no DRY_RUN handling — run_plan executes steps verbatim in dry-run, so a `--select --dry-run` preview installed skills/agents into the user's live config. run_cmd (the usual dry-safe wrapper) does not apply to child CLI invocations.

### Anti-pattern: PLAN consumer-map row without an owning step

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/plan-consumer-map-row-without-step.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: A Dependency & Consumer Map row that names a consumer but maps to no implementation step is a silent coverage hole.

### Steps appended to one build_plan branch vanish when main rebuilds the plan

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/plan-rebuild-drops-non-mode-side-steps.md`
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: The #474 load-preset step was appended only in build_plan's full branch, but main rebuilds the plan after the headless no-TTY default flips SKILLS_ONLY — the rebuild re-derives steps from flags alone, so `--preset foo` was silently ignored on headless runs.

### Plugin pickers filtering by filename prefix drop companion files the plugin needs

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/provenance-pin-single-source-false-green.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: Two #473 pins were false greens: the provenance pin used ONE direct choice (a single solo entry cannot expose the attribution bug), and the driver "equivalence" pin compared only the lengths of an EMPTY selection — while tui.mjs's header claimed "equivalence is test-pinned".

### Attribution loops must test membership in the per-source closure, not the union pool

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/solo-closure-attribution-tested-the-union-pool.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: The #473 picker's provenance loop checked `pool.includes(name)` where `pool` was the full combined closure — tautologically true for every item being mapped, so every locked dependency was credited to the first solo entry in insertion order, `locked-by:transitive` was unreachable, and the persisted plan misrecorded who required what whenever more than one thing was selected.

### A repoint sweep derived from an audited-file list misses grep-derived sibling consumers

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/sweep-set-from-audit-list-misses-grep-derived-consumers.md`
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: When a path move (or rename) makes old strings dead, derive the repoint sweep from `grep -rn "<old-path-string>"` across all file types — every hit is either repointed or explicitly exempted with a dated note. An audit list is a lower bound, not the universe: sibling consumers cite the same dead paths and are found only by the string, not by the list. Gate the sweep on the same grep returning zero

### A thin launcher with a syntax error passes every textual delegation pin

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/thin-launcher-syntax-error-passes-text-pins.md`
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: The #474 ps1 rewrite left a stray `}` plus a duplicated tail (an edit artifact of a partial-block replacement). The file was unparseable PowerShell — it would have died before param() binding on every Windows invocation — yet all 486 bats pins stayed green, because every ps1 pin is a textual grep and CI has no pwsh to parse with.

### First unguarded empty-array `${arr[@]}` crashes stock macOS bash 3.2 under nounset

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/unguarded-empty-array-under-nounset-bash32.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: `local dry_args=(); … "${dry_args[@]}"` under `set -o nounset`: bash < 4.4 (macOS stock /bin/bash 3.2.57) treats the expansion of an EMPTY declared array as unbound — real (non-dry) `--select` runs crash on macOS while dry-run (non-empty) and Linux CI (bash 5) stay green.

### Tests that execute setup.sh end-to-end need a mktemp HOME, not just source-pins

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/xdg-data-home-punches-through-home-sandboxes.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: Credential-seeding tests sandboxed `HOME` into a temp dir, yet on machines exporting `XDG_DATA_HOME` they wrote `new-provider` entries into the developer's REAL `~/.local/share/opencode/auth.json` (setup.sh resolves the auth path via `${XDG_DATA_HOME:-$HOME/.local/share}`), and assertions read the untouched sandbox copy — red per-environment, not per-change.

### A zero-reference gate must census where the string lives and exclude itself

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/zero-reference-gate-must-census-and-self-exclude.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: A "zero references to the removed slugs" gate grepped only `--include="*.md" --include="*.bats" --include="*.mjs"`. It missed the two real consumers — `opencode_app/Dockerfile:63` (extensionless) and `opencode_app/docker-entrypoint.sh:132` (`*.sh`) — and it matched the PLAN document itself, which quotes the slugs it bans. The gate could never exit clean while simultaneously certifying a hole it ex

### A launcher that hands Windows users into bash needs .gitattributes EOL pins

- **Category**: convention
- **File**: `LEARNINGS/conventions/delegation-launcher-needs-eol-attributes.md`
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: A default Git-for-Windows clone (core.autocrlf=true) checks out shell scripts with CRLF; bash dies on `$'\r'`. The old native ps1 never ran bash; the #474 thin launcher does. Any repo whose Windows entrypoint delegates into bash must ship `*.sh text eol=lf` in .gitattributes (and `*.ps1 text eol=crlf`).

### New ONLY-mode flag must extend validate_mode_conflicts in both lists

- **Category**: convention
- **File**: `LEARNINGS/conventions/new-plan-mode-wires-mode-conflict-validator.md`
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: Adding an ONLY-mode flag to setup.sh requires ALL of: defaults block entry, parser arm, conflict validator registration in BOTH lists (modes exclusivity + enable-pack packless), build_plan branch, mode completion case, both help surfaces, wiring pins. Missing the validator lets the build_plan elif chain silently swallow any combined mode (`--check-catalog --skills-only` ran only the check, exit 0)

### Bats tests mutating shipped artifacts: snapshot/restore + private fixture copies

- **Category**: pattern
- **File**: `LEARNINGS/patterns/bats-mutating-shipped-artifacts-snapshot-and-isolate.md`
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: Bats tests that mutate a shipped file snapshot/restore it in setup()/teardown (cp to a mktemp path — a fixed /tmp name serializes future --jobs runs), and fixture mutations go through a PRIVATE mktemp copy. #472's drop-fatal test deleted a provider from the SHARED fixture and poisoned the three tests after it — every one of them failed for a reason unrelated to its own assertion.

### Format-token census classifies deferral-by-name as verified-compatible

- **Category**: pattern
- **File**: `LEARNINGS/patterns/format-token-census-deferral-classification.md`
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: A canonical-format change's blast radius = literal-token census (`GATE <sha>`, `lint=t`): grep every restating site for the tokens, then classify each hit update/no-change. Surfaces that defer by name only zero-hit *by design* and take the "verified compatible" classification — never invent changes for them. Name deliberate exclusions (immutable history dirs) in the census record itself.

### inline question payload specs at prose sites

- **Category**: pattern
- **File**: `LEARNINGS/patterns/inline-question-payload-specs-at-prose-sites.md`
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: embed verbatim `question`-tool payload JSON (all four levels: `questions[]` wrapper, `question`+`header`+`multiple:false`, `options[]` with `label` AND `description`) at every prose-only prompt site — #448's audit found 7/1158 schema failures, all missing-required-field from freehand construction; enumerate every placeholder the model must instantiate and cap option lists so instantiation + decline stays within the 2-4 option hygiene bound; duplication across skills is intentional per #437, never extract it (#504)

### Transient cross-file contract drift between per-phase commits is safe iff pinned

- **Category**: pattern
- **File**: `LEARNINGS/patterns/phased-canonical-contract-drift-window.md`
- **Confidence**: 0.7
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: Editing a canonical contract and its deferring consumers in separate per-phase commits creates a window where the consumer restates the stale format (e.g. tierless memo after Phase 1, before Phase 2). The window is safe iff (a) the stale surface already points at the canonical by name and (b) no test pins the stale example — pre-verify both before relying on it; do not "fix" by reordering phases.

### Solution: markitdown-mcp upstream facts (alpha pin, co-install, residual)

- **Category**: solution
- **File**: `LEARNINGS/solutions/markitdown-mcp-alpha-pin-upstream-facts.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: Upstream markitdown-mcp publishes only alphas (latest 0.0.1a7) — exact pin installs without --pre; requires markitdown[all] + mcp>=2.1.1,<3; coexists with docling-mcp 3.x on mcp 2.x; stdio default; bump ritual spans 2 files (deploy/setup.sh + opencode_app/Dockerfile; ps1 thin since #474)

### Merge writers must back up unparseable user JSON, never reset to {}

- **Category**: solution
- **File**: `LEARNINGS/solutions/merge-writers-backup-on-parse-failure.md`
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: `register_provider_auth` merges one key into the user's auth.json. The inherited pattern reset `auth = {}` on any parse failure (FileNotFoundError AND ValueError alike) — so a half-written auth.json got replaced by a one-entry file, silently destroying every stored provider key.

### readJsonMaybe tolerates only "$comment" lines — doc claims of JSONC stripping are false

- **Category**: solution
- **File**: `LEARNINGS/solutions/readjsonmaybe-strict-json-jsonc-claims.md`
- **Confidence**: high
- **Scope**: project
- **Date**: 2026-09-21
- **Summary**: Two ticket PLANs (#470-era, #491) claimed `readJsonMaybe` strips JSONC comments so commented configs patch cleanly. Reality: `stripJsonComments` (resolve-models.mjs:80-83) removes only `"$comment":` lines; a `//`-commented opencode.json throws at :75 BEFORE any write (writes happen at :400+) — loud failure, no partial state, but not the tolerance the docs promised.

### Fix-round PLAN sync stopped at the AC block — Technical Notes and gate trace left stale

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/plan-fix-round-ac-only-sync.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20 (#448 re-review, fix round 1)
- **Summary**: When a review/Mode-R fix round changes shipped behavior, the fixer syncs the PLAN's Acceptance Criteria (amended AC text, ticked) but leaves the plan-body restatements alone. In #448 the drop rule changed from "items with no usable `options` array are dropped" to "keep with `options: []`" — the plugin header comment, code, and tests were all updated, and the AC was amended, yet `PLANS/PLAN-448.md`

### Uncoordinated `execute.before` writers on `event.input` — vibeguard restore vs. plugin payload rewrites

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/concurrent-execute-before-writers-event-input.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20 (#448 plan review)
- **Summary**: Every local plugin that hooks `ctx.tool.hook('execute.before')` becomes a **concurrent writer** on the same `event.input` field, with ordering decided by plugin glob order (an implementation detail, currently alphabetical). `plugins/vibeguard.ts:490-496` registers an unguarded (all-tools) hook that mutates `event.input` **in place** (`restoreDeep`) to unmask `__VG_…__` placeholders before executio

### `setup.sh --dry-run` under non-interactive stdin takes the skills-only path — plugin deploy is never previewed

- **Category**: solution
- **File**: `LEARNINGS/solutions/setup-sh-dry-run-menu-skips-plugin-deploy.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-20 (#448 plan review)
- **Summary**: `./deploy/setup.sh --dry-run` run headless (stdin at EOF, e.g. `</dev/null` in CI) resolves the interactive menu to Skills-Only Setup: the flow exits via "Skills deployment complete!" and **never calls `deploy_plugins()`** (deploy/setup.sh:4303) — zero `[DRY-RUN] Would execute: cp -r …/plugins/` lines are printed, yet the script still exits 0. A dry-run gate grepping for a plugin copy line false-f

### Env-prefix sandboxing of globals a sourced script reassigns is clobbered

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/colon-plus-on-boolean-string-flags.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: `node … update ${DRY_RUN:+--dry-run}` looked like a clean dry-run gate, but `DRY_RUN` is the *string* `"false"` when unset-flagged (setup.sh:326) — non-empty, so `:+` expanded on every run. Real `--models-only` deploys silently became permanent previews: the resolver applied, the manifest update printed its dry JSON and changed nothing, and the script still said "Model resolution complete!".

### AC cross-references must resolve to a real artifact

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/dangling-cross-reference-in-ac.md`
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: PLAN-470's AC delegated full/quick/single-step step lists to "the table in Technical Notes" — no such table existed (Technical Notes held only a criticality list). Per-step atomicity checks (Why/Done-when/Consumers all present) passed while the AC pointed at a nonexistent artifact, leaving pin authoring (1.6) with unspecified expected values.

### Delta derived from a single surface duplicates entries in the other

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/delta-derived-from-single-surface.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Changes landing in two arrays with different memberships (full allowlist vs lean profile) need the delta computed against EACH surface — a single-surface delta silently duplicates entries while subset/typo guards stay green (#481 plan review).

### Directory-scoped rename sweeps miss repo-root docs that teach the spelling

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/directory-scoped-rename-sweep-misses-root-docs.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Frontmatter-vocabulary sweeps scoped to code dirs skip README/opencode_app teaching sites, and literal `action: task` greps pass vacuously over `action:"task"` — sweep repo-root *.md + opencode_app/ with form-insensitive patterns and named exclusions (#482).

### Dry-run preview logs must not interpolate secret values

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/dry-run-logs-interpolating-secrets.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: A new DRY_RUN gate logged `Would set ${key}=${value} via setx` — for the API-key variable that puts the full key into terminal scrollback and CI transcripts on every preview run. The script's house convention redacts: first8/last4 (:1958) or name-only with "(value suppressed)".

### Embedded diff hunks + a path claim are untrusted — reviewer probes .git/HEAD first

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/embedded-diff-hunks-unverifiable-probe-git-head-first.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Review prompts embedding diff hunks plus a worktree path can name the wrong tree — the reviewer's first act is a no-shell branch probe (.git/HEAD + one hunk spot-check); on mismatch fail fast with probe evidence (#482 Step 9).

### Guard error branches need negative fixtures in the same change

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/guard-error-branches-need-negative-fixtures.md`
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: A review fix added two fail-loudly branches to the #468 pin checker (non-object preset entry, missing `.primary`). Their correctness was proven by a manual one-off run; the committed fixture still exercised only the membership branch — so both new branches were silently deletable while the suite stayed green.

### Negated assertions are errexit-exempt — they can never fail a bats test

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/node-e-argv-has-no-script-name-slot.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: A bats test passed `node -e "$SCRIPT" "$A" "$B"` with a checker that read `process.argv.slice(2)`. Under `node -e`, argv is `[execPath, ...args]` — there is no script-name slot like `node file.js` has. slice(2) dropped the first real argument and shifted the rest; one test threw (ERR_INVALID_ARG_TYPE) while a sibling test PASSED on meaningless shifted inputs — a false green, not a crash.

### Partial record refresh contradicts itself

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/partial-record-refresh-contradicts-itself.md`
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Refreshing a decision record's header/update-block while leaving body counts stale creates in-file contradictions — refresh every count in the same edit or freeze the body behind a dated historical label (#481 review).

### Plan step functions must return, never exit

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/plan-step-functions-must-return.md`
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: `setup_zai_api_key` (a NON-critical plan step) still ended an invalid/declined key with `exit 1`. Under the #470 executor that bypassed the uniform epilogue (no zip backup, no summary) and turned a warn-and-continue into a hard mid- deploy failure — deterministic for headless `-y` with no `ZAI_API_KEY` (EOF → invalid → decline default).

### Prefix-keyed guards silently exempt every unknown shape

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/prefix-keyed-guard-silent-exemption.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Two generations of the same bug: (1) the #281 deploy guard validated only `zai*` prefixes, so the broken anthropic `claude-haiku-4-6` pin shipped unnoticed; (2) the pin test written to fix it skipped preset entries without `.primary`, so a future shape change (renamed key, wrong nesting) would escape both coverage and pin checks with a fully green suite.

### Two artifact surfaces, one count vocabulary — every count names its surface

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/two-surface-count-conflation.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Root skills/ vs opencode_app/.opencode/skills — single-surface derivations mint phantoms and duplicate deltas; fix = union guard (SKILL.md-filtered) + disjointness assert + surface-explicit counts; dated narratives keep period-true numbers (#486).

### Unified dispatch swallows per-mode preconditions

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/unified-dispatch-swallows-per-mode-preconditions.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Collapsing setup.sh's six mode branches into one planner/executor nearly shipped three regressions at once: skills-only (documented as the offline/headless escape path) would have gained the network check and menu gate it never had; its hidden `check_dependencies` precondition vanished from the step list; models-only/migrate-only lost their node-presence gates.

### v1 frontmatter action names are inert under opencode v2 — rename and probe with a matrix

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/v1-action-names-inert-under-v2.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Agent frontmatter `action: bash`/`action: task` rules do nothing on opencode v2 (actions are `shell`/`subagent`) — a v1 deny leaves the tool executable; the rename restores enforcement, licensed only by the 2×2 probe matrix (#482).

### `blocked-by:` format has one parser, multiple producers

- **Category**: convention
- **File**: `LEARNINGS/conventions/blocked-by-format-single-home.md`
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: The `blocked-by: <ref>` issue-body line has **one parser** — `worktree-pipeline-skill` Step 1's skip-guard (whole-body scan, ticket regex `^(#\d+|[\w.-]+/[\w.-]+#\d+|[A-Z][A-Z0-9]+-\d+)$`) — and **two producers**: `ticket-creation-skill` (Step 4b, this convention's origin) and `wayfinder-skill`. Producers restate the format minimally and point at the parser's rule (`policy-single-home-pointer-shap

### Recount claimed structural counts in PLANs — an unnamed element is an unrecorded scope decision

- **Category**: convention
- **File**: `LEARNINGS/conventions/plan-counted-structural-removals-recount.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: PLAN-470 said "remove the six early-exit blocks"; main() has seven. The uncounted seventh (`--check-update`, setup.sh:4301-4304) carries the exact defect the ticket exists to kill — `check_for_updates_only` returns 1 on real failures (:3830/:3840) while the caller exits 0 unconditionally — and would have survived outside the truthful-exit contract.

### Structure-pinning tests are first-class consumers for any refactor PLAN

- **Category**: convention
- **File**: `LEARNINGS/conventions/structure-pinning-tests-are-map-consumers.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: PLAN-470's Dependency & Consumer Map listed runtime consumers only — and missed three bats files that awk/grep the SOURCE SHAPE of functions: test_skills_only_parity.bats (function-body extraction), test_dry_run_leaks.bats (literal gate-string pins), deploy_delegate.bats (first-occurrence line-order pin). Executing the refactor as planned would have red-gated CI midway and tempted a "fix" that del

### Decision: two skill surfaces — root deployable + Docker-app project-scoped

- **Category**: decision
- **File**: `LEARNINGS/decisions/app-scoped-skill-surface.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Keep both skill surfaces: root skills/ (deployable, 146 dirs) + opencode_app/.opencode/skills (Docker-app project-scoped: github-runners-setup-skill); union guard + disjointness assert enforce it; revisit = split the app config base if app skills grow (#486).

### Decline-config contract honored by omitting --config-src

- **Category**: decision
- **File**: `LEARNINGS/decisions/resolver-omit-config-src-preserve-contract.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: "Decline config overwrite" (SKIP_CONFIG_COPY=true) means the user's existing opencode.json wins: `run_resolver` omits `--config-src` and resolve-models bases its in-place patch on the existing file; execution-verified both directions (#470 D2; #491 update: presence-gated for --models-only/--migrate).

### The child skill gate follows the merged config, not the agent frontmatter

- **Category**: pattern
- **File**: `LEARNINGS/patterns/child-skill-gate-follows-merged-config.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Subagent skill loading resolves against merged config layers (global/project), not agent-frontmatter skill allows — config-layer allows are the working unlock while upstream #50149 stands (#481); includes the 3-step regression probe + revert-flip check.

### Conditionally-armed detectors need an always-armed complement

- **Category**: pattern
- **File**: `LEARNINGS/patterns/conditionally-armed-detectors-need-always-armed-twin.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: The #467 sandbox-escape detector (md5 of the worktree `.env` before/after a test run) only arms when that file exists — never in CI, where the worktree `.env` is absent. Paired with it, the positive control (real run MUST change sandbox bytes) is always armed and catches the same regression class in CI.

### Count-literal sweeps must include docs-of-record

- **Category**: pattern
- **File**: `LEARNINGS/patterns/count-sweeps-include-docs-of-record.md`
- **Confidence**: 0.75
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Count-drift sweeps must include LEARNINGS/ (docs-of-record), and docs-of-record should cite search anchors not file:line — line refs rot within weeks (#481 review).

### A fail-closed guard couples cross-file edits into one atomic unit

- **Category**: pattern
- **File**: `LEARNINGS/patterns/fail-closed-guard-couples-cross-file-edits.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Fail-closed cross-file guards (apply-skill-profile.mjs lean⊆full exit 1) name their atomic unit — the append, its source-file prerequisite, and their test-pinned mirrors ride one commit or per-push CI goes red (#481 plan review).

### Unconditional log_success after run_cmd overstates completion in dry-run

- **Category**: pattern
- **File**: `LEARNINGS/patterns/gate-success-log-with-the-dry-branch.md`
- **Confidence**: 0.8
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Unconditional log_success after run_cmd claims completion in dry-run — new gates use the run_cmd early-return shape (deploy/setup.sh:1117); legacy sites sweep into #470 (#469 review)

### Menu-case-to-flag extraction must re-derive the menu path's free preconditions

- **Category**: pattern
- **File**: `LEARNINGS/patterns/menu-case-to-flag-precondition-rederivation.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Giving PeonPing (menu option 5) a `--peonping` flag would silently drop two preconditions the menu path got for free: menu options run after main's `check_dependencies` AND the network check. Copying only the case body (`setup_peonping`) would have shipped a flag that fails differently offline.

### Permission-enforcement probes need a 2×2 matrix

- **Category**: pattern
- **File**: `LEARNINGS/patterns/permission-probe-2x2-matrix.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: Probing whether a permission rule enforces crosses rule-name version (v1 alias vs v2 native) × session shape (top-level vs child-spawn); only the v2-name × child-spawn cell licenses a "rename restores enforcement" claim (#482).

### Prompt EOF takes the default — headless safety hinges on gate defaults

- **Category**: pattern
- **File**: `LEARNINGS/patterns/prompt-eof-takes-default-headless.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: setup.sh's `prompt_user`/`prompt_yes_no` resolve EOF stdin (`read` with no TTY) to the declared default (`${result:-$default_value}`) — they never hang and never return junk. So the headless safety of any code path is decided entirely by what each gate prompt's default IS.

### Subagent briefs can misdescribe the subagent's own toolset — probe, don't trust

- **Category**: pattern
- **File**: `LEARNINGS/patterns/subagent-brief-may-misdescribe-own-tools.md`
- **Confidence**: 0.7
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: A parent brief may assert false runtime facts ("you have no shell") — the subagent probes one cheap tool call before degrading to read-only; on contradiction use the stronger capability and say so (#482 Step 9).

### set -E would arm the ERR trap inside plan steps — never add it while dispatch-by-call

- **Category**: solution
- **File**: `LEARNINGS/solutions/errtrace-would-arm-the-err-trap-inside-steps.md`
- **Confidence**: 0.75
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: setup.sh arms a global ERR trap (:487) but never sets `set -E`/errtrace, so the trap never fires inside functions. This is LOAD-BEARING for the #470 plan executor: `run_plan` dispatches steps as `if ! "$func"` and step functions deliberately `return 1` for warn-and-continue semantics.

### `gh issue edit --body` replaces — appending is fetch-then-write

- **Category**: solution
- **File**: `LEARNINGS/solutions/gh-issue-edit-body-replaces-not-appends.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-20
- **Summary**: `gh issue edit --body <text>` **replaces** the entire issue body — there is no append mode. Any instruction (skill text, agent runbook) that hints "append a line via `gh issue edit --body`" invites an agent literalizing it into clobbering the body, acceptance criteria included. The safe pattern is fetch-then-write:

### bats test bodies run under errexit — for-loop assertions are fail-fast

- **Category**: solution
- **File**: `LEARNINGS/solutions/bats-errexit-loop-failfast.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19 (#417 review)
- **Summary**: Review knee-jerk: a bats `for` loop whose body is a bare `grep -q` / `cmp -s` "only fails on the last iteration" — flag it as false-pass. False. bats-core executes each test body under `set -e`; any failing command inside the loop aborts the test immediately. The `run` helper exists precisely to capture failures without tripping errexit, and `!`-prefixed commands are exempt.

### Anti-pattern: normative rule added, in-file example left stale

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/rule-added-example-stale.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19 (#417 re-review)
- **Summary**: Adding a normative rule to a skill (e.g. title-prefix parity at `ticket-creation-skill/SKILL.md:148`) without updating the same file's Example Usage that illustrates the flow leaves the example teaching the deprecated behavior — examples are the strongest prompt signal agents copy. Genus of `heading-rename-syncs-quoted-pointers`: when a commit adds or changes a rule, sweep the file's own examples 

### build-registry plain run always rewrites generatedAt — "zero diff" done-whens must use --check

- **Category**: solution
- **File**: `LEARNINGS/solutions/build-registry-plain-run-churns-generatedat.md`
- **Confidence**: 1.0
- **Scope**: project
- **Date**: 2026-09-19 (#416 plan review)
- **Summary**: PLAN verification steps worded as "run `node installer/build-registry.mjs`; `git diff installer/registry.json` must be empty." This done-when can never pass literally, even when frontmatter is untouched.

### skill-add count sync blast radius — 8 surfaces, number-keyed ones hide from name-keyed sweeps

- **Category**: pattern
- **File**: `LEARNINGS/patterns/skill-add-count-sync-blast-radius.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-19 (#402 architecture review)
- **Summary**: Adding one skill touches EIGHT count surfaces, and they fail in two classes:

### docs/registry.json is a gitignored build-site artifact, never a build-registry output

- **Category**: solution
- **File**: `LEARNINGS/solutions/docs-registry-is-build-site-artifact.md`
- **Confidence**: 1.0
- **Scope**: project
- **Date**: 2026-09-19 (#402 architecture review)
- **Summary**: Plans/tickets ask for "`installer/registry.json` + `docs/registry.json` rebuilt via `build-registry.mjs`". The docs copy can never satisfy that: `build-registry.mjs` writes ONLY `installer/registry.json` (OUT_FILE, installer/build-registry.mjs:45).

### agentModel (init.mjs) and resolveAgent (resolve-models.mjs) are a precedence-parity pair

- **Category**: convention
- **File**: `LEARNINGS/conventions/agent-override-precedence-parity.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19 (#401 code review)
- **Summary**: `installer/init.mjs` `agentModel` (~:280) must mirror `installer/resolve-models.mjs` `resolveAgent` (~:205) at the two agent-overrides levels: project pin (`<project>/.opencode/agent-overrides.json`) > global pin (`~/.config/opencode/agent-overrides.json`)

### Case-sensitive / line-anchored grep gates false-green on file-tree prose

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/case-sensitive-grep-gates-false-green.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: PLAN-423's 3.5 reference gate reported "reference greps empty", yet `README.md:32` still documented the deleted symlink bridge: `├── .opencode/ # Symlink bridge → root content (local serve only)`.

### `git stash` exits 0 on "No local changes to save" — porcelain-gated STASHED flags lie

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/git-stash-nothing-to-save-exit-zero.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: `restart-opencode-docker.sh` fix round introduced:

### Guard-regex quote-shape mismatch false-greens on regression spellings

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/guard-regex-quote-shape-mismatch.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: `tests/test_skill_isolation.bats` test 2 passed its mutation canary yet missed 8/10 realistic regression spellings — including the exact pre-#437 lines (`parents[2] / "_common"`, `_SKILLS / "_common" / "scripts"`): the pattern required a segmented `"_"` token, but every historical line used the single-segment spelling `"_common"` (code-review #437, empirically run).

### Anti-pattern: Manifest claims a file the gate skipped

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/manifest-claims-skipped-file.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: **Context**: Conflict-gated writes whose manifest records path-claims unconditionally (built before the gate decides).

### mid rule yaml sequence insert

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/mid-rule-yaml-sequence-insert.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: **Context**: Adding a value-only rule to an agent frontmatter `permissions` array (PLAN-404, gh-cli-setup-skill allow rule).

### Anti-pattern: a validator must never crash on the input it exists to reject

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/validator-crashes-on-invalid-input.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: **Context**: #402 review — `spec_to_dxf.py` parallel/aligned constraint path called `math.dist` on unguarded `_point()` results and divided by line length without a zero guard; an invalid spec (malformed or zero-length line geometry referenced by a `parallel` constraint) raised TypeError/ZeroDivisionError before the validation report was emitted, breaking the "exit 1 + report, no traceback" contra

### Derive consistency pins from the source-of-truth file at runtime

- **Category**: convention
- **File**: `LEARNINGS/conventions/derived-consistency-pins.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: A test that pins two files to each other must derive its expectation from the source-of-truth file at runtime (grep HANDOFF_OWNER/HANDOFF_TARGET out of `tests/test_skill_isolation.bats`, as `tests/test_requires_skills.bats` does) — not restate the literals in both files (the `tests/test_docling_skill.bats` impliesMcp style). Derived pins turn drift into a hard test failure instead of two files agi

### Convention: Single-homed policy prose — copies are pointer + skill-specific only

- **Category**: convention
- **File**: `LEARNINGS/conventions/policy-single-home-pointer-shape.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: **Context**: #434 single-homed the MCP Availability Guard into `jira-git-integration-skill` (canonical); 6 other locations became pointers.

### new skill count literal gates

- **Category**: pattern
- **File**: `LEARNINGS/patterns/new-skill-count-literal-gates.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: **Context**: PLAN-404 review (new `gh-cli-setup-skill`). The obvious sync surfaces (registry rebuild, lean array, full-profile allow, README count+row) were planned; CI still would have gone red twice.

### Pattern: Per-phase commits must satisfy per-push CI gates — registry drift and test-pinned invariants need in-phase owners

- **Category**: pattern
- **File**: `LEARNINGS/patterns/phase-commit-ci-gate-ordering.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-19
- **Summary**: **Context**: PLAN-409 review. Plans executed by plan-automation-loop commit + push per phase, and CI (release.yml) runs the full bats suite plus `node installer/build-registry.mjs --check` on every push.

### Conditional-mode blocks must supersede all restatements, not just the numbered list

- **Category**: pattern
- **File**: `LEARNINGS/patterns/conditional-mode-blocks-supersede-all-restatements.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-18 (#399 architecture review)
- **Summary**: A conditional-mode block in an agent/skill body (e.g. "in pipeline mode, skip steps X/Y/Z") must explicitly supersede EVERY other restatement of the skipped steps in the file — non-numbered sections, delegation bullets, framework quality-checks sections, closing imperatives — and mark the list non-exhaustive ("e.g."). Otherwise the un-superseded clauses stay in force and the redundancy the mode wa

### Partial proceed-path beside a skip list

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/partial-proceed-path-beside-skip-list.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-18 (#399 Step 9 review)
- **Summary**: An explicit skip list plus a partial "proceed via" enumeration in the same instruction block leaves unnamed steps ambiguous for agent runtimes — each unnamed step resolves arbitrarily depending on which sentence the runtime obeys. Skip-path ∪ proceed-path must equal the full step list, or the unnamed steps must be explicitly dispositioned.

### A hand-rolled YAML-subset parser cannot read a shape richer than the shapes it was built for

- **Category**: solution
- **File**: `LEARNINGS/solutions/hand-rolled-yaml-parser-sequence-gap.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-17 (#380 plan review)
- **Summary**: `installer/build-registry.mjs` parseFrontmatter (:72-121) handles scalars and nested maps only. Any plan that rewrites frontmatter into YAML **sequences** (`- action:` rule lists) while touching only the downstream reader lines (:144-146) is unimplementable: the parser collapses a rules array into `{"- action": "...", resource: "...", effect: "..."}` (last rule survives, keys overwrite) and `fm.pe

### Anti-pattern: subagent review prompts with unexpanded `$(cat …)` + cwd on the wrong branch

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/unexpanded-cat-embedding-wrong-branch-cwd.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-17
- **Summary**: **Context**: #383 content-trim review spawn. The parent's prompt embedded 7 file bodies as literal `$(cat skills/…/SKILL.md)` — the substitution never executed. The subagent's cwd was on `main` (pre-trim side), the `feat/383` ref did not exist in that clone (not in `.git/packed-refs`, no loose ref, no `.git/worktrees/`, no copy under `/tmp/opencode`), and `bash:deny` blocked `git show`. Review cou

### frontmatter shape change blast radius

- **Category**: pattern
- **File**: `LEARNINGS/patterns/frontmatter-shape-change-blast-radius.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-17
- **Summary**: **Context**: Changing the frontmatter *format* of `agents/*.md` (e.g. #380 `permission:` map → `permissions:` array), as opposed to changing a value.

### Pattern: Skill-content trim with verbatim preservation (the #383 recipe)

- **Category**: pattern
- **File**: `LEARNINGS/patterns/skill-trim-verbatim-preservation.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-17
- **Summary**: **Context**: 93% content cut across 51 SKILL.md files (issue #383) under the rule "a skill encodes only what is house-specific: triggers, conventions, version-pinned facts, workflow contracts, codified learnings".

### Literal-only stale-path greps miss variable indirection

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/literal-only-path-sweep-misses-variable-indirection.md`
- **Confidence**: 0.95
- **Scope**: project
- **Date**: 2026-09-15
- **Summary**: Path-move sweeps that grep only literal `deploy/<file>` strings miss references built from shell variables. #378 moved `provider-models.json` to `installer/` but `deploy/setup.sh:3008` read it as `${DEPLOY_DIR}/provider-models.json` — every PLAN grep gate returned 0 while the `-f` presence test silently flipped to skip, disabling the exposed-model guard on Linux/macOS (the ps1 mirror at `setup.ps1:1884` WAS repointed → platform divergence). When auditing a move, enumerate every variable that resolves into the moved dir (`DEPLOY_DIR`, `$DeployDir`, `Join-Path $DeployDir …`) and grep uses of THAT variable too, not just literal paths.

### doc claims match plugin defaults

- **Category**: convention
- **File**: `LEARNINGS/conventions/doc-claims-match-plugin-defaults.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-15
- **Summary**: **Context**: Code review of #382 flagged that `plan-automation-loop-skill` claimed the goal plugin "enforces turn/token/duration limits" — but the plugin ships `default_token_budget` and `max_goal_duration_seconds` **unset**, so with the repo's no-options config only turn limits (`max_auto_turns: 25`), no-progress pause, the prompt-failure ceiling, and Plan-mode locks are actually enforced.

### Convention: Heading renames must sync quoted § pointers

- **Category**: convention
- **File**: `LEARNINGS/conventions/heading-rename-syncs-quoted-pointers.md`
- **Confidence**: 0.87
- **Scope**: project
- **Date**: 2026-09-15
- **Summary**: **Context**: Commit renamed a MIGRATION.md heading to add a ticket ref ("(#385)") and missed the verbatim quoted-title pointer in an agent file.

### Verified-stamp docs must cite every actionable claim

- **Category**: convention
- **File**: `LEARNINGS/conventions/verified-doc-claims-need-citations.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-15
- **Summary**: In any doc section stamped "Verified against <source>", every actionable command, env var, and config field path must trace to that source — or carry its own citation or explicit inference/unverified label at EACH occurrence, not only where the claim first drives a recommendation. #385 review: the cache-inference was labeled in the ranked-levers list but restated as bare fact under "Why v2 dropped

### goal plugin v2 readoption

- **Category**: decision
- **File**: `LEARNINGS/decisions/goal-plugin-v2-readoption.md`
- **Confidence**: 0.85
- **Scope**: project
- **Date**: 2026-09-14
- **Summary**: plugins: ["@prevalentware/opencode-goal-plugin@^0.1.48"] — caret pin (v1 breakage was v1-only versions under v2 runtime, not pinning), no options (secure defaults), no commands.goal block (v2 self-registers); wejick/opencode-goal rejected; #387 resolved — v2 binary + authenticated goal-presence healthcheck (see the file's Docker note)

### Path-move restructure: anchor CI tarball gates, verify search-path consumers

- **Category**: solution
- **File**: `LEARNINGS/solutions/path-move-ci-gate-anchoring.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-09-14
- **Summary**: Path moves (#381): anchor CI `npm pack` grep gates to package-root paths (substring matches false-green); config files consumed via search-path chains (plugins/opencode-vibeguard-v2.ts + vibeguard.config.json) need bridge symlink / explicit COPY per runtime

### permission.task delegate changes — 4 sync surfaces + delegate ceiling check

- **Category**: convention
- **File**: `LEARNINGS/conventions/task-delegate-permission-sync.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-08-27 (GIT-350 review)
- **Summary**: Adding/removing a `permission.task` allow entry on an agent touches FOUR surfaces. A diff that updates only some of them is partially stale by construction:

### tier model swap blast radius

- **Category**: pattern
- **File**: `LEARNINGS/patterns/tier-model-swap-blast-radius.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-08-27
- **Summary**: **Context**: When swapping a model pinned to an agent tier in this repo (models.default.json / provider-presets.json)

### skill permission allowlist

- **Category**: decision
- **File**: `LEARNINGS/decisions/skill-permission-allowlist.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-08-14
- **Summary**: Ship a permissions deny-all-first allowlist in opencode_app/opencode.json (full = 106 allow rules, one of them app-scoped) + deploy/skill-profiles.json lean (70); --skill-profile lean|full rewrites only action:"skill" rules at deploy time. Post-#481: reviewer skill union is config-allowed (upstream #50149 ignores frontmatter skill allows in child sessions) — 146 shipped / 106 full allows / 70 lean / 36 hidden vs full; counts re-derive from disk before citing.

### jsonc comments in opencode json

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/jsonc-comments-in-opencode-json.md`
- **Confidence**: 0.9
- **Scope**: project
- **Date**: 2026-07-26
- **Summary**: **Context**: When editing `opencode_app/opencode.json`

### Plan-file self-hit breaks purge gate

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/plan-file-self-hit-breaks-purge-gate.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: A tracked PLANS/PLAN-*.md (or any pipeline-written record — LEARNINGS candidates, review memos) whose AC gates grep repo-wide for a token it contains makes the gate unpassable — decide the exclusion set up front (own surfaces: PLANS/, LEARNINGS/) or keep records token-free; reviewers on purge tickets emit token-free candidates (#516)
- **Date**: 2026-09-21

### Dual-provider catalog entry proves endpoint swap

- **Category**: pattern
- **File**: `LEARNINGS/patterns/dual-provider-catalog-entry-proves-endpoint-swap.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: A model-id swap in a dual-endpoint API recipe is provable without a live call when provider-models.json (models.dev-pinned) lists the replacement under both provider prefixes the recipe's key resolution can select; on purge tickets keep candidates token-free (#516)
- **Date**: 2026-09-21

### Deliberate catalog divergence needs regen exclusion

- **Category**: solution
- **File**: `LEARNINGS/solutions/deliberate-catalog-divergence-needs-regen-exclusion.md`
- **Confidence**: medium
- **Scope**: project
- **Summary**: A deliberate divergence from a generated catalog (models.dev-pinned file vs purge mandate) is unenforced — regen re-adds and --check is warn-only; fix with a regen exclusion list, interim ceiling is a reconciling $comment sentence naming the re-add behavior (#516)
- **Date**: 2026-09-21

### Transport-only fallback kills disclaimer drift

- **Category**: pattern
- **File**: `LEARNINGS/patterns/transport-only-fallback-kills-disclaimer-drift.md`
- **Confidence**: medium
- **Scope**: project
- **Summary**: A fallback that reuses the native model id (different transport, same model) deletes the cross-doc "different model" disclaimer class instead of maintaining it — prefer transport-only divergence when picking fallback models (#516)
- **Date**: 2026-09-21

---

- Project-level: `LEARNINGS/` (this directory, git-committed)
- User-level: `~/.config/opencode/learnings/` (personal, cross-project)
- Searchable memory: `memory` tool (primary for quick retrieval)

**Naming convention:** Use descriptive slugs (e.g., `event-driven-modules.md`), not dated or numbered prefixes. The category is determined by the subfolder.

- **Category**: convention
- **File**: `conventions/merge-method-by-head-branch-class.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: PR merge method is classified by head-branch class — long-lived heads (main/dev/uat/staging/release/*, …) merge with `--merge`, short-lived heads squash regardless of base; squash on a surviving head duplicates content under new SHAs so promotion branches never converge (betekk-keycloak #55/#72: uat 9 ahead of dev); per-PR user override with SHA-divergence warning only, never autonomous (#519)
- **Date**: 2026-09-21

- **Category**: anti-pattern
- **File**: `anti-patterns/exact-match-branch-taxonomy-fallthrough.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: exact-match branch enumerations in agent-facing classifiers fall through on plausible variants (bare `release`, `development`, case diffs) into the unsafe default arm — pair every list with missing siblings, an explicit "exact + case-sensitive" statement, and a fall-through heuristic favoring the safe arm (#519)
- **Date**: 2026-09-21

- **Category**: anti-pattern
- **File**: `anti-patterns/orchestrator-embedded-facts-are-claims.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: "pre-verified repo facts" in review briefs are claims — #519's brief asserted no merge-method defaults elsewhere while semantic-release-convention-skill carried 9 squash directives incl. a governance MUST; reviewers re-run the one grep before relying on embedded negatives, and briefs state claims with the producing command (#519)
- **Date**: 2026-09-21

### Scoped shell allow rules have zero footprint in every generated artifact

- **Category**: pattern
- **File**: `LEARNINGS/patterns/scoped-shell-rules-zero-registry-footprint.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Scoped shell rules (non-`*` resources) feed no registry edges (build-registry.mjs:180-182, :236-242 — generatedAt-only diff, tier-4 proven), kimi/claude targets drop them with a documented warning (init.mjs:959-963), and the only mechanical consumer is tests/test_reviewer_no_writes.bats plus verbatim deploy copies. Prefix allows express read-intent, not a security boundary — `edit: deny` remains it (#524)
- **Date**: 2026-09-22

### Command-description parallel restatements drift when only the source is fixed

- **Category**: anti-pattern
- **File**: `LEARNINGS/anti-patterns/command-description-parallel-restatement-drift.md`
- **Confidence**: 0.75
- **Scope**: project
- **Summary**: Editing a `commands.*.description` without grepping its distinctive phrase repo-wide leaves parallel restatements stale — /run-plan's was mirrored in README.md:624 and anchored by docker-compose.yml:29-31. Map every hit before authoring steps (#524)
- **Date**: 2026-09-22

### Tracker issue body is the tiebreaker for flagged scope

- **Category**: solution
- **File**: `LEARNINGS/solutions/tracker-issue-body-is-the-tiebreaker-for-flagged-scope.md`
- **Confidence**: medium
- **Scope**: project
- **Summary**: When a review brief and a PLAN disagree on maintainer-directive scope for a flagged inclusion, fetch the tracker issue body before emitting a Requirements Gap — it is the authoritative tiebreaker (#522)
- **Date**: 2026-09-22

### Purge AC prefix coverage is accidental

- **Category**: solution
- **File**: `LEARNINGS/solutions/purge-ac-prefix-coverage-is-accidental.md`
- **Confidence**: medium
- **Scope**: project
- **Summary**: A purge AC's grep alternation gates a flagged extension id only by prefix luck — list every removed id explicitly in the pattern, flagged extensions included (#522)
- **Date**: 2026-09-22

### Skill snippet paths resolve via env vars, never cwd-relative paths

- **Category**: pattern
- **File**: `patterns/skill-snippet-paths-via-env-not-cwd.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: SKILL.md/agent-doc python snippets resolve engines via `os.environ['SKILL_DIR']` and prerequisite siblings via `get('DEP_SKILL_DIR', normpath(SKILL_DIR/../dep))` — never `.opencode/skills/…` literals, which break on every non-project install target; missing export fails loud by design (#511)
- **Date**: 2026-09-22

### Binding-row fallback token: one shape, every site

- **Category**: convention
- **File**: `conventions/binding-row-token-single-shape.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: normalize mechanically-greppable contract markers at every insertion site in the implementing commit; probes grep the delivered token case-insensitively; inline rows satisfy the canonical binding block (#512, Mode R ruling — codified by #515's guard)
- **Date**: 2026-09-22

### PLAN checkboxes lag delivered hunks in the same diff

- **Category**: anti-pattern
- **File**: `anti-patterns/plan-checkbox-state-lags-delivered-hunks.md`
- **Confidence**: 0.7
- **Scope**: project
- **Summary**: tick + Done-line each PLAN step in the same commit as its hunks — "code pushed, plan unticked" is an unfinished phase that --gate/--update will re-execute and that AC-verified claims inherit (#512 review)
- **Date**: 2026-09-22

### Single-sample parity probes miss type-conflict edges

- **Category**: anti-pattern
- **File**: `anti-patterns/single-sample-parity-probe-misses-type-conflicts.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: parity probes for reimplemented merge logic need type-mismatch fixtures on both sides (obj-vs-array, obj-vs-scalar, …) compared against the reference output — one well-formed sample let a delta-dropping recurse condition ship as "verified" (#513 review)
- **Date**: 2026-09-22

### Windows winget ImageMagick pairs with `magick`, not `convert`

- **Category**: solution
- **File**: `solutions/winget-im7-needs-magick-not-convert.md`
- **Confidence**: high
- **Scope**: project
- **Summary**: winget installs IM7 (`magick` entry point); plain `convert` on Windows resolves to System32's FAT→NTFS tool — install rows and usage snippets must be reviewed as a pair (#513 review)
- **Date**: 2026-09-22

### PLAN per-file census claims must be derived from the tree

- **Category**: anti-pattern
- **File**: `anti-patterns/plan-per-file-census-unverified.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: a PLAN's "N have X / M lack X" census asserted from memory was wrong twice (even the re-correction) and would have created duplicate metadata: keys invisible to every gate — capture the tree grep, reviewers re-run it, executors re-run before the first edit (#514)
- **Date**: 2026-09-22

### Portability warnings live in the install writers, not the resolver

- **Category**: decision
- **File**: `decisions/portability-warnings-in-writers-not-resolver.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: #514 warnings push into sel.warnings at the two writer sites AFTER effective-target resolution (writeUserScopeInstall via activeTargets — both never warns; writeInstall after --project degradation) — resolveSelection is target-free and shared; cmdAdd --all routes through writeUserScopeInstall anyway
- **Date**: 2026-09-22

### Learning write scripted via heredoc committed as content

- **Category**: anti-pattern
- **File**: `anti-patterns/learning-write-heredoc-committed-as-content.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: a scripted learning write left heredoc tail (EOF/cat/echo) inside the .md, companion file uncreated, index entries missing — all gate-invisible; verify learning artifacts (markdown-only body, companions exist, index gained entries) after any scripted write (#514 review)
- **Date**: 2026-09-22

### Portability guard: what it enforces and what it exempts

- **Category**: decisions
- **File**: `decisions/portability-guard-enforces-rules-1-2.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: test_portability.bats enforces contract rules 1-2 (no .opencode/skills literals in skill bodies; Other/none fallback rows; metadata.os on unix idioms; canonical quoted-comma authoring form) — rule 3 stays review-enforced; PORTABILITY_ROOT enables seeded-violation fixtures (#515)
- **Date**: 2026-09-22

### Canonical-form guards need regex, not case-globs

- **Category**: solutions
- **File**: `solutions/bash-canonical-form-guards-use-regex-not-case-globs.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: shell case-globs can't express character classes — a canonical "quoted lowercase comma" check implemented as globs validated only quote-wrapping; implement advertised forms as rg -v regex inversion over a shared awk frontmatter slice (#515 review)
- **Date**: 2026-09-22

### CI runners lack ripgrep — bats guards must use grep

- **Category**: anti-pattern
- **File**: `anti-patterns/ci-runners-lack-ripgrep-bats-guards-use-grep.md`
- **Confidence**: 1.0
- **Scope**: project
- **Summary**: bats guards executing in CI must use POSIX grep/find/awk — rg is absent on ubuntu runners (127) and sweeps would read vacuous-green without the non-vacuous canary; local-green is not CI-green for tooling-dependent tests (#515 CI red)
- **Date**: 2026-09-22

### Compare API ahead_by counts the HEAD side — operand order must be pinned

- **Category**: anti-pattern
- **File**: `anti-patterns/compare-api-ahead-by-counts-head-side.md`
- **Confidence**: 0.95
- **Scope**: project
- **Summary**: GitHub `compare/{BASE}...{HEAD}` returns ahead_by = HEAD-side commits, behind_by = BASE-side commits; #532's Phase 0 labeled them backwards under `{source}...{target}` while in-repo LEARNINGS held the correct empirical direction — flows keyed on these fields must state the operand order and be checked against a known-divergence example (#532 code review BLOCK)
- **Date**: 2026-09-22

- **File**: `anti-patterns/companion-lookup-fail-open-consumes-plan.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: In consume-once deploy functions, derived-artifact lookups (node/jq/CLI) must fail closed — a silent lookup failure skips artifacts AND the plan file is then deleted, converting a transient error into a permanently broken deploy (#537 code review)
- **Date**: 2026-09-23

- **File**: `anti-patterns/re-run-pin-single-invocation-vacuous.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: An idempotency assertion over N invocations is vacuous unless the test performs N invocations — `find | wc -l = 0` after one apply cannot detect removal of an rm-first line (#537 code review)
- **Date**: 2026-09-23

- **File**: `patterns/plugin-companions-declarative-single-home.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: Plugin companion artifacts live in dependency-map.json `pluginCompanions` (trailing slash = dir), consumed by the picker path fail-closed and pinned by no-hardcode + per-edge cross-surface tests — next companion-bearing plugin edits the map, never setup.sh (#537)
- **Date**: 2026-09-23

- **File**: `solutions/node-e-dynamic-import-resolves-against-cwd.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: `import("./rel.mjs")` inside `node -e` resolves against process.cwd — scripts that run from any cwd (setup.sh PATH shim) must import via pathToFileURL over an argv-passed absolute path, pinned by a second-cwd test (#537)
- **Date**: 2026-09-23

- **File**: `anti-patterns/grep-q-under-pipefail-sigpipes-upstream.md`
- **Confidence**: 0.9
- **Scope**: project
- **Summary**: `grep -q` in a pipeline under `set -o pipefail` SIGPIPEs the upstream writer — pipeline exits 141 and `&&` chains break while the identical line is green in CI under plain `bash -e`; "CI green, 141 locally" on a guard line is this pattern first (#537 exit gate)
- **Date**: 2026-09-23

### PLAN exit gates must cover the pinned-content suites of rewritten files

- **Category**: anti-patterns
- **File**: `anti-patterns/plan-exit-gate-narrower-than-pinned-consumers.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: A PLAN rewriting a file pinned by bats suites must map those suites AND run them in its exit gate — ticket-named suites are a lower bound; PLAN-546 could pass every named gate with the pinned preamble already deleted (#546 plan review)
- **Date**: 2026-09-24

### Element-list merge PLANs drop every upstream section the list fails to name

- **Category**: anti-patterns
- **File**: `anti-patterns/plan-element-lists-drop-unnamed-upstream-sections.md`
- **Confidence**: 0.85
- **Scope**: project
- **Summary**: Merge PLANs that enumerate upstream guidance as a named element list silently drop unnamed sections and the AC shares the blind spot; require a per-section delta table (section → step or "dropped: why") before authoring steps (#546 plan review)
- **Date**: 2026-09-24

### Replacement edits need removal assertions plus unique positive sentinels

- **Category**: anti-patterns
- **File**: `anti-patterns/replacement-edits-need-removal-assertions.md`
- **Confidence**: 0.8
- **Scope**: project
- **Summary**: Done-when for a replacement must positively grep a unique new marker (fails pre-edit) AND negatively grep the old text at known locations; "orchestrated" was already green on the line being replaced (#546 plan review)
- **Date**: 2026-09-24
