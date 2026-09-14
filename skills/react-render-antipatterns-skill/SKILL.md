---
name: react-render-antipatterns-skill
description: >-
  Detect and fix React render anti-patterns — missing fragment keys, unsafe
  JSON.parse, revalidatePath/redirect swallowing, ssr:false hydration.
license: Apache-2.0
compatibility: opencode
category: Framework-Specific
---

<!-- Provenance: canvastekk-frontend-nextjs LEARNINGS. Split from react-nextjs-antipatterns-skill. PLAN-GIT-312. -->

## What I do

I detect and fix anti-patterns specific to React render-time behavior that cause production incidents:

1. **JSX Render Pitfalls**: Missing fragment keys in `.map()`, unsafe JSON.parse in drag-and-drop handlers
2. **State-Driven Render Issues**: Inconsistent visibility toggle strategies mixing hard-removal with runtime filtering
3. **Recommended Pattern**: Theme-driven component design using CSS custom properties only

## When to use me

Use this skill when:
- Debugging React key warnings in list rendering
- Fixing UI crashes from malformed drag-and-drop data
- Auditing inconsistent component visibility patterns
- Implementing theme-driven (light/dark mode) component design
- Reviewing React render-time code for production-readiness

## Related Skills

- **react-hooks-antipatterns-skill**: Peer — covers hook lifecycle anti-patterns (stale state, StrictMode double-execution, useCallback/useMemo traps). This skill covers render-time anti-patterns.
- **accessibility-a11y-skill**: ARIA patterns for dynamic error banners. This skill handles React render correctness.
- **frontend-design-skill**: UI aesthetics and layout. This skill handles runtime correctness.
- **uiux-review-skill**: Visual/UX review of rendered output. This skill handles the code-level anti-patterns that cause render bugs.

---

## A. JSX Render Pitfalls

### A1. `fragment-key-in-map` — Missing List Keys

`<>` shorthand Fragment in `.map()` can't accept `key`.

**Before (warning):**
```tsx
{items.map((item) => (
  <>
    <span>{item.name}</span>
    <span>{item.value}</span>
  </>
))}
```

**After (correct):**
```tsx
import { Fragment } from 'react'

{items.map((item) => (
  <Fragment key={item.id}>
    <span>{item.name}</span>
    <span>{item.value}</span>
  </Fragment>
))}
```

### A2. `unsafe-json-parse-event-handler` — UI Crash on Malformed Data

`JSON.parse` in drag-and-drop handlers crashes UI on malformed data.

**Before (crashes):**
```tsx
function onDrop(e: DragEvent) {
  const data = JSON.parse(e.dataTransfer.getData('text')) // Throws on bad data
  handleDrop(data)
}
```

**After (safe):**
```tsx
function onDrop(e: DragEvent) {
  try {
    const data = JSON.parse(e.dataTransfer.getData('text'))
    handleDrop(data)
  } catch {
    showToast('Invalid drag data')
  }
}
```

---

## B. State-Driven Render Issues

### B1. `inconsistent-visibility-toggle-strategy` — Mixed Hide Approaches

Mixing hard-removal with runtime `isXxxVisible()` filtering causes confusion.

**Before (inconsistent):**
```tsx
// File A: hard-removes from array
items = items.filter(i => i.id !== removedId)

// File B: runtime filter
{items.filter(i => isFeatureVisible(i.id)).map(...)}
```

**After (consistent):**
```tsx
// Standardize on runtime flag everywhere
const visibleItems = items.filter(i => isVisible(i.id))
{visibleItems.map(...)}
```

---

## C. Recommended Pattern

### C1. `folder-tabs-theme-driven` — CSS Custom Properties

CSS custom properties only — no hardcoded colors, automatic light/dark mode.

```tsx
// Component uses only CSS variables
<div className="tab-bar" style={{ '--tab-active-bg': 'var(--color-primary)' }}>
  <button className="tab active">Overview</button>
</div>

/* CSS */
.tab { background: var(--tab-bg, transparent); }
.tab.active { background: var(--tab-active-bg); color: var(--tab-active-fg); }

/* Theme switch is automatic via :root[data-theme] */
:root[data-theme="dark"] { --color-primary: #6366f1; }
:root[data-theme="light"] { --color-primary: #4f46e5; }
```

---

## D. Next.js Runtime Patterns

Patterns specific to Next.js that affect render-time behavior. Redistributed from the original `react-nextjs-antipatterns-skill` (PLAN-GIT-312).

### D1. `revalidatepath-inside-generic-try-catch` — Swallowed Redirects

`revalidatePath()` and `redirect()` throw non-Error objects with a `digest` property. Generic try/catch swallows them silently.

```tsx
// BAD — swallows redirect signal
try {
  revalidatePath('/dashboard')
} catch (e) {
  console.error('Failed to revalidate') // page never refreshes
}

// GOOD — re-throw Next.js internal signals
try {
  revalidatePath('/dashboard')
} catch (e) {
  if (e && typeof e === 'object' && 'digest' in e) {
    const digest = e.digest as string
    if (digest.startsWith('NEXT_REDIRECT') || digest.startsWith('NEXT_REVALIDATE')) {
      throw e
    }
  }
  console.error('Revalidation failed', e)
}
```

### D2. `ssr-false-eliminates-hydration-mismatch` — No More `typeof window` Guards

Wrap browser-API components in `next/dynamic({ ssr: false })` to eliminate hydration mismatches.

```tsx
import dynamic from 'next/dynamic'

const MapComponent = dynamic(() => import('./Map'), { ssr: false })
// No need for: if (typeof window === 'undefined') return null
```

### D3. `browserName-playwright-project-routing` — Project vs Browser

`browserName` is the browser engine, not the project name. Use `testInfo.project.name` for multi-project routing.

```ts
// BAD — matches all chromium-based projects, not the specific one
test('works in all projects', ({ browserName }) => {
  if (browserName === 'chromium') { /* ... */ }
})

// GOOD — correctly matches specific project config
test('works in all projects', ({}, testInfo) => {
  if (testInfo.project.name === 'desktop-chrome') { /* ... */ }
})
```
