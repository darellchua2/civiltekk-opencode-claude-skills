# PLAN: Remove Docker container/image implementation; relocate config source

**Branch**: feat/607
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/607
**Base**: main

## Acceptance Criteria

- [ ] `opencode_app/`, `docker-compose.yml`, `restart-opencode-docker.sh`, `.dockerignore`, `.env.example` deleted; no Docker implementation files remain
- [ ] Config source of truth lives at `deploy/opencode.json`; `setup.sh`, `init.mjs`, `.releaserc.json`, `release.yml`, and all guard tests repointed; `jq . deploy/opencode.json` validates
- [ ] `setup.sh` carries no `--enable-llm`/`--enable-vllm`/Docker machinery; `bash -n deploy/setup.sh` passes; help text updated
- [ ] `resolve-models.mjs` has no `--inject-primary`
- [ ] Full bats suite passes (skill_profiles, test_markitdown_skill, test_pack_permissions, test_help_parity, test_count_drift, test_skill_isolation, test_mcp_count_consistency, test_docling_skill, init, test_requires_skills)
- [ ] `node installer/build-registry.mjs` produces no diff (skill set unchanged: 150 skills / 34 agents)
- [ ] README / AGENTS.md / MIGRATION.md / CONTRIBUTING.md carry no Docker sections; `skills/docker-containerization-skill` untouched (shippable product, not this repo's hosting)
- [ ] PLANS/ / LEARNINGS/ / CHANGELOG history untouched; one new LEARNINGS decision note supersedes `app-scoped-skill-surface`

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/opencode.json` → `deploy/opencode.json` | — | `deploy/setup.sh:130`, `installer/init.mjs:56`, `.releaserc.json:133`, `release.yml:86-87`, `tests/skill_profiles.bats`, `tests/test_mcp_count_consistency.bats:26`, `tests/test_docling_skill.bats:11`, `tests/init.bats:10`, `tests/test_requires_skills.bats:75`, `deploy/apply-skill-profile.mjs`, `deploy/merge-packs.mjs:198`, `deploy/skill-profiles.json` | high — single source of truth for all 3 install modes |
| `deploy/setup.sh` | config path (1.2) | every user-space deploy; `tests/test_help_parity.bats`; LLM flags → compose file | med |
| `opencode_app/` remainder (Dockerfile, entrypoint, README, AGENTS.md, `.opencode/skills/github-runners-setup-skill`) | config relocation (Phase 1 first — config lives inside this dir) | `tests/test_markitdown_skill.bats:96-99` (reads app README), `tests/test_pack_permissions.bats:213` (sweeps Dockerfile) | med |
| `docker-compose.yml`, `restart-opencode-docker.sh`, `.dockerignore`, `.env.example` | — | `setup.sh` LLM flags (`docker compose --profile …`), compose `env_file: .env` | med |
| `setup.sh` LLM/vLLM machinery (~2945-3260, help 630-640, `ENABLE_VLLM:367`) | compose file deletion (Phase 2) | `--enable-llm`/`--enable-vllm` users (none — user-confirmed); `tests/test_help_parity.bats:24` asserts markitdown bump-ritual comment | med |
| `installer/resolve-models.mjs` `--inject-primary` | Dockerfile deletion (Phase 2 — its only caller) | none after Docker removal; `installer/models.default.json` `$comment` | low |
| Docs: `README.md`, `AGENTS.md`, `MIGRATION.md`, `CONTRIBUTING.md`, `agents/opencode-tooling-subagent.md:280`, `THIRD_PARTY_LICENSES.md:164`, `skills/markitdown-mcp-skill`, `plugins/` comments | code phases (describe end state) | humans; `tests/test_count_drift.bats` (README counts) | low |
| `installer/registry.json` | — | expected NO diff (github-runners-setup-skill was never registered) | low |

## Implementation Phases

### Phase 1: Relocate config source of truth

- [ ] **1.1** `git mv opencode_app/opencode.json deploy/opencode.json`
    — **Why:** the file is the config source for ALL install modes, not Docker-only; it must leave `opencode_app/` before that dir is deleted.
    — **Done when:** `git status` shows the rename staged; `deploy/opencode.json` exists; `opencode_app/opencode.json` does not.
    — **Consumers affected:** every consumer row in the map; all repointed in 1.2–1.7.
- [ ] **1.2** Repoint `deploy/setup.sh`: `SOURCE_CONFIG` (line 130) and the two prose comments (≈2729, ≈3579) that name `opencode_app/opencode.json`
    — **Why:** setup.sh is the deploy entrypoint; a stale path breaks every user-space deploy.
    — **Done when:** `grep -n 'opencode_app' deploy/setup.sh` returns no config-path hits (LLM-section hits remain until Phase 3).
    — **Consumers affected:** `./deploy/setup.sh` users, `setup.ps1` thin launcher.
- [ ] **1.3** Repoint `installer/init.mjs` `SOURCE_OC` (line 56)
    — **Why:** the npx installer generates project configs from this file.
    — **Done when:** `node installer/init.mjs --list categories` (or `--help`) runs without ENOENT.
    — **Consumers affected:** `npx github:darellchua2/...` installs, `opencode-init`.
- [ ] **1.4** Repoint `.releaserc.json:133` and `.github/workflows/release.yml:86-87`
    — **Why:** release CI validates the config with jq; a stale path fails the release workflow.
    — **Done when:** `grep -rn 'opencode_app/opencode.json' .releaserc.json .github/` is empty.
    — **Consumers affected:** semantic-release config check, release workflow.
- [ ] **1.5** Repoint guard tests: `test_mcp_count_consistency.bats:26`, `test_docling_skill.bats:11`, `init.bats:10`, `test_requires_skills.bats:75`
    — **Why:** these read the config as source of truth; they fail ENOENT until repointed.
    — **Done when:** `bats tests/test_mcp_count_consistency.bats tests/test_docling_skill.bats tests/init.bats tests/test_requires_skills.bats` all pass in the worktree.
    — **Consumers affected:** CI bats suite.
- [ ] **1.6** Rework `tests/skill_profiles.bats`: repoint config path AND strip the app-surface union/disjoint assertions (`opencode_app/.opencode/skills`, #486 two-surface contract)
    — **Why:** the two-surface contract is superseded by this ticket; the app surface dies in Phase 2, so its assertions must go with the path change in the same atomic edit.
    — **Done when:** `grep -n 'opencode_app' tests/skill_profiles.bats` is empty and `bats tests/skill_profiles.bats` passes.
    — **Consumers affected:** skill-profile guard coverage (lean⊆shipped check survives, app-union check retired).
- [ ] **1.7** Update deploy tooling comments/messages that name the old path: `deploy/skill-profiles.json` `_comment`, `deploy/apply-skill-profile.mjs:11`, `deploy/merge-packs.mjs:198`
    — **Why:** operator-facing error text and comments must not send users to a deleted path.
    — **Done when:** `grep -rn 'opencode_app' deploy/` returns nothing (outside setup.sh LLM section, handled in Phase 3).
    — **Consumers affected:** pack-merge error messages, profile tooling readers.

### Phase 2: Delete Docker artifacts + coupled test reads

- [ ] **2.1** `git rm -r opencode_app/` (Dockerfile, docker-entrypoint.sh, README.md, AGENTS.md, `.opencode/skills/github-runners-setup-skill`)
    — **Why:** the container/image implementation is the removal target; zero external references confirmed at review.
    — **Done when:** `opencode_app/` absent from tree; `git ls-files opencode_app` empty.
    — **Consumers affected:** test_markitdown_skill count block (2.3), test_pack_permissions sweep (2.4).
- [ ] **2.2** `git rm docker-compose.yml restart-opencode-docker.sh .dockerignore .env.example`
    — **Why:** compose (all 4 services), the maintainer redeploy script, build-context ignore, and the compose env template are Docker-only surfaces.
    — **Done when:** files absent; `git ls-files` confirms.
    — **Consumers affected:** setup.sh LLM flags (Phase 3), README Docker sections (Phase 5).
- [ ] **2.3** `tests/test_markitdown_skill.bats`: remove the `opencode_app/README.md` skill-count check (≈96-99)
    — **Why:** the assertion reads a file deleted in 2.1; keeping it would fail every run.
    — **Done when:** `bats tests/test_markitdown_skill.bats` passes.
    — **Consumers affected:** CI bats suite.
- [ ] **2.4** `tests/test_pack_permissions.bats`: drop `opencode_app/Dockerfile` from the permission sweep (≈204, 213)
    — **Why:** the sweep greps a deleted file; `|| true` would mask it, but the reference must not outlive the file.
    — **Done when:** `bats tests/test_pack_permissions.bats` passes; no `opencode_app` refs in the file.
    — **Consumers affected:** CI bats suite.

### Phase 3: setup.sh Docker/LLM surgery

- [ ] **3.1** Remove the local-LLM machinery: `setup_local_llm` + `setup_vllm` functions and their wiring, `ENABLE_VLLM` var (367), help-text block (≈630-640), flag parsing for `--enable-llm`/`--enable-vllm`, `.env` writer (≈3059-3146)
    — **Why:** these install and start Docker containers via the deleted compose file; dead after Phase 2.
    — **Done when:** `grep -niE 'docker|llm|vllm' deploy/setup.sh` returns no machinery hits; `bash -n deploy/setup.sh` passes; `./deploy/setup.sh --help` renders without the LLM block.
    — **Consumers affected:** setup.sh help-parity test (3.3); no end users (user-confirmed removal).
- [ ] **3.2** Update the markitdown bump-ritual comment (≈2808): pin now lives in `deploy/setup.sh` only
    — **Why:** the ritual named `opencode_app/Dockerfile` as the second surface; one surface remains.
    — **Done when:** comment states the single-surface pin.
    — **Consumers affected:** `tests/test_help_parity.bats:24`.
- [ ] **3.3** `tests/test_help_parity.bats`: update the asserted phrase to the new single-surface comment
    — **Why:** the test greps the exact ritual sentence changed in 3.2.
    — **Done when:** `bats tests/test_help_parity.bats` passes.
    — **Consumers affected:** CI bats suite.

### Phase 4: resolve-models dead flag

- [ ] **4.1** Remove `--inject-primary` from `installer/resolve-models.mjs` (flag parse, usage line, comments ≈9/32/196-197/274)
    — **Why:** the Dockerfile was its only caller; post-removal it is unreachable dead code.
    — **Done when:** `node --check installer/resolve-models.mjs` passes; `grep -n 'inject-primary' installer/` empty.
    — **Consumers affected:** none (no live callers); `setup.sh` resolver call omits the flag already.
- [ ] **4.2** Trim the `installer/models.default.json` `$comment` Docker-build sentence
    — **Why:** comment describes the removed `--inject-primary` build path.
    — **Done when:** `node -e "JSON.parse(require('fs').readFileSync('installer/models.default.json'))"` parses; no `Docker build` mention.
    — **Consumers affected:** none (opaque comment).

### Phase 5: Docs sweep

- [ ] **5.1** `README.md`: remove §"Docker — the whole setup as a browser endpoint" + §"Docker: run the whole setup in a browser", dir-tree entries (`opencode_app/`, `docker-compose.yml`, `restart-opencode-docker.sh`, `.env.example`, `.env`), the "auto-injected in Docker" note (≈194), and the `docker compose build --build-arg` MCP line (≈246)
    — **Why:** docs must not teach deleted flows.
    — **Done when:** `grep -niE 'docker compose|opencode_app|\.env\.example' README.md` returns no stale hits; `bats tests/test_count_drift.bats` passes (counts untouched: 150/34).
    — **Consumers affected:** README readers; count-drift guard.
- [ ] **5.2** `AGENTS.md`: rewrite §Repository Purpose to two modes (user-space deploy, individual install); drop the `opencode_app/README.md` row from the sync table; `CONTRIBUTING.md:15` drop the same from the sync list
    — **Why:** agent-facing contract must match the real repo shape.
    — **Done when:** `grep -n 'opencode_app\|Docker standalone' AGENTS.md CONTRIBUTING.md` empty.
    — **Consumers affected:** agents following repo instructions.
- [ ] **5.3** `MIGRATION.md`: remove §Docker (≈286-302) and the three-surface `OPENCODE_VERSION` pin note
    — **Why:** both describe the deleted image build.
    — **Done when:** no `docker compose` / `OPENCODE_VERSION` references remain.
    — **Consumers affected:** migration readers.
- [ ] **5.4** Prose fixes: `agents/opencode-tooling-subagent.md` tree (≈280-281), `THIRD_PARTY_LICENSES.md:164` ("baked into the Docker image" → pip-installed on demand), `skills/markitdown-mcp-skill/SKILL.md` Docker-baking paragraphs
    — **Why:** stale references to deleted infrastructure mislead agents and users.
    — **Done when:** `grep -rn 'opencode_app' agents/ THIRD_PARTY_LICENSES.md skills/markitdown-mcp-skill/` empty.
    — **Consumers affected:** tooling subagent, license readers, markitdown skill users.
- [ ] **5.5** `plugins/`: reword Docker-volume rationale comments in `plugins/README.md:10`, `plugins/ATTRIBUTION.md:45`, `plugins/opencode-ponytail-scoped.ts` (≈28, 52) — keep the XDG-data-path rule, drop the compose-volume rationale
    — **Why:** the path rule survives (LEARNINGS: plugin-persisted-state-needs-volume-backed-path); only the Docker justification is stale.
    — **Done when:** `grep -niE 'docker' plugins/` returns no compose/image references.
    — **Consumers affected:** plugin maintainers.

### Phase 6: Verification + knowledge capture

- [ ] **6.1** Run `node installer/build-registry.mjs`; assert no diff (`git diff --exit-code installer/registry.json`)
    — **Why:** proves the skill set (150/34) is unchanged by the removal.
    — **Done when:** exit 0.
    — **Consumers affected:** installer registry.
- [ ] **6.2** Run the full bats suite (`bats tests/`)
    — **Why:** exit gate — every touched guard must be green on the final tree.
    — **Done when:** 0 failures.
    — **Consumers affected:** all.
- [ ] **6.3** Write `LEARNINGS/decisions/docker-surface-removal.md` superseding `app-scoped-skill-surface.md` (one-surface contract: root `skills/` only) + append `_index.md` entry
    — **Why:** the #486 two-surface decision is now false; future sessions must not resurrect the app surface.
    — **Done when:** file exists, `_index.md` lists it, old entry left untouched (history).
    — **Consumers affected:** future agent sessions.
- [ ] **6.4** Final audit grep: no `opencode_app|docker-compose|restart-opencode-docker|inject-primary|OPENCODE_VERSION` references outside `PLANS/`, `LEARNINGS/`, `CHANGELOG.md`, `docs/` (historical research snapshot), `.gitignore` (`.env*` ignore stays)
    — **Why:** proves the removal is complete; history dirs are exempt by design.
    — **Done when:** grep returns only exempted paths.
    — **Consumers affected:** none (audit).

## Technical Notes

- `skills/docker-containerization-skill` and preset references to it are PRODUCTS (teach Docker) — never touched.
- `deploy/setup.ps1` is a thin launcher (no config path, no LLM flags, no markitdown pin — LEARNINGS #474); expected zero edits, verify with `tests/test_setup_ps1_vars.bats`.
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
