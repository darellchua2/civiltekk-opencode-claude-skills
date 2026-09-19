# PLAN: Consolidate runtime on Docker — multi-stage image, v2.0.8 pin, drop pm2

**Branch**: feat/423
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/423
**Base**: main

## Acceptance Criteria

- [ ] Multi-stage `opencode_app/Dockerfile` builds cleanly: `node` stage, `python-deps` stage (venv + markitdown-local-mcp), runtime stage on `python:3.12-slim-bookworm`
- [ ] `@opencode/cli` pinned to `2.0.8` in all three surfaces, in sync: `.env`, `docker-compose.yml` arg default, Dockerfile `ARG OPENCODE_VERSION`
- [ ] `typescript` + `ts-node` global npm installs removed
- [ ] `opencode_app/.opencode/` (4 tracked symlinks) deleted; bridge block removed from `.dockerignore`
- [ ] `restart-opencode-pm2.sh` replaced with `restart-opencode-docker.sh` (compose-based, with health checks)
- [ ] Host `.env` sets `OPENCODE_PORT=4096` so the `opencode-ha.civiltekk.com` proxy works unchanged
- [ ] Container healthy: `/api/command` registers the goal command; TS plugins load (vibeguard, auto-continue, learnings-autoinject)
- [ ] No "sanctioned: symlink bridge" paragraphs remain in root `AGENTS.md`, `opencode_app/AGENTS.md`, `opencode_app/README.md`
- [ ] Local endpoint (4096) and public endpoint return 200

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `opencode_app/Dockerfile` | — | `docker-compose.yml` (build args), `opencode_app/README.md` (build docs), operator host (runtime image) | med |
| `docker-compose.yml` (arg default) | Dockerfile `ARG` name | operator deploys, restart script | low |
| `opencode_app/.opencode/*` (4 symlinks, deleted) | 1.3 image-verified green | `restart-opencode-pm2.sh` (deleted), bridge paragraphs in root `AGENTS.md`, `opencode_app/AGENTS.md`, `opencode_app/README.md` | med |
| `.dockerignore` | 2.1 bridge deletion (block becomes dead) | docker build context | low |
| `restart-opencode-pm2.sh` → `restart-opencode-docker.sh` | `docker-compose.yml` | operator host (public endpoint lifecycle) | med |
| host `.env` (uncommitted, host-side) | 1.2 pin surfaces | compose build args + host port mapping at deploy time | low |
| `AGENTS.md` (root) | 2.1 (bridge gone) | every future session | low |
| `opencode_app/AGENTS.md` | 2.1 (bridge gone) | opencode_app-scoped sessions | low |
| `opencode_app/README.md` | 1.1 final Dockerfile behavior | operators/users | low |

## Implementation Phases

### Phase 1: Multi-stage Dockerfile + pin bump

- [ ] **1.1** Rewrite `opencode_app/Dockerfile` as a 3-stage build: `node` stage (toolchain source only), `python-deps` stage (venv at `/opt/python-env` with all pip floors + markitdown-local-mcp), runtime stage on `python:3.12-slim-bookworm` (apt runtime tools only; `COPY --from=node /usr/local`; `COPY --from=python-deps /opt/python-env`; `npm i -g @opencode/cli@$OPENCODE_VERSION` without `typescript`/`ts-node`; content COPYs, resolve-models, merge-packs, baseURL patch, user/chown, entrypoint, HEALTHCHECK unchanged)
    — **Why:** the core deliverable of #423 — every later step (cutover, docs, verification) assumes the new image shape exists and is verifiable before any machinery is removed
    — **Done when:** the file declares exactly three `FROM` stages; `grep -c "typescript\|ts-node"` returns 0; `grep -n "markitdown"` appears only in the `python-deps` stage; `ARG OPENCODE_VERSION` precedes the npm install RUN
    — **Consumers affected:** `docker-compose.yml` (same build args — unchanged interface), `opencode_app/README.md` (docs rewritten in 3.3)

- [ ] **1.2** Bump the OpenCode pin 2.0.3 → 2.0.8 in the Dockerfile `ARG OPENCODE_VERSION` default and the `docker-compose.yml` arg default `${OPENCODE_VERSION:-2.0.8}`
    — **Why:** the image must ship current v2; the two repo-side surfaces must match so neither silently wins over the other (host `.env` handled separately in 2.3)
    — **Done when:** `grep -rn "2\.0\.3" opencode_app/Dockerfile docker-compose.yml` returns nothing (historical comments excluded)
    — **Consumers affected:** operator host (image version), restart script (builds from compose)

- [ ] **1.3** Build the image and smoke it: `docker compose build`, then verify `opencode --version` reports 2.0.8, `/opt/python-env/bin/python --version` runs, `import pandas` succeeds inside the venv, and `/app/.opencode/{agents,skills,plugins}` are non-empty
    — **Why:** hard proof the base-swap (node/python copy-across) and venv relocation work BEFORE any existing machinery is deleted — failure here halts the pipeline with the pm2 fallback still intact
    — **Done when:** build exits 0; `docker run --rm --entrypoint opencode <img> --version` prints `2.0.8`; `docker run --rm --entrypoint /opt/python-env/bin/python <img> -c "import pandas"` exits 0; agent/skill/plugin dir listings are non-empty
    — **Consumers affected:** none (read-only verification)

### Phase 2: Runtime consolidation (bridge + pm2 removal)

- [ ] **2.1** `git rm` the four tracked symlinks under `opencode_app/.opencode/` and delete the bridge exclusion block (comments + 4 path lines) from `.dockerignore`
    — **Why:** the bridge existed solely to feed the pm2 runtime, which 2.2 removes; the `.dockerignore` lines are dead the moment the paths vanish — one atomic removal of the bridge mechanism
    — **Done when:** `git ls-files opencode_app/.opencode/` returns empty; `grep -n "opencode_app/.opencode" .dockerignore` returns nothing
    — **Consumers affected:** `restart-opencode-pm2.sh` (deleted next step), bridge paragraphs in docs (Phase 3)

- [ ] **2.2** Replace `restart-opencode-pm2.sh` with `restart-opencode-docker.sh`: `git checkout main && git pull`, `docker compose up -d --build`, then poll `docker inspect --format '{{.State.Health.Status}}' opencode` until `healthy` (bounded retry honoring the 60s start_period), then the unchanged public-endpoint curl check (200/101)
    — **Why:** the operator entrypoint must manage the container lifecycle instead of pm2; using the image's own HEALTHCHECK (which authenticates with the entrypoint-materialized password) avoids the old script's bare-curl 200 check, which v2 auth makes wrong
    — **Done when:** `restart-opencode-pm2.sh` is deleted; `restart-opencode-docker.sh` exists, is executable, and passes `bash -n`; it contains no pm2 references
    — **Consumers affected:** operator host (public endpoint lifecycle)

- [ ] **2.3** Host-side (uncommitted): set `OPENCODE_VERSION=2.0.8` and `OPENCODE_PORT=4096` in `~/VSCODE/opencode-config-template/.env`
    — **Why:** `.env` overrides the compose default at build time, so without this the 1.2 bumps are inert; port 4096 keeps the `opencode-ha.civiltekk.com` reverse proxy working unchanged — `.env` is gitignored, so this is a host action recorded here for completeness
    — **Done when:** `grep -E '^(OPENCODE_VERSION|OPENCODE_PORT)=' ~/VSCODE/opencode-config-template/.env` shows `2.0.8` and `4096`
    — **Consumers affected:** compose build args and host port mapping at next deploy

### Phase 3: Docs sync

- [ ] **3.1** Root `AGENTS.md` §Source of Truth: drop the "(A symlink bridge under `opencode_app/.opencode/` serves the local pm2 runtime only — sanctioned: symlink bridge.)" parenthetical
    — **Why:** the sanctioned exception is gone; leaving it teaches future sessions a dead mechanism
    — **Done when:** `grep -n "symlink bridge" AGENTS.md` returns nothing
    — **Consumers affected:** every future session

- [ ] **3.2** `opencode_app/AGENTS.md`: rewrite the bridge sentences (container-load line and the two "in a local checkout the same path is a sanctioned symlink bridge" clauses) to describe COPY-at-build sourcing only
    — **Why:** same dead-mechanism removal, scoped doc
    — **Done when:** `grep -n "symlink" opencode_app/AGENTS.md` returns nothing; the agents/skills loading sentences describe the build-time COPY
    — **Consumers affected:** opencode_app-scoped sessions

- [ ] **3.3** `opencode_app/README.md`: remove the bridge tree entry, the symlink/Windows-materialization paragraph, and the `.dockerignore` "symlink bridge" mention; document the 3-stage build layout and the `OPENCODE_VERSION` pin surfaces (repo defaults + host `.env`)
    — **Why:** the operator-facing doc must describe the image people now build; the pin-surface note prevents the exact "bumped only the Dockerfile" trap this ticket fixes
    — **Done when:** `grep -n "symlink" opencode_app/README.md` returns nothing; the README names the three stages and lists all three pin surfaces
    — **Consumers affected:** operators/users

- [ ] **3.4** Run the reference gate: `grep -rnE 'opencode_app[/\\]\.opencode' README.md AGENTS.md opencode_app/ .dockerignore docker-compose.yml restart-opencode-docker.sh` returns nothing outside `PLANS/`, `LEARNINGS/`, `docs/` (historical)
    — **Why:** house grep gate (PLAN-381 lineage) proving no live references to the deleted bridge paths remain
    — **Done when:** the grep returns empty
    — **Consumers affected:** none (verification only)

### Phase 4: End-to-end cutover + verification

- [ ] **4.1** `docker compose up -d` on the host; wait for the container to report `healthy` (goal command registered via the compose healthcheck's `/api/command` grep)
    — **Why:** the live cutover from the old runtime; the healthcheck is the merge-grade proof the goal plugin npm-fetch and registration completed
    — **Done when:** `docker inspect --format '{{.State.Health.Status}}' opencode` prints `healthy`
    — **Consumers affected:** operator host (the public endpoint now serves from Docker)

- [ ] **4.2** Verify plugin load and content: container logs show vibeguard, auto-continue, and learnings-autoinject loading; `/app/.opencode/{agents,skills,plugins}` populated (already smoke-checked in 1.3, re-confirmed live)
    — **Why:** the v1-binary trap (plugins key silently ignored) is exactly what the v2 pin guards against — the log evidence is the regression check
    — **Done when:** `docker logs opencode 2>&1 | grep -ci "vibeguard\|auto-continue\|learnings-autoinject"` > 0
    — **Consumers affected:** none (verification only)

- [ ] **4.3** Endpoint checks: local authenticated curl on `http://localhost:4096` (password from `/home/opencode/.local/share/opencode/server-password` in the container) and the public `https://opencode-ha.civiltekk.com` check return 200 (public: 200 or 101)
    — **Why:** final acceptance — the reverse proxy path users actually hit must work unchanged after cutover
    — **Done when:** both status checks pass
    — **Consumers affected:** end users of the public endpoint

## Technical Notes

- **Venv relocation:** the venv is built at `/opt/python-env` in `python-deps` and copied to the identical path; both Python stages share `python:3.12-slim-bookworm`, so interpreter path and glibc match. Node arrives via `COPY --from=node /usr/local` (node image prefix is `/usr/local`; root-at-build global installs land there).
- **Pin surfaces:** host `.env` (`OPENCODE_VERSION`) overrides the compose default at build time — bumping only the Dockerfile is inert. All three surfaces (`.env`, compose default, Dockerfile ARG) move together (1.2 repo-side, 2.3 host-side).
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
| Cutover moment drops the public endpoint | pm2 not running on this host (verified: `pm2 list` empty); port 4096 free; `OPENCODE_PORT=4096` keeps proxy config untouched; 4.3 verifies both endpoints |
| `.env` not committed → PR reviewers can't see it | `.env` is gitignored by design; the host-side change is documented in 2.3 and must be restated in the PR body deployment notes |
| Another host runs the old pm2 flow | That host runs `restart-opencode-docker.sh` after merge; noted in the PR body |

## Plan Review Trace

_(filled at Step 7)_

## Execution Trace

_(filled by /run-plan — gate memos per phase)_
