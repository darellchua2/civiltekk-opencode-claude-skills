# PLAN: kilo install target (agents + skills)

**Branch**: feat/455
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/455
**Base**: main

## Acceptance Criteria

- [ ] Transform maps `read`/`edit`/`bash`/`glob`/`grep`/`task`/`webfetch`/`websearch` permission rules to Kilo's `permission` map; unmappable ones dropped with an explicit warning naming them per agent
- [ ] `disabled` → `disable`; pass-through fields verified in output frontmatter
- [ ] Global + project dest dirs both supported; nested-dir namespacing not triggered by flat copies
- [ ] Transform unit tests; `--dry-run` previews; README / `--help` synced

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` (`TARGETS` kilo row, `kiloAgentContent`, shared rule-parser extraction, help text) | #453/#454 TARGETS layer (merged, `6e9fa51`), `installer/source.mjs` | `package.json` bin (npx installs), `tests/kilo_target.bats` (new), existing suites (`init`/`update`/`parse_arguments`/`agents_target`/`kimi_target` — must stay green), deploy scripts (default-target, exit-code only), README, root `AGENTS.md` | med |
| `parsePermissionRules` extraction (shared by kimi + kilo transforms) | kimi transform (`kimiAgentContent`) | both transform fns; kimi suite pins behavior — refactor must be byte-neutral for kimi output | low |
| Kilo frontmatter translation (additive `permission:` map) | opencode `permissions` array shape in `agents/*.md` | Kilo Code loader (`permission` map enforced; unknown fields ignored) | med |

Cross-module consumers exist (tests, docs, deploy scripts) → architecture review selected. No frontend signal → no uiux review.

## Implementation Phases

### Phase 1: kilo table row + translation

- [x] **1.1** Add the `kilo` row to `TARGETS` (user agents: `~/.config/kilo/agent` — singular per Kilo docs; user skills: `~/.kilo/skills`; project: `.kilo/agents` + `.kilo/skills`; `agentMode: "kilo-translate"`, `skillMode: "verbatim"`) and the `USER_KILO_*` constants; help SCOPE + `--target` lines gain kilo (die message already derives from `TARGET_VALUES`).
    — **Why:** the table is the single resolution site; the global agents dir spelling (`agent`, not `agents`) is a Kilo doc fact that must not be "normalized".
    — **Done when:** `add code-review-subagent --target kilo --dry-run` exits 0 naming `~/.config/kilo/agent`; `--target bogus` still dies listing six values; kimi_target.bats die-pin still green (derivation, not literal).
    — **Consumers affected:** install/update/remove paths (Phase 2-3), docs (Phase 4).
    — **Done:** kilo row + USER_KILO_* constants added (global agents ~/.config/kilo/agent singular, skills ~/.kilo/skills); help SCOPE/--target lines updated; dry-run names the singular dir, bogus target dies listing six (derived); kimi die-pin refreshed to six values; files: installer/init.mjs, tests/agents_target.bats; fixes: none
- [x] **1.2** Extract `parsePermissionRules(lines, closeIdx)` from `kimiAgentContent` (byte-neutral for kimi output — kimi suite is the regression net) and implement `kiloAgentContent(content, warn)`: parse `permissions`; map mappable `{action, resource: "*", effect}` rules — `read/edit/bash/glob/grep/task/webfetch/websearch` pass through as Kilo `permission` type names, `ask` effect maps to Kilo's `ask` — into an additive `permission:` map inserted at column 0 immediately after the opening `---` (same strategy as kimi; never key-scanning); last rule wins per action (mirrors opencode ordering AND Kilo's last-match-wins); `mcp:*` and other non-`*` resources are dropped + warned; `skill`/`question`/subagent gating dropped + warned; `disabled:` frontmatter lines renamed `disable:` (corpus has zero today — future-proofing per the Kilo property name); empty map omits the key; body + existing keys (incl. `permissions` — Kilo ignores unknown fields) byte-identical; frontmatter-less/unterminated guards return verbatim with warn; pre-existing `permission:` key → warn + skip insert.
    — **Why:** Kilo's `permission` map is the enforcement surface; additive insertion keeps single-source fidelity; last-wins is faithful to both semantics.
    — **Done when:** transform verified on 4 real agents (skill-heavy reviewer, one with `task` deny, one read-only, and `zai-media-subagent` which carries `effect: ask` — kilo maps ask→`ask`, kimi drops it): map correct (incl. `task` passthrough + ask), dropped rules named, body bytes unchanged; kimi output byte-identical to pre-refactor on the same inputs.
    — **Consumers affected:** install + update would-content (Phase 2), Kilo users.
    — **Done:** parsePermissionRules extracted (shared); kiloAgentContent implemented (action-passthrough map, *-resources only, last-wins, ask mapped, mcp:*/skill/question dropped+warned, disabled→disable, permission-key + frontmatter guards); verified on 4 agents incl. zai-media (bash: ask) + opencode-tooling (task: deny); kimi output neutral (FetchURL intact post-refactor); files: installer/init.mjs; fixes: none
- [x] **1.3** Wire `kilo-translate` into the user-scope install loop, `cmdUpdate` would-content, **and the project branch's agent write** — `writeInstall`'s `if (ocProject) … else kimiAgentContent` dispatch (the #454 code, `init.mjs:427-434`) must dispatch on `pCfg.agentMode` exactly like the user-scope loop; kimi behavior stays pinned by `kimi_target.bats:101`. Hash = `sha256Hex(translated content)` everywhere.
    — **Why:** architecture-review round 1 disproved the zero-code premise by simulation: the hardcoded else-branch emits kimi-dialect agents (`tools:`/`disallowedTools:`) for every new non-opencode project target — silent tool-gating loss for Kilo project installs. A table-driven seam is only as general as its dispatch sites.
    — **Done when:** `add --target kilo` writes a translated agent; source mutation + `update` re-copies translated content; second `update` reports `unchanged`; `--project --target kilo` writes `permission:` and contains neither `^tools:` nor `^disallowedTools:`; `--project --target kimi` output unchanged (kimi suite green).
    — **Consumers affected:** lifecycle (Phase 3), Kilo + Kimi project users.
    — **Done:** kilo-translate wired into user loop + cmdUpdate + project dispatch (writeInstall now dispatches on pCfg.agentMode — the arch-review Major); idempotent update verified; project kilo install has permission: and zero kimi keys; files: installer/init.mjs; fixes: none

### Phase 2: project scope (TARGETS columns)

- [ ] **2.1** Verify the #454 project-branch table lookup covers kilo rows **after the 1.3 dispatch fix**: `--project --target kilo` writes `.kilo/agents/` + `.kilo/skills/` with `permission:`-translated agents (content asserted — not just dirs), no opencode artifacts (`opencode.json`/`models.json`/`AGENTS.md` absent), dry-run omits config keys, downgrade notes intact for agents/claude, preset flow dies on non-opencode `--target`; flat copies only (no nested-dir namespacing — flat names never contain `/`).
    — **Why:** dirs/manifest/prune ride the table (verified in review); the transform dispatch was the one hard-coded imperative — owned by 1.3.
    — **Done when:** behavioral checks pass including the content assertion above; any further delta found is fixed in the shared dispatch code, not per-target.
    — **Consumers affected:** Kilo project users, CI bats.
- [ ] **2.2** Verify lifecycle rides TARGETS: `update` per-target drift (missing reports `(kilo)`), `remove` wipes user kilo copies, legacy synthesis synthesizes `targets.kilo`, `--prune --project --target kilo` prunes; add nothing if green — pin in 4.1.
    — **Why:** proves the #453/#454 abstraction carries a third platform for free.
    — **Done when:** all behavioral checks green.
    — **Consumers affected:** Kilo users, #457.

### Phase 3: regression sweep

- [ ] **3.1** Regression sweep: opencode/claude/agents/kimi/both targets — manifests + trees identical to pre-change (exists-paired diff method); opencode project preset dry-run byte-identical.
    — **Why:** AC: no regression on existing targets/flows (five surfaces now).
    — **Done when:** all sweeps identical (modulo `generatedAt`).
    — **Consumers affected:** existing users.

### Phase 4: tests + docs + gates

- [ ] **4.1** Add `tests/kilo_target.bats` (HOME-isolated), mirroring the kimi suite: translated `permission:` map (incl. `task` passthrough + `ask` effect via `zai-media-subagent` + dropped `skill()` warning), `disabled→disable` rename (synthesized fixture — corpus has none), verbatim skills, body-byte integrity, no `model:` line, update idempotency + source-drift re-copy, user-scope remove, **project scope with content assertion** (`permission:` present, `tools:`/`disallowedTools:` absent) + artifact guard + downgrade pins, preset-flow die, dry-run preview, corpus guard pinning zero inline `` !`cmd` `` snippets in `skills/` (Kilo executes them in trusted locations), zero `disabled:` in `agents/`.
    — **Why:** the ticket's AC names transform coverage; the two corpus guards pin verified-clean hazards against future regressions.
    — **Done when:** new suite green; no writes outside isolated `$HOME`/tmp project.
    — **Consumers affected:** CI.
- [ ] **4.2** Docs sync: README target table `kilo` row (dirs incl. the singular `~/.config/kilo/agent`, lossy-mapping note: `*`-resource rules map by action name, resource-globbed + `skill`/`question` rules dropped, `task` maps to Kilo's delegation gate, **`mcp:*` denies have no Kilo equivalent — MCP access is governed by Kilo's own config**; unknown frontmatter keys like `permissions`/`system`/`category` are retained, not stripped — Kilo ignores them), root `AGENTS.md` bullet, help text (Phase 1).
    — **Why:** repo documentation-sync rules; the retention note resolves the ticket's "stripped" wording (architecture-review Gap 1 recommended answer: retention preserves update-hash stability + one-key reversibility; stripping buys nothing Kilo can observe).
    — **Done when:** `rg -i 'opencode, claude' README.md AGENTS.md installer/init.mjs` consistent (six values); kilo row cites the Kilo docs URLs.
    — **Consumers affected:** users, docs readers.
- [ ] **4.3** Full gate: all bats suites + `node --test` + pack/drift; `GATE` memo line for the pushed SHA.
    — **Why:** pipeline gate contract.
    — **Done when:** every suite green; memo emitted.
    — **Consumers affected:** code review, PR creation.

## Technical Notes

- **Kilo dir spellings are asymmetric by design** (docs-verified 2026-09-20): global agents `~/.config/kilo/agent` (singular), project agents `.kilo/agents` (plural; `.kilo/agent` also read), skills `~/.kilo/skills` + `.kilo/skills`. The table row encodes the spellings verbatim — no normalization.
- **Kilo also loads `.agents/skills/` and `~/.agents/skills/`** — users who installed #453's shared target already have the skills in Kilo without this ticket; the `kilo` target's skills column adds the native-dir option and (primarily) the agents translation. Per-target hashes keep double installs independent.
- **Kilo executes `!`cmd`` snippets in trusted (global) skills** behind a single approval prompt; the corpus has zero inline snippets (verified 2026-09-20) and 4.1 pins that. Fenced code blocks never execute.
- **Translation is additive** (`permission:` inserted, `permissions` retained — Kilo ignores unknown fields), mirroring the kimi design; reversible by deleting one key.
- **Model pinning:** kilo agents never model-injected; `pCfg`-driven paths mean `update`/`remove`/synthesis/prune ride the table with zero new code (2.1-2.2 verify this claim mechanically).
- **Deliberately out of scope:** MCP cross-platform config; `kilo.jsonc` config-file installs (file-copy model only); nested-dir agent namespacing (flat copies only).

## Dependencies

- Builds on #453 (TARGETS table, per-target hashes, lifecycle) and #454 (project columns, translation pattern, preset-flow guard). No blocked-by.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| `parsePermissionRules` extraction changes kimi behavior | kimi_target.bats (12 tests) is the regression net; 1.2 done-when demands byte-identical kimi output |
| Global agents dir `agent` vs `agents` misspelled in table | 1.1 done-when greps the dry-run destination; 4.1 asserts the installed path |
| Kilo `permission` map semantics differ from opencode ordering | Last-wins per action mirrors both; documented in 1.2 + README |
| Frontmatter insertion corrupts YAML | Same column-0 strategy as kimi (proven); guards for frontmatter-less + pre-existing `permission:` |

## Gate Trace

_Plan review round 1 (architecture-review-subagent): **rejected** → amended. Tier-4 simulation disproved Phase 2's zero-code premise: the project branch (`init.mjs:427-434`) hardcodes `kimiAgentContent` in the else of `if (ocProject)`, so a kilo-row-only change ships kimi-dialect agents into `.kilo/agents/` with no tool gating. Amendments applied: 1.3 owns the project dispatch (pCfg.agentMode, kimi pinned by kimi_target.bats:101); 2.1 + 4.1 assert kilo project content (`permission:` present, kimi keys absent); 1.2/4.1 add `effect: ask` coverage via `zai-media-subagent`; 4.2 documents `mcp:*`-deny non-parity + unknown-key retention (Gap 1 resolved with reviewer's recommended answer: retain, not strip). Dirs/manifest/prune/remove/synthesis verified table-driven (2.2 zero-code claim holds for lifecycle — disproven only for the transform dispatch)._

GATE 0b60caf lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a. — 71 bats ok (die-pin refreshed to six values), node --test green
