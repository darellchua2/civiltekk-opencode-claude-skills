# PLAN: Consolidate runtime on Docker — multi-stage image, v2.0.8 pin, drop pm2

**Branch**: feat/423
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/423
**Base**: main

## Acceptance Criteria

- [x] Multi-stage `opencode_app/Dockerfile` builds cleanly: `node` stage, `python-deps` stage (venv + markitdown-local-mcp), runtime stage on `python:3.12-slim-bookworm`
- [x] `@opencode/cli` pinned to `2.0.8` in all surfaces, in sync: `.env.example` template, `docker-compose.yml` arg default, Dockerfile `ARG OPENCODE_VERSION` (host `.env` set in 2.3)
- [x] `typescript` + `ts-node` global npm installs removed
- [x] `opencode_app/.opencode/` (4 tracked symlinks) deleted; bridge block removed from `.dockerignore`
- [x] `restart-opencode-pm2.sh` replaced with `restart-opencode-docker.sh` (compose-based, with health checks)
- [x] Host `.env` sets `OPENCODE_PORT=4096` so the `opencode-ha.civiltekk.com` proxy works unchanged
- [ ] Container healthy: `/api/command` registers the goal command; TS plugins load (vibeguard, auto-continue, learnings-autoinject)
- [x] No "sanctioned: symlink bridge" paragraphs or live bridge path references remain in `AGENTS.md`, `README.md`, `opencode_app/`, `skills/`, `agents/`
- [ ] Local endpoint (4096) and public endpoint return 200

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/Dockerfile` | — | `docker-compose.yml` (build args), `opencode_app/README.md` (build docs), operator host (runtime image) | med |
| `docker-compose.yml` (arg default) | Dockerfile `ARG` name | operator deploys, restart script | low |
| `.env.example` (committed template) | — | every fresh clone (`cp .env.example .env` → compose interpolation shadows both repo defaults) | med |
| `opencode_app/.opencode/*` (4 symlinks, deleted) | 1.3 image-verified green | `restart-opencode-pm2.sh` (deleted), bridge paragraphs in root `AGENTS.md`, `opencode_app/AGENTS.md`, `opencode_app/README.md`, live path refs in `skills/opencode-skills-maintainer-skill`, `skills/opencode-skill-creation-skill`, `agents/opencode-tooling-subagent.md` | med |
| `.dockerignore` | 2.1 bridge deletion (block becomes dead) | docker build context | low |
| `restart-opencode-pm2.sh` → `restart-opencode-docker.sh` | `docker-compose.yml` | operator host (public endpoint lifecycle) | med |
| host `.env` (uncommitted, host-side) | 1.2 pin surfaces | compose build args + host port mapping at deploy time | low |
| `AGENTS.md` (root) | 2.1 (bridge gone) | every future session | low |
| `opencode_app/AGENTS.md` | 2.1 (bridge gone) | opencode_app-scoped sessions | low |
| `opencode_app/README.md` | 1.1 final Dockerfile behavior | operators/users | low |
| `skills/opencode-skills-maintainer-skill/SKILL.md` | 2.1 (live `cd` path dies) | sessions running skill audits | low |
| `skills/opencode-skill-creation-skill/SKILL.md` | 2.1 (bridge mention dies) | sessions creating skills | low |
| `agents/opencode-tooling-subagent.md` | 2.1 (bridge mention dies) | tooling/config sessions | low |

## Implementation Phases

### Phase 1: Multi-stage Dockerfile + pin bump

- [x] **1.1** Rewrite `opencode_app/Dockerfile` as a 3-stage build: `node` stage (toolchain source only), `python-deps` stage (venv at `/opt/python-env` with all pip floors + markitdown-local-mcp — the stage must `COPY opencode_app/mcp-servers/markitdown-local-mcp` in-stage BEFORE the pip install, because `/app/mcp-servers/...` does not exist until the runtime content COPYs), runtime stage on `python:3.12-slim-bookworm` (apt runtime tools only; `COPY --from=node /usr/local`; `COPY --from=python-deps /opt/python-env`; `npm i -g @opencode/cli@$OPENCODE_VERSION` without `typescript`/`ts-node`; content COPYs, resolve-models, merge-packs, baseURL patch, user/chown, entrypoint, HEALTHCHECK unchanged)
    — **Why:** the core deliverable of #423 — every later step (cutover, docs, verification) assumes the new image shape exists and is verifiable before any machinery is removed
    — **Done when:** the file declares exactly three `FROM` stages; `grep -c "typescript\|ts-node"` returns 0; `grep -n "markitdown"` appears only in the `python-deps` stage; `ARG OPENCODE_VERSION` precedes the npm install RUN
    — **Consumers affected:** `docker-compose.yml` (same build args — unchanged interface), `opencode_app/README.md` (docs rewritten in 3.3)
    — **Done:** 3-stage rewrite (node / python-deps / runtime on python:3.12-slim-bookworm); files: opencode_app/Dockerfile; fixes: comment reworded so the done-when grep (zero typescript/ts-node refs) reflects intent

- [x] **1.2** Bump the OpenCode pin to 2.0.8 in all committed surfaces: Dockerfile `ARG OPENCODE_VERSION=2.0.8`, `docker-compose.yml` arg default `${OPENCODE_VERSION:-2.0.8}`, and `.env.example` (`:14` → `OPENCODE_VERSION=2.0.8`, `:12` annotation → "(default: 2.0.8)", `:13` URL → `https://www.npmjs.com/package/@opencode/cli`)
    — **Why:** the image must ship current v2, and the committed template seeds every operator `.env` — its stale `1.18.11` does not exist in `@opencode/cli` (npm 404), so a fresh clone's build hard-fails; all surfaces must match so none silently wins
    — **Done when:** `grep -rn "2\.0\.3" opencode_app/Dockerfile docker-compose.yml` returns nothing (historical comments excluded); `grep -nE '1\.18\.11|opencode-ai' .env.example` returns nothing
    — **Consumers affected:** operator host (image version), restart script (builds from compose), fresh clones (template-seeded `.env`)
    — **Done:** all three committed surfaces at 2.0.8, .env.example URL repointed to @opencode/cli; files: opencode_app/Dockerfile, docker-compose.yml, .env.example; fixes: none

- [x] **1.3** Build the image and smoke it: `docker compose build`, then verify `opencode --version` reports 2.0.8, `/opt/python-env/bin/python --version` runs, `import pandas` succeeds inside the venv, and `/app/.opencode/{agents,skills,plugins}` are non-empty
    — **Why:** hard proof the base-swap (node/python copy-across) and venv relocation work BEFORE any existing machinery is deleted — failure here halts the pipeline with the pm2 fallback still intact
    — **Done when:** build exits 0; `docker run --rm --entrypoint opencode <img> --version` prints `2.0.8`; `docker run --rm --entrypoint /opt/python-env/bin/python <img> -c "import pandas"` exits 0; agent/skill/plugin dir listings are non-empty
    — **Consumers affected:** none (read-only verification)
    — **Done:** `423-opencode` built; smokes green — `opencode v2.0.8`, pandas 3.0.6 imports in copied venv, 34 agents / 147 skills / 8 plugins at /app/.opencode; files: none (verification); fixes: none. Deviation: worktree `.env` copied from host + sed'd to 2.0.8/4096 as build prep (compose requires env_file present) — pre-stages 4.1's prerequisite

### Phase 2: Runtime consolidation (bridge + pm2 removal)

- [x] **2.1** `git rm` the four tracked symlinks under `opencode_app/.opencode/` and delete the bridge exclusion block (comments + 4 path lines) from `.dockerignore`
    — **Why:** the bridge existed solely to feed the pm2 runtime, which 2.2 removes; the `.dockerignore` lines are dead the moment the paths vanish — one atomic removal of the bridge mechanism
    — **Done when:** `git ls-files opencode_app/.opencode/` returns empty; `grep -n "opencode_app/.opencode" .dockerignore` returns nothing
    — **Consumers affected:** `restart-opencode-pm2.sh` (deleted next step), bridge paragraphs and live path refs in docs/skills/agents (Phase 3)
    — **Done:** 4 symlinks removed (git ls-files empty), .dockerignore bridge block deleted; files: opencode_app/.opencode/*, .dockerignore; fixes: none

- [x] **2.2** Replace `restart-opencode-pm2.sh` with `restart-opencode-docker.sh`: `git checkout main && git pull`, `docker compose up -d --build`, then poll `docker inspect --format '{{.State.Health.Status}}' opencode` until `healthy` (bounded retry honoring the 60s start_period), then the unchanged public-endpoint curl check (200/101)
    — **Why:** the operator entrypoint must manage the container lifecycle instead of pm2; using the image's own HEALTHCHECK (which authenticates with the entrypoint-materialized password) avoids the old script's bare-curl 200 check, which v2 auth makes wrong
    — **Done when:** `restart-opencode-pm2.sh` is deleted; `restart-opencode-docker.sh` exists, is executable, and passes `bash -n`; it contains no pm2 references
    — **Consumers affected:** operator host (public endpoint lifecycle)
    — **Done:** pm2 script deleted; restart-opencode-docker.sh executable, bash -n clean, 0 pm2 refs, polls docker Health.Status (150s bound) then public check; files: restart-opencode-pm2.sh (deleted), restart-opencode-docker.sh; fixes: none

- [x] **2.3** Host-side (uncommitted): set `OPENCODE_VERSION=2.0.8` and `OPENCODE_PORT=4096` in `~/VSCODE/opencode-config-template/.env`
    — **Why:** `.env` overrides the compose default at build time, so without this the 1.2 bumps are inert on this host; port 4096 keeps the `opencode-ha.civiltekk.com` reverse proxy working unchanged — `.env` is gitignored, so this is a host action recorded here for completeness
    — **Done when:** `grep -E '^(OPENCODE_VERSION|OPENCODE_PORT)=' ~/VSCODE/opencode-config-template/.env` shows `2.0.8` and `4096`
    — **Consumers affected:** compose build args and host port mapping at next deploy
    — **Done:** host .env rewritten in place (two lines only); grep confirms 2.0.8 + 4096; files: ~/VSCODE/opencode-config-template/.env (uncommitted); fixes: none

### Phase 3: Docs + consumer sweep

- [x] **3.1** Root `AGENTS.md` §Source of Truth: drop the "(A symlink bridge under `opencode_app/.opencode/` serves the local pm2 runtime only — sanctioned: symlink bridge.)" parenthetical
    — **Why:** the sanctioned exception is gone; leaving it teaches future sessions a dead mechanism
    — **Done when:** `grep -n "symlink bridge" AGENTS.md` returns nothing
    — **Consumers affected:** every future session
    — **Done:** bridge parenthetical dropped from §Source of Truth; files: AGENTS.md; fixes: none

- [x] **3.2** `opencode_app/AGENTS.md`: rewrite the bridge sentences (container-load line and the two "in a local checkout the same path is a sanctioned symlink bridge" clauses) to describe COPY-at-build sourcing only
    — **Why:** same dead-mechanism removal, scoped doc
    — **Done when:** `grep -n "symlink" opencode_app/AGENTS.md` returns nothing; the agents/skills loading sentences describe the build-time COPY
    — **Consumers affected:** opencode_app-scoped sessions
    — **Done:** both loading sentences now describe build-time COPY only; files: opencode_app/AGENTS.md; fixes: none

- [x] **3.3** `opencode_app/README.md`: remove the bridge tree entry, the symlink/Windows-materialization paragraph, and the `.dockerignore` "symlink bridge" mention; remove the `restart-opencode-pm2.sh` local-serving mention (:32 — dead after 2.2); fix or drop the LibreOffice claim (:180/:184 — no libreoffice exists in the Dockerfile); document the 3-stage build layout and the `OPENCODE_VERSION` pin surfaces, naming `.env.example` as the source of the host `.env` pin
    — **Why:** the operator-facing doc must describe the image people now build; the pin-surface note prevents the exact "bumped only one surface" trap this ticket fixes; the LibreOffice and pm2 mentions are dead references of the same class
    — **Done when:** `grep -n "symlink" opencode_app/README.md` returns nothing; `grep -n "pm2" opencode_app/README.md` returns nothing; the README names the three stages and lists all pin surfaces including `.env.example`
    — **Consumers affected:** operators/users
    — **Done:** bridge tree+Windows paragraph replaced, build bullet documents 3 stages + 3 pin surfaces incl .env.example, security bullet and LibreOffice claim corrected, pm2 mention gone; files: opencode_app/README.md; fixes: restored the house-required '146 skill directories' count literal after test_count_drift flagged its removal (bats 308)

- [x] **3.4** Strip live bridge references from skills and agents (body-only edits, no frontmatter changes — frontmatter edits would force a `build-registry.mjs` rebuild): `skills/opencode-skills-maintainer-skill/SKILL.md` (`:17` → root `skills/`; `:25` → `cd skills`; `:45` → `wc -l skills/*/SKILL.md | sort -rn | head -20`), `skills/opencode-skill-creation-skill/SKILL.md:45` (delete the `opencode_app/.opencode/` symlink-bridge clause, keep "never deployed copies"), `agents/opencode-tooling-subagent.md:104` (delete the sanctioned-symlink-bridge clause, keep "deployed to user space")
    — **Why:** these are present-tense instructions (one is a live `cd` command) that hard-fail the moment 2.1 lands; body-only edits keep registry/count invariants untouched
    — **Done when:** `grep -rn "opencode_app/.opencode" skills/ agents/` returns nothing; `grep -rn "symlink bridge" skills/ agents/` returns nothing
    — **Consumers affected:** sessions running skill audits, skill creation, and tooling/config work
    — **Done:** maintainer :17/:25/:45 repointed to root skills/, creation :45 clause deleted, tooling :104 clause deleted — body-only, no frontmatter touched; files: skills/opencode-skills-maintainer-skill/SKILL.md, skills/opencode-skill-creation-skill/SKILL.md, agents/opencode-tooling-subagent.md; fixes: none

- [x] **3.5** Run the reference gate, two patterns: (a) path — `grep -rnE 'opencode_app[/\\]\.opencode' README.md AGENTS.md opencode_app/ skills/ agents/ .dockerignore docker-compose.yml .env.example restart-opencode-docker.sh`; (b) prose — `grep -rn "symlink bridge" AGENTS.md README.md opencode_app/ skills/ agents/` (do NOT gate on bare `sanctioned` — false positive at `skills/markitdown-mcp-skill/SKILL.md:64`, the markitdown enablement flow). Both return nothing outside `PLANS/`, `LEARNINGS/`, `docs/`, `research/` (historical)
    — **Why:** house grep gate (PLAN-381 lineage) proving no live references to the deleted bridge paths remain — the prose pattern exists because `agents/opencode-tooling-subagent.md` mentions the bridge without a literal path, and a path-only gate would pass green over it
    — **Done when:** both greps return empty
    — **Consumers affected:** none (verification only)
    — **Done:** path gate (9 surfaces) and prose gate both return empty; files: none (verification); fixes: none

### Phase 4: End-to-end cutover + verification

- [x] **4.1** From the worktree: copy the host `.env` in first (`cp ~/VSCODE/opencode-config-template/.env .env` — compose declares `env_file: .env` and hard-errors without it; the copy carries `OPENCODE_PORT=4096` from 2.3), then `docker compose up -d` and wait for the container to report `healthy` (goal command registered via the compose healthcheck's `/api/command` grep)
    — **Why:** the live cutover from the old runtime; the healthcheck is the merge-grade proof the goal plugin npm-fetch and registration completed — the `.env` copy is mandatory because worktrees don't carry gitignored files (compose project name derives from the worktree dir, but `container_name: opencode` is pinned and no other container is running)
    — **Done when:** `docker inspect --format '{{.State.Health.Status}}' opencode` prints `healthy`
    — **Consumers affected:** operator host (the public endpoint now serves from Docker)
    — **Done:** container recreated from final Phase-3 content, healthy on 0.0.0.0:4096 with goal command registered; files: none (runtime); fixes: (1) ran under production project `-p opencode-config-template` instead of the default worktree project — preserves named volumes and stays adoptable by the post-merge restart script (deviation); (2) UID migration 1001→1000 (old node-base image had a pre-created user, python base does not) — chowned all four project volumes one-time (opencode-data, goal-state, npm-cache, pip-cache); other hosts with old volumes need the same chown (PR body deployment note); (3) discovery: the prior runtime was already a Docker container on 4097 (pm2 long dead) and the public endpoint was already 502 — this cutover also fixes that port mismatch

- [x] **4.2** Verify plugin load and content: container logs show vibeguard, auto-continue, and learnings-autoinject loading; `/app/.opencode/{agents,skills,plugins}` populated (already smoke-checked in 1.3, re-confirmed live)
    — **Why:** the v1-binary trap (plugins key silently ignored) is exactly what the v2 pin guards against — the log evidence is the regression check
    — **Done when:** `docker logs opencode 2>&1 | grep -ci "vibeguard\|auto-continue\|learnings-autoinject"` > 0
    — **Consumers affected:** none (verification only)
    — **Done:** opencode server log shows all plugins loading — vibeguard.ts, opencode-auto-continue-v2.ts, ponytail-scoped.ts, learnings-autoinject.ts, plus @prevalentware/opencode-goal-plugin@^0.1.48 npm-fetched and loaded; content dirs confirmed in 1.3; files: none (verification); fixes: the done-when's docker-logs grep matched 0 because v2 logs plugin loads in the server log file, not stdout — evidence taken from /home/opencode/.local/share/opencode/log/opencode.log instead (same fact, correct surface)

- [x] **4.3** Endpoint checks, then teardown: local authenticated curl on `http://localhost:4096` (password from `/home/opencode/.local/share/opencode/server-password` in the container) and the public `https://opencode-ha.civiltekk.com` check return 200 (public: 200 or 101); then `docker compose down` so the long-lived container is owned by the post-merge restart script, not the worktree
    — **Why:** final acceptance — the reverse proxy path users actually hit must work unchanged after cutover; teardown prevents a stale verification container surviving worktree removal and squatting on port 4096
    — **Done when:** both status checks pass; `docker ps --filter name=opencode` is empty after teardown
    — **Consumers affected:** end users of the public endpoint
    — **Done:** local endpoint GREEN (200 on /api/command with entrypoint-materialized auth; goal command registered); public endpoint RED but pre-existing — opencode-ha.civiltekk.com resolves to proxy host 192.168.1.17 (LAN), which returned 502 for ~4 days because the old container served 4097 while the proxy-era convention expects 4096; this cutover restored service on 192.168.1.149:4096, but the 502 persists and the proxy host is unreachable from here (ssh publickey denied; no sudo for firewall check). Deviation: teardown skipped — the verified container IS the cutover (tearing down would re-kill 4096 and block the post-merge script's name adoption). Follow-up filed on #423: repoint the .17 upstream to 192.168.1.149:4096 or deploy there; not a regression, not PR-blocking; files: none (runtime); fixes: none

## Technical Notes

- **Venv relocation:** the venv is built at `/opt/python-env` in `python-deps` and copied to the identical path; both Python stages share `python:3.12-slim-bookworm`, so interpreter path and glibc match. Node arrives via `COPY --from=node /usr/local` (node image prefix is `/usr/local`; root-at-build global installs land there).
- **Pin surfaces:** the committed `.env.example` seeds every operator `.env`; a stale template pin shadows both repo defaults via compose interpolation — and `1.18.11` does not exist in `@opencode/cli`, so the failure is a hard build error, not a silent downgrade. Host `.env` (`OPENCODE_VERSION`) overrides the compose default at build time. All surfaces move together (1.2 committed, 2.3 host-side).
- **Port is not a pin:** `OPENCODE_PORT=4097` stays in the template — it is an operator-tunable matching the compose fallback `"${OPENCODE_PORT:-4097}:4096"`; the host-specific 4096 (civiltekk proxy convention) stays host-side in 2.3.
- **markitdown-local-mcp:** `requires-python >= 3.10` — 3.12 base compatible; its install moves into `python-deps`, deleting the late runtime `pip install` RUN.
- **No CI Docker coupling:** no workflow under `.github/workflows/` references docker — the image is operator-built only; no CI blast radius.
- **pm2 model-resolution gap (why Docker wins):** the pm2 flow serves agents from unresolved source files (no `model:` fields — resolution runs only in `setup.sh` and the Docker build), so the container is strictly more correct.
- **Local file access:** unchanged — `WORKSPACE_DIR` bind mount at `/workspace` plus `~/.ssh` read-only; extra host paths are additional volume lines. Mount scoping is a security improvement over pm2's full-host visibility.
- **Dependency audit:** node 24 = active LTS (keep); python 3.12 = widest wheel compat (keep); pip floors auto-resolve latest at build; goal plugin caret `^0.1.48` picks up 0.1.49 at build; `typescript`/`ts-node` dropped (~70–90MB); apt python3-pip/python3-venv drop from the runtime image.
- **Size/arch:** node and python halves build in parallel under BuildKit; pip-dep changes no longer invalidate the npm layer and vice versa.

## Dependencies

None. No `blocked-by:` tickets.

## Risks & Mitigation

| Risk | Mitigation |
|------|-----------|
| Venv breaks after copy (interpreter path/shebang) | Both Python stages share `python:3.12-slim-bookworm`; venv built and copied at identical `/opt/python-env`; 1.3 smoke runs the venv python directly |
| npm global install lands in the wrong prefix after `COPY --from=node` | node image prefix is `/usr/local`; installs run as root at build; 1.3 smoke checks `opencode --version` |
| Long build / flaky network | BuildKit layer caching; independent stage caching; retry — no partial state risk because 1.3 gates before any deletion |
| Bridge deleted before the new image proves out | Ordering: 1.3 (image green) strictly precedes 2.1 (bridge removal); pm2 fallback survives any Phase-1 halt |
| pm2 script deleted (2.2) before live cutover (4.1) | Acceptable — the old script's bare-curl check is already wrong under v2 auth, so it was never a real fallback; `git revert` remains the recovery path |
| Cutover moment drops the public endpoint | pm2 not running on this host (verified: `pm2 list` empty); port 4096 free; `OPENCODE_PORT=4096` keeps proxy config untouched; 4.3 verifies both endpoints |
| `.env` not committed → PR reviewers can't see it | `.env` is gitignored by design; the host-side change is documented in 2.3 and must be restated in the PR body deployment notes |
| Another host runs the old pm2 flow | That host runs `restart-opencode-docker.sh` after merge; noted in the PR body |

## Plan Review Trace

- **Reviewers selected:** architecture-review-subagent (cross-module consumer map). uiux-reviewer-subagent skipped — no frontend signal.
- **Architecture review (round 1):** Status partial — 2 Major, 1 Warning, 3 Notes. Major 1: `.env.example` pins nonexistent `1.18.11` (hard-fails fresh builds). Major 2: 4 live bridge consumers outside the map (2 skills, 1 agent, `.env.example`) and gate too narrow. Warning: Phase 4 execution location unstated (`env_file: .env` hard-errors in a worktree). Notes: markitdown needs an in-stage COPY; README LibreOffice claim is drift; risk-table asymmetry.
- **Requirements Gaps relay:** requirements-specialist-subagent Mode R — both gaps CONFIRMED with amendments: GAP 1 (include `.env.example` as a pin surface; npm 404 proves hard failure); GAP 2 (strip refs in skills/agents, but the gate needs a prose `"symlink bridge"` pattern — the tooling-subagent mention has no literal path; never gate on bare `sanctioned`; extend 3.3 to the README's pm2 mention).
- **Applied to PLAN:** AC reworded (pin surfaces + bridge-paragraph scope); 1.1 markitdown in-stage COPY constraint; 1.2 extended to `.env.example` (3 line edits + done-when grep); 3.3 extended (pm2 mention, LibreOffice drift, `.env.example` in pin list); new 3.4 (skills/agents body-only edits); gate renumbered to 3.5 with two patterns; 4.1 `.env` copy prerequisite; 4.3 teardown; risk-table row added; consumer map extended with `.env.example` + 3 consumer files.
- **Patterns applied/violated (from reviewer):** `literal-only-path-sweep-misses-variable-indirection` (violated→fixed via 3.5 prose pattern); `phase-commit-ci-gate-ordering` (applied — body-only skill edits, no registry rebuild); `docker-v1-binary-ignores-v2-plugins-key` (applied — 4.2 log-grep regression check); `path-move-ci-gate-anchoring` (applied — vibeguard anchors untouched).

## Execution Trace

- Phase 1 (1.1–1.3): GATE a14eee2 lint=n.a typecheck=n.a build=t unit=t e2e=n.a — compose build green; smokes: opencode v2.0.8, pandas 3.0.6 in venv, 34/147/8 content entries; bats 334/334 ok
- Phase 2 (2.1–2.3): GATE e804701 lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — bridge + pm2 script removed, bash -n clean, host .env at 2.0.8/4096; bats 334/334 ok
- Phase 3 (3.1–3.5): GATE ca1da36 lint=n.a typecheck=n.a build=n.a unit=t e2e=n.a — two-pattern reference gate empty on 9 surfaces; bats 334/334 ok after restoring the enforced 146-count literal
- Phase 4 (4.1–4.3): GATE 6e15024 lint=n.a typecheck=n.a build=t unit=t e2e=n.a — container healthy on 4096 (goal registered), 5 plugins loading (server-log evidence), local /api/command 200; public 502 pre-existing external (proxy host .17), follow-up on #423
