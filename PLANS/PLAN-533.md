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
| `installer/dependency-map.json` | — | `installer/init.mjs` (reads edges), `tests/test_skill_isolation.bats` (guards requiresSkills parity) | med |
| `installer/init.mjs` | dependency-map.json, verified plugin target path (2.1) | `npx … add` CLI flow, installer tests | high |
| `installer/registry.json` | `installer/build-registry.mjs` | `installer/init.mjs` (reads registry only) | low |
| `tests/` (installer + isolation bats) | installer changes | CI | med |
| `README.md`, `deploy/setup.sh` help, `CHANGELOG.md` | implementation lands | users, docs | low |

## Implementation Phases

### Phase 1: Re-vendor ponytail v4.8.4 → v4.10.0

- [ ] **1.1** Apply the upstream `ponytail:` marker rewording to `plugins/ponytail/SKILL.md` ("cut a real corner with a known ceiling"; drop the generic `// ponytail: this exists` example) and bump the vendored-from comment + source URLs to v4.10.0
    — **Why:** the ruleset source is the single source of truth for injected enforcement; the narrowed marker rule is the only semantic drift vs upstream v4.10.0 and the debt-harvest convention depends on it
    — **Done when:** `diff` against the fetched upstream v4.10.0 copy (`/tmp/opencode/ponytail-upstream/ponytail-SKILL.md`) shows only the vendored-header comment as delta
    — **Consumers affected:** `instructions.cjs` (runtime read), 8 agent lens sections, `deploy/setup.sh`, the injected system prompt

- [ ] **1.2** Bump `plugins/ATTRIBUTION.md` pinned version to v4.10.0
    — **Why:** ATTRIBUTION.md is the pin record every vendored header points at; a stale pin misleads the next deliberate re-vendor
    — **Done when:** file states `Pinned version: v4.10.0 (tag \`v4.10.0\`)`
    — **Consumers affected:** none runtime; provenance readers

- [ ] **1.3** Re-sync the agent lens sections quoting the old marker wording — `rg 'ponytail: this exists' agents/` must go to zero; keep each lens's provenance marker intact
    — **Why:** lens sections are static distillations of the ruleset; stale wording silently diverges subagent guidance from the injected ruleset the moment 1.1 lands
    — **Done when:** `rg 'ponytail: this exists' agents/` returns no matches; `rg 'Ponytail lens derived' agents/` still finds all 8 markers
    — **Consumers affected:** the 8 subagent system prompts; frontmatter-contract tests

- [ ] **1.4** Port persisted-default mode into `plugins/opencode-ponytail-scoped.ts`: resolution order env var → config file → `full`; `/ponytail default <mode>` writes the config; bare `/ponytail` reports the active level instead of resetting
    — **Why:** upstream v4.9.0's only feature with real payoff here — mode choice currently resets between restarts unless the env var is set; mirror upstream resolution order for least surprise
    — **Done when:** harness exercise (pattern of `research/ponytail-load-fix.md` §5) proves: default survives plugin re-init, env var wins over config file, bare command reports level, invalid mode args ignored
    — **Consumers affected:** opencode runtime (auto-load), `deploy/setup.sh` deploy_plugins(), `opencode_app/` docker

- [ ] **1.5** Injection smoke test on the updated ruleset
    — **Why:** proof the v2 plugin still injects end-to-end after the edits — the AC demands the updated wording in the injected block
    — **Done when:** harness output contains `PONYTAIL MODE ACTIVE` and the new ceiling-wording phrase; idempotency (no double-inject) and off-set agent skip checks pass
    — **Consumers affected:** none downstream; phase exit evidence

### Phase 2: Installer ships the enforcement plugin

- [ ] **2.1** Verify the project-scope plugin discovery path against opencode v2 docs (`opencode.ai/docs/plugins` + source check); record the verified path (or a user-scope-only decision) in the PLAN trace
    — **Why:** the installer must write the plugin where v2 actually discovers it — user scope is documented (`~/.config/opencode/plugins/`), project scope is not yet verified in this repo
    — **Done when:** PLAN trace block records the decision with doc/source citation
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

- [ ] **2.5** Run the full bats suite + `node installer/build-registry.mjs`; commit `registry.json` if changed
    — **Why:** frontmatter-contract rule — registry is generated and must be committed after any registry-affecting change; the isolation guard must prove the new edge type doesn't trip it
    — **Done when:** bats green; `git status` clean on `installer/registry.json` or its diff committed
    — **Consumers affected:** CI; `init.mjs` (reads registry only)

### Phase 3: Build/test gate clause + docs

- [ ] **3.1** Add the build/test gate paragraph to `plugins/ponytail/SKILL.md` (before declaring build/test done: no new dependency for what stdlib covers, no speculative abstraction, non-trivial logic landed with one runnable check) and mirror it into the tdd/testing/loop-operator lens sections
    — **Why:** the ruleset source is the single injection point — gate text in `instructions.cjs` would fork the ruleset; the three named agents own build/test work and need the mirrored clause
    — **Done when:** paragraph present in SKILL.md; the three named agent files mirror it; injection smoke output includes the gate sentence
    — **Consumers affected:** injected ruleset (primary + non-off-set agents); tdd/testing/loop-operator subagent prompts

- [ ] **3.2** Docs sync: README installer section (plugin-shipping behavior + non-OpenCode notice), `deploy/setup.sh` help text iff it describes installer behaviors, CHANGELOG per release-please convention (check `.github/workflows/` first; conventional commits only if bot-managed, manual entry otherwise)
    — **Why:** AGENTS.md sync rules — a behavior change that outpaces docs is drift; counts stay unchanged (no new skills/agents)
    — **Done when:** README documents the new deliverable and its target-scope behavior; CHANGELOG handled per the detected convention
    — **Consumers affected:** README readers; `setup.sh --help` users

- [ ] **3.3** Ticket exit gate (full tier): full bats suite, injection smoke with gate sentence, registry check — write the `GATE <short-sha> tier=full` memo line
    — **Why:** the pipeline's run-level last gate is full by contract; review fixes (Step 9) will re-run it on the fixed tree
    — **Done when:** all checks green and the `tier=full` memo line exists for the final tree
    — **Consumers affected:** PR citation (Step 10)

## Technical Notes

- Upstream v4.10.0 reference copies are fetched to `/tmp/opencode/ponytail-upstream/` for diffing (core SKILL.md, both hooks, three derived skills).
- Derived skill bodies are already byte-identical to v4.10.0 — no edits to `skills/ponytail-*-skill/` beyond nothing at all; frontmatter deltas are intentional house adaptations.
- Skipped deliberately: upstream's Cursor `hooks.json`, Grok adapter, VS Code Copilot detection, pi plumbing — harnesses this repo doesn't ship.
- `dependency-map.json` `$comment` requires HANDOFF_OWNER/HANDOFF parity only for `requiresSkills` pairs; the new `shipsPlugins` key is a different edge type and must not enter that invariant.
- Plugin wrapper is OpenCode-only by design; the portability story for non-OpenCode targets is skills-on-demand + notice (capability binding per AGENTS.md §Portability contract).

## Dependencies

- None blocking (`blocked-by:` absent). Upstream npm `@dietrichgebert/ponytail@4.10.0` and GitHub tag `v4.10.0` verified as latest at authoring time.

## Risks & Mitigation

- **Project-scope plugin discovery unverified** → 2.1 verifies before 2.3 implements; fallback is user-scope-only with a documented note.
- **CHANGELOG ownership ambiguous** (release-please format but no workflow grep hit) → 3.2 checks `.github/workflows/` first; manual entry only when no bot owns it.
- **Isolation guard could flag the new edge type** → 2.5 runs the full suite; if `test_skill_isolation.bats` trips, align the edge naming with the guard's source-of-truth vars rather than loosening the guard.
- **Plugin copy could clobber a user's existing plugin dir** → 2.3 constrains writes to exact-name artifacts; never bulk-syncs a directory.
