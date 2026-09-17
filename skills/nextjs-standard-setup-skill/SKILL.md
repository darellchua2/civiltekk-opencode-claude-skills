---
name: nextjs-standard-setup-skill
description: >-
  Scaffold standardized Next.js 16 demos — shadcn, Tailwind v4, src directory
  with path aliases, React Compiler, Tekk-prefixed components.
license: Apache-2.0
compatibility: opencode
category: Framework-Specific
---

## What I do

Scaffold the house-standard Next.js 16 demo: create-next-app + shadcn + Tailwind v4 + `src/` layout + React Compiler + Tekk component conventions + project-level OpenCode LSP.

## When to use me

New Next.js 16 demo/prototype; standardizing an existing project onto the house structure.

## House standard

**Bootstrap**: `npx -y create-next-app@latest --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"` (npx for everything — zero-install), then `npx shadcn@latest init` + add components.

**Structure**: `src/app` (App Router) · `src/components/ui` (shadcn primitives, untouched) · `src/components/TekkComponents` + `src/custom-components` (Tekk-prefixed wrappers) · `src/page-containers` (`*PageContainer`) · `src/lib` · `src/types`.

**Component rules**: custom components carry the `Tekk` prefix (`TekkButton`); page containers end `PageContainer`; sections end `Section`; **named exports only** with `index.ts` re-exports (no default exports from shared components); shadcn primitives are wrapped, never edited; JSDoc on every custom component; `next/image` everywhere (see `nextjs-image-usage-skill`).

**React Compiler**: enabled for optimized reactivity (no manual `useMemo`/`useCallback` scaffolding in compiler-covered code).

**OpenCode LSP**: root `opencode.json` with `"lsp": {"typescript": {}, "eslint": {}}` — ambient cross-package diagnostics; check into git (refs: opencode.ai/docs/lsp, /docs/config).

**Related**: `nextjs-image-usage-skill` (Image rules) · `nextjs-unit-test-creator-skill` (tests) · `python-backend-skill` (Python equivalent).

> Removed 2026-09: step-by-step scaffolding transcripts (init, shadcn add, Tailwind v4 config, tsconfig alias edits), full directory trees, worked component examples, verification checklists — create-next-app/shadcn CLI flows are model-known; kept the house structure, naming/export rules, and the LSP wiring.
