# React Performance Guidelines

Rule-by-rule catalog for `react-best-practices-skill` — 43 rules in 8 impact-ranked categories. Paraphrased guidance; snippets are minimal idioms. See SKILL.md provenance for sourcing.

## 1. Eliminating waterfalls (CRITICAL)

Sequential awaits each pay full network latency. This category usually yields the largest wins.

### 1.1 Defer await until needed
Move `await` calls into the branch that consumes the value; don't block a fast early-return path on a fetch it never uses.

```ts
async function handle(userId: string, skip: boolean) {
  if (skip) return { skipped: true }      // returns without waiting
  const user = await getUser(userId)      // fetched only when needed
  return process(user)
}
```

### 1.2 Dependency-based parallelization
When tasks form a partial dependency chain, start the independent ones immediately and express each task's true dependencies. `better-all` automates this start-early/await-late wiring for object-shaped task groups.

### 1.3 Prevent waterfall chains in API routes
In route handlers and Server Actions, kick off independent work before the first await instead of sequencing every step.

```ts
export async function GET() {
  const sessionP = auth()          // starts now
  const configP = loadConfig()     // starts now
  const session = await sessionP
  const [config, data] = await Promise.all([configP, getData(session.id)])
  return Response.json({ data, config })
}
```

### 1.4 Promise.all() for independent operations
No dependency between async calls → run them concurrently; three sequential round trips become one.

### 1.5 Strategic Suspense boundaries
An async component that awaits before returning JSX blocks everything above it. Wrap the slow child in `<Suspense>` so the surrounding layout streams immediately and only the data-dependent subtree waits.

## 2. Bundle size (CRITICAL)

Smaller initial bundles improve Time to Interactive and LCP.

### 2.1 Avoid barrel file imports
Barrel entry points re-export thousands of modules; importing `{ Check } from 'lucide-react'` can evaluate ~1,500 modules for one icon. Import the source module directly, or enable Next.js `experimental.optimizePackageImports` to rewrite barrel imports at build time. Commonly affected: icon sets, `lodash`, `date-fns`, `rxjs`, `react-icons`, Radix/MUI packages.

### 2.2 Conditional module loading
Load large data or modules only once the feature that needs them is activated — dynamic `import()` inside the activation branch, guarded so SSR bundles skip it.

### 2.3 Defer non-critical third-party libraries
Analytics, logging, and error trackers never block interaction; load them after hydration (`next/dynamic` with `ssr: false`).

### 2.4 Dynamic imports for heavy components
Editors, charts, maps: `next/dynamic` keeps them out of the initial chunk until first render of the component that hosts them.

### 2.5 Preload based on user intent
Reduce perceived latency by warming heavy bundles early: preload on hover/focus of the entry button, or when a feature flag turns the feature on.

## 3. Server-side performance (HIGH)

### 3.1 Cross-request LRU caching
`React.cache()` lives for one request. For data reused across sequential requests (click A then click B), wrap the fetch in an LRU cache (`lru-cache`, short TTL). In serverless, use a shared store (e.g. Redis) when processes must share.

### 3.2 Minimize serialization at RSC boundaries
Everything crossing the server→client boundary is serialized. Pass the fields the client uses, not the whole object.

```tsx
// server
<Profile name={user.name} />   // not <Profile user={user} /> for one field
```

### 3.3 Parallel data fetching with component composition
Server components in a tree render sequentially. Move fetches into sibling components (or pass children through a layout) so each fetches independently instead of waiting on the parent's await.

### 3.4 Per-request deduplication with React.cache()
Wrap auth/session and hot DB reads in `cache(...)` — N call sites in one request cost one execution.

## 4. Client-side data fetching (MEDIUM-HIGH)

### 4.1 Deduplicate global event listeners
One global listener + a registry of callbacks beats N component instances each calling `addEventListener`. `useSWRSubscription` gives you the shared-subscription shape; the key idea is a module-level `Map<key, Set<callback>>` with refcount cleanup.

### 4.2 Use SWR for automatic deduplication
`useSWR(key, fetcher)` dedupes concurrent requests for the same key, caches, and revalidates across component instances. `useSWRMutation` covers writes; immutable data can skip revalidation.

## 5. Re-render optimization (MEDIUM)

### 5.1 Defer state reads to the usage point
If a dynamic value (search params, storage) is only read inside a callback, read it in the callback — don't subscribe the component to every change just to have it available.

### 5.2 Extract to memoized components
`useMemo` at the top of a component still runs before an early return. Extract the expensive subtree into a `memo` component so a loading early-return skips the work entirely.

### 5.3 Narrow effect dependencies
Depend on the primitive you use (`[user.id]`), not the object (`[user]`). For derived conditions, compute the boolean outside the effect and depend on it — the effect then runs on the state transition, not every intermediate value.

### 5.4 Subscribe to derived state
A `useWindowWidth()` subscription re-renders on every pixel. Subscribe to the boolean you actually branch on (`useMediaQuery('(max-width: 767px)')`).

### 5.5 Use lazy state initialization
`useState(expensive())` recomputes every render; `useState(() => expensive())` computes once. Use the function form for storage reads, index building, and heavy transforms — skip it for primitives and cheap literals.

### 5.6 Use transitions for non-urgent updates
Frequent low-stakes updates (scroll trackers, hover previews) belong in `startTransition(() => set...(...))` so they don't contend with urgent input work.

## 6. Rendering performance (MEDIUM)

### 6.1 Animate the SVG wrapper, not the SVG element
CSS transforms/transitions on `<svg>` elements often miss GPU acceleration. Put the animation class on a wrapping `<div>`.

### 6.2 CSS content-visibility for long lists

```css
.row { content-visibility: auto; contain-intrinsic-size: 0 80px; }
```

The browser skips layout/paint for off-screen rows — roughly an order of magnitude faster first render on thousand-row lists.

### 6.3 Hoist static JSX elements
Element trees that never change can live at module scope and be reused each render instead of being re-created — worthwhile for large static SVGs and skeletons.

### 6.4 Optimize SVG precision
Coordinate precision beyond what the viewBox needs is dead bytes. Trim decimals (SVGO: `--precision=1 --multipass`).

### 6.5 Prevent hydration mismatch without flickering
Reading `localStorage` during render breaks SSR; fixing it in a `useEffect` flashes the default. The fix is a synchronous inline `<script>` that sets the DOM (class/text) before hydration paints — right value on first paint, no mismatch. Themes and auth-gated UI are the typical cases.

### 6.6 Use the Activity component for show/hide
`<Activity mode={visible ? 'visible' : 'hidden'}>` preserves state and DOM for expensive subtrees that toggle often, instead of unmount/remount.

### 6.7 Use explicit conditional rendering
`{count && <Badge />}` renders a literal `0` when count is 0. Use `{count > 0 ? <Badge /> : null}` whenever the left side can be `0`, `NaN`, or another falsy value that renders.

## 7. JavaScript performance (LOW-MEDIUM)

### 7.1 Batch DOM CSS changes
Property-by-property style writes trigger a reflow each. Toggle one class (preferred) or assign `style.cssText` once.

### 7.2 Build index maps for repeated lookups
`array.find()` inside a loop is O(n) per lookup. Build a `Map` once, then every lookup is O(1) — 1000×1000 relation goes from ~1M comparisons to ~2K operations.

### 7.3 Cache property access in loops
Deep lookups (`obj.a.b.c`) inside a hot loop should be read once into a local before the loop.

### 7.4 Cache repeated function calls
Same function called repeatedly with the same inputs (slugify, feature checks): memoize in a module-level `Map`, or a simple nullable variable for single-value results. Clear the cache when the underlying input can change.

### 7.5 Cache storage API calls
`localStorage`/`sessionStorage`/`document.cookie` are synchronous and slow. Keep a `Map` mirror; invalidate on the `storage` event / visibility change.

### 7.6 Combine multiple array iterations
Three `.filter()` passes over the same array can be one `for...of` filling three result arrays.

### 7.7 Early length check for array comparisons
Comparing arrays by sort/join is O(n log n) plus string memory. If lengths differ, they're not equal — return before doing any of it.

### 7.8 Early return from functions
Return on the first failure instead of finishing the loop to set one more flag.

### 7.9 Hoist RegExp creation
`new RegExp(...)` per render (or per loop iteration) is wasted compilation. Hoist to module scope; for dynamic sources, `useMemo` it. Beware shared global regexes carrying `lastIndex` state.

### 7.10 Use a loop for min/max instead of sort
Sorting to find one extreme is O(n log n) plus a copy; a single pass is O(n). `Math.min(...arr)`/`Math.max(...arr)` are fine for small arrays but degrade on very large ones.

### 7.11 Use Set/Map for O(1) lookups
Membership checks against a growing list: `new Set(ids)` + `.has()` instead of `.includes()` per item.

### 7.12 Use toSorted() instead of sort() for immutability
`.sort()` mutates in place — dangerous on React state and props. `.toSorted()` (and `toReversed()`) return new arrays. Fallback for older targets: `[...arr].sort(...)`.

## 8. Advanced patterns (LOW)

### 8.1 Store event handlers in refs
Effects that bind window listeners shouldn't resubscribe because the callback identity changed. Keep the handler in a ref (updated each render), bind a stable listener once, depend only on the event name.

### 8.2 useLatest for stable callback refs

```ts
function useLatest<T>(value: T) {
  const ref = useRef(value)
  useEffect(() => { ref.current = value })
  return ref
}
```

Read `ref.current` inside timeouts/subscriptions for the freshest value without adding it to dependency arrays.
