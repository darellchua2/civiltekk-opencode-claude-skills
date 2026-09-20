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

- [ ] **1.1** Give `TARGETS.claude` an `agentsDir: ~/.claude/agents` + `agentMode: "claude-translate"` (skills columns unchanged; no project columns — `--project --target claude` keeps its downgrade note); help SCOPE + `--target` prose mention claude agents (die message derives).
    — **Why:** the table is the resolution site; user-scope-only mirrors the ticket AC.
    — **Done when:** `add code-review-subagent --target claude --dry-run` exits 0 listing `~/.claude/agents` among destinations; `--project --target claude` still prints the downgrade note (existing pin).
    — **Consumers affected:** install/update/remove paths (1.3, Phase 2), docs (Phase 3).
- [ ] **1.2** Implement `claudeAgentContent(content, warn)` via the shared parser: mappable `allow` rules with `resource: "*"` become a `tools:` comma-separated allowlist (`read→Read, write→Write, edit→Edit, bash→Bash, glob→Glob, grep→Grep, webfetch→WebFetch, websearch→WebSearch, task→Task` — Claude Code registry names); everything else (deny, ask, `skill`/`question`, globbed/mcp resources) is dropped + warned per agent (Claude Code permission enforcement lives in settings, not agent frontmatter — a deny cannot be carried, so nothing deny-ish is emitted); column-0 insertion after opening `---`; guards: frontmatter-less/unterminated → verbatim + warn; pre-existing `tools:` key → warn + skip. No `model:` injection ever (claude agents unpinned, epic decision).
    — **Why:** the issue's design — Claude gets an allowlist; deny semantics have no frontmatter home and must not silently masquerade.
    — **Done when:** transform verified on 3 real agents (code-review-subagent: Read present, `skill(...)`/`read(mcp:*)` dropped; opencode-tooling-subagent: `task→Task` mapped; zai-media-subagent: ask dropped + warned); body bytes unchanged; kimi/kilo suites green (shared parser untouched).
    — **Consumers affected:** install + update would-content (1.3), Claude users.
- [ ] **1.3** Wire `claude-translate` into the user-scope install loop, `cmdUpdate` would-content, and remove the now-obsolete claude skip-warning from both the dry-run preview (`claudeSkipWarning`) and the write loop; flip the #377 pins in `tests/init.bats:194-201` to assert the new behavior (agent installs to `~/.claude/agents/`, translated, no skip warning).
    — **Why:** #377's skills-only rationale was revisited and reversed by ticket #457 (Alternatives section); leaving the warning would contradict the install.
    — **Done when:** `add --target claude` writes `~/.claude/agents/<stem>.md` translated + `~/.claude/skills/` unchanged; `both` does the same; manifest records stems + `targets.claude` hashes; init.bats flipped pins green.
    — **Consumers affected:** claude-target users, CI.

### Phase 2: lifecycle + regression

- [ ] **2.1** Verify (pin in 2.3's suite) the TARGETS-driven lifecycle for claude agent entries: `update` drift re-copies translated content + missing reports `(claude)`; `remove` wipes `~/.claude/agents/<stem>.md`; legacy synthesis synthesizes `targets.claude` for agent files; prune parity (project-scope none — claude is user-only).
    — **Why:** the table should carry a fourth mode for free; prove it rather than assume.
    — **Done when:** all behavioral checks green with no new code beyond 1.x.
    — **Consumers affected:** claude-target users.
- [ ] **2.2** Regression sweep: skills output for claude/both identical to pre-change; opencode/agents/kimi/kilo targets fully identical (trees + manifests); opencode project preset dry-run byte-identical. The claude-target agent install is the feature — asserted by 1.3/2.1 pins, not the sweep.
    — **Why:** AC: skills output unchanged; no regression elsewhere.
    — **Done when:** sweeps identical (modulo `generatedAt`).
    — **Consumers affected:** existing users.

### Phase 3: tests + docs + gates

- [ ] **3.1** Add `tests/claude_agents.bats` (HOME-isolated): translated `tools:` allowlist (comma form), dropped-rules warning, no `model:` line, body-byte integrity, `both` target installs agents too, update idempotency + source-drift re-copy, remove wipe, dry-run preview, `--project --target claude` downgrade retained.
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
- **Tools allowlist is comma-separated** (Claude Code's canonical agent-file form); unknown frontmatter keys (incl. `permissions`, `mode`, `steps`) stay verbatim — Claude Code ignores them (same precedent as #453's claude skills work: "other unknown frontmatter fields are safely ignored").
- **Deny/ask rules cannot be carried** — Claude Code's permission model lives in `settings.json`, not agent frontmatter; dropping them is fail-open at the agent-file level, which is why every drop is named in a per-agent warning.
- **Deliberately out of scope:** project-scope claude agents (`.claude/agents/` in-repo — user-scope only per ticket AC); model pinning; `settings.json` permission synthesis.

## Dependencies

- Builds on #453/#454/#455 (merged). No blocked-by.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| #377 pin flip hides a skills regression | 2.2 sweeps skills output separately from agent behavior; skills path untouched by 1.x |
| Deny-rule loss surprises users | Per-agent dropped-rules warning (1.2) + README note that Claude permission enforcement lives in settings |
| Comma-form vs array-form `tools:` | Comma-separated is Claude Code's documented agent-file form; 3.1 asserts the emitted form |
