---
name: amplify-nextjs-deployment-skill
description: >-
  Deploy and troubleshoot Next.js 16+ on AWS Amplify Hosting — amplify.yml, SSR
  Lambda env vars, CloudFront OAC, Route53 DNS, deploy triggers, rollback.
license: Apache-2.0
compatibility: opencode
metadata:
  pattern: amplify-deployment
category: Framework-Specific
---

## What this skill does

- Documents the **7 production-learned gotchas** for deploying Next.js 16+ to AWS Amplify Hosting
- Provides a canonical `amplify.yml` build spec template with SSR Lambda env-var injection
- Covers GitHub Actions-based deploy triggers (more reliable than Amplify webhooks)
- Includes post-deploy verification commands and rollback strategy
- Provides a troubleshooting matrix mapping symptoms → root causes → fixes

## When to use me

- When the user mentions "Amplify", "amplify.yml", "SSR Lambda", "CloudFront OAC", or "deploy to Amplify"
- When debugging `process.env.*` returning `undefined` in Next.js Server Components after a successful Amplify build
- When setting up a new Next.js + Amplify Hosting deployment
- When configuring custom domains via Route53 + Amplify
- When deploying media/S3 + CloudFront integration with Next.js Image optimization
- When reviewing or writing `amplify.yml`, deploy workflows, or infra-as-code for Amplify

## Prerequisites

- Next.js 16+ project (App Router + Turbopack build)
- AWS account with Amplify Hosting enabled
- (Optional) OpenTofu/Terraform infra module for S3 + CloudFront + Route53
- (Optional) GitHub Actions workflow for `aws amplify start-job` deploy triggers

---

## The 7 Critical Rules (Production-Learned)

These rules come from production debugging. Violating any of them typically produces a **successful build pipeline** with a **broken runtime** — the hardest failure mode to detect.

### Rule 1: Amplify branch env vars are build-time ONLY

The Amplify SSR Lambda does **NOT** receive branch env vars at runtime. Next.js Turbopack inlines `process.env.*` at build time from `.env.production`. The `amplify.yml` build spec MUST inject env vars into `.env.production` so they're baked into the server bundle.

**Symptom if violated:** `process.env.DATABASE_URL` is `undefined` in Server Components, despite the build succeeding and the env var being set in Amplify console.

**Fix:** See `amplify.yml` template below — the `preBuild` phase writes env vars to `.env.production`.

### Rule 2: Do NOT set `NODE_ENV` as a persistent Amplify env var

Setting `NODE_ENV=production` as a persistent Amplify branch env var causes npm to skip `devDependencies`, breaking the build. Tools like `@tailwindcss/postcss`, `tailwindcss`, and type-checking utilities often live in `devDependencies`.

**Symptom if violated:** Build fails with `Cannot find module '@tailwindcss/postcss'` or similar, despite the package being in `package.json`.

**Fix:** Let Amplify set `NODE_ENV=production` automatically during the build phase. Do not override it in the Amplify console's environment variables.

### Rule 3: Amplify webhooks are unreliable — use `aws amplify start-job`

Amplify's automatic webhook-based deploy triggers (fired on every GitHub push) are flaky. For reliable deploys, trigger via GitHub Actions using the AWS CLI:

```bash
aws amplify start-job \
  --app-id $AMPLIFY_APP_ID \
  --branch-name $BRANCH_NAME \
  --job-type RELEASE
```

**Symptom if violated:** Pushes to `main` sometimes don't trigger a deploy; the Amplify console shows the last deploy was hours ago despite recent commits.

**Fix:** Add a GitHub Actions workflow that runs `aws amplify start-job` after CI passes. See deploy workflow template below.

### Rule 4: Use CloudFront OAC (not legacy OAI) for S3 media access

For S3-hosted media accessed by Next.js Image optimization, use **CloudFront Origin Access Control (OAC)** — the modern replacement for legacy OAI. Dev environments can use direct S3 public read (CF disabled) for simplicity.

**Symptom if violated:** 403 Forbidden on optimized images in production; works locally because dev uses S3 public read.

**Fix:** Configure OAC on the CloudFront distribution pointing at the S3 media bucket. Update S3 bucket policy to allow `cloudfront:GetOriginAccessControl` from the distribution.

### Rule 5: Transfer DNS to Route53 BEFORE associating domain with Amplify

For custom domains, transfer DNS to Route53 **first**, then associate the domain with Amplify. Wildcard subdomains may show `verified: False` in Amplify console even when the domain is actually working — verify with `curl -sI https://yourdomain.com`.

**Symptom if violated:** Domain verification stuck in "Pending" for hours; Amplify console shows errors about DNS records not found.

**Fix:** Use OpenTofu/Terraform to manage Route53 records → wait for propagation → run `aws amplify create-domain-association`. Order matters.

### Rule 6: `tsconfig.json` must exclude infra/scripts/test dirs

Next.js type-checks the entire repo by default. If the repo co-locates OpenTofu/Terraform infra (`<infra-dir>/`), deploy scripts, or test configs alongside the Next.js app, TypeScript will try to compile them and fail on missing imports.

**Symptom if violated:** `npm run build` fails with type errors in files unrelated to the Next.js app (e.g., `Cannot find module '@aws-sdk/client-amplify'` in a deploy script).

**Fix:** Add explicit `exclude` to `tsconfig.json`:

```json
{
  "exclude": [
    "<infra-dir>/**/*",
    "scripts/**/*",
    "tests/**/*",
    "e2e/**/*"
  ]
}
```

### Rule 7: Build success ≠ runtime success

A green Amplify build pipeline only means the bundle compiled. It does NOT mean the SSR Lambda can connect to the database, read env vars, or reach downstream APIs. Always verify SSR pages return 200 with real content after deploy.

**Symptom if violated:** Build pipeline is green; users see 500 errors or blank pages in production.

**Fix:** Add a post-deploy smoke test (see verification commands below).

---

## Canonical `amplify.yml` Template

Place this file at the repo root. Adapt the env var grep pattern to match your project's variables.

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci --cache .npm --prefer-offline
        # Amplify SSR Lambda does NOT receive branch env vars at runtime.
        # Next.js Turbopack inlines process.env.* at build time from .env.production.
        # Write all server-side env vars so they get baked into the server bundle.
        - env | grep -e DATABASE_URL -e NEON_DATABASE_URL -e S3_BUCKET_NAME -e CLOUDFRONT_DOMAIN -e NEXT_PUBLIC_ -e SES_ -e ADMIN_ -e AWS_REGION >> .env.production
    build:
      commands:
        - npm run build
    postBuild:
      commands:
        # Drop server-side source maps to reduce artifact size
        - find .next -name '*.map' -type f -delete
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - .next/cache/**/*
      - .npm/**/*
```

**Critical:** Customize the `env | grep` line to include every server-side env var your app needs. Missing one means `process.env.X` is `undefined` at runtime, with no error message.

---

## GitHub Actions Deploy Trigger

Reliable alternative to Amplify webhooks. Place in `.github/workflows/deploy-amplify.yml`:

```yaml
name: Deploy to Amplify

on:
  workflow_run:
    workflows: ["Release"]  # or your CI workflow name
    types: [completed]
    branches: [main, dev]
  workflow_dispatch:
    inputs:
      branch:
        description: "Amplify branch to deploy"
        required: true
        default: "main"
        type: choice
        options: [main, dev]

permissions:
  id-token: write  # Required for OIDC AWS auth

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' || github.event_name == 'workflow_dispatch' }}
    steps:
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AMPLIFY_DEPLOY_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}

      - name: Trigger Amplify deploy
        run: |
          aws amplify start-job \
            --app-id ${{ vars.AMPLIFY_APP_ID }} \
            --branch-name ${{ inputs.branch || github.event.workflow_run.head_branch }} \
            --job-type RELEASE

      - name: Wait for deploy completion
        run: |
          JOB_ID=$(aws amplify list-jobs \
            --app-id ${{ vars.AMPLIFY_APP_ID }} \
            --branch-name ${{ inputs.branch || github.event.workflow_run.head_branch }} \
            --max-results 1 \
            --query 'jobSummaries[0].jobId' \
            --output text)
          aws amplify wait job-complete \
            --app-id ${{ vars.AMPLIFY_APP_ID }} \
            --branch-name ${{ inputs.branch || github.event.workflow_run.head_branch }} \
            --job-id "$JOB_ID" || echo "Job still running, will not block"
```

---

## Post-Deploy Verification Commands

Run these after every deploy to catch Rule 7 failures (build success ≠ runtime success):

```bash
# 1. Check the deployed SSR page returns 200 with real content
BRANCH_URL="https://${BRANCH}.<amplify-domain>"  # e.g., https://main.d2rwb3sd15g8e0.amplifyapp.com
curl -sI "$BRANCH_URL" | head -1  # Expect: HTTP/2 200

# 2. Check a dynamic Server Component actually rendered (not just shell HTML)
curl -s "$BRANCH_URL" | grep -c "<expected-data-marker>"  # Expect: > 0

# 3. Verify env vars reached the SSR Lambda (create a debug API route temporarily)
curl -s "$BRANCH_URL/api/debug-env" | jq .  # Should show all expected env vars

# 4. Check CloudFront media URLs resolve (Rule 4)
MEDIA_URL=$(curl -s "$BRANCH_URL" | grep -oE 'https://[^"]*\.(jpg|png|webp)' | head -1)
curl -sI "$MEDIA_URL" | head -1  # Expect: HTTP/2 200

# 5. Check custom domain if configured
curl -sI "https://<custom-domain>" | head -1  # Expect: HTTP/2 200
```

**Remove the `/api/debug-env` route after verification** — never leave it in production.

---

## Rollback Strategy

Amplify Hosting keeps a history of recent deploys. To rollback:

```bash
# List recent jobs to find the last-known-good
aws amplify list-jobs \
  --app-id $AMPLIFY_APP_ID \
  --branch-name $BRANCH \
  --max-results 10

# Rollback to a specific commit (creates a new job that deploys the old artifact)
aws amplify start-job \
  --app-id $AMPLIFY_APP_ID \
  --branch-name $BRANCH \
  --job-type RELEASE \
  --commit-id $LAST_KNOWN_GOOD_COMMIT_SHA \
  --commit-message "Rollback to $LAST_KNOWN_GOOD_COMMIT_SHA due to <reason>"
```

**For env-var-only changes:** No rollback needed — update the Amplify branch env var in the console and trigger a redeploy via `aws amplify start-job`.

**For infra changes (S3/CloudFront/Route53):** Use OpenTofu/Terraform state rollback. Amplify deploy rollback does NOT revert infra changes.

---

## Troubleshooting Matrix

| Symptom                                              | Likely cause                                                | Fix                                                                |
| ---------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------ |
| `process.env.X is undefined` in Server Components     | Env var not in `amplify.yml` `env \| grep` pattern         | Add to grep pattern, redeploy                                       |
| Build fails: `Cannot find module '@tailwindcss/postcss'` | `NODE_ENV=production` set as persistent env var          | Remove `NODE_ENV` from Amplify console env vars                    |
| Push to main doesn't trigger a deploy                 | Amplify webhook dropped the event                          | Add GitHub Actions `aws amplify start-job` workflow                 |
| 403 Forbidden on optimized images in prod             | Using legacy OAI instead of OAC, or S3 policy missing      | Configure CloudFront OAC + update S3 bucket policy                 |
| Domain verification stuck in "Pending"                | DNS not yet on Route53, or wildcard mismatch               | Transfer DNS to Route53 first; test with `curl -sI`                |
| Type errors in `infra/` or `scripts/` dirs            | `tsconfig.json` doesn't exclude them                       | Add explicit `exclude` array                                       |
| Build green but 500s in prod                          | Runtime issue (DB connection, missing env var, etc.)       | Run post-deploy verification; check CloudWatch Logs (us-east-1)    |
| Slow cold starts on SSR Lambda                        | Bundle too large (server-side source maps included)        | Verify `postBuild` strips `.map` files                            |
| Wildcard subdomain `verified: False` but works        | Amplify console bug — actual DNS is fine                   | Ignore; verify with `curl -sI https://app.yourdomain.com`          |

---

## Key Files in a Next.js + Amplify Project

| File                                          | Purpose                                                                |
| -------------------------------------------- | ---------------------------------------------------------------------- |
| `amplify.yml` (repo root)                    | Build spec with `.env.production` injection — **critical**              |
| `<infra-dir>/`                                | OpenTofu/Terraform module (Amplify app, S3, CloudFront, Route53)        |
| `src/lib/media/url.ts` (or similar)           | Client-safe `getMediaUrl()` helper (CloudFront → S3 fallback)           |
| `next.config.ts`                              | `images.remotePatterns` for S3/CloudFront domains                       |
| `tsconfig.json`                               | MUST `exclude` infra/scripts/test dirs                                  |
| `.github/workflows/deploy-amplify.yml`        | GitHub Actions trigger (alternative to flaky webhooks)                  |

---

## Detection Commands

```bash
# Find repos with Amplify deployment but missing .env.production injection
rg -l 'amplify\.yml' --type yaml | xargs -I{} grep -L 'env \|.*>> \.env\.production' {}

# Find tsconfig.json missing exclude for common infra dirs
rg -A 10 '"exclude"' tsconfig.json | grep -vE '<infra-dir>|scripts|tests|e2e'

# Find Next.js Server Components accessing env vars (verify each is in amplify.yml)
rg 'process\.env\.[A-Z_]+' --type ts --type tsx -g '!*.test.*' -g '!*.spec.*'
```

---

## Related Skills

- **`nextjs-standard-setup-skill`** — scaffolds the Next.js project that this skill deploys
- **`nextjs-image-usage-skill`** — configures `next.config.ts` `images.remotePatterns` (referenced by Rule 4)
- **`react-hooks-antipatterns-skill`** + **`react-render-antipatterns-skill`** — catch SSR/runtime anti-patterns that fail at runtime (Rule 7)
- **`opentofu-aws-explorer-skill`** — manages the OpenTofu/Terraform infra module for Amplify + S3 + CloudFront
- **`opentofu-provisioning-workflow-skill`** — state management for the infra side of rollbacks
