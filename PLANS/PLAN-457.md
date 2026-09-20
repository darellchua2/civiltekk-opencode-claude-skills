# PLAN: Claude Code agents install target (~/.claude/agents/)

**Branch**: feat/457
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/457
**Base**: main

## Acceptance Criteria

- [ ] `--target claude` and `both` install agents to `~/.claude/agents/` with translated frontmatter; skills output unchanged
- [ ] Agents skipped no more: warning replaced by per-agent note listing dropped `permissions` rules
- [ ] Manifest per-target hashes cover the new claude-agents writes; `update`/`remove` handle them
- [ ] Transform unit tests; `--dry-run` previews; README / `--help` synced

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` (`TARGETS.claude` agentsDir + `claude-translate` mode, `claudeAgentContent`, skip-warning removal, help text) | #453/#454/#455 TARGETS layer (merged, `14246be`), shared `parsePermissionRules` | `package.json` bin (npx installs), `tests/claude_agents.bats` (new), `tests/init.bats` (`:186-201` #377 pins — deliberately flipped, see 1.3), `tests/agents_target.bats:85` die-pin (unaffected — derived), deploy scripts (default-target), README, root `AGENTS.md` | med |
| Claude Code agent frontmatter (additive `tools:` comma-separated allowlist) | opencode `permissions` array shape; shared `parsePermissionRules` | Claude Code loader (`tools` is an allowlist; unknown frontmatter keys ignored per #453 precedent) | low |
| `~/.claude/agents/` install surface | TARGETS.claude.agentsDir | Claude Code subagent discovery; `cmdRemove`/`cmdUpdate`/synthesis via existing TARGETS loops | low |

Cross-module consumers exist (tests, docs, deploy scripts) → architecture review selected. No frontend signal → no uiux review.

## Implementation Phases

### Phase 1: claude agents translation + wiring

- [x] **1.1** Give `TARGETS.claude` an `agentsDir: ~/.claude/agents` + `agentMode: "claude-translate"` (skills columns unchanged; no project columns — `--project --target claude` keeps its downgrade note); help SCOPE + `--target` prose mention claude agents (die message derives); sweep stale #377 comments (TARGETS row comment `:73`, dry-run warning site, manifest comment `:775-778`).
    — **Why:** the table is the resolution site; user-scope-only mirrors the ticket AC.
    — **Done when:** `add code-review-subagent --target claude --dry-run` exits 0 with `destinations.claude` = `~/.claude` (dirname of agentsDir — existing convention); legacy `destination` key for an agents-only claude selection reports `~/.claude` (explicit decision: agents-only selections report the agents parent, matching kimi/kilo behavior); `--project --target claude` still prints the downgrade note (existing pin); no stale "skills only"/"no agent files" comments remain.
    — **Consumers affected:** install/update/remove paths (1.3, Phase 2), docs (Phase 3).
    — **Done:** TARGETS.claude gained agentsDir (~/.claude/agents) + claude-translate; stale #377 comments swept (row comment, dry warning, manifest comment); dry-run destinations.claude = ~/.claude, legacy key = ~/.claude (explicit decision implemented); downgrade pin intact; files: installer/init.mjs; fixes: none
- [x] **1.2** Implement `claudeAgentContent(content, warn)` via the shared parser, **mirroring the kimi deny strategy** (architecture-review Gap 2 ruling): mappable `allow` rules with `resource: "*"` → additive `tools:` YAML list (`read→Read, write→Write, edit→Edit, bash→Bash, glob→Glob, grep→Grep, webfetch→WebFetch, websearch→WebSearch, task→Task` — the `task→Task` entry is corpus-inert today: all 23 agents with task rules use deny+narrow allows, so narrow allows drop + warn and `Task` must be ABSENT from emitted lists); `resource: "*"` deny rules → `disallowedTools:` list, deny wins on action conflicts; everything else (ask, `skill`/`question`, globbed/mcp resources) dropped + warned per agent (Claude Code permission enforcement lives in settings, not agent frontmatter); **synthesize `name: <stem>`** (Claude Code requires name+description; 0/34 corpus agents carry one) — guarded: pre-existing real `name:` → keep + no synthesis; column-0 insertion after opening `---`; guards: frontmatter-less/unterminated → verbatim + warn; pre-existing `tools:`/`disallowedTools:` keys → warn + skip translation. No `model:` injection ever.
    — **Why:** name+description are Claude Code's required agent fields (unknown-key tolerance covers extra keys, never missing required ones); the deny strategy mirrors kimi for cross-transform consistency (Claude frontmatter supports `disallowedTools:`).
    — **Done when:** transform verified on 3 real agents (code-review-subagent: `name: code-review-subagent` synthesized, Read in tools, `skill(...)`/`read(mcp:*)` dropped+warned, `Task` absent; opencode-tooling-subagent: narrow task allows dropped+warned, `Task` absent; zai-media-subagent: ask dropped + warned); body bytes unchanged; kimi/kilo suites green (shared parser untouched).
    — **Consumers affected:** install + update would-content (1.3), Claude users.
    — **Done:** claudeAgentContent implemented (kimi-mirror: tools/disallowedTools lists, deny-wins, name:<stem> synthesis with pre-existing-name guard, dropped-rule warns, column-0 insert, guards); verified: code-review-subagent → name synthesized, tools [Glob,Grep,Read,WebFetch,WebSearch], disallowed [Bash,Edit,Task] (task deny carried), skill()/read(mcp:*) dropped+warned; opencode-tooling narrow task allows dropped, Task absent from tools; zai-media ask dropped; body bytes unchanged; files: installer/init.mjs; fixes: none
- [x] **1.3** Wire `claude-translate` into the user-scope install loop, `cmdUpdate` would-content, and remove the now-obsolete claude skip-warning from both the dry-run preview (`claudeSkipWarning`) and the write loop; flip the #377 pins in `tests/init.bats:194-201` to assert the new behavior (agent installs to `~/.claude/agents/`, translated, no skip warning).
    — **Why:** #377's skills-only rationale was revisited and reversed by ticket #457 (Alternatives section); leaving the warning would contradict the install.
    — **Done when:** `add --target claude` writes `~/.claude/agents/<stem>.md` translated + `~/.claude/skills/` unchanged; `both` does the same; manifest records stems + `targets.claude` hashes; init.bats flipped pins green.
    — **Consumers affected:** claude-target users, CI.
    — **Done:** claude-translate wired (user loop + cmdUpdate + stem param); claudeSkipWarning removed from dry + write branches; #377 pins flipped in init.bats (agent installs translated, no skip warning); manifest records claude stems; both-target verified (skills path intact); files: installer/init.mjs, tests/init.bats; fixes: none

### Phase 2: lifecycle + regression

- [ ] **2.1** Verify (pin in 3.1's suite) the TARGETS-driven lifecycle for claude agent entries: `update` drift re-copies translated content + missing reports `(claude)`; `remove` wipes `~/.claude/agents/<stem>.md`; legacy synthesis synthesizes `targets.claude` for agent files; prune parity (project-scope none — claude is user-only).
    — **Why:** the table should carry a fourth mode for free; prove it rather than assume.
    — **Done when:** all behavioral checks green with no new code beyond 1.x. (Lifecycle pins live in 3.1's suite — the "2.3" reference in earlier drafts normalized to Phase 3.)
    — **Consumers affected:** claude-target users.
- [ ] **2.2** Regression sweep: skills output for claude/both identical to pre-change; opencode/agents/kimi/kilo targets fully identical (trees + manifests); opencode project preset dry-run byte-identical. The claude-target agent install is the feature — asserted by 1.3/2.1 pins, not the sweep.
    — **Why:** AC: skills output unchanged; no regression elsewhere.
    — **Done when:** sweeps identical (modulo `generatedAt`).
    — **Consumers affected:** existing users.

### Phase 3: tests + docs + gates

- [ ] **3.1** Add `tests/claude_target.bats` (HOME-isolated; family naming per arch review F5): synthesized `name:` assertion, translated `tools:` list, `disallowedTools:` deny-carry (mirrored kimi strategy), dropped-rules warning, `Task` absence on deny+narrow agents, no `model:` line, body-byte integrity, `both` target installs agents too, update idempotency + source-drift re-copy, remove wipe, dry-run preview, `--project --target claude` downgrade retained.
    — **Why:** ticket AC; the #377 flip needs its own net.
    — **Done when:** suite green; no writes outside isolated `$HOME`.
    — **Consumers affected:** CI.
- [ ] **3.2** Docs sync: README claude row (agents now install to `~/.claude/agents/` with `tools:` allowlist translation; deny/ask rules dropped — Claude Code permission model lives in settings), root `AGENTS.md` bullet, help text (1.1).
    — **Why:** repo documentation-sync rules.
    — **Done when:** claude docs describe agent translation; sweep consistent.
    — **Consumers affected:** users, docs readers.
- [ ] **3.3** Full gate: all bats suites + `node --test` + pack/drift; `GATE` memo line for the pushed SHA.
    — **Why:** pipeline gate contract.
    — **Done when:** every suite green; memo emitted.
    — **Consumers affected:** code review, PR creation.

## Technical Notes

- **#377 reversal is the point of this ticket** (its Alternatives section): the original skills-only decision predates the transform machinery; `kimi`/`kilo` proved cross-loader agent translation cheap. `tests/init.bats:194-201` pins are flipped deliberately (1.3), not silently.
- **`tools:`/`disallowedTools:` are YAML lists** (mirroring the kimi transform; Claude Code accepts both list and comma forms — the list form keeps the two transforms structurally identical). Deny-carry mirrors kimi deny-wins; unknown frontmatter keys (incl. `permissions`, `mode`, `steps`) stay verbatim — Claude Code ignores them (same precedent as #453's claude skills work).
- **`name:` synthesis** — Claude Code requires name+description in agent frontmatter; corpus agents carry neither a `name:` (0/34) — synthesized from the stem, guarded against pre-existing names. The description (also required) exists in 34/34 corpus agents.
- **Deliberately out of scope:** project-scope claude agents (`.claude/agents/` in-repo — user-scope only per ticket AC); model pinning; `settings.json` permission synthesis.

## Dependencies

- Builds on #453/#454/#455 (merged). No blocked-by.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| #377 pin flip hides a skills regression | 2.2 sweeps skills output separately from agent behavior; skills path untouched by 1.x |
| Deny-rule loss surprises users | Per-agent dropped-rules warning (1.2) + README note that Claude permission enforcement lives in settings |
| Comma-form vs array-form `tools:` | Resolved: YAML list form, mirroring kimi (Claude Code accepts both); 3.1 asserts the emitted form |
| `name:` synthesis collides with a future corpus `name:` | Guarded skip+warn on pre-existing real name (1.2); corpus census 0/34 |

## Gate Trace

_Plan review round 1 (architecture-review-subagent): approved-with-notes; 2 required amendments applied — F1 `name: <stem>` synthesis added (Claude Code requires name+description; corpus census 0/34 carry name) with pre-existing-name guard + 3.1 assertion; F2 task→Task done-when reworded (corpus-inert: all task rules are deny+narrow-allow, Task must be ABSENT). Gap rulings adopted: F3 deny strategy mirrors kimi (disallowedTools + deny-wins; Technical Note corrected), F4 destinations.claude = ~/.claude + legacy-key decision documented, F5 suite renamed claude_target.bats, F6 stale-comment sweep added to 1.1/1.3. Stale-comment sites: init.mjs :73 row comment, :710, :775-778 manifest comment._
