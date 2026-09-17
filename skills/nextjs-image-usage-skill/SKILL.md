---
name: nextjs-image-usage-skill
description: Implement proper Next.js 16 Image component usage with configuration for remote domains, responsive images, and breaking changes from previous versions
license: Apache-2.0
compatibility: opencode
metadata:
  pattern: image-implementation
category: Framework-Specific
---

## What this skill does

- Enforces the house rule: every image in Next.js 16 code uses `<Image />`, never `<img>`
- Configures remote image sources via `remotePatterns` in `next.config.ts`
- Migrates ≤15 image code across the Next.js 16 breaking changes

## When to use

- Any `<img>` tag appears in (or is proposed for) Next.js 16 code
- Remote images fail to load / console errors about next/image configuration
- Migrating a codebase from Next.js 13/14/15 to 16
- Setting up external image domains or responsive image layouts

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
