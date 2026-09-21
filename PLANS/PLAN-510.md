# PLAN: Add portability contract to repo conventions

**Branch**: feat/510
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/510
**Base**: main

## Acceptance Criteria
- [ ] Contract section documents the binding-block format and metadata vocabulary
- [ ] opencode-skill-creation-skill checklist includes the portability check
- [ ] No runtime behavior change (docs/conventions only)

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `AGENTS.md` §Skill / Agent Frontmatter Contract | — | skill authors; `opencode-skill-creation-skill` (mirrors it); tickets #512–#515 consume the vocabulary | low |
| `skills/opencode-skill-creation-skill/SKILL.md` | AGENTS.md contract (must mirror, same vocabulary) | skill authors; `opencode-skills-maintainer-skill` audits against it | low |
| `registry.json` (untouched, verified) | no frontmatter value changes in this ticket | installer, setup.sh counts | none |
| `installer/build-registry.mjs` (not edited here) | parses SKILL.md frontmatter | sole extraction point for `os`/`harness` into `registry.json`; #514 extends it — init.mjs consumes registry.json only | info |

## Implementation Phases

### Phase 1: Define the portability vocabulary (AGENTS.md, then mirror)

- [x] **1.1** In `AGENTS.md` §Skill / Agent Frontmatter Contract, extend the `metadata` row to `House sub-keys: protocol, pattern, os, harness` and append a `### Portability contract` subsection defining (a) the capability-binding block format — capability sentence, then per-harness rows (OpenCode, Claude Code), then a portable-fallback row; (b) `metadata.os: [linux, macos, windows]` and `metadata.harness: opencode` as installer-only, zero-runtime-effect vocabulary; (c) the bash rule — every bash snippet carries `Requires bash (git-bash/WSL on Windows)` or becomes a `node -e` one-liner.
    — **Why:** tickets #512–#515 apply this vocabulary mechanically; defining it first prevents format re-litigation mid-pipeline.
    — **Done when:** `rg -n '### Portability contract' AGENTS.md` matches and the `metadata` row lists all four sub-keys.
    — **Consumers affected:** `opencode-skill-creation-skill` (must mirror — 1.2), all future skill authors.
    — **Done:** metadata row extended to four sub-keys; `### Portability contract` appended with binding-block format + os/harness vocabulary + bash rule; files: AGENTS.md; fixes: none
- [x] **1.2** Mirror the vocabulary in `skills/opencode-skill-creation-skill/SKILL.md`: update the `metadata:` frontmatter-template comment (line ~36) to the same four sub-keys and add a `## Portability` section with the condensed binding-block skeleton + bash rule.
    — **Why:** this skill is the author-facing checklist; a single-surface delta is exactly the drift the vocabulary exists to prevent.
    — **Done when:** `rg -l 'protocol.*pattern.*os.*harness' AGENTS.md skills/opencode-skill-creation-skill/SKILL.md` returns both files (shape-insensitive — the AGENTS.md row backticks each token) and the SKILL.md contains the binding-block skeleton.
    — **Consumers affected:** skill authors; `opencode-skills-maintainer-skill` audits.
    — **Done:** frontmatter comment + new `## Portability` section mirror the contract; verified with the shape-insensitive grep — both files match; files: skills/opencode-skill-creation-skill/SKILL.md; fixes: none

### Phase 2: Verify no runtime/registry drift

- [x] **2.1** Run `node installer/build-registry.mjs`; confirm exit 0 and `git status --porcelain registry.json` empty (vocabulary is prose — no frontmatter values changed in this ticket, so the registry must not move).
    — **Why:** repo rule rebuilds the registry after any frontmatter change; here it doubles as proof that a docs-only ticket caused zero registry drift.
    — **Done when:** build-registry exits 0 with an unchanged `registry.json`.
    — **Consumers affected:** installer, setup.sh counts.
    — **Done:** build-registry exit 0, registry.json unchanged; full bats suite 529/529; files: none (verification-only step); fixes: none

## Gate Trace

GATE 7787015 tier=light lint=t typecheck=n.a build=- unit=t e2e=n.a
GATE b69a349 tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a
Note: final commit aeb80c6 (and any later PLAN-trace-only commits) differ from b69a349 by the PLAN file alone; the full gate ran on the b69a349 tree content. CI is the unconditional re-run.

## Technical Notes
- Binding-block canonical shape (from zai-video-skill:90 prior art):
  ```markdown
  <capability sentence>.
  - OpenCode: <mechanism>
  - Claude Code: <mechanism>
  - Other/none: <portable fallback>
  ```
- `metadata` remains an opaque string map — `os`/`harness` are list-shaped strings (`[linux, macos]`), read only by installer/init.mjs warnings (#514).
  > Correction (2026-09-21, Mode R relay): values are **double-quoted comma-separated strings** — `os: "linux, macos"`, `harness: "opencode"`, never brackets (runtime schema is a string-to-string map; the registry parser yields literal bracket text for flow sequences). AGENTS.md §Portability contract is the source of truth; #514 extracts via build-registry.mjs.
- Keep the AGENTS.md subsection ≤ ~30 lines; the skill version is the condensed author checklist, not a duplicate of the contract prose.

## Dependencies
- None (first ticket in the sequence; #512/#513 depend on this one).

## Risks & Mitigation
- *Vocabulary drift between the two files* → 1.2 immediately after 1.1, verified by a two-file grep in the same gate.
- *Registry accidentally regenerated* → 2.1 asserts `registry.json` is byte-identical.
GATE 2410722 tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a
Note: review-fix re-gate (contract Step 9) — post-review fixes (vocabulary spelling pin, done-when grep shape, consumer-map producer row, fallback wording, overclaim soften) + LEARNINGS capture; tree-equivalent PLAN-only commits may follow.
