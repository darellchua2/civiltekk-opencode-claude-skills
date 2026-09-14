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

- Ensures all images use Next.js 16 Image component (not img tag)
- Configures remote domains in next.config.ts for external images
- Handles responsive images with proper sizing and priority
- Migrates from old Next.js versions to Next.js 16 Image API
- Implements image optimization for performance
- Configures image domains and patterns for security
- Uses proper placeholder and blur strategies
- Handles local and remote image sources correctly

## LLM Code Detection and Conversion

When an LLM proposes using `<img>` tags in Next.js 16 code, **automatically convert** them to the Next.js `<Image />` component equivalent.

### Detection Patterns

The LLM may propose `<img>` tags in these scenarios:

```html
<!-- Pattern 1: Basic img tag -->
<img src="/image.jpg" alt="Description" />

<!-- Pattern 2: With width/height -->
<img src="/image.jpg" alt="Description" width="800" height="600" />

<!-- Pattern 3: With class -->
<img src="/image.jpg" alt="Description" class="rounded-lg shadow-md" />

<!-- Pattern 4: Remote URL -->
<img src="https://cdn.example.com/image.jpg" alt="Description" />

<!-- Pattern 5: In JSX -->
<img src={imageUrl} alt={altText} />
```

### Conversion Rules

Always convert `<img>` to `<Image />` following these rules:

| `<img>` Attribute | Next.js 16 `<Image />` Equivalent | Notes |
|------------------|-----------------------------------|---------|
| `src="/path.jpg"` | `src="/path.jpg"` | Same (local images in public/) |
| `src="https://..."` | `src="https://..."` | Must configure remotePatterns |
| `alt="text"` | `alt="text"` | Required (same) |
| `width="800"` | `width={800}` | Change to JS number |
| `height="600"` | `height={600}` | Change to JS number |
| `class="name"` | `className="name"` | JSX class -> className |
| `loading="lazy"` | `loading="lazy"` | Same (default) |
| `style={{...}}` | `style={{...}}` | Same object syntax |

### Required Conversions

**All `<img>` tags MUST be converted** in Next.js 16:

```tsx
// ❌ INCORRECT - Plain img tag
<img src="/hero.jpg" alt="Hero banner" width="1920" height="1080" />

// ✅ CORRECT - Next.js Image component
import Image from 'next/image'
<Image src="/hero.jpg" alt="Hero banner" width={1920} height={1080} />
```

### Conversion Examples

#### Example 1: Basic img tag

```tsx
// ❌ Before (LLM proposed)
<img src="/logo.png" alt="Company Logo" />

// ✅ After (converted to Next.js Image)
import Image from 'next/image'
<Image src="/logo.png" alt="Company Logo" width={200} height={60} />
```

#### Example 2: With styling classes

```tsx
// ❌ Before (LLM proposed)
<img 
  src="/avatar.jpg" 
  alt="User Avatar" 
  class="rounded-full w-12 h-12 shadow-md"
  width="48"
  height="48"
/>

// ✅ After (converted to Next.js Image)
import Image from 'next/image'
<Image 
  src="/avatar.jpg" 
  alt="User Avatar" 
  className="rounded-full w-12 h-12 shadow-md"
  width={48}
  height={48}
/>
```

#### Example 3: Dynamic source

```tsx
// ❌ Before (LLM proposed)
interface Props {
  imageUrl: string
  altText: string
}

export function ProductImage({ imageUrl, altText }: Props) {
  return <img src={imageUrl} alt={altText} width={400} height={300} />
}

// ✅ After (converted to Next.js Image)
import Image from 'next/image'

interface Props {
  imageUrl: string
  altText: string
}

export function ProductImage({ imageUrl, altText }: Props) {
  return <Image src={imageUrl} alt={altText} width={400} height={300} />
}
```

#### Example 4: Remote image

```tsx
// ❌ Before (LLM proposed - won't work without config)
<img 
  src="https://cdn.example.com/photo.jpg" 
  alt="Photo" 
  width={800} 
  height={600}
/>

// ✅ After (converted to Next.js Image - requires remote config)
import Image from 'next/image'

// Configure remotePatterns first:
// next.config.ts:
// images: { remotePatterns: [{ protocol: 'https', hostname: 'cdn.example.com', pathname: '/**' }] }

<Image 
  src="https://cdn.example.com/photo.jpg" 
  alt="Photo" 
  width={800} 
  height={600}
/>
```

#### Example 5: Background image (CSS)

```tsx
// ❌ Before (LLM proposed - img tag not suitable for background)
<div className="relative">
  <img 
    src="/bg.jpg" 
    alt="" 
    class="absolute inset-0 object-cover"
  />
  <div className="relative z-10">Content</div>
</div>

// ✅ After (converted to Next.js Image with fill prop)
import Image from 'next/image'

<div className="relative">
  <Image 
    src="/bg.jpg" 
    alt="" 
    fill
    className="object-cover"
  />
  <div className="relative z-10">Content</div>
</div>
```

#### Example 6: Gallery of images

```tsx
// ❌ Before (LLM proposed - multiple img tags)
export function Gallery({ images }: { images: string[] }) {
  return (
    <div className="grid grid-cols-3 gap-4">
      {images.map((src, index) => (
        <img 
          key={index} 
          src={src} 
          alt={`Gallery image ${index + 1}`}
          width={400}
          height={300}
          loading="lazy"
        />
      ))}
    </div>
  )
}

// ✅ After (converted to Next.js Image components)
import Image from 'next/image'

export function Gallery({ images }: { images: string[] }) {
  return (
    <div className="grid grid-cols-3 gap-4">
      {images.map((src, index) => (
        <Image 
          key={index} 
          src={src} 
          alt={`Gallery image ${index + 1}`}
          width={400}
          height={300}
          loading="lazy"
        />
      ))}
    </div>
  )
}
```

### Automatic Conversion Checklist

When LLM proposes `<img>` tags, verify:

- [ ] Replace all `<img>` tags with `<Image />` component
- [ ] Import `Image` from `next/image`
- [ ] Convert string attributes to JavaScript props (numbers, objects)
- [ ] Change `class` to `className`
- [ ] Add required `width` and `height` props (or `fill`)
- [ ] Ensure all images have `alt` text for accessibility
- [ ] Configure `remotePatterns` in next.config.ts for remote images
- [ ] Use `fill` prop instead of CSS positioning for backgrounds
- [ ] Add `loading="lazy"` for images below fold
- [ ] Add `priority` prop for images above fold

### Why Convert img to Image?

**Performance Benefits:**
- Automatic optimization (WebP, AVIF formats)
- Responsive image generation
- Lazy loading by default
- Priority loading for critical images
- Reduced bandwidth usage

**DX Benefits:**
- Better TypeScript support
- Consistent API across project
- Built-in error handling
- Automatic blur placeholder support

**SEO Benefits:**
- Proper alt text enforcement
- Better accessibility scores
- Optimized images for faster LCP
- Core Web Vitals improvement

### Common Conversion Mistakes to Avoid

#### Mistake 1: Keeping img for dynamic images

```tsx
// ❌ Wrong - Still using img
<Image src={dynamicUrl} alt="Dynamic" />

// ✅ Correct - Already converted (this is right)
// Actually, this IS correct - Image works with dynamic URLs!
```

#### Mistake 2: Forgetting to import Image

```tsx
// ❌ Missing import
<Image src="/image.jpg" alt="Image" width={800} height={600} />

// ✅ Include import
import Image from 'next/image'
<Image src="/image.jpg" alt="Image" width={800} height={600} />
```

#### Mistake 3: String instead of number props

```tsx
// ❌ Wrong - Strings for width/height
<Image src="/image.jpg" alt="Image" width="800" height="600" />

// ✅ Correct - Numbers for width/height
<Image src="/image.jpg" alt="Image" width={800} height={600} />
```

#### Mistake 4: Missing required props

```tsx
// ❌ Wrong - Missing dimensions (and no fill)
<Image src="/image.jpg" alt="Image" />

// ✅ Correct - Has width/height or fill
<Image src="/image.jpg" alt="Image" width={800} height={600} />
// OR
<Image src="/image.jpg" alt="Image" fill />
```

## When to use

Use this when:
- Displaying images in Next.js 16 applications
- LLM proposes `<img>` tags that need conversion
- Migrating from Next.js 13/14/15 to Next.js 16
- Images not loading or showing placeholder icons
- Need to configure external image domains
- Implementing responsive image layouts
- Optimizing image loading performance
- Setting up image placeholders or blur effects

**Common signals:**
- LLM suggests `<img>` tags in Next.js code
- Using `<img>` tags instead of `<Image />` component
- Remote images not displaying
- Console errors about "next/image" configuration
- Images appearing slowly or unoptimized
- Need to load images from external domains
- Placeholder images not working

## Next.js 16 Image Component Changes

### Breaking Changes from Previous Versions

| Feature | Next.js < 16 | Next.js 16+ |
|----------|----------------|--------------|
| Import Path | `next/image` (same) | `next/image` (same) |
| `unoptimized` | Supported | **Removed** - Use custom loader |
| `layout` prop | `'fill'`, `'fixed'`, `'intrinsic'`, `'responsive'` | **Removed** - Use `fill` boolean or explicit sizing |
| `objectFit` prop | Supported | **Removed** - Use `style={{ objectFit: ... }}` |
| `objectPosition` prop | Supported | **Removed** - Use `style={{ objectPosition: ... }}` |
| Default loader | `loader()` function | Simplified loader interface |
| Remote patterns | `remotePatterns` in config | **Enhanced** - More powerful matching |

### Key Changes in Next.js 16

1. **Removed `layout` prop**: Use explicit width/height or `fill` prop instead
2. **Removed `objectFit` and `objectPosition`**: Use CSS `style` object instead
3. **Removed `unoptimized`**: Use custom `loader` for unoptimized images
4. **Enhanced remote patterns**: More flexible domain and pattern matching
5. **Better TypeScript types**: Improved type safety for Image props

## Configuration

### Remote Domains Configuration

Configure external image domains in `next.config.ts`:

```typescript
// next.config.ts
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
        port: '',
        pathname: '/images/**',
      },
      {
        protocol: 'https',
        hostname: '**.cloudinary.com',
      },
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/static/**',
      },
    ],
  },
}

export default nextConfig
```

### Remote Patterns Options

```typescript
const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        // Required: Protocol (http, https, or both)
        protocol: 'https',

        // Required: Domain hostname (supports wildcards)
        hostname: 'example.com',
        hostname: '**.example.com',  // Matches subdomains

        // Optional: Port number
        port: '',  // Empty means any port
        port: '443',  // Specific port

        // Optional: Path pattern (glob pattern)
        pathname: '/images/**',
        pathname: '/static/**.jpg',
        pathname: '/uploads/**/*.png',
      },
    ],
  },
}
```

### Domain vs. Patterns

**Old Way (deprecated in Next.js 16):**
```typescript
// ❌ Deprecated - use remotePatterns instead
const nextConfig = {
  images: {
    domains: ['example.com', 'cdn.example.com'],
  },
}
```

**New Way (recommended):**
```typescript
// ✅ Use remotePatterns for Next.js 16+
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
        pathname: '/**',
      },
    ],
  },
}
```

## Basic Image Usage

### Import the Component

```typescript
import Image from 'next/image'
```

### Local Images

Import and use local images from `public/` directory:

```typescript
import Image from 'next/image'
import heroImage from '@/public/hero.jpg'

/**
 * Hero section with local image.
 *
 * @returns Hero section component
 */
export function HeroSection() {
  return (
    <div className="relative">
      <Image
        src={heroImage}
        alt="Hero banner showing our product"
        width={1920}
        height={1080}
        priority
      />
    </div>
  )
}
```

### Remote Images

Use remote URLs with configured domains:

```typescript
import Image from 'next/image'

/**
 * User profile with remote avatar image.
 *
 * @param userId - User identifier
 * @returns User profile component
 */
export function UserProfile({ userId }: { userId: string }) {
  return (
    <div className="flex items-center gap-4">
      <Image
        src={`https://cdn.example.com/avatars/${userId}.jpg`}
        alt={`User ${userId} avatar`}
        width={64}
        height={64}
        className="rounded-full"
      />
      <div>User {userId}</div>
    </div>
  )
}
```

### Dynamic Remote Images

```typescript
import Image from 'next/image'

interface ProductProps {
  id: string
  name: string
  imageUrl: string
}

/**
 * Product card with dynamic remote image.
 *
 * @param product - Product data including image URL
 * @returns Product card component
 */
export function ProductCard({ id, name, imageUrl }: ProductProps) {
  return (
    <div className="product-card">
      <Image
        src={imageUrl}
        alt={name}
        width={400}
        height={300}
        className="product-image"
        loading="lazy"
      />
      <h3>{name}</h3>
    </div>
  )
}
```

## Image Props (Next.js 16)

### Required Props

| Prop | Type | Description |
|------|-------|-------------|
| `src` | `string` or `StaticImageData` | Image source (URL or import) |
| `alt` | `string` | Alt text for accessibility (required) |
| `width` | `number` | Width in pixels (required unless `fill`) |
| `height` | `number` | Height in pixels (required unless `fill`) |

### Common Props

| Prop | Type | Default | Description |
|------|-------|----------|-------------|
| `fill` | `boolean` | `false` | Fill parent container |
| `priority` | `boolean` | `false` | Load image with high priority |
| `loading` | `'lazy' \| 'eager'` | `'lazy'` | Loading strategy |
| `quality` | `number` | `75` | Image quality (1-100) |
| `placeholder` | `'blur' \| 'empty'` | `undefined` | Placeholder type |
| `blurDataURL` | `string` | - | Base64 blur data URL |
| `sizes` | `string` | - | Responsive sizes string |
| `className` | `string` | - | CSS class names |
| `style` | `CSSProperties` | - | Inline styles |

## Responsive Images

### Using Sizes Prop

```typescript
import Image from 'next/image'

/**
 * Responsive banner image.
 *
 * Sizes string determines which image size to load
 * based on the viewport width.
 *
 * @returns Responsive banner component
 */
export function ResponsiveBanner() {
  return (
    <Image
      src="/banner.jpg"
      alt="Promotional banner"
      width={1920}
      height={600}
      // Load different sizes based on viewport
      sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
      className="w-full"
    />
  )
}
```

### Sizes String Format

```typescript
// Full width on mobile, half on tablet, third on desktop
sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"

// Fixed width on mobile, half on desktop
sizes="50vw"

// Full width always
sizes="100vw"

// Different breakpoints
sizes="
  (max-width: 640px) 100vw,
  (max-width: 1024px) 50vw,
  33vw
"
```

### Responsive Width/Height

```typescript
/**
 * Image that adapts to container.
 *
 * Uses fill prop to match parent dimensions.
 *
 * @param src - Image source
 * @returns Responsive image component
 */
export function ResponsiveImage({ src }: { src: string }) {
  return (
    <div className="relative w-full aspect-video">
      <Image
        src={src}
        alt="Responsive image"
        fill
        className="object-cover"
        sizes="100vw"
      />
    </div>
  )
}
```

## Placeholder Images

### Blur Placeholder

```typescript
import Image from 'next/image'

/**
 * Image with blur placeholder effect.
 *
 * Blur placeholder loads a low-quality version
 * that transitions to full quality when loaded.
 *
 * @param src - Image source
 * @param blurData - Base64 encoded blur data
 * @returns Image with blur effect
 */
export function BlurredImage({
  src,
  blurData
}: {
  src: string
  blurData: string
}) {
  return (
    <Image
      src={src}
      alt="Image with blur placeholder"
      placeholder="blur"
      blurDataURL={blurData}
      width={800}
      height={600}
    />
  )
}
```

### Generate Blur Data

```typescript
import { getImageProps } from 'next/image'

/**
 * Generate blur data for local image.
 *
 * @param src - Local image import
 * @returns Blur data URL
 */
export function getBlurData(src: string) {
  const props = getImageProps(src)
  return props.blurDataURL || ''
}
```

### Empty Placeholder

```typescript
/**
 * Image with empty placeholder.
 *
 * Shows transparent placeholder until image loads.
 *
 * @param src - Image source
 * @returns Image with empty placeholder
 */
export function EmptyPlaceholderImage({ src }: { src: string }) {
  return (
    <Image
      src={src}
      alt="Image with empty placeholder"
      placeholder="empty"
      width={800}
      height={600}
    />
  )
}
```

## Fill Images

### Background Image

```typescript
/**
 * Full-width background image using fill prop.
 *
 * @param src - Image source URL
 * @returns Full-screen background image
 */
export function BackgroundImage({ src }: { src: string }) {
  return (
    <div className="absolute inset-0 -z-10">
      <Image
        src={src}
        alt="Background"
        fill
        className="object-cover"
        priority
      />
    </div>
  )
}
```

### Card Cover Image

```typescript
/**
 * Card with cover image that fills container.
 *
 * @param imageSrc - Image source URL
 * @param title - Card title
 * @returns Card component with cover image
 */
export function ImageCard({ imageSrc, title }: { imageSrc: string; title: string }) {
  return (
    <div className="relative h-64 w-full overflow-hidden rounded-lg">
      <Image
        src={imageSrc}
        alt={title}
        fill
        className="object-cover"
      />
      <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/60 to-transparent p-4">
        <h3 className="text-white text-lg font-semibold">{title}</h3>
      </div>
    </div>
  )
}
```

## Custom Loaders

### Unoptimized Images

```typescript
import Image, { ImageLoader } from 'next/image'

/**
 * Custom loader for unoptimized images.
 *
 * Bypasses Next.js optimization and loads images
 * directly from source. Use for dynamic images
 * that change frequently.
 *
 * @param src - Image source URL
 * @param width - Requested image width
 * @param quality - Requested image quality
 * @returns Unoptimized image URL
 */
const unoptimizedLoader: ImageLoader = ({ src, width, quality }) => {
  return `${src}?w=${width}&q=${quality || 75}`
}

/**
 * Component using custom loader.
 *
 * @param src - Dynamic image source
 * @returns Unoptimized image component
 */
export function DynamicImage({ src }: { src: string }) {
  return (
    <Image
      src={src}
      alt="Dynamic image"
      loader={unoptimizedLoader}
      width={800}
      height={600}
    />
  )
}
```

### CDN Loader

```typescript
import Image, { ImageLoader } from 'next/image'

/**
 * CDN-specific image loader.
 *
 * Formats URL for CDN with optimization parameters.
 *
 * @param src - Image source path
 * @param width - Requested width
 * @param quality - Requested quality
 * @returns CDN URL with parameters
 */
const cdnLoader: ImageLoader = ({ src, width, quality }) => {
  return `https://cdn.example.com/images/${src}?w=${width}&q=${quality || 75}&fmt=webp`
}

/**
 * Image using CDN loader.
 *
 * @param imagePath - Image path (without domain)
 * @returns CDN-optimized image
 */
export function CDNImage({ imagePath }: { imagePath: string }) {
  return (
    <Image
      src={imagePath}
      alt="CDN image"
      loader={cdnLoader}
      width={600}
      height={400}
    />
  )
}
```

## Common Patterns

### Avatar Component

```typescript
import Image from 'next/image'

/**
 * User avatar component with styling.
 *
 * @param src - Avatar image URL
 * @param size - Avatar size in pixels (default: 48)
 * @param alt - Alt text for avatar
 * @returns Styled avatar component
 */
export function Avatar({
  src,
  size = 48,
  alt = 'User avatar'
}: {
  src: string
  size?: number
  alt?: string
}) {
  return (
    <div className="relative overflow-hidden rounded-full">
      <Image
        src={src}
        alt={alt}
        width={size}
        height={size}
        className="rounded-full"
      />
    </div>
  )
}
```

### Logo Component

```typescript
import Image from 'next/image'

/**
 * Company logo component with proper sizing.
 *
 * @param src - Logo image URL
 * @param height - Logo height (width calculated from aspect ratio)
 * @param alt - Company name for alt text
 * @returns Logo component
 */
export function Logo({
  src,
  height = 40,
  alt = 'Company logo'
}: {
  src: string
  height?: number
  alt?: string
}) {
  return (
    <div className="relative h-[40px]">
      <Image
        src={src}
        alt={alt}
        height={height}
        width={height * 2} // Assuming 2:1 aspect ratio
        className="object-contain"
      />
    </div>
  )
}
```

### Gallery Image

```typescript
import Image from 'next/image'
import { useState } from 'react'

/**
 * Gallery image with lightbox functionality.
 *
 * @param src - Image source URL
 * @param caption - Image caption
 * @returns Gallery image component
 */
export function GalleryImage({
  src,
  caption
}: {
  src: string
  caption: string
}) {
  const [isLoaded, setIsLoaded] = useState(false)

  return (
    <figure className="relative">
      <Image
        src={src}
        alt={caption}
        width={800}
        height={600}
        className={`transition-opacity duration-300 ${isLoaded ? 'opacity-100' : 'opacity-0'}`}
        onLoad={() => setIsLoaded(true)}
        loading="lazy"
      />
      {!isLoaded && (
        <div className="absolute inset-0 bg-gray-200 animate-pulse" />
      )}
      <figcaption className="mt-2 text-sm text-gray-600">{caption}</figcaption>
    </figure>
  )
}
```

## Migration Guide

### From Next.js 15 to 16

#### Remove Layout Prop

```typescript
// ❌ Next.js 15 - layout prop removed in 16
<Image
  src="/image.jpg"
  alt="Image"
  layout="responsive"
  width={800}
  height={600}
/>

// ✅ Next.js 16 - use fill prop or explicit sizing
<Image
  src="/image.jpg"
  alt="Image"
  width={800}
  height={600}
/>
```

#### Remove objectFit/ObjectPosition Props

```typescript
// ❌ Next.js 15 - props removed in 16
<Image
  src="/image.jpg"
  alt="Image"
  objectFit="cover"
  objectPosition="center"
  fill
/>

// ✅ Next.js 16 - use style object
<Image
  src="/image.jpg"
  alt="Image"
  fill
  style={{
    objectFit: 'cover',
    objectPosition: 'center'
  }}
/>
```

#### Replace Unoptimized Prop

```typescript
// ❌ Next.js 15 - unoptimized prop removed in 16
<Image
  src="/image.jpg"
  alt="Image"
  unoptimized
/>

// ✅ Next.js 16 - use custom loader
const unoptimizedLoader: ImageLoader = ({ src }) => src

<Image
  src="/image.jpg"
  alt="Image"
  loader={unoptimizedLoader}
  width={800}
  height={600}
/>
```

#### Update Domain Configuration

```typescript
// ❌ Next.js 15 - domains deprecated
const nextConfig = {
  images: {
    domains: ['example.com', 'cdn.example.com'],
  },
}

// ✅ Next.js 16 - use remotePatterns
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'cdn.example.com',
        pathname: '/**',
      },
    ],
  },
}
```

## Best Practices

### Accessibility

- **Always provide alt text**: Describe the image for screen readers
- **Alt text should be descriptive**: Not just "image" or "photo"
- **Decorative images**: Use empty alt text `alt=""`
- **Avoid "Image of"**: Alt text should start with the subject

```typescript
// ✅ Good alt text
<Image src="/dog.jpg" alt="Golden retriever playing in park" />

// ❌ Bad alt text
<Image src="/dog.jpg" alt="Image of a dog" />
```

### Performance

- **Use `priority` for above-fold images**: Load critical images first
- **Use `loading="lazy"` for below-fold**: Defer loading off-screen images
- **Provide proper sizes**: Help browser select correct image size
- **Optimize image quality**: Use quality prop (75-85 recommended)
- **Use blur placeholders**: Improve perceived performance

```typescript
// Above-fold - use priority
<Image src="/hero.jpg" alt="Hero" priority />

// Below-fold - use lazy loading
<Image src="/gallery.jpg" alt="Gallery" loading="lazy" />
```

### Security

- **Configure remote patterns**: Only allow trusted domains
- **Use specific paths**: Don't allow wildcard `/**` for all paths
- **HTTPS only**: Always use HTTPS for remote patterns
- **Validate image URLs**: Sanitize user-provided image URLs

```typescript
// ✅ Secure - specific domain and path
{
  protocol: 'https',
  hostname: 'cdn.trusted.com',
  pathname: '/images/**',
}

// ❌ Insecure - wildcard on everything
{
  protocol: 'https',
  hostname: '**',
  pathname: '/**',
}
```

### Responsive Design

- **Use sizes prop**: Ensure correct image size loads
- **Test on multiple viewports**: Verify images load properly
- **Use fill for flexible layouts**: Match parent container
- **Maintain aspect ratio**: Avoid layout shifts

## Common Issues and Solutions

### Remote Images Not Loading

**Issue:** External images showing placeholder or error

**Solution:** Add domain to `remotePatterns` in next.config.ts

```typescript
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'your-domain.com',
        pathname: '/**',
      },
    ],
  },
}
```

### Type Errors on width/height

**Issue:** TypeScript error when width/height is unknown

**Solution:** Use fill prop or define explicit dimensions

```typescript
// ❌ Missing width/height
<Image src="/image.jpg" alt="Image" />

// ✅ With explicit dimensions
<Image src="/image.jpg" alt="Image" width={800} height={600} />

// ✅ With fill prop
<Image src="/image.jpg" alt="Image" fill />
```

### Layout Shift Issues

**Issue:** Page content jumps when images load

**Solution:** Reserve space for images with proper dimensions or fill

```typescript
// Reserve space with explicit dimensions
<Image src="/image.jpg" alt="Image" width={800} height={600} />

// Or use fill with parent container
<div className="relative aspect-video">
  <Image src="/image.jpg" alt="Image" fill />
</div>
```

### Slow Image Loading

**Issue:** Images taking too long to load

**Solution:** Use priority, quality, and blur placeholders

```typescript
<Image
  src="/critical.jpg"
  alt="Critical image"
  priority        // Load first
  quality={85}      // Balance quality and size
  placeholder="blur" // Show placeholder while loading
  blurDataURL="data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  width={800}
  height={600}
/>
```

### Blur Data Not Working

**Issue:** Blur placeholder not showing

**Solution:** Ensure blurDataURL is valid base64 string

```typescript
// Generate blur data properly
import { getPlaiceholder } from 'plaiceholder'

const { base64 } = await getPlaiceholder(800, 600)

<Image
  src="/image.jpg"
  alt="Image"
  width={800}
  height={600}
  placeholder="blur"
  blurDataURL={base64} // Valid base64 string
/>
```

### Images Not Optimizing

**Issue:** Images not being optimized by Next.js

**Solution:** Ensure images are in public/ or properly configured

```typescript
// Local images - place in public/
import image from '@/public/image.jpg'  // ✅ Will optimize

// Remote images - configure remotePatterns
const nextConfig = {
  images: {
    remotePatterns: [{ protocol: 'https', hostname: 'example.com', pathname: '/**' }],
  },
}
```

## Verification Checklist

After implementation, verify:

### Configuration
- [ ] Remote domains configured in next.config.ts
- [ ] Remote patterns use HTTPS protocol
- [ ] Specific paths defined instead of wildcards
- [ ] Image optimization enabled

### Image Usage
- [ ] All images use Next.js Image component (not img tag)
- [ ] Alt text provided for all images
- [ ] Width and height specified (or fill prop used)
- [ ] Proper sizes string for responsive images
- [ ] Priority prop for above-fold images
- [ ] Lazy loading for below-fold images

### Performance
- [ ] Images load without layout shift
- [ ] Blurry placeholders during load (optional)
- [ ] Appropriate image quality (75-85)
- [ ] Responsive images work on all viewports
- [ ] Images optimized and served in WebP

### Accessibility
- [ ] All images have descriptive alt text
- [ ] Decorative images use empty alt text
- [ ] Alt text doesn't start with "Image of"
- [ ] Screen readers can read image descriptions

### TypeScript
- [ ] No TypeScript errors on Image props
- [ ] Types for src, width, height correct
- [ ] Custom loaders properly typed
- [ ] Fill props used correctly in TypeScript

