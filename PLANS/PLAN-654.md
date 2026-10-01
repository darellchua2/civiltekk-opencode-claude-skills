# PLAN: civiltekk-coding-harness-setup-skill — cross-harness project parity setup

**Branch**: feat/654
**Issue**: https://github.com/darellchua2/civiltekk-skills/issues/654
**Base**: main

## Acceptance Criteria

- [ ] `skills/civiltekk-coding-harness-setup-skill/` exists: router `SKILL.md` + `references/harnesses/{opencode-v1,opencode-v2,pi,claude-code,codex}.md`
- [ ] Router carries: detection scan, version detect (`opencode --version` + config-shape fallback), decision tree (zero → ask; one → offer team standard; multiple → parity mode), freshness gate, backup-then-merge write rules, parity-matrix report + revert instructions
- [ ] Every side file has a WHEN+WHAT load rule in the router; no preload instruction; values carry citations or verify-locally notes
- [ ] Frontmatter contract: name = dir, description ≤50 words with triggers, license Apache-2.0, compatibility opencode, `metadata.harness "opencode"`, category Harness Setup
- [ ] Self-contained: no sibling-skill paths in fenced code; prose-only handoffs; isolation + portability guard tests green
- [ ] `node installer/build-registry.mjs` run, `installer/registry.json` committed; counts + category updated in `deploy/setup.sh`, `deploy/setup.ps1`, `README.md`
- [ ] Detection smoke-tested on this repo (multi-harness signals) and a scratch repo holding only `.pi/` (single-harness path)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/civiltekk-coding-harness-setup-skill/SKILL.md` (new) | frontmatter contract (root AGENTS.md §Skill/Agent Frontmatter) | `installer/build-registry.mjs` (category extraction), `installer/registry.json`, `deploy/setup.sh` per-category auto-derive (line 441), `README.md` Skill Categories table | low |
| `skills/civiltekk-coding-harness-setup-skill/references/harnesses/*.md` (new, 5 files) | SKILL.md load table | the skill's runtime flow (reader loads per current step); nothing else — repo tooling only reads SKILL.md frontmatter | low |
| `installer/registry.json` (regenerated) | new SKILL.md frontmatter | `installer/init.mjs` (reads registry only), setup.sh category output (line 4084) | low |
| `README.md` Skill Categories row (edited) | skill category `Harness Setup` exists in registry | humans; `tests/test_count_drift.bats` (count-sync enforcement) | low |
| `deploy/setup.sh` / `deploy/setup.ps1` | none expected — counts auto-derive from `category:` frontmatter (setup.sh:441-447); setup.ps1 is a parameter forwarder (setup.ps1:109,125) inheriting that logic | end-user installs | low |
| `deploy/skill-profiles.json` `lean` array | skill frontmatter exists (2.1) | lean-deploy primary sessions (description ~90 tokens each); `tests/test_skill_profiles.bats` | low |
| `.gitignore` (LEARNINGS negations, pipeline Step 9) | LEARNINGS bodies written during run | git add of learned bodies | low |

## Implementation Phases

### Phase 1: Router + harness profile side files

- [ ] **1.1** Write `skills/civiltekk-coding-harness-setup-skill/SKILL.md` router: frontmatter (name `civiltekk-coding-harness-setup-skill`, description ≤50 words keeping triggers "set up harness for this repo / harness parity / project harness setup / setup pi, opencode, claude, codex", license Apache-2.0, compatibility opencode, `metadata.harness: "opencode"`, category `Harness Setup`); body = What-I-do one-screen, layer rules as one-liners (skills neutral-first in `.agents/skills/` with refreshed `.claude/skills/` copies; canonical `AGENTS.md` + `CLAUDE.md` `@AGENTS.md` shim with content-bearing-CLAUDE.md conflict surfacing; per-harness config backup-then-merge; MCP per supported harness with pi honestly reported extensions/no-MCP), detection scan table, version detect (`opencode --version` then config-shape fallback), decision tree (zero → ask; one → offer team standard; multiple → parity mode), freshness gate (per-side-file doc URLs, fetch unless version pinned, offline → embedded baseline + disclosure), write rules (create-if-absent, marker-append, backup-then-merge with vendored jq/node deep-merge one-liners), parity-matrix report + revert instructions, side-file load table, ask-mechanism capability-binding block (OpenCode question tool / Claude Code AskUserQuestion / plain-reply fallback)
    — **Why:** the router is the skill's contract; every later file and test depends on its shape.
    — **Done when:** file exists, frontmatter parses (registry build in 2.1 warns on nothing), description ≤50 words, no sibling-skill path inside any fenced code block; detection table states case-insensitive filename matching plus an explicit fall-through heuristic (harness-shaped signal not listed → ask, never guess).
    — **Consumers affected:** installer/build-registry.mjs, README (Phase 2).
- [ ] **1.2** Write `references/harnesses/opencode-v2.md`: project/global skill dirs incl. compat `.claude/skills/` + `.agents/skills/`, opencode.json v2 keys relevant to setup (mcp.servers atomicity rule, agents model pins), verify commands, official doc URLs (opencode.ai/v2/docs/skills, /docs/agents), WHEN+WHAT load rule declared in router table
    — **Why:** opencode v2 is the team's primary harness; its side file carries the atomic-replace MCP semantics the merge rules must honor.
    — **Done when:** every value has a doc citation or verify-locally note; load rule present in router table.
    — **Consumers affected:** router load table (1.1).
- [ ] **1.3** Write `references/harnesses/opencode-v1.md`: same skeleton for v1 config shape, v1→v2 version-detection markers, prose-only pointer to `opencode-v2-migration-skill` for conversions
    — **Why:** parity must not silently write v2 keys into a v1 install; detection markers make the branch decision checkable.
    — **Done when:** skeleton complete with citations/verify-locally notes; no sibling path in fenced code.
    — **Consumers affected:** router load table (1.1).
- [ ] **1.4** Write `references/harnesses/pi.md`: `.pi/skills/` + `.agents/skills/` project dirs, AGENTS.md/CLAUDE.md native, settings.json skills array only as override, extensions-not-MCP asymmetry (parity matrix must report it), doc URLs (pi.dev, badlogic/pi-mono skills docs)
    — **Why:** pi is the team's second harness and the MCP-asymmetric case the matrix must not lie about.
    — **Done when:** skeleton complete; MCP row explicitly documented as unsupported/extensions-path.
    — **Consumers affected:** router load table (1.1).
- [ ] **1.5** Write `references/harnesses/claude-code.md`: `.claude/skills/` project dir, `CLAUDE.md` as `@AGENTS.md` import shim + conflict rule, `.mcp.json` syntax, verify commands, doc URLs
    — **Why:** Claude Code is the one harness needing both a skills copy and an instructions shim — the two neutral-first exceptions.
    — **Done when:** skeleton complete; shim procedure and conflict rule stated with verify-locally note on import syntax.
    — **Consumers affected:** router load table (1.1).
- [ ] **1.6** Write `references/harnesses/codex.md`: `.codex/skills/` + `.agents/skills` REPO scope, AGENTS.md global/root/subdir layering, config.toml `[mcp_servers]` syntax, optional `openai.yaml` note, doc URLs
    — **Why:** codex reads the neutral skills dir but has its own MCP syntax — a values-only translation case.
    — **Done when:** skeleton complete with citations.
    — **Consumers affected:** router load table (1.1).
- [ ] **1.7** Write `skills/civiltekk-coding-harness-setup-skill/README.md`: human usage + contribute-a-side-file walkthrough (copy skeleton, add load-table row) — links only, mirrors no router rule
    — **Why:** extension path for new harnesses must live where humans read, not in the load-weighted router.
    — **Done when:** README contains zero duplicated router rules (link, don't mirror).
    — **Consumers affected:** none (never read at load).

### Phase 2: Registry + deploy/docs sync

- [ ] **2.1** Run `node installer/build-registry.mjs`; verify `installer/registry.json` gains the skill under category `Harness Setup` with no warnings; commit the regenerated registry
    — **Why:** registry.json is the installer's source of truth; an uncommitted regen breaks `npm ci`-style reproducibility and init.mjs.
    — **Done when:** `git diff installer/registry.json` shows exactly one new skill entry; committed.
    — **Consumers affected:** installer/init.mjs, setup.sh category output.
- [ ] **2.2** Update `README.md`: add the `Harness Setup` row to the Skill Categories table AND sweep every total-count literal to the mechanically derived value (skills total at lines 76 and 259: 121 → 122; primary-visible at line 220: 69 → 70; derive each via `find skills -maxdepth 1 -type d | wc -l` and the lean array length — never hand-count)
    — **Why:** review finding F1: the count literals at README.md:76/220/259 have no test coverage (`test_count_drift.bats` covers agent counts in setup scripts only), so an unswept literal rots silently.
    — **Done when:** every count literal in README matches the mechanically derived number (`grep -n "121\|69 " README.md` returns only non-count matches); Harness Setup row present.
    — **Consumers affected:** humans; test_count_drift (3.1).
- [ ] **2.3** Verify `deploy/setup.sh` + `deploy/setup.ps1` need no edit: counts auto-derive from `category:` frontmatter (setup.sh:441-447) and setup.ps1 carries no count logic — it forwards `--skill-profile`/`--skills-only` to the shared engine (setup.ps1:109,125); if any count-drift or help-parity test says otherwise, apply the minimal fix it names
    — **Why:** review finding F2: the mirror claim was asserted, not inspected; naming the actual mechanism (forwarding) makes the no-edit provable rather than assumed.
    — **Done when:** test_count_drift + test_help_parity green with zero setup-script edits, or the named minimal fix applied.
    — **Consumers affected:** end-user installs.
- [ ] **2.4** Add `civiltekk-coding-harness-setup-skill` to the `lean` array in `deploy/skill-profiles.json` (primary-visible per user decision 2026-10-01; precedent: `opencode-repo-setup-skill` already in lean)
    — **Why:** requirements gap F5 resolution — the skill is user-invoked interactive setup; invisible-to-primary would defeat its trigger phrases and leave the README:220 literal stale.
    — **Done when:** lean array length = 70 and contains the skill name; `tests/test_skill_profiles.bats` green in 3.1.
    — **Consumers affected:** lean-deploy primary sessions (~90 tokens/session); README:220 literal (2.2).

### Phase 3: Guard tests + smoke detection

- [ ] **3.1** Run guard set: `bats tests/test_skill_isolation.bats tests/test_portability.bats tests/test_count_drift.bats tests/test_requires_skills.bats tests/test_skill_profiles.bats` — all green
    — **Why:** these five encode the isolation contract, portability rules 1–2, count sync, dependency-map invariant, and lean-profile integrity the ticket's AC name.
    — **Done when:** exit 0 on all four files.
    — **Consumers affected:** CI pipeline.
- [ ] **3.2** Frontmatter gate re-check on the final SKILL.md: name = dir, description word count ≤50 with triggers present, category `Harness Setup`, `metadata.harness "opencode"`
    — **Why:** the description gate is a hard cap the registry build only warns about — it must be checked explicitly.
    — **Done when:** printed word count ≤50 and `grep -i` shows all four trigger phrases (case-insensitive per the #423/#512 false-green class).
    — **Consumers affected:** registry entry, skill discoverability.
- [ ] **3.3** Smoke A (multi-harness detection, read-only): run the router's detection + parity-matrix steps against this configurator repo; confirm the matrix reflects actual signals (AGENTS.md, opencode.json, `.claude/` if present, absent `.pi/`, `.agents/`)
    — **Why:** AC requires evidence the decision tree works on a real multi-signal repo without writing anything.
    — **Done when:** parity matrix printed in the run transcript matching `ls`-verifiable signals; zero files written.
    — **Consumers affected:** none (read-only).
- [ ] **3.4** Smoke B (single-harness path): create a scratch repo under `/tmp/opencode/` holding only `.pi/skills/` + `AGENTS.md`; run detection; confirm single-harness branch (offer team standard, no parity mode) and correct pi profile load
    — **Why:** the zero/one-harness branches and the pi side file's load rule are untested by Smoke A.
    — **Done when:** transcript shows pi-only detection, team-standard offer branch, pi side file consulted; scratch repo disposable.
    — **Consumers affected:** none (scratch repo).

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
