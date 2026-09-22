# PLAN: Rebrand repo and rework README for shared skills collection

**Branch**: feat/536
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/536
**Base**: main

## Acceptance Criteria

- [ ] `research/` and `docs/` deleted
- [ ] `LEARNINGS/` contains only `_index.md` + category dirs with `.gitkeep`; `.gitignore` has `LEARNINGS/**/*.md` and `!LEARNINGS/_index.md`
- [ ] `grep -rn "opencode-config-template"` hits zero outside CHANGELOG.md and PLANS/
- [ ] README titled "CivilTekk OpenCode & Claude Skills" with: purpose intro, /create-ticket + /run-worktree-pipeline + /run-plan + /goal commands table (incl. full-deploy note), simplified install paths, updated directory tree, opencode_app/ Docker purpose section, Support section linking issue templates, deep reference in `<details>`
- [ ] Broken `PLAN.md` link fixed; skill/agent counts re-derived from `ls`; Pages URL updated to the new repo name
- [ ] `bash -n` passes on touched scripts; `node --check` passes on touched .mjs; relevant bats guards pass

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `research/`, `docs/` | — | two stale doc pointers in living plugin READMEs (fixed in 2.2) | low |
| `LEARNINGS/` content | — | learnings autoinject plugin (runtime dir scan, not git); no bats test depends on the dir | low |
| `.gitignore` | LEARNINGS skeleton (Phase 1 order) | git tracking only | low |
| `deploy/setup.sh` (name refs in help/comments) | — | bats: parse_arguments, init, deploy_delegate, test_count_drift (source it / grep its banner); opencode-setup bin | med — functional script; verify `bash -n` + bats subset |
| `installer/build-site.mjs` (repo-name/URL refs) | — | release.yml pages job (functional URL output) | med — `node --check` |
| `installer/templates/api-quality/{README.md,api-quality-rules.mjs,pre-commit-redocly,redocly.yaml}` | — | installed into downstream repos; pre-commit-redocly is `/bin/sh` → joins `bash -n` | low |
| `opencode_app/Dockerfile` (OCI `title` + `source` labels, :33/:35) | — | image registries + GitHub repo↔image linkage (machine-read metadata) | med — label edit, build-arg unaffected |
| `agents/opencode-tooling-subagent.md`, 3 SKILL.md files (name refs) | — | per-skill npx installs (doc text only) | low |
| `restart-opencode-docker.sh` (comment) | — | maintainer redeploy flow | low |
| `plugins/README.md`, `plugins/opencode-learnings-autoinject.README.md` (stale `research/` pointers) | Phase 1 deletion (2.2 follows 1.1) | humans reading plugin docs | low |
| `AGENTS.md` (Repository Purpose npx refs) | rename sweep (Phase 2) | repo agents/contributors | low |
| `README.md` | rename sweep FIRST (single edit pass over renamed text) | `test_markitdown_skill.bats` (:102 "N skill director(y|ies)" == disk; :110 "Configuration (N)" == registry.json) and `test_mcp_count_consistency.bats` (:39 "ships N MCP server entries" == mcp.servers count) — **README literals ARE test-consumed**; also `opencode_app/README.md` watch-clause (:97 same skill-count assertion) if Phase 3 touches it | med — rework may rephrase pinned literals; 3.3 done-when pins them |

## Implementation Phases

### Phase 1: Cleanup & LEARNINGS skeleton

- [x] **1.1** `git rm -r research/ docs/` in the worktree
    — **Why:** unreferenced internal artifacts shipped as if product (grep-verified: only stale doc pointers remain, fixed in 2.2)
    — **Done when:** `test ! -d research && test ! -d docs` in the worktree; deletions staged
    — **Consumers affected:** none (living pointers fixed in 2.2)
    — **Done:** git rm -r research/ docs/ — dirs gone, deletions staged; files: research/, docs/; fixes: none
- [x] **1.2** Reduce `LEARNINGS/` to skeleton: `git rm` all `LEARNINGS/**/*.md` EXCEPT `_index.md`; keep `patterns/ decisions/ solutions/ conventions/ anti-patterns/` dirs via their `.gitkeep` files
    — **Why:** 156 internal dev-memory entries are not product for a shared collection; skeleton preserves the documented shape
    — **Done when:** `git ls-files LEARNINGS | grep -v '\.gitkeep$' | grep -v '_index.md$'` outputs nothing
    — **Consumers affected:** learnings autoinject plugin (degrades gracefully — empty manifest); future sessions write untracked
    — **Done:** 155 LEARNINGS content .md git-rm-ed; ls-files residue empty; files: LEARNINGS/**; fixes: none
- [x] **1.3** Append to `.gitignore`: `LEARNINGS/**/*.md` then `!LEARNINGS/_index.md`
    — **Why:** future locally-written learnings stay off the public repo while the index template stays tracked
    — **Done when:** `git check-ignore -q LEARNINGS/patterns/foo.md` exits 0 AND `git check-ignore -q LEARNINGS/_index.md` exits 1
    — **Consumers affected:** git tracking only
    — **Done:** .gitignore rules appended + verified (content ignored, _index tracked); files: .gitignore; fixes: none
- [x] **1.4** Commit Phase 1 (`chore(repo): remove research/ docs/; reduce LEARNINGS to skeleton + gitignore`)
    — **Why:** atomic revertable unit; deletions separate from content rework
    — **Done when:** `git log -1 --format=%s` shows the message; working tree clean
    — **Consumers affected:** none
    — **Done:** Phase 1 committed as 45f1082; files: PLANS/PLAN-536.md; fixes: none

### Phase 2: Rename sweep (opencode-config-template → civiltekk-opencode-claude-skills) + pointer fixes

- [x] **2.1** Replace every `opencode-config-template` occurrence in the 14 grep-derived live files: README.md, AGENTS.md, deploy/setup.sh, installer/build-site.mjs, installer/templates/api-quality/README.md, installer/templates/api-quality/api-quality-rules.mjs, installer/templates/api-quality/pre-commit-redocly, installer/templates/api-quality/redocly.yaml, opencode_app/Dockerfile (OCI `org.opencontainers.image.title` + `.source` labels), agents/opencode-tooling-subagent.md, skills/markitdown-mcp-skill/SKILL.md, skills/pptx-template-modifier-skill/SKILL.md, skills/worktree-pipeline-skill/SKILL.md, restart-opencode-docker.sh — CHANGELOG.md and PLANS/ stay untouched (history; GitHub redirects resolve)
    — **Why:** shipped-forward text must carry the new repo path; npx commands, Pages URL, and OCI source labels are functional strings
    — **Done when:** `grep -rn "opencode-config-template" --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=_archived .` in the worktree matches only CHANGELOG.md and PLANS/*
    — **Consumers affected:** npx remote installs, Pages catalog URL, setup.sh help text, image registries
    — **Done:** sed sweep over 14 files; live grep residue zero; files: 14 listed; fixes: none
- [x] **2.2** Fix the two stale `research/` pointers left by 1.1: `plugins/README.md` (drop `research/` from the historical-records policy list) and `plugins/opencode-learnings-autoinject.README.md` (dead `research/ponytail-load-fix.md` link → one-clause inline summary of the .ts-not-.mjs rationale, or a git-history pointer)
    — **Why:** living docs must not point at deleted paths; history pointers belong to the records, not to them
    — **Done when:** `grep -rn "research/" plugins/*.md plugins/*.README.md 2>/dev/null` empty in the worktree
    — **Consumers affected:** humans reading plugin docs
    — **Done:** plugins/README.md policy list minus research/; autoinject README dead link → inline .ts rationale + git pathspec pointer; fixes: reworded pointer to keep done-when grep clean
- [x] **2.3** Syntax-check touched executables: `bash -n deploy/setup.sh restart-opencode-docker.sh installer/templates/api-quality/pre-commit-redocly` and `node --check installer/build-site.mjs installer/templates/api-quality/api-quality-rules.mjs`
    — **Why:** sweep touches functional scripts; prove no breakage before content rework stacks on top
    — **Done when:** both commands exit 0
    — **Consumers affected:** opencode-setup bin, pages job, downstream pre-commit hook
    — **Done:** bash -n x3 + node --check x2 all green; fixes: none
- [x] **2.4** Commit Phase 2 (`chore(rebrand): sweep opencode-config-template → civiltekk-opencode-claude-skills (14 live files + 2 pointer fixes)`)
    — **Why:** mechanical rename isolated from editorial rework for reviewable diff
    — **Done when:** commit exists; tree clean
    — **Consumers affected:** none new
    — **Done:** Phase 2 committed as a98e4a8; fixes: none

### Phase 3: README rework

- [x] **3.1** Restructure README top matter: title "CivilTekk OpenCode & Claude Skills"; purpose-first intro (personal dev skills collection shared for single-skill use; OpenCode v2-native + multi-harness targets claude/agents/kimi/kilo); "Daily-driver commands" table for /create-ticket, /run-worktree-pipeline, /run-plan, /goal with note that slash commands ship with full deploys (single-skill installs get skills via natural-language triggers only); simplified install (three paths: one skill / full deploy / project preset + `--target` table + Docker one-liner); updated directory tree (no research/, no docs/, LEARNINGS as skeleton); Docker section declaring `opencode_app/` purpose (self-hosted browser endpoint of the whole setup); Support section linking `.github/ISSUE_TEMPLATE` bug/feature forms
    — **Why:** the agreed positioning — visitors see what this is and how to grab one skill in one command
    — **Done when:** all seven elements present in the rendered README top matter; no old title remains
    — **Consumers affected:** humans; `opencode_app/README.md` NOT edited (watch-clause: its skill-count literal stays valid untouched)
    — **Done:** README restructured: title/purpose/commands-table/install/tree/Docker/Support all present; opencode_app/README.md untouched (watch-clause held); fixes: none
- [x] **3.2** Collapse deep reference into `<details><summary>` blocks: setup flag tables, MCP servers + provider packs + skill profiles, model resolution/tiers, plugins (vibeguard/ponytail/auto-continue/question-repair/learnings), skill categories + agents tables, LSP, knowledge persistence, CodeGraph, testing recipes, portability
    — **Why:** keep one entry file without link sprawl; agreed alternative to docs/ (which Phase 1 deletes)
    — **Done when:** every deep section renders inside a collapsed details block; no content dropped (moved, not deleted — historical count narration may compress); `<details>` wrapping keeps text greppable so bats assertions keep matching
    — **Consumers affected:** humans; test_markitdown_skill + test_mcp_count_consistency (greps read markdown source — wrapping is safe, rephrasing is not)
    — **Done:** deep reference collapsed into 10 <details> blocks, content moved not deleted; greppable text preserved; fixes: none
- [x] **3.3** Repair accuracy defects: fix broken `PLAN.md` root link (→ `PLANS/`), re-derive counts (`ls skills/ | grep -v _archived | wc -l` = 146, `ls agents/*.md | wc -l` = 34), Pages URL `darellchua2.github.io/civiltekk-opencode-claude-skills`, replace count-history narration with current numbers. **Pinned phrasings (test-consumed — survive verbatim, counts derived at execution time):** "N skill director(y|ies)" where N = disk count; "Configuration (N)" where N = `installer/registry.json` Configuration-category length; "ships N MCP server entries" where N = `opencode_app/opencode.json` mcp.servers count. A deliberate rephrase updates the consuming bats assertion in the same commit.
    — **Why:** stale counts and dead links erode trust; the pinned literals are CI contracts
    — **Done when:** counts match disk; `grep -n "PLAN.md](PLAN.md" README.md` empty; Pages URL carries new name; `bats tests/test_markitdown_skill.bats tests/test_mcp_count_consistency.bats` green on the worktree
    — **Consumers affected:** humans; both bats files
    — **Done:** PLAN.md link fixed (issue #268 + PLANS/), counts 146/34, Pages URL new; pinned literals 146 skill directories / **Configuration** (2) / ships 8 MCP server entries verified + both bats green; fixes: none
- [x] **3.4** Commit Phase 3 (`docs(readme): rework for shared-collection positioning under CivilTekk OpenCode & Claude Skills`)
    — **Why:** editorial change isolated from mechanical sweep
    — **Done when:** commit exists; tree clean
    — **Consumers affected:** none new
    — **Done:** Phase 3 committed as 8511bee; fixes: none

### Phase 4: Verification (ticket exit gate — full tier)

- [ ] **4.1** Run gates: (a) grep gate from 2.1; (b) `bash -n deploy/setup.sh restart-opencode-docker.sh installer/templates/api-quality/pre-commit-redocly`; (c) `node --check installer/build-site.mjs installer/templates/api-quality/api-quality-rules.mjs installer/init.mjs`; (d) bats set covering swept + reworked surfaces: `tests/test_count_drift.bats tests/test_skill_isolation.bats tests/init.bats tests/test_markitdown_skill.bats tests/test_mcp_count_consistency.bats` (`bats` resolves on PATH)
    — **Why:** ticket AC requires mechanical proof; this is the complete set of guards that consume the touched files (README literals included)
    — **Done when:** all four green; failures fixed before push
    — **Consumers affected:** pipeline gate memo
- [ ] **4.2** Write the gate memo into this PLAN's trace block with `tier=full` and final SHA; tick all AC boxes
    — **Why:** Step 10 PR citation requires a green tier=full memo on the pushed SHA
    — **Done when:** memo line present; PLAN committed
    — **Consumers affected:** pr-workflow citation

## Technical Notes

- **Preserving local LEARNINGS memory on the maintainer machine:** the merge deletes tracked `LEARNINGS/**/*.md` from disk on the next `git pull` in the MAIN checkout. Before pulling the merge there, run `cp -r LEARNINGS /tmp/LEARNINGS-backup`, pull, then `cp -rn /tmp/LEARNINGS-backup/* LEARNINGS/` — restored files are untracked (gitignored) and the autoinject plugin keeps seeing them. Content also survives in git history.
- package.json bin names (`opencode-setup`, `opencode-init`, `opencode-skill`) stay generic — commands, not branding.
- `skills/_archived/` is the legacy exception — NOT counted in the 146 and NOT part of this rework (grep-gate exclusion, verified clean of old-name hits).
- Step 2.1 exclusion list for the grep gate: `.git/`, `node_modules/`, `skills/_archived/`, `CHANGELOG.md`, `PLANS/` (ticket comment documents this scope).
- Review-round learnings (2 evidence bumps + 1 new anti-pattern) are captured at pipeline Step 9 per the worktree-capture rule — deferred there because Phase 1 untracks LEARNINGS content.

## Dependencies

None — no blocked-by tickets. All hard pipeline deps satisfied (plan-execution-skill, code-review-subagent, pr-workflow-subagent).

## Risks & Mitigation

- **setup.sh sweep breaks deploy** — mitigated by `bash -n` + bats subset (init/parse_arguments/deploy_delegate source it).
- **README rework rephrases pinned literals** — mitigated by 3.3 pins with derived counts + both consuming bats in 4.1(d); deliberate rephrase = same-commit assertion update.
- **README details-collapse drops content** — mitigated by "moved, not deleted" rule in 3.2 and code-review pass in Step 9.
- **Losing maintainer LEARNINGS on merge** — mitigated by Technical Notes restore procedure; content in git history regardless.
- **Old external links (issues, forks, blog posts) break** — GitHub redirects renamed repos; acceptable residual.

## Trace

| Phase | Gate | Result | Notes |
|-------|------|--------|-------|
| 1 | light (done-when greps) | green | GATE 45f1082 tier=light lint=- typecheck=- build=- unit=- e2e=n.a |
| 2 | light (grep gate + bash -n + node --check) | green | GATE a98e4a8 tier=light lint=- typecheck=t(bash -n/node --check on touched) build=- unit=- e2e=n.a |
| 3 | light (pinned-literal bats + link/URL greps) | green | GATE 8511bee tier=light lint=- typecheck=- build=- unit=t(markitdown+mcp_count bats) e2e=n.a |
