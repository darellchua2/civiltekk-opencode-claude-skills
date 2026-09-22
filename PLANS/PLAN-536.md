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
| `research/`, `docs/` | — | none (grep-verified: zero refs in tests/live files) | low |
| `LEARNINGS/` content | — | learnings autoinject plugin (runtime dir scan, not git); no bats test depends on the dir | low |
| `.gitignore` | LEARNINGS skeleton (Phase 1 order) | git tracking only | low |
| `deploy/setup.sh` (name refs in help/comments) | — | bats: parse_arguments, init, deploy_delegate, test_count_drift (source it / grep its banner); opencode-setup bin | med — functional script; verify `bash -n` + bats subset |
| `installer/build-site.mjs` (repo-name/URL refs) | — | release.yml pages job (functional URL output) | med — `node --check` |
| `installer/templates/api-quality/{README.md,api-quality-rules.mjs}` | — | installed into downstream repos | low |
| `agents/opencode-tooling-subagent.md`, 3 SKILL.md files (name refs) | — | per-skill npx installs (doc text only) | low |
| `restart-opencode-docker.sh` (comment) | — | maintainer redeploy flow | low |
| `AGENTS.md` (Repository Purpose npx refs) | rename sweep (Phase 2) | repo agents/contributors | low |
| `README.md` | rename sweep FIRST (single edit pass over renamed text) | humans; no bats test greps README name/count literals (verified: test_count_drift targets setup.sh/ps1 only) | low |

## Implementation Phases

### Phase 1: Cleanup & LEARNINGS skeleton

- [ ] **1.1** `git rm -r research/ docs/` in the worktree
    — **Why:** unreferenced internal artifacts shipped as if product (grep-verified zero live references)
    — **Done when:** `test ! -d research && test ! -d docs` in the worktree; deletions staged
    — **Consumers affected:** none
- [ ] **1.2** Reduce `LEARNINGS/` to skeleton: `git rm` all `LEARNINGS/**/*.md` EXCEPT `_index.md`; keep `patterns/ decisions/ solutions/ conventions/ anti-patterns/` dirs via their `.gitkeep` files
    — **Why:** 156 internal dev-memory entries are not product for a shared collection; skeleton preserves the documented shape
    — **Done when:** `git ls-files LEARNINGS | grep -v '\.gitkeep$' | grep -v '_index.md$'` outputs nothing
    — **Consumers affected:** learnings autoinject plugin (degrades gracefully — empty manifest); future sessions write untracked
- [ ] **1.3** Append to `.gitignore`: `LEARNINGS/**/*.md` then `!LEARNINGS/_index.md`
    — **Why:** future locally-written learnings stay off the public repo while the index template stays tracked
    — **Done when:** `git check-ignore -q LEARNINGS/patterns/foo.md` exits 0 AND `git check-ignore -q LEARNINGS/_index.md` exits 1
    — **Consumers affected:** git tracking only
- [ ] **1.4** Commit Phase 1 (`chore(repo): remove research/ docs/; reduce LEARNINGS to skeleton + gitignore`)
    — **Why:** atomic revertable unit; deletions separate from content rework
    — **Done when:** `git log -1 --format=%s` shows the message; working tree clean
    — **Consumers affected:** none

### Phase 2: Rename sweep (opencode-config-template → civiltekk-opencode-claude-skills)

- [ ] **2.1** Replace every `opencode-config-template` occurrence in the 12 live files: README.md, AGENTS.md, deploy/setup.sh, installer/build-site.mjs, installer/templates/api-quality/README.md, installer/templates/api-quality/api-quality-rules.mjs, agents/opencode-tooling-subagent.md, skills/markitdown-mcp-skill/SKILL.md, skills/pptx-template-modifier-skill/SKILL.md, skills/worktree-pipeline-skill/SKILL.md, restart-opencode-docker.sh — CHANGELOG.md and PLANS/ stay untouched (history; GitHub redirects resolve)
    — **Why:** shipped-forward text must carry the new repo path; npx commands and Pages URL are functional strings
    — **Done when:** `grep -rn "opencode-config-template" --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=_archived .` in the worktree matches only CHANGELOG.md and PLANS/*
    — **Consumers affected:** npx remote installs, Pages catalog URL, setup.sh help text
- [ ] **2.2** Syntax-check touched executables: `bash -n deploy/setup.sh restart-opencode-docker.sh` and `node --check installer/build-site.mjs installer/templates/api-quality/api-quality-rules.mjs`
    — **Why:** sweep touches functional scripts; prove no breakage before content rework stacks on top
    — **Done when:** both commands exit 0
    — **Consumers affected:** opencode-setup bin, pages job
- [ ] **2.3** Commit Phase 2 (`chore(rebrand): sweep opencode-config-template → civiltekk-opencode-claude-skills (12 live files)`)
    — **Why:** mechanical rename isolated from editorial rework for reviewable diff
    — **Done when:** commit exists; tree clean
    — **Consumers affected:** none new

### Phase 3: README rework

- [ ] **3.1** Restructure README top matter: title "CivilTekk OpenCode & Claude Skills"; purpose-first intro (personal dev skills collection shared for single-skill use; OpenCode v2-native + multi-harness targets claude/agents/kimi/kilo); "Daily-driver commands" table for /create-ticket, /run-worktree-pipeline, /run-plan, /goal with note that slash commands ship with full deploys (single-skill installs get skills via natural-language triggers only); simplified install (three paths: one skill / full deploy / project preset + `--target` table + Docker one-liner); updated directory tree (no research/, no docs/, LEARNINGS as skeleton); Docker section declaring `opencode_app/` purpose (self-hosted browser endpoint of the whole setup); Support section linking `.github/ISSUE_TEMPLATE` bug/feature forms
    — **Why:** the agreed positioning — visitors see what this is and how to grab one skill in one command
    — **Done when:** all seven elements present in the rendered README top matter; no old title remains
    — **Consumers affected:** humans (first impression); nothing mechanical
- [ ] **3.2** Collapse deep reference into `<details><summary>` blocks: setup flag tables, MCP servers + provider packs + skill profiles, model resolution/tiers, plugins (vibeguard/ponytail/auto-continue/question-repair/learnings), skill categories + agents tables, LSP, knowledge persistence, CodeGraph, testing recipes, portability
    — **Why:** keep one entry file without link sprawl; agreed alternative to docs/ (which Phase 1 deletes)
    — **Done when:** every deep section renders inside a collapsed details block; no content dropped (moved, not deleted — historical count narration may compress)
    — **Consumers affected:** humans
- [ ] **3.3** Repair accuracy defects: fix broken `PLAN.md` root link (→ `PLANS/`), re-derive counts (`ls skills/ | grep -v _archived | wc -l` = 146, `ls agents/*.md | wc -l` = 34), Pages URL `darellchua2.github.io/civiltekk-opencode-claude-skills`, replace count-history narration with current numbers
    — **Why:** stale counts and dead links erode trust in a shared repo
    — **Done when:** counts match disk; `grep -n "PLAN.md](PLAN.md" README.md` empty; Pages URL carries new name
    — **Consumers affected:** humans
- [ ] **3.4** Commit Phase 3 (`docs(readme): rework for shared-collection positioning under CivilTekk OpenCode & Claude Skills`)
    — **Why:** editorial change isolated from mechanical sweep
    — **Done when:** commit exists; tree clean
    — **Consumers affected:** none new

### Phase 4: Verification (ticket exit gate — full tier)

- [ ] **4.1** Run gates: (a) grep gate from 2.1; (b) `bash -n deploy/setup.sh restart-opencode-docker.sh`; (c) `node --check installer/build-site.mjs installer/templates/api-quality/api-quality-rules.mjs installer/init.mjs`; (d) bats subset covering swept surfaces: `tests/test_count_drift.bats tests/test_skill_isolation.bats tests/init.bats` (bats at `tests/lib/bats-core/bin/bats`)
    — **Why:** ticket AC requires mechanical proof; these are the guards that consume the touched files
    — **Done when:** all four green; failures fixed before push
    — **Consumers affected:** pipeline gate memo
- [ ] **4.2** Write the gate memo into this PLAN's trace block with `tier=full` and final SHA; tick all AC boxes
    — **Why:** Step 10 PR citation requires a green tier=full memo on the pushed SHA
    — **Done when:** memo line present; PLAN committed
    — **Consumers affected:** pr-workflow citation

## Technical Notes

- **Preserving local LEARNINGS memory on the maintainer machine:** the merge deletes tracked `LEARNINGS/**/*.md` from disk on the next `git pull` in the MAIN checkout. Before pulling the merge there, run `cp -r LEARNINGS /tmp/LEARNINGS-backup`, pull, then `cp -rn /tmp/LEARNINGS-backup/* LEARNINGS/` — restored files are untracked (gitignored) and the autoinject plugin keeps seeing them. Content also survives in git history.
- package.json bin names (`opencode-setup`, `opencode-init`, `opencode-skill`) stay generic — commands, not branding.
- `skills/_archived/` is the legacy exception — NOT counted in the 146 and NOT part of this rework.
- Step 2.1 exclusion list for the grep gate: `.git/`, `node_modules/`, `skills/_archived/` (if it contains old-name prose it is history, like PLANS/), `CHANGELOG.md`, `PLANS/`.

## Dependencies

None — no blocked-by tickets. All hard pipeline deps satisfied (plan-execution-skill, code-review-subagent, pr-workflow-subagent).

## Risks & Mitigation

- **setup.sh sweep breaks deploy** — mitigated by `bash -n` + bats subset (init/parse_arguments/deploy_delegate source it).
- **README rework drops content during details-collapse** — mitigated by "moved, not deleted" rule in 3.2 and code-review pass in Step 9.
- **Losing maintainer LEARNINGS on merge** — mitigated by Technical Notes restore procedure; content in git history regardless.
- **Old external links (issues, forks, blog posts) break** — GitHub redirects renamed repos; acceptable residual.

## Trace

| Phase | Gate | Result | Notes |
|-------|------|--------|-------|
| — | — | — | executor appends per-phase rows; final `tier=full` memo line required |
