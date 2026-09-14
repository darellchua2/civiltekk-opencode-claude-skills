# PLAN: Move skills/agents/plugins to repo root (Phase 1 of #376)

**Branch**: feat/381
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/381
**Base**: main

## Acceptance Criteria

- [ ] `bats tests/` green (the 9 suites carrying deep path refs updated)
- [ ] `node deploy/init.mjs --list skills | jq 'length'` = 149; `--list agents | jq 'length'` = 34 (output is pretty-printed JSON — `wc -l` cannot work)
- [ ] `node deploy/source.mjs` self-check passes (prints skill/agent counts — doubles as the 149/34 verification)
- [ ] Registry regenerated via `node deploy/build-registry.mjs`; counts unchanged (149 skills / 34 agents; raw dirs = 151 incl. `_archived`/`_common`)
- [ ] `docker build` succeeds (or unavailability recorded in PR body)
- [ ] Grep gate, **separator-agnostic** (setup.ps1 spells paths with backslashes): `grep -rnE 'opencode_app[/\\]\.opencode' deploy/ tests/ .releaserc.json .github/workflows/release.yml README.md AGENTS.md opencode_app/ restart-opencode-pm2.sh | grep -v 'sanctioned: symlink bridge'` returns nothing (the marker exempts docs lines explaining the bridge; the four tracked symlinks under `opencode_app/.opencode/` are themselves sanctioned)
- [ ] Public command shape unchanged: `node deploy/init.mjs add tdd-subagent --dry-run` resolves from new source paths

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `skills/`, `agents/`, `plugins/` (root, moved) | — | source.mjs, build-registry.mjs, init.mjs, build-site.mjs, setup.sh (23 refs), setup.ps1 (16 refs), Dockerfile, .releaserc.json assets, release.yml tarball check, 11 bats files, docs | high |
| `deploy/source.mjs` | moved dirs | init.mjs (imports seam), self-check | low (designed seam, 2 lines) |
| `deploy/build-registry.mjs` | moved dirs | registry.json → init.mjs --list/add, setup.sh counts | low |
| `deploy/init.mjs` | source.mjs, registry.json | public npx command, setup.sh (symlinks as opencode-init) | med |
| `deploy/build-site.mjs` | registry.json | GitHub source links (GH_BASE) | low |
| `deploy/setup.sh` | moved dirs, build-registry counts | user-space deploy (4,583 lines; 19 deep refs of 23 — 4 must stay) | high |
| `deploy/setup.ps1` | same | Windows mirror (13 deep **backslash** refs of 16 — 3 must stay) | high |
| `.releaserc.json` | moved dirs | semantic-release assets | med (silent failure) |
| `.github/workflows/release.yml` | moved dirs, package tarball | release CI gate | med |
| `opencode_app/Dockerfile` + root `.dockerignore` | moved dirs | docker compose build (context = repo root) | med |
| `opencode_app/.opencode/*` symlinks | moved dirs | restart-opencode-pm2.sh (local serve, cwd=opencode_app) | low |
| content self-refs (5 SKILL.md, 1 agent .md) | moved dirs | skill/agent readers | low |
| docs (README, AGENTS.md, opencode_app/README, THIRD_PARTY_LICENSES) | final tree | humans | low |

**Deliberately unchanged**: `deploy/skill-profiles.json` + `deploy/dependency-map.json` (refs are to `opencode_app/opencode.json`, which stays), `opencode_app/mcp-servers/*` (stays put), `CHANGELOG.md` (historical release log), `SOURCE_OC = opencode_app/opencode.json` in init.mjs (stays), `PLANS/`, `research/`, `LEARNINGS/` (historical), `opencode_app/.dockerignore` (inert — build context is repo root; leave, noted in docs phase).

## Implementation Phases

> Phase ordering note: Phases 1–4 are one logical rewire split for reviewability; bats runs red between them **by design**. The full test gate runs in Phase 5 and Phase 7. Do not block Phases 1–4 on bats.

### Phase 1: Move content + local runtime bridge
- [ ] **1.1** `git mv opencode_app/.opencode/skills skills && git mv opencode_app/.opencode/agents agents && git mv opencode_app/.opencode/plugins plugins && git mv opencode_app/.opencode/vibeguard.config.json plugins/vibeguard.config.json`
    — **Why:** The move is the ticket's core; everything else re-points at it. History-preserving `git mv` keeps blame.
    — **Done when:** `git status --porcelain` shows only R (rename) entries for the four moves; `ls skills | wc -l` = 151, `ls agents/*.md | wc -l` = 34.
    — **Consumers affected:** all rows of the map above (re-pointed in Phases 2–4).
- [ ] **1.2** Create tracked symlinks for local runtime: `opencode_app/.opencode/agents → ../../agents`, `…/skills → ../../skills`, `…/plugins → ../../plugins`, `…/vibeguard.config.json → ../../plugins/vibeguard.config.json`
    — **Why:** `restart-opencode-pm2.sh` serves with `--cwd opencode_app`; OpenCode auto-discovers `.opencode/{agents,skills,plugins}` from cwd. Without the bridge, the local server loses all content while the Docker path (explicit COPY) is unaffected.
    — **Done when:** `ls -l opencode_app/.opencode/` shows the four symlinks; `test -f opencode_app/.opencode/agents/tdd-subagent.md` (via symlink) succeeds.
    — **Consumers affected:** restart-opencode-pm2.sh (local pm2 serve); none in CI/Docker (excluded from context in 1.3). On Windows clones without symlink support these materialize as text files — cosmetic only, nothing in setup.ps1 consumes them; documented in 7.1.
- [ ] **1.3** Root `.dockerignore`: replace `opencode_app/.opencode/skills/_archived/` with `skills/_archived/` AND add `opencode_app/.opencode/agents`, `opencode_app/.opencode/skills`, `opencode_app/.opencode/plugins`, `opencode_app/.opencode/vibeguard.config.json`
    — **Why:** Context is repo root; `_archived` must stay out of images as before, and the bridge symlinks must never enter the build context (they dangle inside a container).
    — **Done when:** `grep -n '_archived\|opencode_app/.opencode' .dockerignore` shows exactly the five new-form entries; `git check-ignore` style sanity via `tar` is deferred to the Phase 4 docker build.
    — **Consumers affected:** docker compose build.

### Phase 2: Rewire installer/deploy code
- [ ] **2.1** `deploy/source.mjs` lines 21–22: `skillDir`/`agentDir` → `join(root, "skills")` / `join(root, "agents")`
    — **Why:** Designed single seam; init.mjs inherits the fix through its import.
    — **Done when:** `grep -n 'opencode_app' deploy/source.mjs` returns nothing; `node deploy/source.mjs` self-check passes (prints the skill/agent counts — this is also a ticket AC).
    — **Consumers affected:** init.mjs (`add`/`--list` flows).
- [ ] **2.2** `deploy/build-registry.mjs` lines 40–41: `AGENTS_DIR`/`SKILLS_DIR` → repo-root `agents`/`skills`
    — **Why:** Registry generation reads the source dirs; wrong path = empty registry = broken installer + setup counts.
    — **Done when:** `node deploy/build-registry.mjs` exits 0 (defer count check to 5.2).
    — **Consumers affected:** registry.json → init.mjs, setup.sh/ps1 counts, build-site.mjs.
- [ ] **2.3** `deploy/init.mjs` lines 42–43: `AGENTS_SRC`/`SKILLS_SRC` → root `agents`/`skills` (line 51 `SOURCE_OC` stays as `opencode_app/opencode.json`)
    — **Why:** Direct path constants used by user-scope copy and remove flows.
    — **Done when:** `grep -n 'opencode_app/.opencode' deploy/init.mjs` returns nothing; `SOURCE_OC` still resolves.
    — **Consumers affected:** public npx command, setup.sh symlink (opencode-init).
- [ ] **2.4** `deploy/build-site.mjs` line 18: `GH_BASE` → `https://github.com/darellchua2/opencode-config-template/blob/main` and downstream path joins updated to `skills/<name>/SKILL.md` / `agents/<stem>.md`
    — **Why:** Site source links point into the tree; stale base = 404 links.
    — **Done when:** `node deploy/build-site.mjs` (real build — its outputs `docs/index.html`/`docs/registry.json` are git-ignored, so side effects are safe) then `grep -c '/blob/main/skills/' docs/index.html` returns > 0.
    — **Consumers affected:** generated site output.
- [ ] **2.5** `deploy/apply-skill-profile.mjs` line 11 comment: update path mention (comment-only, no behavior)
    — **Why:** Comments that lie are worse than none; zero runtime risk.
    — **Done when:** `grep -n 'opencode_app/.opencode' deploy/apply-skill-profile.mjs` returns nothing.
    — **Consumers affected:** none.

### Phase 3: Rewire deploy scripts
- [ ] **3.1** `deploy/setup.sh`: update the 19 deep `opencode_app/.opencode` refs to the new layout (path vars, copy loops, counts/drift checks, help text). MUST STAY untouched: line ~118 (`SOURCE_CONFIG` = `opencode_app/opencode.json`), line ~2608 (mcp-servers launcher path), comments ~2478/~3581 — they reference `opencode_app/opencode.json` / `mcp-servers/`, not the moved content.
    — **Why:** The user-space deploy is the primary consumer of the content dirs; 4,583 lines means refs hide in heredocs — edit by grep iteration, not by eyeballing. The must-stay list protects the config's single-source seam from over-editing.
    — **Done when:** `grep -nE 'opencode_app[/\\]\.opencode' deploy/setup.sh` returns nothing; the four must-stay refs still present; `bash -n deploy/setup.sh` passes.
    — **Consumers affected:** every user-space deploy; bats count/drift suites.
- [ ] **3.2** `deploy/setup.ps1`: same for the 13 deep refs — **spelled with backslashes** (`opencode_app\.opencode\…`; grep-verified at lines 101, 105, 965, 1002, 1004, 1756, 1772, 1799, 2783, 2790, 2796, 2799 — recount at edit time). MUST STAY untouched: line ~133 (`opencode_app/opencode.json`) and comments ~1744/~1949.
    — **Why:** Mirror must not drift from setup.sh — and backslash spelling is invisible to forward-slash greps, so every gate here is separator-agnostic or Windows deploys rot silently behind a green gate.
    — **Done when:** `grep -nE 'opencode_app[/\\]\.opencode' deploy/setup.ps1` returns nothing; must-stay refs intact; pwsh parse check if pwsh exists (`pwsh -NoProfile -Command "[scriptblock]::Create((Get-Content -Raw deploy/setup.ps1)) | Out-Null"`), else the gap is recorded in the PR body.
    — **Consumers affected:** Windows deploys.

### Phase 4: Release, CI, Docker
- [ ] **4.1** `.releaserc.json` asset globs: `opencode_app/.opencode/agents/**/*` → `agents/**/*`; `opencode_app/.opencode/skills/**/*` → `skills/**/*` (keep the adjacent `deploy/*.mjs` + `opencode_app/opencode.json` entries)
    — **Why:** semantic-release silently ships a content-less tarball if this is missed.
    — **Done when:** `grep -nE 'opencode_app[/\\]\.opencode' .releaserc.json` returns nothing; `npx semantic-release --dry-run` verified in CI, or the local `npm pack --dry-run` fallback (7.2e) passes with the outcome recorded in the PR body.
    — **Consumers affected:** every future release artifact.
- [ ] **4.2** `.github/workflows/release.yml` lines ~59–61: tarball check greps for `skills/` AND `agents/` (replace the single `opencode_app/.opencode/` grep with both, fail message updated); line ~85–86 `opencode_app/opencode.json` refs stay
    — **Why:** The CI gate that would have caught a missed 4.1 currently checks the OLD path — it must gate the new layout instead.
    — **Done when:** `grep -n 'opencode_app/.opencode' .github/workflows/release.yml` returns nothing; the check greps both new dirs.
    — **Consumers affected:** release CI.
- [ ] **4.3** `opencode_app/Dockerfile`: after `COPY opencode_app/ /app/` add `COPY skills/ /app/.opencode/skills/`, `COPY agents/ /app/.opencode/agents/`, `COPY plugins/ /app/.opencode/plugins/`, `COPY plugins/vibeguard.config.json /app/.opencode/vibeguard.config.json` (before the resolve-models RUN; `--agents-src /app/.opencode/agents` etc. unchanged — in-container paths identical)
    — **Why:** Image content previously arrived via `COPY opencode_app/`; after the move it must come from root explicitly, before model injection reads it.
    — **Done when:** `grep -n 'COPY' opencode_app/Dockerfile` shows the four new lines ordered before the resolve-models RUN; `docker build` gate in Phase 7.
    — **Consumers affected:** docker compose users; resolve-models stage.

### Phase 5: Tests + registry regen (first full gate)
- [ ] **5.1** Update the 9 bats files carrying deep refs (`tests/init.bats`, `skill_profiles.bats`, `test_autoresearch_protocol.bats`, `test_autoresearch_skills.bats`, `test_count_drift.bats`, `test_default_behavior.bats`, `test_docling_skill.bats`, `test_markitdown_skill.bats`, `test_pack_permissions.bats`) to the new layout. `test_mcp_count_consistency.bats` has only `opencode_app/opencode.json` refs — no edit needed.
    — **Why:** Tests encode the old layout as truth; they must encode the new one.
    — **Done when:** `grep -rnE 'opencode_app[/\\]\.opencode' tests/` returns nothing; `bats tests/` green.
    — **Consumers affected:** CI.
- [ ] **5.2** Regenerate registry: `node deploy/build-registry.mjs` → counts exactly 149 skills / 34 agents; commit regenerated `deploy/registry.json`
    — **Why:** Registry carries counts + metadata consumed by installer and setup; regen proves the rewire end-to-end.
    — **Done when:** `node -e "const r=require('./deploy/registry.json'); console.log(Object.keys(r.skills).length, Object.keys(r.agents).length)"` prints `149 34` (adapt to actual shape).
    — **Consumers affected:** init.mjs --list/add, setup.sh counts.

### Phase 6: Content self-references
- [ ] **6.1** Update in-content path references: `agents/opencode-tooling-subagent.md` + 3 SKILL.md files (`agent-introspection-debugging-skill`, `context-budget-skill`, `documentation-consistency-skill`) — replace `opencode_app/.opencode/…` mentions with new root paths. ALSO fix `skills/markitdown-mcp-skill/SKILL.md` (~lines 20/235): relative links `../../mcp-servers/markitdown-local-mcp/…` resolve one level wrong after the move → rewrite as `../../opencode_app/mcp-servers/…`. (`opencode-repo-setup-skill` has no deep refs — no edit.)
    — **Why:** These files describe their own repo locations; stale or mis-resolved relative links misdirect maintainers and agents — and relative-link rot is invisible to the literal-path grep.
    — **Done when:** `grep -rnE 'opencode_app[/\\]\.opencode' agents/ skills/ plugins/` returns nothing AND every `../`-relative path mentioned in the edited files resolves (`test -e` from each file's directory).
    — **Consumers affected:** skill/agent readers; none runtime.

### Phase 7: Docs + final verification gates
- [ ] **7.1** Docs: README structure tree + install/npx sections; root `AGENTS.md` (§Source of Truth → root `skills/`+`agents/`, §Subagent Locations row → `agents/*.md`, §Secret Masking vibeguard path → `plugins/vibeguard.config.json`); `opencode_app/AGENTS.md` (~lines 22/26 describe content as "symlinked … at build time" — rewrite for the explicit COPY flow, and describe the 1.2 bridge under the `<!-- sanctioned: symlink bridge -->` marker); `opencode_app/README.md` (Docker content sourcing note; note `opencode_app/.dockerignore` is inert since context=root; note Windows symlink materialization); `THIRD_PARTY_LICENSES.md` line 203 gsap paths
    — **Why:** Docs are the map for every future contributor; the sync rules in AGENTS.md require doc updates with structural change. The bridge must be documented under the sanctioned marker or the AC gate forces it to stay undocumented.
    — **Done when:** `grep -rnE 'opencode_app[/\\]\.opencode' README.md AGENTS.md opencode_app/AGENTS.md opencode_app/README.md THIRD_PARTY_LICENSES.md | grep -v 'sanctioned: symlink bridge'` returns nothing; README tree shows `skills/ agents/ plugins/` at root.
    — **Consumers affected:** humans, opencode-tooling-subagent doc-sync flows.
- [ ] **7.2** Final gates: (a) `bats tests/` green; (b) `node deploy/init.mjs --list skills | jq 'length'` = 149 and `--list agents | jq 'length'` = 34; (b2) `node deploy/source.mjs` self-check passes with matching counts; (c) `node deploy/init.mjs add tdd-subagent --dry-run` succeeds; (d) separator-agnostic grep gate from Acceptance Criteria returns clean; (e) `npm pack --dry-run` output contains both `skills/` and `agents/`; (f) `docker build` succeeds (unavailability recorded in PR body, same convention as 4.1)
    — **Why:** These are the ticket's acceptance criteria, executed in measurable form.
    — **Done when:** All sub-gates pass (or docker-unavailability + pwsh-gap recorded in PR body); results recorded in the PR body.
    — **Consumers affected:** release, Docker, installer users.

## Technical Notes

- `listAvailable` filters `_`-prefixed dirs → `_archived` + `_common` move along with `skills/` and stay invisible: 151 raw = 149 effective. No counting change.
- `package.json` has no `files` array → root content enters the npm tarball automatically; only the release.yml grep needed updating (4.2).
- Root `AGENTS.md` frontmatter contract says registry regen must follow content changes and `registry.json` committed (5.2).
- The four tracked symlinks (1.2) are the only sanctioned `opencode_app/.opencode/*` paths remaining; they are excluded from Docker context (1.3) and referenced by the local pm2 flow only.
- Do NOT touch: `CHANGELOG.md` (historical), `PLANS/`, `research/`, `LEARNINGS/`, `opencode_app/mcp-servers/`, `opencode_app/opencode.json`, `deploy/skill-profiles.json`, `deploy/dependency-map.json`.
- PR body must flag two ticket-text deviations (both entailed by the epic's intent): the 1.2 symlink bridge (four new tracked files keeping `restart-opencode-pm2.sh` local serve working) and the 4.2 release.yml gate rewire (the CI tarball check would otherwise gate on a dead path).

## Dependencies

- None external. Parent epic #376; sibling phases (#378 split, #380 normalize) build on this layout and must NOT be mixed into this PR.

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| setup.sh heredoc-hidden refs missed | grep-zero gate is the Phase 3/7 done-condition, `bash -n` syntax check |
| semantic-release ships content-less tarball | 4.1 + 4.2 CI grep re-pointed; `npm pack --dry-run` local gate 7.2e |
| Docker build breaks on COPY order/exclusions | 4.3 orders COPY before resolve-models; 1.3 excludes symlinks; docker build in 7.2f |
| Bats red between Phases 1–4 confuses the executor | Explicit ordering note at top of Implementation Phases; full gate only at 5/7 |
| Registry counts drift (149/34) | 5.2 hard gate — abort on mismatch |
| Local pm2 serve silently loses content | 1.2 symlink bridge + verification via symlink resolution |
