# PLAN: reconcile skill-allow rules on declined config copy

**Branch**: feat/625
**Issue**: https://github.com/darellchua2/civiltekk-opencode-claude-skills/issues/625
**Base**: main

## Acceptance Criteria
- [ ] Declining the config copy + redeploying after a skill rename converges the deployed permissions: shipped skill-allows present, dead-resource rules dropped, non-skill config preserved (models/mcp/theme/agent rules)
- [ ] `apply-skill-profile` lean application succeeds after a reconcile pass without manual config edits
- [ ] Dry-run: reconcile is previewable and mutates nothing under `--dry-run`
- [ ] Tests pin the reconcile semantics (rename scenario: old names dropped, new names added, custom rules preserved; deny-all-first ordering preserved)
- [ ] Doc-only elsewhere: no agents/skills/frontmatter changes (registry no-op)

## Dependency & Consumer Map

| Node | Depends on | Consumers | Risk |
|------|-----------|-----------|------|
| `deploy/apply-skill-profile.mjs` (new `--reconcile-shipped` + `--skills-dir` mode) | — | setup.sh declined-copy path; bats tests | med |
| `deploy/setup.sh` (SKIP_CONFIG_COPY branch wiring) | script mode | every declined-copy redeploy | med |
| deployed `opencode.json` permissions | reconcile | opencode runtime routing | high (user config — preserve strictly) |

## Implementation Phases

### Phase 1: reconcile mode in apply-skill-profile.mjs
- [ ] **1.1** Add `--reconcile-shipped <path>` + `--skills-dir <path>` + `--deployed-skills-dir <path>` mode to `deploy/apply-skill-profile.mjs`: read shipped + deployed configs; DROP deployed skill-allow rules whose `resource` has no `skills/<resource>/` dir under `--skills-dir` AND no dir under `--deployed-skills-dir`; ADD every shipped skill-allow rule missing from the deployed config; preserve the leading `{"action":"skill","resource":"*","effect":"deny"}` position and ALL non-skill rules (agents/mcp/models keys untouched — only the permissions array's skill-allow entries change)
    — **Why:** the declined-copy path leaves stale allow names; without migration the lean typo-guard dead-ends the deploy (observed 2026-09-27, Wave-1 renames)
    — **Done when:** a scratch deployed config missing a shipped allow + holding a dead resource reconciles to: shipped allow present, dead rule gone, models/mcp keys byte-preserved, deny-first intact
    — **Consumers affected:** setup.sh declined-copy path (Phase 2); user deployed configs
- [ ] **1.2** `--dry-run` support for the mode: print the would-be added/dropped rule names, write nothing
    — **Why:** the ticket's dry-run AC; matches setup.sh --dry-run gating
    — **Done when:** dry run prints both lists and exits 0 with the file unmodified (mtime/content)
    — **Consumers affected:** setup.sh --dry-run users
### Phase 2: setup.sh wiring + tests
- [ ] **2.1** In the `SKIP_CONFIG_COPY = true` branch after the resolver step: invoke the reconcile mode with `--shipped "$SOURCE_CONFIG" --config "$CONFIG_FILE" --skills-dir "${SOURCE_DIR}/skills"`, gated by `$DRY_RUN` → `--dry-run`; failures log_warn but do not abort the deploy (profile application remains the loud failure point)
    — **Why:** this is the exact path the Wave-1 rename broke; wiring here fixes every future rename/consolidation without user action
    — **Done when:** a scratch HOME with a pre-rename config + `--yes` declined-copy run converges (scripted in the test below)
    — **Consumers affected:** all declined-copy redeploys
- [ ] **2.2** New `tests/test_reconcile_skill_allows.bats`: (a) rename scenario — deployed config has `old-skill` allow, shipped has `civiltekk-new-skill` → reconcile adds new, drops old, preserves models/mcp/theme; (b) deny-first ordering preserved; (c) `--dry-run` mutates nothing; (d) end-to-end: reconcile then `apply-skill-profile --profile lean` succeeds with zero missing keys
    — **Why:** the ticket's semantics must be pinned, not eyeballed
    — **Done when:** the new bats file passes in isolation
    — **Consumers affected:** CI suite
### Phase 3: exit gate
- [ ] **3.1** Full `bats tests/` exit=0; `node installer/build-registry.mjs` no-op verified (no agents/skills change); README: no changes needed (the remediation hint stays accurate as the fallback); `GATE <sha> tier=full` memo
    — **Why:** pipeline exit-gate citation
    — **Done when:** suite green, registry clean, memo appended
    — **Consumers affected:** PR reviewer, watcher

## Technical Notes
- apply-skill-profile.mjs already has the permissions-parsing helpers (`skillAllows`, deny-first rebuild) — the reconcile mode reuses them; keep `--profile` and `--reconcile-shipped` mutually exclusive in argv validation.
- setup.sh `$SOURCE_CONFIG`/`$CONFIG_FILE`/`$SOURCE_DIR` are the established variables (see the config-copy step at ~:2962).
- The remediation hint in the typo-guard error remains: reconcile handles renames, but a genuinely typo'd lean key still needs the hint.

## Dependencies
None. Independent of #624/#623. #617 (other session) touches the pipeline skill, not deploy/.

## Risks & Mitigation
- **Overzealous dropping** → a rule survives if the resource exists in EITHER the repo skills dir OR the deployed skills dir (user-authored customs live only in the latter); only true orphans (deleted everywhere) drop.
- **Deny-first violation** → rebuild preserves rule order: non-skill rules first (unchanged), then deny-all, then sorted allows (apply-skill-profile's proven shape).
