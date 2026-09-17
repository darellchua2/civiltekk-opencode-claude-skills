---
name: threejs-nextjs-skill
description: >-
  Three.js + Next.js (App Router, React 19) integration — SSR pitfalls, GLSL
  bundling, hydration, WebGL context loss, R3F/drei, WebXR, companion-library
  decision tree. Version detection first.
license: Apache-2.0
compatibility: opencode
category: Framework-Specific
---

# Three.js + Next.js Integration Guidance

Provenance: built for the chronic friction of Three.js + Next.js App Router / React 19 — three.js ships 10–12 breaking releases/year, R3F v8/v9 is the React 18/19 split, drei lags `three` by months, and Next 16's default Turbopack breaks Webpack-era GLSL patterns.

## CRITICAL: Version detection first (MANDATORY)

Never give version-specific code before confirming versions. Ask the user to run:
`npm ls three @react-three/fiber @react-three/drei @react-three/xr` + `grep -E 'three|react|next' package.json`; or detect from files (package.json → `npm ls` → `require('three').REVISION`; monorepos: per-workspace). Generic architectural guidance (e.g. "use `'use client'`") is safe without versions; concrete imports/JSX are not.

**Version matrix (verified Jul 2026 — refresh with `npm view <pkg> version` before relying on it):** `three` 0.185.1 (addons at `three/addons/*`; WebGPURenderer+TSL present) · `@react-three/fiber` 9.6.1 (**v9 = React 19**, v8 = React 18) · `@react-three/drei` 10.7.7 (**stale, compatibility risk** — uses `three-stdlib`; test before upgrading `three` past drei's tested range) · `@react-three/xr` 6.6.30 (v6 `createXRStore()` + `<XR store>`; v5 API entirely different) · `next` 16 (Turbopack default) · `react` 19 (StrictMode double-mounts → WebGL context loss in non-R3F code).

**Version-sensitive areas**: addons path (`three/examples/jsm` ≤0.155 → `three/addons` 0.156+) · WebGLRenderer vs WebGPURenderer not interchangeable · R3F v8/v9 JSX element mappings differ · GLSL via `raw-loader` = Webpack-only (≤Next 15), breaks under Turbopack · TSL replaces GLSL on the WebGPU path.

## Pitfall catalog (identifier → one-line rule)

**SSR**: `three-in-server-component` — every file transitively importing `three`/`@react-three/*`/WebXR MUST start `'use client'`; load via `next/dynamic(..., { ssr: false })` · `next-image-inside-drei-html` — drei `<Html>` portals bypass Next's Image optimizer: use plain `<img>` inside `<Html>`, or hoist `<Image>` out of the scene.
**Hydration**: `hydration-mismatch-canvas` — Canvas dimensions are runtime-computed; skip SSR or render a static placeholder · StrictMode double-mounts → guard context-loss listeners.
**Bundler (Turbopack)**: `raw-loader` GLSL imports fail — use `?.glsl` type modules or inline template literals; Webpack-only config must be rewritten for Turbopack.
**Resource management**: `persistent-canvas-route-changes` — unmount Canvas or lose WebGL state on route change · `missing-dispose-memory-leak` — imperative `useThree()`/raw Three objects need explicit `.dispose()` (JSX-created objects are managed by R3F); `material clone leak`: `.clone()` materials must be re-registered with the manager · `line-not-disposed-in-overlay-cleanup` (provenance: canvastekk-frontend-nextjs/LEARNINGS) — overlay `THREE.Line`s removed from the scene graph still hold GPU memory until `geometry.dispose()` + material dispose · `perspectivecamera-cast-after-swap` (same provenance) — raycaster must receive the CURRENT camera after any camera swap, never an init-time capture.

**Companion libraries**: zustand (5.x) is the standard state pairing; drei covers most needs — add others (postprocessing, rapier, csg) only when drei lacks the feature. WebXR: v6 `createXRStore()` pattern only.

When stuck, consult the three.js migration guide for the user's exact version before improvising: github.com/mrdoob/three.js/wiki/Migration-Guide.

> Removed 2026-09: expanded pitfall walkthroughs with full before/after code (kept identifier+rule table), framework-detection transcripts, integration-approach essays, WebXR tutorials, research-workflow prose — the version matrix, version-sensitive map, and pitfall rules are the durable content.
