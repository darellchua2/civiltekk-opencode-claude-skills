---
name: react-hooks-antipatterns-skill
description: >-
  Detect and fix React hooks anti-patterns — stale useState from props,
  StrictMode double-execution, dependency traps, stale refs, toast.promise
  leaks.
license: Apache-2.0
compatibility: opencode
category: Framework-Specific
---

<!-- Provenance: canvastekk-frontend-nextjs LEARNINGS. Split from react-nextjs-antipatterns-skill. PLAN-GIT-312. -->

## What I do

I detect and fix anti-patterns specific to React hooks that cause production incidents:

1. **State & Ref Pitfalls**: Stale derived state, StrictMode double-execution, stale ref accumulators
2. **Dependency Trap Anti-Patterns**: useCallback/useMemo dependency issues that cause unnecessary recreation or stale closures
3. **Async Hook Pitfalls**: toast.promise double-consumer Sentry noise
4. **Recommended Pattern**: Hook decomposition for complex components

## When to use me

Use this skill when:
- Debugging stale state after external data mutations
- Investigating StrictMode double-execution bugs
- Fixing useCallback/useMemo dependency warnings or stale closures
- Auditing toast.promise usage for double-error-reporting
- Decomposing large components into focused hooks
- Reviewing React hooks code for production-readiness

## Related Skills

- **react-render-antipatterns-skill**: Peer — covers render-time anti-patterns (fragment keys, JSON.parse in handlers, visibility toggle inconsistencies, theme-driven design). This skill covers hook lifecycle anti-patterns.
- **typescript-dry-principle-skill**: Duplicate type definitions and status mappings (redistributed from original skill).
- **performance-optimization-skill**: Module-scope cache leaks (redistributed from original skill).

---

## A. State & Ref Pitfalls

### A1. `derived-state-props-without-sync` — Stale useState from Props

`useState` initialized from props becomes stale when the parent updates the prop.

**Before (stale):**
```tsx
function EditDialog({ initialName }: { initialName: string }) {
  const [name, setName] = useState(initialName)
  // name stays "old" even after parent passes new initialName
}
```

**After (synced):**
```tsx
function EditDialog({ initialName }: { initialName: string }) {
  const [name, setName] = useState(initialName)

  useEffect(() => {
    setName(initialName)
  }, [initialName])
  // OR use a controlled component with `key={initialName}` to remount
}
```

### A2. `ref-guard-early-return` — StrictMode Double-Execution

`useRef(false)` guard with early returns before setting ref causes double-execution in React StrictMode.

**Before (buggy):**
```tsx
function useInit() {
  const started = useRef(false)

  useEffect(() => {
    if (someCondition) return // Early return BEFORE setting ref
    if (started.current) return
    started.current = true
    init() // Runs twice in StrictMode
  }, [])
}
```

**After (correct):**
```tsx
function useInit() {
  const started = useRef(false)

  useEffect(() => {
    if (started.current) return
    started.current = true // Set ref FIRST, before any logic
    if (someCondition) return
    init()
  }, [])
}
```

---

## B. Dependency Trap Anti-Patterns

### B1. `loading-state-in-usecallback-deps` — Unnecessary Callback Recreation

Including loading booleans in `useCallback` deps causes unnecessary recreation.

**Before (inefficient):**
```tsx
const handleSubmit = useCallback(() => {
  if (loading) return
  submit()
}, [loading, submit]) // Recreates on every loading toggle
```

**After (efficient):**
```tsx
const handleSubmit = useCallback(() => {
  submit()
}, [submit])

// Disable in the JSX instead
<button onClick={handleSubmit} disabled={loading}>Submit</button>
```

### B2. `inline-computed-usememo-dep` — New Reference Every Render

Inline ternary/computed values as `useMemo` deps create new references every render.

**Before (stale):**
```tsx
const sorted = useMemo(() => sortItems(items), [items.length > 0 ? items : []])
// Inline ternary creates new array reference each render — memo never hits
```

**After (correct):**
```tsx
const effectiveItems = useMemo(() => (items.length > 0 ? items : []), [items])
const sorted = useMemo(() => sortItems(effectiveItems), [effectiveItems])
```

### B3. `reset-refs-on-effect-restart` — Stale Ref Accumulators

`useRef` accumulators in `useEffect` carry over from previous lifecycles.

**Before (buggy):**
```tsx
const counter = useRef(0)

useEffect(() => {
  counter.current++ // Carries stale value from previous lifecycle — not reset
  doWork(counter.current)
}, [dependency])
```

**After (correct):**
```tsx
const counter = useRef(0)

useEffect(() => {
  counter.current = 0 // Reset at TOP of effect body
  counter.current++
  doWork(counter.current)
}, [dependency])
```

---

## C. Async Hook Pitfalls

### C1. `toast-promise-await-without-catch` — Double Consumer on toast.promise

`toast.promise(apiCall(), { ... })` and a bare `await apiCall()` are two INDEPENDENT consumers of the same promise. The toast wrapper handles the rejection (shows the error UI), but the bare `await` still lets the rejection propagate up the call stack. If the containing function is called from a path that has no try/catch, the unhandled rejection fires a Sentry alert for an error the user has already seen and dismissed. Add an empty `.catch(() => {})` to the awaited promise to swallow the already-surfaced error, OR drop the `await` entirely if only the toast UX is needed.

```tsx
import { toast } from 'sonner'

// BAD — toast handles the error UI, but the bare await re-surfaces it to Sentry
async function handleSubmit() {
  toast.promise(apiCall(), {
    loading: 'Saving...',
    success: 'Saved',
    error: 'Save failed',        // user sees this
  })
  await apiCall()                // rejection propagates AGAIN → Sentry noise
}

// GOOD (option A) — swallow the already-surfaced error
async function handleSubmit() {
  toast.promise(apiCall(), {
    loading: 'Saving...',
    success: 'Saved',
    error: 'Save failed',
  })
  await apiCall().catch(() => {}) // user already saw the toast; don't double-report
}

// GOOD (option B) — single consumer; await drives both UX and error handling
async function handleSubmit() {
  const promise = apiCall()
  toast.promise(promise, { loading: 'Saving...', success: 'Saved', error: 'Save failed' })
  try {
    await promise
  } catch {
    // already surfaced by toast; swallow to avoid Sentry noise
  }
}
```

**Detection:**

```bash
rg "toast\.promise" --type ts --type tsx -A 8 | rg "await" | rg -v "catch|try"
```

**Rule:** `toast.promise()` and a bare `await` of the same promise are two independent consumers. If the toast handles the error UI, add `.catch(() => {})` to the await (or drop the await) to prevent the rejection from being re-surfaced as Sentry noise for an error the user has already seen.

---

## D. Recommended Pattern

### D1. `hook-decomposition-complex-component` — Focused Hooks

Decompose complex components into focused hooks with typed interfaces.

```tsx
// Before: 300-line component doing everything
function ReportForm() { /* state + validation + submit + persistence */ }

// After: focused hooks
function useReportState(initial?: Report) { /* state management */ }
function useReportValidation(values: Report) { /* field validation */ }
function useReportSubmit() { /* API calls + error handling */ }

function ReportForm({ initial }: { initial?: Report }) {
  const { values, setField } = useReportState(initial)
  const errors = useReportValidation(values)
  const { submit, isSubmitting } = useReportSubmit()
  // Component is now ~50 lines of clean JSX
}
```
