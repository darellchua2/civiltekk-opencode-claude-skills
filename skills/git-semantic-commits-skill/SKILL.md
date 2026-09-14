---
name: git-semantic-commits-skill
description: "Conventional Commits — type, scope, breaking changes, semver guidance, atomic-commit granularity by layer. Triggers: commit and push, make a commit, write a commit message, commit message format, semantic commit. Not for brevity (git-compact-commits-skill)."
license: Apache-2.0
compatibility: opencode
category: Git/Workflow
---

## What I do

Conventional Commits formatting plus this config's atomic-commit granularity doctrine. A framework skill — other skills consume these rules.

**Handoffs:** commit-length enforcement (72-char subject, 150-word body, commitlint config, semantic grouping) → `git-compact-commits-skill` (the authority for those). Full release pipeline conventions (PR titles, merge strategy, release tags, GitHub Actions) → `semantic-release-convention`.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

- Types: `feat fix docs style refactor test chore perf ci build revert`
- Subject: imperative mood ("add", not "added"), lowercase type/scope, ≤72 chars, no trailing period
- Body: what and why, not how; wrap at 72; word-count limits live in `git-compact-commits-skill`
- Footers: `BREAKING CHANGE: <desc + migration>`, `Closes #N`, `Reviewed-by:`, `Authored-by:`
- Breaking change: `!` after type/scope (`feat(api)!: …`) **or** `BREAKING CHANGE:` footer → MAJOR

## Semver mapping

`feat`→MINOR · `fix`→PATCH · `perf`→PATCH/MINOR · `build`→PATCH if functional · `docs`/`style`/`refactor`/`test`/`chore`/`ci`→none · breaking→MAJOR.

## Commit Granularity (house doctrine)

**One logical change per commit** — each commit compiles and passes tests on its own. Never mix style-only changes with logic.

| Layer | Commit type | Why isolate |
|---|---|---|
| Database migration | `feat(db):` / `chore(db):` | DDL is irreversible; isolated rollback |
| ORM / model | `feat(model):` | downstream code depends on schema |
| API contract (pydantic/schema) | `feat(schema):` | consumers must adapt |
| Business logic | `feat:` / `fix:` / `refactor:` | one concern per commit |
| Tests | same commit as the code (or `test:` if large) | tests validate what they accompany |
| Docs / plan updates | `docs:` | no runtime effect |
| Style / formatting | `style:` | always its own commit |

Split vs combine: single concern → one commit · different layers → one per layer · same layer, tightly coupled (can't compile/test apart) → combine · same layer, independent → separate commits.

## Project override

These are **defaults**. The project's `AGENTS.md` and `.commitlintrc*` / `commitlint.config.*` override them (layer naming, body line length 72 vs 120, squash-merge policy). Always check the project's AGENTS.md first.

> Removed 2026-09: per-type example/keyword catalogs, filled templates, changelog samples, validation/detection bash scripts, commitizen/commitlint/semantic-release setup guides, and common-issue walkthroughs — the spec lives at conventionalcommits.org; this file keeps the house doctrine and handoffs.
