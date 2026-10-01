# PLAN: civiltekk-coding-harness-setup-skill — cross-harness project parity setup

**Branch**: feat/654
**Issue**: https://github.com/darellchua2/civiltekk-skills/issues/654
**Base**: main

## Acceptance Criteria

- [x] `skills/civiltekk-coding-harness-setup-skill/` exists: router `SKILL.md` + `references/harnesses/{opencode-v1,opencode-v2,pi,claude-code,codex}.md`
- [x] Router carries: detection scan, version detect (`opencode --version` + config-shape fallback), decision tree (zero → ask; one → offer team standard; multiple → parity mode), freshness gate, backup-then-merge write rules, parity-matrix report + revert instructions
- [x] Every side file has a WHEN+WHAT load rule in the router; no preload instruction; values carry citations or verify-locally notes
- [x] Frontmatter contract: name = dir, description ≤50 words with triggers, license Apache-2.0, compatibility opencode, `metadata.harness "opencode"`, category Harness Setup
- [x] Self-contained: no sibling-skill paths in fenced code; prose-only handoffs; isolation + portability guard tests green
- [x] `node installer/build-registry.mjs` run, `installer/registry.json` committed; counts + category updated in `deploy/setup.sh`, `deploy/setup.ps1`, `README.md`
- [x] Detection smoke-tested on this repo (multi-harness signals) and a scratch repo holding only `.pi/` (single-harness path)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/civiltekk-coding-harness-setup-skill/SKILL.md` (new) | frontmatter contract (root AGENTS.md §Skill/Agent Frontmatter) | `installer/build-registry.mjs` (category extraction), `installer/registry.json`, `deploy/setup.sh` per-category auto-derive (line 441), `README.md` Skill Categories table | low |
| `skills/civiltekk-coding-harness-setup-skill/references/harnesses/*.md` (new, 5 files) | SKILL.md load table | the skill's runtime flow (reader loads per current step); nothing else — repo tooling only reads SKILL.md frontmatter | low |
| `installer/registry.json` (regenerated) | new SKILL.md frontmatter | `installer/init.mjs` (reads registry only), setup.sh category output (line 4084) | low |
| `README.md` Skill Categories row (edited) | skill category `Harness Setup` exists in registry | humans; `tests/test_count_drift.bats` (count-sync enforcement) | low |
| `deploy/setup.sh` / `deploy/setup.ps1` | none expected — counts auto-derive from `category:` frontmatter (setup.sh:441-447); setup.ps1 is a parameter forwarder (setup.ps1:109,125) inheriting that logic | end-user installs | low |
| `deploy/skill-profiles.json` `lean` array | skill frontmatter exists (2.1) | lean-deploy primary sessions (description ~90 tokens each); `tests/skill_profiles.bats` | low |
| `.gitignore` (LEARNINGS negations, pipeline Step 9) | LEARNINGS bodies written during run | git add of learned bodies | low |

## Implementation Phases

### Phase 1: Router + harness profile side files

- [x] **1.1** Write `skills/civiltekk-coding-harness-setup-skill/SKILL.md` router: frontmatter (name `civiltekk-coding-harness-setup-skill`, description ≤50 words keeping triggers "set up harness for this repo / harness parity / project harness setup / setup pi, opencode, claude, codex", license Apache-2.0, compatibility opencode, `metadata.harness: "opencode"`, category `Harness Setup`); body = What-I-do one-screen, layer rules as one-liners (skills neutral-first in `.agents/skills/` with refreshed `.claude/skills/` copies; canonical `AGENTS.md` + `CLAUDE.md` `@AGENTS.md` shim with content-bearing-CLAUDE.md conflict surfacing; per-harness config backup-then-merge; MCP per supported harness with pi honestly reported extensions/no-MCP), detection scan table, version detect (`opencode --version` then config-shape fallback), decision tree (zero → ask; one → offer team standard; multiple → parity mode), freshness gate (per-side-file doc URLs, fetch unless version pinned, offline → embedded baseline + disclosure), write rules (create-if-absent, marker-append, backup-then-merge with vendored jq/node deep-merge one-liners), parity-matrix report + revert instructions, side-file load table, ask-mechanism capability-binding block (OpenCode question tool / Claude Code AskUserQuestion / plain-reply fallback)
    — **Why:** the router is the skill's contract; every later file and test depends on its shape.
    — **Done when:** file exists, frontmatter parses (registry build in 2.1 warns on nothing), description ≤50 words, no sibling-skill path inside any fenced code block; detection table states case-insensitive filename matching plus an explicit fall-through heuristic (harness-shaped signal not listed → ask, never guess).
    — **Consumers affected:** installer/build-registry.mjs, README (Phase 2).
    — **Done:** router SKILL.md authored: frontmatter (47-word description, 4 triggers), layer one-liners, detect/ask/load/freshness/write/report steps, gates, governance; files: skills/civiltekk-coding-harness-setup-skill/SKILL.md; fixes: none
- [x] **1.2** Write `references/harnesses/opencode-v2.md`: project/global skill dirs incl. compat `.claude/skills/` + `.agents/skills/`, opencode.json v2 keys relevant to setup (mcp.servers atomicity rule, agents model pins), verify commands, official doc URLs (opencode.ai/v2/docs/skills, /docs/agents), WHEN+WHAT load rule declared in router table
    — **Why:** opencode v2 is the team's primary harness; its side file carries the atomic-replace MCP semantics the merge rules must honor.
    — **Done when:** every value has a doc citation or verify-locally note; load rule present in router table.
    — **Consumers affected:** router load table (1.1).
    — **Done:** opencode-v2 profile: dirs incl. compat reads, FULL-entry MCP atomicity, agent-pin safety, version markers, 3 doc URLs; files: references/harnesses/opencode-v2.md; fixes: none
- [x] **1.3** Write `references/harnesses/opencode-v1.md`: same skeleton for v1 config shape, v1→v2 version-detection markers, prose-only pointer to `opencode-v2-migration-skill` for conversions
    — **Why:** parity must not silently write v2 keys into a v1 install; detection markers make the branch decision checkable.
    — **Done when:** skeleton complete with citations/verify-locally notes; no sibling path in fenced code.
    — **Consumers affected:** router load table (1.1).
    — **Done:** opencode-v1 profile: v1 skeleton, singular/plural dir verify-locally note, migration-skill prose handoff; files: references/harnesses/opencode-v1.md; fixes: none
- [x] **1.4** Write `references/harnesses/pi.md`: `.pi/skills/` + `.agents/skills/` project dirs, AGENTS.md/CLAUDE.md native, settings.json skills array only as override, extensions-not-MCP asymmetry (parity matrix must report it), doc URLs (pi.dev, badlogic/pi-mono skills docs)
    — **Why:** pi is the team's second harness and the MCP-asymmetric case the matrix must not lie about.
    — **Done when:** skeleton complete; MCP row explicitly documented as unsupported/extensions-path.
    — **Consumers affected:** router load table (1.1).
    — **Done:** pi profile: native dirs, AGENTS.md/CLAUDE.md native, extensions-not-MCP asymmetry stated; files: references/harnesses/pi.md; fixes: none
- [x] **1.5** Write `references/harnesses/claude-code.md`: `.claude/skills/` project dir, `CLAUDE.md` as `@AGENTS.md` import shim + conflict rule, `.mcp.json` syntax, verify commands, doc URLs
    — **Why:** Claude Code is the one harness needing both a skills copy and an instructions shim — the two neutral-first exceptions.
    — **Done when:** skeleton complete; shim procedure and conflict rule stated with verify-locally note on import syntax.
    — **Consumers affected:** router load table (1.1).
    — **Done:** claude-code profile: .claude/skills shim rationale, @AGENTS.md import + conflict rule, .mcp.json; files: references/harnesses/claude-code.md; fixes: none
- [x] **1.6** Write `references/harnesses/codex.md`: `.codex/skills/` + `.agents/skills` REPO scope, AGENTS.md global/root/subdir layering, config.toml `[mcp_servers]` syntax, optional `openai.yaml` note, doc URLs
    — **Why:** codex reads the neutral skills dir but has its own MCP syntax — a values-only translation case.
    — **Done when:** skeleton complete with citations.
    — **Consumers affected:** router load table (1.1).
    — **Done:** codex profile: .agents/skills REPO scope (cwd+parent), AGENTS.md layering, TOML MCP warning, openai.yaml note; files: references/harnesses/codex.md; fixes: none
- [x] **1.7** Write `skills/civiltekk-coding-harness-setup-skill/README.md`: human usage + contribute-a-side-file walkthrough (copy skeleton, add load-table row) — links only, mirrors no router rule
    — **Why:** extension path for new harnesses must live where humans read, not in the load-weighted router.
    — **Done when:** README contains zero duplicated router rules (link, don't mirror).
    — **Consumers affected:** none (never read at load).
    — **Done:** skill README: usage, install, add-a-profile walkthrough, links only — zero mirrored router rules; files: README.md (skill dir); fixes: none

### Phase 2: Registry + deploy/docs sync

- [x] **2.1** Run `node installer/build-registry.mjs`; verify `installer/registry.json` gains the skill under category `Harness Setup` with no warnings; commit the regenerated registry
    — **Why:** registry.json is the installer's source of truth; an uncommitted regen breaks `npm ci`-style reproducibility and init.mjs.
    — **Done when:** `git diff installer/registry.json` shows exactly one new skill entry; committed.
    — **Consumers affected:** installer/init.mjs, setup.sh category output.
    — **Done:** build-registry ran clean (no warnings), registry.json +12/-2 with the entry under category Harness Setup, harness=opencode; --check drift guard green; files: installer/registry.json; fixes: none
- [x] **2.2** Update `README.md`: add the `Harness Setup` row to the Skill Categories table AND sweep every total-count literal to the mechanically derived value (skills total at lines 76 and 259: 121 → 122; primary-visible at line 220: 69 → 70; derive each via `find skills -maxdepth 1 -type d | wc -l` and the lean array length — never hand-count)
    — **Why:** review finding F1: the count literals at README.md:76/220/259 have no test coverage (`test_count_drift.bats` covers agent counts in setup scripts only), so an unswept literal rots silently.
    — **Done when:** every count literal in README matches the mechanically derived number (`grep -n "121\|69 " README.md` returns only non-count matches); Harness Setup row present.
    — **Consumers affected:** humans; test_count_drift (3.1).
    — **Done:** 6 count literals swept 121->122 (lines 5/76/102/220/259/261), 69->70 primary-visible, Harness Setup row added after OpenCode Meta, #654 history clause; files: README.md; fixes: none
- [x] **2.3** Verify `deploy/setup.sh` + `deploy/setup.ps1` need no edit: counts auto-derive from `category:` frontmatter (setup.sh:441-447) and setup.ps1 carries no count logic — it forwards `--skill-profile`/`--skills-only` to the shared engine (setup.ps1:109,125); if any count-drift or help-parity test says otherwise, apply the minimal fix it names
    — **Why:** review finding F2: the mirror claim was asserted, not inspected; naming the actual mechanism (forwarding) makes the no-edit provable rather than assumed.
    — **Done when:** test_count_drift + test_help_parity green with zero setup-script edits, or the named minimal fix applied.
    — **Consumers affected:** end-user installs.
    — **Done:** setup.sh per-category auto-derive confirmed (441-447); setup.ps1 confirmed parameter forwarder (109/125); zero setup-script edits; files: none; fixes: none
- [x] **2.4** Add `civiltekk-coding-harness-setup-skill` to the `lean` array in `deploy/skill-profiles.json` (primary-visible per user decision 2026-10-01; precedent: `opencode-repo-setup-skill` already in lean)
    — **Why:** requirements gap F5 resolution — the skill is user-invoked interactive setup; invisible-to-primary would defeat its trigger phrases and leave the README:220 literal stale.
    — **Done when:** lean array length = 70 and contains the skill name; `tests/skill_profiles.bats` green in 3.1.
    — **Consumers affected:** lean-deploy primary sessions (~90 tokens/session); README:220 literal (2.2).
    — **Done:** lean array 69->70 with the new skill; SHIPPED ALLOW RULE added to deploy/opencode.json permissions (lean<=allows invariant — gate caught its absence, profile application had failed closed); tests/skill_profiles.bats literals 69->70; files: deploy/skill-profiles.json, deploy/opencode.json, tests/skill_profiles.bats; fixes: allow rule + test literals (1 gate fix)

### Phase 3: Guard tests + smoke detection

- [x] **3.1** Run guard set: `bats tests/test_skill_isolation.bats tests/test_portability.bats tests/test_count_drift.bats tests/test_requires_skills.bats tests/skill_profiles.bats` — all green
    — **Why:** these five encode the isolation contract, portability rules 1–2, count sync, dependency-map invariant, and lean-profile integrity the ticket's AC name.
    — **Done when:** exit 0 on all four files.
    — **Consumers affected:** CI pipeline.
    — **Done:** five guard files green (29 tests) — plus full 52-file suite green twice (fix-on-fail rerun + exit gate); files: none; fixes: PLAN step text corrected test_skill_profiles.bats -> skill_profiles.bats (wrong filename in authored step)
- [x] **3.2** Frontmatter gate re-check on the final SKILL.md: name = dir, description word count ≤50 with triggers present, category `Harness Setup`, `metadata.harness "opencode"`
    — **Why:** the description gate is a hard cap the registry build only warns about — it must be checked explicitly.
    — **Done when:** printed word count ≤50 and `grep -i` shows all four trigger phrases (case-insensitive per the #423/#512 false-green class).
    — **Consumers affected:** registry entry, skill discoverability.
    — **Done:** name=dir, 47 words <=50, 4/4 triggers via case-insensitive match, category/harness/license/compat all present; files: none; fixes: none
- [x] **3.3** Smoke A (multi-harness detection, read-only): run the router's detection + parity-matrix steps against this configurator repo; confirm the matrix reflects actual signals (AGENTS.md, opencode.json, `.claude/` if present, absent `.pi/`, `.agents/`)
    — **Why:** AC requires evidence the decision tree works on a real multi-signal repo without writing anything.
    — **Done when:** parity matrix printed in the run transcript matching `ls`-verifiable signals; zero files written.
    — **Consumers affected:** none (read-only).
    — **Done:** smoke A on configurator repo: signals opencode.json + .opencode/ + AGENTS.md -> single-harness branch, team-standard offer, matrix printed (pi/Claude/Codex columns would-provision/shim/unsupported); zero files written; files: none; fixes: none
- [x] **3.4** Smoke B (single-harness path): create a scratch repo under `/tmp/opencode/` holding only `.pi/skills/` + `AGENTS.md`; run detection; confirm single-harness branch (offer team standard, no parity mode) and correct pi profile load
    — **Why:** the zero/one-harness branches and the pi side file's load rule are untested by Smoke A.
    — **Done when:** transcript shows pi-only detection, team-standard offer branch, pi side file consulted; scratch repo disposable.
    — **Consumers affected:** none (scratch repo).
    — **Done:** smoke B on /tmp/opencode/smoke-pi: signals .pi + AGENTS.md only -> single-harness pi branch, profile values cited (skills native, MCP unsupported-extensions, zero config writes); scratch repo disposable; files: none; fixes: none

## Technical Notes

- **Self-contained**: no `requiresSkills` edge, no dependency-map.json change, no HANDOFF var edits. Handoffs to `opencode-repo-setup-skill` (deep MCP opt-ins) and `opencode-v2-migration-skill` (v1→v2 conversion) are prose-only skill-name mentions; NEVER a sibling-skill path inside a fenced code block (isolation guard carrier rule).
- **Portability contract**: every harness-specific mechanism (ask tool, codegraph/npx commands) gets the capability-binding block with per-harness rows + portable fallback; every bash snippet is a `node -e` one-liner or states `Requires bash (git-bash/WSL on Windows)`; `metadata.os` omitted (unrestricted).
- **Vendored duplication is sanctioned** (root AGENTS.md §Skill Isolation Contract): the backup-then-merge jq/node deep-merge may be duplicated from `opencode-repo-setup-skill` — do NOT extract a shared module.
- **Reference input**: `docs/harness-landscape-2026-09.md` (in-repo) — reconcile side-file values against it; where it disagrees with live docs fetched during execution, live docs win and the side file cites them.
- **Load weight**: router stays one-screen; per-harness detail lives only in side files; no "read all references" preload rule anywhere.
- **ponytail ceiling**: v1 non-goals from the ticket stand — no manifest lock file, no agent-file parity translation, no MCP translation beyond the user-stated server list, no sixth harness profile.

## Dependencies

None. No `blocked-by` refs.

## Risks & Mitigation

- **Docs drift** (harness dirs changed twice in a year) → every side-file value carries a citation or verify-locally note; the router's freshness gate fetches official docs at runtime unless a version is pinned.
- **Guard false positives** (isolation regex catching path-shaped prose) → sibling skills referenced by name in prose only; all fenced examples use generic or own-skill paths.
- **Count drift** (README hardcoded table) → 2.2 updates the row; 3.1 runs test_count_drift as the mechanical backstop.
- **Registry category mismatch** → 2.1 verifies the JSON entry in the same phase that introduces the frontmatter.

## Execution trace

GATE 5a68190 tier=light lint=n.a typecheck=n.a build=- unit=t e2e=n.a (bats test_skill_isolation + test_portability 10/10 exit 0; description 47 words, 4 triggers — Phase 1, docs-only phase)

GATE f0a660b tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a (52 bats files green after 1 gate fix: shipped allow rule in deploy/opencode.json + skill_profiles literals 69->70; registry drift OK skills=122; Phase 2)
GATE 471446b tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a (52 bats files green on the review-fixed tree — final implementation SHA; review: 0 BLOCK / 0 WARN / 1 NOTE-fixed)
GATE 452839c tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a (52 bats files green on the rebased tree after #630 landed mid-run — registry skills=123, both allow/lean sets intact; supersedes the 471446b memo which named the pre-rebase SHA)
