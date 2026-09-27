# PLAN: Fix documentation drift in README and AGENTS.md

**Branch**: feat/615
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/615
**Base**: main

## Acceptance Criteria
- [x] README preset table lists all 10 presets in `installer/presets/` (names match `--preset` values); `review` row states 21 skills
- [x] Every `setup.sh` flag and `setup.ps1` param appears in the full setup reference; `--select` no longer prose-only
- [x] `setup.sh` subcommands documented (one line or short table)
- [x] AGENTS.md portability contract target list includes `zcode` and `copilot`
- [x] README directory tree includes `CHANGELOG.md` and `CONTRIBUTING.md`
- [x] Doc-only change — no counts, frontmatter, or registry changes (119 skills / 34 agents, post-#616 — the ticket body said 135 pre-#616; README counts stay 119/67 untouched)

## Dependency & Consumer Map

_Before writing steps, list each touched file/module and who consumes it._

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `README.md` §3 preset table | `installer/presets/pack-*.json` (row source of truth) | `opencode-init --preset` users; catalog readers | low |
| `README.md` Full setup reference table | `deploy/setup.sh --help`, `deploy/setup.ps1` param block | `setup.sh` users (headless/scripted deploys) | low |
| `AGENTS.md` § Portability contract | `installer/init.mjs` `TARGETS` | skill authors; portability review enforcement | low |
| `README.md` directory tree | repo root listing | newcomers orienting in the repo | low |

Thin map — prose files only, no code consumers, no cross-module nodes.

## Implementation Phases

_Every step MUST be atomic and carry rationale. Reject any step missing a "Why"._

### Phase 1: Apply documentation fixes
- [x] **1.1** Add the `inline-workers` row to the README §3 preset table and correct the `review` row count 31 → 21 (re-derived at execution: Wave 2/#616 shrank pack-review 26 → 21; the ticket said 26 pre-#616)
    — **Why:** `installer/presets/` ships 10 packs but the table documents 9; `#614` shrank `pack-review.json` 25 → 21 direct (closure re-verified at 26), leaving the count stale.
    — **Done when:** the table has 10 rows whose names equal the `installer/presets/` stems; the `review` row reads "21 skills"; the table block contains `inline-workers`.
    — **Consumers affected:** `opencode-init --preset` users.
    — **Done:** inline-workers row added; review row 31->21 (re-derived from live pack: #616 shrank it past the ticket's 26); table = 10/10 shipped packs (cross-check asserted)
- [x] **1.2** Add the 9 missing flag rows (bash + PowerShell columns) and a subcommands line to the "Full setup reference" section
    — **Why:** the section claims "every flag" but omits `--preset`, `--save-preset`, `--list-items`, `--select`, `--peonping`, `--enable-auto-update` (removed), `--disable-auto-update`, `--schedule-update`, `--check-update`; the subcommands `install | update | rollback | peonping | plan | check-catalog` are documented nowhere.
    — **Done when:** a scripted cross-check finds every `setup.sh` case-arm flag and every `setup.ps1` param name in the section, and the subcommand list appears verbatim.
    — **Consumers affected:** `setup.sh` users running headless/scripted deploys.
    — **Done:** 10 flag rows added (9 planned + -v/--verbose found by the checker) + subcommands line at table end; checker also exposed 4 wrong PS parity columns on existing rows (-Mix/-Migrate/-CheckCatalog/-Force forward per setup.ps1:112-129) - fixed; mid-table insertion incident recovered (anchor assumed wrong row order)
- [x] **1.3** Extend the AGENTS.md § Portability contract target list to `claude|agents|kimi|kilo|zcode|copilot`
    — **Why:** § Repository Purpose lists all 7 targets (incl. #581 zcode/copilot); the portability section's parenthetical still names 4, so reviewers enforce against an incomplete list.
    — **Done when:** the portability contract line contains `zcode` and `copilot`.
    — **Consumers affected:** skill authors; portability review enforcement.
    — **Done:** portability list extended to claude|agents|kimi|kilo|zcode|copilot (AGENTS.md:93)
- [x] **1.4** Add `CHANGELOG.md` and `CONTRIBUTING.md` entries to the README directory tree
    — **Why:** both files exist at the repo root and are linked elsewhere in the README, but the tree block omits them.
    — **Done when:** the tree code block lists both files.
    — **Consumers affected:** none (orientation doc).
    — **Done:** CHANGELOG.md + CONTRIBUTING.md added to the directory tree
- [x] **1.5** Run the scripted documentation cross-check as the ticket exit gate
    — **Why:** doc-only change — the cross-check IS the gate; it proves ACs 1–5 mechanically and the full tier satisfies the pipeline's exit-gate citation.
    — **Done when:** exit gate memo `GATE <sha> tier=full` appended with all cross-check asserts passing.
    — **Consumers affected:** none (verification).
    — **Done:** cross-check (case-arm-derived flag universe + ps1 param parity + pack/table + targets + tree + count-integrity): PASS all 6 ACs; full bats 615/615 exit=0 as insurance

## Technical Notes

Exact content for each fix — execution is mechanical from here.

**1.1 — preset table.** Insert after the `research` row:

```markdown
| `inline-workers` | Inline delegation family — `plan-execution-inline-skill` + the testing/linting/documentation/responsive-audit inline skills and their knowledge-skill closure; companion to `/run-plan-v2` and `/run-worktree-pipeline-v2` |
```

Change `review` row: `+ 31 skills` → `+ 21 skills`.

**1.2 — flag table rows** (match existing 3-column style):

```markdown
| `--preset <p>` | `-Preset <p>` | Restore a saved preset (models.json; deploy-plan.json only consumed together with `--select`) |
| `--save-preset <p>` | `-SavePreset <p>` | Save models.json + deploy-plan.json as a named preset |
| `--list-items` | `-ListItems` | Dump the deploy item catalog (skills/agents/…) |
| `--select` | `-Select` | Pick skills/agents/packs/plugins per item (interactive picker; emits a deploy plan) |
| `--peonping` / `-P` | `-Peonping` | Install PeonPing sound notifications only (menu option 5 as a flag) |
| `--enable-auto-update` | `-EnableAutoUpdate` | (removed) schedule updates externally, e.g. cron |
| `--disable-auto-update` | `-DisableAutoUpdate` | Disable automatic updates |
| `--schedule-update <s>` | `-ScheduleUpdate <s>` | Set update-check frequency: daily, weekly, monthly, manual (default) |
| `--check-update` | `-CheckUpdate` | Check for updates without installing |
```

Subcommands line (directly under the table):

```markdown
Subcommands (aliases over the flags): `install | update | rollback | peonping | plan | check-catalog`
```

**1.3 — AGENTS.md portability line (~line 93):** `--target claude|agents|kimi|kilo` → `--target claude|agents|kimi|kilo|zcode|copilot`

**1.4 — tree block:** insert before the `MIGRATION.md` line:

```markdown
├── CHANGELOG.md                 # Release history (semantic-release generated)
├── CONTRIBUTING.md              # Contribution guide (skill/agent authoring)
```

## Dependencies
None — no `blocked-by:` tickets.

## Risks & Mitigation
Docs-only change; the only real risk is introducing fresh drift while fixing existing drift. Mitigation: step 1.5's scripted cross-check asserts preset-table/pack parity, flag/param parity against both setup scripts, the AGENTS.md target list, and tree/root parity.

## Trace

GATE 9cf2cbe tier=full lint=- typecheck=- build=- unit=t e2e=n.a
WORK LOG — resumed a parked PLAN-only branch from another session (single docs commit, no PR); rebased onto ea7b1bc; corrected stale numbers (review 26->21 post-#616, base note 135->119); execution found 3 drift classes beyond the ticket (verbose flag, 4 PS parity columns, row-order anchoring incident).
