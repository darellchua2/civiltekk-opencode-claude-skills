# Route `ts-dry` — TypeScript DRY refactoring

Values for `civiltekk-react-quality-skill` route `ts-dry`.

## What I do

Eliminate duplication in TypeScript projects: detect repeated logic/types/config, extract shared utilities/services/generics, consolidate types, verify with tsc + tests.

## When to use me

- Similar code blocks across .ts/.tsx files; copy-paste between modules
- Duplicate type definitions; scattered config values; repeated validation/fetch logic

## House patterns (the two that recur here)

**Canonical type import** — local component types duplicating canonical types drift apart silently (one gains a field, the other doesn't; props mismatch). Never re-declare a type beside its consumer: import from the single source of truth (`types/<domain>.ts`).

**Shared status mapping** — near-identical status→icon/color switches across components extract to one `Record<string, {icon, color}>` map per domain + a `getStatusIcon(status, map, size)` helper; parameterize only what actually varies (usually just `size`).

Verify after refactor: `npx tsc --noEmit` && tests && lint. Watch for circular deps when extracting (split modules or move shared types to `types/`); start concrete, abstract only on second occurrence.

> Removed 2026-09: the 10-step tutorial (before/after examples for utils, API services, generic components/hooks, constants, validators, folder layout), best-practice lists, common-issue walkthroughs, factory/repository/HOC pattern dumps, and troubleshooting checklists — standard DRY/TypeScript knowledge the model already has; the house patterns above are what this config actually added.
