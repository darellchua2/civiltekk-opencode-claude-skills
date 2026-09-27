# PLAN: Declare autoresearch loop→core requiresSkills edges

**Branch**: feat/602
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/602
**Base**: main

## Acceptance Criteria

- [x] `installer/dependency-map.json` carries `requiresSkills` entries for all three loop skills (`autoresearch-code-skill`, `autoresearch-ml-skill`, `autoresearch-research-skill` → `autoresearch-core-skill`)
- [x] `tests/test_skill_isolation.bats` allowlist mirrors the edges via a new `HANDOFF3_OWNERS`/`HANDOFF3_TARGETS` pair (multi-owner guard extension)
- [x] `tests/test_requires_skills.bats` exact-match pin extended to include HANDOFF3; one new live test proves `add autoresearch-ml-skill` auto-installs core with the notice
- [x] `AGENTS.md` §Skill Isolation Contract records the third declared exception group
- [x] `bats tests/` green
- [x] `installer/registry.json` deliberately NOT rebuilt (requiresSkills there is agent-frontmatter-sourced; dependency-map is read directly by init.mjs)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/dependency-map.json` | — | `installer/init.mjs` L280 (runtime auto-install), `tests/test_requires_skills.bats` exact-match pin, `tests/test_skill_isolation.bats` invariant comment | med |
| `tests/test_skill_isolation.bats` | map edit (lockstep) | CI bats suite; `test_requires_skills.bats` greps its HANDOFF vars | med |
| `tests/test_requires_skills.bats` | guard vars + map entries | CI bats suite | low |
| `AGENTS.md` (isolation contract prose, L23) | — | contributors + AI agents reading the contract | low |
| `installer/init.mjs` | — (data-driven) | none — no edit required | — |
| `installer/registry.json` | — (agent-frontmatter-sourced) | none — no rebuild required | — |

## Implementation Phases

### Phase 1: Declare the edges (map + guard)

- [x] **1.1** Add three `requiresSkills` entries to `installer/dependency-map.json` — `"autoresearch-code-skill": ["autoresearch-core-skill"]`, same for `-ml-` and `-research-`; extend the file's `$comment` to name `HANDOFF3_OWNERS`/`HANDOFF3_TARGETS` alongside HANDOFF1/2
    — **Why:** the map is the installer's edge source; without it `npx add <loop-skill>` ships a skill citing files it did not get
    — **Done when:** `python3 -c "import json; d=json.load(open('installer/dependency-map.json')); assert all(d['requiresSkills'].get(k)==['autoresearch-core-skill'] for k in ('autoresearch-code-skill','autoresearch-ml-skill','autoresearch-research-skill'))"` exits 0
    — **Consumers affected:** init.mjs auto-install path; test_requires_skills exact-match pin (updated in lockstep 1.2/2.1)
    — **Done:** three entries added + $comment extended; the python assertion exits 0; files: installer/dependency-map.json; fixes: none

- [x] **1.2** Extend `tests/test_skill_isolation.bats`: add `HANDOFF3_OWNERS="autoresearch-code-skill autoresearch-ml-skill autoresearch-research-skill"` + `HANDOFF3_TARGETS="autoresearch-core-skill"`; pass both as argv 5/6 to the sibling-paths test's python and fold them into `allowed` (`for o in owners3.split(): allowed[o] = set(targets3.split())`); update the file header comment
    — **Why:** the guard's allowlist is the contract's source of truth; three owners sharing one target cannot fit the single-owner shape, so the multi-owner pair is the minimal extension (anticipated by the ticket)
    — **Done when:** `bats tests/test_skill_isolation.bats` green with the new entries present, red if one loop skill's core citation is fenced
    — **Consumers affected:** test_requires_skills.bats test 5 (greps these vars — updated in 2.1)
    — **Done:** HANDOFF3 vars + header comment + test-3 argv/python fold; suite green (test 3 ok); files: tests/test_skill_isolation.bats; fixes: none

### Phase 2: Extend the installer tests

- [x] **2.1** Extend `tests/test_requires_skills.bats` test 5 (`requires_skills_map_entry_matches_isolation_guard_handoff_pair`): grep HANDOFF3_OWNERS/HANDOFF3_TARGETS from the guard and fold `owners3.split()` × `targets3.split()` into `expected`; update the file header comment
    — **Why:** the pin asserts `got == expected` — new map entries without this extension turn CI red, with it drift stays impossible
    — **Done when:** the test passes with the three new edges and fails if any one is removed from the map
    — **Consumers affected:** CI bats suite
    — **Done:** pin extended to fold HANDOFF3 (multi-owner), header updated; test 11 green; files: tests/test_requires_skills.bats; fixes: trailing impliesMcp argv index 6→8 (missed in first edit, caught by gate attempt 1)

- [x] **2.2** Add `requires_skills_autoresearch_loop_pulls_core`: `init.mjs add autoresearch-ml-skill --yes` in a tmp HOME must print `also installing required skill: autoresearch-core-skill` and create both skill dirs; update header comment to name the third handoff group
    — **Why:** live proof of the ticket's AC ("installer shows core pulled as prerequisite") — the existing tests only exercise the pptx edge
    — **Done when:** the new bats test passes in isolation (`bats tests/test_requires_skills.bats`)
    — **Consumers affected:** CI bats suite
    — **Done:** test added (ok 9), header names #602 group; files: tests/test_requires_skills.bats; fixes: none

### Phase 3: Contract prose + full gate

- [x] **3.1** Update `AGENTS.md` §Skill Isolation Contract (L23): record the third declared exception group — `{autoresearch-code, autoresearch-ml, autoresearch-research}-skill → autoresearch-core-skill` (#602 — the loop skills cite the core protocol host's references at runtime) — and the `HANDOFF3_OWNERS`/`HANDOFF3_TARGETS` multi-owner shape
    — **Why:** AGENTS.md documents "the two declared exceptions"; leaving it stale after adding a third group makes the contract lie
    — **Done when:** `grep -c 'HANDOFF3_OWNERS' AGENTS.md installer/dependency-map.json tests/test_skill_isolation.bats tests/test_requires_skills.bats` shows ≥1 in each
    — **Consumers affected:** all agents/contributors reading the isolation contract
    — **Done:** prose updated (three exception groups + HANDOFF3 multi-owner shape); grep shows 4/4 files; files: AGENTS.md; fixes: none

- [x] **3.2** Run the full gate: `bats tests/` (all files, incl. test_skill_isolation, test_requires_skills, skill_profiles, select_items, docling); confirm no registry change (`git status --porcelain installer/registry.json` empty); confirm skill count unchanged at 150
    — **Why:** the ticket exit gate must be tier=full green on the final tree before review/PR
    — **Done when:** bats suite exits 0; registry untouched; `ls -d skills/*/ | wc -l` = 150
    — **Consumers affected:** PR citation (`GATE <sha> tier=full`), reviewer
    — **Done:** exit=0, 633/633 ok, 0 failures; registry 0 changes; count 150; files: none (verification only); fixes: none

## Technical Notes

- The guard's test 3 receives owner/target pairs as argv (`"$HANDOFF1_OWNER" "$HANDOFF1_TARGETS" "$HANDOFF2_OWNER" "$HANDOFF2_TARGETS"`) — the extension adds argv 5/6; keep the heredoc python signature in sync (`sys.argv[1:7]`).
- Loop→core citations are prose (outside fences) today, which is why the guard never flagged the gap — the declaration is prophylactic for installer correctness, not a guard-fix for an existing violation.
- init.mjs notice prefix is pinned by test 1: `also installing required skill: <name>` — reuse verbatim.
- Phase commits land as: `fix(installer): declare autoresearch loop→core dependency edges (#602)` (1.x), `test(installer): pin autoresearch edges + live auto-install check (#602)` (2.x), `docs(agents): record the autoresearch handoff exception (#602)` (3.1 + 3.2 memo).

## Dependencies

None — no blocked-by; independent of #603/#604 (Wave merges must re-point nothing here; Wave 1 renames documentation-inline-skill only).

## Risks & Mitigation

- **Exact-match pin turns red if lockstep slips** → all four files (map, guard, requires-tests, AGENTS.md) change in this one branch; phase commits keep related files adjacent.
- **Multi-owner pair could be misread as a shape change** → documented in AGENTS.md + guard header as an extension of the uniform shape (owner-set → target-set), mirrored per-owner in the map.
- **Live installer test needs network-free execution** → init.mjs `add` copies from the repo checkout (no network); tmp-HOME pattern already proven by tests 1–4.

## Trace

WORK LOG — Phases 1+2 landed as one commit (deliberate deviation from the PLAN's per-phase commit split): the exact-match pin in test_requires_skills #5 makes map+guard+tests a lockstep unit; separate commits would push a red gate between them. Tier judgment: light (config+tests only; exit gate Phase 3 runs full).
GATE c3258f3 tier=light lint=- typecheck=- build=- unit=t e2e=n.a
GATE 03e8f9e tier=full lint=- typecheck=- build=- unit=t e2e=n.a
