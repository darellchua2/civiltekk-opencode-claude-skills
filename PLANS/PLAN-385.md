# PLAN: Document DCP-to-v2-compaction migration reasoning

**Branch**: feat/385
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/385
**Base**: main (rebased onto ece1032 after #388 restructure; root `agents/` is the single source, `opencode_app/.opencode/agents` is a symlink bridge)

## Acceptance Criteria

- [x] `MIGRATION.md` gains a "Context pruning (DCP) → v2 checkpoint compaction" section containing: workflow comparison table (v1 per-request pruning vs v2 episodic checkpoints), why v2 changed (4 reasons), native knob mapping with ALL FOUR rows (compaction.auto/keep.tokens/buffer; tool_output caps + 2000-char retained-tail cap; fixed overhead → skill/MCP allowlists; v1 `experimental.compaction.autocontinue` → native pending-step rebuild), token-reduction levers ranked, and the cache-invalidation note explicitly labeled as inference
- [x] `agents/opencode-v2-migration-subagent.md` (source of truth; NOT the `opencode_app/.opencode/agents` symlink bridge) plugin-triage one-liner (line ~168) expanded to point at the MIGRATION.md section
- [x] Sources cited: opencode.ai/v2/docs/compaction, /v2/docs/config, /v2/docs/build/plugins/migrate-v1, /v2/docs/migrate-v1
- [x] Verification guidance included: `opencode stats` + `OPENCODE_DISABLE_AUTOCOMPACT`
- [x] No config/skill/agent/MCP count changes (docs-only); `node deploy/build-registry.mjs --check` passes (proves frontmatter untouched)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `MIGRATION.md` (new section) | — | Human readers; deploy docs; linked from subagent file | low |
| `agents/opencode-v2-migration-subagent.md` (body edit, line ~168) | MIGRATION.md section must exist first (stable anchor to reference) | opencode-v2-migration-subagent at runtime (knowledge base); reaches the pm2 runtime via the `opencode_app/.opencode/agents` symlink bridge | low |

No code, config, frontmatter, or registry surfaces touched. Docs-only diff.

## Implementation Phases

### Phase 1: MIGRATION.md section

- [x] **1.1** Add section "## Context pruning (DCP) → v2 checkpoint compaction" to `MIGRATION.md` between "### Personal config: small_model + vision fallback (GIT-357)" and "## Docker", containing: (a) workflow comparison table, (b) "Why v2 dropped prune/tail_turns" numbered list (info relocation, cache-prefix stability, tool-pair integrity, provider-native composability + auditability), (c) native replacement mapping table with all four rows (history shrinking → compaction.auto/keep.tokens/buffer; oversized tool results → tool_output caps + 2000-char retained-tail cap; fixed overhead → skill/MCP allowlists; v1 autocontinue → native pending-step rebuild), (d) token-reduction levers ranked (fixed overhead > compaction tuning > plugin port, with the plugin-port row marked "not recommended"), (e) one-line note that the cache claim is inference from provider caching mechanics, not an opencode-docs statement, (f) source list + verification commands (`opencode stats`, `OPENCODE_DISABLE_AUTOCOMPACT`)
    — **Why:** Single home for the decision trail; the subagent pointer (Phase 2) needs this section to exist first so the reference is stable.
    — **Done when:** `MIGRATION.md` new section contains all of: `keep.tokens`, `tool_output`, `fixed overhead`, `inference`, `autocontinue` (grep each ≥1 hit within the section) and `git diff --stat` shows exactly one file changed.
    — **Consumers affected:** Human readers of MIGRATION.md; none runtime.
    — **Done:** Section inserted between "Personal config" and "## Docker" (65 lines): comparison table, 4-reason list, 4-row mapping, ranked levers with plugin-port marked not recommended, cache-inference label, sources + verify commands; files: MIGRATION.md; fixes: none

### Phase 2: Migration-subagent pointer

- [x] **2.1** In `agents/opencode-v2-migration-subagent.md`, expand the plugin-triage line "Known: context-pruning plugins → v2 checkpoint compaction" (~line 168) to append a pointer: native checkpoint compaction replaces them (`compaction.keep.tokens`; no `prune`/`tail_turns` in v2) — full reasoning in MIGRATION.md § Context pruning. Body-only edit; frontmatter untouched. Do NOT edit through the `opencode_app/.opencode/agents` symlink — same inode, but the canonical path keeps diffs clean.
    — **Why:** The subagent is the runtime knowledge base for v1→v2 triage; without the pointer it keeps giving the one-liner with no depth or source.
    — **Done when:** `git diff` shows the hunk starts below the closing frontmatter delimiter (body-only) and `node deploy/build-registry.mjs --check` exits 0.
    — **Consumers affected:** opencode-v2-migration-subagent runtime behavior; registry check pipeline.
    — **Done:** Expanded triage entry with native knobs + MIGRATION.md section pointer; edited via canonical root path (not symlink bridge); files: agents/opencode-v2-migration-subagent.md; fixes: none

### Phase 3: Verification

- [x] **3.1** Run gates: `node deploy/build-registry.mjs --check` (registry sync; CI parity — release.yml runs it), then the `documentation-consistency-skill` audit (count sync, setup.sh/README drift, orphan references — ticket AC5 mandates this confirmation method; expected result: zero count changes since no skills/agents/MCP are added or removed), then bats if runnable locally (`bats tests/` — CI installs it; locally optional, skip cleanly when absent).
    — **Why:** CI (release.yml) runs registry check + bats; the ticket explicitly requires the documentation-consistency confirmation, which the registry check alone does not cover.
    — **Done when:** Registry check exits 0; doc-consistency audit reports no count changes needed; bats skipped-with-note or green.
    — **Consumers affected:** CI pipeline on PR; none runtime.
    — **Done:** Registry check OK (agents=34, skills=149, no drift); doc-consistency audit: README 149 = registry 149 = disk 149 real skills (raw 150 includes `skills/_common`, no SKILL.md — correctly excluded; setup.sh `SKILLS (N)` count format no longer exists post-restructure — no count references to sync); bats absent locally → skipped with note (CI runs it); files: PLANS/PLAN-385.md only; fixes: none

## Technical Notes

- Sources verified 2026-09-14: opencode.ai/v2/docs/compaction (checkpoints, settings, migration note), /v2/docs/config (compaction block, tool_output, warming), /v2/docs/build/plugins/migrate-v1 (V1 plugins don't run on V2), /v2/docs/migrate-v1 (tail_turns/prune ignored with warning).
- Key facts to preserve verbatim-accurate: preflight formula `estimated tokens >= min(input limit - buffer, context limit - max(output reserve, buffer))`; defaults `keep.tokens: 15000`, `buffer: 20000`; retained-tail tool outputs capped at 2,000 chars; `tool_output` defaults `max_lines: 2000`, `max_bytes: 51200`; v2 warning "V1 plugin implementations do not run in V2".
- Path note: after #388's restructure, root `agents/` is the single source of truth; `opencode_app/.opencode/agents` is a symlink bridge (`../../agents`). All edits target root paths.
- Conventional Commit: `docs(migration): document DCP → v2 checkpoint compaction reasoning`.
- MIGRATION.md voice: tables, tight bullets, verified-against-docs dates (match existing style).

## Dependencies

None. No blocked-by tickets.

## Risks & Mitigation

- **Risk:** Doc drift if upstream v2 compaction changes again. **Mitigation:** Section carries "verified 2026-09-14" date stamp, consistent with repo convention.
- **Risk:** Accidentally editing agent frontmatter (registry check failure). **Mitigation:** Body-only edit; `build-registry.mjs --check` is the Phase 3 gate.
- **Risk:** Further restructures moving `agents/` again before merge. **Mitigation:** PR rebases on main at merge time; the target file is tracked by git regardless of directory moves.
