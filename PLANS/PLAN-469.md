# PLAN: plugin/shim deploy parity drift in skills-only (bash vs ps1)

**Branch**: feat/469
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/469
**Base**: main

## Acceptance Criteria
- [x] bash `deploy_skills_only()` (the one body behind `--skills-only`, menu option 2, and the headless default) now also runs `deploy_plugins` and `setup_opencode_init_symlink` — membership identical to ps1 `-SkillsOnly`, which chains Deploy-Plugins + Setup-OpencodeInitShim (setup.ps1:1832-1833) via its config path
- [x] setup.ps1 untouched (it is the correct side)
- [x] Class-sibling fix found during recon: `setup_opencode_init_symlink`'s bare `mkdir -p` and `ln -sf` bypass run_cmd and really create `~/.local/bin/opencode-init` during dry-run (#467 class; missed by #467's audit pattern which didn't cover ln) — both routed through run_cmd
- [x] bats: (a) source pin — deploy_skills_only body contains both calls; (b) functional — a real (non-dry) deploy_skills_only in a sandboxed HOME deploys the plugins dir and the opencode-init symlink, while a dry run creates neither; (c) ps1 parity pin — the ps1 skills-only-reachable config path greps both Deploy-Plugins and Setup-OpencodeInitShim
- [x] Full gate green; --quick and full paths byte-identical behavior (they already deployed plugins+shim)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `deploy/setup.sh` deploy_skills_only | deploy_plugins, setup_opencode_init_symlink (both exist) | flag path, menu case 2, headless default (#466) | low |
| `deploy/setup.sh` setup_opencode_init_symlink | — | main full path (pre-existing caller), now deploy_skills_only | low — dry-run gating only |
| `deploy/setup.ps1` | — (reference implementation; untouched) | Windows users | none |
| `tests/test_skills_only_parity.bats` (new) | the setup.sh edits | CI bats job | low |

## Implementation Phases

### Phase 1: membership parity + the ln dry-run leak
- [x] **1.1** deploy_skills_only: add `deploy_plugins || true` after `deploy_agents || true` and `setup_opencode_init_symlink || true` after that (bash full-path ordering: agents → plugins → symlink)
    — **Why:** The drift is real user impact, not cosmetics: opencode-* plugins include the auto-continue hook (enabled by default) — bash skills-only users silently ran without it while Windows users got it. Membership must be a platform property, not a mode accident.
    — **Done when:** the function body contains both calls; a dry run of it creates neither plugins dir nor symlink; a real run creates both (pinned in 2.1).
    — **Consumers affected:** bash skills-only users gain plugins + shim (aligning with Windows and with --quick).
    — **Done:** deploy_plugins + setup_opencode_init_symlink added after deploy_agents (bash full-path ordering), parity comment cites ps1:1832-1833; files: deploy/setup.sh; fixes: none
- [x] **1.2** setup_opencode_init_symlink: route `mkdir -p "$user_bin"` and `ln -sf` through run_cmd; keep the readlink correctness check unguarded (read-only)
    — **Why:** Same #467 class (bare writes bypass run_cmd) — surfaced during this recon because 1.1 widens the function's reachability into the headless-default dry-run path; fixing it here avoids a fourth ticket for a 3-line gate.
    — **Done when:** grep shows `run_cmd mkdir -p "$user_bin"` and `run_cmd ln -sf`; dry run of the function leaves no `~/.local/bin/opencode-init` in a sandboxed HOME.
    — **Consumers affected:** dry-run users only; real runs byte-identical.
    — **Done:** mkdir + ln -sf through run_cmd with class comment; dry probe creates no shim, real probe creates it (pinned in 2.1); files: deploy/setup.sh; fixes: none
- [x] **1.3** Class re-audit with a WIDER pattern than #467's (add `ln -sf`, `mkdir -p` outside run_cmd, `setx`, `tee `): list remaining bare writes in dry-reachable functions and either gate them here (trivial, same class) or file them
    — **Why:** #467's audit pattern missed ln because it only looked for redirection/sed shapes; a wider sweep closes the class properly.
    — **Done when:** sweep output documented in the PLAN Done line — every remaining bare write either gated in this PR or named as a filed follow-up.
    — **Consumers affected:** none (audit).
    — **Done:** wide sweep (ln -sf, setx, tee, bare mkdir): setx_env gated (persistent user env var — same class); bare mkdir hits triaged as benign empty-dir clutter (BACKUP_DIR/CONFIG_DIR/pre_dir/peonping download dir — pre-existing, no config mutation) — recorded for #470's plan validation to absorb, not filed separately; files: deploy/setup.sh; fixes: none
- [x] **1.4** Ticket comment on #469 (or PR body note) recording the decision rationale: plugins+shim are core functionality (auto-continue hook is default-enabled), so "skills-only" mode semantics stay "no API keys / no Node management" — the auxiliary core still ships. Alternative (strip plugins from ps1 too) rejected: it would regress Windows users mid-epic.
    — **Why:** The ticket says "pick one behavior" — the pick and its rejection must be recorded where future maintainers see it.
    — **Done when:** rationale present in the PR body.
    — **Consumers affected:** none (documentation).
    — **Done:** rationale recorded in PR body (plugins+shim are core functionality; stripping ps1 rejected as a Windows regression); files: —; fixes: none

### Phase 2: parity pins + full gate
- [x] **2.1** New tests/test_skills_only_parity.bats: (a) source pin — the deploy_skills_only body (awk-extracted function text) contains deploy_plugins and setup_opencode_init_symlink; (b) functional real run — sandboxed HOME, stubbed command_exists/check_dependencies, DRY_RUN=false: `~/.config/opencode/plugins/` exists and `~/.local/bin/opencode-init` exists after the call; (c) functional dry run — same stubs, DRY_RUN=true: neither artifact exists; (d) ps1 parity pin — setup.ps1 greps Deploy-Plugins and Setup-OpencodeInitShim adjacent (:1832-1833 region)
    — **Why:** Membership parity is the ticket's definition of done; the dry/real artifact pair also re-pins 1.2's gate in both directions.
    — **Done when:** `bats tests/test_skills_only_parity.bats` green.
    — **Consumers affected:** CI bats job.
    — **Done:** 4/4 ok — source pin, real-run artifact pins (plugins dir + symlink), dry-run absence pins, ps1 region parity pin; files: tests/test_skills_only_parity.bats; fixes: none
- [x] **2.2** Full gate: `bash -n deploy/setup.sh`, `bats tests/`, `node --test tests/*.test.ts`; diff scope = setup.sh + new test only (ps1 untouched)
    — **Why:** Gate contract.
    — **Done when:** all green; scope as stated.
    — **Consumers affected:** none.
    — **Done:** bash -n ok; bats 433 ok / 0 fail (429 + 4); node --test 30/0; diff = setup.sh + new test (ps1 untouched); files: —; fixes: none

## Technical Notes
- ps1 reference: `-SkillsOnly` → Set-Configuration → (Deploy-Plugins, Setup-OpencodeInitShim at :1832-1833) → Show-Summary. bash equivalent ordering inside deploy_skills_only: config → agents → plugins → symlink → learnings → summary.
- The headless default (#466) routes through deploy_skills_only, so this change also widens plugin/shim reachability in CI-style runs — intended, same parity argument.
- #470 will restructure all of this into the plan executor; the parity fix must not be deferred to it because the drift ships broken Windows-vs-Linux behavior today.

## Dependencies
None — standalone. Part of epic #464.

## Risks & Mitigation
- **Functional test weight** (deploy_agents runs init.mjs for real in the sandbox): mitigated by HOME sandboxing and `|| true` guards; if too slow, the artifact assertions can move to calling deploy_plugins directly while the source pin keeps the membership contract — but only if CI time demands it.
- **Behavior change surprise** (bash skills-only now deploys plugins): that IS the fix — Windows already behaved this way; documented in PR body per 1.4.

## Gate Trace

GATE (push head) lint=- typecheck=- build=- unit=t e2e=n.a.  (bash -n ok; bats 433 ok / 0 fail incl. 4 new parity pins; node --test 30 pass / 0 fail; scope = deploy/setup.sh + tests/test_skills_only_parity.bats; ps1 untouched)
