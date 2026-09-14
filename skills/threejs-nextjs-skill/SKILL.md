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

Provenance: created to address the well-known friction of integrating Three.js
(and its React wrapper ecosystem) with Next.js App Router / React 19.
Three.js has 312+ published releases with significant API churn, and Next.js
16's default Turbopack bundler breaks many Webpack-era patterns. **Always
verify versions before advising** — see §Version Detection below.

## CRITICAL: Version Detection (MANDATORY)

### Version Prompting Rules

You **MUST** determine the user's Three.js ecosystem versions **BEFORE**
providing any concrete code or migration guidance. Three.js ships 10–12
releases per year with breaking API changes; React Three Fiber v8 vs v9 is
the React 18 vs React 19 split; `@react-three/drei` lags `three` by months
and silently breaks on major Three.js changes.

**If the user has NOT specified versions:**

```
STOP and ask:
"What versions are you using? Run these in your project and paste the output:

  npm view three version                  # latest published
  npm ls three @react-three/fiber @react-three/drei @react-three/xr
  cat package.json | grep -E 'three|react|next'

This is required because API availability, JSX element mappings, WebXR
helpers, and bundler behavior differ significantly across versions. Guessing
leads to runtime errors, hydration crashes, or stale examples."
```

**DO NOT proceed with concrete code until versions are confirmed.** Generic
architectural guidance (e.g. "use `"use client"`") is fine without versions;
version-specific imports/JSX are not.

### Version Detection Methods

When project files are available, check in this order:

1. `cat package.json` — read `dependencies` and `devDependencies` for `three`,
   `@react-three/fiber`, `@react-three/drei`, `@react-three/xr`,
   `@react-three/postprocessing`, `@react-three/rapier`, `react`, `react-dom`,
   `next`
2. `npm ls three @react-three/fiber @react-three/drei 2>/dev/null` — resolves
   nested/peer-installed versions
3. `node -e "console.log(require('three').REVISION)"` — actual installed
   Three.js revision (e.g. `185`)
4. For monorepos: check each workspace's `package.json` independently

### Version Matrix (verified July 2026)

> **Refresh instructions:** Run `npm view <pkg> version` for each package
> before relying on this table. Re-verify the migration guide URL
> (https://github.com/mrdoob/three.js/wiki/Migration-Guide) for the user's
> specific `three` version.

| Package | Verified Latest | Pairing Notes |
|---|---|---|
| `three` | **0.185.1** (Jul 2026) | 11.5M weekly downloads. Includes `WebGPURenderer`, TSL (Three Shading Language), NodeMaterials, extensive addon system. Imports under `three/addons/*` (formerly `three/examples/jsm/*`). |
| `@react-three/fiber` | **9.6.1** (Apr 2026) | **v9 = React 19.** v8 = React 18. TypeScript built-in. Pair with React 19.2+. |
| `@react-three/drei` | **10.7.7** (Nov 2025) | **8 months stale — compatibility risk.** Uses `three-stdlib` instead of `three/examples/jsm`. Test before upgrading `three` past what drei has tested. |
| `@react-three/xr` | **6.6.30** (~May 2026) | Uses `createXRStore()` + `<XR store={store}>` pattern (v6). v5 API is different. |
| `@react-three/postprocessing` | follows drei | Wraps `postprocessing` library |
| `@react-three/rapier` | active | Rapier WASM physics |
| `@react-three/csg` | active | Constructive solid geometry |
| `zustand` | 5.x | Standard state pairing (also pmndrs) |
| `next` | 16.x | **Turbopack is default bundler** — breaks Webpack-only GLSL configs |
| `react` / `react-dom` | 19.x | StrictMode double-mounts → WebGL context loss in non-R3F code |

### Version-Sensitive Areas

These topics have major differences across versions — always confirm:

- **Renderer**: `WebGLRenderer` (stable for years) vs `WebGPURenderer` (0.165+,
  TSL shaders) — APIs are NOT interchangeable
- **Addons path**: `three/examples/jsm/*` (≤0.155) → `three/addons/*` (0.156+)
- **JSX element mapping**: R3F v8 vs v9 reconciler changes which intrinsic
  elements are available (e.g. `<mesh>` vs `<primitive>`)
- **XR API**: `@react-three/xr` v5 (`<VRButton>`, `<XR>`) vs v6
  (`createXRStore`, `<XR store={...}>`) — completely different
- **GLSL imports**: `raw-loader` worked under Webpack (≤Next 15); breaks under
  Turbopack (Next 16 default)
- **TSL (Three Shading Language)**: replaces raw GLSL for WebGPU path; only
  available in recent `three` versions

---

## Framework Detection (Detect Once, Top of Conversation)

In addition to package versions, detect the framework context:

| Detection | How | Implication |
|---|---|---|
| Next.js App Router | `app/` directory exists, or `next.config.*` + `import "server-only"` | Server Components are default — must use `"use client"` for any Three.js code |
| Next.js Pages Router | `pages/` directory exists | `_app.tsx`/`_document.tsx` wrapping; less strict SSR rules but still browser-only for Three.js |
| React 18 vs 19 | `package.json` `react` version | R3F v8 (React 18) vs v9 (React 19) — different packages |
| Turbopack vs Webpack | Next 16 default = Turbopack; `next.config.ts` `experimental.turbopack` field; check `next dev --turbopack` vs `next dev --webpack` | GLSL/bundler polyfills differ — see §Pitfall C3 |
| Vite / CRA / vanilla | No `next.config.*`; `vite.config.*` or `webpack.config.*` | **Out of scope for this skill.** Use `frontend-design-skill` or general Three.js docs. |

---

## Integration Approaches (Decision Tree)

```
Is this a Next.js project?
├── No  → Out of scope. Recommend frontend-design-skill or threejs.org/docs.
└── Yes → Are you wrapping Three.js in React?
    ├── No  → Approach A: Raw Three.js + next/dynamic({ ssr: false })
    └── Yes → Approach B: R3F + drei (RECOMMENDED for new projects)
              └── Need persistent canvas across routes?
                  ├── Yes → Use react-three-next starter pattern
                  │        (tunnel-rat + View + gl.scissor)
                  └── No  → Plain <Canvas> inside a single Client Component
```

### Approach A — Raw Three.js + `next/dynamic({ ssr: false })`

**When:** Performance-critical scenes, porting legacy Three.js code, R3F
overhead unacceptable (rare — R3F has zero overhead at runtime).

```tsx
// app/page.tsx (Server Component by default — keep it server)
import dynamic from 'next/dynamic'

const Scene = dynamic(() => import('./scene'), { ssr: false })

export default function Page() {
  return (
    <main>
      <Scene />
    </main>
  )
}
```

```tsx
// app/scene.tsx
'use client'  // REQUIRED — Three.js touches window/document/WebGL at module load

import { useEffect, useRef } from 'react'
import * as THREE from 'three'

export default function Scene() {
  const mountRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const mount = mountRef.current!
    const renderer = new THREE.WebGLRenderer({ antialias: true })
    // ... setup scene, camera, animation loop ...

    mount.appendChild(renderer.domElement)

    return () => {
      // CRITICAL: dispose everything (see Pitfall D2)
      renderer.dispose()
      // geometry.dispose(); material.dispose(); texture.dispose()
      mount.removeChild(renderer.domElement)
    }
  }, [])

  return <div ref={mountRef} />
}
```

### Approach B — R3F + drei (RECOMMENDED)

**When:** Default choice for any new React + Three.js work. Declarative,
React hooks, automatic disposal, 970+ drei helpers.

```tsx
// app/scene.tsx
'use client'  // REQUIRED — R3F's <Canvas> touches WebGL

import { Canvas } from '@react-three/fiber'
import { OrbitControls, Environment, useGLTF } from '@react-three/drei'

export default function Scene() {
  return (
    <Canvas camera={{ position: [0, 0, 5], fov: 50 }} dpr={[1, 2]}>
      <ambientLight intensity={0.5} />
      <directionalLight position={[5, 5, 5]} />
      <Model url="/model.glb" />
      <OrbitControls />
      <Environment preset="city" />
    </Canvas>
  )
}

function Model({ url }: { url: string }) {
  const { scene } = useGLTF(url)
  return <primitive object={scene} />
}

useGLTF.preload('/model.glb')
```

```tsx
// app/page.tsx (Server Component — keeps metadata exportable)
import dynamic from 'next/dynamic'
import type { Metadata } from 'next'

const Scene = dynamic(() => import('./scene'), { ssr: false })

export const metadata: Metadata = {
  title: '3D Scene',
}

export default function Page() {
  return <Scene />
}
```

### Approach C — `react-three-next` Starter Pattern

**Repo:** https://github.com/pmndrs/react-three-next (2.9k stars)
**Install:** `yarn create r3f-app next my-app`
**Status (Jul 2026):** Not yet updated for Next.js 16 + React 19 (open issue
#180). Useful as architectural reference; may need migration work.

Key patterns to copy:
- `tunnel-rat` for portaling R3F content into a persistent `<Canvas>` mounted
  in `layout.tsx`, so route changes don't remount the WebGL context
- `<View>` (drei) for embedding 3D content in arbitrary DOM `<div>`s via
  `gl.scissor` viewport segmentation
- `@react-three/drei` `Loader` for asset preload progress UI

---

## Pitfall Catalog

Mirrors the format of `react-hooks-antipatterns-skill` / `react-render-antipatterns-skill`. Each pitfall has an
identifier, symptom, root cause, and fix with code.

### Section A: SSR & Server Components (Critical)

#### A1. `three-in-server-component` — Module-Load Crash

**Symptom:** `ReferenceError: window is not defined` or
`document is not defined` during `next dev` or `next build`.

**Root cause:** Three.js and most of its addons touch `window`/`document`
at module load time (not just at render time). Importing them in a Server
Component executes that code on the server.

**Before (broken):**
```tsx
// app/page.tsx — Server Component by default
import { Canvas } from '@react-three/fiber'  // 💥 crashes on import

export default function Page() {
  return <Canvas />  // never reached
}
```

**After (correct):**
```tsx
// app/scene.tsx
'use client'  // REQUIRED at top of every file that imports three/* or @react-three/*

import { Canvas } from '@react-three/fiber'
export default function Scene() { return <Canvas /> }

// app/page.tsx — Server Component, can stay server
import dynamic from 'next/dynamic'
const Scene = dynamic(() => import('./scene'), { ssr: false })
export default function Page() { return <Scene /> }
```

**Rule:** Every file in the import graph that transitively touches `three`,
`@react-three/fiber`, `@react-three/drei`, `@react-three/xr`,
`postprocessing`, or any WebGL/WebXR library MUST start with `'use client'`.

#### A2. `next-image-inside-drei-html` — Portal Conflict

**Symptom:** `next/image` components inside drei `<Html>` render incorrectly
or trigger "Image is missing required alt property" warnings from Next's
optimizer.

**Root cause:** drei `<Html>` portals content into the DOM via
`react-dom/createPortal`, bypassing Next.js's `<Image>` optimization context.

**Fix:** Use plain `<img>` inside `<Html>`, or hoist `<Image>` outside the
3D scene and overlay it with CSS.

```tsx
// Bad: <Image> inside drei <Html>
<Html>
  <Image src="/overlay.png" width={200} height={100} alt="" />  // ⚠️
</Html>

// Good: plain img, or DOM overlay outside Canvas
<Html>
  <img src="/overlay.png" width={200} height={100} alt="" />
</Html>
```

### Section B: Hydration & StrictMode

#### B1. `hydration-mismatch-canvas` — Server vs Client HTML Drift

**Symptom:** React warning: "Hydration failed because the initial UI does
not match what was rendered on the server."

**Root cause:** `<Canvas>` renders a `<canvas>` element with dimensions set
at runtime by Three.js based on the container's clientWidth/clientHeight.
Server-rendered HTML can't know these dimensions, so the attributes differ.

**Fix:** Use `next/dynamic({ ssr: false })` to skip server rendering
entirely, OR render a static placeholder server-side and swap in `<Canvas>`
client-side.

```tsx
// Option A: skip SSR entirely
const Scene = dynamic(() => import('./Scene'), { ssr: false })

// Option B: static placeholder
export default function Page() {
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])
  return (
    <div style={{ minHeight: 400 }}>
      {mounted ? <Canvas /> : <div>Loading 3D…</div>}
    </div>
  )
}
```

#### B2. `strictmode-webgl-context-loss` — Double-Mount Leak

**Symptom:** `THREE.WebGLRenderer: Context Lost` warnings in dev console;
GPU memory grows over time; tab crashes after many hot reloads.

**Root cause:** React 19 StrictMode double-invokes `useEffect` (mount,
unmount, mount) in development. Custom (non-R3F) Three.js code that creates
WebGLRenderer/Geometry/Material/Texture in `useEffect` without proper
cleanup leaks the first instance.

**Before (leaks):**
```tsx
useEffect(() => {
  const renderer = new THREE.WebGLRenderer()
  // ... animation loop ...
  // Missing return () => renderer.dispose()
}, [])
```

**After (correct):**
```tsx
useEffect(() => {
  const renderer = new THREE.WebGLRenderer()
  const geometry = new THREE.BoxGeometry()
  const material = new THREE.MeshStandardMaterial()
  const mesh = new THREE.Mesh(geometry, material)
  let frameId = 0

  const animate = () => {
    frameId = requestAnimationFrame(animate)
    renderer.render(scene, camera)
  }
  animate()

  return () => {
    cancelAnimationFrame(frameId)
    geometry.dispose()
    material.dispose()
    // Dispose all textures on the material:
    Object.values(material).forEach(v => {
      if (v instanceof THREE.Texture) v.dispose()
    })
    renderer.dispose()
    renderer.forceContextLoss()  // Force release for StrictMode remount
  }
}, [])
```

**Note:** R3F `<Canvas>` handles disposal automatically. This pitfall only
affects raw Three.js code or `useThree()` consumers creating objects
outside R3F's reconciler.

### Section C: Bundler (Turbopack vs Webpack)

#### C1. `fs-path-polyfills-needed` — Module Not Found

**Symptom:** `Module not found: Can't resolve 'fs'` (or `'path'`, `'os'`,
`'crypto'`) during `next build` or `next dev`.

**Root cause:** Some Three.js addons and loader utilities reference Node.js
built-ins. Browsers don't have these, but the bundler tries to resolve them.

**Fix (Webpack):**
```js
// next.config.js
module.exports = {
  webpack: (config) => {
    config.resolve.fallback = { fs: false, path: false, os: false, crypto: false }
    return config
  }
}
```

**Fix (Turbopack, Next 16+):**
Turbopack doesn't use `webpack` config. Use the `turbopack` field:
```js
// next.config.ts
const config = {
  turbopack: {
    resolveAlias: {
      // May need to polyfill or stub specific packages
    }
  }
}
```
If a critical package can't be made Turbopack-compatible, fall back:
```bash
next dev --webpack
next build --webpack
```

#### C2. `webpack-glsl-raw-loader` — Webpack-Only Pattern

**Symptom:** GLSL shader files (`.glsl`, `.vert`, `.frag`) error out under
Turbopack with "Module parse failed".

**Root cause:** The popular pattern of importing GLSL as strings via
`raw-loader` only works under Webpack. Turbopack's loader ecosystem differs.

**Fix — Option A: Inline GLSL as template literals (bundler-agnostic):**
```ts
const vertexShader = /* glsl */ `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
  }
`
```

**Fix — Option B: Switch to TSL (Three Shading Language):**
For WebGPU path (Three.js 0.165+), prefer TSL over raw GLSL.
```ts
import { Fn, vec2, vec3, float, uv } from 'three/tsl'
import { uniform, texture } from 'three/tsl'

const myEffect = Fn(([uv]) => {
  // ... TSL node graph ...
})
```

**Fix — Option C: Stay on Webpack for shader-heavy projects:**
```bash
next dev --webpack
```

#### C3. `draco-loader-asset-fail` — Missing Decoder

**Symptom:** `useGLTF('/model.glb')` errors with "No DRACOLoader instance
provided" or hangs forever.

**Root cause:** GLTF files compressed with Draco need a WASM decoder. Three.js
ships a reference to it but the file must be served from a CDN or copied to
`public/`.

**Fix:**
```tsx
import { DRACOExporter } from 'three/addons/exporters/DRACOExporter.js'
import { useGLTF } from '@react-three/drei'

// Provide Draco decoder path (CDN or /public/draco/)
useGLTF.setDecoderPath('https://www.gstatic.com/draco/v1/decoders/')
useGLTF.setDecoderPath('/draco/')  // if self-hosting from public/draco/

// Or use KTX2 decoder for compressed textures:
useGLTF.setKTX2Path('/ktx2/')
```

### Section D: Resource Management

#### D1. `persistent-canvas-route-changes` — Lost WebGL State

**Symptom:** Navigating between routes in Next.js App Router causes
`<Canvas>` to remount, losing all 3D state (loaded models, textures,
animation progress).

**Root cause:** `<Canvas>` lives in a page component. Route changes unmount
the page, disposing the WebGL context.

**Fix — Hoist `<Canvas>` to `layout.tsx`:**
```tsx
// app/layout.tsx
'use client'
import { Canvas } from '@react-three/fiber'
import { useStore } from '@/store/scene'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <div className="canvas-container">  {/* persistent */}
          <Canvas>
            <SceneContents />
          </Canvas>
        </div>
        {children}  {/* route content swaps below the canvas */}
      </body>
    </html>
  )
}
```

Alternative: use `tunnel-rat` + drei `<View>` for embedding 3D content in
arbitrary page DOM (see react-three-next starter).

#### D2. `missing-dispose-memory-leak` — GPU Memory Growth

**Symptom:** Browser tab memory grows over time; eventually crashes.

**Root cause:** Three.js geometries, materials, and textures allocate GPU
memory. JavaScript's GC cannot free them — they must be explicitly disposed.

**Fix — Track every GPU allocation:**
```ts
class ThreeResourceManager {
  private geometries = new Set<THREE.BufferGeometry>()
  private materials = new Set<THREE.Material>()
  private textures = new Set<THREE.Texture>()

  trackGeometry(g: THREE.BufferGeometry) { this.geometries.add(g); return g }
  trackMaterial(m: THREE.Material) { this.materials.add(m); return m }
  trackTexture(t: THREE.Texture) { this.textures.add(t); return t }

  disposeAll() {
    this.geometries.forEach(g => g.dispose())
    this.materials.forEach(m => {
      // Dispose textures attached to materials
      const mat = m as any
      if (mat.map) mat.map.dispose()
      if (mat.normalMap) mat.normalMap.dispose()
      if (mat.roughnessMap) mat.roughnessMap.dispose()
      if (mat.emissiveMap) mat.emissiveMap.dispose()
      m.dispose()
    })
    this.textures.forEach(t => t.dispose())
    this.geometries.clear()
    this.materials.clear()
    this.textures.clear()
  }
}
```

**Note:** R3F handles this automatically for objects created via JSX
(`<mesh>`, `<boxGeometry>`, etc.). The above is only for objects created
imperatively via `useThree()` or raw Three.js.

**Sub-pattern — `material clone leak`:** `.clone()` on a material creates a new
GPU allocation that is NOT tracked by any manager. Always register cloned
materials: `manager.trackMaterial(mat.clone())`. This is a refinement of D2 —
the root cause is the same (missing dispose), but `.clone()` is a sneakier path
to the leak because developers assume the original manager covers the clone.

#### D3. `line-not-disposed-in-overlay-cleanup` — Overlay Line Leak

<!-- Provenance: canvastekk-frontend-nextjs/LEARNINGS/ -->

**Symptom:** Memory grows when toggling overlay visibility (measurements, annotations).

**Root cause:** `THREE.Line` objects added to an overlay group are removed from
the scene graph but never `.dispose()`d — the GPU memory is retained.

**Fix:**
```ts
function clearOverlay(group: THREE.Group) {
  group.children.forEach(child => {
    if (child instanceof THREE.Line) {
      child.geometry.dispose()
      const mat = child.material as THREE.Material
      if (Array.isArray(mat)) mat.forEach(m => m.dispose())
      else mat.dispose()
    }
  })
  group.clear()
}
```

#### D4. `perspectivecamera-cast-after-swap` — Stale Camera Reference

<!-- Provenance: canvastekk-frontend-nextjs/LEARNINGS/ -->

**Symptom:** Raycasting returns wrong results after camera swap (e.g., switching
between perspective and orthographic views).

**Root cause:** The raycaster holds a stale reference to the old camera object.
After a camera swap, `raycaster.setFromCamera()` must be called with the NEW
camera, not the one captured at initialization.

**Fix:**
```ts
// BAD — captures camera at init, never updates
const raycaster = new THREE.Raycaster()
raycaster.setFromCamera(pointer, camera) // stale after camera swap

// GOOD — always pass the current camera
function onClick(event: MouseEvent, getCurrentCamera: () => THREE.Camera) {
  const raycaster = new THREE.Raycaster()
  raycaster.setFromCamera(pointer, getCurrentCamera())
  // ...
}
```

---

## Companion Library Decision Tree

Pick companions based on what the scene needs. Each entry: package name →
one-line purpose → when to reach for it.

| Need | Library | Notes |
|---|---|---|
| Camera controls (orbit, pan, zoom) | `@react-three/drei` (`OrbitControls`, `TrackballControls`, `MapControls`) | Built into drei, not a separate package |
| Environment / lighting presets | `@react-three/drei` (`Environment`, `Lightformer`, `Sky`) | HDRI presets via `<Environment preset="city" />` |
| GLTF/GLB loading | `@react-three/drei` (`useGLTF`, `useAnimations`) + `gltfjsx` CLI | `gltfjsx` converts .glb to JSX component source |
| Text rendering | `troika-three-text` (via drei `<Text>`) | SDF text, crisp at any scale; `<Text>` is drei wrapper |
| Fat lines (variable-width) | `@react-three/drei` (`<Line>`) or `meshline` | Native Three.js `Line` is always 1px wide |
| Post-processing (bloom, SSAO, DOF) | `@react-three/postprocessing` | Wraps `postprocessing` lib; declarative `<EffectComposer>` |
| Physics | `@react-three/rapier` | Rapier WASM; rigid bodies, joints, raycasts |
| Constructive solid geometry | `@react-three/csg` | Union/subtract/intersect meshes |
| Debug GUI controls | `leva` | Sliders, color pickers, folders; sinle source of truth |
| Math helpers (easing, random) | `maath` | By pmndrs; complements Three's `MathUtils` |
| Accelerated raycasting | `three-mesh-bvh` | Mandatory for raycasting against large meshes |
| 3D UI inside scene | `@react-three/uikit` | WebGL-rendered buttons/panels (DOM-free) |
| Flexbox layout in 3D | `@react-three/flex` | Yoga-based; rare use |
| Path tracing | `@react-three/gpu-pathtracer` | Realistic GI; very expensive |
| Performance monitoring | `r3f-perf` | On-screen overlay with FPS/draw calls/memory |
| Offscreen canvas (Web Worker) | `@react-three/offscreen` | Move rendering off main thread |
| Entity Component System | `miniplex` | Game-like architecture |
| State management | `zustand` | De facto standard; also from pmndrs |
| Animation libraries | `react-spring` (physics), `maath` (easing), `theatre.js` (timeline), `framer-motion-3d` (Framer integration) | Pick one; don't mix |

### Draco / KTX2 / Meshopt Compression

For production GLTF assets, always compress:
- **Draco** — mesh compression (5–10× smaller). Needs `DRACOLoader`.
- **KTX2 / Basis** — texture compression. Needs `KTX2Loader`.
- **Meshopt** — alternative mesh compression with broader decoder support.

Tools:
- `gltf-pipeline` (CLI) — Draco compression
- `gltfpack` (CLI) — Meshopt compression
- `@react-three/gltfjsx` (CLI) — JSX component generation from .glb

---

## WebXR / AR / VR

### Two Paths

| Path | When to use |
|---|---|
| Native Three.js WebXR (`three/addons/webxr/*`) | Custom setup, R3F not in use, need fine control over XR session lifecycle |
| `@react-three/xr` v6 | R3F project — declarative `<XR>` wrapper, idiomatic React API |

### Native Three.js WebXR (no R3F)

```ts
import * as THREE from 'three'
import { VRButton } from 'three/addons/webxr/VRButton.js'
import { ARButton } from 'three/addons/webxr/ARButton.js'
import { XRControllerModelFactory } from 'three/addons/webxr/XRControllerModelFactory.js'
import { XRHandModelFactory } from 'three/addons/webxr/XRHandModelFactory.js'
import { XREstimatedLight } from 'three/addons/webxr/XREstimatedLight.js'

const renderer = new THREE.WebGLRenderer({ antialias: true })
renderer.xr.enabled = true

// VR or AR — pick one
document.body.appendChild(VRButton.createButton(renderer))
// OR: document.body.appendChild(ARButton.createButton(renderer))

const controller1 = renderer.xr.getController(0)
const controller2 = renderer.xr.getController(1)
const controllerModelFactory = new XRControllerModelFactory()
const handModelFactory = new XRHandModelFactory()

// Animation loop MUST use setAnimationLoop for XR (not requestAnimationFrame)
renderer.setAnimationLoop(() => {
  renderer.render(scene, camera)
})
```

**Gotcha in Next.js:** `'use client'` is still required. Wrap with
`dynamic(() => import('./xr-scene'), { ssr: false })`.

### React Three XR (`@react-three/xr` v6)

v6 introduced `createXRStore()` — a fundamental change from v5's
`<XR>`/`<VRButton>` JSX pattern.

```tsx
'use client'
import { Canvas } from '@react-three/fiber'
import { XR, createXRStore, XROrigin } from '@react-three/xr'

const store = createXRStore({
  // Options: offerSessionOptions, controllers, hands, emulated: true
})

export default function Page() {
  return (
    <>
      <button onClick={() => store.enterVR()}>Enter VR</button>
      <button onClick={() => store.enterAR()}>Enter AR</button>

      <Canvas>
        <XR store={store}>
          <mesh>
            <boxGeometry />
            <meshStandardMaterial color="hotpink" />
          </mesh>
        </XR>
      </Canvas>
    </>
  )
}
```

**Migration note:** v5 → v6 is a breaking change. v5 patterns
(`<VRButton>`, `<ARButton>`, `<Hands>`, `<Controllers>` as separate JSX)
are gone. The `createXRStore` + `<XR store={...}>` pattern replaces them
all.

### Browser Support Matrix

| Platform | VR | AR | Notes |
|---|---|---|---|
| Chrome (Android) | WebXR VR | WebXR AR | Full support on compatible devices |
| Chrome (Desktop) | WebXR VR | — | Requires tethered headset (Quest via Link, Index, etc.) |
| Firefox | WebXR VR | Partial | Varies |
| Safari (iOS) | — | AR via Quick Look (usdz) | **Not WebXR** — uses `<a rel="ar">` + usdz |
| Safari (macOS) | — | — | No WebXR support |
| Meta Quest Browser | WebXR VR | WebXR AR | Primary standalone VR target |
| Edge (Windows) | WebXR VR | — | Requires OpenXR headset |

**Always feature-detect, never user-agent sniff:**
```ts
if ('xr' in navigator) {
  const supported = await navigator.xr.isSessionSupported('immersive-ar')
  if (supported) { /* show AR button */ }
}
```

### Canonical WebXR Examples

- Three.js examples: https://threejs.org/examples/?q=webxr (filter by `webxr`)
- Source: https://github.com/mrdoob/three.js/tree/dev/examples/webxr
- @react-three/xr docs: https://docs.pmnd.rs/xr
- Meta Quest official R3F tutorial: https://github.com/meta-quest/webxr-first-steps-react

---

## Research Workflow (When to Consult External Sources)

This skill ships a verified-July-2026 snapshot. Three.js releases monthly,
so always consult canonical sources before recommending version-specific
APIs:

| Trigger | Action |
|---|---|
| User reports a version newer than the matrix above | `webfetch` the [Migration Guide](https://github.com/mrdoob/three.js/wiki/Migration-Guide) for their specific version range |
| User asks about an addon/API not covered here | `webfetch` https://threejs.org/docs/?q=<addon-name> or use built-in `websearch` |
| User needs an example pattern | Spawn built-in `explore` subagent to mine https://github.com/mrdoob/three.js/tree/dev/examples and https://github.com/pmndrs/<repo>/tree/main/examples for relevant working code |
| User reports a drei-specific issue | `webfetch` https://drei.pmnd.rs/ or https://github.com/pmndrs/drei/issues |
| User reports R3F reconciler weirdness | `webfetch` https://docs.pmnd.rs/react-three-fiber and the [R3F GitHub discussions](https://github.com/pmndrs/react-three-fiber/discussions) |
| User wants AR/VR pattern not covered here | Mine https://github.com/pmndrs/xr and https://github.com/meta-quest/webxr-first-steps-react |
| User mentions WebGPU / TSL / NodeMaterials | Verify against https://threejs.org/docs/?q=WebGPU — APIs are still stabilizing |

### When to Webfetch vs Delegate to `explore`

- **Single URL, known answer** → `webfetch` directly (primary session)
- **Open-ended search across multiple repos / docs** → spawn built-in `explore`
  subagent (heavy result sets stay out of primary context)
- **Needs running code to verify** → spawn built-in `general` subagent with
  bash access (rare for this skill)

---

## Authoritative Sources

| Resource | URL | Use For |
|---|---|---|
| Three.js API Docs | https://threejs.org/docs/ | Class/method reference |
| Three.js Manual | https://threejs.org/manual/ | Tutorials, basics→advanced |
| Three.js Examples | https://threejs.org/examples/ | Interactive demos for every addon |
| Three.js GitHub | https://github.com/mrdoob/three.js | Source, issues, releases |
| Three.js Migration Guide | https://github.com/mrdoob/three.js/wiki/Migration-Guide | **Read before any version bump** |
| Three.js Forum | https://discourse.threejs.org/ | Community Q&A, troubleshooting |
| R3F Docs | https://docs.pmnd.rs/react-three-fiber | R3F core API |
| Drei Storybook | https://drei.pmnd.rs/ | Interactive drei component docs |
| XR Docs | https://docs.pmnd.rs/xr | @react-three/xr tutorials |
| pmndrs GitHub Org | https://github.com/pmndrs | All R3F ecosystem repos |
| react-three-next Starter | https://github.com/pmndrs/react-three-next | Canonical Next.js + R3F architecture |
| Discover Three.js | https://discoverthreejs.com/ | Best-practices guide |
| Three.js Journey | https://threejs-journey.com/ | Premium course (R3F chapter) |
| Meta WebXR React Tutorial | https://github.com/meta-quest/webxr-first-steps-react | Official Quest + R3F guide |

---

## Related Skills

| Peer Skill | Boundary |
|---|---|
| **frontend-design-skill** | Visual aesthetics, layout, typography. This skill handles Three.js runtime correctness; frontend-design handles what the 3D scene sits inside. |
| **react-hooks-antipatterns-skill** / **react-render-antipatterns-skill** | React runtime anti-patterns (hydration, StrictMode, hooks traps). This skill covers Three.js-specific issues; many pitfalls (e.g. StrictMode double-mount) overlap — coordinate. |
| **accessibility-a11y-skill** | ARIA for canvas. Three.js `<canvas>` has no DOM semantics; this skill notes the issue but defers to a11y for screen-reader strategy. |
| **performance-optimization-skill** | WebGL perf profiling, GPU memory. This skill documents the disposal pattern; perf-optimization goes deeper into draw-call counts and shader cost. |
| **nextjs-standard-setup-skill** | Scaffolding a Next.js 16 project. Reach for it before this skill if the project doesn't exist yet; then layer Three.js on top using this skill. |

---

## Quick Reference: Minimal Working Setup

For a new Next.js 16 + R3F project, the minimum viable integration:

```bash
# Create project
npx create-next-app@latest my-3d-app --typescript --app --turbopack
cd my-3d-app

# Install Three.js stack
npm install three @react-three/fiber @react-three/drei
npm install -D @types/three
```

```tsx
// app/page.tsx
import dynamic from 'next/dynamic'

const Scene = dynamic(() => import('./scene'), { ssr: false })

export default function Page() {
  return (
    <main style={{ width: '100vw', height: '100vh' }}>
      <Scene />
    </main>
  )
}
```

```tsx
// app/scene.tsx
'use client'

import { Canvas } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'

export default function Scene() {
  return (
    <Canvas camera={{ position: [0, 0, 5] }}>
      <ambientLight intensity={0.5} />
      <directionalLight position={[5, 5, 5]} />
      <mesh>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial color="hotpink" />
      </mesh>
      <OrbitControls />
    </Canvas>
  )
}
```

That's the floor. Add drei helpers, GLTF loading, post-processing, physics,
or WebXR as needed per the decision trees above.

---

## Verification Checklist (Before Advising)

Before recommending any Three.js approach, confirm:

- [ ] User's `three` version detected (npm ls or package.json)
- [ ] User's `@react-three/fiber` version (v8 vs v9 = React 18 vs 19)
- [ ] User's React version (18 vs 19 — affects R3F major)
- [ ] Next.js version (15 vs 16 — affects Turbopack default)
- [ ] Bundler (Turbopack vs Webpack — affects GLSL/fs polyfills)
- [ ] Router (App vs Pages — affects `"use client"` discipline)
- [ ] Specific addon/API in scope (drei? xr? postprocessing? rapier?)

If any are unknown, **stop and ask** before writing version-specific code.
