# Drift-audit route (values)

Audit and auto-fix contract for documentation drift across PLAN, README, AGENTS.md, and deploy scripts. The host SKILL.md carries the METHOD (detect → route → load); this file carries the VALUES for the `drift-audit` route.

**Authority:** this route is the authority for validation levels, the four audit categories, auto-fix rules, and the output format; `references/sync-on-add.md` in this skill owns the on-add update procedure (the two were formerly peer skills — the boundary is internal now).

All shell snippets require bash (git-bash/WSL on Windows).

## When to use

After adding/removing skills or agents; before PR; after bulk changes; during plan execution (targeted mode).

## Validation levels

| Level | Checks | Use case |
|-------|--------|----------|
| `quick` | count sync only | pre-commit |
| `standard` | counts + PLAN drift + orphans | after a session |
| `thorough` | all categories | pre-PR, bulk changes |
| `targeted` | one PLAN file, all categories | during execution |

## Category 1 — Cross-file count sync

Actual: `ls -d skills/*/ | grep -v scripts | wc -l` (agents: `ls agents/*.md | wc -l`). Must match every reference:

| File | Pattern |
|------|---------|
| `deploy/setup.sh` / `deploy/setup.ps1` | `SKILLS (` total + per-category counts |
| `README.md` | `<N> skills`, Skill Categories table |
| `AGENTS.md` | `<N> skill` refs, directory-tree comments |

**Auto-fix:** count on disk → grep each file's patterns → `edit` mismatches to actual → per-category counts must sum to total.

## Category 2 — PLAN vs reality drift

Per PLAN file: stale checkboxes (done work `[ ]` / undone `[x]`) · Scope-section files vs `git diff --name-only <base>` on the branch · acceptance criteria vs implementation · completed phases fully `[x]` · PLAN branch header vs `git branch --show-current`. Commands: `grep -n "\- \[ \]" <PLAN>` vs actual state; scope vs `git diff --name-only`.

## Category 3 — Orphan references

Skill/agent names referenced in docs/scripts that no longer exist on disk (and vice versa: shipped-but-undocumented skills). `grep -rn '<name>' README.md AGENTS.md deploy/` after any rename/removal; broken §-anchor pointers in the AGENTS.md chain must resolve in their target skill. Deletions update ALL referencing files in the same commit.

## Category 4 — Claim verification (thorough)

Actionable claims (commands, paths, counts) spot-checked against reality — e.g. a documented MCP server actually configured, a documented count matches disk. Fix doc or flag code (never silently "fix" code to match a stale doc).

## Output format

Per category: checked / passed / fixed / failed, with file:line for each finding; auto-fixes applied only where mechanical (counts, checkboxes); judgment calls (scope mismatches) reported, not auto-fixed.

## Handoffs

- `plan-execution-skill` (`--update`) — owns PLAN checkbox commits during plan execution; this audit reports drift only.
- `references/sync-on-add.md` (this skill's `sync-on-add` route) — the per-file update procedure once drift is identified.
