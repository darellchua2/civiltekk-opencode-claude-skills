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

- [x] **1.1** Write `tests/test_portability.bats` (root overridable via `PORTABILITY_ROOT` for seeded-violation checks) with 4 tests: (a) no `.opencode/skills` literals in `skills/**/SKILL.md`; (b) every SKILL.md mentioning `background: true` contains an `Other/none` fallback row; (c) every SKILL.md matching unix idioms (`xvfb|pkill|\$DISPLAY`) declares `os: "linux…"` in frontmatter; (d) every frontmatter `os:`/`harness:` line matches the canonical authoring form `^  (os|harness): "[a-z0-9]+(, [a-z0-9]+)*"$` (Mode R ruling).
    — **Why:** rules 1–2 of the portability contract need mechanical enforcement; rule 3 stays review-enforced (per #514-linked scope note on the issue).
    — **Done when:** `bats tests/test_portability.bats` green on the current tree.
    — **Consumers affected:** skill authors; CI.
    — **Done:** guard written with 4 tests (literals, background fallback, unix idioms→os, authoring form); green on current tree; files: tests/test_portability.bats; fixes: bats 1.13-env lacks `fail` helper — used return-1 + stderr idiom- [x] **1.2** Seeded-violation verification: build a fixture tree at `/tmp/opencode/portability-seed/` (one violating SKILL.md per rule: a literal path, a `background: true` without fallback, `xvfb` without `metadata.os`, `os: [linux]` unquoted) and run `PORTABILITY_ROOT=<fixture> bats tests/test_portability.bats` — all 4 must fail; then run without the override — all must pass.
    — **Why:** a guard that cannot fail is decoration (mirror of test_skill_isolation's canary discipline).
    — **Done when:** seeded run shows 4 failures; clean run shows 4 passes.
    — **Consumers affected:** none (fixture under /tmp).

### Phase 2: docs sync

    — **Done:** seeded fixture (literal + background-without-fallback + xvfb-without-os + os: [linux]) → all 4 tests FAIL under PORTABILITY_ROOT; clean tree → 4/4 pass; files: none (fixture under /tmp/opencode/portability-seed); fixes: none- [x] **2.1** `skills/agent-introspection-debugging-skill/SKILL.md:100` — scope the stale metadata claim: "the v2 frontmatter contract **at the time** reserved metadata sub-keys `protocol`/`pattern` (pre-#510; now `protocol`, `pattern`, `os`, `harness`)".
    — **Why:** strongest remaining teacher of the superseded rule (#512 review fold-in).
    — **Done when:** the present-tense "only" claim is gone.
    — **Consumers affected:** skill authors reading the removal note.
    — **Done:** stale present-tense claim scoped 'at the time … pre-#510' with the current four sub-keys named; files: skills/agent-introspection-debugging-skill/SKILL.md; fixes: none- [x] **2.2** `README.md` — add a short "Skill portability" paragraph: binding-block convention, `metadata.os`/`metadata.harness`, installer warnings, pointer to AGENTS.md §Portability contract.
    — **Why:** the ticket's docs-sync AC; user-facing entry point for the conventions.
    — **Done when:** paragraph present and factually aligned with the contract.
    — **Consumers affected:** README readers.

### Phase 3: LEARNINGS + exit gate

    — **Done:** Skill Portability section added before Testing & Development (3 conventions + contract pointer + guard reference); files: README.md; fixes: none- [x] **3.1** LEARNINGS: capture the guard decision (what rules 1–2 enforce, the `Other/none` token, the authoring-form regex, the exemptions — installer/tests/README/opencode_app docs are legitimate install-destination references) + append the index entry; verify artifacts after scripted writes (per the #514 heredoc anti-pattern).
    — **Why:** the conventions decision and its enforcement surface must be recallable.
    — **Done when:** learning file exists, markdown-only, index entry present.
    — **Consumers affected:** future sessions.
    — **Done:** guard-decision learning captured (4 checks, token, exemptions, PORTABILITY_ROOT fixtures); artifact verified markdown-only + index entry present (per #514 heredoc anti-pattern); files: LEARNINGS/decisions/portability-guard-enforces-rules-1-2.md, LEARNINGS/_index.md; fixes: none- [x] **3.2** Full exit gate: entire bats suite (incl. the new guard) + `build-registry --check` + count checks; final registry untouched (no frontmatter edits in this ticket — assert byte-identical).
    — **Why:** ticket exit gate runs full unconditionally.
    — **Done when:** suite green incl. the new guard tests; --check exits 0.
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
    — **Done:** full suite 533/533 (529 + 4 guard tests; 5 after review-fix canary); --check exits 0; registry byte-identical (no frontmatter edits); files: none (verification); fixes: none
## Gate Trace

GATE 77f4aa0 tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a
Note: lint axis = guard probes + seeded-violation proof; build = build-registry --check; the post-commit PLAN-only push is tree-equivalent; CI is the unconditional re-run.

### Phase 4: Review fixes (post-Step-9)

- [x] **4.1** Refute the review's BLOCK with tree evidence: playwright carries `metadata.os: "linux"` at feat/515 HEAD (merged via #514/PR #529); guard runs 5/5 green on the real worktree. The reviewer's cwd was a stale main checkout.
    — **Why:** the BLOCK claimed test 3 cannot pass and the green claim was unreliable — disproven by re-running on the branch.
    — **Done when:** fresh guard run + frontmatter capture recorded in this PLAN.
    — **Consumers affected:** none.
    — **Done:** frontmatter captured (os: "linux" present); guard 4/4 then 5/5 green; files: none (evidence record); fixes: none
- [x] **4.2** Guard v2: regex-inversion canonical-form check (was case-globs), shared `frontmatter_lines` awk slicer (was head -15), non-vacuous sweep canary, `_archived/` exclusion; README per-rule enforcement attribution (rules 1–2 guard, rule 3 review).
    — **Why:** review Majors (glob under-implementation, wrong extractor) + NOTEs (over-attribution, vacuous-pass, archived scope).
    — **Done when:** 5/5 clean; seeded fixture still fails the 4 rule checks; README wording per-rule.
    — **Consumers affected:** skill authors (guard output now names non-canonical lines).
    — **Done:** all applied; files: tests/test_portability.bats, README.md, LEARNINGS/*; fixes: glob→regex, slicer dedupe, canary, attribution

## Gate Trace (review-fix)

GATE 5d2b248 tier=full lint=t typecheck=n.a build=t unit=t e2e=n.a
