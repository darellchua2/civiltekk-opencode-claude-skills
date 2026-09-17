# PLAN: Phase 4 — Normalize agent frontmatter to opencode v2

**Branch**: feat/380
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/380
**Base**: main (816d903)

## Acceptance Criteria

From ticket #380, re-validated against `origin/main` @ `816d903` (delta documented in [issue comment](https://github.com/darellchua2/opencode-config-template/issues/380#issuecomment-5712928698)); amended after plan review (blockers ARCH-1/2, majors REQ-1/ARCH-3 folded in):

- [ ] `node installer/build-registry.mjs` regenerates identical counts (149/34) and byte-identical agent/skill arrays (`--check` green; only `$comment`-preserved fields + `generatedAt` move)
- [ ] `bats tests/` green (full suite, including the 8 rewired test blocks in 3 files)
- [ ] No `^prompt:` / `^tools:` / `^permission:` left in `agents/` **frontmatter regions** (body prose in fenced examples is exempt — tooling:137-138, :321)
- [ ] Spot-check: 3 agents parse + schema-validate against the v2 contract (action/resource/effect, order-preserving); real `opencode` load if the CLI is available on the runner, else parse-level floor noted in PR body
- [ ] `LEGACY_USER_CONFIG` adoption path removed from `installer/init.mjs`
- [ ] One-shot normalizer deleted after run (ticket scope)

**Re-validation delta:** 0 agents have `prompt:`/`tools:` in frontmatter (the `prompt:` hit, `opencode-tooling-subagent.md:137`, is body prose; same file has body-prose `permission:` at :138, :321). The mass legacy shape is `permission:` (singular) nested map — scalar (`bash: deny`) or resource→effect sub-map (`read: {"*": allow, "mcp:*": deny}`) — in all 34 agents. Mapping: `permission:<map>` → `permissions:` array of `{action, resource, effect}` rules, entry order preserved (v2 last-match-wins ≡ map order). `build-registry.mjs:144-146` consumes the old map (`keysOf(perm.skill)` → requiresSkills, `keysOf(perm.task)` → delegatesTo; `keysOf` drops `*`, ignores effect) and must flip to array reading in the same change.

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `agents/*.md` (34 files, frontmatter only) | normalizer script | `installer/build-registry.mjs` (parser+reader), `installer/init.mjs` `readAgent` (raw copy — no parse), `installer/resolve-models.mjs` (`model:` line splice only), `deploy/setup.sh` (copy/count/hash only), opencode v2 runtime | high |
| `installer/build-registry.mjs` `parseFrontmatter` (:60-121) | — (extended BEFORE normalization: needs `- ` sequence support or arrays mangle to objects and the reader's `.filter` throws — proven by review execution) | registry build, the one-shot normalizer (imported), future tooling | high |
| `installer/build-registry.mjs` reader (:144-146) + header docs (:9-23) | parser extension + agents normalized in same change | `installer/registry.json`, CI drift guard, README category table, `tests/init.bats` count assertions | high |
| `tests/test_autoresearch_skills.bats` (:111,:124,:137,:141,:145), `tests/test_markitdown_skill.bats` (:59), `tests/test_docling_skill.bats` (:129) | agents normalized in same change | CI bats suite — 8 blocks structurally consume the legacy map (`fm['permission']` PyYAML access + literal `<skill>: allow` greps) | high |
| `installer/registry.json` regen | parser + reader + normalization | CI `--check`, `--list` flows, presets provenance | med |
| `installer/init.mjs` LEGACY_USER_CONFIG (:59, :648, :689-695) | — | `checkStrictAllowlist` fallback read, `permitMerge` legacy adoption; bats `--permit` cases (isolated HOME — no legacy fixture, safe) | med |
| Docs: root `AGENTS.md` (:78 deferred sentence), `MIGRATION.md`, `README.md` (:252,:268,:409), `opencode_app/README.md` (:189), `skills/opencode-skill-creation-skill/SKILL.md` (:283,:317) | behavior lands first | humans; `tests/test_pack_permissions.bats:177` doc sweep (covers `permission.tool`/`tools` — NOT `permission.task`/`skill`; no new mechanical guard, sweep is manual+grep) | med |
| Skills frontmatter | — (no change; already standard per ticket) | — | — |

## Implementation Phases

### Phase 1: Normalize agents + registry parser + test rewires (atomic triple)

- [ ] **1.1** `installer/build-registry.mjs`: (a) extend `parseFrontmatter` with YAML sequence support — lines matching `- key: value` (or `- key:` map start) at a given indent collect into an array under the parent key; maps after scalars/sequences still parse; (b) `export` the function; (c) keep pre-normalization behavior bit-identical (registry `--check` green BEFORE any agent is rewritten); update header comment (:9-23) from map-shape to array-shape description
    — **Why:** Review-proven blocker: the current parser has no sequence support, so post-normalization `fm.permissions` mangles to an object and the array reader throws. The extension must exist and be proven non-breaking before the flip.
    — **Done when:** `node installer/build-registry.mjs --check` green on un-normalized tree; a quick inline node test parses `- action: skill` sequences into arrays.
    — **Consumers affected:** registry build, normalizer import, future tooling.

- [ ] **1.2** Write `installer/normalize-frontmatter.mjs` (one-shot, deleted in 1.5): for each `agents/*.md` — parse frontmatter via imported parser; if `permission` map present, build `permissions` array (for each action key in insertion order: scalar → one `{action, resource:"*", effect}` rule; sub-map → one rule per resource in insertion order); **in-place replacement of only the `permission:` block** — every other frontmatter line byte-identical (folded `>-` descriptions untouched), body region byte-identical; fail-loud on non-scalar/non-map values, missing description/mode/category, or frontmatter `prompt:`/`tools:` keys; **round-trip guard**: re-parse the emitted frontmatter and deep-compare against the original parsed map with permission→permissions applied. Emits YAML matching repo style (unquoted keys, glob resources quoted, 2-space indent, `- action:` list items).
    — **Why:** Mechanical, order-preserving mapping is the ticket; fail-loud + round-trip guards catch any census-invisible shape or emitter bug instead of silently mangling agents (ARCH-4, REQ-3).
    — **Done when:** dry-run prints 34 planned rewrites, 0 odd; round-trip deep-equal passes for all 34.
    — **Consumers affected:** all 34 agent files (frontmatter only).

- [ ] **1.3** Run the normalizer; flip the `build-registry.mjs` reader (:144-146) to array form (`requiresSkills = (fm.permissions||[]).filter(r => r.action==="skill" && r.resource!=="*").map(r=>r.resource)`, `delegatesTo` same for `"task"` — faithful to old `keysOf`, no effect filter); regenerate registry
    — **Why:** Files, parser, and reader must flip together — registry is the contract CI/tests verify; preserving `keysOf` semantics (drop `*`, ignore effect) keeps edges byte-identical (fixture: code-review-subagent requiresSkills=17, delegatesTo=4).
    — **Done when:** frontmatter-region sweep (lines between first two `---` per file) shows zero `permission:`/`prompt:`/`tools:` keys across all 34; `node installer/build-registry.mjs --check` green; `git diff installer/registry.json` touches only `generatedAt`.
    — **Consumers affected:** registry consumers (CI, `--list`, presets, tests).

- [ ] **1.4** Rewire the 8 legacy-map test blocks to array form: `tests/test_autoresearch_skills.bats` :111 (`fm['permission']['edit']` → find rule `action==='edit'`), :124 (scalar asserts bash/webfetch/websearch via rule lookup), :137/:141/:145 (literal `<skill>: allow` greps → rule-presence checks via PyYAML `fm['permissions']` filter); `tests/test_markitdown_skill.bats` :59 (markitdown-mcp-skill rule across 5 agents); `tests/test_docling_skill.bats` :129 (docling-mcp-skill rule)
    — **Why:** Review-found blocker (ARCH-1): these blocks structurally consume the map form; without rewiring, the ticket AC "bats tests/ green" is unreachable and CI is red on the PR regardless of code quality.
    — **Done when:** `bats tests/test_autoresearch_skills.bats tests/test_markitdown_skill.bats tests/test_docling_skill.bats` green; assertions semantically equivalent (same skills/agents, same allow/deny facts).
    — **Consumers affected:** CI bats suite.

- [ ] **1.5** Delete `installer/normalize-frontmatter.mjs`
    — **Why:** Ticket scope — one-shot script kept out of the shipped installer tree (rides the npm tarball otherwise).
    — **Done when:** file absent; `npm pack --dry-run` shows no normalizer entry.
    — **Consumers affected:** none (git history preserves it).

**Phase gate:** registry `--check` green (counts 34/149 + edges: code-review-subagent skills=17 delegates=4); `node --check` all touched .mjs; `bats tests/init.bats tests/test_autoresearch_skills.bats tests/test_markitdown_skill.bats tests/test_docling_skill.bats` green; frontmatter-region sweeps zero legacy keys; body-region byte-identity: `git diff agents/` hunks confined to frontmatter blocks (every changed hunk starts before the second `---` line of its file); registry diff = `generatedAt` only.

### Phase 2: Remove LEGACY_USER_CONFIG from init.mjs

- [ ] **2.1** Delete `LEGACY_USER_CONFIG` const (:59), the `?? readJsonMaybe(LEGACY_USER_CONFIG)` fallback in `checkStrictAllowlist` (:648), and the legacy `config.json` adoption block in `permitMerge` (:689-695: comment :690-691 + if-block :692-695)
    — **Why:** Ticket scope — v2 never reads `~/.config/opencode/config.json`; the adoption path is dead code implying a migration that no longer exists.
    — **Done when:** `grep -c LEGACY_USER_CONFIG installer/init.mjs` = 0; `node --check`; `bats tests/init.bats` green (incl. `--permit` cases exercising `permitMerge`).
    — **Consumers affected:** hypothetical pre-v2.1 deployers (none known).

### Phase 3: Docs

- [ ] **3.1** Root `AGENTS.md` §Skill/Agent Frontmatter Contract: drop the "Source agent `.md` files still use the legacy key spellings … normalisation pass … is deferred" sentence (:78); state: source agents ship native `permissions:` rules arrays and no `model:` (tier-injected at deploy); the markdown body is the system prompt — do NOT claim agents carry `system:` (none do, REQ-4)
    — **Why:** The contract doc is the repo's agent-file source of truth; a lingering deferred note (or an over-broad replacement claim) is a false doc claim (doc-claims-match-plugin-defaults lesson).
    — **Done when:** `grep -c 'normalisation pass' AGENTS.md` = 0; new sentence mentions `permissions` array + tier-injected `model:` only.
    — **Consumers affected:** agent authors (human + AI) reading the contract.

- [ ] **3.2** Legacy-spelling doc sweep (ARCH-3): fix claims that THIS REPO's source agents still use legacy spellings — `README.md` :252, :268, :409; `opencode_app/README.md` :189; `skills/opencode-skill-creation-skill/SKILL.md` :283, :317 (teaching examples must show `permissions` arrays). Exempt: text describing USER-authored v1 agents being debugged/migrated (e.g. `agent-introspection-debugging-skill` :100-258 — legitimately discusses legacy user configs)
    — **Why:** These become false the moment this lands; the skill-creation skill actively teaches the old spelling to every reader.
    — **Done when:** per-file grep for `legacy`/`permission\.` near agent-frontmatter claims shows only exempt (user-config) contexts; updated examples are array-form.
    — **Consumers affected:** README readers; skill-creation skill consumers.

- [ ] **3.3** `MIGRATION.md`: add "Frontmatter normalized to v2" section — what changed (`permission:` map → `permissions:` rules array, order-preserving; `LEGACY_USER_CONFIG` adoption removed), why (drop v2 auto-translation dependence), pointer to AGENTS.md contract
    — **Why:** MIGRATION.md is the change ledger users consult on version bumps; this is a user-visible file-format change in a major cycle.
    — **Done when:** section exists with the three facts + pointer.
    — **Consumers affected:** users diffing deployed agent files after `setup.sh`.

**Phase gate:** doc greps per step; full bats re-run; registry `--check` still green.

### Phase 4: Final verification

- [ ] **4.1** Full gate re-run + v2 spot-check: all 13 bats files; registry `--check`; `--list agents` (34); schema-validate 3 representative agents (scalar-heavy, map-heavy, skill+task rules — code-review-subagent, tdd-subagent, opencode-tooling-subagent): parse their `permissions` arrays, assert every rule has action/resource/effect with valid enums, and assert `mcp:*` deny follows `*` allow where present (order preservation); if `opencode` CLI exists on the runner, load-check one agent, else note parse-level floor in the PR body
    — **Why:** Ticket spot-check AC; parse-level schema validation is the floor (pwsh/docker precedent), a real v2 load is the ceiling.
    — **Done when:** all checks green (or CLI absent + parse-level pass noted for PR).
    — **Consumers affected:** none (verification).

## Technical Notes

- v2 auto-translates legacy keys today — this removes translation dependence (ticket framing). Hash churn across all 34 agents is deliberate and precedes #379.
- Order preservation is semantic: v2 evaluates last-match-wins; map entry order must survive parse → array → emit (review-proven at parse: action order + resource order stable, no integer-like keys in the census).
- `keysOf` (:123-126) drops `*` and ignores effect — the array reader replicates exactly or edges drift.
- Body-prose hits that must SURVIVE untouched: `opencode-tooling-subagent.md` :134 (`model:`), :137 (`prompt:`), :138 & :321 (`permission:`) — fenced YAML examples. Sweeps must scope to the frontmatter region (between first two `---`), never whole-file.
- readAgent copies raw content (source.mjs:57-62); injectModelLine filters `^model:` lines only (init.mjs:448-460, resolve-models.mjs:85-115, tui-primitives.mjs:186-193 same pattern) — none parse permission shapes; setup.sh touches counts/hashes only. Packs/apply-skill-profile operate on opencode.json arrays (different file).
- CI ordering safe: release.yml runs on push→main and pull_request→main/dev only; intermediate feat-branch pushes run nothing; PR checks evaluate the merged snapshot (review-verified).
- Registry top-level keys: `$comment`, `generatedAt`, `counts`, `agents`, `skills` — there is no `__meta` field; only `generatedAt` is volatile.

## Dependencies

- Branch cut from `816d903` (includes #378 installer split, #377 targets).
- Must land BEFORE #379 (Phase 5) — normalization rewrites all 34 agent hashes first, avoiding a spurious mass "34 agents updated" event on first `update`.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Parser sequence extension regresses pre-normalization registry | 1.1 gate: `--check` green on the UN-normalized tree before proceeding |
| Registry edge drift (requiresSkills/delegatesTo) | Reader flips with files in 1.3; `--check` + count assertions + fixture spot (17/4) in the phase gate |
| Census-invisible permission shape mangles an agent | Normalizer fail-loud + dry-run + round-trip deep-compare (1.2) |
| Emitter churns non-permission frontmatter (folded descriptions) | In-place block replacement only; other FM lines + body byte-identical; phase-gate hunk confinement check |
| Rule order flipped → different allow/deny outcome | Insertion-order iteration at parse+emit; 4.1 order-assertion on `mcp:*` deny after `*` allow |
| Bats suite red from legacy-map assertions | 1.4 rewires all 8 blocks in the same phase; phase gate runs the 3 affected files |
| Docs teach stale spelling post-landing | 3.2 sweep with explicit exempt list (user-config contexts stay) |
| Real v2 load unavailable on runner | Parse-level schema validation floor; noted in PR body (pwsh/docker precedent) |
