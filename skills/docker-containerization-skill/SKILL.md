---
name: docker-containerization-skill
description: >-
  Create and optimize Dockerfiles — multi-stage builds, compose patterns, layer
  caching, .dockerignore, health checks, hadolint/docker scout scanning.
license: Apache-2.0
compatibility: opencode
category: DevOps
---

## What I do

I help you create, optimize, and secure Docker containers:

1. **Dockerfile Authoring**: Write production-grade Dockerfiles with multi-stage builds
2. **Image Optimization**: Reduce image size with distroless, Alpine, and layer strategies
3. **Docker Compose**: Design development and production compose configurations
4. **Layer Caching**: Structure builds for maximum cache efficiency
5. **Health Checks**: Implement proper health check endpoints and probes
6. **Security Scanning**: Scan images with hadolint (linting) and docker scout (vulnerabilities)

## When to use me

Use this skill when:
- Writing or optimizing a Dockerfile for a new or existing project
- Setting up docker-compose for local development or production deployment
- Reducing Docker image size
- Debugging container build failures or slow builds
- Implementing health checks and graceful shutdown
- Setting up multi-container architectures
- Scanning containers for security issues
- Creating .dockerignore files

## Related Skills

- **opentofu-provisioning-workflow-skill**: Handles infrastructure provisioning. This skill handles container image building and composition.
- **security-audit-skill**: Handles application-level security auditing. This skill handles container-specific security (image scanning, hadolint).

---

## Step 1: Dockerfile Templates

### Node.js (Next.js)

```dockerfile
FROM node:20-alpine AS base
RUN apk add --no-cache libc6-compat
WORKDIR /app

FROM base AS deps
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN corepack enable pnpm && pnpm build

FROM base AS runner
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000 HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
```

### Python (FastAPI)

```dockerfile
FROM python:3.12-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential && rm -rf /var/lib/apt/lists/*
WORKDIR /app

FROM base AS deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS runner
COPY --from=deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=deps /usr/local/bin /usr/local/bin
COPY . .

RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Go

```dockerfile
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/server /server
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/server"]
```

## Step 2: Image Size Optimization

### Strategy Matrix

| Technique | Size Reduction | Best For |
|-----------|---------------|----------|
| Multi-stage build | 50-80% | All compiled languages |
| Alpine base | 30-50% | Python, Node.js, Go |
| Distroless | 40-60% | Go, static binaries |
| `.dockerignore` | 10-30% | All projects |
| Layer squashing | 10-20% | Complex builds |
| `--no-cache-dir` (pip) | 5-15% | Python |
| `--frozen-lockfile` | Prevents bloat | Node.js |

### .dockerignore Template

```
.git
.github
.gitignore
node_modules
__pycache__
*.pyc
.pytest_cache
.venv
.env
.env.*
*.md
LICENSE
docker-compose*.yml
Dockerfile*
.dockerignore
.vscode
.idea
coverage
.nyc_output
dist
build
.next
*.log
```

## Step 3: Docker Compose Patterns

### Development

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: deps
    volumes:
      - .:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/app_dev
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

### Production

```yaml
services:
  app:
    image: ghcr.io/org/app:${VERSION:-latest}
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://localhost:3000/api/health').then(r=>r.ok?process.exit(0):process.exit(1))"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "0.5"
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

## Step 4: Layer Caching Optimization

### Rules

1. **Copy dependency files first** — `package.json`, `requirements.txt`, `go.mod`
2. **Install dependencies** — changes when deps change
3. **Copy source code last** — changes most frequently
4. **Order from least to most frequently changing**

### Cache Check

```bash
docker build --no-cache -t app:latest .
docker history app:latest --human --no-trunc
docker images app --format "{{.Repository}}:{{.Tag}} {{.Size}}"
```

### BuildKit Cache Mounts

```dockerfile
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

RUN --mount=type=cache,target=/app/.npm \
    npm ci
```

## Step 5: Health Checks

### Application Health Endpoint

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
async def health():
    return {"status": "healthy", "version": "1.0.0"}

@app.get("/health/ready")
async def readiness():
    return {"status": "ready", "checks": {"database": "connected"}}
```

### Container Health Check Config

| Parameter | Default | Recommended |
|-----------|---------|-------------|
| interval | 30s | 30s |
| timeout | 30s | 5-10s |
| start-period | 0s | 10-30s |
| retries | 3 | 3 |

## Step 6: Security Scanning

### Hadolint (Dockerfile Linting)

```bash
hadolint Dockerfile
```

### Docker Scout (Vulnerability Scanning)

```bash
docker scout cves app:latest
docker scout recommendations app:latest
```

### Trivy

```bash
trivy image app:latest
trivy image --severity HIGH,CRITICAL app:latest
```

### Common Hadolint Fixes

| Rule | Issue | Fix |
|------|-------|-----|
| DL3008 | Pin apt versions | `RUN apt-get install -y --no-install-recommends package=1.0.*` |
| DL3013 | Pin pip versions | `RUN pip install --no-cache-dir package==1.0.0` |
| DL3016 | Pin npm versions | `RUN npm ci` (uses lockfile) |
| DL3007 | Use latest tag | Pin specific version: `FROM node:20.11-alpine` |
| DL4006 | Pipe fail | `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` |
| DL3059 | Multiple consecutive RUN | Combine into single RUN with `&&` |

## Step 7: Graceful Shutdown

```javascript
const server = app.listen(PORT)

function gracefulShutdown(signal) {
  console.log(`Received ${signal}, shutting down gracefully...`)
  server.close(() => {
    console.log('HTTP server closed')
    process.exit(0)
  })
  setTimeout(() => {
    console.error('Forced shutdown after timeout')
    process.exit(1)
  }, 10000)
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
process.on('SIGINT', () => gracefulShutdown('SIGINT'))
```

```yaml
compose:
  stop_grace_period: 10s
```

---

## Deployment Rollback Strategy

### `no-rollback-on-deploy`

A deployment that overwrites the running image and then runs a smoke test has no way back when the smoke test fails — production is already on the broken image. Capture the previous image URI BEFORE the update, then add an explicit rollback step that restores it on smoke-test failure. This is especially critical with dual deployment targets (e.g. EC2 service + Lambda function) where one target may update successfully and the other fail, leaving the system in a split-brain state where rollback is the only safe action.

```bash
# VULNERABLE — overwrite in place, no previous image captured, no rollback
aws ecs update-service --cluster prod --service api \
  --task-definition api:42         # previous task def api:41 is now orphaned
./smoke_test.sh                    # FAILS — prod is now on api:42 with no way back

# SECURE — capture previous, rollback on smoke test failure
set -euo pipefail
PREV_TASK_DEF=$(aws ecs describe-services --cluster prod --services api \
  --query 'services[0].taskDefinition' --output text)
aws ecs update-service --cluster prod --service api \
  --task-definition api:42
aws ecs wait services-stable --cluster prod --service api

if ! ./smoke_test.sh; then
  echo "Smoke test failed — rolling back to ${PREV_TASK_DEF}" >&2
  aws ecs update-service --cluster prod --service api \
    --task-definition "${PREV_TASK_DEF}"
  aws ecs wait services-stable --cluster prod --service api
  exit 1
fi
```

```yaml
# CI/CD step (GitHub Actions) — capture + rollback for dual EC2 + Lambda targets
- name: Deploy
  env:
    PREV_ECS: ${{ steps.prev.outputs.task_def }}
    PREV_LAMBDA: ${{ steps.prev.outputs.lambda_arn }}
  run: |
    ./deploy_ecs.sh "${{ steps.build.outputs.image }}"
    ./deploy_lambda.sh "${{ steps.build.outputs.image }}"
    if ! ./smoke_test.sh; then
      ./rollback_ecs.sh "${PREV_ECS}"
      ./rollback_lambda.sh "${PREV_LAMBDA}"
      exit 1
    fi
```

**Detection:**

```bash
rg 'update-service|deploy|aws lambda update-function-code' .github/workflows/ -A 5 | rg -v 'rollback|prev|previous'
```

**Rule:** Every deployment MUST (1) capture the previous image/task-def/ARN before updating, and (2) include an explicit rollback step that restores it on smoke-test failure. Dual-target deployments (EC2 + Lambda) must rollback BOTH targets atomically on any failure.

---

## Build ARG Centralization

### `hardcoded-sed-version-swap`

SDK or library versions hardcoded as `sed` substitutions across Dockerfiles, CI workflows, and shell scripts are a DRY violation that drifts within a single repo. Bump the version once and three files still ship the old value because nobody grepped for every occurrence. Use a single `ARG` (Dockerfile) or a single variable sourced by all build steps (CI workflow matrix) so there is exactly one place to bump the version.

```dockerfile
# WRONG — version appears in 3+ places via sed, drifts on bump
RUN sed -i 's/VERSION=1.2.3/VERSION=1.3.0/g' config.toml
# .github/workflows/release.yml
#   run: sed -i 's/sdk-version=1.2.3/sdk-version=1.3.0/' package.json
# scripts/install.sh
#   sed -i 's/SERVICE_VERSION=1.2.3/SERVICE_VERSION=1.3.0/' .env

# CORRECT — one ARG, referenced everywhere; bump in a single line
ARG SERVICE_VERSION=1.3.0
ENV SERVICE_VERSION=${SERVICE_VERSION}
RUN echo "{\"version\": \"${SERVICE_VERSION}\"}" > /app/version.json
```

```yaml
# .github/workflows/release.yml — single variable, consumed by all steps
env:
  SERVICE_VERSION: 1.3.0
jobs:
  build:
    steps:
      - run: docker build --build-arg SERVICE_VERSION=${{ env.SERVICE_VERSION }} .
      - run: ./scripts/install.sh "${{ env.SERVICE_VERSION }}"
```

**Detection:**

```bash
rg "sed.*version|sed.*VERSION" Dockerfile* .github/ scripts/ -n
```

**Rule:** Pin SDK/library versions in exactly one place — a Dockerfile `ARG`, a CI workflow-level `env`, or a single `.env` — and have every build step consume that single source. Never `sed` the same version string into multiple files.
