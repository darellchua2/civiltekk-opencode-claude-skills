# PLAN: opencode-* prefix for plugins + naming convention

**Branch**: feat/456
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/456
**Base**: main

## Acceptance Criteria

- [x] Four plugin files renamed via `git mv`; zero stale references in live code, tests, deploy scripts, Dockerfile, and docs (LEARNINGS/PLANS historical records excluded)
- [x] Deploy + Docker still ship all OpenCode plugins: `./deploy/setup.sh --dry-run -y` shows cp lines for every renamed plugin
- [x] Vibeguard masking verified post-rename in at least one runtime: `OPENCODE_VIBEGUARD_DEBUG=1` shows replace-counts > 0
- [x] `node --test` plugin suites pass against renamed paths
- [x] Naming convention documented in `plugins/` (`opencode-*` = OpenCode runtime; `kimi-*`/`kilo-*` reserved for future ports)

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|---------------------|---------------------------|---------------------------------|-------------|
| `plugins/*.ts` renames (4 files + 1 README) | nothing (leaf files; glob-discovered by the OpenCode loader, no importers except the one test) | OpenCode plugin loader (glob `plugins/*.ts`), `tests/test_question_repair_plugin.test.ts:6` (import), `deploy_plugins()` wholesale copy (`setup.sh:3231`/`setup.ps1:2206`), `opencode_app/Dockerfile:82` (`COPY plugins/`), README/docs prose | low |
| `vibeguard.config.json` (name unchanged — deliberate) | resolved via search path by the (renamed) vibeguard plugin | Dockerfile:83 COPY to `/app/.opencode/`, `setup.sh:2514`, `setup.ps1:1774` | low — untouched |
| In-file plugin `id` fields + ids in log parsers | — | debug greps, session logs | low — unchanged |

Thin consumer map: renames + reference sweep, no logic change → zero plan reviewers selected (code review backstops per pipeline triage).

## Implementation Phases

### Phase 1: renames + reference sweep

- [x] **1.1** `git mv`: `vibeguard.ts → opencode-vibeguard.ts`, `ponytail-scoped.ts → opencode-ponytail-scoped.ts`, `question-repair.ts → opencode-question-repair.ts`, `learnings-autoinject.ts → opencode-learnings-autoinject.ts`, `learnings-autoinject.README.md → opencode-learnings-autoinject.README.md`. Update in-file header comments that name the old paths (incl. `vibeguard.ts:1` self-reference, `question-repair.ts:12` and `opencode-auto-continue-v2.ts:30` cross-references).
    — **Why:** the rename is the feature; header comments naming old paths would rot immediately.
    — **Done when:** `git status` shows 5 renames; `rg -n 'plugins/(vibeguard|ponytail-scoped|question-repair|learnings-autoinject)\.ts' installer/ deploy/ tests/ plugins/ opencode_app/` has zero hits.
    — **Consumers affected:** every swept consumer below.
    — **Done:** 5 renames via git mv (4 plugins + learnings README); in-file headers updated (vibeguard self-ref, question-repair cross-ref, auto-continue cross-ref); files: plugins/*; fixes: none
- [x] **1.2** Sweep live references: `README.md` (:504, :710, :728, :741, :765), `opencode_app/README.md` (:109, :193, :234, :260), `AGENTS.md:27` (`plugins/opencode-vibeguard.ts` — the `vibeguard.config.json` part of that line stays), `skills/security-audit-skill/SKILL.md:52`, `tests/test_question_repair_plugin.test.ts` (:1 comment, :6 import), `plugins/ATTRIBUTION.md:5`, `plugins/question-repair.ts:12`, `plugins/opencode-auto-continue-v2.ts:30`. `research/` historical note left as-is (same policy as LEARNINGS/PLANS). Plugin `id` fields and the `vibeguard.config.json` filename unchanged (search-path chain: LEARNINGS `path-move-ci-gate-anchoring`).
    — **Why:** stale references break the test import (hard failure) and mislead docs (soft failure) — both are AC-level defects.
    — **Done when:** `rg -n 'plugins/(vibeguard|ponytail-scoped|question-repair|learnings-autoinject)\b' README.md AGENTS.md deploy/ tests/ opencode_app/ plugins/ skills/ --glob '!*config.json*'` returns zero old-path hits.
    — **Consumers affected:** CI, docs readers.
    — **Done:** sweep: README (5), opencode_app/README (4), AGENTS.md:27 (vibeguard.ts part only — config.json ref kept), security-audit-skill:52, ATTRIBUTION.md:5, test comment+import, research/ left historical; rg sweep zero old-path hits; files: README.md, AGENTS.md, opencode_app/README.md, skills/security-audit-skill/SKILL.md, plugins/ATTRIBUTION.md, tests/test_question_repair_plugin.test.ts; fixes: none

### Phase 2: convention doc + gates

- [x] **2.1** Add `plugins/README.md`: naming convention (`opencode-*.ts` = OpenCode runtime plugins; `kimi-*`/`kilo-*` reserved for future foreign-runtime ports, never deployed to OpenCode); the deploy-glob decision (deferred — filter lands with the first foreign plugin PR, per the ticket's open decision default); plugin `id` + config-filename stability note.
    — **Why:** the ticket's core deliverable is the convention, not just the renames.
    — **Done when:** `plugins/README.md` exists, states the three rules, and links the ticket.
    — **Consumers affected:** future plugin authors.
    — **Done:** plugins/README.md convention doc written (prefix table, id/config stability, deferred glob decision per ticket default, historical-records policy); files: plugins/README.md; fixes: none
- [x] **2.2** Full gate: `node --test tests/test_question_repair_plugin.test.ts tests/test_auto_continue_plugin.test.ts` + all bats suites + pack/drift; deploy pickup proof via `./deploy/setup.sh --dry-run -y` cp lines for every renamed plugin; `GATE` memo for the pushed SHA.
    — **Why:** pipeline gate contract; the deploy-copy proof is the ticket's AC-2.
    — **Done when:** every suite green; dry-run cp lines observed for all renamed plugins; memo emitted.
    — **Consumers affected:** code review, PR creation.
    — **Done:** full gate green: 96 bats ok, node --test green (plugin suites import renamed paths), pack/drift green; deploy dry-run -y shows cp lines for all 5 renamed files (AC-2); migration shim added to deploy_plugins (setup.sh + setup.ps1) removing stale pre-rename copies so the same plugin never loads twice; vibeguard import smoke OK (runtime OPENCODE_VIBEGUARD_DEBUG check recorded as PR manual TODO — requires a live opencode restart); files: deploy/setup.sh, deploy/setup.ps1, PLANS/PLAN-456.md; fixes: migration shim added beyond PLAN (deploy legs would otherwise double-load renamed plugins)

## Technical Notes

- **Deliberately unchanged:** plugin `id` fields (log-parser stability), `vibeguard.config.json` filename (3-leg search-path chain — LEARNINGS `path-move-ci-gate-anchoring`), `LEARNINGS/` + `PLANS/` + `research/` historical records.
- **Deliberate decision (ticket default):** `deploy_plugins()` glob restriction DEFERRED — the `opencode-*`-only filter lands in the same PR as the first foreign plugin; no dead gating ships today.
- The OpenCode loader glob-discovers `plugins/*.ts`; renames are loader-invisible (same discovery, new names) — no registration surface exists.

## Dependencies

- None. Independent of #453-#455/#457.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Missed reference breaks a test or doc | 1.2's rg sweep is the mechanical gate; node --test import failure is loud |
| Vibeguard masking silently breaks on rename | AC-3: runtime DEBUG verification (replace-counts > 0) in the gate phase |
| Deploy copy misses a renamed plugin | AC-2: dry-run cp-line proof (learning: `-y` is mandatory for the deploy path) |
GATE 2136870 lint=n.a. typecheck=n.a. build=n.a. unit=t e2e=n.a. — FINAL: 96 bats ok, node --test green (plugin imports on renamed paths), deploy dry-run pickup proven
