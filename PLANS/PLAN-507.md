# PLAN: Migrate v1 PTY docs to v2 background shell, drop v1 SDK pin

**Branch**: feat/507
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/507
**Base**: main

## Acceptance Criteria
- [ ] `grep -rE 'pty_spawn|pty_read|pty_write|pty_kill|notifyOnExit' skills/ agents/` returns zero hits (the prose-only doctrine line in `agents/opencode-v2-migration-subagent.md:193` names no `pty_*` tool and is unaffected)
- [ ] zai-video-skill §2 uses `background: true` + completion notification; foreground noted as blocking fallback
- [ ] responsive-audit skill/subagent use the background runner or explicit-`timeout` foreground; 6-assertion methodology unchanged
- [ ] `README.md` no longer says "PTY watch loop" / "PTY poll"
- [ ] `.opencode` v1 SDK files/dirs deleted locally (untracked); no `@opencode-ai/plugin` imports in `scripts/`/`tests/`; evidence in ticket comments
- [ ] Test suite green before and after (baseline: 529/529 ok at origin/main 9bd649b5)
- [ ] No frontmatter changes → `registry.json` untouched (no `build-registry.mjs` run)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/zai-video-skill/SKILL.md` | — | `agents/zai-media-subagent.md` rule 3 + routing table (prose alignment); agents executing video tasks | low |
| `agents/zai-media-subagent.md` | 1.1 (skill defines the pattern the agent references) | Primary sessions routing media work | low |
| `skills/playwright-responsive-audit-skill/SKILL.md` | — | `agents/responsive-audit-subagent.md` (mirrors its strategy); responsive-audit pipeline | low |
| `agents/responsive-audit-subagent.md` | 2.1 (skill's execution strategy is its source of truth) | Primary sessions spawning the auditor | low |
| `README.md` | 1.1, 2.1 (category table advertises the patterns) | Humans reading repo docs; skill/agent counts must not change | low |
| `.opencode/package.json` + lock + `node_modules/` (untracked, main checkout only) | — | None — zero `@opencode-ai/plugin` imports in `scripts/`/`tests/` | low |

All nodes are documentation leaves; no cross-module code consumers → architecture review not selected (Step 7 triage). No frontend signal → uiux review not selected.

## Implementation Phases

### Phase 1: Video/media docs → background shell
- [ ] **1.1** Rewrite `skills/zai-video-skill/SKILL.md` PTY references (intro line ~L25, §2 heading + body ~L70-89) to the v2 background-shell pattern: same poll-loop script run with `background: true`; the automatic completion notification replaces `notifyOnExit: true`; the foreground loop becomes the non-OpenCode fallback, noted as blocking the session.
    — **Why:** This skill is the canonical async pattern the media subagent's routing and rules reference; every other doc change aligns to it.
    — **Done when:** `grep -nE 'pty_spawn|pty_read|pty_write|pty_kill|notifyOnExit|PTY' skills/zai-video-skill/SKILL.md` returns zero hits and the §2 body instructs `background: true` + completion notification.
    — **Consumers affected:** `agents/zai-media-subagent.md` (updated in 1.2), README Media Generation row (updated in 2.3).
- [ ] **1.2** Rewrite `agents/zai-media-subagent.md` lines 75 and 87: routing table cell "submit → PTY poll" → "submit → background-shell poll"; rule 3 references the skill's background-shell pattern (`shell` `background: true`, completion notification) while keeping the never-poll-synchronously discipline.
    — **Why:** The executable prompt must not name tools absent from v2; it must match the pattern its delegated skill now teaches (1.1).
    — **Done when:** `grep -nE 'pty_|PTY' agents/zai-media-subagent.md` returns zero hits; rule 3 still forbids synchronous polling.
    — **Consumers affected:** Primary sessions delegating video generation.

### Phase 2: Responsive-audit docs + README
- [ ] **2.1** Rewrite `skills/playwright-responsive-audit-skill/SKILL.md` "PTY execution" section (~L30-34): one long-running runner via `background: true` when a watch mode is used (`--ui` if `$DISPLAY`/`xvfb-run` available), else per-iteration foreground `npx playwright test` with an explicit `timeout`; early-abort via sentinel file or process kill instead of `pty_write "\x03"`.
    — **Why:** Upstream source of the subagent's execution model; defines the pattern 2.2 aligns to.
    — **Done when:** `grep -nE 'pty_spawn|pty_read|pty_write|pty_kill|notifyOnExit' skills/playwright-responsive-audit-skill/SKILL.md` returns zero hits; background/timeout instructions present; the six-assertion methodology text untouched.
    — **Consumers affected:** `agents/responsive-audit-subagent.md` (updated in 2.2).
- [ ] **2.2** Rewrite `agents/responsive-audit-subagent.md` "PTY Execution Model" section (L76-128) as the background execution model: Strategy A = background watch runner driven by completion notifications; Strategy B (persistent warm shell via `pty_write`) has no v2 port → per-iteration foreground runs with explicit `timeout`; update the referencing lines (~100, ~120, ~128); keep the 6-assertion methodology, 3-tier fix ladder, and batch-bash fallback unchanged.
    — **Why:** The subagent's prompt is executed verbatim by the model; naming nonexistent `pty_*` tools breaks DETECT/RE-VERIFY on stock v2.
    — **Done when:** `grep -nE 'pty_spawn|pty_read|pty_write|pty_kill|pty_' agents/responsive-audit-subagent.md` returns zero hits; methodology sections (assertions, tiers) verbatim vs pre-edit.
    — **Consumers affected:** Primary sessions spawning responsive audits; uiux-reviewer handoffs unchanged.
- [ ] **2.3** Update `README.md` category-table wording: line ~638 "persistent PTY watch loop" → background watch runner phrasing; line ~640 "async submit + PTY poll" → "async submit + background poll". Row and skill counts unchanged.
    — **Why:** The table advertises capabilities; it must not describe removed tooling (docs-consistency rule).
    — **Done when:** `grep -n 'PTY' README.md` returns zero hits; table row count and skill counts identical to pre-edit.
    — **Consumers affected:** Repository readers; installer counts untouched.

### Phase 3: Local v1 SDK hygiene (no repo diff)
- [ ] **3.1** In the MAIN checkout (`/home/silentx/VSCODE/opencode-config-template`, not the worktree — the files are untracked and absent from fresh checkouts): confirm `grep -rn '@opencode-ai/plugin' scripts/ tests/` returns zero hits, delete `.opencode/package.json`, `.opencode/package-lock.json`, `.opencode/node_modules/`, re-run `bats tests/` and confirm green, then post the evidence (grep result + suite tail + deletion listing) as a comment on issue #507.
    — **Why:** Closes AC item 5; the v1 pin is machine-local state, so verification must run where the files live and the evidence must be durable in the ticket.
    — **Done when:** Files gone (`ls .opencode/package.json` errors), grep clean, suite green, evidence comment visible on #507.
    — **Consumers affected:** None — zero imports anywhere in tracked code (historical v1 mentions in `research/ponytail-load-fix.md` are protected records, never rewritten).

### Phase 4: Verification gate
- [ ] **4.1** Run the full verification gate in the worktree: `bats tests/` (tier=full, ticket exit gate) plus every AC grep check from this PLAN's Acceptance Criteria section, recording the gate memo.
    — **Why:** Pipeline ticket-exit gate is full tier; the memo line is the citation Step 10's PR must carry.
    — **Done when:** `GATE <short-sha> tier=full` memo line exists for the final tree, all AC greps pass, and `git status --porcelain` shows no `registry.json` or frontmatter changes.
    — **Consumers affected:** Step 9 code review (diff scope) and Step 10 pr-workflow citation.

## Technical Notes
- v2 mapping used everywhere: `pty_spawn` + `notifyOnExit: true` → `shell` with `background: true` (returns immediately, notifies the session when the command exits); bounded runs → explicit `timeout` (ms); early-abort → sentinel file the background loop checks, or killing the process (no `\x03` write path).
- Strategy B (persistent warm shell accepting writes) has no v2 equivalent — v2 shell calls are independent processes. Per-iteration foreground with explicit timeout is the replacement, matching the already-documented batch-bash fallback.
- `agents/opencode-v2-migration-subagent.md:193` ("PTY/background plugins → v2 background") is migration doctrine prose, not tool usage — deliberately unchanged.
- Historical v1 references in `research/ponytail-load-fix.md` stay: repo rule — `LEARNINGS/`, `PLANS/`, `research/` records are never rewritten.
- `.opencode/` is untracked: the SDK-pin deletion cannot appear in the PR diff; it is verified locally and evidenced on the ticket (Phase 3).

## Dependencies
None — single ticket, no `blocked-by:` refs.

## Risks & Mitigation
- **Line-number drift** between ticket references and worktree content → edits target content via unique anchors, not bare line numbers.
- **`tests/test_skill_isolation.bats` guards** (isolation, vendored-copy byte-identity) → only SKILL.md prose and agents/*.md bodies change; no scripts, no vendored trees, no new dirs.
- **README count drift** → wording-only edits inside existing table cells; counts re-checked against pre-edit values.
- **Suite flakiness masking a regression** → baseline (529/529 at 9bd649b5) recorded before any edit; after each phase the same suite re-run must match.
