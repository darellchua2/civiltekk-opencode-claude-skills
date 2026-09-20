# PLAN: kimi install target (agents + skills)

**Branch**: feat/454
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/454
**Base**: main

## Acceptance Criteria

- [ ] User and project scope installs land in Kimi-native dirs (`~/.kimi-code/{agents,skills}/`, `.kimi-code/{agents,skills}/`); a sample agent loads in Kimi Code CLI with `description` + body intact
- [ ] Mappable `permissions` rules translate to `tools` / `disallowedTools`; unmappable ones are dropped with an explicit warning listing them per agent
- [ ] Skills install verbatim
- [ ] Transform unit tests cover both the mapped and dropped cases
- [ ] `--dry-run` previews; README / `--help` synced

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` (`TARGETS` kimi row + project columns, kimi translate fn, project-branch table lookup, help text) | #453 TARGETS table (merged, `29397ca`), `installer/source.mjs` | `package.json` bin (npx installs), `tests/kimi_target.bats` (new), existing suites (`init`/`update`/`parse_arguments`/`agents_target` — must stay green), `deploy/setup.sh:3339`/`:4134` + `setup.ps1:2299`/`:2891` (default-target invocations, exit-code only), README, root `AGENTS.md` | med |
| Project-scope branch (`writeInstall`) — table lookup replaces forced-opencode downgrade | TARGETS project columns (this PLAN) | `--project` users: opencode/claude/agents behavior must be unchanged (note-and-downgrade preserved); kimi gains project support | high — touches the project preset flow (opencode.json/models.json/AGENTS.md artifacts) |
| Kimi frontmatter translation (additive `tools`/`disallowedTools`) | opencode `permissions` array shape in `agents/*.md` | Kimi Code CLI loader (ignores unknown fields; `tools`/`disallowedTools` are enforced) | med |

Cross-module consumers exist (tests, docs, deploy scripts) → architecture review selected. No frontend signal → no uiux review.

## Implementation Phases

### Phase 1: kimi table row + translation

- [x] **1.1** Add the `kimi` row to `TARGETS` (user: `~/.kimi-code/{agents,skills}`, project: `.kimi-code/{agents,skills}`, `agentMode: "kimi-translate"`, `skillMode: "verbatim"`) plus per-target optional `projectAgentsDir`/`projectSkillsDir` columns (opencode row gains its existing `.opencode/{agents,skills}`; claude/agents rows stay projectless); extend `TARGET_VALUES` derivation untouched (already derives from `TARGETS` keys), update the die message, `--format` warning, and help SCOPE/`--target` lines to five values.
    — **Why:** the table is the single resolution site since #453; project columns are the deferred seam (#453 Mode R ruling) whose first consumer is this ticket.
    — **Done when:** `node installer/init.mjs add code-review-subagent --target kimi --dry-run` exits 0 naming `~/.kimi-code`; `--target bogus` still dies; `rg -i 'opencode, claude' installer/init.mjs` shows all five values in the die message.
    — **Consumers affected:** all install/update/remove paths (Phase 2-3), docs (Phase 4). **Note:** `tests/agents_target.bats:85` pins the four-value die message — update that pin to five values in this step or the suite goes red.
    — **Done:** kimi row + project columns added (USER_KIMI_* constants); die/--format/help lines carry five values; agents_target.bats die pin updated to five; kimi dry-run names ~/.kimi-code, bogus target dies; files: installer/init.mjs, tests/agents_target.bats; fixes: none
- [x] **1.2** Implement `kimiAgentContent(content, warn)` pure transform: parse the frontmatter `permissions` array; map mappable `{action, resource, effect}` rules — `read→Read, edit→Edit, write→Write, bash→Bash, glob→Glob, grep→Grep, webfetch→FetchURL, websearch→WebSearch` (Kimi's real registry per its tools doc — there is no `WebFetch`; unknown names never match) with `resource: '*'` — into additive `tools:` (allow) / `disallowedTools:` (deny) YAML **inserted at column 0 immediately after the opening `---` line** (the `injectModelLine` precedent, `init.mjs:525-539`) — never scan for `description` (a `>-` folded scalar would corrupt the YAML); files with no frontmatter or no closing `---` return unchanged with a warning; `mcp:*` resource globs translate to `mcp__*`; deny wins on action conflicts; unmappable actions (`skill`, `task`, `question`, `todowrite`, subagent gating) and non-`*`/non-`mcp:` resources are dropped and reported via `warn()`; empty lists omit the key; body and all existing frontmatter keys (including `permissions` itself — Kimi ignores unknown fields) stay byte-identical.
    — **Why:** Kimi ignores unknown fields and loads OpenCode-style files, so additive insertion is the minimal lossless translation; tool gating survives via `tools`/`disallowedTools`.
    — **Done when:** transform verified on 3 real agents (one skill-heavy reviewer, one read-only, one with `mcp:*` deny): mapped lists correct (incl. `FetchURL`/`WebSearch`), dropped rules named in warnings, body bytes unchanged, YAML round-trips.
    — **Consumers affected:** install + update would-content paths (Phase 2-3).
    — **Done:** kimiAgentContent implemented (column-0 insert after opening ---, KIMI_TOOL_MAP with FetchURL/WebSearch, mcp:*→mcp__*, deny-wins, dropped-rule warn, frontmatter-less guard); verified on code-review-subagent (tools FetchURL/Glob/Grep/Read/WebSearch, disallowedTools Bash/Edit/mcp__*, description >- intact, body byte-identical) + nextjs-specialist-subagent (FetchURL/WebSearch); files: installer/init.mjs; fixes: none
- [x] **1.3** Wire `kimi-translate` into the user-scope install loop and `cmdUpdate` would-content computation (alongside `model-injected` and verbatim), hash = `sha256Hex(translated content)`.
    — **Why:** install and update must produce byte-identical kimi content or update re-copies forever.
    — **Done when:** `add --target kimi` writes a translated agent; source mutation + `update` re-copies translated content; idempotent second `update` reports `unchanged`.
    — **Consumers affected:** lifecycle (Phase 3), Kimi users.
    — **Done:** kimi-translate wired into install loop + cmdUpdate would-content; idempotent update (unchanged 1), source mutation re-copies translated content; files: installer/init.mjs; fixes: none

### Phase 2: project scope (the #453 seam)

- [ ] **2.1** Replace the hard-wired `--project`-forces-opencode branch (`cmdAdd`: note + opencode downgrade) with a TARGETS lookup: targets carrying `projectSkillsDir`/`projectAgentsDir` (opencode, kimi) install to their project dirs; targets without them (claude, agents, both→claude side) keep today's note-and-downgrade with the existing message; a `--project --target bogus` degrades through the same presence-check (no new error). The **preset/init main flow** (`init.mjs:1133`/`:1137`, `--project . --preset X`) keeps opencode semantics: it passes no `--target`, and a non-opencode `--target` there dies (help already scopes `--target` to `add`).
    — **Why:** ticket #454 promises project scope; the seam was designed for exactly this (#453 Mode R ruling).
    — **Done when:** `--project --target kimi` writes `.kimi-code/{agents,skills}`; `--project --target agents` and `--project --target claude` still print the note and write only `.opencode/` (pinned in bats); `--project` (no target) behaves byte-identically to today; `--preset` + `--target kimi` exits non-zero with a clear message.
    — **Consumers affected:** project-scope users, preset flow.
- [ ] **2.2** Guard the opencode-specific project artifacts: `opencode.json`, `models.json`, `AGENTS.md` writes and their conflict checks run only when the project target includes opencode (`opencode` or `both`); kimi project installs write agents+skills+manifest only (manifest at `.kimi-code/.opencode-init.manifest.json`), kimi project agents get kimi-translate (no model injection — kimi stays unpinned in project scope too), and the kimi project `--dry-run` JSON omits/nulls `configPath`/`modelsPath`/`agentsMd` so the preview doesn't lie. Additionally, `doPrune` (`init.mjs:568-589`) resolves its manifest + dirs from the TARGETS project columns instead of hardcoded `.opencode` so kimi project installs are prunable; relative project columns resolve **only** where an explicit project root exists — `Object.values(TARGETS)` loops must never join relative columns against cwd.
    — **Why:** kimi projects must not receive opencode config artifacts; injecting opencode models into kimi agents contradicts the unpinned decision; the hardcoded `.opencode` prune would orphan kimi project installs.
    — **Done when:** kimi project install creates no `opencode.json`/`models.json`/`AGENTS.md`, dry-run omits those keys, and `update --project --prune` prunes kimi project entries; opencode `--project --preset` flow unchanged (existing init.bats green).
    — **Consumers affected:** project users, CI bats.

### Phase 3: lifecycle + regression

- [ ] **3.1** Verify (and pin where gaps exist) the TARGETS-driven lifecycle for kimi rows, **user-scope only for remove** (parity with opencode: project copies are prune-only — `cmdRemove` has no project context by design): `update` per-target drift, `remove` probing `~/.kimi-code`, legacy synthesis, prune — no code change expected beyond what Phase 1-2 wiring already covers; add bats pins.
    — **Why:** #453 made these paths table-driven; the pin proves kimi rows ride them for free and guards #455.
    — **Done when:** remove wipes the user kimi copies; `update --project --prune` prunes kimi project entries (2.2); update reports `(kimi)` missing when the user dir is deleted; legacy manifest with kimi-installed files synthesizes `targets.kimi`.
    — **Consumers affected:** kimi users, #455.
- [ ] **3.2** Regression sweep: opencode/claude/agents/both targets — manifests + trees identical to pre-change (reuse the #453 sweep method); `--project` opencode preset dry-run JSON identical.
    — **Why:** AC: no regression on existing targets/flows.
    — **Done when:** all sweeps identical (modulo `generatedAt`).
    — **Consumers affected:** existing users.

### Phase 4: tests + docs + gates

- [ ] **4.1** Add `tests/kimi_target.bats` (HOME-isolated): user install (translated frontmatter present — `FetchURL`/`WebSearch` names — permissions key preserved, body intact, no `model:` line), dropped-rule warning, verbatim skill, project install to `.kimi-code/`, project downgrade asserts (agents/claude targets), update idempotency + source-drift re-copy, user-scope remove probing, transform coverage for mapped vs dropped cases, and a derived guard pinning zero Kimi template variables (`${cwd}`/`${os}`/`${shell}`/`${now}`) in the translated corpus. Record a manual Kimi CLI load smoke in the PR body (structural bats pins are the CI proxy).
    — **Why:** the ticket's AC names transform coverage explicitly; bats is the only gate net.
    — **Done when:** new suite green; no writes outside isolated `$HOME`/tmp project.
    — **Consumers affected:** CI.
- [ ] **4.2** Docs sync: README target table `kimi` row (native dirs, translation summary, link to Kimi agents doc, default-path-only note — `KIMI_CODE_HOME` env relocation is an optional follow-up), the lossy-mapping table (`webfetch→FetchURL`, `websearch→WebSearch`, `write→Write` currently unused, `skill`/`task`/`question` dropped — task-deny agents become auto-delegable in Kimi), the Kimi `${var}` body-template caveat, root `AGENTS.md` bullet, help text (Phase 1).
    — **Why:** repo documentation-sync rules.
    — **Done when:** `rg -i 'opencode, claude' README.md AGENTS.md installer/init.mjs` consistent (five values); kimi row cites the Kimi docs URL and the lossy table.
    — **Consumers affected:** users, docs readers.
- [ ] **4.3** Full gate: all bats suites + `node --test` + pack/drift; `GATE` memo line for the pushed SHA.
    — **Why:** pipeline gate contract.
    — **Done when:** every suite green; memo emitted.
    — **Consumers affected:** code review, PR creation.

## Technical Notes

- **Translation is additive, not rewriting:** Kimi's loader ignores unknown fields and reads OpenCode-style files (documented); `permissions`/`mode`/`steps` stay in the frontmatter. Only `tools`/`disallowedTools` are inserted. This keeps a single source of truth and makes the transform reversible by deleting two keys.
- **Deny-wins rationale:** opencode rules are ordered last-match-wins per file; Kimi lists are unordered. On conflict the safer effect (deny) wins; conflicts are expected to be rare (agents conventionally allow-by-action or deny-by-action, not both).
- **Model pinning:** kimi agents are never model-injected (user or project scope) — epic decision; `agentModel`/tier machinery untouched.
- **Kimi loads `~/.agents/` too** — users can double-install (shared + native); that's their choice; the manifest tracks both target keys independently (per-target hash merge from #453 handles it).
- **Deliberately out of scope:** MCP cross-platform config (kimi reads its own MCP config); `kilo` target (#455); Kimi `subagents` allowlist translation (`task` rules dropped + warned — kimi's default delegation allowlist is a reasonable landing).

## Dependencies

- Builds on #453 (merged: TARGETS table, per-target hashes, lifecycle probing). No blocked-by.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Project-branch rework breaks the opencode preset flow (high-traffic path) | 2.1 keeps opencode behavior behind the same lookup; 3.2 byte-diff sweep + init.bats green is the gate |
| Frontmatter insertion corrupts YAML (description `>-` blocks, nested lists) | Insert at column 0 immediately after the opening `---` (injectModelLine precedent) — never key-scanning; guard frontmatter-less files; 1.2 verifies on 3 real agents incl. multi-line descriptions |
| Translation drift between install and update would-content | Single `kimiAgentContent` function used by both (1.3); idempotency pinned in 4.1 |
| Dropped-rule warnings spam full-catalog installs | One line per agent max, aggregated rule list (same pattern as claude skip-warning) |

## Gate Trace

_Plan review round 1 (architecture-review-subagent): approved-with-notes; 4 Major amendments applied — tool map corrected to Kimi's real registry (`webfetch→FetchURL`/`websearch→WebSearch`, verified against live docs 2026-09-20); frontmatter insertion point pinned to column-0-after-`---`; preset flow + `doPrune` folded into Phase 2; 3.1 scoped to user-scope remove (project copies prune-only, opencode parity). Requirements Gaps resolved with the reviewer's verified recommended answers (tool map, remove parity, Kimi load smoke recorded in PR body, KIMI_CODE_HOME documented default-only). `agents/` corpus verified clean of Kimi `${var}` collisions 2026-09-20._

