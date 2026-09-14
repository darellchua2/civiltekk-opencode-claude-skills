# PLAN: Document DCP-to-v2-compaction migration reasoning

**Branch**: feat/385
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/385
**Base**: main

## Acceptance Criteria

- [ ] `MIGRATION.md` gains a "Context pruning (DCP) → v2 checkpoint compaction" section containing: workflow comparison table (v1 per-request pruning vs v2 episodic checkpoints), why v2 changed (4 reasons), native knob mapping (compaction.auto/keep.tokens/buffer, tool_output caps, 2000-char retained-tail cap), token-reduction levers ranked, and the cache-invalidation note explicitly labeled as inference
- [ ] `opencode_app/.opencode/agents/opencode-v2-migration-subagent.md` plugin-triage one-liner (line ~168) expanded to point at the MIGRATION.md section
- [ ] Sources cited: opencode.ai/v2/docs/compaction, /v2/docs/config, /v2/docs/build/plugins/migrate-v1, /v2/docs/migrate-v1
- [ ] Verification guidance included: `opencode stats` + `OPENCODE_DISABLE_AUTOCOMPACT`
- [ ] No config/skill/agent/MCP count changes (docs-only); `node deploy/build-registry.mjs --check` passes (proves frontmatter untouched)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `MIGRATION.md` (new section) | — | Human readers; deploy docs; linked from subagent file | low |
| `opencode_app/.opencode/agents/opencode-v2-migration-subagent.md` (body edit, line ~168) | MIGRATION.md section must exist first (stable anchor to reference) | opencode-v2-migration-subagent at runtime (knowledge base) | low |

No code, config, frontmatter, or registry surfaces touched. Docs-only diff.

## Implementation Phases

### Phase 1: MIGRATION.md section

- [ ] **1.1** Add section "## Context pruning (DCP) → v2 checkpoint compaction" to `MIGRATION.md` between "### Personal config: small_model + vision fallback (GIT-357)" (ends ~line 206) and "## Docker" (~line 207), containing: (a) workflow comparison table, (b) "Why v2 dropped prune/tail_turns" numbered list (info relocation, cache-prefix stability, tool-pair integrity, provider-native composability + auditability), (c) native replacement mapping table (DCP job → v2 knob), (d) token-reduction levers ranked (fixed overhead > compaction tuning > plugin port, with the plugin-port row marked "not recommended"), (e) one-line note that the cache claim is inference from provider caching mechanics, not an opencode-docs statement, (f) source list + verification commands (`opencode stats`, `OPENCODE_DISABLE_AUTOCOMPACT`)
    — **Why:** Single home for the decision trail; the subagent pointer (Phase 2) needs this section to exist first so the reference is stable.
    — **Done when:** `grep -c "checkpoint compaction" MIGRATION.md` ≥ 2 and `git diff --stat` shows exactly one file changed.
    — **Consumers affected:** Human readers of MIGRATION.md; none runtime.

### Phase 2: Migration-subagent pointer

- [ ] **2.1** In `opencode_app/.opencode/agents/opencode-v2-migration-subagent.md`, expand the plugin-triage line "Known: context-pruning plugins → v2 checkpoint compaction" (~line 168) to append a pointer: native checkpoint compaction replaces them (`compaction.keep.tokens`; no `prune`/`tail_turns` in v2) — full reasoning in MIGRATION.md § Context pruning. Body-only edit; frontmatter untouched.
    — **Why:** The subagent is the runtime knowledge base for v1→v2 triage; without the pointer it keeps giving the one-liner with no depth or source.
    — **Done when:** `git diff` shows a body-only change (no `---` frontmatter lines in the hunk) and `node deploy/build-registry.mjs --check` exits 0.
    — **Consumers affected:** opencode-v2-migration-subagent runtime behavior; registry check pipeline.

### Phase 3: Verification

- [ ] **3.1** Run gates: `node deploy/build-registry.mjs --check` (registry sync) and `bash tests/lib/bats-core/bin/bats tests/ 2>/dev/null || bats tests/` (CI parity); confirm zero count changes needed (no skills/agents/MCP added or removed — setup.sh/README counts untouched).
    — **Why:** CI (release.yml) runs these; docs-only changes must still pass them, and the registry check is the proof the agent-file edit stayed body-only.
    — **Done when:** Both commands exit 0 (or bats absent locally and registry check green + no lint/build applicable to .md files).
    — **Consumers affected:** CI pipeline on PR.

## Technical Notes

- Sources verified 2026-09-14: opencode.ai/v2/docs/compaction (checkpoints, settings, migration note), /v2/docs/config (compaction block, tool_output, warming), /v2/docs/build/plugins/migrate-v1 (V1 plugins don't run on V2), /v2/docs/migrate-v1 (tail_turns/prune ignored with warning).
- Key facts to preserve verbatim-accurate: preflight formula `estimated tokens >= min(input limit - buffer, context limit - max(output reserve, buffer))`; defaults `keep.tokens: 15000`, `buffer: 20000`; retained-tail tool outputs capped at 2,000 chars; `tool_output` defaults `max_lines: 2000`, `max_bytes: 51200`; v2 warning "V1 plugin implementations do not run in V2".
- Conventional Commit: `docs(migration): document DCP → v2 checkpoint compaction reasoning`.
- MIGRATION.md voice: tables, tight bullets, verified-against-docs dates (match existing style).

## Dependencies

None. No blocked-by tickets.

## Risks & Mitigation

- **Risk:** Doc drift if upstream v2 compaction changes again. **Mitigation:** Section carries "verified 2026-09-14" date stamp, consistent with repo convention.
- **Risk:** Accidentally editing agent frontmatter (registry check failure). **Mitigation:** Body-only edit; `build-registry.mjs --check` is the Phase 3 gate.
