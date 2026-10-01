# PLAN: document skill-allow workflow + enforce README count literals

**Branch**: feat/659
**Issue**: https://github.com/darellchua2/civiltekk-skills/issues/659
**Base**: main

## Acceptance Criteria

- [ ] README carries an "allowing an installed skill" subsection: deny-all-first mechanics, the `{"action":"skill","resource":"<name>","effect":"allow"}` JSON shape, reconcile-via-`setup.sh` flow, `--skill-profile full` alternative
- [ ] The section links the two LEARNINGS entries as the deeper checklist
- [ ] `test_count_drift.bats` derives the skill count + lean length mechanically and asserts README's count literals match both
- [ ] Negative fixture: a deliberately stale literal fails the new test (the test proves it can fail)
- [ ] Full guard suite green (52-file bats suite, registry drift check)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `README.md` Skill-Profiles-adjacent subsection (edited) | LEARNINGS entry files exist on this branch (tracked: `LEARNINGS/patterns/command-referenced-skills-need-deploy-allowlist-entries.md`, `LEARNINGS/conventions/add-skill-deploy-checklist.md`) | humans; the new drift test (2.1 pattern-pins README count contexts) | low |
| `tests/test_count_drift.bats` (extended, 2 new @test blocks + helper) | README count contexts stable (1.1 must not rename them) | CI (`release.yml` runs every `tests/*.bats`); future skill-adding PRs (the enforcement this ticket exists for) | low |
| nothing in `deploy/` or `installer/` | — | — (deliberate: docs + test only, no behavior change) | low |

## Implementation Phases

### Phase 1: README section

- [ ] **1.1** Add a subsection directly under the Skill Profiles block (after the `--skill-profile` command examples and the #481 note, before the next `###` heading): title `#### Installed a skill the primary session can't see?` with: (a) the mechanism (lean deploys a skill deny-all-first allowlist — a skill not in the allow list is invisible to primary sessions even though it is on disk); (b) the per-skill fix — add `{"action": "skill", "resource": "<skill-name>", "effect": "allow"}` to `deploy/opencode.json` `permissions` (keep the shipped file as source of truth) and re-run `./deploy/setup.sh`, ACCEPTING the config copy when prompted (stale allow rules are reconciled only on an accepted copy); (c) the wholesale alternative `./deploy/setup.sh --skill-profile full`; (d) links to `LEARNINGS/patterns/command-referenced-skills-need-deploy-allowlist-entries.md` and `LEARNINGS/conventions/add-skill-deploy-checklist.md` as the deeper checklist. Do NOT alter any existing count literal or the `#481` interim note.
    — **Why:** the ticket's user-facing gap — installation is documented, the allow step is not; twice-hit incident class with two learnings encoding it.
    — **Done when:** the subsection exists with all four elements; `grep -c "effect\": \"allow\"\|effect.*allow" README.md` gains ≥1 hit in the new block; zero existing count literals changed (`git diff README.md` shows only the new block + its heading); both LEARNINGS link targets exist (`test -f` both).
    — **Consumers affected:** humans; the new drift test reads README (unchanged contexts).

### Phase 2: drift-test extension

- [ ] **2.1** Extend `tests/test_count_drift.bats` with a parameterized helper `readme_count_assert <readme-path>` plus two @test blocks: (a) `readme_skill_total_matches_disk` — derive `disk=$(find skills -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')` (the SAME derivation shape as the file's existing `skill_count_matches_disk` — one concept, one derivation) and assert the five pinned count contexts in the given README carry exactly that number: `**N ready-to-load skills`, `+ N skills.`, `# N skill directories`, `N skills stay on disk`, `**Skill catalog — N skills by category`, `Current count: **N**`; (b) `readme_primary_visible_matches_lean` — derive `lean=$(node -e "console.log(require('./deploy/skill-profiles.json').lean.length)")` and assert `(N primary-visible skills` matches. All greps pinned to their context phrases (never bare numbers) so non-count `123`s elsewhere can never false-green or false-red.
    — **Why:** the ticket's enforcement half — #630 proved hand-swept literals rot; only a test that derives the number makes every future skill-adding PR self-checking.
    — **Done when:** `bats tests/test_count_drift.bats` green with the two new tests listed ok, on the unmodified README.
    — **Consumers affected:** CI release.yml; future skill-adding PRs.
- [ ] **2.2** Negative fixture `readme_stale_literal_fails`: copy README to a temp file, `sed` one pinned context to `N-1`, run the same `readme_count_assert` helper against the corrupted copy, and assert it FAILS (non-zero) — the test-proves-it-can-fail guard, mirroring `skill_profiles.bats` #5's phantom-rule fixture.
    — **Why:** a drift test that cannot fail is decoration (the #423/#512 false-green class); the fixture is the mechanical proof of failure capability.
    — **Done when:** the fixture test is green (i.e., the corrupted copy correctly fails the helper) and stays green in CI.
    — **Consumers affected:** CI; reviewers trusting the guard.

### Phase 3: exit gate

- [ ] **3.1** Run the full gate on the final tree: lint axes (`node --check installer/*.mjs`, `jq . package.json`, tarball guard), build (`node installer/build-registry.mjs --check` — no drift expected: no frontmatter touched), full unit suite (`for f in tests/*.bats`), and the final `grep -n "^- \[ \]"` PLAN residue check.
    — **Why:** the ticket exit gate runs full unconditionally; this change touches a CI-consumed test file (anchor).
    — **Done when:** all axes green, zero unchecked PLAN boxes; append the `GATE <sha> tier=full` memo for the final implementation SHA.
    — **Consumers affected:** CI; the PR citation.

## Technical Notes

- **Pattern-pinned greps only** (case-sensitive-grep-gates-false-green + the pinned-context rule): every count assertion anchors its number to a context phrase; no bare `\bN\b` sweeps over README prose.
- **No behavior change**: deploy/, installer/, and setup.sh are untouched — this is docs + test only; the registry drift check must stay green with zero regeneration (no frontmatter touched).
- **LEARNINGS link targets are tracked files** (both negated in `.gitignore`) — verify existence in-tree before linking (1.1 Done-when covers it); if a target is missing on a future base, the subsection link — not the file — is what breaks, so link text carries the full path.
- **Count contexts are load-bearing for 2.1**: if a future PR rewords a README count phrase, the pinned grep fails loudly → update the helper's pinned phrase list in the same PR (self-documenting contract).

## Dependencies

None. No `blocked-by` refs.

## Risks & Mitigation

- **Pinned-phrase drift** (README rewording breaks the helper) → the failure names the phrase; helper comment states the update-in-same-PR contract.
- **Negative fixture flakiness in CI** (temp-file handling) → mirror the existing `TEST_HOME`/mktemp patterns from `skill_profiles.bats`.
- **Base moving again mid-run** (third time today) → the pipeline's rebase-re-gate path already proven on #654; reuse it verbatim if 10a blocks.
