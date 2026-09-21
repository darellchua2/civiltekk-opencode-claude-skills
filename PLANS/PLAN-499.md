# PLAN: Deploy scripts install v1 opencode-ai instead of @opencode/cli

**Branch**: feat/499
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/499
**Base**: main

## Acceptance Criteria
- [x] Fresh-install path in `setup_opencode()` runs `npm install -g @opencode/cli`
- [x] `update_opencode_cli()` and `check_for_updates_only()` compare against `@opencode/cli`
- [x] A detected v1 (`1.x`) install is offered the uninstall-then-install migration instead of a silent in-place "update"
- [ ] `validate_opencode_install()` hint, `--help` text, and `print_summary()` labels reference `@opencode/cli`
- [ ] `setup.ps1` header documents the v2 install command
- [ ] `README.md` flag descriptions no longer say "requires opencode-ai installed"
- [ ] `bash -n deploy/setup.sh` passes; deploy-related bats suite stays green

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` `setup_opencode()` | — | End users/CI running full setup; `update_opencode_cli()` shares the install/update idiom | med — wrong package name = broken installs |
| `deploy/setup.sh` `update_opencode_cli()` | `setup_opencode()` idiom (keep both consistent) | `./setup.sh --update` / `update` subcommand users | med |
| `deploy/setup.sh` `check_for_updates_only()` | — | `./setup.sh -C` / `--check-catalog` adjacent update checks | low |
| `deploy/setup.sh` `validate_opencode_install()` | — | `tests/test_skills_only_parity.bats` (stubs it — name-level contract only, no body pins) | low |
| `deploy/setup.sh` help text + `print_summary()` labels | — | Humans reading `--help` / setup summary | low |
| `deploy/setup.ps1` (header comment) | — | Windows users reading the launcher; forwards everything to setup.sh | low |
| `README.md` flag rows (lines 65, 147) | deploy/setup.sh flag semantics (unchanged) | Readers of the flags table | low |

Out of scope (must NOT change): `@opencode-ai/plugin` references (plugin SDK package, unrelated), `docker-compose.yml` / `opencode_app/Dockerfile` v1-vs-v2 explanatory comments (they deliberately name the v1 package), `research/`, `LEARNINGS/`.

## Implementation Phases

### Phase 1: Install + update paths target the v2 package (`deploy/setup.sh`)
- [x] **1.1** In `setup_opencode()`, rename every npm reference from `opencode-ai` to `@opencode/cli` (fresh install, reinstall, update, `npm view` probe) and normalize the current-version probe to extract a bare semver (`grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1`) so the equality check against `npm view @opencode/cli version` can actually match (today `opencode --version` prints `opencode v2.0.11`, which never equals `2.0.11`).
    — **Why:** These are the AC-1/AC-2 sites; the version normalization is what makes the AC-2 comparison meaningful rather than perpetually "update available".
    — **Done when:** `grep -n "opencode-ai" deploy/setup.sh` shows no remaining hits inside `setup_opencode()`; the version probe yields a bare `x.y.z`.
    — **Consumers affected:** full-setup users; `--update` users.
    — **Done:** all npm refs in setup_opencode renamed to @opencode/cli (install/reinstall/update/probe); probe normalized to bare semver; stub sim: v2.0.11 vs latest 2.0.11 reports "already up to date" (equality now matches); files: deploy/setup.sh; fixes: none
- [x] **1.2** In `setup_opencode()`, add a v1-detection branch before the update prompt: if the normalized current version starts with `1.`, warn that v1 is frozen and the official migration is `npm uninstall -g opencode-ai` **then** `npm install -g @opencode/cli@latest`, and offer it via `prompt_yes_no` (default y; run through `run_cmd` so `--dry-run` previews it).
    — **Why:** AC-3 — the v2 docs (migrate-v1) require removing the package-managed v1 install before v2; the two packages fight over the same `opencode` bin link.
    — **Done when:** simulating a `1.x` version reaches the migration prompt; declining leaves the system untouched; `--dry-run` prints `[DRY-RUN] Would execute:` lines only.
    — **Consumers affected:** machines provisioned by earlier runs of this script (the v1 population this bug created).
    — **Done:** `case "$current_version" in 1.*)` branch added before the update logic; stub sim (opencode v1.18.31): reaches migration prompt, runs uninstall-then-install, reports success, never falls through to update logic; files: deploy/setup.sh; fixes: none
- [x] **1.3** In `update_opencode_cli()`, apply the same package rename, the same semver normalization, and the same v1-detection migration branch (shared idiom with 1.1/1.2, per this file's existing convention of one body per entry point).
    — **Why:** AC-2/AC-3 — `--update` must not "update" a v2 install down to v1, and must offer v1 machines the migration.
    — **Done when:** `update_opencode_cli()` contains no `opencode-ai` install/view references; a `1.x` detection reaches the migration prompt.
    — **Consumers affected:** `./setup.sh --update` / `update` subcommand users.
    — **Done:** rename + normalization + v1 branch applied (incl. both new_version probes); stub sim: v1.18.31 → prompt → uninstall + @opencode/cli@latest; files: deploy/setup.sh; fixes: none

### Phase 2: Message surface (`deploy/setup.sh`)
- [x] **2.1** Rename remaining `opencode-ai` mentions in `check_for_updates_only()` (npm probe + log strings), `validate_opencode_install()` (install hint), the `--help`/header comment blocks (lines ~30, 38, 51, 522, 533–537, 666, 761), and `print_summary()` status labels (lines ~4507–4512) to `@opencode/cli` (prose labels may read "OpenCode CLI (@opencode/cli)").
    — **Why:** AC-4 — help and summary text that says `opencode-ai` sends users to the frozen v1 package even after the logic is fixed.
    — **Done when:** `grep -n "opencode-ai" deploy/setup.sh` returns only v1-detection/migration strings (uninstall target + explanatory "v1-only" prose), zero install/probe/hint references.
    — **Consumers affected:** humans reading `--help`, the setup summary, and `--skills-only` validation failures.
    — **Done:** all listed sites renamed (verified: 8 remaining matches are exactly the v1-migration strings + explanatory comments); check_for_updates_only probe normalized to bare semver; files: deploy/setup.sh; fixes: none

### Phase 3: Windows launcher + README parity
- [ ] **3.1** In `deploy/setup.ps1`, extend the `# Requires:` header comment to state the CLI install command: `npm install -g @opencode/cli` (v2 scoped package).
    — **Why:** AC-5 — the launcher has no install logic of its own, so its header is the only place a ps1-only reader learns how to install the CLI.
    — **Done when:** the header names `@opencode/cli` and the file still parses as a PowerShell param block (no logic touched).
    — **Consumers affected:** Windows users.
- [ ] **3.2** In `README.md` lines 65 and 147, change "requires opencode-ai installed" to "requires @opencode/cli installed".
    — **Why:** AC-6 — docs must match the renamed flag prerequisites or contradict the scripts.
    — **Done when:** `grep -n "opencode-ai" README.md` returns nothing.
    — **Consumers affected:** README readers.

### Phase 4: Verification gate
- [ ] **4.1** Run `bash -n deploy/setup.sh`, then the repo's deploy-relevant test suite (`bats tests/` — at minimum `tests/test_skills_only_parity.bats`, the only suite referencing a touched function) and a dry-run smoke (`./deploy/setup.sh --dry-run -y --skills-only` is out of scope — use a non-mutating flag path such as `--help` plus `bash -n`) to confirm no syntax or stub breakage.
    — **Why:** AC-7 — the gate contract requires lint (bash -n) + tests on touched logic paths.
    — **Done when:** `bash -n` exits 0 and the parity bats suite passes.
    — **Consumers affected:** CI (the PR gate runs the same suite).

## Technical Notes
- npm ground truth (verified 2026-09-21): `opencode-ai` latest = 1.18.31 (v1-only, frozen); `@opencode/cli` latest = 2.0.11 (v2 line). Confirmed against `LEARNINGS/solutions/docker-v1-binary-ignores-v2-plugins-key.md` and the v2 migrate-v1 docs ("Remove a package-managed V1 installation before installing V2").
- `run_cmd` supports multi-arg form; prefer `run_cmd npm install -g @opencode/cli@latest` (spaces preserved, no eval).
- The v1-detection case pattern `1.*)` on the normalized semver is sufficient — npm `@opencode/cli` will never emit a 1.x.
- Keep `npm uninstall -g opencode-ai` naming the v1 package literally — that is the one place the old name must remain.

## Dependencies
None — single contained ticket, no `blocked-by:` refs.

## Risks & Mitigation
- **Bin-link fight if v1 is not uninstalled first** — mitigated by the explicit uninstall-then-install order in the migration branch (1.2/1.3).
- **Version-probe format drift** (`opencode v2.0.11` today, other formats historically) — mitigated by extracting the semver with a regex instead of trusting the full string.
- **Bats stubs** — `validate_opencode_install` is stubbed by `tests/test_skills_only_parity.bats`; message-body changes cannot break a stub override (name-level contract only).

## Gate Trace

Full tier on every phase — deploy files are a critical-area anchor (§Tiered gating #1) and the ticket exit gate is full unconditionally. Lint = `bash -n deploy/setup.sh` (shellcheck not installed — closest executable substitute). Typecheck/build: no manifest targets exist in this repo (package.json has no scripts) — n.a, nothing invented. Unit = full vendored bats suite (`tests/lib/bats-core/bin/bats tests/`). E2E = n.a per the E2E rule (no Playwright; scripts/docs only). Pre-existing (identical on base, verified): BW01 warning in test_subcommands.bats (`load_user_preset` 127 via `bash -c` source — function-visibility quirk unrelated to this change).

### Phase 1
- WORK LOG: full-tier escalation reason — deploy/config file anchor (deploy/setup.sh).
- WORK LOG: verification also included a 15-assertion stub harness (/tmp/opencode/plan499-phase1-sanity.sh) covering v1 migration, normalization equality, outdated-update, fresh-install, and update-path v1 detection — all green.
- GATE ae5ba79 tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a — bash -n ok; bats 517 ok / 0 fail.

### Phase 2
- WORK LOG: deliberate deviation — while renaming check_for_updates_only's update hint, the stale text pointing at the removed `-A -S` auto-update flags (#474) was replaced with `-C` / `--update` guidance; same line, already being rewritten.
- GATE (pending-commit sha) tier=full lint=t typecheck=n.a build=n.a unit=t e2e=n.a — bash -n ok; bats 517 ok / 0 fail.
