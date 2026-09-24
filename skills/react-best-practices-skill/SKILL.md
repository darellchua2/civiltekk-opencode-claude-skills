---
name: react-best-practices-skill
description: >-
  React and Next.js performance best practices — waterfall elimination, bundle
  size, server-side caching, data fetching, re-render and rendering
  optimization. Use when writing, reviewing, or refactoring React/Next.js code
  for performance. Triggers: react performance, nextjs optimization, bundle
  size, waterfall, slow page, unnecessary re-renders.
license: Apache-2.0
compatibility: opencode
category: Framework-Specific
---

<!-- Provenance (#546): source-inspired by vercel-labs/agent-skills (react-best-practices branch), Vercel Engineering — license: none found (verified 2026-09-24 via GitHub API). Rules paraphrased in original words; code snippets are minimal self-written idioms. No verbatim upstream text copied. Structure: upstream's split rules directory deliberately flattened into this single references file. -->

## What I do

Priority-ordered React/Next.js performance guidance: 43 rules across 8 impact-ranked categories, from critical (request waterfalls, bundle bloat) to incremental (micro-optimizations, advanced patterns).

**Don't use me for** (peers instead): correctness anti-patterns (stale state, hook traps) → `react-hooks-antipatterns-skill` · render-time correctness (fragment keys, JSON.parse) → `react-render-antipatterns-skill` · visual design → `frontend-design-skill`.

## When to apply

- Writing new React components or Next.js pages
- Implementing data fetching (client or server)
- Reviewing or refactoring React/Next.js code for performance
- Optimizing bundle size, load times, or interaction responsiveness

## Priority-ordered categories

| Priority | Category | Impact |
|----------|----------|--------|
| 1 | Eliminating waterfalls | CRITICAL |
| 2 | Bundle size | CRITICAL |
| 3 | Server-side performance | HIGH |
| 4 | Client-side data fetching | MEDIUM-HIGH |
| 5 | Re-render optimization | MEDIUM |
| 6 | Rendering performance | MEDIUM |
| 7 | JavaScript micro-optimizations | LOW-MEDIUM |
| 8 | Advanced patterns | LOW |

Apply top-down: a CRITICAL fix (parallelizing requests) dwarfs any number of LOW fixes (hoisting regexps).

## Quick reference

**Waterfalls (CRITICAL)** — move each `await` into the branch that needs it; start independent work before awaiting (fire promises early, await late); `Promise.all()` for independent operations; Suspense boundaries so wrappers render while data streams; split dependency chains so slow steps don't gate fast ones.

**Bundle size (CRITICAL)** — import from source modules, not barrel files (icon/component libraries can re-export thousands of modules; 200-800ms cold-start cost); `next/dynamic` for heavy components; load analytics/logging after hydration; preload on user intent (hover/focus, feature-flag on).

**Server-side (HIGH)** — `React.cache()` deduplicates within a request; an LRU cache covers across requests; pass only the fields a client component uses across the RSC boundary; restructure trees so sibling server components fetch in parallel.

**Client data (MEDIUM-HIGH)** — SWR deduplicates and caches across instances; share global event listeners through one subscription instead of one per component instance.

**Re-renders (MEDIUM)** — read dynamic state where it's used, not at the top; extract expensive work into memoized components so early returns skip it; depend on primitives, not objects; subscribe to derived booleans, not continuous values; lazy `useState` initializers for expensive first values; `startTransition` for non-urgent updates.

**Rendering (MEDIUM)** — animate a wrapper `<div>`, not the `<svg>` element (GPU acceleration); `content-visibility: auto` + `contain-intrinsic-size` for long lists; hoist static JSX out of components; trim SVG coordinate precision; prevent hydration-mismatch flicker with a synchronous inline script instead of post-hydration `useEffect`; `<Activity>` to preserve state on frequent show/hide; explicit `? :` over `&&` (falsy `0`/`NaN` render literally).

**JavaScript (LOW-MEDIUM)** — batch style changes via classes or `cssText`; index Maps for repeated lookups; cache repeated function results at module level; cache storage-API reads; merge multi-pass array loops; length check before expensive comparisons; early returns; hoist RegExp out of render; single-pass loops for min/max instead of sort; `Set`/`Map` for membership checks; `toSorted()`/`toReversed()` instead of mutating `sort()` on React state.

**Advanced (LOW)** — keep event handlers in refs so effects don't resubscribe; a `useLatest` ref gives callbacks fresh values without dependency churn.

## References

Full rule-by-rule catalog with examples: [references/react-performance-guidelines.md](references/react-performance-guidelines.md)
