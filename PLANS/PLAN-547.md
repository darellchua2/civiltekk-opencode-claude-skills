# PLAN: Built-in agent model pin option in repo-setup skill

**Branch**: feat/547
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/547
**Base**: main

## Acceptance Criteria

- [ ] AC1 — Step 2 offers the builtin-model-pin extra with group multi-select + scope choice (project recommended / global)
- [ ] AC2 — Free-form model string validated (contains `/`); no model IDs hardcoded in the skill
- [ ] AC3 — Project write merges `agents.<id>.model` via the existing merge procedure; existing keys preserved — diff-check wording covers `agents.*` alongside `mcp.*`
- [ ] AC4 — Global option backs up `~/.config/opencode/opencode.json` before merging
- [ ] AC5 — Step 5 report lists the pins + revert instructions; notes hidden agents stay non-selectable
- [ ] AC6 — Frontmatter `description` gains trigger phrases (stays ≤50 words); `node installer/build-registry.mjs` run and `registry.json` committed
- [ ] AC7 — Skills test suite passes (SKILL.md-only change; isolation contract unaffected)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `skills/opencode-repo-setup-skill/SKILL.md` | — | Skill runtime (loader reads `description` for triggers; LLM follows body in target-project sessions), `documentation-consistency-skill` audits | low |
| `registry.json` | SKILL.md frontmatter (regenerated from it) | `installer/init.mjs` (add/update flows), `deploy/setup.sh` counts/banner, `installer/deploy-plan-items.mjs` | low (generated artifact — never hand-edit) |

Thin map: prose-only skill change; no cross-module code consumers. Architecture review triaged out (no cross-module nodes); no frontend signal → no uiux review; Step 9 code review backstops.

## Implementation Phases

### Phase 1: SKILL.md capability (builtin model pins)

- [ ] **1.1** Update SKILL.md frontmatter `description` to add trigger phrases "pin agent models" / "agent model pins" while staying ≤50 words and keeping `name` unchanged
    — **Why:** skill discovery is description-driven; without the triggers the new capability is unreachable. Registry (step 2.1) derives from this field, so it must land first.
    — **Done when:** description contains the new trigger phrases, word count ≤50, `name: opencode-repo-setup-skill` unchanged, YAML frontmatter still parses.
    — **Consumers affected:** registry.json (regenerated in 2.1).
- [ ] **1.2** Add the Step 2 extra: "Pin built-in agent models?" question payload — group multi-select (hidden maintenance `title`/`summary`/`compaction` · subagents `explore`/`general` · all five · no) + scope choice (project `<repo>/opencode.json` recommended / global `~/.config/opencode/opencode.json`) + free-form `provider/model[#variant]` input per chosen group validated to contain `/`
    — **Why:** this is the user-facing capability itself (AC1, AC2); the scope question is what makes it per-project opt-in instead of a global override.
    — **Done when:** SKILL.md Step 2 documents the extra with the exact group list, both scope options with project marked recommended, the model-string validation rule, and a "no model IDs hardcoded" note consistent with the Governance section.
    — **Consumers affected:** Step 3 write path (1.3), Step 5 report (1.4).
- [ ] **1.3** Add the Step 3 write path: `{"agents": {"<id>": {"model": "..."}}}` delta through the existing mandatory jq/Node deep-merge procedure; global target = backup-then-merge of `~/.config/opencode/opencode.json`; extend the diff-check wording to `agents.*` alongside `mcp.*`; note the merge-safety rationale (agent definitions merge across layers — scalars replace, permission rules append)
    — **Why:** AC3 + AC4; reusing the existing merge procedure avoids a second write mechanic that could drift from the mcp one.
    — **Done when:** SKILL.md Step 3 shows the agents delta shape, names both targets, states the backup requirement for the global path, and the diff-check line covers `mcp.*`/`agents.*`.
    — **Consumers affected:** Step 5 report/revert wording (1.4).
- [ ] **1.4** Update the "What I do" intro (global-edit exception for this extra only) and Step 5 report/revert: list written pins (effective next session), revert = delete added `agents.<id>` keys (or whole `agents` key if we created the file), hidden agents remain non-selectable, `build`/`plan` deliberately not offered
    — **Why:** AC5 + honesty rule — the skill currently states "I never edit the global config"; that sentence must carry the scoped exception or the skill contradicts itself.
    — **Done when:** intro states the exception is limited to the agent-model-pin extra; Step 5 enumerates pins written + revert instructions + the hidden-agent caveat.
    — **Consumers affected:** none (documentation surface).

### Phase 2: Registry + verification

- [ ] **2.1** Run `node installer/build-registry.mjs` in the worktree and stage the regenerated `registry.json`
    — **Why:** AC6 + house rule (any frontmatter change requires registry regen + commit); the registry is the installer's source of skill metadata.
    — **Done when:** `git diff registry.json` shows only the opencode-repo-setup-skill description change; `installer/init.mjs` still parses the registry (build script exits 0).
    — **Consumers affected:** `installer/init.mjs`, `deploy/setup.sh` banner counts.
- [ ] **2.2** Run the skills test suite subset (skill isolation + frontmatter/registry guards) and fix any failure attributable to this change
    — **Why:** AC7; the guard tests mechanically enforce the isolation contract and frontmatter rules the edit must not break.
    — **Done when:** `bats tests/test_skill_isolation.bats` (and any frontmatter/registry guard test present) exits 0, or failures are proven pre-existing on `origin/main`.
    — **Consumers affected:** CI (PR checks in Step 10).

## Technical Notes

- Model strings carry the provider (`provider/model[#variant]`) — no separate provider field needed.
- Safe-by-docs: OpenCode v2 merges agent definitions across config layers (scalars replace, permission rules append), so a model-only project entry preserves the global entry's `permissions`. Unlike `mcp.servers.<name>`, no full-entry requirement — cite this in the skill so future editors don't apply the mcp atomicity rule here.
- Hidden builtins per v2 docs: `compaction`, `title`, `summary` — maintenance-only, not selectable; pinning is purely a cost knob (they inherit the session model when unset).
- Do not touch `deploy/setup.sh` or `installer/resolve-models.mjs` — out of scope per ticket.

## Dependencies

None — single contained ticket, no `blocked-by:`.

## Risks & Mitigation

- **Skill description drifts past the 50-word house cap** → word-count check is an explicit Done-when in 1.1; registry build fails loud if frontmatter breaks.
- **Users conflate project vs global scope writes** → the question payload marks project as recommended and the global path mandates a backup (1.3), reported in Step 5.
- **Generated-artifact drift** → 2.1 regenerates rather than hand-edits `registry.json`; diff scope check confirms nothing else moved.
