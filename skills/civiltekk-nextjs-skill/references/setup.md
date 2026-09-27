# Route `scaffold` — house-standard Next.js 16 setup (values)

Values for `civiltekk-nextjs-skill` route `scaffold`. The host SKILL.md
carries the METHOD (detect route → load this file → apply); this file
carries the house standard.

## What this route covers

Scaffold the house-standard Next.js 16 demo: create-next-app + shadcn +
Tailwind v4 + `src/` layout + React Compiler + Tekk component conventions
+ project-level OpenCode LSP. Use when: a new Next.js 16 demo/prototype is
requested, or an existing project is being standardized onto the house
structure.

## House standard

**Bootstrap**: `npx -y create-next-app@latest --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"` (npx for everything — zero-install), then `npx shadcn@latest init` + add components.

**Structure**: `src/app` (App Router) · `src/components/ui` (shadcn primitives, untouched) · `src/components/TekkComponents` + `src/custom-components` (Tekk-prefixed wrappers) · `src/page-containers` (`*PageContainer`) · `src/lib` · `src/types`.

**Component rules**: custom components carry the `Tekk` prefix (`TekkButton`); page containers end `PageContainer`; sections end `Section`; **named exports only** with `index.ts` re-exports (no default exports from shared components); shadcn primitives are wrapped, never edited; JSDoc on every custom component; `next/image` everywhere (route `image-usage` of this skill).

**React Compiler**: enabled for optimized reactivity (no manual `useMemo`/`useCallback` scaffolding in compiler-covered code).

**OpenCode LSP**: root `opencode.json` with `"lsp": {"typescript": {}, "eslint": {}}` — ambient cross-package diagnostics; check into git (refs: opencode.ai/docs/lsp, /docs/config).

**Related**: route `image-usage` of this skill (Image rules) · `nextjs-unit-test-creator-skill` (tests) · `civiltekk-python-backend-skill` (Python equivalent).

> Removed 2026-09: step-by-step scaffolding transcripts (init, shadcn add, Tailwind v4 config, tsconfig alias edits), full directory trees, worked component examples, verification checklists — create-next-app/shadcn CLI flows are model-known; kept the house structure, naming/export rules, and the LSP wiring.
