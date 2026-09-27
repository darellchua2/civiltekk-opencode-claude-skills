# nextjs route — Next.js 16 render/action/route patterns

For `civiltekk-test-generation-skill` route `nextjs`. The shared 6-step
lifecycle (framework detection, scenario generation, confirmation,
executability verification) lives in `framework.md`; this file carries only
the Next-16-specific patterns.

## What this route covers

Unit tests for Next.js 16 App Router Server/Client Components, Server
Actions, `app/api/*/route.ts` handlers, hooks, and utilities — plus
Playwright E2E for routing and navigation when detected and explicitly
requested.

**Hard requirement:** all generated tests must pass `npm run test` before
any PR — enforced downstream by `civiltekk-pr-workflow-skill` create route
(gate contract: `verification-loop-skill`).

## Next.js 16 testing rules (the version-specific part)

- **Server Components** are async: `render(await ServerComponent())`; no hooks in tests of them
- **Client Components**: `render(<ClientComponent/>)` + interaction via `user.click(screen.getByRole(...))`
- **Server Actions**: plain async functions — call directly with FormData: `await serverAction(formData)`
- **API routes**: Request/Response handlers — `const res = await POST(new Request('http://localhost', { method: 'POST', body }))`; assert status/json
- **Framework choice**: Vitest recommended for Next 16 (ESM-native, faster); Jest works with more config; Playwright for E2E (detect from package.json; E2E only when explicitly requested)
- **E2E API mocking**: `page.route('**/api/x', route => route.fulfill({ status, contentType, body }))` — cover 200, error status, and slow-response cases

## Mock hygiene

Route-handler tests fake `Response` objects: give every fake a real
`headers` (`new Headers({...})` or a plain object), never an auto-created
mock attribute — a truthy phantom `headers.get()` masks missing-header bugs
the same way in every language. Canonical case, wrong/right examples, and
the detection command: `framework.md` §Mock Pitfalls
(`mock-headers-magicmock-truthy`).

## Scenario coverage checklist

SSR render + props for Server Components; `'use client'` interactivity + state updates; routing/navigation; image optimization; metadata generation.

> Removed 2026-09: the 500-line step-by-step workflow (framework detection transcripts, per-artifact scenario walkthroughs, full Vitest/Jest config listings, generated-example dumps), Best Practices/Common Issues/Troubleshooting ceremony — framework-generic testing knowledge; kept the Next-16-specific render/action/route patterns and the pass-before-PR contract.
