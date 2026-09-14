# PLAN: Phase 2 — Split deploy/ into installer/ + deploy/

**Branch**: feat/378
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/378
**Base**: main

## Acceptance Criteria

From ticket #378, re-validated against `origin/main` @ `ece1032` (line drift from ticket noted inline):

- [ ] `bats tests/` green (full suite)
- [ ] `node installer/init.mjs --list skills` works
- [ ] `node installer/init.mjs add tdd-subagent --dry-run` resolves paths (local run of the npx flow)
- [ ] `bash deploy/setup.sh --dry-run` passes; `opencode-init` symlink points at the new path
- [ ] `npm pack --dry-run` tarball contains `installer/`
- [ ] Repo-wide sweep: zero references to moved files under old `deploy/` paths (excluding `LEARNINGS/`, `PLANS/` — historical records)

**Re-validation deltas** (ticket line refs → actual @ `ece1032`): setup.sh script vars `99-104` → `97-107`; setup.sh `init_src` `4316` → `4005`; setup.ps1 `114-119` → `112-121`, `2230` → `2225`; Dockerfile `56,75` → `46-84` (whole-`deploy/` COPY at 57 + resolver RUN at 63-69; `merge-packs` at 82-84 **stays** on `/app/deploy/`).

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/` (13 moved paths) | Phase 1 git mv | `package.json` bin, `deploy/setup.sh`, `deploy/setup.ps1`, `opencode_app/Dockerfile`, `.github/workflows/release.yml`, `.releaserc.json`, 3 bats files | high |
| `package.json` `bin` | `installer/init.mjs` exists | Public `npx github:…` flow, npm tarball | high |
| `installer/init.mjs` path constants (`DEPLOY` → installer dir) | mv | Every path join inside init (registry, presets, depmap, tiers, models, resolver; SOURCE_OC unchanged) | high |
| `installer/build-registry.mjs` | mv, before registry regen | CI drift check (`release.yml:50`), `registry.json` regen | med |
| `installer/build-site.mjs`, `installer/resolve-models.mjs`, `installer/source.mjs` | mv | CI lint (`release.yml:55`), Docker build, self-checks | med |
| `deploy/setup.sh` script vars | `installer/` files | resolver/mix/provider flows, `opencode-init` symlink (`:4005`) | high |
| `deploy/setup.ps1` script vars | same | Windows mirror (no pwsh on runner — grep-verified only) | med |
| `deploy/tui.mjs` import | `installer/tui-primitives.mjs` | setup.sh TUI flows | low |
| `opencode_app/Dockerfile` | `COPY installer/` line | `docker compose build` (no docker on runner — textual gate) | med |
| `.github/workflows/release.yml` | moved paths | CI gate, npx tarball guard | high |
| `.releaserc.json` git assets | moved paths | semantic-release release commits | med |
| `tests/{init,test_autoresearch_skills,test_markitdown_skill,test_docling_skill}.bats` | mv | CI bats suite | low |
| Docs: `README.md`, `AGENTS.md`, `MIGRATION.md`, `opencode_app/README.md`, 2× `skills/*/SKILL.md` | mv | Humans; no tests read these paths | low |

## Implementation Phases

### Phase 1: Move + self-contained rewires (npx flow restored)

- [x] **1.1** `git mv` the 13 paths `deploy/` → `installer/`: `init.mjs`, `tui-primitives.mjs`, `source.mjs`, `build-registry.mjs`, `registry.json`, `dependency-map.json`, `presets/`, `agent-tiers.json`, `models.default.json`, `provider-models.json`, `provider-presets.json`, `resolve-models.mjs`, `build-site.mjs`
    — **Why:** Physical split precedes every rewire; `git mv` preserves history.
    — **Done when:** `ls installer/` shows all 13; `git status` lists only renames (R100).
    — **Consumers affected:** all rows of the map (broken until 1.2–1.6 restore them).

- [x] **1.2** `installer/init.mjs`: replace `const DEPLOY = join(REPO, "deploy")` with an installer-dir constant (`const INSTALLER = __dirname;`) and rename all `DEPLOY` uses inside the file; update header comments (`deploy/init.mjs` → `installer/init.mjs`); `SOURCE_OC` unchanged
    — **Why:** init.mjs joins registry/presets/depmap/tiers/models/resolver to `DEPLOY` (7 constants at :44-50) — all co-move, so the dir constant flips to the file's own directory; `REPO = dirname(__dirname)` stays valid (installer/.. = repo root).
    — **Done when:** `grep -c 'join(REPO, "deploy")' installer/init.mjs` = 0; `node --check installer/init.mjs` passes.
    — **Consumers affected:** `--list/--expand/--describe/resolver` flows, bin entry (1.4).

- [x] **1.3** Fix intra-installer path joins + stale self-references: `build-registry.mjs` `TIERS_FILE` :42 AND `OUT_FILE` :43 (`join(REPO, "deploy/…")` → `installer/…` — missing :43 would resurrect the old path on regen) + embedded strings :201,:215 + header comments :2-31; `build-site.mjs:16` + comments :2-8; `resolve-models.mjs` comments :5-7 + runtime error strings :387-388; `source.mjs` comments :1,19,64; `tui-primitives.mjs` header comments :1,4; `$comment` fields in co-moved JSON (`presets/pack-*.json` all files, `dependency-map.json:2`); `deploy/merge-packs.mjs:9` comment (file stays, points at moved sibling)
    — **Why:** These files compute `REPO = dirname(__dirname)` (still correct post-move) but `build-registry.mjs` hardcodes `deploy/` segments for siblings that co-moved (OUT_FILE is the dangerous one); stale comments/`$comment`s would fail the final sweep (5.4) with no owning step. Enumerated from the 1.3/5.4 grep hit set — review finding (step text must cover its own gate's hits).
    — **Done when:** `node --check` on all installer `.mjs`; `grep -rn 'deploy/' installer/` returns 0 (JSON `$comment`s included).
    — **Consumers affected:** CI drift check, registry regen (1.6), Docker resolver.

- [x] **1.4** `package.json` bin: `"opencode-skill": "./deploy/init.mjs"` → `"./installer/init.mjs"`; then `npm install` to regenerate `package-lock.json:11` (embeds the bin path) and commit the lockfile — never hand-edit the lockfile
    — **Why:** Public `npx github:… add <name>` must keep working unchanged — this is the entry the bin resolves after the move; the lockfile mirrors the bin path and `npm ci` hard-fails on drift (repo policy: dependency changes MUST regen the lockfile).
    — **Done when:** `node -e "console.log(require('./package.json').bin)"` prints the installer path; `grep -c 'installer/init.mjs' package-lock.json` ≥ 1; `npm ci --dry-run` (or `npm install --no-audit --no-fund` idempotent run) clean.
    — **Consumers affected:** every npx user (public contract), CI `npm ci` steps.

- [x] **1.5** `deploy/tui.mjs`: import `./tui-primitives.mjs` → `../installer/tui-primitives.mjs`; update comments :5-6
    — **Why:** tui.mjs stays in deploy/, its only import moved — the single cross-package edge enforcing one-way `deploy/ → installer/`.
    — **Done when:** `node --check deploy/tui.mjs`; `node deploy/tui.mjs` (no args) prints usage, exits non-zero.
    — **Consumers affected:** setup.sh TUI flows (`provider-picker` etc.).

- [x] **1.6** Regenerate `installer/registry.json` (`node installer/build-registry.mjs`) and commit the `__meta` generator-note drift
    — **Why:** registry embeds `deploy/build-registry.mjs` in its generator note; regen keeps `--check` green in CI.
    — **Done when:** `node installer/build-registry.mjs --check` exits 0; `git diff` shows only the `__meta` line.
    — **Consumers affected:** CI drift gate, README category table provenance.

**Phase gate:** `node --check installer/*.mjs deploy/tui.mjs`; `node installer/init.mjs --list skills`; `node installer/init.mjs add tdd-subagent --dry-run`; `node installer/build-registry.mjs --check`.

### Phase 2: setup.sh + setup.ps1 rewires

- [x] **2.1** `deploy/setup.sh`: add `INSTALLER_DIR="${REPO_DIR}/installer"` (:97 block); repoint `RESOLVER_SCRIPT` (:99), `AGENT_TIERS` (:105), `MODELS_DEFAULT_MAP` (:106), `PROVIDER_PRESETS` (:107) to `${INSTALLER_DIR}`; `init_src` :4005 → `${REPO_DIR}/installer/init.mjs` (comment :4000); the inline `--status` read of `${REPO_DIR}/deploy/models.default.json` at :3856 → installer path (its `|| echo` fallback silently masks a missing file — grep gate must not be the only net)
    — **Why:** setup.sh consumes the resolver + tier metadata (shared catalog data — lives in installer/ per ticket decision) and symlinks `opencode-init`; `DEPLOY_DIR` stays for merge-packs/packs/apply-skill-profile/skill-profiles/tui which remain local.
    — **Done when:** `bash -n deploy/setup.sh` passes; `grep -nE 'deploy/(init\.mjs|resolve-models|agent-tiers|models\.default|provider-presets)' deploy/setup.sh` = 0 (includes the :3856 inline read).
    — **Consumers affected:** resolver/mix/provider flows, `opencode-init` symlink (AC 4), `--status` output.

- [x] **2.2** `deploy/setup.ps1` mirror: `$InstallDir = Join-Path $RepoDir "installer"`; repoint `$ResolverScript`, `$AgentTiers`, `$ModelsDefaultMap`, `$ProviderPresets` (:113,119-121) and `$initSrc` :2225 (`deploy\init.mjs` → `installer\init.mjs`); comment :2222
    — **Why:** Windows mirror must track setup.sh exactly or the flows diverge across platforms.
    — **Done when:** separator-agnostic `grep -nE 'deploy[/\\](init\.mjs|resolve-models\.mjs|agent-tiers\.json|models\.default\.json|provider-presets\.json)' deploy/setup.ps1` = 0 (lesson from #384: match backslash paths).
    — **Consumers affected:** Windows users (unverified runtime — grep only, no pwsh on runner).

**Phase gate:** `bash -n deploy/setup.sh`; `bash deploy/setup.sh --dry-run` passes; both separator-agnostic greps return 0 matches.

### Phase 3: Dockerfile + CI/release

- [x] **3.1** `opencode_app/Dockerfile`: add `COPY installer/ /app/installer/` after :57; `RUN node /app/installer/resolve-models.mjs` (:63); repoint `--tiers/--default-map/--provider-models/--presets` args (:66-69) to `/app/installer/…`; update comment :46. `merge-packs` (:82-84) stays on `/app/deploy/`.
    — **Why:** Docker build resolves models from tier metadata (now installer/); merge-packs + packs stay deploy-local — the COPY split makes the one-way dependency visible in the image.
    — **Done when:** `grep -n 'installer' opencode_app/Dockerfile` shows COPY + 5 rewritten refs; `grep -n '/app/deploy/' opencode_app/Dockerfile` shows only merge-packs lines.
    — **Consumers affected:** `docker compose build` (textual gate only — no docker on runner).

- [x] **3.2** `.github/workflows/release.yml`: `node installer/build-registry.mjs --check` (:50); `node --check installer/init.mjs installer/source.mjs installer/build-site.mjs` (:55); `node installer/build-site.mjs` (:151); echo text :49; extend tarball guard :60 with `echo "$tarball" | grep -q " installer/"`
    — **Why:** CI must gate the new paths and the tarball guard is the only automated check that the npx flow's bin dir ships.
    — **Done when:** `grep -nE 'deploy/(init\.mjs|source\.mjs|build-registry|build-site|registry)' .github/workflows/release.yml` = 0; guard line includes `installer/`.
    — **Consumers affected:** every CI run, release pipeline.

- [x] **3.3** `.releaserc.json` git assets (:130-132): `deploy/{init,source,build-site}.mjs` → `installer/…` (`deploy/setup.sh`/`ps1` stay)
    — **Why:** semantic-release commits build artifacts back; pointing at moved paths would silently stop committing the installer sources.
    — **Done when:** assets array lists `installer/init.mjs`, `installer/source.mjs`, `installer/build-site.mjs`.
    — **Consumers affected:** release commits (chore(release) SHA).

**Phase gate:** `npm pack --dry-run 2>&1` output greps `installer/`, `skills/`, `agents/`; all Phase 3 grep assertions pass.

### Phase 4: Test rewires

- [x] **4.1** Rewire moved-path refs: `tests/init.bats:8-9` (init.mjs, registry.json), `tests/test_autoresearch_skills.bats:59,76,93` (agent-tiers.json), `tests/test_markitdown_skill.bats:105` (registry.json), `tests/test_docling_skill.bats:137` (dependency-map.json)
    — **Why:** These 4 bats files reference moved files at runtime (13 bats files exist; the rest reference only `deploy/setup.sh`/`ps1` which stay) — review finding: docling's dependency-map read was outside the original enumeration and its grep.
    — **Done when:** the full 5.4 sweep pattern restricted to `tests/` returns 0 (`grep -rnE 'deploy/(init\.mjs|build-registry|registry\.json|source\.mjs|resolve-models|agent-tiers|models\.default|provider-(models|presets)|tui-primitives|presets/|dependency-map|build-site)' tests/`).
    — **Consumers affected:** CI bats suite.

**Phase gate:** per-file `bats` on the 4 rewired files plus `cleanup_old_backups`, `parse_arguments`, `test_backup_rollback`, `test_count_drift`, `test_mcp_count_consistency`, `test_pack_permissions` — all green (full suite).

### Phase 5: Docs + final sweep

- [ ] **5.1** `README.md`: tier-file paths (:84, :100), registry provenance note (:561); sweep remaining moving-file refs
    — **Why:** README documents the file tree users navigate; stale paths break discoverability of the split.
    — **Done when:** `grep -nE 'deploy/(init\.mjs|build-registry|registry\.json|source\.mjs|resolve-models|agent-tiers|models\.default|provider-(models|presets)|tui-primitives|presets/|dependency-map|build-site)' README.md` = 0.
    — **Consumers affected:** humans; doc-consistency skill.

- [ ] **5.2** `AGENTS.md` (:35, :49, :80) and `MIGRATION.md` (:53-68, :253, :261): same path rewires
    — **Why:** AGENTS.md is the repo's agent-facing source-of-truth (tier table file paths); MIGRATION.md documents the model system layout.
    — **Done when:** same grep = 0 on both files.
    — **Consumers affected:** future agent sessions, users migrating.

- [ ] **5.3** `opencode_app/README.md` (:39 Docker copy description) and `skills/opencode-agent-creation-skill/SKILL.md:52`, `skills/opencode-skill-creation-skill/SKILL.md:135`
    — **Why:** Docker README describes the build context; the two SKILL.md files cite `deploy/agent-tiers.json` and `deploy/build-registry.mjs` as repo layout examples. SKILL.md frontmatter is untouched (body text only — no registry impact).
    — **Done when:** grep = 0 on all three files; `node installer/build-registry.mjs --check` still green (proves no frontmatter drift).
    — **Consumers affected:** Docker users; skill readers.

- [ ] **5.4** Final repo-wide sweep: `grep -rnE 'deploy/(init\.mjs|build-registry|registry\.json|source\.mjs|resolve-models|agent-tiers|models\.default|provider-(models|presets)|tui-primitives|presets/|dependency-map|build-site)' .` excluding `.git/`, `node_modules/`, `LEARNINGS/`, `PLANS/` → 0 hits
    — **Why:** LEARNINGS/PLANS are historical records of past work (their refs were true at write time); everything else must reflect the new layout.
    — **Done when:** sweep returns 0.
    — **Consumers affected:** none (verification step).

**Phase gate:** full `bats tests/` suite green; re-run AC gates 1-6; `bash deploy/setup.sh --dry-run`.

## Technical Notes

- Dependency direction stays one-way: `deploy/ → installer/ → content` (root `skills/`, `agents/`, `plugins/`). No cycles.
- Model tiering metadata (`agent-tiers.json`, `models.default.json`, `provider-*.json`, `resolve-models.mjs`) lives in `installer/` because all three tools consume it: installer CLI, setup.sh deploy, Docker build.
- `registry.json` regeneration (1.6) changes only its `__meta` generator note — content counts unchanged (149 skills / 34 agents invariant).
- `deploy/.AGENTS.md:41` references `deploy/skill-profiles.json` — stays, no change.
- Known limitation: no pwsh on runner — setup.ps1 changes are grep-verified only (same note as PR #384); no docker — Dockerfile is textually verified only; `release.yml` has no docker build job.
- Branch re-synced to `origin/main` @ `ece1032` after PR #388 (goal plugin) landed; #388 touched none of this PLAN's anchor files.

## Dependencies

- None (Phase 1 of the epic landed as #384 / `65212e2`, included in base).
- Later phases depend on this: #377 (`--target`), #380 (v2 normalization), #379 (`update` command).

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Public npx flow breaks (bin path / tarball missing `installer/`) | AC gates 2-3 locally; tarball guard extended in 3.2; `npm pack --dry-run` in Phase 3 gate |
| setup.ps1 divergence (no pwsh runner) | Mirror edit 2.2 + separator-agnostic grep (lesson from #384 backslash paths); PR note for a future Windows CI pass |
| registry.json churn / hash mismatch | Single regen in 1.6, committed atomically; `--check` gate in CI |
| Docker build breakage undetected | Textual grep gates on Dockerfile; no docker job exists in CI today — noted in PR body |
| semantic-release stops committing moved sources | 3.3 asset rewire + release.yml greps |
| PR-branch CI red window: release.yml runs per push; Phases 1-3 pushes leave drift/lint/bats pointing at moved paths until Phase 4 | Expected and documented in the PR body — only the post-Phase-4 (final) state gates merge; alternative (batch Phases 1-4 into one push) rejected to keep per-phase atomic commits |
| Missed references elsewhere | 5.4 repo-wide sweep is an acceptance criterion |
