# PLAN: Fix documentation drift in README and AGENTS.md

**Branch**: feat/615
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/615
**Base**: main

## Acceptance Criteria
- [ ] README preset table lists all 10 presets in `installer/presets/` (names match `--preset` values); `review` row states 26 skills
- [ ] Every `setup.sh` flag and `setup.ps1` param appears in the full setup reference; `--select` no longer prose-only
- [ ] `setup.sh` subcommands documented (one line or short table)
- [ ] AGENTS.md portability contract target list includes `zcode` and `copilot`
- [ ] README directory tree includes `CHANGELOG.md` and `CONTRIBUTING.md`
- [ ] Doc-only change — no counts, frontmatter, or registry changes (135 skills / 34 agents, post-#614)

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
- [ ] **1.1** Add the `inline-workers` row to the README §3 preset table and correct the `review` row count 31 → 26
    — **Why:** `installer/presets/` ships 10 packs but the table documents 9; `#614` shrank `pack-review.json` 25 → 21 direct (closure re-verified at 26), leaving the count stale.
    — **Done when:** the table has 10 rows whose names equal the `installer/presets/` stems; the `review` row reads "26 skills"; the table block contains `inline-workers`.
    — **Consumers affected:** `opencode-init --preset` users.
- [ ] **1.2** Add the 9 missing flag rows (bash + PowerShell columns) and a subcommands line to the "Full setup reference" section
    — **Why:** the section claims "every flag" but omits `--preset`, `--save-preset`, `--list-items`, `--select`, `--peonping`, `--enable-auto-update` (removed), `--disable-auto-update`, `--schedule-update`, `--check-update`; the subcommands `install | update | rollback | peonping | plan | check-catalog` are documented nowhere.
    — **Done when:** a scripted cross-check finds every `setup.sh` case-arm flag and every `setup.ps1` param name in the section, and the subcommand list appears verbatim.
    — **Consumers affected:** `setup.sh` users running headless/scripted deploys.
- [ ] **1.3** Extend the AGENTS.md § Portability contract target list to `claude|agents|kimi|kilo|zcode|copilot`
    — **Why:** § Repository Purpose lists all 7 targets (incl. #581 zcode/copilot); the portability section's parenthetical still names 4, so reviewers enforce against an incomplete list.
    — **Done when:** the portability contract line contains `zcode` and `copilot`.
    — **Consumers affected:** skill authors; portability review enforcement.
- [ ] **1.4** Add `CHANGELOG.md` and `CONTRIBUTING.md` entries to the README directory tree
    — **Why:** both files exist at the repo root and are linked elsewhere in the README, but the tree block omits them.
    — **Done when:** the tree code block lists both files.
    — **Consumers affected:** none (orientation doc).
- [ ] **1.5** Run the scripted documentation cross-check as the ticket exit gate
    — **Why:** doc-only change — the cross-check IS the gate; it proves ACs 1–5 mechanically and the full tier satisfies the pipeline's exit-gate citation.
    — **Done when:** exit gate memo `GATE <sha> tier=full` appended with all cross-check asserts passing.
    — **Consumers affected:** none (verification).

## Technical Notes

Exact content for each fix — execution is mechanical from here.

**1.1 — preset table.** Insert after the `research` row:

```markdown
| `inline-workers` | Inline delegation family — `plan-execution-inline-skill` + the testing/linting/documentation/responsive-audit inline skills and their knowledge-skill closure; companion to `/run-plan-v2` and `/run-worktree-pipeline-v2` |
```

Change `review` row: `+ 31 skills` → `+ 26 skills`.

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
