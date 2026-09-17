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

Diff OpenAPI specs (`oasdiff`), classify every change Breaking/Additive/Cosmetic with semver impact and consumer action, emit `CONTRACT_DIFF.{md,json}` + a migration plan.

## When to use me

Spec changed in a PR; consumer-impact review; before publishing a new API version; regenerating SDK clients.

**Tools:** `oasdiff` (primary; Docker fallback `tufin/oasdiff:stable`); linters `redocly lint` / `spectral lint`; generators per client language.

## Workflow

1. **Discover specs**: git-based baseline (`git show <base>:path/to/spec.yaml > base.yaml`; default = target branch merge-base) or manual baseline; monorepos — diff each spec independently and report per-spec.
2. **Validate** both specs (`redocly lint`; fix errors before diffing — an invalid spec yields garbage diffs).
3. **Diff — three oasdiff invocations** (intermediates, gitignored via `.oasdiff-*`):
   `oasdiff changelog base.yaml revision.yaml --format markdown > .oasdiff-changelog.md` (human) · `--format json > .oasdiff-changelog.json` (feeds summary counts) · `oasdiff breaking base.yaml revision.yaml --format json > .oasdiff-breaking.json` (feeds `breakingChanges[]`).
4. **Classify** with the matrix below; **semverBump rollup**: any Breaking → major; else any Additive → minor; else Cosmetic → patch; else none.
5. **Map consumers**: grep call sites for each changed operation/path (`rg '"/users' --type ts -l` etc.); each hit gets the consumer action.
6. **Emit** `CONTRACT_DIFF.md` (changelog + impact) and `CONTRACT_DIFF.json` (`{summary: {breaking, nonBreaking, cosmetic, semverBump}, breakingChanges: [...], consumerImpact: [...]}`) + a migration plan section per breaking change. Intermediates never committed.

## Classification matrix (authoritative)

| Change | Severity | Semver | Consumer action |
|---|---|---|---|
| Operation removed / path or param renamed | Breaking | Major | remove/replace call site, update route construction |
| Required request field added | Breaking | Major | send the new field |
| Field type changed / `format` changed (int32→int64) | Breaking | Major | update types + parsing |
| Response field removed / status code changed or removed | Breaking | Major | stop relying on field; update branching |
| Enum value removed | Breaking | Major | remove branches on that value |
| Required response field added | Breaking | Major | update null-checks |
| Security scheme changed / required header removed | Breaking | Major | update auth flow / request builder |
| Constraint tightened | Breaking | Major | re-validate inputs client-side |
| Optional field added (request or response) | Non-breaking | Minor | optional adoption |
| New operation / additive response field | Additive | Minor | optional adoption |
| Description/title/summary updated | Cosmetic | Patch | none |

**Related:** `api-design-skill` §Authoring Quality Gate (write-time rules; this skill is the review-time counterpart).
