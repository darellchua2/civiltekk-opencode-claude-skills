---
name: openapi-contract-adherence-skill
description: >-
  Detect OpenAPI contract changes, classify breaking vs additive, map consumer
  impact, generate migration plans (oasdiff). Triggers: openapi diff, api
  contract, breaking change, contract review, spec changed, regenerate client.
license: Apache-2.0
compatibility: opencode
category: Framework
---

## What I do

I help you detect, classify, and plan for OpenAPI spec changes across their
full consumer surface:

1. **Validate specs** — lint baseline and revision with `redocly` / `spectral` before diffing
2. **Diff with oasdiff** — produce changelog and breaking-change reports in markdown + JSON
3. **Classify changes** — map each change to severity (Breaking / Non-breaking / Additive / Cosmetic) and semver impact
4. **Map consumer impact** — locate SDK generator configs, direct fetch/axios/httpx call sites, and generated client files
5. **Generate dual-format report** — `CONTRACT_DIFF.md` (human-readable) + `CONTRACT_DIFF.json` (machine-readable)
6. **Emit PR-gate artifact** — the JSON is consumable by `pr-creation-workflow-skill` for automated label selection and merge gating

## When to use me

Use this skill when:

- An OpenAPI spec changed on a branch and you need to review the impact
- You want to detect breaking changes before merging
- You need a consumer-side migration plan (which files to update, which SDKs to regenerate)
- You want to classify changes for semver label selection (`major` / `minor` / `patch`)
- You are reviewing a PR that touches `openapi.yaml` / `openapi.json`
- You want to regenerate client SDKs after a spec change

**Trigger phrases**:

- "openapi diff"
- "api contract"
- "breaking change"
- "consumer update plan"
- "contract review"
- "spec changed"
- "regenerate client"

## Prerequisites

Install these tools before running the workflow. Version numbers verified as of 2026-06-21.

### oasdiff (primary diffing tool)

```bash
# Go binary (repo moved from tufin/oasdiff → oasdiff/oasdiff in 2024)
go install github.com/oasdiff/oasdiff@latest

# OR Homebrew
brew install oasdiff

# OR Docker fallback (no local install needed)
# Use :stable or a pinned version tag; avoid bare :latest which tracks main
# and may contain unreleased commits
docker pull tufin/oasdiff:stable
```

**Version pinning** (recommended): pin to a specific release to keep binary and
Docker output schemas consistent. As of 2026-06-14, latest stable is **v1.19.1**.

```bash
go install github.com/oasdiff/oasdiff@v1.19.1
# OR
docker pull tufin/oasdiff:v1.19.1
```

### Spec linters

```bash
# Primary linter (latest 2.34.0; requires Node >=22.12.0)
npm i -g @redocly/cli

# Alternative linter (latest 6.16.0)
npm i -g @stoplight/spectral-cli
```

### SDK generators

**Node.js requirement**: oasdiff itself is Go-based (no Node needed), but the SDK
generators below require **Node >=22.x**.

```bash
# TypeScript-first generators
npm i -D @hey-api/openapi-ts              # latest 0.98.2; Node >=22.18.0
npm i -D orval                             # latest 8.18.0; Node >=22.18.0
npm i -D @openapitools/openapi-generator-cli  # latest 2.39.0; Node >=22.0.0

# Python server-side stubs
pip install fastapi-code-generator          # latest 0.7.0; CLI binary is `fastapi-codegen`
# NOTE: the PyPI package is `fastapi-code-generator` (with `-rator`).
#       There is no `fastapi-codegen` package on PyPI.
```

## Step 1: Discover Specs

Establish the baseline (original) and revision (changed) OpenAPI specs.

### Git-based baseline (default)

```bash
# Baseline: spec at the merge-base of current branch and main
git show $(git merge-base HEAD main):openapi.yaml > /tmp/openapi-base.yaml

# Revision: spec in the working tree (or staged)
cp openapi.yaml /tmp/openapi-revision.yaml
```

### Manual baseline (non-git or custom)

If the repo isn't git-tracked or you want a specific baseline:

```bash
# User supplies both paths
BASE_SPEC="/path/to/baseline-openapi.yaml"
REVISION_SPEC="/path/to/current-openapi.yaml"
```

### Monorepo handling (multiple specs)

For repos with per-service specs, use glob discovery and iterate:

```bash
# Discover all OpenAPI specs in the repo
SPECS=$(find . -name "openapi.yaml" -o -name "openapi.yml" -o -name "openapi.json" \
  | grep -v node_modules | grep -v _archived)

# For each spec, produce per-service reports
for spec in $SPECS; do
  service=$(dirname "$spec" | sed 's|^\./||;s|/|-|g')
  # ... run Steps 2-6 for each (base, revision) pair ...
  # Output: CONTRACT_DIFF.${service}.md / CONTRACT_DIFF.${service}.json
done

# Plus an aggregated summary: CONTRACT_DIFF.summary.md
```

## Step 2: Validate

Lint both specs **before** diffing. oasdiff on malformed specs produces
misleading diffs. Surface validation errors as a hard stop.

### redocly (primary)

```bash
# Lint both specs; --format github-actions produces PR-inline annotations
redocly lint /tmp/openapi-base.yaml --format github-actions
redocly lint /tmp/openapi-revision.yaml --format github-actions

# Exit code != 0 means validation failed — STOP and fix spec errors first
```

### spectral (alternative)

```bash
spectral lint /tmp/openapi-base.yaml
spectral lint /tmp/openapi-revision.yaml
```

If either spec fails validation, stop and report the errors. Do not proceed to
Step 3 (diffing) on invalid specs.

## Step 3: Diff

Run three `oasdiff` invocations. These produce **intermediate** artifacts that
Step 6 assembles into the final deliverables.

### Command 1 — Full changelog in markdown (human-reading)

```bash
oasdiff changelog base.yaml revision.yaml --format markdown > .oasdiff-changelog.md
```

### Command 2 — Full changelog in JSON (feeds summary counts)

```bash
oasdiff changelog base.yaml revision.yaml --format json > .oasdiff-changelog.json
```

This output is required to populate `summary.nonBreaking` and `summary.cosmetic`
counts in the final `CONTRACT_DIFF.json` — the breaking-only diff (Command 3)
does not include non-breaking or cosmetic changes.

### Command 3 — Breaking changes only, in JSON (feeds breakingChanges[])

```bash
oasdiff breaking base.yaml revision.yaml --format json > .oasdiff-breaking.json
```

### Docker fallback

```bash
docker run --rm -t -v $(pwd):/specs tufin/oasdiff:stable \
  changelog /specs/base.yaml /specs/revision.yaml --format json
```

### Intermediate vs final artifact naming

| Intermediate (raw oasdiff output) | Final deliverable (assembled) |
|-----------------------------------|-------------------------------|
| `.oasdiff-changelog.md`           | `CONTRACT_DIFF.md`            |
| `.oasdiff-changelog.json`         | feeds `CONTRACT_DIFF.json` summary |
| `.oasdiff-breaking.json`          | feeds `CONTRACT_DIFF.json` breakingChanges[] |

**Add `.oasdiff-*` to `.gitignore`** so intermediate files are never committed.

## Step 4: Classify Changes

Map each detected change to a severity tier, semver impact, and required
consumer action. Use this table as the authoritative reference.

### `semverBump` rollup rule

```
if any change is Breaking  → semverBump = "major"
else if any change is Additive → semverBump = "minor"
else if any change is Cosmetic → semverBump = "patch"
else → semverBump = "none"
```

### Classification matrix

| Change Type                                         | Severity     | Semver Impact | Consumer Action                          |
|-----------------------------------------------------|--------------|---------------|------------------------------------------|
| Operation removed (e.g., `DELETE /users/{id}`)      | Breaking     | Major         | Remove/replace call site                 |
| Required request field added                        | Breaking     | Major         | Send the new field in requests           |
| Request/response field type changed                 | Breaking     | Major         | Update type annotations + parsing        |
| Response field removed                              | Breaking     | Major         | Stop relying on the field                |
| Enum value removed                                  | Breaking     | Major         | Remove branches relying on that value    |
| Required response field added                       | Breaking     | Major         | Update consumer null-checks              |
| Operation path or parameter renamed                 | Breaking     | Major         | Update route construction                |
| Response status code removed or changed             | Breaking     | Major         | Update success/error branching           |
| Security scheme removed or changed                  | Breaking     | Major         | Update auth headers / token flow         |
| Required header removed                             | Breaking     | Major         | Stop sending or update request builder   |
| Parameter `format` changed (e.g., int32 → int64)    | Breaking     | Major         | Update parser / type width               |
| Constraint tightened (min/max/maxLength)            | Breaking     | Major         | Re-validate inputs client-side           |
| Optional request field added                        | Non-breaking | Minor         | Optional adoption                        |
| Optional response field added                       | Non-breaking | Minor         | Optional adoption                        |
| New operation added                                 | Additive     | Minor         | Optional adoption                        |
| New response field (additive)                       | Additive     | Minor         | Optional adoption                        |
| Description / title / summary updated                | Cosmetic     | Patch         | None                                     |
| Tag or category renamed                             | Cosmetic     | Patch         | None                                     |

## Step 5: Map Consumer Impact

For each changed operation, find the consumer code that will be affected.

### Sub-operation 1: Locate SDK generators

Find generator config files in the repo:

```bash
rg -l "openapi-generator|hey-api|orval" --glob "*.{json,js,ts,yaml,yml,rc}"
```

Map each config to its output directory:
- `openapi-generator-config.json` / `.openapi-generator-ignore` → `src/api/` (or configured output)
- `openapi-ts.config.ts` → `src/api/generated/` (or configured output)
- `orval.config.ts` → `src/api/` (or configured output)

### Sub-operation 2: Find direct call sites

For each changed operation path, grep for direct HTTP calls. Example for
`DELETE /api/v1/users/{id}`:

```bash
# TypeScript (fetch / axios) — escape {id} braces for ripgrep
rg -n --type ts "(fetch|axios)\(['\"\`][^'\"]*/api/v1/users/[^'\"]+['\"\`]"

# Python (httpx / requests)
rg -n --type py "(httpx|requests)\.(get|post|put|patch|delete)\(['\"\`][^'\"]*/api/v1/users/[^'\"]+"
```

**Brace escaping note**: ripgrep treats `{n}` as a quantifier. For path
parameters like `{id}`, escape them in the regex: `\{id\}`.

### Sub-operation 3: Identify generated client files

Common locations for generated client code:
- `src/api/**` — typical output root
- `src/generated/**` — alternative output root
- `src/client/sdk/**` — some generators
- `client/sdk/**` — Python generators

**File-protection**: regeneration overwrites generated dirs. Document
`.openapi-generator-ignore` / `.swagger-codegen-ignore` for hand-edited wrapper
files that live outside generated dirs.

### Zero-result fallback

If all three sub-operations return empty (no generator config, no direct call
sites, no generated client dirs), emit a warning:

> **No standard consumers detected.** Consumers may use a custom HTTP wrapper
> or dynamically-constructed URLs. Manually review these directories:
> `src/services/`, `src/lib/api/`, `src/api/client/`, `app/api/`.

### Output shape

Each affected consumer becomes an entry in `affectedConsumers[]`:

```json
{
  "file": "src/features/user/deleteUser.ts",
  "line": 14,
  "snippet": "await fetch('/api/v1/users/123', { method: 'DELETE' })"
}
```

## Step 6: Generate Migration Report

Assemble the final deliverables from the intermediate oasdiff outputs and the
consumer impact mapping.

### `CONTRACT_DIFF.md` (human-readable)

```markdown
# OpenAPI Contract Change Report

## Summary
- Baseline: `openapi.yaml @ abc1234`
- Revision: `openapi.yaml @ def5678`
- **2 breaking changes** (MAJOR semver bump required)
- 4 additive changes
- 1 cosmetic change

## Breaking Changes

### BC-1: Removed operation `DELETE /api/v1/users/{id}`
- **Severity**: MAJOR
- **Runtime impact**: 404 errors at consumer call sites
- **Affected consumers** (3):
  - `src/features/user/deleteUser.ts:14` — calls this operation directly
  - `src/api/generated/UsersApi.ts:88` — generated client method
  - `src/features/admin/AdminUserTable.tsx:203` — handler triggering deletion
- **Migration**:
  1. Replace with `POST /api/v1/users/{id}/archive` (new deprecation-safe endpoint)
  2. Update UI copy: "Delete" → "Archive"
  3. Regenerate SDK: `npm run gen:api`

### BC-2: ...

## Additive Changes
(Changes that are safe to adopt optionally — no action required)

## Cosmetic Changes
(Description / metadata updates — no action required)

## SDK Regeneration Commands
(See Step 8 for per-generator commands)
```

### `CONTRACT_DIFF.json` (machine-readable)

```json
{
  "baseline": "abc1234",
  "revision": "def5678",
  "generatedAt": "2026-06-21T10:30:00Z",
  "summary": {
    "breaking": 2,
    "nonBreaking": 4,
    "cosmetic": 1,
    "semverBump": "major"
  },
  "breakingChanges": [
    {
      "id": "BC-1",
      "method": "DELETE",
      "path": "/api/v1/users/{id}",
      "changeType": "operation-removed",
      "severity": "MAJOR",
      "affectedConsumers": [
        {
          "file": "src/features/user/deleteUser.ts",
          "line": 14,
          "snippet": "await fetch('/api/v1/users/123', { method: 'DELETE' })"
        },
        {
          "file": "src/api/generated/UsersApi.ts",
          "line": 88,
          "snippet": "async deleteUser(id: string) { ... }"
        },
        {
          "file": "src/features/admin/AdminUserTable.tsx",
          "line": 203,
          "snippet": "onClick={() => deleteUser(row.original.id)}"
        }
      ],
      "migrationSteps": [
        "Replace DELETE /users/{id} with POST /users/{id}/archive",
        "Update UI copy: 'Delete' → 'Archive'",
        "Regenerate SDK: npm run gen:api"
      ]
    }
  ],
  "additiveChanges": [
    {
      "id": "AD-1",
      "method": "POST",
      "path": "/api/v1/users/{id}/archive",
      "changeType": "operation-added",
      "severity": "MINOR"
    }
  ],
  "cosmeticChanges": [
    {
      "id": "CO-1",
      "changeType": "description-updated",
      "severity": "PATCH"
    }
  ]
}
```

### Schema stability contract

The JSON schema above is versioned. Future changes MUST be additive (new fields
allowed, no field removals or type changes). `pr-creation-workflow-skill`
depends on these fields being stable:
- `summary.semverBump`
- `summary.breaking`
- `breakingChanges[].affectedConsumers[]`

## Step 7: PR Gate Integration

`CONTRACT_DIFF.json` is consumed by `pr-creation-workflow-skill` for automated
PR quality gating. The following fields have defined downstream effects:

| JSON Field                           | PR Gate Effect                                                            |
|--------------------------------------|---------------------------------------------------------------------------|
| `summary.semverBump`                 | Selects PR label: `major` / `minor` / `patch`                             |
| `summary.breaking > 0`               | Blocks auto-merge when `--require-approval` is set                        |
| `breakingChanges[].affectedConsumers[]` | Included in reviewer-assignment prompt for informed review             |

When the `CONTRACT_DIFF.json` file exists in the repo root (or in
`CONTRACT_REPORT_DIR`), `pr-creation-workflow-skill` reads it automatically
and applies these rules.

## Step 8: SDK Regeneration

After migrating consumer code, regenerate client SDKs. Pick the command for
your generator:

| Generator                          | Command                                                                              | Output Location      | Notes                                                                                          |
|------------------------------------|--------------------------------------------------------------------------------------|----------------------|------------------------------------------------------------------------------------------------|
| `@hey-api/openapi-ts` (recommended) | Create `openapi-ts.config.ts` with `input`, `output`, `plugins`; run `npx @hey-api/openapi-ts` | `src/api/generated/**` | Plugin-based config (verified vs `@hey-api/openapi-ts` 0.98.2 docs). NOT `hey-api.config.ts`. |
| `orval`                            | `npx orval --config ./orval.config.ts`                                               | `src/api/**`         | TS + react-query/swr hooks                                                                     |
| `openapi-generator-cli` (TS)       | `openapi-generator-cli generate -i openapi.yaml -g typescript-fetch -o src/api`      | `src/api/**`         | TS fetch client                                                                                |
| `openapi-generator-cli` (Python)   | `openapi-generator-cli generate -i openapi.yaml -g python -o ./client`               | `./client/**`        | Python httpx-based client                                                                      |
| `fastapi-code-generator` (server)  | `fastapi-codegen --input openapi.yaml --output app/` (install: `pip install fastapi-code-generator`) | `app/**`            | Server-side stubs. PyPI package is `fastapi-code-generator` (CLI binary: `fastapi-codegen`)   |

### `@hey-api/openapi-ts` config example

```typescript
// openapi-ts.config.ts (NOT hey-api.config.ts)
import { defineConfig } from '@hey-api/openapi-ts';

export default defineConfig({
  input: 'openapi.yaml',
  output: 'src/api/generated',
  plugins: [
    '@hey-api/sdk',           // typed SDK functions
    '@hey-api/client-fetch',  // Fetch-based HTTP client
    // For TanStack Query integration, see the plugin catalog at
    // https://heyapi.dev/docs/openapi/typescript/plugins for the current
    // plugin name (the catalog evolves; verify before use)
  ],
});
```

Run: `npx @hey-api/openapi-ts`

### File-protection note

Regeneration overwrites generated directories. Protect hand-edited wrapper
files:

```gitignore
# .openapi-generator-ignore — protects files from being overwritten
src/api/customAuth.ts
src/api/retryMiddleware.ts
```

## Return Contract

```
**Status:** [success | partial | failed]
**Output:** CONTRACT_DIFF.md, CONTRACT_DIFF.json
**Summary:** N breaking changes detected across M consumer files; semver bump: <major|minor|patch>
**Issues:** [blockers or "None"]
```

## Related Skills

- **`api-design-skill`** — Authoring counterpart: REST conventions, OpenAPI spec generation, GraphQL schemas, pagination, error formats. Use when designing or creating specs; use `openapi-contract-adherence-skill` when evolving or reviewing existing specs.
- **`pr-creation-workflow-skill`** — PR gate consumer: reads `CONTRACT_DIFF.json` for automated semver label selection and breaking-change merge gating.
- **`verification-loop-skill`** — General verification: use after migration to verify consumer code still compiles and passes tests.
- **`documentation-sync-workflow-skill`** — Deploy sync: run after adding this skill to verify count consistency across deploy scripts and README.
