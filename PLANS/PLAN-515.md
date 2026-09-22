# PLAN: Portability guard test and docs sync

**Branch**: feat/515
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/515
**Base**: main

## Acceptance Criteria
- [ ] Guard passes on the current tree and fails on a seeded violation
- [ ] Full bats suite green; `node installer/build-registry.mjs --check` clean
- [ ] README + LEARNINGS updated

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `tests/test_portability.bats` (new) | #510 contract + #511/#512 delivered token/forms + #514 metadata keys (all merged) | CI (Run bats tests), skill authors | med |
| `skills/agent-introspection-debugging-skill/SKILL.md:100` | #510 merged contract | skill authors (stale-claim fix from #512 review fold-in) | low |
| `README.md` (portability paragraph) | #510–#514 merged | installers/authors | low |
| LEARNINGS | — | future sessions | low |

## Implementation Phases

### Phase 1: the guard

- [ ] **1.1** Write `tests/test_portability.bats` (root overridable via `PORTABILITY_ROOT` for seeded-violation checks) with 4 tests: (a) no `.opencode/skills` literals in `skills/**/SKILL.md`; (b) every SKILL.md mentioning `background: true` contains an `Other/none` fallback row; (c) every SKILL.md matching unix idioms (`xvfb|pkill|\$DISPLAY`) declares `os: "linux…"` in frontmatter; (d) every frontmatter `os:`/`harness:` line matches the canonical authoring form `^  (os|harness): "[a-z0-9]+(, [a-z0-9]+)*"$` (Mode R ruling).
    — **Why:** rules 1–2 of the portability contract need mechanical enforcement; rule 3 stays review-enforced (per #514-linked scope note on the issue).
    — **Done when:** `bats tests/test_portability.bats` green on the current tree.
    — **Consumers affected:** skill authors; CI.
- [ ] **1.2** Seeded-violation verification: build a fixture tree at `/tmp/opencode/portability-seed/` (one violating SKILL.md per rule: a literal path, a `background: true` without fallback, `xvfb` without `metadata.os`, `os: [linux]` unquoted) and run `PORTABILITY_ROOT=<fixture> bats tests/test_portability.bats` — all 4 must fail; then run without the override — all must pass.
    — **Why:** a guard that cannot fail is decoration (mirror of test_skill_isolation's canary discipline).
    — **Done when:** seeded run shows 4 failures; clean run shows 4 passes.
    — **Consumers affected:** none (fixture under /tmp).

### Phase 2: docs sync

- [ ] **2.1** `skills/agent-introspection-debugging-skill/SKILL.md:100` — scope the stale metadata claim: "the v2 frontmatter contract **at the time** reserved metadata sub-keys `protocol`/`pattern` (pre-#510; now `protocol`, `pattern`, `os`, `harness`)".
    — **Why:** strongest remaining teacher of the superseded rule (#512 review fold-in).
    — **Done when:** the present-tense "only" claim is gone.
    — **Consumers affected:** skill authors reading the removal note.
- [ ] **2.2** `README.md` — add a short "Skill portability" paragraph: binding-block convention, `metadata.os`/`metadata.harness`, installer warnings, pointer to AGENTS.md §Portability contract.
    — **Why:** the ticket's docs-sync AC; user-facing entry point for the conventions.
    — **Done when:** paragraph present and factually aligned with the contract.
    — **Consumers affected:** README readers.

### Phase 3: LEARNINGS + exit gate

- [ ] **3.1** LEARNINGS: capture the guard decision (what rules 1–2 enforce, the `Other/none` token, the authoring-form regex, the exemptions — installer/tests/README/opencode_app docs are legitimate install-destination references) + append the index entry; verify artifacts after scripted writes (per the #514 heredoc anti-pattern).
    — **Why:** the conventions decision and its enforcement surface must be recallable.
    — **Done when:** learning file exists, markdown-only, index entry present.
    — **Consumers affected:** future sessions.
- [ ] **3.2** Full exit gate: entire bats suite (incl. the new guard) + `build-registry --check` + count checks; final registry untouched (no frontmatter edits in this ticket — assert byte-identical).
    — **Why:** ticket exit gate runs full unconditionally.
    — **Done when:** suite green incl. 5 new guard tests; --check exits 0.
    — **Consumers affected:** installer, CI.

## Technical Notes
- Guard sweeps `skills/**/SKILL.md` only — repo-root docs, installer code, tests, opencode_app, and THIRD_PARTY_LICENSES legitimately reference `.opencode/skills/` as real install destinations (census from #511).
- Known follow-up (out of scope, tracked in the epic): unix `/tmp` idioms remain in cad-gcode/cad-implicit/uiux-review snippets (#513 review) — the guard does not police `/tmp`; they are declaration-class, not path-bug class.
- `PORTABILITY_ROOT` override is also how CI could reuse the guard for fixture-based regression tests later.

## Dependencies
- blocked-by: #510, #511, #512, #513, #514 (all merged).

## Risks & Mitigation
- *Guard false-positives on future legit mentions* → tests match the delivered spellings (census-derived), `Other/none` token case-insensitive per Mode R; seeded fixtures pin the intended failure modes.
- *Docs drift vs contract* → README paragraph links AGENTS.md as source of truth; no second full spec.
