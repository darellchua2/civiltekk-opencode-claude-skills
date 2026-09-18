# docs/registry.json is a gitignored build-site artifact, never a build-registry output

- **Category**: solution
- **Confidence**: 1.0
- **Scope**: project
- **Added**: 2026-09-19 (#402 architecture review)

## Symptom

Plans/tickets ask for "`installer/registry.json` + `docs/registry.json`
rebuilt via `build-registry.mjs`". The docs copy can never satisfy that:
`build-registry.mjs` writes ONLY `installer/registry.json` (OUT_FILE,
installer/build-registry.mjs:45).

## Cause

`docs/registry.json` is emitted by `installer/build-site.mjs`
(:5-8 header, :143 write) for GitHub Pages and is **gitignored**
(.gitignore:32-33); CI regenerates it from the installer registry at
release (release.yml:151).

## Solution

Scope any registry step to `installer/registry.json` + the `--check` drift
guard (`node installer/build-registry.mjs --check`). Treat
`docs/registry.json` as an out-of-scope release artifact — never commit it,
never hand-generate it; optionally run `build-site.mjs` locally to preview.
Write ACs so the done-when is CI-verifiable, not phantom.

## Evidence

#402 (feat/402, 2026-09-19): architecture review flagged the unachievable
done-when; requirements relay (Mode R) confirmed; PLAN-402 AC + step 5.1
rewritten to installer-only wording; issue #402 body amended to match.

Related: `patterns/skill-add-count-sync-blast-radius.md`.
