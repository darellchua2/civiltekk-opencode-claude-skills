# Route `image-usage` — Next.js 16 Image component (values)

Values for `civiltekk-nextjs-skill` route `image-usage`. The host SKILL.md
carries the METHOD (detect route → auto-convert without asking); this file
carries the house conversion policy and the version-pinned Next 16 deltas.

## What this route covers

- Enforces the house rule: every image in Next.js 16 code uses `<Image />`, never `<img>`
- Configures remote image sources via `remotePatterns` in `next.config.ts`
- Migrates ≤15 image code across the Next.js 16 breaking changes

Use when: any `<img>` tag appears in (or is proposed for) Next.js 16 code;
remote images fail to load / console errors about next/image configuration;
migrating a codebase from Next.js 13/14/15 to 16; setting up external image
domains or responsive image layouts.

**Exception:** plain `<img>` inside drei `<Html>` portals is sanctioned in
route `threejs` (pitfall `next-image-inside-drei-html`) — the optimizer is
bypassed there anyway.

## House rule: auto-convert `<img>` → `<Image />`

When an `<img>` tag is proposed in Next.js 16 code, convert it automatically:

- `import Image from 'next/image'`
- String attributes become JS props: `width="800"` → `width={800}`; `class` → `className`
- Required: `src`, `alt`, and either explicit `width`+`height` **or** `fill`
- Background / cover layouts: `fill` inside a positioned parent (`relative`/`absolute`), styling via `className="object-cover"` — not absolute-positioned `<img>`
- Remote `src` → a matching `remotePatterns` entry must exist **before** the image works
- Above the fold → add `priority`; below the fold stays lazy (default)

## Next.js 16 breaking changes (vs ≤15)

| Feature | Next.js ≤15 | Next.js 16 |
|---|---|---|
| `layout` prop | `'fill'`/`'fixed'`/`'intrinsic'`/`'responsive'` | **REMOVED** — `fill` boolean or explicit `width`/`height` |
| `objectFit` / `objectPosition` props | supported | **REMOVED** — `style={{ objectFit, objectPosition }}` |
| `unoptimized` prop | supported | **REMOVED** — custom `loader` (`({ src }) => src`) |
| `images.domains` | supported | **DEPRECATED** — use `remotePatterns` |
| `remotePatterns` | basic | **ENHANCED** — wildcard subdomains (`**.example.com`), port, pathname globs |

## Remote configuration (next.config.ts)

```typescript
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: 'cdn.trusted.com', pathname: '/images/**' },
      { protocol: 'https', hostname: '**.cloudinary.com' },
    ],
  },
}
export default nextConfig
```

Security: HTTPS only; scope `pathname` globs tightly (never blanket `/**` on a broad host); never `hostname: '**'`. `port` optional (empty = any).

## Failure → fix

- **Remote image shows placeholder/error** → hostname missing from `remotePatterns`
- **TS error on dimensions** → numeric `width`/`height`, or `fill`
- **Layout shift on load** → explicit dimensions, or `fill` + sized parent (`aspect-video` etc.)
- **Blur placeholder not rendering** → `placeholder="blur"` needs a valid base64 `blurDataURL` (pairs only)

> Removed 2026-09: component recipes (avatar/logo/gallery/hero/card), full props tables, sizes-string formats, loader implementations, per-case migration code, and verification checklists — the model knows the Image API; this file keeps the house conversion policy and the version-pinned Next 16 deltas.
