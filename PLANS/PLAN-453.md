# PLAN: installer target layer + shared ~/.agents/ target

**Branch**: feat/453
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/453
**Base**: main

## Acceptance Criteria

- [ ] `--target agents` installs skills verbatim to `~/.agents/skills/` and agents verbatim to `~/.agents/agents/`
- [ ] Target table drives dest dirs + transforms for **user-scope** installs; existing `opencode` and `claude` user-scope output is unchanged (no regression). Project-scope dest columns are **deferred to #454** (no current consumer — `--project` installs are opencode-only): `--project` stays opencode-only and keeps its existing note-and-downgrade behavior when combined with a non-opencode `--target` (no `~/.agents` write, no new error)
- [ ] Manifest entries record per-target content hashes; `update` copies only changed targets; `remove` cleans every probed target dir
- [ ] `--dry-run` previews new-target writes and writes nothing
- [ ] `node --test` + `bats` gates pass; README / `--help` / installer counts synced per repo documentation-sync rules

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` (`--target` validation, `writeUserScopeInstall`, `cmdUpdate`, `cmdRemove`, help text) | `installer/registry.json`, `installer/source.mjs`, `installer/tui-primitives.mjs` | `package.json` bin (`opencode-skill`, npx GitHub installs), `tests/init.bats`, `tests/update.bats`, `tests/parse_arguments.bats`, `deploy/setup.sh:3339` (`add --all --yes`) + `:4134` (`update`), `deploy/setup.ps1:2299`/`:2891`, README install docs, root `AGENTS.md` §Repository Purpose | med |
| User manifest `~/.config/opencode/.skill-manifest.json` (schema: `entries.<name>.targets` + new `agents` key) | `init.mjs` write path | `cmdUpdate` (per-target re-copy), `cmdRemove` (probing), legacy-manifest upgrade path | med |
| `~/.agents/` install surface (new; `agents/` + `skills/`) | installer write path | Kimi Code CLI (reads `~/.agents/agents/` + `~/.agents/skills/`), pi (reads `~/.agents/skills/`) | low |

Cross-module consumers exist (tests, docs, bin) → architecture review selected. No frontend signal → no uiux review.

## Implementation Phases

### Phase 1: Target table + validation + preview

- [x] **1.1** Extract the test contract from `tests/init.bats` + `tests/update.bats`: (a) how user-scope tests isolate `$HOME`, (b) every asserted dry-run JSON key for `add` and `update`.
    — **Why:** backward-compat constraints (AC: no regression) and test-isolation mechanics gate every later step; discovering them mid-phase would force rework.
    — **Done when:** assertion inventory + HOME-isolation mechanism recorded in Technical Notes below.
    — **Consumers affected:** all later phases.
    — **Done:** contract inventory recorded in Technical Notes (HOME isolation: init.bats per-test `HOME="$TMP_PROJ/home"`, update.bats mktemp; update dry-run asserts per-entry `updated` bucket; add user-scope dry-run JSON unasserted — keys kept stable anyway); gates discovered: bats×3 + node --test, lint/typecheck/build n.a. (no tooling configured); files: PLANS/PLAN-453.md; fixes: none
- [x] **1.2** Add `USER_AGENTS_SHARED`/`USER_SKILLS_SHARED` constants and a `TARGETS` table (target → user dest dirs + transform mode) as the single site destined to own target dest/transform resolution; extend `--target` validation (`init.mjs:651`) to accept `agents`; update the validation die message (`init.mjs:652`), the `--help` `--target` line, and the help SCOPE block (`~/.agents` mention, `init.mjs:1180-1182`).
    — **Why:** single source of per-target dest+transform unblocks the write path and lifecycle; validation is the public contract, and the die message enumerates its valid values.
    — **Done when:** `node installer/init.mjs add code-review-subagent --target agents --dry-run` exits 0 and names `~/.agents` paths; `--target bogus` still dies listing all four values; `bats tests/parse_arguments.bats` green.
    — **Consumers affected:** write path (Phase 2), update/remove (Phase 3), docs (Phase 4).
    — **Done:** TARGETS table + shared constants added as the single dest/transform site; validation accepts `agents`; die message, --format warning, help SCOPE + --target lines updated; verified agents dry-run exit 0 naming ~/.agents (4 hits) and bogus target dying with all four values; files: installer/init.mjs; fixes: none
- [x] **1.3** Generalize the user-scope dry-run preview (`init.mjs:660-673`): per-target destinations; preserve every existing JSON key byte-for-byte for `opencode`/`claude`/`both`.
    — **Why:** the preview JSON is an asserted contract (1.1 inventory); breaking keys fails gates and downstream scripts.
    — **Done when:** dry-run JSON for legacy targets has the identical key set as the 1.1 baseline; `agents` target preview lists `~/.agents` destinations; `bats tests/init.bats` green.
    — **Consumers affected:** bats suites, docs examples.
    — **Done:** preview emits per-target `destinations` map; legacy `destination` key + all baseline keys preserved (both-target dry-run key diff checked: additive only, `destinations` new); files: installer/init.mjs; fixes: none

### Phase 2: agents-target install path

- [x] **2.1** Implement shared-target skill install: verbatim `cp` of the skill dir to `~/.agents/skills/<name>/`; manifest entry gains `targets.agents = hashSkillDir(dst)`.
    — **Why:** core value — pi and Kimi read `~/.agents/skills/`; verbatim copy is safe because both loaders ignore unknown frontmatter.
    — **Done when:** `add --target agents --skills <name> --yes` creates the dir tree; the shared write path resolves dest + transform from `TARGETS` (no bespoke `writeAgentsFormat`-style branch beside `writeClaudeFormat`); manifest entry records `targets.agents`.
    — **Consumers affected:** `cmdUpdate`/`cmdRemove` (Phase 3), Kimi/pi users.
    — **Done:** shared skill install verified (dir tree created, manifest `targets.agents` recorded); write loop resolves dest+transform from `TARGETS` — `writeClaudeFormat` folded into the table loop and deleted, no bespoke branch; files: installer/init.mjs; fixes: none
- [x] **2.2** Implement shared-target agent install: write raw `agent.content` (NO `injectModelLine`) to `~/.agents/agents/<stem>.md`; record `manifest.agents` for shared-target installs (extend the `doOc`-only condition at `init.mjs:716`); entry `targets.agents = sha256Hex(content)`.
    — **Why:** foreign targets ship agents unpinned (ticket #453 decision); the raw content hash differs from the opencode-injected hash by design — per-target hashes (#379) already accommodate this.
    — **Done when:** installed file contains no `model:` line unless the source has one; manifest lists the stem; manifest `entries` carry both `opencode` and `agents` hashes after a `both`+`agents` install; the opencode agent write path (`init.mjs:681-688`) now resolves its dest + inject transform from `TARGETS` rather than inline constants.
    — **Consumers affected:** `cmdUpdate` (Phase 3), Kimi users.
    — **Done:** shared agent install verified (raw content written, 0 `model:` lines, manifest.agents records stem); dual-target install carries differing opencode(injected)/agents(raw) hashes; opencode write path resolves via TARGETS; files: installer/init.mjs; fixes: none
- [x] **2.3** Regression sweep: in a temp `$HOME`, run full `add` for `opencode`, `claude`, and `both` and diff the manifests + written trees against the 1.1 baseline.
    — **Why:** AC demands zero regression on existing targets; a diff is the only objective proof.
    — **Done when:** manifest key-sets and written-tree shapes identical to baseline (modulo `generatedAt`); every remaining read/write site in `init.mjs` resolves per-target dest/transform via `TARGETS` (structural grep owned by 3.1).
    — **Consumers affected:** existing user installs.
    — **Done:** old(main) vs new per opencode/claude/both — manifests identical modulo generatedAt, written trees identical; the opencode-target ~/.claude "DIFF" was a both-sides-missing artifact (confirmed neither writes it); dir-creation semantics kept byte-compatible (unconditional mkdir per active target); files: none (verification); fixes: none

### Phase 3: lifecycle (update / remove)

- [x] **3.1** Rework `cmdUpdate` per-target loop: replace the "agents only ever install to the opencode target" assumption (`init.mjs:960`) — `installedPath` and `wouldHash` become target-dependent via `TARGETS` (opencode = model-injected content; agents = raw content); extend the `--prune` path (`init.mjs:944-946`) to remove shared files when `targets.agents` is present; add `~/.agents` probes to the legacy-manifest synthesis loop (`init.mjs:913-930`) so crash-orphaned shared files enter the lifecycle.
    — **Why:** `update` must re-copy drifted shared copies or the AC "update copies only changed targets" fails; prune must not leave orphans; asymmetric probing (remove cleans `~/.agents`, update never maintains it) is the exact inconsistency `legacy-upgrade-target-probe` bans.
    — **Done when:** `update` re-copies the shared copy on SOURCE drift and recomputes each target with its own transform (opencode = injected, agents = raw); per-target missing reports `(agents)`; dest constants referenced only in the `TARGETS` block (structural grep); `bats tests/update.bats` green. Installed-file drift alone is not repaired — pre-existing #379 semantics, identical for opencode.
    — **Consumers affected:** all manifest-tracked users.
    — **Done:** per-target loop resolves via TARGETS; unknown-key explicit no-op+warning replaces fallback dispatch; prune + legacy synthesis probe all TARGETS dirs (shared included); verified: source-drift re-copy gives opencode marker+model-line / agents marker-raw, dry-run missing lists `(agents)`, structural grep clean, update.bats green; files: installer/init.mjs; fixes: none
- [x] **3.2** Extend `cmdRemove` (`init.mjs:885-895`) to probe `~/.agents/agents/<stem>.md` and `~/.agents/skills/<name>/` alongside the existing opencode + claude paths.
    — **Why:** remove must clean every probed target dir (LEARNINGS: `legacy-upgrade-target-probe` — probe every historical target, not just the default).
    — **Done when:** remove wipes all three destinations for a multi-target install and cleans the manifest; single-target installs only remove what exists.
    — **Consumers affected:** users uninstalling.
    — **Done:** remove iterates TARGETS dirs (opencode+claude+shared); verified tri-target install fully wiped by one remove; files: installer/init.mjs; fixes: none
- [x] **3.3** Filter the update-path advisory visibility check (`checkStrictAllowlist` call, `init.mjs:1021-1026`) to entries carrying an `opencode` target.
    — **Why:** an agents-target-only user with a strict opencode allowlist otherwise gets misleading HIDDEN warnings for skills never installed to opencode (`advisory-check-full-catalog-noise` recurrence; exposure grows with this feature).
    — **Done when:** an agents-only manifest produces zero HIDDEN advisory lines from `update`; an opencode-target skill is still warned as before.
    — **Consumers affected:** update users.
    — **Done:** advisory `sel` filtered to entries with `targets.opencode`; verified agents-only manifest + deny-all allowlist yields zero HIDDEN lines; files: installer/init.mjs; fixes: none

### Phase 4: tests + docs + gates

- [x] **4.1** Add bats coverage for the `agents` target: happy path (skills + agents), dry-run preview, update drift on a shared copy, remove probing — mirroring the 1.1 HOME-isolation mechanism.
    — **Why:** the AC requires lifecycle coverage; untested lifecycle code is where the probing regressions live.
    — **Done when:** new bats file green locally; no writes outside the isolated `$HOME`; includes an assert that `--project --target agents` keeps the existing note-and-opencode-downgrade (no `~/.agents` write, no new error).
    — **Consumers affected:** CI.
    — **Done:** tests/agents_target.bats — 6 tests (skill verbatim + manifest, agent unpinned, dry-run preview + no writes, source-mutation re-copy without model injection, tri-target remove wipe, --project note-and-downgrade with no ~/.agents write), all green; files: tests/agents_target.bats; fixes: none
- [x] **4.2** Docs sync: README install section (new `agents` target + which tools read `~/.agents/`), `--help` text, root `AGENTS.md` §Repository Purpose target list.
    — **Why:** repo documentation-sync rules; undocumented installer surface breaks the repo's own contract (PLAN-418 precedent).
    — **Done when:** case-insensitive sweep of target-enumeration spellings (`rg -i 'opencode, claude|--target' README.md AGENTS.md installer/init.mjs`) shows all four values consistently, including the `init.mjs:652` die message; the README `agents`-target section cites the Kimi/pi doc URLs from the ticket and notes the Kimi skill-body placeholder-expansion caveat.
    — **Consumers affected:** users, docs readers.
    — **Done:** README target table gained the `agents` row (Kimi/pi citations + placeholder caveat) + example; AGENTS.md §Repository Purpose extended; sweep confirms die message carries all four values; files: README.md, AGENTS.md; fixes: none
- [x] **4.3** Full local gate: `bats tests/init.bats tests/update.bats tests/parse_arguments.bats` + new suite + `node --test tests/*.test.ts` + `bats tests/test_pack_permissions.bats tests/test_count_drift.bats`; record the `GATE <short-sha>` memo line for the pushed SHA.
    — **Why:** pipeline gate contract — the PR step cites this memo as its verification evidence.
    — **Done when:** every suite green; memo line emitted.
    — **Consumers affected:** code review (Step 9), PR creation (Step 10).
    — **Done:** all suites green (55 bats core+new ok, node --test exit 0, pack/drift bats exit 0); files: none (verification); fixes: none

## Technical Notes

- **Manifest schema is already multi-target** (`entries.<name>.targets.{opencode,claude}` with written-content hashes, #379/#400): this PLAN adds an `agents` key — no schema migration needed. Legacy manifests upgrade via the existing `cmdUpdate` synthesis path.
- **Shared-dir collision risk:** `~/.agents/` may contain files owned by other tools (Kimi/pi). Current user-scope `add` overwrites installer-owned names without conflict checks; same behavior extends to `~/.agents/`. Mitigation for v1: document it; ownership tracking beyond the existing manifest is deferred.
- **1.1 contract inventory (filled by step 1.1):** HOME isolation — init.bats `export HOME="$TMP_PROJ/home"` (per-test), update.bats `export HOME="$(mktemp -d)"` (setup); `os.homedir()` reads env per fresh process, so overrides work. Dry-run JSON assertions — `update --dry-run` JSON must carry per-entry `updated` bucket (update.bats:44,100); `add` user-scope dry-run JSON keys are NOT bats-asserted (keep keys stable anyway for scripts/docs). Gate commands: no lint/typecheck/build configured (package.json `scripts: null`) → test gate = `bats tests/init.bats tests/update.bats tests/parse_arguments.bats` (+ new suite in Phase 4) + `node --test tests/*.test.ts`.
- **Deliberately out of scope:** model pinning on foreign targets; `kimi`/`kilo` native targets (#454/#455 build on this table); MCP cross-platform config.
- **Project-scope dest dimension deferred (descope of ticket Proposed-solution #1, Mode R ruling):** `TARGETS` maps target → **user** dest dirs + transform mode only. Rationale: zero current consumers (`--project` is opencode-only, `init.mjs:637-644`; the `agents` target writes `~/.agents/` user-scope), and Kimi's project-level `.agents/` scan has no consumer until #454. Seam for #454: (a) add a project dest mapping to `TARGETS`; (b) replace the hard-wired `--project`-forces-opencode branch with a table lookup; (c) decide whether note-and-downgrade becomes hard validation or per-target project support. Until then `--project` + non-opencode `--target` keeps the existing note-and-downgrade (asserted in 4.1).
- **Mixed-version hazard (older binary × new manifest):** an older binary's update loop dispatches any non-opencode target key through the claude branch (`init.mjs:971-975`), so it may report `~/.agents` entries missing or re-copy `~/.claude` and overwrite the `agents` hash — self-healing on the next new-binary run, no data loss. Accepted; #454 must replace fallback dispatch with explicit target-key matching.
- **Kimi skill-body placeholder expansion:** Kimi expands `$0`/`$1`/declared `$<name>`/`${KIMI_SKILL_DIR}` placeholders in skill bodies — verbatim-copied skills with shell snippets carry the same exposure the claude target already has today; documented in the 4.2 README notes rather than treated as "verbatim is safe".
- Per-target agents hashing: opencode = `sha256Hex(injected)`, agents = `sha256Hex(raw)` — both stored under their own key; `update` recomputes the same way (mirrors the claude skill-strip asymmetry at `init.mjs:973-974`).

## Dependencies

- None blocked-by. Builds the foundation consumed by #454/#455/#457.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Dry-run JSON key drift breaks bats or downstream parsers | 1.1 inventories asserted keys first; 1.3 preserves them byte-for-byte; new keys only added |
| Tests pollute the real `$HOME` (`~/.agents`) | Mirror the existing bats HOME-isolation mechanism (1.1); 4.1 asserts isolation |
| `~/.agents/` name collisions with other tools' files | Documented v1 behavior (same as installer-owned dirs); manifest tracks what we wrote |
| Update loop regression on opencode-only agents | 2.3 regression sweep + 3.1 done-when asserts opencode copy untouched |

## Gate Trace

_Gate per `verification-loop-skill` §The gate contract; lint/typecheck/build = n.a. (no tooling configured in repo or CI — closest executable check is the unit suite, which exercises `init.mjs` end-to-end)._

GATE 9ab5aaa lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a. — bats init/update/parse_arguments 49 ok, node --test green
GATE 16c01a2 lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a. — bats init/update/parse_arguments green, node --test green, 3-target regression sweep identical
GATE e5f4a8f lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a. — bats 49 ok, node --test green, lifecycle behavioral checks green
GATE 300b271 lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a. — FINAL: 55 bats ok (init/update/parse_arguments/agents_target), node --test green, pack+drift bats green
