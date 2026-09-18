# PLAN: gate project models.json — no clobber of hand-authored config (#412)

**Branch**: feat/412
**Issue**: https://github.com/darellchua2/opencode-config-template/issues/412
**Base**: main (7fa6e71)

## Acceptance Criteria

From ticket #412 (owner ruling: configurator repo — never clobber config it didn't write):

- [x] bats: hand-authored `.opencode/models.json` survives `add --project` (stderr `conflict (skipped, use --force)` warning; content byte-identical)
- [x] bats: `--force` overwrites it and the rewritten manifest claims it (`modelsPath`)
- [x] bats: a previously-generated `models.json` re-installs silently (idempotent, no warning)
- [x] Manifest claims ownership ONLY of files actually written this run — a conflict-skipped `modelsPath`/`configPath` is recorded as `null`, so the warning repeats every run until `--force` (owner ruling: protection until force, not one-time; includes the pre-existing `configPath` twin; review CR-1 + requirements-gap answer applied in-branch)
- [x] Gate mirrors the adjacent `opencode.json` gate byte-for-byte in pattern (existsSync + prevManifest claim + `--force`); no content comparison, no new heuristics

## Dependency & Consumer Map

| Node (file/module) | Depends on (must precede) | Consumers (who depends on this) | Change risk |
|--------------------|---------------------------|---------------------------------|-------------|
| `installer/init.mjs` `writeInstall` models.json write (:404-412) | manifest already records `modelsPath` (:366) | `resolve-models.mjs --project-map` (:17, :26) reads `<project>/.opencode/models.json`; tests/init.bats; `models:` summary line (:425) | low |
| `prevManifest.modelsPath` | manifests written since inception record it (:366) | gate condition only | low |

## Implementation Phases

### Phase 1: Conflict gate + bats

- [x] **1.1** `writeInstall`: wrap the models.json write in the same gate shape as `opencode.json` (:400-404) — `modelsConflict = existsSync(modelsFile) && !(prevManifest.modelsPath === modelsFile)`; on conflict + `!force` print the identical `conflict (skipped, use --force)` stderr line with `relative(project, modelsFile)` and skip the write; write when absent, `--force`, or prevManifest claims the path. Move the `usedTiers`/`modelsMap` construction inside the write branch (dead on skip). `models:` summary line unchanged (the path is still the project's models file either way)
    — **Why:** The write at :412 is unconditional today — a hand-authored tier map is silently destroyed on every project install, violating the owner's no-clobber ruling and inconsistent with the ocFile gate directly above.
    — **Done when:** `node --check`; the three bats scenarios below pass.
    — **Consumers affected:** `resolve-models.mjs --project-map` (now sees a surviving hand-authored map — intended semantics); summary output unchanged.
- [x] **1.2** `tests/init.bats`: three cases, fixture `add explorer-subagent --project "$TMP_PROJ" --yes` with fake HOME (same idiom as #401 cases) — (a) seed `$TMP_PROJ/.opencode/models.json` with `{"tiers": {"fast": "hand/authored"}}`, install, assert stderr contains `conflict (skipped, use --force)` + `models.json`, file still contains `hand/authored` and not the default tier id; (b) rerun with `--force`, assert file carries the generated `$comment` and `$TMP_PROJ/.opencode/.opencode-init.manifest.json` `modelsPath` equals the file path; (c) install twice (no seed), second run's output contains no `conflict (skipped` and the file still has the generated tier value
    — **Why:** The ticket's acceptance is executable proof at all three gate outcomes (skip / force-claim / idempotent rewrite).
    — **Done when:** `bats tests/init.bats` green (28 cases).
    — **Consumers affected:** CI.

**Phase gate:** full bats suite green; registry `--check`; public `add --dry-run` unchanged (dry-run returns before any writes, :369-372).

## Technical Notes

- Back-compat (ticket §Back-compat note): projects whose manifest predates `modelsPath` (field written since inception, but defensively) — first re-install warns once, `--force` claims it, rewritten manifest records the path → subsequent runs silent. Call out in PR body.
- Deliberately NO content-equality escape hatch (`generated == existing → silent rewrite`): the ocFile gate has none; mirroring keeps one mental model. A hand-edited-then-reverted file warns until `--force` — acceptable noise.
- Existing tests unaffected: fresh `mktemp` projects have no models.json → `existsSync` false → write branch (today's behavior).

## Dependencies

- None. Closes #412.

## Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| Redeploy flows that relied on unconditional models.json refresh | setup.sh delegates user-scope (untouched); project-scope users re-claim with `--force` once — warning names the escape hatch |
| `models:` summary line printed even when skipped | Line points at the file's path, which still exists (hand-authored) — accurate either way |
