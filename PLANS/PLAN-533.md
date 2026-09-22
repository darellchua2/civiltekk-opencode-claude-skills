# PLAN: Ponytail v4.10.0 re-vendor + installer plugin ship + build/test gate

**Branch**: feat/533
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/533
**Base**: main

## Acceptance Criteria

- [ ] `plugins/ponytail/SKILL.md` body matches upstream v4.10.0 (modulo the vendored-header comment); `plugins/ATTRIBUTION.md` pin bumped to v4.10.0
- [ ] All 8 agent lens markers re-synced; no lens quotes the old `// ponytail: this exists` wording
- [ ] Persisted default mode works: `/ponytail default <mode>` survives restart, env var still wins; bare `/ponytail` reports the active level
- [ ] Installing a ponytail skill via the installer also delivers the plugin to the target plugin dir; `--no-deps` respected; non-OpenCode targets get a notice, not a copy
- [ ] Gate paragraph injected with the ruleset; tdd/testing/loop-operator lenses mirror it
- [ ] `node installer/build-registry.mjs` run; `registry.json` committed if changed
- [ ] Bats suite passes; injection smoke test shows `PONYTAIL MODE ACTIVE` with the updated wording
- [ ] Docs synced (README installer section, `deploy/setup.sh` help, CHANGELOG per release-please convention)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `plugins/ponytail/SKILL.md` | — | `plugins/ponytail/instructions.cjs` (reads at runtime), 8 agent lens sections (derived), `deploy/setup.sh` deploy_plugins(), injected system prompt | med |
| `plugins/ponytail/instructions.cjs` | SKILL.md | `plugins/opencode-ponytail-scoped.ts` (requires it) | low |
| `plugins/opencode-ponytail-scoped.ts` | instructions.cjs | opencode runtime (auto-load), `deploy/setup.sh`, `opencode_app/` docker | med |
| `plugins/ATTRIBUTION.md` | — | provenance readers; vendored headers reference it | low |
| `agents/*.md` (8 lens files) | `plugins/ponytail/SKILL.md` (lens source) | subagent system prompts, frontmatter-contract tests | low |
| `plugins/opencode-learnings-autoinject.ts` | off-set convention sync only | NOT affected by this change (non-affected consumer, noted for completeness) | none |
| `installer/dependency-map.json` | — | `installer/init.mjs` (reads edges), `tests/test_skill_isolation.bats` (guards requiresSkills parity) | med |
| `installer/init.mjs` | dependency-map.json, verified plugin target path (2.1) | `npx … add` CLI flow, installer tests | high |
| `installer/registry.json` | `installer/build-registry.mjs` | `installer/init.mjs` (reads registry only) | low |
| `tests/` (installer + isolation bats) | installer changes | CI | med |
| `README.md`, `deploy/setup.sh` help, `CHANGELOG.md` | implementation lands | users, docs | low |

## Implementation Phases

### Phase 1: Re-vendor ponytail v4.8.4 → v4.10.0

- [x] **1.1** Apply the upstream `ponytail:` marker rewording to `plugins/ponytail/SKILL.md` ("cut a real corner with a known ceiling"; drop the generic `// ponytail: this exists` example) and bump the vendored-from comment + source URLs to v4.10.0
    — **Why:** the ruleset source is the single source of truth for injected enforcement; the narrowed marker rule is the only semantic drift vs upstream v4.10.0 and the debt-harvest convention depends on it
    — **Done when:** `diff` against the fetched upstream v4.10.0 copy (`/tmp/opencode/ponytail-upstream/ponytail-SKILL.md`) shows only the vendored-header comment as delta
    — **Consumers affected:** `instructions.cjs` (runtime read), 8 agent lens sections, `deploy/setup.sh`, the injected system prompt
    — **Done:** SKILL.md marker rule reworded to upstream v4.10.0 + header bumped; diff vs upstream copy clean (body identical); files: plugins/ponytail/SKILL.md; fixes: none

- [x] **1.2** Bump `plugins/ATTRIBUTION.md` pinned version to v4.10.0
    — **Why:** ATTRIBUTION.md is the pin record every vendored header points at; a stale pin misleads the next deliberate re-vendor
    — **Done when:** file states `Pinned version: v4.10.0 (tag \`v4.10.0\`)`
    — **Consumers affected:** none runtime; provenance readers
    — **Done:** ATTRIBUTION pin now v4.10.0 (tag `v4.10.0`); files: plugins/ATTRIBUTION.md; fixes: none

- [x] **1.3** Re-sync the 8 agent lens provenance markers to `(vendored v4.10.0)` and record a lens-body delta review against the one-bullet upstream change (expected honest outcome: version strings only — no lens paraphrases the marker rule; `rg 'ponytail: this exists' agents/` is already zero pre-work, so that grep alone certifies nothing)
    — **Why:** a provenance marker citing the superseded version is not "re-synced" (AC #2); the delta review is the actual verification that lens bodies need no rewording
    — **Done when:** all 8 `Ponytail lens derived` markers state v4.10.0; the delta-review outcome (version strings only) recorded in the trace; `rg 'ponytail: this exists' agents/` still zero
    — **Consumers affected:** the 8 subagent system prompts; frontmatter-contract tests
    — **Done:** 8/8 Ponytail lens markers now (vendored v4.10.0); delta review: version strings only (no lens paraphrases the marker rule; old-wording grep 0 pre and post); files: agents/*.md ×8; fixes: none

- [x] **1.4** Port persisted-default mode into `plugins/opencode-ponytail-scoped.ts`: config file pinned to `~/.local/share/opencode/ponytail-config.json` (XDG state dir — volume-mounted in docker, goal-plugin precedent `docker-compose.yml:16-17`), resolution order env var → config file → `full`; `/ponytail default <mode>` writes the config; bare `/ponytail` reports the active level instead of resetting
    — **Why:** upstream v4.9.0's only feature with real payoff here — mode choice currently resets between restarts unless the env var is set; pinning the state dir is what makes "survives restart" true for the docker container too (only `~/.local/share/opencode` survives container recreation — `~/.config/opencode/` and `/app/` do not)
    — **Done when:** harness exercise (pattern of `research/ponytail-load-fix.md` §5) proves: default survives plugin re-init, env var wins over config file, bare command reports level, invalid mode args ignored; plus structural assertion that the config path resolves under the volume-mounted state dir (container-recreation survival)
    — **Consumers affected:** opencode runtime (auto-load), `deploy/setup.sh` deploy_plugins(), `opencode_app/` docker (this step owns the docker consumer named in the map)
    — **Done:** persisted default ported: CONFIG_PATH pinned under ~/.local/share/opencode/ (volume-backed), BOM-tolerant merge write, env > file > full, /ponytail default <mode>, bare /ponytail reports level, help updated; files: plugins/opencode-ponytail-scoped.ts; fixes: none

- [x] **1.5** Own the full old-version-string census: `rg -l 'v4\.8\.4' --glob '!PLANS/**'` lists 18 files (8 agent markers covered by 1.3, `plugins/opencode-ponytail-scoped.ts:26`, `plugins/ponytail/instructions.cjs:1`, `README.md:610` + `:741`, `opencode_app/README.md:192`, the 3 derived-skill vendored-header pins, SKILL.md header + ATTRIBUTION covered by 1.1/1.2) — bump every pin to v4.10.0
    — **Why:** a re-vendor that updates 2 of 18 version-bearing files leaves thirteen-plus lying pins; the next maintainer trusts a stale pin — the exact failure `plugins/ATTRIBUTION.md` warns about (plan-review Major)
    — **Done when:** `rg -l 'v4\.8\.4' --glob '!PLANS/**'` returns zero matches (PLAN-533's own phase title legitimately names the from-version)
    — **Consumers affected:** provenance readers; next re-vendor
    — **Done:** census sweep complete: 7 additional pin files bumped; rg v4.8.4 → zero outside PLANS/ + LEARNINGS/ (historical from-version refs, deliberate allowlist); files: README.md, opencode_app/README.md, wrapper header, instructions.cjs header, 3 derived-skill headers; fixes: none

- [x] **1.6** Injection smoke test on the updated ruleset
    — **Why:** proof the v2 plugin still injects end-to-end after the edits — the AC demands the updated wording in the injected block
    — **Done when:** harness output contains `PONYTAIL MODE ACTIVE` and the new ceiling-wording phrase; idempotency (no double-inject) and off-set agent skip checks pass
    — **Consumers affected:** none downstream; phase exit evidence
    — **Done:** tests/test_ponytail_plugin.bats 8/8: marker + ceiling wording + gate sentence + off-empty + old-wording-gone + restart-picks-up + env-wins + merge/BOM/invalid; full suite 542/542; files: tests/test_ponytail_plugin.bats; fixes: test 5 initially asserted same-process session (default resolves at module load) — restructured to two-process restart assertion

### Phase 2: Installer ships the enforcement plugin

- [ ] **2.1** Verify the project-scope plugin discovery path against opencode v2 docs (`opencode.ai/docs/plugins` + source check); in-repo empirical evidence already exists: `opencode_app/Dockerfile:82` (`COPY plugins/ /app/.opencode/plugins/`) and `research/ponytail-load-fix.md` (user-scope `~/.config/opencode/plugins/` glob); record the verified path (or a user-scope-only decision) in the PLAN trace
    — **Why:** the installer must write the plugin where v2 actually discovers it — corroborating docs with the repo's own working docker setup avoids a docs-only mistake
    — **Done when:** PLAN trace block records the decision with doc/source + in-repo citation
    — **Consumers affected:** steps 2.2/2.3 implement against this decision

- [ ] **2.2** Extend `installer/dependency-map.json` with a `shipsPlugins` edge mapping the three ponytail skills to the plugin artifacts (`opencode-ponytail-scoped.ts`, `ponytail/`, `ATTRIBUTION.md`); update the `$comment` schema docs
    — **Why:** the map is the single declarative edge source `init.mjs` reads; a parallel ad-hoc list inside init.mjs would drift on the next edge
    — **Done when:** JSON parses, `$comment` documents the new key, all three ponytail skills listed
    — **Consumers affected:** `installer/init.mjs`; `tests/test_skill_isolation.bats` (must not trip — plugin paths are not skill-to-skill edges)

- [ ] **2.3** Implement the plugin copy in `installer/init.mjs`: ponytail skill install → copy the three artifacts to the target plugin dir (user scope; project scope per 2.1); non-OpenCode targets (`claude`/`agents`/`kimi`/`kilo`) print a notice and skip; `--no-deps` skips the copy too; never overwrite unrelated files in an existing plugin dir (exact-name artifacts only)
    — **Why:** closes the enforcement gap — skill-only installs currently ship docs without runtime injection, which is the core complaint in the ticket
    — **Done when:** a ponytail skill install delivers the plugin artifacts to the verified dir; each non-OpenCode target prints the notice and copies nothing; `--no-deps` skips the copy
    — **Consumers affected:** `npx … add` CLI users; installer tests

- [ ] **2.4** Add installer tests pinning the new behavior — positive (plugin delivered on ponytail install) and negative fixtures (non-OpenCode notice, `--no-deps` skip)
    — **Why:** test-pinned installer behavior is repo convention (#454/#455); error branches need negative fixtures in the same change (LEARNINGS guard-error-branches rule)
    — **Done when:** new bats tests pass alongside the existing suite; both polarity fixtures present
    — **Consumers affected:** CI

- [ ] **2.5** Run the full bats suite + registry drift gate: `node installer/build-registry.mjs --check` must exit 0 (plain run always rewrites `generatedAt` — never commit timestamp churn; zero diff expected since no frontmatter changes are planned; if `--check` exits 1, fix the drift source and commit the content diff, never a generatedAt-only diff)
    — **Why:** frontmatter-contract rule with the repo's canonical gate form (7th documented recurrence of the plain-run phantom avoided); the isolation guard must prove the new edge type doesn't trip it
    — **Done when:** bats green; `installer/build-registry.mjs --check` exits 0; no registry commit (or content-only diff committed if real drift surfaced)
    — **Consumers affected:** CI; `init.mjs` (reads registry only)

### Phase 3: Build/test gate clause + docs

- [ ] **3.1** Gate paragraph is the EXISTING upstream text at `plugins/ponytail/SKILL.md:114-120` ("Lazy code without its check is unfinished…" — already present in v4.8.4 and v4.10.0, not mode-keyed, injects at every level): make ZERO SKILL.md body edits; mirror the existing paragraph into the testing lens (`agents/testing-subagent.md` — no mirror today) and the loop-operator lens (`:189` carries a different "unfinished" sentence); the tdd lens already mirrors it (`agents/tdd-subagent.md:173`)
    — **Why:** AC #1 ("matches upstream modulo the vendored-header comment") and a 3.1 body edit are mutually exclusive — adding house text would duplicate the existing paragraph and retro-falsify 1.1's upstream-match gate; the real gap is the two lenses missing the mirror
    — **Done when:** the exact sentence "Lazy code without its check is unfinished" appears in testing-subagent.md and loop-operator-subagent.md (tdd verified already present); injection smoke output contains the same sentence
    — **Consumers affected:** testing/loop-operator subagent prompts; injected ruleset (assertion only — no change)

- [ ] **3.2** Docs sync: README ponytail sections at `:610` and `:741` (plugin-shipping behavior + non-OpenCode notice); `deploy/setup.sh --help` verified NOT to describe installer behaviors (record the verified no-op outcome — nothing to edit); NO manual CHANGELOG entry — `.github/workflows/release.yml` runs `npx semantic-release` with `@semantic-release/changelog` + `@semantic-release/git` owning `CHANGELOG.md` (hand edits get overwritten at next release; conventional commits on this branch feed the bot — AC #8's "release-please" is a ticket mislabel for the repo's actual engine, record it in the trace)
    — **Why:** AGENTS.md sync rules — a behavior change that outpaces docs is drift; and writing to a bot-owned file is worse than not writing (silent overwrite + merge conflicts)
    — **Done when:** README documents the new deliverable and target-scope behavior; the setup.sh-help no-op and the semantic-release determination are recorded with evidence; commit messages follow Conventional Commits
    — **Consumers affected:** README readers; release automation (via conventional commits)

- [ ] **3.3** Ticket exit gate (full tier): full bats suite, injection smoke with gate sentence, registry check — write the `GATE <short-sha> tier=full` memo line
    — **Why:** the pipeline's run-level last gate is full by contract; review fixes (Step 9) will re-run it on the fixed tree
    — **Done when:** all checks green and the `tier=full` memo line exists for the final tree
    — **Consumers affected:** PR citation (Step 10)

## Technical Notes

- **Gap resolutions (requirements Mode R, 2026-09-22):** G1 gate paragraph = existing upstream text (mirror-only, 3.1); G2 persisted config at `~/.local/share/opencode/ponytail-config.json` (volume-mounted; "survives restart" = plugin re-init + container recreation, structural assertion); G3 full 18-file version census owned by 1.5; G4 registry gated via `--check` (2.5); G5 semantic-release owns CHANGELOG — no manual entry (3.2).
- Upstream v4.10.0 reference copies are fetched to `/tmp/opencode/ponytail-upstream/` for diffing (core SKILL.md, both hooks, three derived skills).
- Derived skill BODIES are already byte-identical to v4.10.0 — the only `skills/ponytail-*-skill/` edits are the vendored-header version pins (1.5 census); frontmatter deltas are intentional house adaptations.
- Skipped deliberately: upstream's Cursor `hooks.json`, Grok adapter, VS Code Copilot detection, pi plumbing — harnesses this repo doesn't ship.
- `dependency-map.json` `$comment` requires HANDOFF_OWNER/HANDOFF parity only for `requiresSkills` pairs; the new `shipsPlugins` key is a different edge type and must not enter that invariant (verified: `tests/test_requires_skills.bats` derives expectations from HANDOFF vars for requiresSkills pairs only; `tests/test_select_items.bats` enumerates impliesMcp values only — a new top-level key breaks neither).
- Plugin wrapper is OpenCode-only by design; the portability story for non-OpenCode targets is skills-on-demand + notice (capability binding per AGENTS.md §Portability contract).
- `deploy/setup.sh` `deploy_plugins()` bulk-copies `plugins/*` (no per-file list, no #456 legacy-list entry needed — no renames); `deploy/setup.ps1` has no plugin handling to mirror.

## Dependencies

- None blocking (`blocked-by:` absent). Upstream npm `@dietrichgebert/ponytail@4.10.0` and GitHub tag `v4.10.0` verified as latest at authoring time.

## Risks & Mitigation

- **Project-scope plugin discovery unverified** → 2.1 verifies before 2.3 implements; fallback is user-scope-only with a documented note.
- **CHANGELOG ownership ambiguous** (release-please format but no workflow grep hit) → 3.2 checks `.github/workflows/` first; manual entry only when no bot owns it.
- **Isolation guard could flag the new edge type** → 2.5 runs the full suite; if `test_skill_isolation.bats` trips, align the edge naming with the guard's source-of-truth vars rather than loosening the guard.
- **Plugin copy could clobber a user's existing plugin dir** → 2.3 constrains writes to exact-name artifacts; never bulk-syncs a directory.

---

## Trace

GATE da25d5f tier=full lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a (Phase 1: whole bats suite 542/542 — agents/ + plugins/ touched, so suite-wide beats scoped; no manifest lint/typecheck/build scripts)
