# PLAN: Remove Docker container/image implementation; relocate config source

**Branch**: feat/607
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/607
**Base**: main

## Acceptance Criteria

- [x] `opencode_app/`, `docker-compose.yml`, `restart-opencode-docker.sh`, `.dockerignore`, `.env.example` deleted; no Docker implementation files remain
- [x] Config source of truth lives at `deploy/opencode.json`; `setup.sh`, `init.mjs`, `.releaserc.json`, `release.yml`, and all guard tests repointed; `jq . deploy/opencode.json` validates
- [x] `setup.sh` carries no `--enable-llm`/`--enable-vllm`/Docker machinery; `bash -n deploy/setup.sh` passes; help text updated
- [x] `resolve-models.mjs` has no `--inject-primary`
- [x] Full bats suite passes (skill_profiles, test_markitdown_skill, test_pack_permissions, test_help_parity, test_count_drift, test_skill_isolation, test_mcp_count_consistency, test_docling_skill, init, test_requires_skills)
- [x] `node installer/build-registry.mjs` produces no diff (skill set unchanged: 150 skills / 34 agents)
- [x] README / AGENTS.md / MIGRATION.md / CONTRIBUTING.md carry no Docker sections; `skills/docker-containerization-skill` untouched (shippable product, not this repo's hosting)
- [x] PLANS/ / LEARNINGS/ / CHANGELOG history untouched; one new LEARNINGS decision note supersedes `app-scoped-skill-surface`

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` → `deploy/opencode.json` | — | `deploy/setup.sh:130`, `installer/init.mjs:56`, `installer/dependency-map.json` ($comment), `.releaserc.json:133`, `release.yml:86-87`, `tests/skill_profiles.bats`, `tests/test_mcp_count_consistency.bats:6,26`, `tests/test_docling_skill.bats:11`, `tests/init.bats:10`, `tests/test_requires_skills.bats:75`, `deploy/apply-skill-profile.mjs`, `deploy/merge-packs.mjs:198`, `deploy/skill-profiles.json`, `skills/context-budget-skill/SKILL.md:62` (inventory), `skills/opencode-repo-setup-skill/SKILL.md:202` (table row) | high — single source of truth for all 3 install modes |
| `deploy/setup.sh` | config path (1.2) | every user-space deploy; `deploy/setup.ps1` flag forwarding; `tests/test_help_parity.bats`; LLM flags → compose file | med |
| `deploy/setup.ps1` LLM arms (≈50-53, 135-138) | setup.sh flag removal (Phase 3, same phase) | Windows deploys; `tests/test_help_parity.bats:86-89` pins | med — dead forwarding breaks Windows deploys |
| `opencode_app/` remainder (Dockerfile, entrypoint, README, AGENTS.md, `.opencode/skills/github-runners-setup-skill`) | config relocation (Phase 1 first — config lives inside this dir) | `tests/test_markitdown_skill.bats:96-99` (reads app README), `tests/test_pack_permissions.bats:213` (sweeps Dockerfile) | med |
| `docker-compose.yml`, `restart-opencode-docker.sh`, `.dockerignore`, `.env.example` | — | `setup.sh` LLM flags (`docker compose --profile …`), compose `env_file: .env` | med |
| `setup.sh` LLM/vLLM machinery (~2945-3260, help 630-640, `ENABLE_VLLM:367`) | compose file deletion (Phase 2) | `--enable-llm`/`--enable-vllm` users (none — user-confirmed); `tests/test_help_parity.bats:24` asserts markitdown bump-ritual comment | med |
| `installer/resolve-models.mjs` `--inject-primary` | Dockerfile deletion (Phase 2 — its only caller) | none after Docker removal; `installer/models.default.json` `$comment` | low |
| Docs: `README.md`, `AGENTS.md`, `MIGRATION.md`, `CONTRIBUTING.md`, `agents/opencode-tooling-subagent.md:280`, `THIRD_PARTY_LICENSES.md:164`, `skills/markitdown-mcp-skill`, `skills/context-budget-skill:58,62`, `skills/opencode-repo-setup-skill:202`, `plugins/` comments | code phases (describe end state) | humans; `tests/test_count_drift.bats` (README counts) | low |
| `installer/registry.json` | — | expected NO diff (github-runners-setup-skill was never registered) | low |

## Implementation Phases

### Phase 1: Relocate config source of truth

- [x] **1.1** `git mv opencode_app/opencode.json deploy/opencode.json` AND strip the `github-runners-setup-skill` skill-allow rule from the relocated config (that skill exists only on the app surface deleted in 2.1 — the rule is dead-on-arrival at the new path; plan-review Issue 2 / GAP 3)
    — **Why:** the file is the config source for ALL install modes, not Docker-only; it must leave `opencode_app/` before that dir is deleted, and a dead allow would fail the root-only dead-allow guard (1.6).
    — **Done when:** `git status` shows the rename staged; `deploy/opencode.json` exists; `opencode_app/opencode.json` does not; `grep -c 'github-runners-setup-skill' deploy/opencode.json` = 0.
    — **Consumers affected:** every consumer row in the map; all repointed in 1.2–1.7.
    — **Done:** git mv executed; github-runners-setup-skill allow stripped (grep count 0); files: deploy/opencode.json; fixes: none
- [x] **1.2** Repoint `deploy/setup.sh`: `SOURCE_CONFIG` (line 130) and the two prose comments (≈2729, ≈3579) that name `opencode_app/opencode.json`
    — **Why:** setup.sh is the deploy entrypoint; a stale path breaks every user-space deploy.
    — **Done when:** `grep -n 'opencode_app' deploy/setup.sh` returns no config-path hits (LLM-section hits remain until Phase 3).
    — **Consumers affected:** `./deploy/setup.sh` users, `setup.ps1` thin launcher.
    — **Done:** SOURCE_CONFIG + 2 comments repointed; verified by grep; files: deploy/setup.sh; fixes: none
- [x] **1.3** Repoint `installer/init.mjs` `SOURCE_OC` (line 56)
    — **Why:** the npx installer generates project configs from this file.
    — **Done when:** `node installer/init.mjs --list categories` (or `--help`) runs without ENOENT.
    — **Consumers affected:** `npx github:darellchua2/...` installs, `opencode-init`.
    — **Done:** SOURCE_OC repointed; node --check green; files: installer/init.mjs; fixes: none
- [x] **1.4** Repoint `.releaserc.json:133` and `.github/workflows/release.yml:86-87`
    — **Why:** release CI validates the config with jq; a stale path fails the release workflow.
    — **Done when:** `grep -rn 'opencode_app/opencode.json' .releaserc.json .github/` is empty.
    — **Consumers affected:** semantic-release config check, release workflow.
    — **Done:** jq-validation path + release file list repointed; files: .releaserc.json, .github/workflows/release.yml; fixes: none
- [x] **1.5** Repoint guard tests: `test_mcp_count_consistency.bats:26` (+ source-of-truth comment :6), `test_docling_skill.bats:11`, `init.bats:10`, `test_requires_skills.bats:75`
    — **Why:** these read the config as source of truth; they fail ENOENT until repointed.
    — **Done when:** `bats tests/test_mcp_count_consistency.bats tests/test_docling_skill.bats tests/init.bats tests/test_requires_skills.bats` all pass in the worktree.
    — **Consumers affected:** CI bats suite.
    — **Done:** 4 test files repointed incl. source-of-truth comment; affected bats suite 84/84 green; files: tests/test_mcp_count_consistency.bats, tests/test_docling_skill.bats, tests/init.bats, tests/test_requires_skills.bats; fixes: none
- [x] **1.6** Rework `tests/skill_profiles.bats`: repoint config path to `deploy/opencode.json`; KEEP the dead-allow assert (≈63) and its negative fixture (≈77-86) repointed to the new path; DROP only the app-surface union/disjoint block (≈66-74 and the `dirs(opencode_app/...)` half of the union at ≈37) — #486 two-surface contract superseded
    — **Why:** the two-surface contract is superseded by this ticket, but the dead-allow guard itself must survive root-only (future dead rules stay detectable); the app surface dies in Phase 2.
    — **Done when:** `grep -n 'opencode_app' tests/skill_profiles.bats` is empty and `bats tests/skill_profiles.bats` passes (incl. the negative fixture).
    — **Consumers affected:** skill-profile guard coverage (lean⊆shipped + dead-allow checks survive, app-union check retired).
    — **Done:** dead_allows now root-only, negative fixture kept, union/overlap block dropped, paths swapped; bats green; files: tests/skill_profiles.bats; fixes: none
- [x] **1.7** Update deploy/installer tooling comments/messages that name the old path: `deploy/skill-profiles.json` `_comment`, `deploy/apply-skill-profile.mjs:11`, `deploy/merge-packs.mjs:198`, `installer/dependency-map.json` `$comment` (MCP-key contract names `opencode_app/opencode.json` — plan-review Issue 3)
    — **Why:** operator-facing error text and comments must not send users to a deleted path.
    — **Done when:** `grep -rn 'opencode_app' deploy/ installer/dependency-map.json` returns nothing (outside setup.sh LLM section, handled in Phase 3).
    — **Consumers affected:** pack-merge error messages, profile tooling readers, installer dependency map.
    — **Done:** 4 tooling comments/messages repointed; grep clean; files: deploy/skill-profiles.json, deploy/apply-skill-profile.mjs, deploy/merge-packs.mjs, installer/dependency-map.json; fixes: none

### Phase 2: Delete Docker artifacts + coupled test reads

- [x] **2.1** `git rm -r opencode_app/` (Dockerfile, docker-entrypoint.sh, README.md, AGENTS.md, `.opencode/skills/github-runners-setup-skill`)
    — **Why:** the container/image implementation is the removal target; zero external references confirmed at review.
    — **Done when:** `opencode_app/` absent from tree; `git ls-files opencode_app` empty.
    — **Consumers affected:** test_markitdown_skill count block (2.3), test_pack_permissions sweep (2.4).
    — **Done:** opencode_app/ removed (git rm -r); git ls-files empty for the path; files: opencode_app/; fixes: none
- [x] **2.2** `git rm docker-compose.yml restart-opencode-docker.sh .dockerignore .env.example`
    — **Why:** compose (all 4 services), the maintainer redeploy script, build-context ignore, and the compose env template are Docker-only surfaces.
    — **Done when:** files absent; `git ls-files` confirms.
    — **Consumers affected:** setup.sh LLM flags (Phase 3), README Docker sections (Phase 5).
    — **Done:** docker-compose.yml, restart-opencode-docker.sh, .dockerignore, .env.example removed; files: (those four); fixes: none
- [x] **2.3** `tests/test_markitdown_skill.bats`: remove the `opencode_app/README.md` skill-count check (≈96-99)
    — **Why:** the assertion reads a file deleted in 2.1; keeping it would fail every run.
    — **Done when:** `bats tests/test_markitdown_skill.bats` passes.
    — **Consumers affected:** CI bats suite.
    — **Done:** app-README count block removed; bats 22/22 green incl. pack perms; files: tests/test_markitdown_skill.bats; fixes: none
- [x] **2.4** `tests/test_pack_permissions.bats`: drop `opencode_app/Dockerfile` from the permission sweep (≈204, 213)
    — **Why:** the sweep greps a deleted file; `|| true` would mask it, but the reference must not outlive the file.
    — **Done when:** `bats tests/test_pack_permissions.bats` passes; no `opencode_app` refs in the file.
    — **Consumers affected:** CI bats suite.
    — **Done:** Dockerfile leg dropped from the dead-key sweep; comment updated; files: tests/test_pack_permissions.bats; fixes: none

### Phase 3: setup.sh Docker/LLM surgery

- [x] **3.1** Remove the LLM-container machinery — the FULL flag family, not just the two flagship flags (plan-review Issue 1 / GAP 1): `setup_local_llm` + `setup_vllm` functions (≈3185-3235), `ENABLE_LOCAL_LLM`/`ENABLE_VLLM` vars (≈366-367), flag parsing for `--enable-llm`/`--enable-vllm`/`--enable-local-llm`/`--local-llm`/`--vllm` (≈965-980), help-text block (≈631-641), `PLAN_STEPS` wiring rows (≈3831-3832), dispatch arms (≈4273-4274), `extras` array entries `local-llm`/`vllm` (≈4337), and the `.env` writer (≈3059-3146)
    — **Why:** these install and start Docker containers via the deleted compose file; every arm of the family dies together or setup.sh rejects half-forwarded flags. Provider presets SURVIVE — `installer/provider-presets.json` `local-llm`/`vllm`/`ollama` entries and the `--provider` value lists at ≈608/≈925 are model-routing maps to user-hosted endpoints, not containers (GAP 1 ruling; `test_provider_pins.bats`/`test_provider_credentials.bats` stay green untouched).
    — **Done when:** `grep -nE 'setup_local_llm|setup_vllm|ENABLE_LOCAL_LLM|ENABLE_VLLM|enable-llm|enable-vllm|enable-local-llm|local-llm-up|docker compose|docker pull|nvidia-ctk' deploy/setup.sh` returns only the surviving `--provider` value-list hits at ≈608/≈925 (value tokens, not flags); `bash -n deploy/setup.sh` passes; `./deploy/setup.sh --help` renders without the LLM block.
    — **Consumers affected:** `deploy/setup.ps1` forwarding arms + `tests/test_help_parity.bats` pins (3.3, same phase); no end users (user-confirmed removal).
    — **Done:** full flag family removed (2 vars, help block, 4 flag cases, llm subcommand, 4 functions ~300 lines, PLAN_STEPS rows, dispatch loop, extras emptied); bash -n green; help renders LLM-free with provider value-lists surviving at :606/:910; files: deploy/setup.sh; fixes: none
- [x] **3.2** Update the markitdown bump-ritual comment (≈2808): pin now lives in `deploy/setup.sh` only
    — **Why:** the ritual named `opencode_app/Dockerfile` as the second surface; one surface remains.
    — **Done when:** comment states the single-surface pin.
    — **Consumers affected:** `tests/test_help_parity.bats:24`.
    — **Done:** ritual comment now single-surface (setup.sh only); files: deploy/setup.sh; fixes: none
- [x] **3.3** Update the coupled test + launcher surfaces for the removed flag family (plan-review Issue 1 / GAP 2): `tests/test_help_parity.bats` — reword the asserted markitdown ritual phrase (≈24) AND drop the four ps1-arm pins (≈86-89); `deploy/setup.ps1` — drop the four switch declarations (≈50-53) and four forward arms (≈135-138) for `--enable-local-llm`/`--enable-vllm`/`--local-llm`/`--vllm` (the `--provider local-llm` VALUE survives per GAP 1)
    — **Why:** the parity test greps the exact ritual sentence changed in 3.2 and pins the ps1 arms removed alongside 3.1; keeping the ps1 arms would forward dead flags into a setup.sh that now rejects them (broken Windows deploys).
    — **Done when:** `bats tests/test_help_parity.bats` passes; `grep -nE 'enable-local-llm|enable-vllm|local-llm( |$)|--vllm' deploy/setup.ps1` returns no flag-forwarding hits (provider value lists excluded).
    — **Consumers affected:** CI bats suite, Windows deploys.
    — **Done:** ps1: 4 switches + 4 forward arms + 2 comment lists cleaned; parity test: ritual phrase reworded + 4 ps1 pins dropped; files: deploy/setup.ps1, tests/test_help_parity.bats; fixes: 1 — ritual phrase crossed a line break, rewrapped comment so the asserted phrase is contiguous (bats red→green)

### Phase 4: resolve-models dead flag

- [x] **4.1** Remove `--inject-primary` from `installer/resolve-models.mjs` (flag parse, usage line, comments ≈9/32/196-197/274)
    — **Why:** the Dockerfile was its only caller; post-removal it is unreachable dead code.
    — **Done when:** `node --check installer/resolve-models.mjs` passes; `grep -n 'inject-primary' installer/` empty.
    — **Consumers affected:** none (no live callers); `setup.sh` resolver call omits the flag already.
    — **Done:** flag removed from defaults/boolKeys/usage/header; effectivePrimary simplified; node --check green; dry-run resolver executes against deploy/opencode.json; files: installer/resolve-models.mjs; fixes: none
- [x] **4.2** Trim the `installer/models.default.json` `$comment` Docker-build sentence
    — **Why:** comment describes the removed `--inject-primary` build path.
    — **Done when:** `node -e "JSON.parse(require('fs').readFileSync('installer/models.default.json'))"` parses; no `Docker build` mention.
    — **Consumers affected:** none (opaque comment).
    — **Done:** $comment Docker-build sentence replaced with never-injected wording; JSON parses; files: installer/models.default.json; fixes: none

### Phase 5: Docs sweep

- [x] **5.1** `README.md`: remove §"Docker — the whole setup as a browser endpoint" + §"Docker: run the whole setup in a browser", dir-tree entries (`opencode_app/`, `docker-compose.yml`, `restart-opencode-docker.sh`, `.env.example`, `.env`), the "auto-injected in Docker" note (≈194), the `docker compose build --build-arg` MCP line (≈246), and the Docker-mode mentions at ≈240, ≈346, ≈455 (plan-review Issue 3)
    — **Why:** docs must not teach deleted flows.
    — **Done when:** `grep -niE 'docker compose|opencode_app|\.env\.example' README.md` returns no stale hits; `bats tests/test_count_drift.bats` passes (counts untouched: 150/34).
    — **Consumers affected:** README readers; count-drift guard.
    — **Done:** both Docker sections, 5 dir-tree entries, 4 inline mentions removed (incl. ≈240/346/455 repointed to deploy/opencode.json); count-drift green (150/34 unchanged); files: README.md; fixes: none
- [x] **5.2** `AGENTS.md`: rewrite §Repository Purpose to two modes (user-space deploy, individual install); drop the `opencode_app/README.md` row from the sync table; `CONTRIBUTING.md:15` drop the same from the sync list
    — **Why:** agent-facing contract must match the real repo shape.
    — **Done when:** `grep -n 'opencode_app\|Docker standalone' AGENTS.md CONTRIBUTING.md` empty.
    — **Consumers affected:** agents following repo instructions.
    — **Done:** AGENTS.md purpose rewritten to 2 modes, sync-table row dropped; CONTRIBUTING sync list updated; files: AGENTS.md, CONTRIBUTING.md; fixes: none
- [x] **5.3** `MIGRATION.md`: remove §Docker (≈286-302) and the three-surface `OPENCODE_VERSION` pin note
    — **Why:** both describe the deleted image build.
    — **Done when:** no `docker compose` / `OPENCODE_VERSION` references remain.
    — **Consumers affected:** migration readers.
    — **Done:** §Docker removed; Provider Packs kept as user-space-only section; files: MIGRATION.md; fixes: none
- [x] **5.4** Prose fixes: `agents/opencode-tooling-subagent.md` tree (≈280-281), `THIRD_PARTY_LICENSES.md:164` ("baked into the Docker image" → pip-installed on demand), `skills/markitdown-mcp-skill/SKILL.md` Docker-baking paragraphs, AND the two skills carrying stale infra references to THIS repo's deleted Docker mode (plan-review Issue 3 / GAP 4): `skills/context-budget-skill/SKILL.md` (drop Path 3 `opencode_app/AGENTS.md` at ≈58; repoint the MCP-block inventory at ≈62 to `deploy/opencode.json`) and `skills/opencode-repo-setup-skill/SKILL.md` (repoint the source-of-truth table row at ≈202) — body prose only, no frontmatter changes, so 6.1's registry no-diff holds
    — **Why:** stale references to deleted infrastructure mislead agents and users; without these, the 6.4 exit audit fails its own grep.
    — **Done when:** `grep -rn 'opencode_app' agents/ THIRD_PARTY_LICENSES.md skills/markitdown-mcp-skill/ skills/context-budget-skill/ skills/opencode-repo-setup-skill/` empty.
    — **Consumers affected:** tooling subagent, license readers, three skill consumers. `skills/docker-containerization-skill` remains untouched (teaches Docker generically; references nothing of this repo's hosting).
    — **Done:** tooling-subagent tree repointed; THIRD_PARTY markitdown Docker-baking prose trimmed; markitdown skill Docker bullet dropped; context-budget Path 3 removed + MCP inventory repointed; repo-setup table row repointed; files: agents/opencode-tooling-subagent.md, THIRD_PARTY_LICENSES.md, skills/markitdown-mcp-skill/SKILL.md, skills/context-budget-skill/SKILL.md, skills/opencode-repo-setup-skill/SKILL.md; fixes: none
- [x] **5.5** `plugins/`: reword Docker-volume rationale comments in `plugins/README.md:10`, `plugins/ATTRIBUTION.md:45`, `plugins/opencode-ponytail-scoped.ts` (≈28, 52) — keep the XDG-data-path rule, drop the compose-volume rationale
    — **Why:** the path rule survives (LEARNINGS index row `plugin-persisted-state-needs-volume-backed-path` — the rule is also stated inline in the plugin comments); only the Docker justification is stale.
    — **Done when:** `grep -niE 'docker' plugins/` returns no compose/image references.
    — **Consumers affected:** plugin maintainers.
    — **Done:** plugins README x2 + ATTRIBUTION + ponytail-scoped comments reworded to data-dir rationale; files: plugins/README.md, plugins/ATTRIBUTION.md, plugins/opencode-ponytail-scoped.ts; fixes: none

### Phase 6: Verification + knowledge capture

- [x] **6.1** Run `node installer/build-registry.mjs`; assert no diff (`git diff --exit-code installer/registry.json`)
    — **Why:** proves the skill set (150/34) is unchanged by the removal.
    — **Done when:** exit 0.
    — **Consumers affected:** installer registry.
    — **Done:** build-registry regen → only generatedAt timestamp differs; counts 34/150 stable; registry.json restored untouched; files: (none committed); fixes: none
- [x] **6.2** Run the full bats suite (`bats tests/`)
    — **Why:** exit gate — every touched guard must be green on the final tree.
    — **Done when:** 0 failures.
    — **Consumers affected:** all.
    — **Done:** full suite 630 ok / 0 fail after fix cycle; files: tests/test_subcommands.bats, tests/test_dry_run_leaks.bats, deploy/setup.sh; fixes: 3 — (a) dead 'llm' subcommand still taught in --help line 41, removed; (b)+(c) two setup_local_llm_env dry-run pins retired with the removed .env writer (class pin header annotated #607)
- [x] **6.3** Write `LEARNINGS/decisions/docker-surface-removal.md` superseding the #486 two-surface decision — anchor on the records that actually exist on disk: the `_index.md` row (≈764, `app-scoped-skill-surface`) and `LEARNINGS/anti-patterns/two-surface-count-conflation.md`; note that `LEARNINGS/decisions/app-scoped-skill-surface.md` is index-only (no file) — do not fabricate it; append the new `_index.md` entry (plan-review Issue 4)
    — **Why:** the #486 two-surface decision is now false; future sessions must not resurrect the app surface.
    — **Done when:** new file exists, `_index.md` lists it, pre-existing entries untouched (history).
    — **Consumers affected:** future agent sessions.
    — **Done:** LEARNINGS/decisions/docker-surface-removal.md written + _index.md entry appended; supersede anchored on the index row + two-surface-count-conflation (index-only decisions file not fabricated); files: LEARNINGS/decisions/docker-surface-removal.md, LEARNINGS/_index.md; fixes: none
- [x] **6.4** Final audit grep: no `opencode_app|docker-compose|restart-opencode-docker|inject-primary|OPENCODE_VERSION` references outside `PLANS/`, `LEARNINGS/`, `CHANGELOG.md`, `docs/` (historical research snapshot), `.gitignore` (`.env*` ignore stays)
    — **Why:** proves the removal is complete; history dirs are exempt by design.
    — **Done when:** grep returns only exempted paths.
    — **Consumers affected:** none (audit).
    — **Done:** audit grep: hits only in PLANS/, LEARNINGS/, CHANGELOG.md, docs/ + benign (setup.sh opencode_version bash var; product teaching content in 2 skills); files: (audit only); fixes: none

## Technical Notes

- `skills/docker-containerization-skill` and preset references to it are PRODUCTS (teach Docker) — never touched.
- `deploy/setup.ps1` is a thin launcher (no config path, no markitdown pin — LEARNINGS #474) but DOES carry the LLM flag switches/arms removed in 3.3 (plan-review Issue 1); `tests/test_setup_ps1_vars.bats` has zero LLM references and stays green untouched.
- Provider presets survive: `installer/provider-presets.json` `local-llm`/`vllm`/`ollama` entries and `--provider` value lists (setup.sh ≈608/≈925) are model-routing maps, not containers — pinned by `test_provider_pins.bats`/`test_provider_credentials.bats`, both untouched (GAP 1 ruling).
- Branch convention: `feat/607` (repo uses `feat/<num>`); PLAN file `PLANS/PLAN-607.md`.
- `.gitignore` `# Docker / .env*` stanza: keep ignoring `.env*` (harmless, protects future local env files); optionally retitle comment.
- Root skill count stays 150: `github-runners-setup-skill` lived only on the deleted app surface, never in root `skills/` or `registry.json`.

## Dependencies

None — single executable ticket, no `blocked-by`.

## Risks & Mitigation

- **Broken deploy/installer from a missed path reference** → Phase 1 repoints ALL 13 known consumers before any deletion; per-phase gates run the affected bats tests; 6.4 audits residual references.
- **Hidden consumer of `--inject-primary` or the app-scoped skill** → pre-review grepped the repo (excluding history dirs); registry-diff check (6.1) and the final audit (6.4) backstop.
- **Count drift in README** → counts are untouched (150/34); `test_count_drift.bats` guards.
- **Live web endpoint depending on `restart-opencode-docker.sh`** → user-confirmed the endpoint is retired; removal is the intent of the ticket.

## Gate Trace

GATE 48ea788 tier=light lint=n.a typecheck=n.a build=n.a unit=t(84/84 affected bats) e2e=n.a
GATE e847380 tier=light lint=n.a typecheck=n.a build=n.a unit=t(22/22 affected bats; no orphan refs) e2e=n.a
GATE aff8c4f tier=light lint=n.a typecheck=n.a build=n.a unit=t(help-parity+ps1-vars+select-items 0 fails) e2e=n.a
GATE f99dcb6 tier=light lint=n.a typecheck=n.a build=n.a unit=t(resolver dry-run smoke) e2e=n.a
GATE 555c737 tier=light lint=n.a typecheck=n.a build=n.a unit=t(count-drift+ships-plugins 0 fails; doc grep clean) e2e=n.a
GATE 0cd5aee tier=full lint=n.a typecheck=n.a build=n.a unit=t(bats 630/630) e2e=n.a
GATE 211fba2 tier=full lint=n.a typecheck=n.a build=n.a unit=t(bats 630/630 post-review-fix) e2e=n.a — review-fix re-gate (extras picker surface)
