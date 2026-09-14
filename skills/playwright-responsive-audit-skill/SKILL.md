---
name: playwright-responsive-audit-skill
description: >-
  Responsive-audit methodology — 6 Playwright detection assertions, 3
  fix-confidence tiers, detect-fix-re-verify loop. Loaded by
  responsive-audit-subagent only, not auto-triggered.
license: Apache-2.0
compatibility: opencode
metadata:
  protocol: autoresearch-opt-in
category: Responsive & Visual Testing
---

## What I do

I define the methodology for auditing and fixing responsive UI defects in Next.js (or any web) projects using Playwright. This is a **checker-and-fixer** capability: detect responsive issues, apply fixes by confidence tier, and emit permanent regression specs.

## When to use me

Loaded exclusively by `responsive-audit-subagent` via `permission.skill`. Not auto-triggered. The primary session spawns the subagent once; the subagent runs the closed loop internally over a persistent PTY session (detect→fix→re-verify), delegating only screenshot review to `image-analyzer-subagent`.

## Prerequisite: Playwright Setup

Before running any responsive audit, Playwright must be installed and configured in the target project. This section covers detection, installation, auth setup, fixtures, and E2E best practices.

### Step 0a: Detect if Playwright is Installed

```bash
# Check for Playwright config and dependencies
if [ ! -f "playwright.config.ts" ] || ! grep -q "@playwright/test" package.json 2>/dev/null; then
  echo "PLAYWRIGHT_NOT_INSTALLED"
else
  echo "PLAYWRIGHT_INSTALLED"
fi
```

### Step 0b: Install Playwright (If Not Detected)

If `PLAYWRIGHT_NOT_INSTALLED`, run the full installation sequence:

```bash
# 1. Install Playwright and its test runner
npm init playwright@latest -- --quiet --browser=chromium

# 2. Install browser binaries (chromium is enough for CI; add firefox/webkit for cross-browser)
npx playwright install chromium
npx playwright install-deps chromium

# 3. Verify installation
npx playwright --version
```

**For existing Next.js projects** that already have a test runner (Vitest/Jest), Playwright coexists fine — install as a separate dependency:

```bash
npm install -D @playwright/test
npx playwright install chromium
```

### Step 0c: Configure `playwright.config.ts`

Full configuration with responsive viewport matrix, auth, and best-practice settings:

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  // Test directory
  testDir: './e2e',

  // Fail fast on CI, allow retries locally
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,

  // Reporter
  reporter: process.env.CI
    ? [['html', { open: 'never' }], ['github']]
    : 'html',

  // Shared settings for all projects
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://localhost:3000',

    // Trace on failure (debugging gold)
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',

    // Auth state (shared across all projects)
    storageState: 'e2e/.auth/user.json',
  },

  // Projects: responsive viewport matrix
  projects: [
    // Auth setup runs first (no storageState yet)
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
      use: {
        storageState: undefined, // Don't load state during setup
      },
    },

    // Desktop
    {
      name: 'desktop-chromium',
      dependencies: ['setup'],
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },

    // Mobile (touch)
    {
      name: 'mobile-chrome',
      dependencies: ['setup'],
      use: {
        ...devices['Pixel 5'],
        viewport: { width: 375, height: 667 },
        hasTouch: true,
      },
    },

    // Tablet (touch)
    {
      name: 'tablet',
      dependencies: ['setup'],
      use: {
        ...devices['iPad (gen 7)'],
        viewport: { width: 768, height: 1024 },
        hasTouch: true,
      },
    },
  ],

  // Auto-start dev server
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```

### Step 0d: Auth Setup

Authentication is handled via Playwright's `storageState` pattern — log in once, save cookies/localStorage, reuse across all tests.

**File:** `e2e/auth.setup.ts`

```typescript
import { test as setup, expect } from '@playwright/test';

const AUTH_FILE = 'e2e/.auth/user.json';

setup('authenticate', async ({ page }) => {
  // Navigate to login page
  await page.goto('/login');

  // Fill credentials from environment
  await page.fill('[data-testid="email"]', process.env.E2E_USER_EMAIL || '');
  await page.fill('[data-testid="password"]', process.env.E2E_USER_PASSWORD || '');
  await page.click('[data-testid="login-button"]');

  // Wait for authenticated state (adjust selector to your app)
  await expect(page).toHaveURL(/\/dashboard|\/home/);
  await expect(page.locator('[data-testid="user-menu"]')).toBeVisible();

  // Save auth state
  await page.context().storageState({ path: AUTH_FILE });
});
```

**`.gitignore` addition:**
```
e2e/.auth/
```

**Environment variables** (`.env.local` or CI secrets):
```
E2E_USER_EMAIL=test@example.com
E2E_USER_PASSWORD=secure-password
E2E_BASE_URL=http://localhost:3000
```

### Step 0e: Test Directory Structure

Recommended structure for a mature E2E setup:

```
e2e/
├── auth.setup.ts              # Authentication setup (runs first)
├── .auth/
│   └── user.json              # Saved storageState (gitignored)
├── fixtures/
│   ├── navigation.ts          # Route constants + page object helpers
│   ├── test-data.ts           # Test data factories
│   └── skip-helpers.ts        # Conditional skip utilities
├── baselines/                 # Wireframer baselines (for responsive audit)
│   └── slope/
│       ├── mobile.wireframe.html
│       ├── tablet.wireframe.html
│       └── desktop.wireframe.html
├── responsive/                # Responsive regression specs
│   └── slope.responsive.spec.ts
├── pages/                     # Page Object Models (optional)
│   ├── login.page.ts
│   └── dashboard.page.ts
├── specs/                     # Functional E2E specs
│   ├── auth.spec.ts
│   └── navigation.spec.ts
└── playwright.config.ts       # Config (project root or here)
```

### Step 0f: Fixtures & Helpers

#### Navigation Fixtures (`e2e/fixtures/navigation.ts`)

Centralize route constants and navigation helpers:

```typescript
export const ROUTES = {
  login: '/login',
  dashboard: '/dashboard',
  projects: '/projects',
  reportSlope: (projectId: string) => `/projects/${projectId}/reports/slope`,
  reportDefects: (projectId: string) => `/projects/${projectId}/reports/defects`,
} as const;

export async function navigateTo(page, route: string) {
  await page.goto(route);
  await page.waitForLoadState('networkidle');
}

export async function waitForApiResponse(
  page,
  urlPattern: string | RegExp,
  timeout = 10_000
) {
  return page.waitForResponse(
    (resp) => resp.url().match(urlPattern) && resp.status() === 200,
    { timeout }
  );
}
```

#### Test Data Fixtures (`e2e/fixtures/test-data.ts`)

Factory functions for test data — never hardcode IDs in specs:

```typescript
export const TEST_PROJECT = {
  id: process.env.E2E_TEST_PROJECT_ID || 'test-project-001',
  name: 'E2E Test Project',
} as const;

export const TEST_USER = {
  email: process.env.E2E_USER_EMAIL || 'test@example.com',
  name: 'E2E Test User',
} as const;

export function generateTestId(prefix = 'test'): string {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}
```

#### Skip Helpers (`e2e/fixtures/skip-helpers.ts`)

Conditional test skipping based on environment or feature availability:

```typescript
import { test } from '@playwright/test';

export function skipIfMissingEnv(key: string) {
  if (!process.env[key]) {
    test.skip(true, `Missing ${key} environment variable`);
  }
}

export function skipOnMobile(projectName: string) {
  test.skip(projectName === 'mobile-chrome', 'Desktop-only test');
}

export function skipIfNoBackend(url: string) {
  test.beforeAll(async ({ request }) => {
    try {
      const resp = await request.get(url, { timeout: 3_000 });
      test.skip(resp.status() >= 500, `Backend unavailable at ${url}`);
    } catch {
      test.skip(true, `Backend unreachable at ${url}`);
    }
  });
}
```

### E2E Best Practices

#### Test Isolation

| Practice | Why |
|---|---|
| Each test creates its own data | Tests don't depend on execution order or shared state |
| Use `test.beforeEach` for common setup | Reduces duplication, ensures consistent starting state |
| Never share `page` across tests | Playwright creates fresh contexts per test by default — don't override this |
| Use `storageState` for auth, not per-test login | One login at setup time, all tests reuse the saved state |

#### Selectors

| Practice | Why |
|---|---|
| Prefer `data-testid` over CSS/text selectors | Survives refactoring, doesn't break on copy changes |
| Use `getByRole()`, `getByText()` for user-facing assertions | Tests user-visible behavior, not implementation |
| Avoid `nth-child`, `xpath` unless no alternative | Brittle, breaks on DOM reordering |

```typescript
// GOOD — stable, semantic
await page.getByTestId('submit-button').click();
await expect(page.getByRole('alert')).toContainText('Success');

// BAD — brittle, implementation-dependent
await page.click('.css-1abc123 > div:nth-child(2) button');
```

#### Waiting

| Practice | Why |
|---|---|
| Use `expect(locator).toBeVisible()` | Auto-retries until timeout, no flakiness |
| Use `waitForResponse()` for API-driven actions | Asserts the backend actually responded before proceeding |
| Use `waitForLoadState('networkidle')` sparingly | Can hang on long-polling/websocket connections |
| **Never** use `page.waitForTimeout()` in production tests | Fixed delays are the #1 cause of flaky tests |

```typescript
// GOOD — waits for actual state
await expect(page.getByTestId('results-table')).toBeVisible();
await page.waitForResponse((r) => r.url().includes('/api/results') && r.ok());

// BAD — arbitrary delay
await page.waitForTimeout(2000);
```

#### CI/CD Integration

```yaml
# GitHub Actions example
- name: Install Playwright
  run: npx playwright install --with-deps chromium

- name: Run E2E tests
  run: npx playwright test
  env:
    CI: true
    E2E_BASE_URL: ${{ vars.E2E_BASE_URL }}
    E2E_USER_EMAIL: ${{ secrets.E2E_USER_EMAIL }}
    E2E_USER_PASSWORD: ${{ secrets.E2E_USER_PASSWORD }}

- name: Upload test report
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: playwright-report
    path: playwright-report/
    retention-days: 30
```

#### Debugging

| Command | Use For |
|---|---|
| `npx playwright test --debug` | Step-through debugging with Playwright Inspector |
| `npx playwright test --ui` | Interactive UI mode (watch mode + timeline) |
| `npx playwright show-trace trace.zip` | View trace after failure (screenshots, DOM, network) |
| `npx playwright test --project=mobile-chrome` | Run only mobile project |
| `npx playwright test --grep "auth"` | Run tests matching pattern |

#### `package.json` Scripts

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug",
    "test:e2e:mobile": "playwright test --project=mobile-chrome",
    "test:e2e:responsive": "playwright test e2e/responsive/",
    "test:e2e:report": "playwright show-report"
  }
}
```

---

## Audit Process Overview

```
1. Configure viewport matrix (mobile, tablet, desktop)
2. For each target page:
   a. Navigate at each breakpoint
   b. Run 6 detection assertions
   c. Classify defects by fix-confidence tier
3. Apply fixes (Tier 1 auto, Tier 2 propose+verify, Tier 3 report)
4. Re-audit ALL viewports after each fix
5. Repeat until clean or iteration cap reached
6. Emit regression spec locking the fixed state
```

---

## 6 Detection Assertions

Each assertion runs at every breakpoint (mobile, tablet, desktop). Use Playwright's `page.evaluate()` for DOM measurements.

### 1. Horizontal Overflow Detection

Checks if the page content exceeds the viewport width, causing horizontal scroll.

```typescript
const hasHorizontalOverflow = await page.evaluate(() => {
  return document.documentElement.scrollWidth > document.documentElement.clientWidth;
});
```

**Pass:** `scrollWidth <= clientWidth` (no horizontal scroll)
**Fail:** Content extends beyond viewport — indicates elements with fixed widths or missing responsive constraints

### 2. Element Clipping Detection

Checks if interactive elements are partially or fully clipped by their containers.

```typescript
const clippedElements = await page.evaluate(() => {
  const interactive = document.querySelectorAll('button, a, input, select, textarea, [role="button"]');
  const clipped: string[] = [];
  interactive.forEach(el => {
    const rect = el.getBoundingClientRect();
    const parent = el.parentElement?.getBoundingClientRect();
    if (parent && (rect.right > parent.right || rect.bottom > parent.bottom || rect.left < parent.left)) {
      clipped.push(el.tagName + (el.className ? '.' + el.className.split(' ')[0] : ''));
    }
  });
  return clipped;
});
```

**Pass:** No interactive elements extend beyond parent bounds
**Fail:** Elements are clipped — indicates overflow-hidden containers hiding interactive content

### 3. Breakpoint Visibility Toggle Detection

Verifies that elements intended to show/hide at specific breakpoints (Tailwind `hidden md:block`, `md:hidden`) are in the correct state.

```typescript
const visibilityIssues = await page.evaluate((viewport) => {
  const issues: string[] = [];
  // Check elements with responsive visibility classes
  const responsiveEls = document.querySelectorAll('[class*="hidden"], [class*="md:"], [class*="lg:"]');
  responsiveEls.forEach(el => {
    const style = window.getComputedStyle(el);
    const isVisible = style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0';
    const classes = el.className;
    // Verify the visibility state matches what the breakpoint classes intend
    if (viewport === 'mobile' && classes.includes('hidden') && !classes.includes('sm:block') && isVisible) {
      issues.push(`Should be hidden on mobile: ${el.tagName}.${classes.split(' ')[0]}`);
    }
  });
  return issues;
}, viewportName);
```

**Pass:** All responsive visibility toggles are in the correct state for the current breakpoint
**Fail:** Elements that should be hidden are visible or vice versa

### 4. Tap-Target Size Detection (Touch Only)

Checks that interactive elements meet the minimum 44x44px tap-target requirement on touch devices.

```typescript
const smallTapTargets = await page.evaluate(() => {
  const interactive = document.querySelectorAll('button, a, input, select, textarea, [role="button"]');
  const small: { element: string; width: number; height: number }[] = [];
  interactive.forEach(el => {
    const rect = el.getBoundingClientRect();
    if (rect.width < 44 || rect.height < 44) {
      small.push({
        element: el.tagName + (el.className ? '.' + el.className.split(' ')[0] : ''),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
      });
    }
  });
  return small;
});
```

**Pass:** All interactive elements are >= 44x44px
**Fail:** Tap targets are too small — add padding or increase size
**Note:** Only checked on touch viewports (`hasTouch: true`)

### 5. Text Truncation Detection

Detects text that is truncated or cut off in a way that loses meaningful content.

```typescript
const truncatedText = await page.evaluate(() => {
  const textElements = document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, span, td, th, label');
  const truncated: string[] = [];
  textElements.forEach(el => {
    const style = window.getComputedStyle(el);
    if (style.textOverflow === 'ellipsis' || style.whiteSpace === 'nowrap') {
      if (el.scrollWidth > el.clientWidth) {
        truncated.push(el.tagName + ': "' + el.textContent?.substring(0, 30) + '..."');
      }
    }
  });
  return truncated;
});
```

**Pass:** No text is truncated with content loss
**Fail:** Text is cut off — may need wrapping, font-size adjustment, or responsive text classes

### 6. Layout-Shift Detection

Checks for Cumulative Layout Shift (CLS) caused by responsive breakpoint transitions or content reflow.

```typescript
// Run at page load and after a 2-second delay
const clsBefore = await page.evaluate(() => (window as any).__clsValue || 0);
await page.waitForTimeout(2000);
const clsAfter = await page.evaluate(() => (window as any).__clsValue || 0);
const layoutShift = clsAfter - clsBefore;
```

**Pass:** CLS delta < 0.1 (minimal layout shift)
**Fail:** Significant layout shift — content reflows after initial render

---

## 3 Fix-Confidence Tiers

Defects are classified by how confidently they can be auto-fixed:

### Tier 1: Auto-Fix (High Confidence)

Mechanical changes that don't alter component behavior or structure:

| Defect | Fix Pattern |
|---|---|
| Missing responsive grid | Add `grid-cols-1 sm:grid-cols-2 lg:grid-cols-4` |
| Fixed width causing overflow | Replace `w-[500px]` with `w-full max-w-[500px]` |
| Missing flex direction switch | Add `flex-col sm:flex-row` |
| Small tap targets | Add `min-w-[44px] min-h-[44px]` or `p-2` |
| Text not wrapping | Add `break-words` or remove `whitespace-nowrap` |
| Missing responsive text size | Add `text-sm md:text-base lg:text-lg` |

**Action:** Apply directly, no verification needed beyond re-audit.

### Tier 2: Propose + Verify (Medium Confidence)

Structural changes that alter layout behavior but follow established patterns:

| Defect | Fix Pattern |
|---|---|
| Table on mobile | Transform to card list: `<table>` → stacked `<div>` cards with labeled fields |
| Sidebar always visible | Add `hidden md:block` + hamburger toggle for mobile |
| Dialog/modal too small on mobile | Add responsive sizing: `w-[90vw] max-w-md` |
| Multi-column form | Stack on mobile: `grid-cols-1 md:grid-cols-2` |
| Horizontal tab overflow | Convert to scrollable tabs or dropdown on mobile |

**Action:** Apply the fix, then delegate screenshot capture to primary session for `image-analyzer-subagent` review. Verify visually before accepting.

### Tier 3: Report Only (Low Confidence)

Complex restructures that require human judgment or design decisions:

| Defect | Reason |
|---|---|
| Complex data visualization | May need alternative representation (table → chart → summary) |
| Multi-step wizard layout | Needs UX decision on mobile flow |
| Drag-and-drop interface | Needs touch alternative design |
| Custom canvas/SVG rendering | Needs viewport-aware scaling logic |
| Third-party widget overflow | May need wrapper or replacement |

**Action:** Document as a follow-up item with severity and recommended approach. Do not auto-fix.

---

## PTY Execution Strategy (Display-Branched)

The closed loop runs many detect→fix→re-verify iterations. Booting Playwright + chromium fresh each iteration (batch `bash`) wastes 5-15s of cold start per cycle and gives no streaming. Instead, **keep a persistent PTY session** for the test runner and read results incrementally. PTY tools (`pty_spawn`/`pty_read`/`pty_write`/`pty_kill`/`pty_list`) are ungated in opencode (not a permission key) and available to any agent.

### Step L0: Detect Display

```bash
# DISPLAY set (native X/Wayland) OR xvfb-run available (virtual framebuffer)
if [ -n "$DISPLAY" ] || command -v xvfb-run >/dev/null 2>&1; then
  echo "DISPLAY_AVAILABLE"
else
  echo "HEADLESS"
fi
```

### Strategy A — `watch-ui` (DISPLAY_AVAILABLE)

Interactive Playwright modes auto-re-run on file save, collapsing edit→retest into one live loop. Requires a display (native or `xvfb-run`).

- **Watch-verify:** `pty_spawn` a persistent `npx playwright test --ui` (or `xvfb-run -a npx playwright test --ui`). Edit a `.tsx` → affected tests re-run automatically → `pty_read` the streamed result. No manual re-invocation per iteration.
- **Spec authoring:** `pty_spawn npx playwright codegen <url>` to record real selectors into `e2e/responsive/*.spec.ts` by driving the page, instead of hand-writing.
- **Root-cause (Tier 3):** `pty_spawn npx playwright test --debug <spec>` to step through a failing assertion and inspect the DOM at the breakpoint — can promote Tier 3 "report only" to fixable.

> **xvfb caveat:** under pure `xvfb-run` (no forwarded display), `--ui` auto-watch + streamed stdout work, but `codegen`/`--debug` open GUI inspector windows an agent cannot drive interactively. Step-through/interactive recording needs a real or forwarded display. Strategy B's `pty_read` + early-abort gives the same core value headlessly.

### Strategy B — `stream-shell` (HEADLESS, e.g. Docker standalone / CI)

No display → no `--ui`/`--debug`/`codegen`. Still beats batch:

- **Persistent shell:** `pty_spawn` one bash session; run `npx playwright test` there. Re-run via up-arrow / `!!` history — process spawn amortized, shell warm.
- **Streaming + early-abort:** `pty_read` to see the first failure within seconds; `pty_write "\x03"` (Ctrl+C) to abort once the first defect is confirmed instead of waiting for the full suite.
- **Live report:** `pty_spawn npx playwright show-report` keeps the HTML report server alive across iterations; query it via webfetch rather than re-opening static HTML per run.

### PTY tool mapping

| Action | Tool |
|---|---|
| Start runner / shell / codegen / report | `pty_spawn` (set `title`, e.g. `"PW watch"`) |
| Read streamed test output | `pty_read` (high offset to tail recent lines) |
| Abort a run early | `pty_write` with `"\x03"` |
| Send a re-run command / input | `pty_write` with `"npx playwright test\n"` |
| End the session | `pty_kill` (cleanup: true) |

> **Fallback:** if `pty_*` tools are unavailable in a deployment, the loop degrades to batch `bash` (the original behavior) — slower but correct. PTY is an optimization, not a dependency.

---

## Closed-Loop Iteration Pattern

```
┌──────────────────────────────────────┐
│ ITERATION N                           │
├──────────────────────────────────────┤
│ 1. DETECT: Run 6 assertions           │
│    at all breakpoints                 │
│ 2. DIAGNOSE: Classify defects         │
│    into Tier 1/2/3                    │
│ 3. FIX: Apply Tier 1 auto-fixes       │
│    Apply Tier 2 (with verify)         │
│    Skip Tier 3 (report only)          │
│ 4. RE-VERIFY: Re-run ALL assertions   │
│    at ALL breakpoints                 │
│ 5. DELTA: Compare defect count        │
│    vs previous iteration              │
│ 6. DECISION:                          │
│    - If defects remain AND delta > 0: │
│      increment N, go to 1             │
│    - If defects == 0: DONE            │
│    - If delta == 0 (no improvement):  │
│      STOP — escalate remaining        │
│    - If N >= MAX_ITERATIONS (5):      │
│      STOP — report remaining          │
└──────────────────────────────────────┘
```

**Max iterations:** 5. If no progress is made in an iteration (delta == 0), stop and escalate remaining Tier 2/3 defects.

**Execution:** Steps 1 (DETECT) and 4 (RE-VERIFY) run against the persistent PTY session from the [PTY Execution Strategy](#pty-execution-strategy-display-branched) — `pty_read` for results, not fresh `bash` per iteration. Strategy A auto-re-runs on file save; Strategy B re-invokes in the warm shell.

---

## Regression Spec Emission

After the audit completes (all fixable defects resolved), emit a Playwright regression spec:

**File:** `e2e/responsive/{page-name}.responsive.spec.ts`

**Structure:**
```typescript
import { test, expect, devices } from '@playwright/test';

const breakpoints = [
  { name: 'mobile', viewport: { width: 375, height: 667 }, hasTouch: true },
  { name: 'tablet', viewport: { width: 768, height: 1024 }, hasTouch: true },
  { name: 'desktop', viewport: { width: 1280, height: 720 } },
];

for (const bp of breakpoints) {
  test.describe(`${bp.name} responsive`, () => {
    test.use({ viewport: bp.viewport, hasTouch: bp.hasTouch });

    test('no horizontal overflow', async ({ page }) => {
      await page.goto('/target-page');
      const hasOverflow = await page.evaluate(() =>
        document.documentElement.scrollWidth > document.documentElement.clientWidth
      );
      expect(hasOverflow).toBe(false);
    });

    test('no clipped interactive elements', async ({ page }) => { /* ... */ });
    test('correct breakpoint visibility', async ({ page }) => { /* ... */ });
    test('tap-targets >= 44px', async ({ page }) => { /* ... */ });
    test('no text truncation', async ({ page }) => { /* ... */ });
    test('minimal layout shift', async ({ page }) => { /* ... */ });
  });
}
```

---

## Viewport Matrix Configuration

Reference for `playwright.config.ts` projects:

```typescript
projects: [
  {
    name: 'desktop-chromium',
    use: {
      ...devices['Desktop Chrome'],
      viewport: { width: 1280, height: 720 },
    },
  },
  {
    name: 'mobile-chrome',
    use: {
      ...devices['Pixel 5'],
      viewport: { width: 375, height: 667 },
      hasTouch: true,
    },
  },
  {
    name: 'tablet',
    use: {
      ...devices['iPad (gen 7)'],
      viewport: { width: 768, height: 1024 },
      hasTouch: true,
    },
  },
],
```

All projects should use `storageState: 'e2e/.auth/user.json'` for authenticated pages.

---

## Integration with Other Skills

| Skill | Relationship |
|---|---|
| `wireframer-skill` | Baseline source — generates lo-fi wireframes at breakpoints for structural layout reference |
| `verification-loop-skill` | Used by primary session to verify fixes across iterations |

## Integration with Subagents

| Subagent | Relationship |
|---|---|
| `image-analyzer-subagent` | Receives screenshots for visual verification of Tier 2 fixes |
| `loop-operator-subagent` | Optional outer-loop orchestrator. With PTY the detect→fix→re-verify loop is internal to this skill/subagent, so `loop-operator` is only needed for cross-skill orchestration, not the responsive loop itself. |

## Iteration Protocol (opt-in)

**DO NOT execute any of the following unless `AUTORESEARCH_PROTOCOL=1` is set in your environment.** When unset, this skill behaves exactly as documented in all sections above; the Iteration Protocol block is descriptive only.

When `AUTORESEARCH_PROTOCOL=1`:

### Auto-detection
If invoked on an iterative task, prompt ONCE per session: "This looks iterative. Enable autoresearch protocol? (y/n)". Cache answer for session.

### Skill-specific patterns

**TSV trail.** Each closed-loop iteration appended to `playwright-responsive-results.tsv` (8-column format per `audit-trail.md`). **Evaluator.** Playwright assertion failures produce `{"pass":false,"score":N}` (score = passing assertions / total); all-pass = `{"pass":true,"score":<total>}`. See `evaluator-contract.md`.

### Citations
- `autoresearch-core-skill/references/audit-trail.md`
- `autoresearch-core-skill/references/evaluator-contract.md`

### Imperative gating
When `AUTORESEARCH_PROTOCOL` is unset, this section is descriptive only. Default behavior is documented in all sections above.
