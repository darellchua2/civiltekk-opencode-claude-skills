# PLAN: Phase 4 — Normalize agent frontmatter to opencode v2

**Branch**: feat/380
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/380
**Base**: main (816d903)

## Acceptance Criteria

From ticket #380, re-validated against `origin/main` @ `816d903` (delta documented in [issue comment](https://github.com/darellchua2/opencode-config-template/issues/380#issuecomment-5712928698)):

- [ ] `node installer/build-registry.mjs` regenerates identical counts (149/34) and byte-identical agent/skill arrays (`--check` green; only `__meta`/`generatedAt` move)
- [ ] `bats tests/` green (full suite)
- [ ] No `^prompt:` / `^tools:` / `^permission:` left in `agents/` frontmatter — all 34 agents carry native v2 `permissions:` rules arrays
- [ ] Spot-check: 3 agents parse + schema-validate against the v2 contract (action/resource/effect, order-preserving); real `opencode` load if the CLI is available on the runner
- [ ] `LEGACY_USER_CONFIG` adoption path removed from `installer/init.mjs`
- [ ] One-shot normalizer deleted after run (ticket scope)

**Re-validation delta:** 0 agents have `prompt:`/`tools:` in frontmatter (the one `prompt:` hit, `opencode-tooling-subagent.md:137`, is body prose). The mass legacy shape is `permission:` (singular) nested map — scalar (`bash: deny`) or resource→effect sub-map (`read: {"*": allow, "mcp:*": deny}`) — in all 34 agents. Mapping: `permission:<map>` → `permissions:` array of `{action, resource, effect}` rules, entry order preserved (v2 last-match-wins semantics identical to map order). `build-registry.mjs:144-146` consumes the old map (`keysOf(perm.skill)` → requiresSkills, `keysOf(perm.task)` → delegatesTo; `keysOf` drops `*`) and must switch to the array form in the same change or the registry loses its dependency edges.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `agents/*.md` (34 files, frontmatter only) | normalizer script | `installer/build-registry.mjs` (parser), `installer/init.mjs` `readAgent` (copies content), `installer/resolve-models.mjs` (injects `model:` at deploy), `deploy/setup.sh` (file copy), opencode v2 runtime | high |
| `installer/build-registry.mjs` parser (:144-146) + header docs (:12-22) | agents normalized in same change | `installer/registry.json`, CI drift guard, README category table, `tests/init.bats` count assertions | high |
| `installer/registry.json` regen | parser + normalization | CI `--check`, `--list` flows, presets provenance | med |
| `installer/init.mjs` LEGACY_USER_CONFIG (:59, :648, :689-694) | — | `checkStrictAllowlist` fallback read, `permitMerge` legacy adoption; bats `--permit` cases | med |
| `MIGRATION.md`, root `AGENTS.md` §Frontmatter Contract | behavior lands first | humans; doc-consistency sweeps | low |
| Skills frontmatter | — (no change; already standard per ticket) | — | — |

## Implementation Phases

### Phase 1: Normalize agents + registry parser (atomic pair)

- [ ] **1.1** `installer/build-registry.mjs`: `export` the `parseFrontmatter` function (keyword only, no behavior change); update header comment block (:12-22) from map-shape description to `permissions`-array description
    — **Why:** The one-shot normalizer needs the exact parser the registry uses (comment/quote/folding edge cases); exporting avoids a divergent 60-line copy in a throwaway script.
    — **Done when:** `node --check`; `node installer/build-registry.mjs --check` still green pre-normalization.
    — **Consumers affected:** none at runtime (ESM export addition).

- [ ] **1.2** Write `installer/normalize-frontmatter.mjs` (one-shot, deleted in 1.5): for each `agents/*.md` — parse frontmatter via imported parser; if `permission` map present, build `permissions` array (for each action key in insertion order: scalar → one `{action, resource:"*", effect}` rule; sub-map → one rule per resource in insertion order, effect as mapped); assert fail-loud on non-scalar/non-map values, missing description/mode/category, or `prompt:`/`tools:` keys in frontmatter; rewrite ONLY the frontmatter block (body byte-identical), emitting YAML matching repo style (unquoted keys, `'*'`/`'mcp:*'`/glob resources quoted, 2-space indent, rules as `- action:` list items)
    — **Why:** Mechanical, order-preserving mapping is the whole ticket; fail-loud guards catch any shape the census missed instead of silently mangling an agent.
    — **Done when:** dry-run mode prints 34 planned rewrites, 0 skipped-odd; `node --check` passes.
    — **Consumers affected:** all 34 agent files (frontmatter only).

- [ ] **1.3** Run the normalizer for real; then update `build-registry.mjs` :144-146 to read the array (`requiresSkills = perms.filter(r => r.action==="skill" && r.resource!=="*").map(r=>r.resource)`, `delegatesTo` same for `"task"` — faithful to old `keysOf`, no effect filter); regenerate registry
    — **Why:** Parser and files must flip together — the registry is the contract every downstream tool (CI, presets, tests) verifies against; preserving `keysOf` semantics (drop `*`, ignore effect) keeps requiresSkills/delegatesTo byte-identical.
    — **Done when:** `grep -l '^permission:' agents/*.md` empty; `grep -c '^permissions:' agents/*.md | grep -v ':1$'` empty (all 34 have exactly one); `node installer/build-registry.mjs --check` green; `git diff installer/registry.json` shows only `__meta`/`generatedAt`.
    — **Consumers affected:** registry consumers (CI, `--list`, presets, tests).

- [ ] **1.4** Delete `installer/normalize-frontmatter.mjs`
    — **Why:** Ticket scope — one-shot script, kept out of the shipped installer tree (would ride the npm tarball otherwise).
    — **Done when:** file absent; `npm pack --dry-run` shows no normalizer entry.
    — **Consumers affected:** none (git history preserves it).

**Phase gate:** registry `--check` green with identical counts (34/149) + edges (spot: code-review-subagent still skills=17/delegates=4); `node --check` on all touched .mjs; `bats tests/init.bats`; body-diff proof: `git diff --stat agents/` plus `git diff agents/ | grep -c '^[+-]' | grep -v permissions` sanity (frontmatter-only churn); grep sweeps (no `^permission:`/`^prompt:`/`^tools:` in agents/).

### Phase 2: Remove LEGACY_USER_CONFIG from init.mjs

- [ ] **2.1** Delete `LEGACY_USER_CONFIG` const (:59), the `?? readJsonMaybe(LEGACY_USER_CONFIG)` fallback in `checkStrictAllowlist` (:648), and the legacy `config.json` adoption block in `permitMerge` (:689-694) including its comment
    — **Why:** Ticket scope — v2 never reads `~/.config/opencode/config.json`; the adoption path is dead code that implies a migration that no longer exists.
    — **Done when:** `grep -c LEGACY_USER_CONFIG installer/init.mjs` = 0; `node --check`; `bats tests/init.bats` green (incl. `--permit` cases that exercise `permitMerge`).
    — **Consumers affected:** hypothetical pre-v2.1 deployers (none known; v2 has shipped across this repo's lifetime).

### Phase 3: Docs

- [ ] **3.1** Root `AGENTS.md` §Skill/Agent Frontmatter Contract: drop the "Source agent `.md` files still use the legacy key spellings … normalisation pass … is deferred" sentence; state agents ship native v2 keys (`system`, `permissions` array)
    — **Why:** The contract doc is the repo's agent-file source of truth; leaving the deferred note after landing would be a false claim (doc-claims-match-plugin-defaults lesson).
    — **Done when:** `grep -c 'normalisation pass' AGENTS.md` = 0.
    — **Consumers affected:** agent authors (human + AI) reading the contract.

- [ ] **3.2** `MIGRATION.md`: add a short "Frontmatter normalized to v2" section — what changed (`permission:` map → `permissions:` rules array, order-preserving; `LEGACY_USER_CONFIG` adoption removed), why (drop v2 auto-translation dependence), pointer to AGENTS.md contract
    — **Why:** MIGRATION.md is the repo's change ledger users consult on version bumps; this is a user-visible file-format change shipped in a major cycle.
    — **Done when:** section exists with the three facts + pointer.
    — **Consumers affected:** users diffing deployed agent files after `setup.sh`.

**Phase gate:** doc greps; `bash -n`/`node --check` untouched-by-docs sanity; full bats re-run.

### Phase 4: Final verification

- [ ] **4.1** Full gate re-run + v2 load spot-check: all bats files; registry `--check`; `--list agents` (34); schema-validate 3 representative agents (scalar-heavy, map-heavy, both skill+task rules — e.g. code-review-subagent, tdd-subagent, opencode-tooling-subagent) by parsing their `permissions` arrays and asserting rule shape; if `opencode` CLI is available on the runner, load-check one agent through it, else note the parse-level check in the PR body
    — **Why:** The ticket's spot-check AC; parse-level schema validation is the floor, a real v2 load is the ceiling — take what the runner offers.
    — **Done when:** all checks green (or CLI absent + parse-level pass noted in PR).
    — **Consumers affected:** none (verification).

## Technical Notes

- v2 auto-translates legacy keys, so this is not behavior-blocking today — it removes translation dependence (ticket framing).
- Order preservation is semantic: v2 evaluates permissions last-match-wins; map entry order (e.g. `read: {"*": allow, "mcp:*": deny}`) must survive as array order.
- `keysOf` (build-registry:123-126) drops `*` and ignores effect — the array parser must replicate exactly or registry edges drift.
- Skills untouched (already standard); `category` stays installer-registry-only.
- Census artifacts that are body prose, NOT frontmatter: `prompt:` (tooling:137), `model:` (tooling:134), `workflow:`/`layers:`/`audience:` hits. The normalizer must only ever rewrite the region between the first two `---` lines.

## Dependencies

- Branch cut from `816d903` (includes #378 installer split, #377 targets).
- Must land BEFORE #379 (Phase 5) — normalization rewrites all 34 agent hashes; doing it first avoids a spurious mass "34 agents updated" event on first `update`.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Registry edge drift (requiresSkills/delegatesTo) breaks CI/tests | Parser flips in the same commit as the files; `--check` + count assertions in the phase gate; code-review fixture spot (skills=17 delegates=4) |
| A census-invisible permission shape (list value, weird quoting) mangles an agent | Normalizer fail-loud on unknown shapes + dry-run first; body bytes asserted unchanged |
| Order of rules flipped → different allow/deny outcome | Insertion-order iteration both in parser and emitter; spot-assert `mcp:*` deny follows `*` allow in rewritten files |
| Real v2 load unavailable on runner | Parse-level schema validation floor; honestly noted in PR body (same pattern as pwsh/docker caveats) |
| Hash churn triggering deploy-time noise | Expected and deliberate — that's WHY this precedes #379 (ticket rationale) |
